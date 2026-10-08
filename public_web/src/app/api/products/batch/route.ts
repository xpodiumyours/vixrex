import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  createRichCoreProduct,
  publishInvoiceProduct,
  updateRichCoreProduct,
} from "@/lib/productCoreServer";
import {
  faturaUrununuKaydet,
  mevcutUrunuOku,
  satiriDogrula,
  satiriUrunleBagla,
  urunuGeriAl,
} from "@/lib/faturaUrunBaglantisi";
import { urunGirdisiniHazirla } from "@/lib/productIntake";
import { durumGecerliMi, yayinEksikleri } from "@/lib/faturaKartDurumu";
import { otomatikOzellikler } from "@/lib/faturaOtomatikDoldur";
import { eksikZorunluAlanlar, eksikZorunluAlanMesaji } from "@/lib/productRequiredFields";
import { FATURA_MIN_PRODUCT_IMAGES, yonetilenUrunGorseliMi } from "@/lib/productImagePolicy";
import { kaynakGorselleriniHazirla } from "@/lib/faturaGorsel";
import { tuketicideGorunenler, vitrinOnbelleginiYenile } from "@/lib/vitrinYayinDogrula";

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
  /** Eski istemciler gönderir. Kapı buna bakmaz; stok faturadaki adettir. */
  stokOnaylandi?: boolean;
  gorselKaynagi?: string;
  islemKimligi?: string;
  satirSirasi?: number;
  /** Satırın kanıt durumu. Yalnız "kanitli" satır yayına çıkar. */
  kartDurumu?: unknown;
  /** Faturadaki birim alış fiyatı. Karta yazılmaz, müşteriye gösterilmez. */
  purchasePriceAmount?: unknown;
}

