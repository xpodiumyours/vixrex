import {
  productAttributesForSurface,
  productAttributesForTemplate,
  productTemplateByKey,
} from "./productAttributeSchema";
import {
  normalizeProductMetadata,
  normalizeProductVariants,
  type ProductAttributeValue,
  type ProductVariant,
} from "./productRichData";
import { kategoriBirlestir } from "./kategoriBirlesim";
import { normalizeGoogleGtin } from "./productStructuredData";
import { ilIlceCikar } from "./turkeyPlaceMatcher";

export interface ProductQuickFact {
  key: string;
  label: string;
  value: string;
}

export interface ProductVariantOptionGroup {
  key: string;
  label: string;
  values: string[];
}

export function productPhotoCountBadge(imageCount: number): string | null {
  if (imageCount <= 1) return null;
  return `1/${imageCount}`;
}

function formatAttributeValue(value: ProductAttributeValue["value"], unit?: string) {
  const formatted = Array.isArray(value)
    ? value.join(", ")
    : typeof value === "boolean"
      ? value
        ? "Evet"
        : "Hayır"
      : String(value);
  return unit ? `${formatted} ${unit}` : formatted;
}

function tuketiciMetni(value: string): string {
  return value
    .replace(/\s*\((varsayılan|varsayilan)\)\s*$/iu, "")
    .replace(/(\d)\s*gr\b/giu, "$1 g")
    .replace(/(\d)\s*lt\b/giu, "$1 L")
    .trim();
}

const PRICE_MODE_LABELS = {
  fixed: "Sabit fiyat",
  starting_from: "Başlangıç fiyatı",
  ask: "Fiyat sor",
} as const;

const SERVICE_LOCATION_LABELS = {
  business: "İşletmede",
  customer: "Müşteri adresinde",
  remote: "Uzaktan",
} as const;

const CONDITION_LABELS: Record<string, string> = {
  new: "Yeni",
  used: "Kullanılmış",
  refurbished: "Yenilenmiş",
};

function serviceFacts(metadata: ReturnType<typeof normalizeProductMetadata>, detail = false) {
  const facts: ProductQuickFact[] = [];
  const service = metadata.service;
  if (!service) return facts;

  if (service.serviceType) {
    facts.push({ key: "serviceType", label: "Hizmet türü", value: service.serviceType });
  }
  if (service.priceMode) {
    facts.push({ key: "priceMode", label: "Fiyat biçimi", value: PRICE_MODE_LABELS[service.priceMode] });
  }
  if (service.durationMinutes != null) {
    facts.push({ key: "durationMinutes", label: "Tahmini süre", value: `${service.durationMinutes} dk` });
  }
  if (service.serviceLocation) {
    facts.push({
      key: "serviceLocation",
      label: "Hizmet yeri",
      value: SERVICE_LOCATION_LABELS[service.serviceLocation],
    });
  }
  if (detail && service.appointmentRequired != null) {
    facts.push({
      key: "appointmentRequired",
      label: "Randevu gerekli",
      value: service.appointmentRequired ? "Evet" : "Hayır",
    });
  }
  if (detail && service.included?.length) {
    facts.push({
      key: "included",
      label: "Hizmete dahil olanlar",
      value: service.included.join(", "),
    });
  }
  return facts;
}

const KURAL32_HASSAS_ANAHTARLAR = new Set([
  "vergino",
  "vergi_no",
  "verginumarasi",
  "vkn",
  "tckn",
  "taxid",
  "tax_id",
  "tedarikcivergino",
  "suppliertaxid",
  "supplier_tax_id",
  "alisfiyati",
  "alis_fiyati",
  "alisbirimfiyat",
  "alisbirimfiyati",
  "alistutari",
  "faturaalisfiyati",
  "purchaseprice",
  "purchase_price",
  "purchasepriceamount",
  "purchase_price_amount",
  "toptanfiyat",
  "toptan_fiyat",
  "toptanalisfiyati",
  "wholesaleprice",
  "wholesale_price",
  "tedarikcifiyati",
  "iban",
  "iskonto",
  "discount",
  "ettn",
  "faturano",
  "fatura_no",
  "invoiceno",
  "invoice_no",
  "tckimlikno",
  "tc_kimlik_no",
  "tcno",
  "tc_no",
  "maliyet",
  "costprice",
  "cost_price",
]);

