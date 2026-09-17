import { requiredProductAttributes } from "./productAttributeSchema";
import { normalizeProductMetadata, normalizeProductVariants } from "./productRichData";

export interface EksikZorunluAlan {
  key: string;
  label: string;
}

function doluMu(value: unknown): boolean {
  if (Array.isArray(value)) return value.some((item) => String(item ?? "").trim().length > 0);
  if (typeof value === "string") return value.trim().length > 0;
  if (typeof value === "number") return Number.isFinite(value);
  if (typeof value === "boolean") return true;
  return false;
}

export function eksikZorunluAlanlar(args: {
  templateKey: string | null | undefined;
  brand?: string | null;
  metadata?: unknown;
  variants?: unknown;
}): EksikZorunluAlan[] {
  const metadata = normalizeProductMetadata(args.metadata);
  const service = (metadata.service ?? {}) as Record<string, unknown>;
  const variants = normalizeProductVariants(args.variants);
  const eksikler: EksikZorunluAlan[] = [];

  for (const definition of requiredProductAttributes(args.templateKey)) {
    let value: unknown;
    if (definition.storage === "core.brand") {
      value = args.brand;
    } else if (definition.storage.startsWith("metadata.service.")) {
      value = service[definition.storage.slice("metadata.service.".length)];
    } else {
      value = metadata.attributes?.find((item) => item.key === definition.key)?.value;
    }
    if (doluMu(value)) continue;

    // Renk/beden gibi alanlar varyanttan da girilebiliyor; orada doluysa
    // esnafa ikinci kez sordurmuyoruz.
    const varyanttaDolu =
      definition.variantEligible === true &&
      variants.some((variant) => doluMu(variant.options?.[definition.key]));
    if (varyanttaDolu) continue;

    eksikler.push({ key: definition.key, label: definition.label });
  }

  return eksikler;
}

export function eksikZorunluAlanMesaji(eksikler: EksikZorunluAlan[]): string | null {
  if (eksikler.length === 0) return null;
  const alanlar = eksikler.map((eksik) => eksik.label).join(", ");
  return eksikler.length === 1
    ? `${alanlar} alanı zorunludur.`
    : `Şu alanlar zorunludur: ${alanlar}.`;
}
