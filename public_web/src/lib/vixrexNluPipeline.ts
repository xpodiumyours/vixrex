"use client";

import { supabase } from "./supabase";
import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { resolveVixrexIntent, resolveVixrexIntentsAll } from "./vixrexIntentResolver";
import { extractVixrexValue } from "./vixrexValueExtractor";
import { validateField } from "./vitrinFieldValidation";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";
import {
  VIXREX_DOGAL_GENEL_SORU,
  vixrexBaglamsalCevapKarari,
} from "./vixrexConversationContext";

export type VixrexPipelineOutcome = "handled" | "needsClarification" | "notUnderstood" | "needsSpecialFlow" | "blockedLegal";

export interface VixrexPipelineResult {
  outcome: VixrexPipelineOutcome;
  message: string;
  anahtar?: string;
  deger?: unknown;
  /** Tek cümlede birden çok alan anlaşıldıysa hepsi burada. `anahtar`/`deger`
   * geriye dönük uyum için ilkini taşımaya devam eder — yalnız onu okuyan
   * çağıran diğer alanları sessizce kaybederdi. */
  tumu?: Array<{ anahtar: string; kolon: string; deger: unknown }>;
}

type PendingSlot = {
  anahtar: string;
  etiket: string;
  tip: string;
  eylem?: "kaldir";
};

// Adım 4 (2026-09-03): pending slot artık localStorage DEĞİL, kalıcı ve
// paylaşılan `assistant_conversations.pending_slot` (Furkan, 2026-09-02,
// "NLU Faz 1-3") — RPC'ler auth.uid() ister. OwnerAssistantPanel panel
// açılışında ensureAnonymousSession() çağırıp her esnafa (hesabı olmasa
// bile) gerçek bir auth.uid() sağlıyor; böylece assistant_conversations'ın
// NOT NULL user_id kısıtına dokunmadan, mevcut cross-client tabloya
// yazabiliyoruz. Oturum henüz kurulmadıysa RPC NOT_AUTHENTICATED döner —
// diğer fire-and-forget yazımlarla aynı desende sessizce yutulur, pending
// o turda basitçe "yok" sayılır.
async function loadPending(): Promise<PendingSlot | null> {
  try {
    const { data, error } = await supabase.rpc("get_assistant_pending_slot");
    if (error || !data) return null;
    return data as PendingSlot;
  } catch { return null; }
}
async function savePending(a: VixrexNiyetAlan, eylem?: "kaldir"): Promise<void> {
  try {
    await supabase.rpc("set_assistant_pending_slot", {
      p_slot: {
        anahtar: a.anahtar,
        etiket: a.etiket,
        tip: a.tip,
        ...(eylem ? { eylem } : {}),
      },
    });
  } catch { /* sessizce yut — bellek modu korunur */ }
}
async function clearPending(): Promise<void> {
  try {
    await supabase.rpc("set_assistant_pending_slot", { p_slot: null });
  } catch { /* sessizce yut */ }
}

function needsSpecialFlow(anahtar: string): boolean {
  return anahtar === "il" || anahtar === "ilce";
}

function clarifyAsk(alan: VixrexNiyetAlan): string {
  return `${alan.etiket} için ne yazayım?`;
}
function clarifySuccess(alan: VixrexNiyetAlan, deger: unknown): string {
  return `Kaydettim: ${alan.etiket} → ${String(deger)}`;
}

/**
 * Aç/kapat alanlarında değer, çoğu zaman alan adından ayrı bir "değer"
 * değil komut fiilidir: "puanı göster", "yol tarifini gizle". Genel metin
 * ayıklayıcı bu fiilleri değer saymamalı; burada tip bilgisiyle güvenli
 * boolean'a çevrilir. Negatif sözcükler önce kontrol edilir.
 */
function extractPipelineValue(input: string, alan: VixrexNiyetAlan): unknown | null {
  if (alan.tip === "acikKapali") {
    const tokens = vixrexNormalizeDartParity(input)
      .replace(/[^a-z0-9]+/g, " ")
      .trim()
      .split(/\s+/)
      .filter(Boolean);
    const negatif = new Set(["kapat", "kapali", "gizle", "pasif", "hayir", "off", "false", "0"]);
    const pozitif = new Set(["ac", "acik", "goster", "aktif", "evet", "on", "true", "1"]);
    if (tokens.some((t) => negatif.has(t))) return false;
    if (tokens.some((t) => pozitif.has(t))) return true;
    return null;
  }
  return extractVixrexValue(input, alan);
}