const KURAL32_HASSAS_ETIKET_DESENLERI = [
  "vkn",
  "tckn",
  "vergi no",
  "vergi numara",
  "alis fiyat",
  "toptan fiyat",
  "toptan alis",
  "fatura alis",
  "purchase price",
  "wholesale price",
  "tax id",
  "iban",
  "iskonto",
  "discount",
  "ettn",
  "fatura no",
  "maliyet",
];

function kural32NormalizeMetin(deger: string): string {
  return deger
    .toLocaleLowerCase("tr-TR")
    .replace(/ı/g, "i")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "");
}

export function kural32HassasAlanMi(
  key: string,
  label: string | undefined,
  hasDefinition: boolean,
): boolean {
  const temizAnahtar = kural32NormalizeMetin(key).replace(/[^a-z0-9_]/g, "");
  const altCizgisiz = temizAnahtar.replace(/_/g, "");
  if (
    KURAL32_HASSAS_ANAHTARLAR.has(temizAnahtar) ||
    KURAL32_HASSAS_ANAHTARLAR.has(altCizgisiz)
  ) {
    return true;
  }
  if (!hasDefinition && altCizgisiz === "unitprice") {
    return true;
  }
  const temizEtiket = kural32NormalizeMetin(String(label || ""));
  return KURAL32_HASSAS_ETIKET_DESENLERI.some((desen) => temizEtiket.includes(desen));
}

function metadataAttributeFacts(args: {
  metadata: ReturnType<typeof normalizeProductMetadata>;
  surface: "card" | "quick" | "detail";
  existingKeys: Set<string>;
}) {
  const definitions = productAttributesForSurface(args.metadata.templateKey, args.surface);
  const definitionByKey = new Map(definitions.map((definition) => [definition.key, definition]));
  const facts: ProductQuickFact[] = [];

  for (const attribute of args.metadata.attributes || []) {
    if (args.existingKeys.has(attribute.key)) continue;
    if (
      args.surface !== "detail" &&
      (attribute.key.endsWith("_reported") || String(attribute.label || "").includes("(aktarılan)"))
    ) {
      continue;
    }
    const definition = definitionByKey.get(attribute.key);
    if (kural32HassasAlanMi(attribute.key, attribute.label || definition?.label, Boolean(definition))) {
      continue;
    }
    if (!definition && !args.metadata.lunaInvoice) continue;
    const rawValue = formatAttributeValue(attribute.value, attribute.unit);
    const okunur = Array.isArray(attribute.value)
      ? attribute.value
          .map((item) => definition?.optionLabels?.[String(item)] ?? String(item))
          .join(", ")
      : definition?.optionLabels?.[rawValue] ?? CONDITION_LABELS[rawValue] ?? rawValue;
    const deger =
      attribute.key === "category"
        ? kategoriBirlestir(okunur).ad || okunur
        : tuketiciMetni(okunur);
    facts.push({
      key: attribute.key,
      label: attribute.label || definition?.label || attribute.key,
      value: deger,
    });
  }
  return facts;
}

export function buildProductQuickFacts(args: {
  brand?: string | null;
  metadata?: unknown;
  limit?: number;
}): ProductQuickFact[] {
  const metadata = normalizeProductMetadata(args.metadata);
  const limit = Math.max(0, args.limit ?? 4);
  const facts: ProductQuickFact[] = [];

  const brand = String(args.brand || "").trim();
  if (brand && metadata.itemKind !== "service") {
    facts.push({ key: "brand", label: "Marka", value: brand });
  }

  if (metadata.itemKind === "service") {
    facts.push(...serviceFacts(metadata));
  }

  facts.push(
    ...metadataAttributeFacts({
      metadata,
      surface: "quick",
      existingKeys: new Set(facts.map((fact) => fact.key)),
    }),
  );

  return facts.slice(0, limit);
}

