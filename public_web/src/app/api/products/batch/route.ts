import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { createRichCoreProduct, publishInvoiceProduct } from "@/lib/productCoreServer";
import { urunGirdisiniHazirla } from "@/lib/productIntake";
import { izinsizUreticiGorseli } from "@/lib/ureticiKatalog";
import { durumGecerliMi, yayinEksikleri } from "@/lib/faturaKartDurumu";

/**
 * Toplu ürün oluşturma API'si.
 *
 * POST: Birden fazla ürünü tek seferde oluşturur.
 *
 */

export const dynamic = "force-dynamic";
export const maxDuration = 300;

/** Fatura fotoğrafından gelen satırların kaynak etiketi. */
export const FATURA_KAYNAGI = "invoice";

function pozitifSayi(value: unknown): number | null {
  const sayi =
    typeof value === "number"
      ? value
      : typeof value === "string"
        ? Number(value.trim().replace(",", "."))
        : NaN;
  return Number.isFinite(sayi) && sayi > 0 ? sayi : null;
}

function faturaKapisiSebebi(args: {
  hazirlik: { durum: string; eksik?: string };
  faturaKaynakli: boolean;
  faturaEksikleri: string[];
  yayinIstegi: boolean;
}): string {
  if (args.hazirlik.durum === "taslak" && args.hazirlik.eksik) return args.hazirlik.eksik;
  if (args.faturaKaynakli && args.faturaEksikleri.length > 0) {
    return args.faturaEksikleri[0];
  }
  if (args.faturaKaynakli && !args.yayinIstegi) {
    return "Yayın onayı verilmedi; ürün taslak kaydedildi.";
  }
  return "Görünürlük kapalı istendi.";
}

interface ProductBatchItem {
  name?: string;
  description?: string;
  price_text?: string;
  priceText?: string;
  category_id?: string;
  categoryId?: string;
  image_urls?: string[];
  imageUrls?: string[];
  source_type?: string;
  sourceType?: string;
  sort_order?: number;
  sortOrder?: number;
  isVisible?: boolean;
  brand?: unknown;
  barcode?: unknown;
  stockQuantity?: unknown;
  stockStatus?: unknown;
  metadata?: unknown;
  variants?: unknown;
  externalProductId?: string;
  /** Faturadan gelen satırlarda esnafın açık bilgi onayı (taslak kaydı). */
  ownerApproved?: boolean;
  /**
   * Faturadan gelen satırlarda esnafın ayrı Yayınla onayı. Yalnız true ise
   * ve bütün kapılar geçerse ürün görünür olur; yoksa taslak kaydedilir.
   * Bilgileri onayla ile Yayınla iki ayrı eylemdir.
   */
  yayinIstegi?: boolean;
  /** Faturadan gelen satırlarda esnafın stok onayı. Faturadaki adet öneridir. */
  stokOnaylandi?: boolean;
  /** Satırın kanıt durumu. Yalnız "kanitli" satır yayına çıkar. */
  kartDurumu?: unknown;
  /** Katalog hotlink'i: ürün kartına değil, fatura_kanit özetine yazılır. */
  kaynak?: string;
  /** Kaynak firma adı: ürün kartına değil, fatura_kanit özetine yazılır. */
  kaynakFirma?: string;
  /** Faturadaki birim alış fiyatı. Karta yazılmaz, müşteriye gösterilmez. */
  purchasePriceAmount?: unknown;
  /** Çift-kart engeli: fatura işlem kimliği (invoice_jobs.id). */
  islemKimligi?: string | null;
  /** Çift-kart engeli: fatura satır sırası. */
  satirIndex?: number | null;
  satir_index?: number | null;
}