export async function handleVixrexNluMessage(input: string): Promise<VixrexPipelineResult> {
  const trimmed = input.trim();
  if (!trimmed) {
    return { outcome: "notUnderstood", message: VIXREX_DOGAL_GENEL_SORU };
  }

  const pending = await loadPending();

  // Önceki soru varsa kısa cevabı o bağlamla birlikte değerlendir. Yeni bir
  // alan açıkça söylenmişse pending'e zorlamayız; normal niyet çözümü devralır.
  if (pending) {
    const alan = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === pending.anahtar) ?? null;
    if (alan) {
      const resolved = resolveVixrexIntent(trimmed);
      if (!resolved) {
        const baglam = vixrexBaglamsalCevapKarari(trimmed, {
          anahtar: alan.anahtar,
          etiket: alan.etiket,
          tip: alan.tip,
          eylem: pending.eylem,
        });

        if (baglam.karar === "iptal" || baglam.karar === "ayni_kalsin") {
          await clearPending();
          return { outcome: "needsClarification", message: baglam.mesaj };
        }

        if (!baglam.yazma) {
          if (baglam.karar === "kaldirma_onayi" && pending.eylem !== "kaldir") {
            await savePending(alan, "kaldir");
          }
          return {
            outcome: "needsClarification",
            message: baglam.mesaj,
            anahtar: alan.anahtar,
          };
        }

        if (needsSpecialFlow(alan.anahtar)) {
          return {
            outcome: "needsSpecialFlow",
            message: clarifyAsk(alan),
            anahtar: alan.anahtar,
          };
        }

        const pendingDeger = baglam.karar === "kaldir" ? null : baglam.deger ?? trimmed;
        const v = validateField(alan.anahtar, pendingDeger);
        if (!v.ok) {
          return {
            outcome: "needsClarification",
            message: (v as { hata: string }).hata,
            anahtar: alan.anahtar,
          };
        }
        await clearPending();
        const kesin = (v as { deger: unknown }).deger;
        return {
          outcome: "handled",
          message:
            baglam.karar === "kaldir"
              ? `${alan.etiket} bilgisini kaldırdım.`
              : clarifySuccess(alan, kesin ?? pendingDeger),
          anahtar: alan.anahtar,
          deger: kesin,
          tumu: [{ anahtar: alan.anahtar, kolon: alan.kolon, deger: kesin }],
        };
      }
    }
  }

  const all = resolveVixrexIntentsAll(trimmed);
  if (all.length === 0) {
    return { outcome: "notUnderstood", message: VIXREX_DOGAL_GENEL_SORU };
  }
  if (all.length > 1) {
    const ok: Array<{ alan: VixrexNiyetAlan; deger: unknown }> = [];
    const hatalar: string[] = [];
    for (const a of all) {
      if (needsSpecialFlow(a.anahtar)) { hatalar.push(`${a.etiket} için panelden devam et`); continue; }
      const ham = extractPipelineValue(trimmed, a);
      if (ham === null || ham === "") { hatalar.push(`${a.etiket} için değer bulunamadı`); continue; }
      const v = validateField(a.anahtar, ham);
      if (!v.ok) { hatalar.push((v as { hata: string }).hata); continue; }
      ok.push({ alan: a, deger: (v as { deger: unknown }).deger ?? ham });
    }

    // Çoklu niyette kısmi başarı güvenli değildir: kullanıcı iki alan
    // söylediyse birini sessizce atıp diğerini kaydetmek yerine tüm mesaj
    // netleştirilir. Böylece Flutter ile aynı "bir hata → hiçbir yazım" kuralı.
    if (ok.length === 0 || hatalar.length > 0) {
      return {
        outcome: "needsClarification",
        message: hatalar.join("\n") || VIXREX_DOGAL_GENEL_SORU,
      };
    }

    await clearPending();
    const metin = ok.map(({ alan, deger }) => clarifySuccess(alan, deger)).join("\n");
    return {
      outcome: "handled",
      message: metin,
      anahtar: ok[0].alan.anahtar,
      deger: ok[0].deger,
      tumu: ok.map(({ alan, deger }) => ({ anahtar: alan.anahtar, kolon: alan.kolon, deger })),
    };
  }
  const alan = all[0];
  if (needsSpecialFlow(alan.anahtar)) {
    await savePending(alan);
    return { outcome: "needsSpecialFlow", message: clarifyAsk(alan), anahtar: alan.anahtar };
  }
  const ham = extractPipelineValue(trimmed, alan);
  if (ham === null || ham === "") {
    await savePending(alan);
    return { outcome: "needsClarification", message: clarifyAsk(alan), anahtar: alan.anahtar };
  }
  const v = validateField(alan.anahtar, ham);
  if (!v.ok) return { outcome: "needsClarification", message: (v as { hata: string }).hata, anahtar: alan.anahtar };
  await clearPending();
  const kesinDeger = (v as { deger: unknown }).deger ?? ham;
  return {
    outcome: "handled",
    message: clarifySuccess(alan, kesinDeger),
    anahtar: alan.anahtar,
    deger: kesinDeger,
    tumu: [{ anahtar: alan.anahtar, kolon: alan.kolon, deger: kesinDeger }],
  };
}
