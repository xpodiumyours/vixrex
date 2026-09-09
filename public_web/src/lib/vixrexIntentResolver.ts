import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

interface NiyetAdayi {
  alan: VixrexNiyetAlan;
  normIfade: string;
  len: number;
}

/**
 * Eşleşmenin sıradan bir kelimenin ORTASINDAN başlamasını engeller.
 * Son sınırı katı değildir; Türkçe iyelik/hâl eki sözlük kökünü uzatabilir.
 * Uzun ve bağlamlı sözlük örnekleri kısa eş-anlamlardan önce değerlendirilir.
 */
function niyetBaslangicindaEslesir(normInput: string, normIfade: string): boolean {
  let from = 0;
  while (from <= normInput.length - normIfade.length) {
    const idx = normInput.indexOf(normIfade, from);
    if (idx < 0) return false;
    if (idx === 0 || !/[a-z0-9]/.test(normInput[idx - 1])) return true;
    from = idx + 1;
  }
  return false;
}

/**
 * `ornekIfadeler` artık yalnız dokümantasyon değildir.
 * `{deger}` içeren örneklerde değerden ÖNCEKİ sabit konuşma parçası bir
 * niyet kanıtıdır. Böylece sözlükte "Mağazamın adı {deger} olsun" yazıyorsa
 * motor gerçekten "Mağazamın adı ..." cümlesini tanımak zorundadır.
 *
 * Değeri sabit yazılmış örnekleri genel kalıp saymıyoruz; tek istisna değer
 * taşımayan `acikKapali` komutlarıdır ("Puanı gizle", "Navigasyonu kapat").
 */
function ornekNiyetIfadeleri(alan: VixrexNiyetAlan): string[] {
  const ifadeler: string[] = [];
  for (const ornek of alan.ornekIfadeler) {
    const marker = ornek.indexOf("{deger}");
    let sabit: string | null = null;
    if (marker >= 0) {
      sabit = ornek.slice(0, marker).replace(/[\s:,-]+$/g, "").trim();
    } else if (alan.tip === "acikKapali") {
      sabit = ornek.trim();
    }
    if (sabit) ifadeler.push(sabit);
  }
  return ifadeler;
}

function adaylariOlustur(): NiyetAdayi[] {
  const candidates: NiyetAdayi[] = [];
  for (const alan of VIXREX_NIYET_SOZLUGU) {
    const ifadeler = [...alan.esAnlamlar, ...ornekNiyetIfadeleri(alan)];
    const seen = new Set<string>();
    for (const ifade of ifadeler) {
      const normIfade = vixrexNormalizeDartParity(ifade).trim();
      if (!normIfade || seen.has(normIfade)) continue;
      seen.add(normIfade);
      candidates.push({ alan, normIfade, len: normIfade.length });
    }
  }
  // Daha bağlamlı/uzun ifade daima kısa ve genel eş-anlamdan önce gelir.
  candidates.sort((a, b) => b.len - a.len);
  return candidates;
}

// 46 alan sözlüğü üzerinden eş-anlam + sözlük örneği bulur.
// Dart VixrexIntentResolver ile aynı deterministik algoritma olmalı.
export function resolveVixrexIntent(input: string): VixrexNiyetAlan | null {
  const normInput = vixrexNormalizeDartParity(input);
  if (!normInput.trim()) return null;
  for (const c of adaylariOlustur()) {
    if (niyetBaslangicindaEslesir(normInput, c.normIfade)) return c.alan;
  }
  return null;
}

export function resolveVixrexIntentsAll(input: string): VixrexNiyetAlan[] {
  const normInput = vixrexNormalizeDartParity(input);
  const found: VixrexNiyetAlan[] = [];
  const seen = new Set<string>();
  for (const c of adaylariOlustur()) {
    if (seen.has(c.alan.anahtar)) continue;
    if (niyetBaslangicindaEslesir(normInput, c.normIfade)) {
      found.push(c.alan);
      seen.add(c.alan.anahtar);
    }
  }
  return found;
}
