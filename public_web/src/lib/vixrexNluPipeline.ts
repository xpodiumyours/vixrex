"use client";

import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { resolveVixrexIntent } from "./vixrexIntentResolver";
import { extractVixrexValue } from "./vixrexValueExtractor";
import { validateField } from "./vitrinFieldValidation";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

export type VixrexPipelineOutcome = "handled" | "needsClarification" | "notUnderstood" | "needsSpecialFlow" | "blockedLegal";

export interface VixrexPipelineResult {
  outcome: VixrexPipelineOutcome;
  message: string;
  anahtar?: string;
  deger?: unknown;
}

const PENDING_KEY = "vixrex_pending_slot_v1_local";

function loadPending(): { anahtar: string; etiket: string; tip: string } | null {
  try {
    const raw = typeof window !== "undefined" ? localStorage.getItem(PENDING_KEY) : null;
    if (!raw) return null;
    return JSON.parse(raw);
  } catch { return null; }
}
function savePending(a: VixrexNiyetAlan) {
  if (typeof window === "undefined") return;
  localStorage.setItem(PENDING_KEY, JSON.stringify({ anahtar: a.anahtar, etiket: a.etiket, tip: a.tip }));
}
function clearPending() {
  if (typeof window === "undefined") return;
  localStorage.removeItem(PENDING_KEY);
}

function needsSpecialFlow(anahtar: string): boolean {
  return anahtar === "il" || anahtar === "ilce";
}

function clarifyAsk(alan: VixrexNiyetAlan): string {
  // Faz 1: ipucu varsa sor, yoksa genel.
  // vitrinFieldSchema’daki ipucu’nu al – burada basitleştir.
  return `${alan.etiket} için ne yazayım?`;
}
function clarifySuccess(alan: VixrexNiyetAlan, deger: unknown): string {
  return `Kaydettim: ${alan.etiket} → ${String(deger)}`;
}

export async function handleVixrexNluMessage(input: string): Promise<VixrexPipelineResult> {
  const trimmed = input.trim();
  if (!trimmed) return { outcome: "notUnderstood", message: "Hangi alanı değiştirmek istediğini netleştirebilir misin? Örn: “İşletme adını ... yap”" };

  const norm = vixrexNormalizeDartParity(trimmed);
  const pending = loadPending();

  // Evet/hayır pending ile – Faz 1 dar: sadece temizle.
  if (pending && (norm === "evet" || norm === "hayır" || norm === "hayir" || norm === "iptal")) {
    clearPending();
    if (norm === "evet") return { outcome: "needsClarification", message: "Hangi alanı değiştirmek istediğini netleştirebilir misin?" };
    return { outcome: "needsClarification", message: "Tamam, vazgeçtim. Başka nasıl yardımcı olabilirim?" };
  }

  // Pending varken yeni alan yoksa → ham mesajı pending alanın değeri say.
  if (pending) {
    const alan = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === pending.anahtar) ?? null;
    if (alan) {
      const resolved = resolveVixrexIntent(trimmed);
      if (!resolved) {
        if (needsSpecialFlow(alan.anahtar)) return { outcome: "needsSpecialFlow", message: clarifyAsk(alan), anahtar: alan.anahtar };
        const v = validateField(alan.anahtar, trimmed);
        if (!v.ok) return { outcome: "needsClarification", message: (v as { hata: string }).hata, anahtar: alan.anahtar };
        clearPending();
        return { outcome: "handled", message: clarifySuccess(alan, (v as { deger: unknown }).deger ?? trimmed), anahtar: alan.anahtar, deger: (v as { deger: unknown }).deger ?? trimmed };
      }
    }
  }

  const alan = resolveVixrexIntent(trimmed);
  if (!alan) return { outcome: "notUnderstood", message: "Hangi alanı değiştirmek istediğini netleştirebilir misin? Örn: “İşletme adını ... yap”" };
  if (needsSpecialFlow(alan.anahtar)) {
    savePending(alan);
    return { outcome: "needsSpecialFlow", message: clarifyAsk(alan), anahtar: alan.anahtar };
  }
  const ham = extractVixrexValue(trimmed, alan);
  if (!ham) {
    savePending(alan);
    return { outcome: "needsClarification", message: clarifyAsk(alan), anahtar: alan.anahtar };
  }
  const v = validateField(alan.anahtar, ham);
  if (!v.ok) return { outcome: "needsClarification", message: (v as { hata: string }).hata, anahtar: alan.anahtar };
  clearPending();
  return { outcome: "handled", message: clarifySuccess(alan, (v as { deger: unknown }).deger ?? ham), anahtar: alan.anahtar, deger: (v as { deger: unknown }).deger ?? ham };
}
