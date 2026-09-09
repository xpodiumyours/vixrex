import {
  vixRexIntentSemasi,
  vixRexMesajlari,
  vixRexYanitlar,
} from "./vixrexMesajlari";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

export interface VixrexGeneralFallbackContext {
  /** Yalnız kesin biliniyorsa verilir. Bilinmiyorsa yayın durumuna göre cevap uydurulmaz. */
  isPublished?: boolean;
}

export interface VixrexGeneralFallbackResult {
  payload: string;
  message: string;
}

function kelimeBaslangicindaVarMi(input: string, keyword: string): boolean {
  let from = 0;
  while (from <= input.length - keyword.length) {
    const idx = input.indexOf(keyword, from);
    if (idx < 0) return false;
    if (idx === 0 || !/[a-z0-9]/.test(input[idx - 1])) return true;
    from = idx + 1;
  }
  return false;
}

/**
 * Genel rehber niyetinde kısa/genel kelime daha uzun ve özgül ifadeyi
 * ezemez. Örn. "XML ile toplu ürün yükle" hem "yükle" (fotoğraf) hem
 * "toplu urun" (XML) içerir; en uzun kanıt XML'i seçer.
 * Eşit uzunlukta eski katalog sırası korunur.
 */
export function resolveVixrexGeneralIntent(input: string): string | null {
  const normalized = vixrexNormalizeDartParity(input);
  if (!normalized.trim()) return null;

  let bestPayload: string | null = null;
  let bestLength = -1;

  for (const intent of vixRexIntentSemasi) {
    for (const keyword of intent.anahtarKelimeler) {
      const normalizedKeyword = vixrexNormalizeDartParity(keyword).trim();
      if (!normalizedKeyword) continue;
      if (!kelimeBaslangicindaVarMi(normalized, normalizedKeyword)) continue;
      if (normalizedKeyword.length > bestLength) {
        bestLength = normalizedKeyword.length;
        bestPayload = intent.payload;
      }
    }
  }

  return bestPayload;
}

function tabloMesaji(payload: string): string | null {
  const yanit = vixRexYanitlar.get(payload);
  if (!yanit) return null;
  return vixRexMesajlari[yanit.mesaj] ?? null;
}

/**
 * 46-alan NLU bir alan komutu bulamadığında Flutter'ın ChatbotService
 * rehberine denk gelen API/LLM'siz bilgi cevabını üretir.
 *
 * Dinamik snapshot isteyen dallarda tahmin YASAK:
 * - merhaba: yayınlı vitrinde Flutter kişiselleştirilmiş snapshot mesajı üretir.
 * - qr: yayın durumuna göre iki ayrı cevap vardır.
 * Gerekli durum kesin verilmediyse null döner ve çağıran doğal genel sorusunu
 * korur.
 */
export function vixrexGeneralFallback(
  input: string,
  context: VixrexGeneralFallbackContext = {},
): VixrexGeneralFallbackResult | null {
  const payload = resolveVixrexGeneralIntent(input);
  if (!payload) return null;

  if (payload === "merhaba") return null;

  if (payload === "qr") {
    if (typeof context.isPublished !== "boolean") return null;
    const tableKey = context.isPublished ? "qr_yayinda" : "qr_yayinda_degil";
    const message = tabloMesaji(tableKey);
    return message ? { payload, message } : null;
  }

  if (
    payload === "vixrex_info" ||
    payload === "membership_info" ||
    payload === "vitrin_kurulum" ||
    payload === "ocr_premium"
  ) {
    const message = vixRexMesajlari[payload] ?? null;
    return message ? { payload, message } : null;
  }

  const message = tabloMesaji(payload);
  return message ? { payload, message } : null;
}
