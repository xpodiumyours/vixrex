import { VARSAYILAN_FATURA_PRESET } from "@/lib/faturaPresetSozlesmesi";

export const VARSAYILAN_PRIZ_ADRESI = "https://openrouter.ai/api/v1/chat/completions";

export function faturaPrizAdresi(): string {
  return (process.env.FATURA_PRIZ_URL || VARSAYILAN_PRIZ_ADRESI).trim();
}

export function faturaPrizAnahtari(): string {
  return (process.env.FATURA_PRIZ_API_KEY || process.env.OPENROUTER_API_KEY || "").trim();
}

export function faturaOkumaPresetReferansi(): string {
  const ham = (process.env.OPENROUTER_PRESET || process.env.OPENROUTER_FATURA_PRESET || VARSAYILAN_FATURA_PRESET).trim();
  return ham.startsWith("@preset/") ? ham : `@preset/${ham}`;
}

export function faturaPrizZamanSiniri(): number {
  const deger = Number(process.env.OPENROUTER_FATURA_TIMEOUT_MS ?? 240_000);
  return Number.isFinite(deger) && deger >= 30_000 && deger <= 900_000 ? deger : 240_000;
}

export function faturaPrizBasliklari(anahtar: string): Record<string, string> {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${anahtar}`,
    "HTTP-Referer": "https://vixrex.com",
    "X-Title": "Vixrex Fatura",
  };
}

export async function faturaPrizIstegiGonder(govde: Record<string, unknown>): Promise<Response> {
  const anahtar = faturaPrizAnahtari();
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  try {
    return await fetch(faturaPrizAdresi(), {
      method: "POST",
      headers: faturaPrizBasliklari(anahtar),
      body: JSON.stringify(govde),
      signal: AbortSignal.timeout(faturaPrizZamanSiniri()),
    });
  } catch (hata) {
    if (hata instanceof Error && ["TimeoutError", "AbortError"].includes(hata.name)) {
      throw new Error("OKUYUCU_ZAMAN_ASIMI");
    }
    throw new Error("OKUYUCU_CEVAP_VERMEDI", { cause: hata });
  }
}