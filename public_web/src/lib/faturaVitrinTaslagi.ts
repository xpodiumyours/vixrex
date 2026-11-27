export interface FaturaAliciBilgisi {
  ad?: string | null;
  adres?: string | null;
  il?: string | null;
  ilce?: string | null;
}

const IBAN_DESENI = /\bTR\s*(?:\d\s*){24}\b/gi;
const KIMLIK_VKN_DESENI = /\b\d{10,11}\b/g;
const HASSAS_ETIKET_DESENI =
  /\b(?:vkn|tckn|tc\s*kimlik|vergi\s*no|iban|ettn|fatura\s*no|iskonto|vade)\s*[:：-]?\s*[^\s,;]+/gi;

export function faturaAliciMetniniTemizle(metin: string | null | undefined): string {
  if (!metin || typeof metin !== "string") return "";
  return metin
    .replace(IBAN_DESENI, "")
    .replace(HASSAS_ETIKET_DESENI, "")
    .replace(KIMLIK_VKN_DESENI, "")
    .replace(/\s{2,}/g, " ")
    .replace(/^[\s,;-]+|[\s,;-]+$/g, "")
    .trim();
}

export function faturaAlicidanVitrinTaslagiUret(
  mevcutTaslak: Record<string, unknown>,
  alici: FaturaAliciBilgisi | null | undefined,
): Record<string, unknown> {
  const sonuc: Record<string, unknown> = { ...mevcutTaslak };
  if (!alici) return sonuc;

  const eslesmeler: Array<[string, string | null | undefined]> = [
    ["name", alici.ad],
    ["address", alici.adres],
    ["province_name", alici.il],
    ["district_name", alici.ilce],
  ];

  for (const [hedefAlan, hamDeger] of eslesmeler) {
    const mevcutDeger = sonuc[hedefAlan];
    if (typeof mevcutDeger === "string" && mevcutDeger.trim().length > 0) {
      continue;
    }
    const temiz = faturaAliciMetniniTemizle(hamDeger);
    if (temiz.length > 0) {
      sonuc[hedefAlan] = temiz;
    }
  }

  return sonuc;
}
