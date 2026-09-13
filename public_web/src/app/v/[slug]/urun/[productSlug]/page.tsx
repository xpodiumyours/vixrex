import { Metadata } from "next";
import { notFound } from "next/navigation";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import {
  getProductImages,
  normalizeExternalUrl,
  normalizeWhatsappDigits,
} from "@/lib/products";
import { buildProductDetailFacts } from "@/lib/productCardPresentation";
import { normalizeProductMetadata } from "@/lib/productRichData";
import type { RichProductItem } from "@/lib/richProductItem";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";
import { safeJsonLdHtml } from "@/lib/jsonLd";
import ProductDetailExperience from "@/components/ProductDetailExperience";
import ProductViewTracker from "@/components/ProductViewTracker";

export const revalidate = 300;

interface PageProps {
  params: Promise<{ slug: string; productSlug: string }>;
}

interface StoreRow {
  id: string;
  slug: string;
  name: string;
  description?: string;
  corporate_bio?: string;
  whatsapp?: string;
  instagram?: string;
  website?: string;
  address?: string;
  logo_url?: string;
  shelf_image_url?: string;
  products?: unknown;
  is_published?: boolean;
  is_demo?: boolean | null;
  product_storage_version?: number;
}

interface ProductRow {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  price_text: string | null;
  price_amount: number | null;
  old_price_amount?: number | null;
  badge_tag?: string | null;
  fulfillment_region?: string | null;
  currency: string;
  stock_status: string | null;
  stock_quantity: number | null;
  brand: string | null;
  barcode: string | null;
  metadata: unknown;
  variants: unknown;
  seo_title: string | null;
  seo_description: string | null;
  image_urls: string[];
  category_id: string | null;
  is_visible: boolean;
  is_active: boolean;
  source_type: string;
}

interface CategoryRow {
  id: string;
  name: string;
}

async function _getProductData(slug: string, productSlug: string) {
  const { data: store, error } = await supabase
    .from("stores")
    .select(
      "id,slug,name,description,corporate_bio,whatsapp,instagram,website,address,logo_url,shelf_image_url,products,is_published,is_demo,product_storage_version",
    )
    .eq("slug", slug)
    .eq("is_published", true)
    .single<StoreRow>();

  if (error || !store) return null;

  if (store.id) {
    const { data: productRow } = await supabase
      .from("products")
      .select(
        "id,name,slug,description,price_text,price_amount,old_price_amount,badge_tag,fulfillment_region,currency,stock_status,stock_quantity,brand,barcode,metadata,variants,seo_title,seo_description,image_urls,category_id,is_visible,is_active,source_type",
      )
      .eq("store_id", store.id)
      .eq("slug", productSlug)
      .eq("is_active", true)
      .maybeSingle<ProductRow>();

    if (productRow && productRow.name?.trim() && productRow.is_visible) {
      let categoryName = "";
      if (productRow.category_id) {
        const { data: cat } = await supabase
          .from("product_categories")
          .select("name")
          .eq("id", productRow.category_id)
          .maybeSingle<CategoryRow>();
        categoryName = cat?.name || "";
      }

      const product: RichProductItem = {
        id: productRow.id,
        slug: productRow.slug,
        name: productRow.name,
        description: productRow.description || undefined,
        price:
          productRow.price_text ||
          (productRow.price_amount != null
            ? `${productRow.price_amount} ${productRow.currency}`
            : undefined),
        priceAmount: productRow.price_amount,
        currency: productRow.currency,
        oldPriceAmount: productRow.old_price_amount ?? null,
        badgeTag: productRow.badge_tag ?? null,
        fulfillmentRegion: productRow.fulfillment_region ?? null,
        imageUrls: Array.isArray(productRow.image_urls) ? productRow.image_urls : [],
        category: categoryName || undefined,
        stockStatus: productRow.stock_status || undefined,
        stockQuantity: productRow.stock_quantity,
        brand: productRow.brand,
        barcode: productRow.barcode,
        metadata: productRow.metadata,
        variants: productRow.variants,
        seoTitle: productRow.seo_title,
        seoDescription: productRow.seo_description,
        isVisible: productRow.is_visible,
        source: productRow.source_type,
      };

      return {
        store,
        product,
        productSlug: productRow.slug,
      };
    }
  }

  return null;
}

const getProductData = (slug: string, productSlug: string) =>
  unstable_cache(
    () => _getProductData(slug, productSlug),
    [`product-${slug}-${productSlug}`],
    {
      tags: [`store-${slug}`, `products-${slug}`, `product-${slug}-${productSlug}`],
      revalidate: 300,
    },
  )();

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const data = await getProductData(params.slug, params.productSlug);
  if (!data) return { robots: { index: false, follow: false } };

  const { store, product, productSlug } = data;
  const metadata = normalizeProductMetadata(product.metadata);
  const isService = metadata.itemKind === "service";

  if (store.is_demo) {
    return { robots: { index: false, follow: true } };
  }

  const title = product.seoTitle || `${product.name} - ${store.name} | Vixrex`;
  const description =
    product.seoDescription ||
    product.description ||
    `${store.name} vitrindeki ${product.name} ${isService ? "hizmeti" : "ürünü"} için detay ve iletişim bilgileri.`;
  const image = getProductImages(product)[0] || store.shelf_image_url || store.logo_url || "";
  const canonicalPath = `/v/${store.slug}/urun/${productSlug}`;
  const canonicalUrl = buildSiteUrl(canonicalPath);
  const ogImages = image
    ? [{ url: image.startsWith("http") ? image : buildSiteUrl(image) }]
    : [];

  return {
    title,
    description,
    robots: { index: true, follow: true },
    alternates: { canonical: canonicalPath },
    openGraph: {
      title,
      description,
      url: canonicalUrl,
      siteName: "Vixrex",
      locale: "tr_TR",
      images: ogImages,
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: ogImages.map((item) => item.url),
    },
  };
}

