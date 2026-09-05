"use client";

import { supabase } from "./supabase";
import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import {
  resolveVixrexIntent,
  resolveVixrexIntentMatches,
  type VixrexIntentMatch,
} from "./vixrexIntentResolver";
import { extractVixrexValue } from "./vixrexValueExtractor";
import { validateField } from "./vitrinFieldValidation";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";
import {
  createValidatedAction,
  type VixrexDecisionKind,
  type VixrexValidatedAction,
} from "./vixrexDecisionContract";
import {
  createPendingEnvelope,
  parsePendingEnvelope,
  type VixrexPendingEnvelope,
  type VixrexPendingKind,
} from "./vixrexPendingContract";

export type VixrexPipelineOutcome =
  | "handled"
  | "needsClarification"
  | "notUnderstood"
  | "needsSpecialFlow"
  | "blockedLegal";

export interface VixrexPipelineResult {
  /** Canonical 5.3 decision contract. */
  decision: VixrexDecisionKind;
  actions: VixrexValidatedAction[];

  /**
   * Geriye uyum alanı. Aktif çağıranlar canonical `decision/actions` alanına
   * geçirildikçe kaldırılabilir; decision engine artık persistence yapmaz.
   */
  outcome: VixrexPipelineOutcome;
  message: string;
  anahtar?: string;
  deger?: unknown;
  /** Tek cümlede birden çok alan anlaşıldıysa hepsi burada. `anahtar`/`deger`
   * geriye dönük uyum için ilkini taşımaya devam eder — yalnız onu okuyan
   * çağıran diğer alanları sessizce kaybederdi. */
  tumu?: Array<{ anahtar: string; kolon: string; deger: unknown }>;
}

// 5.4: Supabase `assistant_conversations.pending_slot` kanonik state.
// Parser eski {anahtar, etiket, tip...} kayıtlarını da v1 envelope'a taşır.
async function loadPending(): Promise<VixrexPendingEnvelope | null> {
  try {
    const { data, error } = await supabase.rpc("get_assistant_pending_slot");
    if (error || !data) return null;
    return parsePendingEnvelope(data);
  } catch {
    return null;
  }
}

async function savePending(
  a: VixrexNiyetAlan,
  kind: VixrexPendingKind = "missing_value",
): Promise<void> {
  try {
    await supabase.rpc("set_assistant_pending_slot", {
      p_slot: createPendingEnvelope({
        fieldKey: a.anahtar,
        fieldType: a.tip,
        fieldLabel: a.etiket,
        kind,
      }),
    });
  } catch {
    // Pending write başarısızsa cross-device state kaydedildi varsayılmaz.
  }
}

async function clearPending(): Promise<void> {
  try {
    await supabase.rpc("set_assistant_pending_slot", { p_slot: null });
  } catch {
    // Clear başarısızlığı persistence success olarak raporlanmaz.
  }
}

function needsSpecialFlow(anahtar: string): boolean {
  return anahtar === "il" || anahtar === "ilce";
}

function clarifyAsk(alan: VixrexNiyetAlan): string {
  return `${alan.etiket} için ne yazayım?`;
}

function validatedMessage(count: number): string {
  return count > 1
    ? "Değişiklikler doğrulandı; kayıt için hazır."
    : "Değişiklik doğrulandı; kayıt için hazır.";
}

function uniqueFieldMatches(input: string): VixrexIntentMatch[] {
  const seen = new Set<string>();
  const unique: VixrexIntentMatch[] = [];
  for (const match of resolveVixrexIntentMatches(input)) {
    if (seen.has(match.alan.anahtar)) continue;
    seen.add(match.alan.anahtar);
    unique.push(match);
  }
  return unique;
}

