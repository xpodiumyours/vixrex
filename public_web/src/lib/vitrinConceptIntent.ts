import { resolveVixrexIntentsAll } from "./vixrexIntentResolver";
import {
  VITRIN_CONCEPTS,
  type VitrinConceptMeta,
} from "./vitrinFieldSchema";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

function ifadeVarMi(input: string, ifade: string): boolean {
  const metin = ` ${vixrexNormalizeDartParity(input).replace(/[^a-z0-9]+/g, " ").trim()} `;
  const aranan = ` ${vixrexNormalizeDartParity(ifade).replace(/[^a-z0-9]+/g, " ").trim()} `;
  return aranan.trim().length > 0 && metin.includes(aranan);
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