export default async function ProductDetailPage(props: PageProps) {
  const params = await props.params;
  const data = await getProductData(params.slug, params.productSlug);
  if (!data) notFound();

  const { store, product, productSlug } = data;
  const metadata = normalizeProductMetadata(product.metadata);
  const isService = metadata.itemKind === "service";
  const siteUrl = getSiteUrl();
  const publicUrl = buildSiteUrl(`/v/${store.slug}/urun/${productSlug}`);
  const storeUrl = `/v/${store.slug}`;
  const phoneDigits = normalizeWhatsappDigits(store.whatsapp);
  const itemAccusative = isService ? "hizmeti" : "ürünü";
  const whatsappUrl = phoneDigits
    ? `https://wa.me/${phoneDigits}?text=${encodeURIComponent(
        `Merhaba, ${store.name} vitrininizdeki '${product.name}' ${itemAccusative} hakkında bilgi almak istiyorum.`,
      )}`
    : null;
  const instagramValue = String(store.instagram || "").trim();
  const instagramUrl = (() => {
    if (!instagramValue) return null;
    if (/instagram\.com/i.test(instagramValue)) return normalizeExternalUrl(instagramValue);
    const username = instagramValue.replace(/^@/, "").replace(/\//g, "").trim();
    return username ? `https://instagram.com/${username}` : null;
  })();
  const sourceUrl = normalizeExternalUrl(product.sourcePermalink);
  const productImages = getProductImages(product);
  const fallbackImage = store.shelf_image_url || store.logo_url || "";
  const images = productImages.length > 0 ? productImages : fallbackImage ? [fallbackImage] : [];
  const productDescription =
    product.description ||
    store.description ||
    store.corporate_bio ||
    `${store.name} vitrindeki ${product.name} ${itemAccusative} için detay ve iletişim bilgileri.`;
  const isInStock =
    !isService &&
    (product.stockQuantity == null || product.stockQuantity > 0) &&
    !String(product.stockStatus || "")
      .toLocaleLowerCase("tr-TR")
      .includes("tükendi");
  const structuredPrice =
    product.priceAmount != null
      ? String(product.priceAmount)
      : product.price?.match(/\d/)
        ? product.price.replace(/[^0-9.,]/g, "").replace(",", ".")
        : undefined;
  const detailFacts = buildProductDetailFacts({
    brand: product.brand,
    barcode: product.barcode,
    metadata: product.metadata,
  }).filter((fact) => fact.key !== "brand");

  const structuredData = isService
    ? {
        "@context": "https://schema.org",
        "@type": "Service",
        "@id": `${publicUrl}#service`,
        name: product.name,
        description: productDescription,
        image: images.length > 0 ? images : undefined,
        serviceType: metadata.service?.serviceType || product.category || undefined,
        areaServed: product.fulfillmentRegion || undefined,
        url: publicUrl,
        provider: {
          "@type": "LocalBusiness",
          name: store.name,
          url: buildSiteUrl(`/v/${store.slug}`),
        },
        offers: structuredPrice
          ? {
              "@type": "Offer",
              priceCurrency: product.currency || "TRY",
              price: structuredPrice,
              url: publicUrl,
              seller: { "@type": "LocalBusiness", name: store.name },
            }
          : undefined,
      }
    : {
        "@context": "https://schema.org",
        "@type": "Product",
        "@id": `${publicUrl}#product`,
        name: product.name,
        description: productDescription,
        image: images.length > 0 ? images : undefined,
        brand: product.brand ? { "@type": "Brand", name: product.brand } : undefined,
        gtin: product.barcode || undefined,
        sku: metadata.identifiers?.sku || undefined,
        mpn: metadata.identifiers?.mpn || undefined,
        category: product.category || undefined,
        url: publicUrl,
        offers: structuredPrice
          ? {
              "@type": "Offer",
              availability: isInStock
                ? "https://schema.org/InStock"
                : "https://schema.org/OutOfStock",
              priceCurrency: product.currency || "TRY",
              price: structuredPrice,
              url: publicUrl,
              seller: { "@type": "LocalBusiness", name: store.name },
            }
          : undefined,
      };

  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Ana Sayfa", item: siteUrl },
      {
        "@type": "ListItem",
        position: 2,
        name: store.name,
        item: buildSiteUrl(`/v/${store.slug}`),
      },
      { "@type": "ListItem", position: 3, name: product.name, item: publicUrl },
    ],
  };

  return (
    <>
      <ProductViewTracker storeSlug={store.slug} productSlug={productSlug} />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(structuredData) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(breadcrumbJsonLd) }}
      />
      <ProductDetailExperience
        product={product}
        images={images}
        storeName={store.name}
        storeSlug={store.slug}
        storeUrl={storeUrl}
        productSlug={productSlug}
        detailFacts={detailFacts}
        whatsappUrl={whatsappUrl}
        instagramUrl={instagramUrl}
        sourceUrl={sourceUrl}
        storeAddress={store.address || null}
      />
    </>
  );
}
