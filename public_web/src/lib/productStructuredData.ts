import type { RichProductItem } from "./richProductItem";
import { normalizeProductMetadata, normalizeProductVariants } from "./productRichData";
import { parseProductPriceString } from "./productPrice";

const VARIANT_SCHEMA_PROPERTIES: Record<string, { property: string; field: string }> = {
  color: { property: "https://schema.org/color", field: "color" },
  shade: { property: "https://schema.org/color", field: "color" },
  size: { property: "https://schema.org/size", field: "size" },
  material: { property: "https://schema.org/material", field: "material" },
  pattern: { property: "https://schema.org/pattern", field: "pattern" },
};

const CONDITION_URLS: Record<string, string> = {
  new: "https://schema.org/NewCondition",
  used: "https://schema.org/UsedCondition",
  refurbished: "https://schema.org/RefurbishedCondition",
};

function productCondition(metadata: ReturnType<typeof normalizeProductMetadata>) {
  const raw = metadata.attributes?.find((item) => item.key === "condition")?.value;
  return typeof raw === "string" ? CONDITION_URLS[raw] : undefined;
}

function productIsInStock(stockStatus?: string | null, stockQuantity?: number | null) {
  if (stockQuantity != null) return stockQuantity > 0;
  const status = String(stockStatus || "")
    .trim()
    .toLocaleLowerCase("tr-TR");
  if (!status) return true;
  return ![
    "tükendi",
    "stokta yok",
    "mevcut değil",
    "mevcut degil",
    "out of stock",
    "unavailable",
  ].some((token) => status.includes(token));
}

/**
 * Google/GS1 için yalnız doğrulanabilen GTIN değerini döndürür. Vixrex'teki
 * barkod alanı daha geniş kalır; yerel/özel barkodlar ürün verisinden silinmez,
 * yalnız GTIN olarak structured data'ya yazılmaz.
 */
export function normalizeGoogleGtin(value: string | null | undefined): string | undefined {
  const digits = String(value || "").replace(/[\s-]+/g, "");
  if (!/^(?:\d{8}|\d{12}|\d{13}|\d{14})$/.test(digits)) return undefined;
  if (
    digits.startsWith("02") ||
    digits.startsWith("04") ||
    digits.startsWith("2") ||
    digits.startsWith("98") ||
    digits.startsWith("99")
  ) {
    return undefined;
  }

  const checkDigit = Number(digits[digits.length - 1]);
  let sum = 0;
  let weight = 3;
  for (let index = digits.length - 2; index >= 0; index -= 1) {
    sum += Number(digits[index]) * weight;
    weight = weight === 3 ? 1 : 3;
  }
  const expected = (10 - (sum % 10)) % 10;
  return expected === checkDigit ? digits : undefined;
}

function structuredGtin(value: string | null | undefined): Record<string, string> {
  const gtin = normalizeGoogleGtin(value);
  if (!gtin) return {};
  return { [`gtin${gtin.length}`]: gtin };
}

/**
 * Vixrex fiyat metinleri Türkçe binlik ayırıcıyı destekler: 1.299 TL => 1299.
 * Ondalık örnekleri de korunur: 1299,90 => 1299.90; 1.299,90 => 1299.90.
 */
export function parseProductPriceAmount(value: string | undefined): string | undefined {
  return parseProductPriceString(value);
}

function structuredPrice(product: RichProductItem): string | undefined {
  if (product.priceAmount != null && Number.isFinite(product.priceAmount)) {
    return String(product.priceAmount);
  }
  return parseProductPriceAmount(product.price);
}

function offer(args: {
  url: string;
  price?: number | string | null;
  currency: string;
  stockStatus?: string | null;
  stockQuantity?: number | null;
  storeName: string;
  itemCondition?: string;
}) {
  if (args.price == null || String(args.price).trim() === "") return undefined;
  return {
    "@type": "Offer",
    url: args.url,
    priceCurrency: args.currency,
    price: String(args.price),
    availability: productIsInStock(args.stockStatus, args.stockQuantity)
      ? "https://schema.org/InStock"
      : "https://schema.org/OutOfStock",
    itemCondition: args.itemCondition,
    seller: { "@type": "LocalBusiness", name: args.storeName },
  };
}

export function buildPhysicalProductStructuredData(args: {
  product: RichProductItem;
  productUrl: string;
  storeName: string;
  description: string;
  images: string[];
}) {
  const { product, productUrl, storeName, description, images } = args;
  const metadata = normalizeProductMetadata(product.metadata);
  const variants = normalizeProductVariants(product.variants);
  const currency = product.currency || "TRY";
  const parentPrice = structuredPrice(product);
  const itemCondition = productCondition(metadata);
  const common = {
    "@context": "https://schema.org",
    name: product.name,
    description,
    image: images.length > 0 ? images : undefined,
    brand: product.brand ? { "@type": "Brand", name: product.brand } : undefined,
    category: product.category || undefined,
    url: productUrl,
  };

  if (variants.length <= 1) {
    return {
      ...common,
      "@type": "Product",
      "@id": `${productUrl}#product`,
      ...structuredGtin(product.barcode),
      sku: metadata.identifiers?.sku || undefined,
      mpn: metadata.identifiers?.mpn || undefined,
      offers: offer({
        url: productUrl,
        price: parentPrice,
        currency,
        stockStatus: product.stockStatus,
        stockQuantity: product.stockQuantity,
        storeName,
        itemCondition,
      }),
    };
  }

  const variesBy = Array.from(
    new Set(
      variants.flatMap((variant) =>
        Object.keys(variant.options)
          .map((key) => VARIANT_SCHEMA_PROPERTIES[key]?.property)
          .filter((value): value is string => Boolean(value)),
      ),
    ),
  );
  const groupId = product.id || product.slug || productUrl;
  const groupNodeId = `${productUrl}#product-group`;

  const hasVariant = variants.map((variant) => {
    const optionValues = Object.values(variant.options).filter(Boolean);
    const recognized: Record<string, string> = {};
    const additionalProperty: Array<Record<string, string>> = [];
    for (const [key, value] of Object.entries(variant.options)) {
      const mapped = VARIANT_SCHEMA_PROPERTIES[key];
      if (mapped) recognized[mapped.field] = value;
      else {
        additionalProperty.push({
          "@type": "PropertyValue",
          name: key,
          value,
        });
      }
    }
    const variantUrl = `${productUrl}?variant=${encodeURIComponent(variant.id)}`;
    const variantImages = variant.imageUrls?.length ? variant.imageUrls : images;
    return {
      "@type": "Product",
      "@id": `${productUrl}#variant-${encodeURIComponent(variant.id)}`,
      isVariantOf: { "@id": groupNodeId },
      name: optionValues.length ? `${product.name} - ${optionValues.join(", ")}` : product.name,
      description,
      image: variantImages.length > 0 ? variantImages : undefined,
      url: variantUrl,
      sku: variant.sku || undefined,
      ...structuredGtin(variant.barcode),
      ...recognized,
      additionalProperty: additionalProperty.length ? additionalProperty : undefined,
      offers: offer({
        url: variantUrl,
        price: variant.priceAmount ?? parentPrice,
        currency,
        stockStatus: variant.stockStatus ?? product.stockStatus,
        stockQuantity: variant.stockQuantity ?? product.stockQuantity,
        storeName,
        itemCondition,
      }),
    };
  });

  return {
    ...common,
    "@type": "ProductGroup",
    "@id": groupNodeId,
    productGroupID: groupId,
    variesBy: variesBy.length ? variesBy : undefined,
    hasVariant,
  };
}