export function buildProductDetailFacts(args: {
  brand?: string | null;
  barcode?: string | null;
  metadata?: unknown;
}): ProductQuickFact[] {
  const metadata = normalizeProductMetadata(args.metadata);
  const facts: ProductQuickFact[] = [];

  if (metadata.itemKind === "service") {
    facts.push(...serviceFacts(metadata, true));
    facts.push(
      ...metadataAttributeFacts({
        metadata,
        surface: "detail",
        existingKeys: new Set(facts.map((fact) => fact.key)),
      }),
    );
    return facts;
  }

  const brand = String(args.brand || "").trim();
  const barcode = String(args.barcode || "").trim();
  if (brand) {
    facts.push({ key: "brand", label: "Marka", value: brand });
  }
  if (barcode) {
    facts.push({ key: "barcode", label: "Barkod / GTIN", value: barcode });
  }
  if (metadata.identifiers?.sku) {
    facts.push({ key: "sku", label: "Stok kodu / SKU", value: metadata.identifiers.sku });
  }
  if (metadata.identifiers?.mpn) {
    facts.push({ key: "mpn", label: "Üretici parça kodu / MPN", value: metadata.identifiers.mpn });
  }

  facts.push(
    ...metadataAttributeFacts({
      metadata,
      surface: "detail",
      existingKeys: new Set(facts.map((fact) => fact.key)),
    }),
  );

  return facts;
}

const TUKETICI_GIZLI_ANAHTARLAR = new Set(["barcode", "sku", "mpn"]);

export function buildConsumerDetailFacts(args: {
  brand?: string | null;
  barcode?: string | null;
  metadata?: unknown;
}): ProductQuickFact[] {
  const facts = buildProductDetailFacts(args).filter(
    (fact) => !TUKETICI_GIZLI_ANAHTARLAR.has(fact.key) && !fact.label.includes("(aktarılan)"),
  );
  const miktarDegerleri = new Set(
    facts
      .filter((fact) => fact.key === "netQuantity" || fact.key === "size")
      .map((fact) => fact.value),
  );
  return facts.filter(
    (fact) => !(fact.key === "variant" && miktarDegerleri.has(fact.value)),
  );
}

export function productVariantsForTemplate(
  value: unknown,
  templateKey?: string | null,
  lunaInvoice = false,
): ProductVariant[] {
  const variants = normalizeProductVariants(value, lunaInvoice);
  if (lunaInvoice) return variants;
  const template = productTemplateByKey(templateKey);
  if (!template) return [];

  const variantDefinitions = productAttributesForTemplate(templateKey).filter(
    (definition) => definition.variantEligible,
  );
  if (variantDefinitions.length === 0) return variants;

  const allowedKeys = new Set(variantDefinitions.map((definition) => definition.key));
  return variants
    .map((variant) => ({
      ...variant,
      options: Object.fromEntries(
        Object.entries(variant.options).filter(
          ([key, optionValue]) => allowedKeys.has(key) && optionValue.trim().length > 0,
        ),
      ),
    }))
    .filter((variant) => Object.keys(variant.options).length > 0);
}

export function buildVariantOptionFacts(value: unknown, templateKey?: string | null, lunaInvoice = false): ProductQuickFact[] {
  return buildVariantOptionGroups(value, templateKey, lunaInvoice).map((group) => ({
    key: `variant:${group.key}`,
    label: group.label,
    value: group.values.join(", "),
  }));
}

export function buildVariantOptionGroups(
  value: unknown,
  templateKey?: string | null,
  lunaInvoice = false,
): ProductVariantOptionGroup[] {
  const variants = productVariantsForTemplate(value, templateKey, lunaInvoice);
  const valuesByKey = new Map<string, Set<string>>();
  const definitions = productAttributesForTemplate(templateKey).filter(
    (definition) => definition.variantEligible,
  );
  const definitionByKey = new Map(definitions.map((definition) => [definition.key, definition]));

  for (const variant of variants) {
    for (const [key, optionValue] of Object.entries(variant.options)) {
      const values = valuesByKey.get(key) ?? new Set<string>();
      values.add(optionValue);
      valuesByKey.set(key, values);
    }
  }

  return Array.from(valuesByKey.entries()).map(([key, values]) => ({
    key,
    label: definitionByKey.get(key)?.label || key,
    values: Array.from(values),
  }));
}

export function findMatchingVariant(
  value: unknown,
  selectedOptions: Record<string, string>,
  templateKey?: string | null,
  lunaInvoice = false,
): ProductVariant | null {
  const variants = productVariantsForTemplate(value, templateKey, lunaInvoice);
  const selectedEntries = Object.entries(selectedOptions).filter(([, optionValue]) => optionValue);
  if (!selectedEntries.length) return variants[0] ?? null;
  return (
    variants.find((variant) =>
      selectedEntries.every(([key, optionValue]) => variant.options[key] === optionValue),
    ) ?? null
  );
}

