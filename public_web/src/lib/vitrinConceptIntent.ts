import { resolveVixrexIntentsAll } from "./vixrexIntentResolver";
import {
  VITRIN_CONCEPTS,
  type VitrinConceptMeta,
} from "./vitrinFieldSchema";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

const KAVRAM_SON_EKLERI = new Set([
  "", "i", "u", "a", "e", "ni", "nu", "na", "ne",
  "de", "da", "den", "dan", "le", "la",
]);

function sonTokenEslesir(girdi: string, kok: string): boolean {
  if (girdi === kok) return true;
  if (!girdi.startsWith(kok)) return false;
  return KAVRAM_SON_EKLERI.has(girdi.slice(kok.length));
}

const DUZENLEME_EYLEM_KOKLERI = [
  "duzenl", "degistir", "guncell", "ayarla", "goster", "ekle", "duzelt", "yenile", "bak",
] as const;

function duzenlemeEylemiVarMi(tokenlar: readonly string[]): boolean {
  return tokenlar.some(
    (token) =>
      token === "ac" ||
      DUZENLEME_EYLEM_KOKLERI.some((kok) => token.startsWith(kok)),
  );
}

function ifadeVarMi(input: string, ifade: string): boolean {
  const metin = vixrexNormalizeDartParity(input)
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  const aranan = vixrexNormalizeDartParity(ifade)
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  if (aranan.length === 0 || aranan.length > metin.length) return false;
  if (aranan.length === 1 && metin.length > 1 && !duzenlemeEylemiVarMi(metin)) {
    return false;
  }

  for (let baslangic = 0; baslangic <= metin.length - aranan.length; baslangic += 1) {
    let uyuyor = true;
    for (let i = 0; i < aranan.length; i += 1) {
      const son = i === aranan.length - 1;
      const eslesti = son
        ? sonTokenEslesir(metin[baslangic + i], aranan[i])
        : metin[baslangic + i] === aranan[i];
      if (!eslesti) {
        uyuyor = false;
        break;
      }
    }
    if (uyuyor) return true;
  }
  return false;
}

export function resolveVitrinConceptIntent(input: string): VitrinConceptMeta | null {
  if (!input.trim()) return null;
  if (resolveVixrexIntentsAll(input).length > 0) return null;

  const adaylar = VITRIN_CONCEPTS.flatMap((kavram) =>
    kavram.esAnlamlar.map((ifade) => ({ kavram, ifade })),
  ).sort((a, b) => b.ifade.length - a.ifade.length);

  for (const aday of adaylar) {
    if (ifadeVarMi(input, aday.ifade)) return aday.kavram;
  }
  return null;
}

export function vitrinConceptPrompt(kavram: VitrinConceptMeta): string {
  return kavram.soru;
}
