import { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import {
  findProductBySlug,
  getProductImages,
  getProductUrlSlug,
  normalizeExternalUrl,
  normalizeWhatsappDigits,
  safeParseJson,
  type ProductItem,
} from "@/lib/products";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";

export const revalidate = 300;

interface PageProps {
  params: Promise<{ slug: string; productSlug: string }>;
}

interface StoreRow {
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
}

async function _getProductData(slug: string, productSlug: string) {
  const { data: store, error } = await supabase
    .from("stores")
    .select(
      "slug,name,description,corporate_bio,whatsapp,instagram,website,address,logo_url,shelf_image_url,products,is_published"
    )
    .eq("slug", slug)
    .eq("is_published", true)
    .single<StoreRow>();

  if (error || !store) return null;

  const products = safeParseJson<ProductItem>(store.products);
  const product = findProductBySlug(products, productSlug);
  if (!product || !product.name?.trim() || product.isVisible === false) {
    return null;
  }

  return {
    store,
    product,
    productSlug: getProductUrlSlug(product, products.indexOf(product)),
  };
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

  const { store, product, productSlug } = data;
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

  const productJsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    "@id": `${publicUrl}#product`,
    name: product.name,
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
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />

      <main className="min-h-screen bg-[#071322] px-3 py-4 text-white sm:px-6 sm:py-8">
        <section className="mx-auto grid w-full max-w-[1120px] gap-5 lg:grid-cols-[minmax(0,1fr)_380px]">
          <div className="overflow-hidden rounded-[28px] border border-[#25415F] bg-[#0E1B2E] p-3 shadow-[0_24px_70px_rgba(0,0,0,0.28)]">
            {images.length > 0 ? (
              <div className="flex snap-x snap-mandatory gap-3 overflow-x-auto">
                {images.map((imageUrl, index) => (
                  <div
                    key={imageUrl}
                    className="aspect-square min-w-full snap-center overflow-hidden rounded-[22px] bg-[#13243A]"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={imageUrl}
                      alt={`${product.name} görsel ${index + 1}`}
                      className="h-full w-full object-cover"
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex aspect-square items-center justify-center rounded-[22px] bg-[#13243A] text-sm font-black text-[#9DB2C8]">
                Ürün görseli bekleniyor
              </div>
            )}
            {images.length > 1 && (
              <div className="mt-3 text-center text-xs font-bold text-[#9DB2C8]">
                {images.length} görsel • Kaydırarak inceleyin
              </div>
            )}
          </div>

          <aside className="flex flex-col gap-4 rounded-[28px] border border-[#25415F] bg-[#0E1B2E]/95 p-5 shadow-[0_18px_45px_rgba(0,0,0,0.18)] sm:p-6">
            <Link href={storeUrl} className="text-xs font-black text-[#7BC7FF]">
              ← {store.name} vitrinine dön
            </Link>

            <div>
              {product.category && (
                <span className="rounded-full bg-[#38A0E4]/18 px-3 py-1 text-xs font-extrabold text-[#B9E1FF]">
                  {product.category}
                </span>
              )}
              <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl">
                {product.name}
              </h1>
              <p className="mt-4 whitespace-pre-wrap text-sm font-semibold leading-7 text-[#C4D1E3]">
                {productDescription}
              </p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="rounded-2xl border border-[#25415F] bg-[#13243A] p-4">
                <div className="text-[11px] font-bold text-[#9DB2C8]">Fiyat</div>
                <div className="mt-1 text-lg font-black text-[#7BC7FF]">
                  {product.price || "Fiyat sorun"}
                </div>
              </div>
              <div className="rounded-2xl border border-[#25415F] bg-[#13243A] p-4">
                <div className="text-[11px] font-bold text-[#9DB2C8]">Stok</div>
                <div className="mt-1 text-lg font-black text-emerald-200">
                  {product.stockStatus || "Bilgi alın"}
                </div>
              </div>
            </div>

            <div className="grid gap-3">
              {whatsappUrl && (
                <Link
                  href={whatsappUrl}
                  className="rounded-2xl bg-[#25D366] px-5 py-4 text-center text-sm font-black text-white shadow-lg shadow-emerald-950/20"
                >
                  {"WhatsApp'tan Ürün Sor"}
                </Link>
              )}
              {instagramUrl && (
                <Link
                  href={instagramUrl}
                  className="rounded-2xl border border-[#E1306C]/40 bg-[#E1306C]/18 px-5 py-4 text-center text-sm font-black text-pink-100"
                >
                  Instagram Profiline Git
                </Link>
              )}
              {sourceUrl && (
                <Link
                  href={sourceUrl}
                  className="rounded-2xl border border-white/10 bg-white/10 px-5 py-4 text-center text-sm font-black text-white"
                >
                  Kaynak Paylaşımı Aç
                </Link>
              )}
            </div>

            <div className="rounded-2xl border border-[#25415F] bg-[#071322] p-4">
              <div className="text-xs font-black text-white">Dijital dükkan arşivi</div>
              <p className="mt-2 text-xs font-semibold leading-5 text-[#9DB2C8]">
                Bu ürün Vixrex üzerinde kalıcı ürün sayfası olarak yayınlanır ve Google tarafından okunabilir HTML içerik olarak sunulur.
              </p>
            </div>
          </aside>
        </section>
      </main>
    </>
  );
}