export function variantOptionIsAvailable(
  value: unknown,
  selectedOptions: Record<string, string>,
  optionKey: string,
  optionValue: string,
  templateKey?: string | null,
  lunaInvoice = false,
): boolean {
  const variants = productVariantsForTemplate(value, templateKey, lunaInvoice);
  return variants.some((variant) => {
    if (variant.options[optionKey] !== optionValue) return false;
    return Object.entries(selectedOptions).every(([key, selectedValue]) => {
      if (!selectedValue || key === optionKey) return true;
      return variant.options[key] === selectedValue;
    });
  });
}

export function productVariantCount(value: unknown, templateKey?: string | null): number {
  return productVariantsForTemplate(value, templateKey).length;
}

export function productVariantLabel(value: unknown, templateKey?: string | null): string | null {
  const count = productVariantCount(value, templateKey);
  return count > 1 ? `${count} seçenek` : null;
}

export interface ProductCardOfficialSource {
  url: string;
  alanAdi: string;
}

export interface ProductCardStoreLocationInput {
  district_name?: string | null;
  province_name?: string | null;
  address?: string | null;
  mapsUrl?: string | null;
}

export interface ProductCardLocationFact {
  ilceIlMetni: string | null;
  mapsUrl: string | null;
  raftaHazirMi: boolean;
  rozetMetni: string | null;
}

export interface ProductCardFacts {
  marka: string | null;
  ozellikler: ProductQuickFact[];
  gtin: string | null;
  resmiKaynak: ProductCardOfficialSource | null;
  resmiKatalogRozeti: string | null;
  location: ProductCardLocationFact | null;
}

const KURAL32_KONUM_DESENI =
  /\b(?:vkn|vergi\s*no|vergi\s*numara(?:sı|si)?|tckn|alış\s*fiyat(?:ı|i)?|alis\s*fiyat(?:ı|i)?|toptan\s*(?:alış\s*)?fiyat(?:ı|i)?|fatura\s*alış|purchase\s*price|wholesale\s*price|tax\s*id)\b/iu;

function kural32TemizKonumMetni(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const cleaned = value.replace(/\s+/g, " ").trim();
  if (!cleaned || KURAL32_KONUM_DESENI.test(cleaned)) return null;
  return cleaned;
}