interface SatirSonucu {
  sira: number;
  ad: string;
  durum: "yayinda" | "taslak" | "atlandi";
  sebep?: string;
  id?: string;
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; products?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  }

  if (!Array.isArray(govde.products) || govde.products.length === 0) {
    return NextResponse.json({ hata: "En az bir ürün belirtilmeli." }, { status: 422 });
  }

  if (govde.products.length > 100) {
    return NextResponse.json({ hata: "Tek seferde en fazla 100 ürün yüklenebilir." }, { status: 422 });
  }

  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş." },
      { status: 401 }
    );
  }

  const admin = getSupabaseAdmin();

  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token, name")
    .eq("id", ownerSession.storeId)
    .single();

  if (!store?.edit_token) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }

  const sablonOnbellegi = new Map<string, string | null>();
  const sonuclar: SatirSonucu[] = [];
  let yayinda = 0;
  let taslak = 0;
  let atlandi = 0;

  for (const [index, ham] of (govde.products as ProductBatchItem[]).entries()) {
    const ad = (ham.name || "").trim();
    const satirGovdesi: Record<string, unknown> = {
      name: ad,
      description: ham.description ?? "",
      priceText: ham.priceText ?? ham.price_text ?? "",
      categoryId: ham.categoryId ?? ham.category_id ?? "",
      imageUrls: ham.imageUrls ?? ham.image_urls ?? [],
      brand: ham.brand,
      barcode: ham.barcode,
      stockQuantity: ham.stockQuantity,
      stockStatus: ham.stockStatus,
      metadata: ham.metadata,
      variants: ham.variants,
    };

    const kaynak = (ham.sourceType || ham.source_type || "bulk_import").trim();
    const faturaKaynakli = kaynak === FATURA_KAYNAGI;

    const hazirlik = await urunGirdisiniHazirla({
      admin,
      storeId: store.id,
      storeName: store.name,
      govde: satirGovdesi,
      gorselPolitikasi: "toplu",
      faturaKaynakli,
      sablonOnbellegi,
    });

    if (hazirlik.durum === "reddedildi") {
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: hazirlik.sebep });
      continue;
    }

    // Faturadan gelen satır, fotoğrafı ve zorunlu alanları tam olsa bile
    // kendiliğinden yayına çıkmaz: esnaf satış fiyatını girmeli, kartı
    // açıkça onaylamalı VE ayrıca Yayınla demeli. Bilgileri onayla yalnız
    // taslak kaydeder. Fatura alış fiyatı satış fiyatı yerine geçmez.
    const esnafOnayladi = ham.ownerApproved === true;
    const stokOnaylandi = ham.stokOnaylandi === true;
    const kartDurumu = durumGecerliMi(ham.kartDurumu) ? ham.kartDurumu : "eksik";
    const yayinIstegi = ham.yayinIstegi === true;

    // Çift-kart engeli: fatura kaynaklı satırda (islemKimligi, satirIndex)
    // doluysa köprü tablosuna bak; kayıt varsa ürünü tekrar oluşturma.
    const islemKimligi =
      typeof ham.islemKimligi === "string" && ham.islemKimligi.trim()
        ? ham.islemKimligi.trim()
        : null;
    const satirIndex =
      typeof ham.satirIndex === "number" && Number.isInteger(ham.satirIndex)
        ? ham.satirIndex
        : typeof ham.satir_index === "number" && Number.isInteger(ham.satir_index)
          ? ham.satir_index
          : null;
    if (faturaKaynakli && islemKimligi !== null && satirIndex !== null) {
      try {
        const { data: mevcut } = await admin
          .from("invoice_product_links")
          .select("product_id")
          .eq("job_id", islemKimligi)
          .eq("line_index", satirIndex)
          .maybeSingle();
        const mevcutId =
          mevcut && typeof (mevcut as { product_id?: unknown }).product_id === "string"
            ? (mevcut as { product_id: string }).product_id
            : null;
        if (mevcutId) {
          atlandi += 1;
          sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: "zaten yazılmış", id: mevcutId });
          continue;
        }
      } catch (err) {
        console.error("[products/batch] link sorgulanamadi:", err);
      }
    }

    // Fotoğraf izleme (kilitli kapsam): üreticinin fotoğrafı karta girer ve
    // yayınlanabilir; kullanım izni sonra, çalışan sistemle istenir. Hangi
    // kartta üretici görseli olduğu fatura_kanit + invoice_image_rights
    // kayıtlarından izlenir — izin turu bu listeden yürür. Esnafın kendi
    // fotoğrafı her zamanki gibi serbestçe geçer.
    const ureticiGorselVar = hazirlik.girdi.imageUrls.some(izinsizUreticiGorseli);

    const faturaEksikleri = faturaKaynakli
      ? yayinEksikleri({
          durum: kartDurumu,
          satisFiyati: hazirlik.girdi.priceAmount,
          stok: hazirlik.girdi.stockQuantity,
          stokOnaylandi,
          onaylandi: esnafOnayladi,
          gorselSayisi: hazirlik.girdi.imageUrls.length,
        })
      : [];

    // Ayrı Yayınla kapısı: fatura satırı bütün bilgi kapılarını geçse bile
    // esnaf açıkça yayın istemedikçe taslak kalır. Fatura dışı kaynaklar
    // (Excel/CSV/XML, tekil, kopya) eski davranışını korur.
    const faturaKapisi =
      !faturaKaynakli || (faturaEksikleri.length === 0 && yayinIstegi);

    // Fatura dışı kaynaklarda eski kural: hazır ve kapatılmamışsa görünür.
    // Fatura satırı önce TASLAK kurulur; ayrı Yayınla isteği ve bütün
    // kapılar tamamsa aşağıdaki publish RPC'si görünür yapar. Bu sıra,
    // veritabanı tetiğiyle (fatura_yayin_kilidi) birebir aynıdır.
    const normalGorunur =
      hazirlik.durum === "hazir" && ham.isVisible !== false;
    const gorunur = faturaKaynakli ? false : normalGorunur;

    try {
      const olusan = await createRichCoreProduct({
        admin,
        storeId: store.id,
        editToken: store.edit_token,
        name: hazirlik.girdi.name,
        description: hazirlik.girdi.description,
        priceText: hazirlik.girdi.priceText,
        priceAmount: hazirlik.girdi.priceAmount,
        imageUrls: hazirlik.girdi.imageUrls,
        categoryId: hazirlik.girdi.categoryId,
        sourceType: kaynak,
        externalProductId: ham.externalProductId || "",
        brand: hazirlik.girdi.brand,
        barcode: hazirlik.girdi.barcode,
        stockQuantity: hazirlik.girdi.stockQuantity,
        stockStatus: hazirlik.girdi.stockStatus,
        metadata: hazirlik.girdi.metadata,
        variants: hazirlik.girdi.variants,
        isVisible: gorunur,
        sortOrder: typeof ham.sortOrder === "number"
          ? ham.sortOrder
          : typeof ham.sort_order === "number"
            ? ham.sort_order
            : index,
      });

      // Çift-kart engeli: ilk yazımda köprüyü kur; hata akışı bozmaz.
      if (faturaKaynakli && islemKimligi !== null && satirIndex !== null) {
        try {
          const { error: linkHatasi } = await admin
            .from("invoice_product_links")
            .insert({
              job_id: islemKimligi,
              line_index: satirIndex,
              product_id: olusan.id,
              store_id: store.id,
            });
          if (linkHatasi) {
            console.error("[products/batch] link yazilamadi:", linkHatasi.message);
          }
        } catch (err) {
          console.error("[products/batch] link yazilamadi:", err);
        }
      }

      // Alış fiyatı ürün kartına DEĞİL, kilitli kendi tablosuna yazılır.
      // products tablosunda anon'un tablo düzeyinde okuma yetkisi olduğu için
      // oraya konulan her kolon müşteriye de açılırdı (2026-09-26 ölçümü).
      const alisFiyati = pozitifSayi(ham.purchasePriceAmount);
      if (alisFiyati !== null) {
        const { error: alisHatasi } = await admin
          .from("product_purchase_prices")
          .upsert(
            { product_id: olusan.id, store_id: store.id, amount: alisFiyati, updated_at: new Date().toISOString() },
            { onConflict: "product_id" },
          );
        if (alisHatasi) {
          console.error("[products/batch] alis fiyati yazilamadi:", alisHatasi.message);
        }
      }

      // Fatura kanıt özeti satıra yazılır; ayrı Yayınla adımı (bu uçtaki
      // yayinIstegi veya /api/fatura-yayinla) kapıları buradan yeniden okur.
      // ureticiGorsel işareti, kullanım izni sonra istenecek kartların
      // listesidir (kilitli kapsam: önce çalışan sistem). create/update
      // RPC'leri bu kolonu taşımadığı için doğrudan yazılır.
      if (faturaKaynakli) {
        const { error: kanitHatasi } = await admin
          .from("products")
          .update({
            fatura_kanit: {
              kartDurumu,
              stokOnaylandi,
              ureticiGorsel: ureticiGorselVar,
              kaynak: typeof ham.kaynak === "string" ? ham.kaynak : null,
              kaynakFirma: typeof ham.kaynakFirma === "string" ? ham.kaynakFirma : null,
            },
          })
          .eq("id", olusan.id);
        if (kanitHatasi) {
          console.error("[products/batch] fatura kaniti yazilamadi:", kanitHatasi.message);
        }
      }

      if (!faturaKaynakli) {
        if (gorunur) {
          yayinda += 1;
          sonuclar.push({ sira: index, ad, durum: "yayinda", id: olusan.id });
        } else {
          taslak += 1;
          sonuclar.push({
            sira: index,
            ad,
            durum: "taslak",
            id: olusan.id,
            sebep: faturaKapisiSebebi({
              hazirlik,
              faturaKaynakli,
              faturaEksikleri,
              yayinIstegi,
            }),
          });
        }
      } else if (faturaKapisi) {
        // Esnaf ayrıca Yayınla dedi ve bilgi kapıları tam: publish RPC'si
        // güncel satırı sunucuda tekrar okuyup görünür yapar.
        const yayin = await publishInvoiceProduct({
          admin,
          productId: olusan.id,
          editToken: store.edit_token,
        });
        if (yayin.success) {
          yayinda += 1;
          sonuclar.push({ sira: index, ad, durum: "yayinda", id: olusan.id });
        } else {
          taslak += 1;
          sonuclar.push({
            sira: index,
            ad,
            durum: "taslak",
            id: olusan.id,
            sebep: yayin.hata ?? "Ürün yayınlanamadı.",
          });
        }
      } else {
        taslak += 1;
        sonuclar.push({
          sira: index,
          ad,
          durum: "taslak",
          id: olusan.id,
          sebep: faturaKapisiSebebi({
            hazirlik,
            faturaKaynakli,
            faturaEksikleri,
            yayinIstegi,
          }),
        });
      }
    } catch (err) {
      console.error("[products/batch] create failed:", err);
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: "Ürün oluşturulamadı." });
    }
  }

  return NextResponse.json({
    tamam: true,
    toplam: sonuclar.length,
    eklenen: yayinda + taslak,
    yayinda,
    taslak,
    hatali: atlandi,
    satirlar: sonuclar,
    hataDetaylari: sonuclar
      .filter((satir) => satir.durum === "atlandi")
      .map((satir) => ({ index: satir.sira, error: satir.sebep })),
  });
}
