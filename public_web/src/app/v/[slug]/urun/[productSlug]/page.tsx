import { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import {
  getProductImages,
  normalizeExternalUrl,
  normalizeWhatsappDigits,
  type ProductItem,
} from "@/lib/products";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";
import { safeJsonLdHtml } from "@/lib/jsonLd";
import { productAttributeSchemaFields } from "@/lib/productStructuredData";
import { TrackedWhatsAppLink } from "@/components/TrackedWhatsAppLink";
import { MapPinIcon } from "@/lib/vitrinBrandIcons";
import ProductViewTracker from "@/components/ProductViewTracker";\nimport ProductCommercePanel from "@/components/ProductCommercePanel";\nimport VitrinCartDock from "@/components/VitrinCartDock";

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
  variants: unknown;
  image_urls: string[];
  category_id: string | null;
  is_visible: boolean;
  is_active: boolean;
  source_type: string;
  metadata?: unknown;
}

interface CategoryRow {
  id: string;
  name: string;
}

async function _getProductData(slug: string, productSlug: string) {
  const { data: store, error } = await supabase
    .from("stores")
    .select(
      "id,slug,name,description,corporate_bio,whatsapp,instagram,website,address,logo_url,shelf_image_url,products,is_published,is_demo,product_storage_version"
    )
    .eq("slug", slug)
    .eq("is_published", true)
    .single<StoreRow>();

  if (error || !store) return null;

  if (store.id) {
    const { data: productRow } = await supabase
      .from("products")
      .select(
        "id,name,slug,description,price_text,price_amount,old_price_amount,badge_tag,fulfillment_region,currency,stock_status,stock_quantity,variants,image_urls,category_id,is_visible,is_active,source_type,metadata"
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

      const product: ProductItem = {
        id: productRow.id,
        slug: productRow.slug,
        name: productRow.name,
        description: productRow.description || undefined,
        price:
          productRow.price_text ||
          (productRow.price_amount != null
            ? `${productRow.price_amount} ${productRow.currency}`
            : undefined),
        oldPriceAmount: productRow.old_price_amount ?? null,
        badgeTag: productRow.badge_tag ?? null,
        fulfillmentRegion: productRow.fulfillment_region ?? null,
        imageUrls: Array.isArray(productRow.image_urls)
          ? productRow.image_urls
          : [],
        category: categoryName || undefined,
        stockStatus: productRow.stock_status || undefined,
        isVisible: productRow.is_visible,
        source: productRow.source_type,
      };

      return {
        store,
        product,
        productSlug: productRow.slug,
        // Yalniz arama motoru ciktisi icin; ekran duzeni bunu kullanmaz.
        productMetadata: productRow.metadata ?? null,
        hasVariants: Array.isArray(productRow.variants) && productRow.variants.length > 0,
        stockQuantity: productRow.stock_quantity,
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
    }
  )();

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const data = await getProductData(params.slug, params.productSlug);
  if (!data) return { robots: { index: false, follow: false } };

  const { store, product, productSlug } = data;

  // #345: demo vitrinin ürün sayfası da indekslenmez. Vitrin sayfası
  // `follow: true` ile geçildiği için tarayıcı buraya ulaşabilir.
  if (store.is_demo) {
    return { robots: { index: false, follow: true } };
  }

  const title = `${product.name} - ${store.name} | Vixrex`;
  const description =
    product.description ||
    `${store.name} vitrindeki ${product.name} için detay ve iletişim bilgileri.`;
  const image =
    getProductImages(product)[0] || store.shelf_image_url || store.logo_url || "";
  const canonicalPath = `/v/${store.slug}/urun/${productSlug}`;
  const canonicalUrl = buildSiteUrl(canonicalPath);
  const ogImages = image
    ? [{ url: image.startsWith("http") ? image : buildSiteUrl(image) }]
    : [];

  return {
    title,
    description,
    robots: { index: true, follow: true },
    alternates: {
      canonical: canonicalPath,
    },
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

  const { store, product, productSlug, hasVariants, stockQuantity } = data;
  const siteUrl = getSiteUrl();
  const publicUrl = buildSiteUrl(`/v/${store.slug}/urun/${productSlug}`);
  const storeUrl = `/v/${store.slug}`;
  const phoneDigits = normalizeWhatsappDigits(store.whatsapp);
  const whatsappUrl = phoneDigits
    ? `https://wa.me/${phoneDigits}?text=${encodeURIComponent(
        `Merhaba, ${store.name} vitrininizdeki '${product.name}' hakkında bilgi almak istiyorum.`
      )}`
    : null;
  const instagramValue = String(store.instagram || "").trim();
  const instagramUrl = (() => {
    if (!instagramValue) return null;
    if (/instagram\.com/i.test(instagramValue)) {
      return normalizeExternalUrl(instagramValue);
    }
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
    `${store.name} vitrindeki ${product.name} için detay ve iletişim bilgileri.`;
  const isInStock = !String(product.stockStatus || "")
    .toLocaleLowerCase("tr-TR")
    .includes("tükendi");
  const fulfillmentRegion = String(product.fulfillmentRegion || "").trim();
  const storeAddressText = String(store.address || "").trim();
  const fulfillmentMapUrl = fulfillmentRegion
    ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(fulfillmentRegion)}`
    : null;
  const storeMapUrl = storeAddressText
    ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(storeAddressText)}`
    : null;

  // Esnafin girdigi kategori alanlari arama motoruna da gitsin. Ekranda
  // hicbir sey degismez; bu yalniz sayfanin gorunmeyen veri etiketidir.
  const attributeSchema = productAttributeSchemaFields(data.productMetadata);

  const productJsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    "@id": `${publicUrl}#product`,
    name: product.name,
    ...attributeSchema.recognized,
    additionalProperty: attributeSchema.additionalProperty,
    description: productDescription,
    image: images.length > 0 ? images : undefined,
    brand: {
      "@type": "Brand",
      name: store.name,
    },
    category: product.category || undefined,
    url: publicUrl,
    offers: {
      "@type": "Offer",
      availability: isInStock
        ? "https://schema.org/InStock"
        : "https://schema.org/OutOfStock",
      priceCurrency: "TRY",
      price: product.price?.match(/\d/) ? product.price.replace(/[^0-9.,]/g, "").replace(",", ".") : undefined,
      url: publicUrl,
      seller: {
        "@type": "LocalBusiness",
        name: store.name,
      },
    },
  };

  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Ana Sayfa",
        item: siteUrl,
      },
      {
        "@type": "ListItem",
        position: 2,
        name: store.name,
        item: buildSiteUrl(`/v/${store.slug}`),
      },
      {
        "@type": "ListItem",
        position: 3,
        name: product.name,
        item: publicUrl,
      },
    ],
  };

  return (
    <>
      <ProductViewTracker storeSlug={store.slug} productSlug={productSlug} />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(productJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLdHtml(breadcrumbJsonLd) }}
      />

      <main className="min-h-screen bg-[#0c0d10] px-4 py-6 text-[#f4f1ea] sm:px-6 sm:py-10">
        <section className="mx-auto grid w-full max-w-[1080px] gap-5 lg:grid-cols-[minmax(0,1.1fr)_360px]">
          <div className="overflow-hidden rounded-[24px] border border-white/8 bg-[#15171c] p-2.5">
            {images.length > 0 ? (
              <div className="flex snap-x snap-mandatory gap-2.5 overflow-x-auto">
                {images.map((imageUrl, index) => (
                  <div
                    key={imageUrl}
                    className="aspect-[4/5] min-w-full snap-center overflow-hidden rounded-[20px] bg-[#1c1f27]"
                  >
                    <Image
                      src={imageUrl}
                      alt={`${product.name} görsel ${index + 1}`}
                      width={720}
                      height={900}
                      className="h-full w-full object-cover"
                      priority={index === 0}
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex aspect-[4/5] items-center justify-center rounded-[20px] bg-[#1c1f27] text-sm font-bold text-white/40">
                Ürün görseli bekleniyor
              </div>
            )}
            {images.length > 1 && (
              <div className="mt-3 text-center text-xs font-bold text-white/40">
                {images.length} görsel · kaydırın
              </div>
            )}
          </div>

          <aside className="flex flex-col gap-4 rounded-[24px] border border-white/8 bg-[#15171c] p-5 sm:p-6">
            <Link
              href={storeUrl}
              className="text-xs font-extrabold text-[#E8A87C] transition hover:text-[#f0d0b4]"
            >
              ← {store.name} vitrinine dön
            </Link>

            <div>
              {product.category && (
                <span className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-extrabold text-white/70">
                  {product.category}
                </span>
              )}
              {product.badgeTag && (
                <span className="ml-2 rounded-lg bg-gradient-to-r from-blue-600 to-cyan-600 px-2.5 py-1 text-[10px] font-extrabold text-white shadow-md">
                  {product.badgeTag}
                </span>
              )}
              <h1 className="font-vitrin-display mt-4 text-[clamp(1.9rem,4vw,2.6rem)] font-normal leading-tight text-white">
                {product.name}
              </h1>
              <p className="mt-4 whitespace-pre-wrap text-sm font-medium leading-relaxed text-white/70">
                {productDescription}
              </p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="rounded-2xl border border-white/8 bg-[#1c1f27] p-4">
                <div className="text-[11px] font-bold text-white/40">Fiyat</div>
                <div className="mt-1 text-lg font-extrabold text-[#E8A87C]">
                  {product.price || "Fiyat sorun"}
                </div>
                {product.oldPriceAmount ? (
                  <div className="mt-1 text-xs font-medium text-white/30 line-through">
                    {product.oldPriceAmount} TL
                  </div>
                ) : null}
              </div>
              <div className="rounded-2xl border border-white/8 bg-[#1c1f27] p-4">
                <div className="text-[11px] font-bold text-white/40">Stok</div>
                <div className="mt-1 text-lg font-extrabold text-emerald-200">
                  {product.stockStatus || "Bilgi alın"}
                </div>
              </div>
            </div>

            <div className="rounded-2xl border border-blue-500/20 bg-gradient-to-br from-blue-500/10 to-cyan-500/5 p-4">
              <div className="flex items-start gap-3">
                <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-500/15">
                  <MapPinIcon className="h-4 w-4 text-blue-300" aria-hidden="true" />
                </div>
                <div className="min-w-0 flex-1">
                  {fulfillmentRegion ? (
                    <div>
                      <p className="text-[10px] font-extrabold uppercase tracking-wider text-blue-300">
                        Ürün konumu / teslim bölgesi
                      </p>
                      <p className="mt-1 text-xs font-semibold leading-5 text-white/75">
                        {fulfillmentRegion}
                      </p>
                      {fulfillmentMapUrl ? (
                        <a
                          href={fulfillmentMapUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400"
                        >
                          Haritada ara →
                        </a>
                      ) : null}
                    </div>
                  ) : null}
                  {storeAddressText ? (
                    <div className={fulfillmentRegion ? "mt-3 border-t border-white/10 pt-3" : ""}>
                      <p className="text-[10px] font-extrabold uppercase tracking-wider text-white/35">
                        İşletme konumu
                      </p>
                      <p className="mt-1 text-xs font-semibold leading-5 text-white/75">
                        {storeAddressText}
                      </p>
                      {storeMapUrl ? (
                        <a
                          href={storeMapUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="mt-1.5 inline-flex text-xs font-extrabold text-blue-400"
                        >
                          Yol tarifi →
                        </a>
                      ) : null}
                    </div>
                  ) : null}
                  {!fulfillmentRegion && !storeAddressText ? (
                    <p className="text-xs font-semibold leading-5 text-white/60">
                      Bu ürün için konum bilgisi eklenmemiş.
                    </p>
                  ) : null}
                </div>
              </div>
            </div>

            <div className="grid gap-2.5">
              {whatsappUrl && (
                <TrackedWhatsAppLink
                  href={whatsappUrl}
                  storeSlug={store.slug}
                  productSlug={productSlug}
                  clickLocation="product_detail"
                  className="rounded-full bg-[#25D366] px-5 py-3.5 text-center text-sm font-extrabold text-[#04140a]"
                >
                  WhatsApp’tan ürün sor
                </TrackedWhatsAppLink>
              )}
              {instagramUrl && (
                <Link
                  href={instagramUrl}
                  className="rounded-full border border-white/15 bg-white/5 px-5 py-3.5 text-center text-sm font-extrabold text-white"
                >
                  Instagram
                </Link>
              )}
              {sourceUrl && (
                <Link
                  href={sourceUrl}
                  className="rounded-full border border-white/10 px-5 py-3.5 text-center text-sm font-extrabold text-white/70"
                >
                  Kaynak paylaşımı
                </Link>
              )}
            </div>

            <ProductCommercePanel
              storeSlug={store.slug}
              storeName={store.name}
              productSlug={productSlug}
              productName={product.name}
              imageUrl={images[0] || null}
              priceText={product.price || null}
              stockQuantity={stockQuantity}
              cartEnabled={!hasVariants && isInStock}
              cartDisabledReason={
                hasVariants
                  ? "Bu ürünün seçenekli siparişi için vitrine dönüp Hızlı İncele ekranından beden/renk seç."
                  : ""
              }
            />
          </aside>
        </section>
      </main>

      <VitrinCartDock
        storeSlug={store.slug}
        storeName={store.name}
        whatsappBaseUrl={whatsappUrl}
      />
    </>
  );
}