function guvenliHttpUrl(value: unknown): URL | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  try {
    const parsed = new URL(trimmed);
    if (
      (parsed.protocol !== "http:" && parsed.protocol !== "https:") ||
      parsed.username ||
      parsed.password
    ) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

function resmiKaynakDogrulanmisMi(verificationStatus?: string): boolean {
  const etiket = String(verificationStatus || "")
    .replace(/^[✓?✗⚠\s]+/, "")
    .trim()
    .toLocaleLowerCase("tr-TR");
  return [
    "doğrulandı",
    "dogrulandi",
    "doğrulanmış",
    "dogrulanmis",
    "verified",
    "kanitli",
    "kanıtlı",
  ].includes(etiket);
}

function resmiKaynakBilgisi(
  metadata: ReturnType<typeof normalizeProductMetadata>,
): ProductCardOfficialSource | null {
  if (metadata.itemKind === "service") return null;
  const source = metadata.manufacturerSource;
  if (!source?.url || !resmiKaynakDogrulanmisMi(source.verificationStatus)) return null;
  const parsed = guvenliHttpUrl(source.url);
  if (!parsed) return null;
  const alanAdi = parsed.hostname.toLocaleLowerCase("tr-TR").replace(/^www\./, "");
  if (!alanAdi) return null;
  return { url: parsed.toString(), alanAdi };
}

function urunRaftaHazirMi(args: {
  isService: boolean;
  stockQuantity?: number | null;
  stockStatus?: string | null;
}): boolean {
  if (args.isService) return false;
  if (args.stockQuantity != null) {
    if (!Number.isFinite(args.stockQuantity) || args.stockQuantity <= 0) return false;
  }
  const status = String(args.stockStatus || "")
    .trim()
    .toLocaleLowerCase("tr-TR");
  if (!status) return true;
  return ![
    "tükendi",
    "tukendi",
    "stokta yok",
    "mevcut değil",
    "mevcut degil",
    "out of stock",
    "unavailable",
    "siparişle",
    "siparisle",
    "ön sipariş",
    "on siparis",
  ].some((token) => status.includes(token));
}

function guvenliMapsUrl(value: unknown): string | null {
  const parsed = guvenliHttpUrl(value);
  if (!parsed) return null;
  let decoded = parsed.toString();
  try {
    decoded = decodeURIComponent(decoded);
  } catch {
    return null;
  }
  if (KURAL32_KONUM_DESENI.test(decoded)) return null;
  return parsed.toString();
}

function buildProductCardLocationFact(args: {
  isService: boolean;
  stockQuantity?: number | null;
  stockStatus?: string | null;
  storeLocation?: ProductCardStoreLocationInput | null;
}): ProductCardLocationFact | null {
  const raw = args.storeLocation;
  if (!raw) return null;

  const ilce = kural32TemizKonumMetni(raw.district_name);
  const il = kural32TemizKonumMetni(raw.province_name);
  const adres = kural32TemizKonumMetni(raw.address);

  let ilceIlMetni: string | null = null;
  if (ilce && il) {
    ilceIlMetni =
      ilce.toLocaleLowerCase("tr-TR") === il.toLocaleLowerCase("tr-TR")
        ? il
        : `${ilce}, ${il}`;
  } else if (ilce || il) {
    ilceIlMetni = ilce || il;
  } else if (adres) {
    const yer = ilIlceCikar(adres);
    if (yer?.ilce && yer.il) ilceIlMetni = `${yer.ilce}, ${yer.il}`;
    else if (yer?.il) ilceIlMetni = yer.il;
    else ilceIlMetni = adres;
  }

  let mapsUrl: string | null = null;
  if (raw.mapsUrl !== undefined) {
    mapsUrl = guvenliMapsUrl(raw.mapsUrl);
  } else if (adres || ilceIlMetni) {
    mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(adres || ilceIlMetni || "")}`;
  }

  if (!ilceIlMetni && !mapsUrl) return null;

  const raftaHazirMi = urunRaftaHazirMi({
    isService: args.isService,
    stockQuantity: args.stockQuantity,
    stockStatus: args.stockStatus,
  });

  const rozetMetni = raftaHazirMi
    ? ilceIlMetni
      ? `${ilceIlMetni} · Rafta Hazır`
      : "Rafta Hazır"
    : null;

  return {
    ilceIlMetni,
    mapsUrl,
    raftaHazirMi,
    rozetMetni,
  };
}

export function buildProductCardFacts(args: {
  brand?: string | null;
  barcode?: string | null;
  metadata?: unknown;
  variants?: unknown;
  limit?: number;
  stockStatus?: string | null;
  stockQuantity?: number | null;
  storeLocation?: ProductCardStoreLocationInput | null;
}): ProductCardFacts {
  const metadata = normalizeProductMetadata(args.metadata);
  const limit = Math.max(0, args.limit ?? 3);
  const kartAlanlari = new Set(
    productAttributesForSurface(metadata.templateKey, "card").map((definition) => definition.key),
  );

  const marka =
    metadata.itemKind !== "service" && kartAlanlari.has("brand")
      ? String(args.brand || "").trim() || null
      : null;

  const ozellikler: ProductQuickFact[] = [];

  if (metadata.itemKind === "service") {
    const service = metadata.service;
    if (service?.durationMinutes && kartAlanlari.has("durationMinutes")) {
      ozellikler.push({
        key: "durationMinutes",
        label: "Süre",
        value: `${service.durationMinutes} dk`,
      });
    }
    if (service?.priceMode && kartAlanlari.has("priceMode")) {
      ozellikler.push({
        key: "priceMode",
        label: "Fiyat biçimi",
        value: PRICE_MODE_LABELS[service.priceMode],
      });
    }
    if (service?.serviceLocation && kartAlanlari.has("serviceLocation")) {
      ozellikler.push({
        key: "serviceLocation",
        label: "Hizmet yeri",
        value: SERVICE_LOCATION_LABELS[service.serviceLocation],
      });
    }
  } else {
    ozellikler.push(
      ...metadataAttributeFacts({
        metadata,
        surface: "card",
        existingKeys: new Set(["brand"]),
      }),
    );
  }

  if (metadata.itemKind !== "service") {
    const mevcutAnahtarlar = new Set(ozellikler.map((ozellik) => ozellik.key));
    for (const varyantAlani of buildVariantOptionFacts(args.variants, metadata.templateKey, metadata.lunaInvoice)) {
      const temelAnahtar = varyantAlani.key.replace("variant:", "");
      if (mevcutAnahtarlar.has(temelAnahtar)) continue;
      ozellikler.unshift(varyantAlani);
    }
  }

  const gorulenDegerler = new Set<string>();
  const benzersiz = ozellikler.filter((ozellik) => {
    const deger = ozellik.value.trim();
    if (!deger || gorulenDegerler.has(deger)) return false;
    gorulenDegerler.add(deger);
    return true;
  });

  const gtin = metadata.itemKind === "service" ? null : normalizeGoogleGtin(args.barcode) ?? null;
  const resmiKaynak = resmiKaynakBilgisi(metadata);
  const resmiKatalogRozeti =
    resmiKaynak && gtin
      ? "Resmi Üretici Kataloğu / GS1"
      : resmiKaynak
        ? "Resmi Üretici Kataloğu"
        : gtin
          ? "GS1 GTIN"
          : null;

  const location = buildProductCardLocationFact({
    isService: metadata.itemKind === "service",
    stockQuantity: args.stockQuantity,
    stockStatus: args.stockStatus,
    storeLocation: args.storeLocation,
  });

  return {
    marka,
    ozellikler: benzersiz.slice(0, limit),
    gtin,
    resmiKaynak,
    resmiKatalogRozeti,
    location,
  };
}

const TUTAR_BICIMI = new Intl.NumberFormat("tr-TR", { maximumFractionDigits: 2 });

export function eskiFiyatYazisi(oldPriceAmount: unknown): string | null {
  const tutar = typeof oldPriceAmount === "number" ? oldPriceAmount : Number(oldPriceAmount);
  if (!Number.isFinite(tutar) || tutar <= 0) return null;
  return `${TUTAR_BICIMI.format(tutar)} TL`;
}

export function indirimOrani(args: {
  priceAmount?: number | null;
  oldPriceAmount?: number | null;
}): number | null {
  const guncel = typeof args.priceAmount === "number" ? args.priceAmount : Number(args.priceAmount);
  const eski = typeof args.oldPriceAmount === "number" ? args.oldPriceAmount : Number(args.oldPriceAmount);
  if (!Number.isFinite(guncel) || !Number.isFinite(eski)) return null;
  if (guncel <= 0 || eski <= 0 || eski <= guncel) return null;
  const oran = Math.round(((eski - guncel) / eski) * 100);
  return oran >= 1 && oran <= 99 ? oran : null;
}

export function kartRozeti(args: {
  badgeTag?: string | null;
  priceAmount?: number | null;
  oldPriceAmount?: number | null;
}): string | null {
  const elleYazilan = String(args.badgeTag || "").trim();
  if (elleYazilan) return elleYazilan;
  const oran = indirimOrani(args);
  return oran === null ? null : `%${oran} indirim`;
}

export function tutarYazisi(tutar: number): string {
  return `${TUTAR_BICIMI.format(tutar)} TL`;
}

export function birimFiyatBilgisi(
  metadata: unknown,
  fiyatTutar: number | null,
): { miktar: string; birimFiyat: string } | null {
  if (fiyatTutar == null || !Number.isFinite(fiyatTutar) || fiyatTutar <= 0) return null;
  const normalized = normalizeProductMetadata(metadata);
  for (const attribute of normalized.attributes || []) {
    if (attribute.key !== "netQuantity") continue;
    const ham = `${Array.isArray(attribute.value) ? attribute.value.join(" ") : attribute.value ?? ""} ${attribute.unit ?? ""}`.trim();
    const eslesme = ham.match(/(\d+(?:[.,]\d+)?)\s*(kg|kilo|gr|g|lt|l|ml|cl)\b/i);
    if (!eslesme) continue;
    const sayi = Number(eslesme[1].replace(",", "."));
    if (!Number.isFinite(sayi) || sayi <= 0) continue;
    const birim = eslesme[2].toLocaleLowerCase("tr-TR");
    const agirlikMi = birim === "kg" || birim === "kilo" || birim === "gr" || birim === "g";
    const olcu = agirlikMi
      ? birim === "kg" || birim === "kilo"
        ? sayi
        : sayi / 1000
      : birim === "lt" || birim === "l"
        ? sayi
        : sayi / 1000;
    if (olcu <= 0) continue;
    const birimAd = agirlikMi ? "kg" : "L";
    const gosterilenMiktar = `${eslesme[1]} ${birim === "gr" ? "g" : birim === "lt" ? "L" : eslesme[2]}`;
    return {
      miktar: gosterilenMiktar,
      birimFiyat: `${TUTAR_BICIMI.format(fiyatTutar / olcu)} TL/${birimAd}`,
    };
  }
  return null;
}
