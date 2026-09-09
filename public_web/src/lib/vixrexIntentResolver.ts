import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

/**
 * Eş-anlamın sıradan bir kelimenin ORTASINDAN yakalanmasını engeller.
 *
 * Son sınırı bilerek katı değil: Türkçede sözlük kökünün hemen ardından
 * iyelik/hâl eki gelebilir ("işletme adı" → "işletme adını",
 * "instagram" → "instagramımı"). Başlangıç ise gerçek kelime başlangıcı
 * olmalı; böylece kısa "il" eş-anlamı "ailece" içinden çıkmaz.
 */
function niyetBaslangicindaEslesir(normInput: string, normEa: string): boolean {
  let from = 0;
  while (from <= normInput.length - normEa.length) {
    const idx = normInput.indexOf(normEa, from);
    if (idx < 0) return false;
    if (idx === 0 || !/[a-z0-9]/.test(normInput[idx - 1])) return true;
    from = idx + 1;
  }
  return false;
}

// 46 alan sözlüğü üzerinden eş-anlam bulur – Dart VixrexIntentResolver ile aynı.
// Kural: en uzun eş-anlam önce + kelime başlangıcı zorunlu.
export function resolveVixrexIntent(input: string): VixrexNiyetAlan | null {
  const normInput = vixrexNormalizeDartParity(input);
  if (!normInput.trim()) return null;
  const candidates: Array<{ alan: VixrexNiyetAlan; normEa: string; len: number }> = [];
  for (const alan of VIXREX_NIYET_SOZLUGU) {
    for (const ea of alan.esAnlamlar) {
      const normEa = vixrexNormalizeDartParity(ea);
      if (!normEa.trim()) continue;
      candidates.push({ alan, normEa, len: normEa.length });
    }
  }
  candidates.sort((a, b) => b.len - a.len);
  for (const c of candidates) {
    if (niyetBaslangicindaEslesir(normInput, c.normEa)) return c.alan;
  }
  return null;
}

export function resolveVixrexIntentsAll(input: string): VixrexNiyetAlan[] {
  const normInput = vixrexNormalizeDartParity(input);
  const found: VixrexNiyetAlan[] = [];
  const seen = new Set<string>();
  const candidates: Array<{ alan: VixrexNiyetAlan; normEa: string; len: number }> = [];
  for (const alan of VIXREX_NIYET_SOZLUGU) {
    for (const ea of alan.esAnlamlar) {
      const normEa = vixrexNormalizeDartParity(ea);
      if (!normEa.trim()) continue;
      candidates.push({ alan, normEa, len: normEa.length });
    }
  }
  candidates.sort((a, b) => b.len - a.len);
  for (const c of candidates) {
    if (seen.has(c.alan.anahtar)) continue;
    if (niyetBaslangicindaEslesir(normInput, c.normEa)) {
      found.push(c.alan);
      seen.add(c.alan.anahtar);
    }
  }
  return found;
}
