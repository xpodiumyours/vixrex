import {
  PRODUCT_ATTRIBUTE_SCHEMA,
  getProductProfileDefinition,
  type ProductRichMetadata,
  type ProductVariantData,
  type RichAttributeValue,
} from "@/lib/productRichData";

interface Props {
  brand?: string | null;
  barcode?: string | null;
  stockQuantity?: number | null;
  metadata?: ProductRichMetadata;
  variants?: ProductVariantData[];
}

function displayValue(value: RichAttributeValue | undefined): string {
  if (Array.isArray(value)) return value.join(", ");
  if (typeof value === "boolean") return value ? "Evet" : "Hayır";
  if (value == null) return "";
  return String(value);
}

export default function ProductRichDetails({
  brand,
  barcode,
  stockQuantity,
  metadata = {},
  variants = [],
}: Props) {
  const profile = getProductProfileDefinition(metadata.profileKey);
  const facts: Array<{ label: string; value: string }> = [];

  if (brand) facts.push({ label: "Marka", value: brand });
  if (stockQuantity != null) facts.push({ label: "Stok adedi", value: `${stockQuantity} adet` });
  if (barcode) facts.push({ label: "Barkod / GTIN", value: barcode });
  if (metadata.identifiers?.sku) facts.push({ label: "SKU", value: metadata.identifiers.sku });
  if (metadata.identifiers?.mpn) facts.push({ label: "MPN", value: metadata.identifiers.mpn });

  for (const fieldKey of profile?.fields ?? []) {
    if (["brand", "barcode", "sku", "mpn"].includes(fieldKey)) continue;
    const definition = PRODUCT_ATTRIBUTE_SCHEMA.fields[fieldKey];
    if (!definition) continue;

    let value = "";
    if (definition.storage.startsWith("metadata.attributes.")) {
      value = displayValue(metadata.attributes?.[fieldKey]);
    } else if (definition.storage.startsWith("metadata.service.")) {
      const serviceKey = definition.storage.split(".").at(-1);
      const raw = serviceKey
        ? (metadata.service as Record<string, unknown> | undefined)?.[serviceKey]
        : undefined;
      if (typeof raw === "boolean") value = raw ? "Evet" : "Hayır";
      else if (typeof raw === "number" || typeof raw === "string") value = String(raw);
    }
    if (value) facts.push({ label: definition.label, value });
  }

  if (facts.length === 0 && variants.length === 0) return null;

  return (
    <section className="mx-auto mt-5 w-full max-w-[1080px] rounded-[24px] border border-white/8 bg-[#15171c] p-5 sm:p-6">
      <h2 className="text-lg font-extrabold text-white">Ürün detayları</h2>

      {facts.length > 0 ? (
        <dl className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {facts.map((fact) => (
            <div key={`${fact.label}-${fact.value}`} className="rounded-2xl border border-white/8 bg-[#1c1f27] p-4">
              <dt className="text-[11px] font-bold uppercase tracking-wide text-white/40">{fact.label}</dt>
              <dd className="mt-1 break-words text-sm font-bold leading-6 text-white/80">{fact.value}</dd>
            </div>
          ))}
        </dl>
      ) : null}

      {variants.length > 0 ? (
        <div className="mt-6 border-t border-white/8 pt-5">
          <h3 className="text-sm font-extrabold text-white">Seçenekler</h3>
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            {variants.map((variant) => (
              <div key={variant.id} className="rounded-2xl border border-white/8 bg-[#1c1f27] p-4">
                <div className="flex flex-wrap gap-2">
                  {Object.entries(variant.options).map(([key, value]) => (
                    <span key={key} className="rounded-lg border border-white/10 bg-white/5 px-2.5 py-1 text-xs font-bold text-white/75">
                      {PRODUCT_ATTRIBUTE_SCHEMA.fields[key]?.label ?? key}: {value}
                    </span>
                  ))}
                </div>
                <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-white/55">
                  {variant.priceAmount != null ? <span>Fiyat: {variant.priceAmount} TL</span> : null}
                  {variant.stockQuantity != null ? <span>Stok: {variant.stockQuantity}</span> : null}
                  {variant.stockStatus ? <span>{variant.stockStatus}</span> : null}
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : null}
    </section>
  );
}
