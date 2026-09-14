import { cookies } from "next/headers";
import ProductDetailExperience from "@/components/ProductDetailExperience";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import {
  findProductBySlug,
  getProductImages,
  normalizeExternalUrl,
  normalizeWhatsappDigits,
} from "@/lib/products";
import { buildProductDetailFacts } from "@/lib/productCardPresentation";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import { normalizeProductMetadata } from "@/lib/productRichData";
import type { RichProductItem } from "@/lib/richProductItem";
import { supabase } from "@/lib/supabase";

interface OwnerProductDetailPreviewProps {
  slug: string;
  productSlug: string;
}

function record(value: unknown): Record<string, unknown> | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function text(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function numberOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function imageUrls(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter(Boolean)
    .slice(0, MAX_PRODUCT_IMAGES);
}

async function loadOwnerProductDetail(slug: string, productSlug: string) {
  const cookieStore = await cookies();
  const ownerCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerCookie, slug);
  if (!ownerSession) return null;

  const [draftResult, catalogResult] = await Promise.all([
    supabase.rpc("get_working_draft_for_session", {
      p_session_token: ownerSession.sessionToken,
    }),
    supabase.rpc("get_owner_catalog_for_session", {
      p_session_token: ownerSession.sessionToken,
    }),
  ]);

  if (draftResult.error || catalogResult.error) return null;

  const draft = record(draftResult.data);
  const catalog = record(catalogResult.data);
  if (!draft || !catalog) return null;
  if (text(draft.store_id) !== ownerSession.storeId || text(draft.slug) !== slug) {
    return null;
  }

  const draftData = record(draft.draft_data);
  const storeName = text(draftData?.name);
  if (!draftData || !storeName) return null;

  const categories = Array.isArray(catalog.categories) ? catalog.categories : [];
  const categoryNames = new Map<string, string>();
  for (const categoryValue of categories) {
    const category = record(categoryValue);
    const id = text(category?.id);
    const name = text(category?.name);
    if (id && name) categoryNames.set(id, name);
  }

  const rawProducts = Array.isArray(catalog.products) ? catalog.products : [];
  const products: RichProductItem[] = rawProducts
    .map((productValue): RichProductItem | null => {
      const product = record(productValue);
      const name = text(product?.name);
      if (!product || !name || product.is_active === false || product.is_visible === false) {
        return null;
      }
      const categoryId = text(product.category_id);
      const priceAmount = numberOrNull(product.price_amount);
      const currency = text(product.currency) || "TRY";
      return {
        id: text(product.id) || undefined,
        slug: text(product.slug) || undefined,
        name,
        description: text(product.description) || undefined,
        price:
          text(product.price_text) ||
          (priceAmount != null ? `${priceAmount} ${currency}` : undefined),
        priceAmount,
        currency,
        oldPriceAmount: numberOrNull(product.old_price_amount),
        badgeTag: text(product.badge_tag) || null,
        fulfillmentRegion: text(product.fulfillment_region) || null,
        imageUrls: imageUrls(product.image_urls),
        categoryId: categoryId || undefined,
        category: categoryId ? categoryNames.get(categoryId) : undefined,
        stockStatus: text(product.stock_status) || undefined,
        stockQuantity: numberOrNull(product.stock_quantity),
        brand: text(product.brand) || null,
        barcode: text(product.barcode) || null,
        metadata: product.metadata,
        variants: product.variants,
        isVisible: product.is_visible !== false,
        source: text(product.source_type) || undefined,
        sourcePermalink: text(product.source_permalink) || undefined,
      };
    })
    .filter((product): product is RichProductItem => Boolean(product));

  const product = findProductBySlug(products, productSlug) as RichProductItem | undefined;
  if (!product) return null;

  return {
    store: {
      name: storeName,
      slug,
      description: text(draftData.description),
      corporateBio: text(draftData.corporate_bio),
      whatsapp: text(draftData.whatsapp),
      instagram: text(draftData.instagram),
      address: text(draftData.address),
      logoUrl: text(draftData.logo_url),
      shelfImageUrl: text(draftData.shelf_image_url),
    },
    product,
  };
}

export default async function OwnerProductDetailPreview({
  slug,
  productSlug,
}: OwnerProductDetailPreviewProps) {
  const data = await loadOwnerProductDetail(slug, productSlug);
  if (!data) return null;

  const { store, product } = data;
  const metadata = normalizeProductMetadata(product.metadata);
  const isService = metadata.itemKind === "service";
  const phoneDigits = normalizeWhatsappDigits(store.whatsapp);
  const itemAccusative = isService ? "hizmeti" : "ürünü";
  const whatsappUrl = phoneDigits
    ? `https://wa.me/${phoneDigits}?text=${encodeURIComponent(
        `Merhaba, ${store.name} vitrininizdeki '${product.name}' ${itemAccusative} hakkında bilgi almak istiyorum.`,
      )}`
    : null;
  const instagramUrl = store.instagram
    ? /instagram\.com/i.test(store.instagram)
      ? normalizeExternalUrl(store.instagram)
      : `https://instagram.com/${store.instagram.replace(/^@/, "").replace(/\//g, "")}`
    : null;
  const sourceUrl = normalizeExternalUrl(product.sourcePermalink);
  const productImages = getProductImages(product);
  const fallbackImage = store.shelfImageUrl || store.logoUrl;
  const images = productImages.length > 0 ? productImages : fallbackImage ? [fallbackImage] : [];
  const detailFacts = buildProductDetailFacts({
    brand: product.brand,
    barcode: product.barcode,
    metadata: product.metadata,
  }).filter((fact) => fact.key !== "brand");

  return (
    <div data-vixrex-owner-preview="true">
      <ProductDetailExperience
        product={product}
        images={images}
        storeName={store.name}
        storeSlug={store.slug}
        storeUrl={`/v/${store.slug}`}
        productSlug={productSlug}
        detailFacts={detailFacts}
        whatsappUrl={whatsappUrl}
        instagramUrl={instagramUrl}
        sourceUrl={sourceUrl}
        storeAddress={store.address || null}
      />
    </div>
  );
}