interface SatirSonucu {
  sira: number;
  ad: string;
  durum: "yayinda" | "taslak" | "atlandi";
  sebep?: string;
  id?: string;
  kayit?: "yeni" | "guncellendi" | "mevcut";
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; products?: unknown; editToken?: unknown };
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
  const cerezliOturum = verifyOwnerSession(ownerSessionCookie, slug);
  const editTokenGovde = typeof govde.editToken === "string" ? govde.editToken.trim() : "";
  let ownerSession: { storeId: string } | null = cerezliOturum;
  if (!ownerSession && editTokenGovde) {
    try {
      const { verifyStoreEditToken } = await import("@/lib/instagramServer");
      const dogrulanan = await verifyStoreEditToken(slug, editTokenGovde);
      if (dogrulanan.id) ownerSession = { storeId: dogrulanan.id };
    } catch {
      ownerSession = null;
    }
  }
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

    const hazirlik = await urunGirdisiniHazirla({
      admin,
      storeId: store.id,
      storeName: store.name,
      govde: satirGovdesi,
      gorselPolitikasi: "toplu",
      enAzGorsel:
        (ham.sourceType || ham.source_type || "").trim() === FATURA_KAYNAGI
          ? FATURA_MIN_PRODUCT_IMAGES
          : undefined,
      sablonOnbellegi,
    });

    if (hazirlik.durum === "reddedildi") {
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: hazirlik.sebep });
      continue;
    }

    const kaynak = (ham.sourceType || ham.source_type || "bulk_import").trim();

    // Faturadan gelen satır, fotoğrafı ve zorunlu alanları tam olsa bile
    // kendiliğinden yayına çıkmaz: esnaf satış fiyatını girmeli, kartı
    // açıkça onaylamalı VE ayrıca Yayınla demeli. Bilgileri onayla yalnız
    // taslak kaydeder. Fatura alış fiyatı satış fiyatı yerine geçmez.
    const faturaKaynakli = kaynak === FATURA_KAYNAGI;
    const esnafOnayladi = ham.ownerApproved === true;
    const stokOnaylandi = ham.stokOnaylandi === true;
    const iddiaDurumu = durumGecerliMi(ham.kartDurumu) ? ham.kartDurumu : "eksik";
    const dogrulanmis = faturaKaynakli
      ? await satiriDogrula(
          admin,
          store.id,
          { islemKimligi: ham.islemKimligi, satirSirasi: ham.satirSirasi },
          iddiaDurumu,
        )
      : null;
    if (faturaKaynakli && !dogrulanmis) {
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: "Fatura satırı doğrulanamadı; tekrar dene." });
      continue;
    }
    if (dogrulanmis?.sonuc === "kanitli") {
      const katalog = dogrulanmis.katalog;
      if (!katalog || typeof katalog.resmiAd !== "string" || typeof katalog.kaynak !== "string") {
        atlandi += 1;
        sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: "Kayıtlı resmî ürün kaynağı eksik; yeniden eşleştir." });
        continue;
      }
      hazirlik.girdi.name = katalog.resmiAd;
      hazirlik.girdi.description = typeof katalog.aciklama === "string" ? katalog.aciklama : "";
      hazirlik.girdi.brand = typeof katalog.marka === "string" ? katalog.marka : null;
      const sablonAnahtari = hazirlik.girdi.metadata.templateKey;
      const nitelikler = otomatikOzellikler(
        {
          ad: katalog.resmiAd,
          aciklama: hazirlik.girdi.description,
          varyant: dogrulanmis.varyant,
          beden: dogrulanmis.beden,
        },
        sablonAnahtari,
      );
      const mevcut = hazirlik.girdi.metadata.attributes ?? [];
      const anahtarlar = new Set(mevcut.map((ozellik) => ozellik.key));
      hazirlik.girdi.metadata = {
        ...hazirlik.girdi.metadata,
        attributes: [...mevcut, ...nitelikler.filter((ozellik) => !anahtarlar.has(ozellik.key))],
      };
    }
    const kartDurumu = faturaKaynakli ? (dogrulanmis?.sonuc ?? "eksik") : iddiaDurumu;
    const yayinIstegi = ham.yayinIstegi === true;

    // Fotoğraf izleme (kilitli kapsam): üreticinin fotoğrafı karta girer ve
    // yayınlanabilir; kullanım izni sonra, çalışan sistemle istenir. Hangi
    // kartta üretici görseli olduğu fatura_kanit + invoice_image_rights
    // kayıtlarından izlenir — izin turu bu listeden yürür. Esnafın kendi
    // fotoğrafı her zamanki gibi serbestçe geçer.
    const kaynakGorselleri = faturaKaynakli
      ? hazirlik.girdi.imageUrls.filter(
          (adres) =>
            yonetilenUrunGorseliMi(adres) || dogrulanmis?.izinliGorseller.has(adres.trim()) === true,
        )
      : hazirlik.girdi.imageUrls;
    const disGorseller = faturaKaynakli
      ? kaynakGorselleri.filter((adres) => !yonetilenUrunGorseliMi(adres))
      : [];
    const katalogGorselleri = dogrulanmis?.katalog?.gorseller;
    const ureticiGorselVar =
      Array.isArray(katalogGorselleri) &&
      katalogGorselleri.some((adres) =>
        hazirlik.girdi.imageUrls.includes(String(adres)),
      );

    let urunGorselleri = kaynakGorselleri;
    let gorselDurumu = "";
    let gorselKaynaklari: Array<Record<string, unknown>> = [];
    if (disGorseller.length > 0) {
      const hazir = await kaynakGorselleriniHazirla({
        admin,
        slug,
        kaynakSayfa: typeof dogrulanmis?.katalog?.kaynak === "string" ? dogrulanmis.katalog.kaynak : "",
        adaylar: disGorseller,
      });
      const depodaki = new Map(hazir.gorseller.map((gorsel) => [gorsel.kaynakGorsel, gorsel]));
      const altyapiHatasi = new Set(
        hazir.reddedilenler
          .filter((red) => red.sebep === "erisilemedi" || red.sebep === "depoya-yazilamadi")
          .map((red) => red.kaynakGorsel),
      );
      if (altyapiHatasi.size > 0) {
        atlandi += 1;
        sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: "Ürün görseli kalıcı kaydedilemedi; tekrar dene." });
        continue;
      }
      urunGorselleri = kaynakGorselleri.flatMap((adres) => {
        if (yonetilenUrunGorseliMi(adres)) return [adres];
        const kopya = depodaki.get(adres);
        if (kopya) return [kopya.url];
        return [];
      });
      gorselKaynaklari = hazir.gorseller.map((gorsel) => ({
        depoUrl: gorsel.url,
        kaynakGorsel: gorsel.kaynakGorsel,
        kaynakSayfa: gorsel.kaynakSayfa,
        genislik: gorsel.genislik,
        yukseklik: gorsel.yukseklik,
      }));
      gorselDurumu = altyapiHatasi.size > 0 ? "dis-baglanti" : "depoda";
    }

    const sablonMesaji = faturaKaynakli
      ? eksikZorunluAlanMesaji(
          eksikZorunluAlanlar({
            templateKey: hazirlik.girdi.metadata.templateKey,
            brand: hazirlik.girdi.brand,
            metadata: hazirlik.girdi.metadata,
            variants: hazirlik.girdi.variants,
          }),
        )
      : null;
    const sablonTam = Boolean(faturaKaynakli && kartDurumu === "kanitli" && !sablonMesaji);
    const faturaEksikleri = faturaKaynakli
      ? yayinEksikleri({
          durum: kartDurumu,
          satisFiyati: hazirlik.girdi.priceAmount,
          stok: hazirlik.girdi.stockQuantity,
          stokOnaylandi,
          onaylandi: esnafOnayladi,
          gorselSayisi: urunGorselleri.length,
          sablonEksikleri: sablonMesaji ? [`${sablonMesaji} Katalogda yok; bu satır yayınlanamaz.`] : [],
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
      if (faturaKaynakli && dogrulanmis) {
        const olusan = await faturaUrununuKaydet(admin, {
          storeId: store.id,
          editToken: store.edit_token,
          satirId: dogrulanmis.satirId,
          girdi: { ...hazirlik.girdi, imageUrls: urunGorselleri, sortOrder: ham.sortOrder ?? ham.sort_order ?? index },
          kanit: { kartDurumu, stokOnaylandi, esnafOnayladi, sablonTam, ureticiGorsel: ureticiGorselVar, gorselDurumu, gorselKaynaklari },
          alisFiyati: dogrulanmis.alisBirimFiyati,
        });
        let sonuc: SatirSonucu = { sira: index, ad: hazirlik.girdi.name, durum: "taslak", id: olusan.id, kayit: olusan.kayit,
          sebep: faturaKapisiSebebi({ hazirlik, faturaKaynakli, faturaEksikleri, yayinIstegi }) };
        if (faturaKapisi) {
          const yayin = await publishInvoiceProduct({ admin, productId: olusan.id, editToken: store.edit_token });
          if (yayin.success) sonuc = { ...sonuc, durum: "yayinda", sebep: undefined };
          else sonuc.sebep = yayin.hata ?? "Ürün yayınlanamadı; taslak kaydedildi.";
        }
        if (sonuc.durum === "yayinda") yayinda += 1;
        else taslak += 1;
        sonuclar.push(sonuc);
        continue;
      }
      const mevcutBagli = dogrulanmis?.urunId
        ? await mevcutUrunuOku(admin, store.id, dogrulanmis.urunId)
        : null;
      let kayit: "yeni" | "guncellendi" | "mevcut" = mevcutBagli ? "guncellendi" : "yeni";

      if (mevcutBagli) {
        await updateRichCoreProduct({
          admin,
          productId: mevcutBagli.id,
          editToken: store.edit_token,
          name: hazirlik.girdi.name,
          description: hazirlik.girdi.description,
          priceText: hazirlik.girdi.priceText,
          priceAmount: hazirlik.girdi.priceAmount,
          imageUrls: urunGorselleri,
          categoryId: hazirlik.girdi.categoryId,
          stockStatus: mevcutBagli.stockStatus ?? hazirlik.girdi.stockStatus ?? "",
          stockQuantity: mevcutBagli.stockQuantity,
          brand: hazirlik.girdi.brand,
          barcode: hazirlik.girdi.barcode,
          metadata: hazirlik.girdi.metadata,
          variants: hazirlik.girdi.variants,
        });
      }

      const olusan = mevcutBagli
        ? { id: mevcutBagli.id, slug: "", created: false }
        : await createRichCoreProduct({
        admin,
        storeId: store.id,
        editToken: store.edit_token,
        name: hazirlik.girdi.name,
        description: hazirlik.girdi.description,
        priceText: hazirlik.girdi.priceText,
        priceAmount: hazirlik.girdi.priceAmount,
        imageUrls: urunGorselleri,
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
        if (olusan.created === false && !mevcutBagli) kayit = "mevcut";
        const kanitYazilsin =
          kayit === "yeni" || (kayit === "guncellendi" && mevcutBagli !== null && !mevcutBagli.gorunur);

        if (kanitYazilsin) {
          const { error: kanitHatasi } = await admin
            .from("products")
            .update({
              fatura_kanit: {
                kartDurumu,
                stokOnaylandi,
                ureticiGorsel: ureticiGorselVar,
                gorselDurumu,
                gorselKaynaklari,
              },
            })
            .eq("id", olusan.id);
          if (kanitHatasi) {
            console.error("[products/batch] fatura kaniti yazilamadi:", kanitHatasi.message);
            if (kayit === "yeni") {
              await urunuGeriAl(admin, store.id, olusan.id);
              throw new Error("FATURA_KANIT_YAZILAMADI");
            }
          }
        }

        if (dogrulanmis && kayit !== "guncellendi") {
          const baglandi = await satiriUrunleBagla(admin, dogrulanmis.satirId, olusan.id);
          if (!baglandi && kayit === "yeni") {
            await urunuGeriAl(admin, store.id, olusan.id);
            throw new Error("FATURA_BAGLANTISI_YAZILAMADI");
          }
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
      if (sonuclar.length > 0 && faturaKaynakli) {
        sonuclar[sonuclar.length - 1].kayit = kayit;
      }
    } catch (err) {
      console.error("[products/batch] create failed:", err);
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: "Ürün oluşturulamadı." });
    }
  }

  const faturaYayinlari = sonuclar.filter(
    (sonuc) => sonuc.kayit !== undefined && sonuc.durum === "yayinda" && sonuc.id,
  );
  if (faturaYayinlari.length > 0) {
    const gorunum = await tuketicideGorunenler(
      admin,
      store.id,
      faturaYayinlari.map((sonuc) => sonuc.id as string),
    );
    if (gorunum) {
      for (const sonuc of faturaYayinlari) {
        const durum = gorunum.get(sonuc.id as string);
        if (durum && !durum.gorunur) {
          sonuc.durum = "taslak";
          sonuc.sebep = durum.sebep;
          yayinda -= 1;
          taslak += 1;
        }
      }
    }
  }
  if (yayinda > 0) vitrinOnbelleginiYenile(slug);

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