export async function handleVixrexNluMessage(input: string): Promise<VixrexPipelineResult> {
  const trimmed = input.trim();
  if (!trimmed) {
    return {
      decision: "not_understood",
      actions: [],
      outcome: "notUnderstood",
      message: "Hangi alanı değiştirmek istediğini netleştirebilir misin? Örn: “İşletme adını ... yap”",
    };
  }

  const norm = vixrexNormalizeDartParity(trimmed);
  const pending = await loadPending();

  // Evet/hayır pending ile – pending proposedValue taşımadığı sürece
  // yalnız "evet" mutation üretemez.
  if (pending && (norm === "evet" || norm === "hayır" || norm === "hayir" || norm === "iptal")) {
    await clearPending();
    if (norm === "evet") {
      return {
        decision: "needs_clarification",
        actions: [],
        outcome: "needsClarification",
        message: "Hangi alanı değiştirmek istediğini netleştirebilir misin?",
      };
    }
    return {
      decision: "needs_clarification",
      actions: [],
      outcome: "needsClarification",
      message: "Tamam, vazgeçtim. Başka nasıl yardımcı olabilirim?",
    };
  }

  // Pending varken yeni alan yoksa → ham mesajı pending alanın değeri say.
  if (pending) {
    const alan = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === pending.fieldKey) ?? null;
    if (alan) {
      const resolved = resolveVixrexIntent(trimmed);
      if (!resolved) {
        if (needsSpecialFlow(alan.anahtar)) {
          return {
            decision: "needs_special_flow",
            actions: [],
            outcome: "needsSpecialFlow",
            message: clarifyAsk(alan),
            anahtar: alan.anahtar,
          };
        }
        const v = validateField(alan.anahtar, trimmed);
        if (!v.ok) {
          return {
            decision: "needs_clarification",
            actions: [],
            outcome: "needsClarification",
            message: v.hata,
            anahtar: alan.anahtar,
          };
        }
        await clearPending();
        const kesin = v.deger;
        const action = createValidatedAction({
          fieldKey: alan.anahtar,
          normalizedValue: kesin,
          matchClass: "pending_slot",
        });
        return {
          decision: "validated_action",
          actions: [action],
          outcome: "handled",
          message: validatedMessage(1),
          anahtar: alan.anahtar,
          deger: kesin,
          tumu: [{ anahtar: alan.anahtar, kolon: alan.kolon, deger: kesin }],
        };
      }
    }
  }

  const matches = uniqueFieldMatches(trimmed);
  if (matches.length === 0) {
    return {
      decision: "not_understood",
      actions: [],
      outcome: "notUnderstood",
      message: "Hangi alanı değiştirmek istediğini netleştirebilir misin? Örn: “İşletme adını ... yap”",
    };
  }

  if (matches.length > 1) {
    const ok: Array<{
      alan: VixrexNiyetAlan;
      deger: string | number | boolean | null;
      match: VixrexIntentMatch;
    }> = [];
    const hatalar: string[] = [];

    for (const match of matches) {
      const a = match.alan;
      if (needsSpecialFlow(a.anahtar)) {
        hatalar.push(`${a.etiket} için panelden devam et`);
        continue;
      }
      const ham = extractVixrexValue(trimmed, a);
      if (!ham) {
        hatalar.push(`${a.etiket} için değer bulunamadı`);
        continue;
      }
      const v = validateField(a.anahtar, ham);
      if (!v.ok) {
        hatalar.push(v.hata);
        continue;
      }
      ok.push({ alan: a, deger: v.deger, match });
    }

    if (ok.length === 0) {
      return {
        decision: "needs_clarification",
        actions: [],
        outcome: "needsClarification",
        message: hatalar.join("\n") || "Hangi alanı değiştirmek istediğini netleştirebilir misin?",
      };
    }

    await clearPending();
    const actions = ok.map(({ alan, deger, match }) =>
      createValidatedAction({
        fieldKey: alan.anahtar,
        normalizedValue: deger,
        matchClass: match.matchClass,
      }),
    );

    return {
      decision: actions.length > 1 ? "validated_action_group" : "validated_action",
      actions,
      outcome: "handled",
      message: validatedMessage(actions.length),
      anahtar: ok[0].alan.anahtar,
      deger: ok[0].deger,
      tumu: ok.map(({ alan, deger }) => ({ anahtar: alan.anahtar, kolon: alan.kolon, deger })),
    };
  }

  const match = matches[0];
  const alan = match.alan;
  if (needsSpecialFlow(alan.anahtar)) {
    await savePending(alan, "special_flow");
    return {
      decision: "needs_special_flow",
      actions: [],
      outcome: "needsSpecialFlow",
      message: clarifyAsk(alan),
      anahtar: alan.anahtar,
    };
  }

  const ham = extractVixrexValue(trimmed, alan);
  if (!ham) {
    await savePending(alan, "missing_value");
    return {
      decision: "needs_clarification",
      actions: [],
      outcome: "needsClarification",
      message: clarifyAsk(alan),
      anahtar: alan.anahtar,
    };
  }

  const v = validateField(alan.anahtar, ham);
  if (!v.ok) {
    return {
      decision: "needs_clarification",
      actions: [],
      outcome: "needsClarification",
      message: v.hata,
      anahtar: alan.anahtar,
    };
  }

  await clearPending();
  const kesinDeger = v.deger;
  const action = createValidatedAction({
    fieldKey: alan.anahtar,
    normalizedValue: kesinDeger,
    matchClass: match.matchClass,
  });
  return {
    decision: "validated_action",
    actions: [action],
    outcome: "handled",
    message: validatedMessage(1),
    anahtar: alan.anahtar,
    deger: kesinDeger,
    tumu: [{ anahtar: alan.anahtar, kolon: alan.kolon, deger: kesinDeger }],
  };
}
