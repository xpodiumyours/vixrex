import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

interface NiyetAdayi {
  alan: VixrexNiyetAlan;
  normIfade: string;
  len: number;
}

interface NiyetEslesmesi {
  start: number;
  end: number;
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// Türkçede "dükkan adı" doğal konuşmada "dükkanın adı",
// "ürün başlığı" -> "ürünlerin başlığı" biçimine dönebilir. Yalnız
// çok kelimeli ifadelerin ARA kelimelerinde ve kök >=4 harfse dar bir
// iyelik/genitif/plural-genitif listesine izin verilir. "il", "tel", "ig"
// gibi kısa kökler bu genişlemeye girmez.
const ARA_ISIM_EKI =
  "(?:m|im|um|in|un|min|mun|imin|umun|nin|nun|imiz|umuz|iniz|unuz|imizin|umuzun|inizin|unuzun|larin|lerin)?";

const KISA_KOK_SINIRI = 3;
const KISA_KOK_EKI =
  /^(?:i|u|e|a|in|un|im|um|de|da|den|dan|te|ta|ten|tan|ini|ine|inde|inden|imi|ime|imde|imden|iniz|imiz|ler|lar|leri|lari|lerin|larin|lere|lara|lerde|larda|lerden|lardan)$/;

function kisaKokSonEkiGecerliMi(normInput: string, normIfade: string, end: number): boolean {
  if (normIfade.length > KISA_KOK_SINIRI || /\s/.test(normIfade)) return true;
  const kalan = normInput.slice(end).match(/^[a-z0-9]*/)?.[0] ?? "";
  return kalan === "" || KISA_KOK_EKI.test(kalan);
}

function ortusuyorMu(aday: NiyetEslesmesi, dolu: ReadonlyArray<NiyetEslesmesi>): boolean {
  return dolu.some((d) => aday.start < d.end && aday.end > d.start);
}

function tamIfadeEslesmesiBul(
  normInput: string,
  normIfade: string,
  doluAraliklar: ReadonlyArray<NiyetEslesmesi>,
): NiyetEslesmesi | null {
  let from = 0;
  while (from <= normInput.length - normIfade.length) {
    const idx = normInput.indexOf(normIfade, from);
    if (idx < 0) return null;
    const startOk = idx === 0 || !/[a-z0-9]/.test(normInput[idx - 1]);
    const aday = { start: idx, end: idx + normIfade.length };
    const sonEkOk = kisaKokSonEkiGecerliMi(normInput, normIfade, aday.end);
    if (startOk && sonEkOk && !ortusuyorMu(aday, doluAraliklar)) return aday;
    from = idx + 1;
  }
  return null;
}

function ekliCokKelimeEslesmesiBul(
  normInput: string,
  normIfade: string,
  doluAraliklar: ReadonlyArray<NiyetEslesmesi>,
): NiyetEslesmesi | null {
  const tokens = normIfade.split(/\s+/).filter(Boolean);
  if (tokens.length < 2) return null;

  const body = tokens
    .map((token, i) => {
      const kok = escapeRegExp(token);
      if (i < tokens.length - 1 && /^[a-z0-9]+$/.test(token) && token.length >= 4) {
        return `${kok}${ARA_ISIM_EKI}`;
      }
      return kok;
    })
    .join("\\s+");

  const re = new RegExp(`(^|[^a-z0-9])(${body})`, "g");
  let m: RegExpExecArray | null;
  while ((m = re.exec(normInput)) !== null) {
    const start = m.index + m[1].length;
    const aday = { start, end: start + m[2].length };
    if (!ortusuyorMu(aday, doluAraliklar)) return aday;
    if (m[0].length === 0) re.lastIndex += 1;
  }
  return null;
}

/**
 * Eşleşmenin sıradan bir kelimenin ORTASINDAN başlamasını engeller.
 * Önce bit-identical düz eşleşme denenir; yalnız o yoksa kontrollü Türkçe
 * iyelik/genitif varyasyonu denenir. Böylece eski davranış önceliğini korur.
 */
function niyetEslesmesiBul(
  normInput: string,
  normIfade: string,
  doluAraliklar: ReadonlyArray<NiyetEslesmesi> = [],
): NiyetEslesmesi | null {
  return (
    tamIfadeEslesmesiBul(normInput, normIfade, doluAraliklar) ??
    ekliCokKelimeEslesmesiBul(normInput, normIfade, doluAraliklar)
  );
}

/**
 * `{deger}` içeren örneklerde değerden ÖNCEKİ sabit konuşma parçası niyet
 * kanıtıdır. Değeri sabit yazılmış örnekleri genel kalıp saymıyoruz; tek
 * istisna değer taşımayan `acikKapali` komutlarıdır.
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
  candidates.sort((a, b) => b.len - a.len);
  return candidates;
}

export function resolveVixrexIntent(input: string): VixrexNiyetAlan | null {
  const normInput = vixrexNormalizeDartParity(input);
  if (!normInput.trim()) return null;
  for (const c of adaylariOlustur()) {
    if (niyetEslesmesiBul(normInput, c.normIfade)) return c.alan;
  }
  return null;
}

export function resolveVixrexIntentsAll(input: string): VixrexNiyetAlan[] {
  const normInput = vixrexNormalizeDartParity(input);
  const found: VixrexNiyetAlan[] = [];
  const seen = new Set<string>();
  const doluAraliklar: NiyetEslesmesi[] = [];

  for (const c of adaylariOlustur()) {
    if (seen.has(c.alan.anahtar)) continue;
    const eslesme = niyetEslesmesiBul(normInput, c.normIfade, doluAraliklar);
    if (!eslesme) continue;

    found.push(c.alan);
    seen.add(c.alan.anahtar);
    doluAraliklar.push(eslesme);
  }
  return found;
}
