import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

// 46 alan sözlüğü üzerinden esAnlamlar contains ile alan bulur – Dart VixrexIntentResolver ile aynı.
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
    if (normInput.includes(c.normEa)) return c.alan;
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
      candidates.push({ alan, normEa: vixrexNormalizeDartParity(ea), len: vixrexNormalizeDartParity(ea).length });
    }
  }
  candidates.sort((a, b) => b.len - a.len);
  for (const c of candidates) {
    if (seen.has(c.alan.anahtar)) continue;
    if (normInput.includes(c.normEa)) {
      found.push(c.alan);
      seen.add(c.alan.anahtar);
    }
  }
  return found;
}
