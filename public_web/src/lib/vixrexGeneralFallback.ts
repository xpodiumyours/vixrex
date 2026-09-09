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

function payloadBul(input: string): string | null {
  const normalized = vixrexNormalizeDartParity(input);
  if (!normalized.trim()) return null;

  // Flutter ChatbotService.respond ile aynı sıra ve aynı contains davranışı.
  for (const intent of vixRexIntentSemasi) {
    for (const keyword of intent.anahtarKelimeler) {
      if (normalized.includes(vixrexNormalizeDartParity(keyword))) {
        return intent.payload;
      }
    }
  }
  return null;
}

function tabloMesaji(payload: string): string | null {
  const yanit = vixRexYanitlar.get(payload);
  if (!yanit) return null;
  return vixRexMesajlari[yanit.mesaj] ?? null;
}

/**
 * 46-alan NLU bir alan komutu bulamadığında Flutter'ın eski ChatbotService
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
  const payload = payloadBul(input);
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
