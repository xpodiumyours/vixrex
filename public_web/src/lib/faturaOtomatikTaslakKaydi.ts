import type { SupabaseClient } from "@supabase/supabase-js";
import { islemiYukle, islemYaniti, sahipDurumunuTemizle, type KayitliIslem, type SahipDurumu } from "@/lib/faturaIslemOku";
import { faturaTaslaklari } from "@/lib/faturaTaslagi";
import { faturaUrununuKaydet, satiriDogrula, satiriUrunleBagla } from "@/lib/faturaUrunBaglantisi";
import { kayitliFaturaKatalogunuUygula, faturaUrunGorselleriniAktar } from "@/lib/faturaUrunHazirlama";
import { urunGirdisiniHazirla } from "@/lib/productIntake";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { barkodDenetimi } from "@/lib/faturaKapiDenetimi";
import type { ProductAttributeValue, ProductMetadata } from "@/lib/productRichData";
import { FATURA_MIN_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import { faturaBaslangicZamani, faturaOzetSatiri, faturaOzetiniKaydet, gecenSaniye } from "@/lib/faturaOzeti";

export interface OtomatikTaslakRaporu {
  kaydedildi: number;
  atlandi: number;
  bekleyen: number;
  /** Kart açılmadı, esnafın "aynı ürün mü" cevabı bekleniyor. */
  birlestirmeBekleyen: number;
  /** Görseli olmayan kart sayısı. */
  gorselsiz: number;
  hatalar: string[];
}

function fiyat(ham: string): number | null {
  const temiz = ham.trim().replace(/\s/g, "");
  const sayi = Number(temiz.includes(",") ? temiz.replace(/\./g, "").replace(",", ".") : temiz);
  return temiz && Number.isFinite(sayi) && sayi > 0 ? sayi : null;
}

function stok(ham: string): number | null {
  const sayi = Number(ham);
  return ham.trim() && Number.isSafeInteger(sayi) && sayi >= 0 ? sayi : null;
}

async function ilkSahipDurumu(
  admin: SupabaseClient,
  satir: KayitliIslem["satirlar"][number],
): Promise<{ durum: SahipDurumu | null; bagli: boolean }> {
  if (satir.sahipDurumu) return { durum: satir.sahipDurumu, bagli: false };
  const durum: SahipDurumu = {
    satisFiyati: "", stok: satir.adet === null ? "" : String(satir.adet),
    stokOnaylandi: false, kategoriId: "", onayli: false, esnafGorselleri: [],
  };
  const yazma = await admin.from("invoice_job_lines")
    .update({ owner_state: durum, owner_state_updated_at: new Date().toISOString() })
    .eq("id", satir.satirId).is("owner_state", null).is("product_id", null)
    .select("owner_state,product_id").maybeSingle();
  if (yazma.error) throw new Error("Fatura seçimleri saklanamadı.");
  if (yazma.data) return { durum: sahipDurumunuTemizle(yazma.data.owner_state), bagli: Boolean(yazma.data.product_id) };
  const guncel = await admin.from("invoice_job_lines").select("owner_state,product_id")
    .eq("id", satir.satirId).maybeSingle();
  if (guncel.error || !guncel.data) throw new Error("Fatura satırı okunamadı.");
  return { durum: sahipDurumunuTemizle(guncel.data.owner_state), bagli: Boolean(guncel.data.product_id) };
}

function kanonikSatirIndeksi(satir: KayitliIslem["satirlar"][number], sira: number, toplam: number): number | null {
  const ham = satir.katalog?.canonicalRowId ?? satir.canonicalRowId;
  if (typeof ham !== "string" || !/^[1-9]\d*$/.test(ham)) return null;
  const hedef = Number(ham) - 1;
  if (hedef < 0 || hedef >= toplam || hedef === sira) return null;
  return hedef;
}

export async function faturaTaslakYanitiniHazirla(
  admin: SupabaseClient,
  storeId: string,
  slug: string,
  kayit: KayitliIslem,
): Promise<Record<string, unknown>> {
  const rapor: OtomatikTaslakRaporu = {
    kaydedildi: kayit.satirlar.filter((satir) => satir.urunId).length,
    atlandi: 0, bekleyen: 0, birlestirmeBekleyen: 0, gorselsiz: 0, hatalar: [],
  };
  let guncelKayit = kayit;
  const tumEksik = kayit.satirlar.map((satir, sira) => ({ satir, sira })).filter(({ satir }) => !satir.urunId);
  const eksik = [
    ...tumEksik.filter(({ satir, sira }) => kanonikSatirIndeksi(satir, sira, kayit.satirlar.length) === null),
    ...tumEksik.filter(({ satir, sira }) => kanonikSatirIndeksi(satir, sira, kayit.satirlar.length) !== null),
  ];
  const sonTarih = Date.now() + 240_000;
  const olusanUrunIdleri = new Map<number, string>();
  kayit.satirlar.forEach((satir, sira) => {
    if (satir.urunId) olusanUrunIdleri.set(sira, satir.urunId);
  });
  if (eksik.length > 0) {
    try {
      const islem = await admin.from("invoice_jobs").select("same_purchase_of")
        .eq("id", kayit.islemKimligi).eq("store_id", storeId).maybeSingle();
      if (islem.error || !islem.data) throw new Error("Fatura kaydı doğrulanamadı.");
      if (!islem.data.same_purchase_of) {
        const store = await admin.from("stores").select("id,edit_token,name")
          .eq("id", storeId).eq("slug", slug).maybeSingle();
        if (store.error || !store.data?.edit_token) throw new Error("Vitrin kayıt yetkisi doğrulanamadı.");
        for (const { satir, sira } of eksik) {
          if (Date.now() + 10_000 >= sonTarih) break;
          const dogrulanmis = await satiriDogrula(admin, storeId,
            { islemKimligi: kayit.islemKimligi, satirSirasi: sira }, satir.sonuc);
          if (!dogrulanmis || dogrulanmis.satirId !== satir.satirId) throw new Error("Fatura satırı doğrulanamadı.");
          if (!dogrulanmis.urunId) {
            const sahip = await ilkSahipDurumu(admin, satir);
            if (!sahip.bagli) {
              if (!sahip.durum) throw new Error("Fatura seçimleri okunamadı.");
              const kanonikSira = kanonikSatirIndeksi(satir, sira, kayit.satirlar.length);
              const kanonikUrunId = kanonikSira !== null ? olusanUrunIdleri.get(kanonikSira) : undefined;
              if (kanonikUrunId && typeof satiriUrunleBagla === "function") {
                await satiriUrunleBagla(admin, dogrulanmis.satirId, kanonikUrunId);
                olusanUrunIdleri.set(sira, kanonikUrunId);
                continue;
              }
              const durum = sahip.durum;
              const satisFiyati = fiyat(durum.satisFiyati);
              const katalog = satir.katalog;
              const barkodKontrolu = barkodDenetimi(satir.barkod);
              const barkodGecerli = !barkodKontrolu || barkodKontrolu.gecti;
              const metadata: ProductMetadata = katalog
                ? faturaKatalogMetadatasi(katalog)
                : { lunaInvoice: true };
              const ekBilgiler: ProductAttributeValue[] = [];
              if (!barkodGecerli) {
                ekBilgiler.push({
                  key: "rawBarcode", label: "Faturadaki barkod (kontrol hanesi tutmadı)",
                  value: String(satir.barkod),
                });
              }
              const faturaMarkasi = (satir.marka ?? "").trim();
              if (katalog && katalog.marka.trim() && faturaMarkasi && katalog.marka.trim() !== faturaMarkasi) {
                ekBilgiler.push({ key: "officialBrand", label: "Resmî marka", value: katalog.marka.trim() });
              }
              const hazirlik = await urunGirdisiniHazirla({
                admin, storeId, storeName: store.data.name,
                gorselPolitikasi: "toplu", lunaVaryantlariniKoru: true,
                enAzGorsel: FATURA_MIN_PRODUCT_IMAGES,
                govde: {
                  name: katalog?.resmiAd || satir.ad || satir.model || satir.barkod || satir.hamSatir,
                  description: katalog?.aciklama ?? "", brand: satir.marka || katalog?.marka,
                  barcode: barkodGecerli ? satir.barkod : "", categoryId: "",
                  priceText: satisFiyati === null ? "" : `${satisFiyati} TL`,
                  imageUrls: [...new Set([...(katalog?.gorseller ?? []), ...durum.esnafGorselleri])],
                  stockQuantity: stok(durum.stok),
                  metadata: {
                    ...(satir.model ? { identifiers: { sku: satir.model } } : {}),
                    ...metadata,
                    ...(ekBilgiler.length
                      ? { attributes: [...(metadata.attributes ?? []), ...ekBilgiler] }
                      : {}),
                  },
                },
              });
              if (hazirlik.durum === "reddedildi") throw new Error(hazirlik.sebep);
              const katalogHatasi = await kayitliFaturaKatalogunuUygula({
                admin, storeId, editToken: store.data.edit_token, girdi: hazirlik.girdi,
                satir: dogrulanmis, kategoriOnbellegi: new Map(),
              });
              if (katalogHatasi) throw new Error(katalogHatasi);
              const medya = await faturaUrunGorselleriniAktar({
                admin, slug, girdi: hazirlik.girdi, satir: dogrulanmis, sonTarih,
              });
              const kayitSonucu = await faturaUrununuKaydet(admin, {
                storeId, editToken: store.data.edit_token, satirId: dogrulanmis.satirId,
                girdi: { ...hazirlik.girdi, imageUrls: medya.urunGorselleri, sortOrder: sira },
                kanit: {
                  automaticDraft: true, kartDurumu: dogrulanmis.sonuc,
                  stokOnaylandi: durum.stokOnaylandi, esnafOnayladi: durum.onayli,
                  sablonTam: true, ureticiGorsel: false,
                  gorselDurumu: medya.gorselDurumu, gorselKaynaklari: medya.gorselKaynaklari,
                  gorselRedleri: medya.gorselRedleri,
                },
                alisFiyati: dogrulanmis.alisBirimFiyati,
              });
              if (kayitSonucu.durum === "onay-bekliyor") continue;
              olusanUrunIdleri.set(sira, kayitSonucu.id);
            }
          }
        }
        const yenilenen = await islemiYukle(admin, storeId, kayit.islemKimligi);
        if (!yenilenen?.satirlar.length) throw new Error("Ürün taslağının kalıcı kaydı doğrulanamadı.");
        guncelKayit = yenilenen;
        rapor.kaydedildi = yenilenen.satirlar.filter((satir) => satir.urunId).length;
        rapor.birlestirmeBekleyen = yenilenen.satirlar.filter(
          (satir) => !satir.urunId && satir.birlestirmeAdayi,
        ).length;
        rapor.bekleyen =
          yenilenen.satirlar.length - rapor.kaydedildi - rapor.birlestirmeBekleyen;
      }
    } catch (err) {
      rapor.hatalar.push(err instanceof Error ? err.message : "Ürün taslağı kaydedilemedi.");
      rapor.atlandi = 1;
      const yenilenen = await islemiYukle(admin, storeId, kayit.islemKimligi).catch(() => null);
      if (yenilenen?.satirlar.length) guncelKayit = yenilenen;
      rapor.birlestirmeBekleyen = guncelKayit.satirlar.filter(
        (satir) => !satir.urunId && satir.birlestirmeAdayi,
      ).length;
      rapor.bekleyen = Math.max(
        0,
        guncelKayit.satirlar.filter((satir) => !satir.urunId && !satir.birlestirmeAdayi).length - 1,
      );
    }
  }
  const bagliIdler = [...new Set(guncelKayit.satirlar.flatMap((satir) => satir.urunId ? [satir.urunId] : []))];
  rapor.kaydedildi = 0;
  const gorselUyarilari: string[] = [];
  let gorselliSayisi: number | null = bagliIdler.length ? null : 0;
  if (bagliIdler.length) {
    const urunler = await admin.from("products").select("id,is_visible,fatura_kanit,image_urls")
      .eq("store_id", storeId).in("id", bagliIdler);
    if (urunler.error || !Array.isArray(urunler.data)) {
      rapor.hatalar.push("Kayıtlı ürün taslakları doğrulanamadı.");
    } else {
      rapor.kaydedildi = urunler.data.filter((urun) => urun.is_visible === false).length;
      rapor.gorselsiz = urunler.data.filter(
        (urun) => (urun.fatura_kanit as { gorselDurumu?: string } | null)?.gorselDurumu === "gorsel-yok",
      ).length;
      gorselliSayisi = urunler.data.filter(
        (urun) => Array.isArray(urun.image_urls) && urun.image_urls.length > 0,
      ).length;
      if (rapor.gorselsiz > 0) {
        gorselUyarilari.push(`${rapor.gorselsiz} kart görselsiz kaydedildi.`);
      }
      if (urunler.data.some((urun) => urun.fatura_kanit?.gorselDurumu === "aktarim-bekliyor")) {
        gorselUyarilari.push("Bazı ürün fotoğrafları henüz aktarılamadı. Kartları düzenleyip yeniden kaydedebilirsin.");
      }
    }
  }
  const devamEdiyor = rapor.bekleyen > 0 && rapor.hatalar.length === 0;
  rapor.hatalar.push(...gorselUyarilari);
  const durum = await admin.from("invoice_provider_runs")
    .update({ error_code: !devamEdiyor && rapor.hatalar.length ? "FATURA_TASLAKLARI_EKSIK" : null })
    .eq("job_id", kayit.islemKimligi).eq("store_id", storeId).eq("state", "processed");
  if (durum.error) rapor.hatalar.push("Taslak kayıt durumu saklanamadı.");
  const hazirlaniyor = devamEdiyor && !durum.error;
  let ozetSatiri: string | null = null;
  if (!hazirlaniyor) {
    const baslangic = await faturaBaslangicZamani(admin, storeId, kayit.islemKimligi);
    ozetSatiri = faturaOzetSatiri({
      islemKimligi: kayit.islemKimligi,
      satirSayisi: guncelKayit.satirlar.length,
      kartSayisi: bagliIdler.length,
      gorselliSayisi,
      sureSaniye: gecenSaniye(baslangic),
      hataKodu: rapor.hatalar.length ? "FATURA_TASLAKLARI_EKSIK" : null,
    });
    await faturaOzetiniKaydet(admin, storeId, kayit.islemKimligi, ozetSatiri);
  }
  return {
    ...islemYaniti(guncelKayit),
    tamam: !hazirlaniyor, hazirlaniyor,
    taslaklar: faturaTaslaklari(guncelKayit.satirlar, kayit.islemKimligi),
    otomatikTaslakRaporu: rapor,
    ...(ozetSatiri ? { ozetSatiri } : {}),
    ...(rapor.hatalar.length ? { taslakKayitUyarisi: rapor.hatalar.join(" ") } : {}),
  };
}
