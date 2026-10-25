import type { SupabaseClient } from "@supabase/supabase-js";
import { islemiYukle, islemYaniti, sahipDurumunuTemizle, type KayitliIslem, type SahipDurumu } from "@/lib/faturaIslemOku";
import { faturaTaslaklari } from "@/lib/faturaTaslagi";
import { faturaUrununuKaydet, satiriDogrula } from "@/lib/faturaUrunBaglantisi";
import { kayitliFaturaKatalogunuUygula, faturaUrunGorselleriniAktar } from "@/lib/faturaUrunHazirlama";
import { urunGirdisiniHazirla } from "@/lib/productIntake";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { FATURA_MIN_PRODUCT_IMAGES } from "@/lib/productImagePolicy";

export interface OtomatikTaslakRaporu {
  kaydedildi: number;
  atlandi: number;
  bekleyen: number;
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

export async function faturaTaslakYanitiniHazirla(
  admin: SupabaseClient,
  storeId: string,
  slug: string,
  kayit: KayitliIslem,
): Promise<Record<string, unknown>> {
  const rapor: OtomatikTaslakRaporu = {
    kaydedildi: kayit.satirlar.filter((satir) => satir.urunId).length,
    atlandi: 0, bekleyen: 0, hatalar: [],
  };
  let guncelKayit = kayit;
  const eksik = kayit.satirlar.map((satir, sira) => ({ satir, sira })).filter(({ satir }) => !satir.urunId);
  const sonTarih = Date.now() + 240_000;
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
          try {
          const dogrulanmis = await satiriDogrula(admin, storeId,
            { islemKimligi: kayit.islemKimligi, satirSirasi: sira }, satir.sonuc);
          if (!dogrulanmis || dogrulanmis.satirId !== satir.satirId) throw new Error("Fatura satırı doğrulanamadı.");
          if (!dogrulanmis.urunId) {
            const sahip = await ilkSahipDurumu(admin, satir);
            if (!sahip.bagli) {
              if (!sahip.durum) throw new Error("Fatura seçimleri okunamadı.");
              const durum = sahip.durum;
              const satisFiyati = fiyat(durum.satisFiyati);
              const katalog = satir.katalog;
              const hazirlik = await urunGirdisiniHazirla({
                admin, storeId, storeName: store.data.name,
                gorselPolitikasi: "toplu", lunaVaryantlariniKoru: true,
                enAzGorsel: FATURA_MIN_PRODUCT_IMAGES,
                govde: {
                  name: katalog?.resmiAd || satir.ad || satir.model || satir.barkod || satir.hamSatir,
                  description: katalog?.aciklama ?? "", brand: katalog?.marka || satir.marka,
                  barcode: satir.barkod, categoryId: "",
                  priceText: satisFiyati === null ? "" : `${satisFiyati} TL`,
                  imageUrls: [...new Set([...(katalog?.gorseller ?? []), ...durum.esnafGorselleri])],
                  stockQuantity: stok(durum.stok),
                  metadata: { ...(satir.model ? { identifiers: { sku: satir.model } } : {}),
                    ...(katalog ? faturaKatalogMetadatasi(katalog) : { lunaInvoice: true }) },
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
              await faturaUrununuKaydet(admin, {
                storeId, editToken: store.data.edit_token, satirId: dogrulanmis.satirId,
                girdi: { ...hazirlik.girdi, imageUrls: medya.urunGorselleri, sortOrder: sira },
                kanit: {
                  automaticDraft: true, kartDurumu: dogrulanmis.sonuc,
                  stokOnaylandi: durum.stokOnaylandi, esnafOnayladi: durum.onayli,
                  sablonTam: true, ureticiGorsel: false,
                  gorselDurumu: medya.gorselDurumu, gorselKaynaklari: medya.gorselKaynaklari,
                },
                alisFiyati: dogrulanmis.alisBirimFiyati,
              });
              if (medya.gorselDurumu === "aktarim-bekliyor") {
                rapor.hatalar.push(`Satır ${sira + 1}: Ürün taslağı kaydedildi; bazı fotoğraflar aktarılamadı.`);
              }
            }
          }
          } catch (err) {
            rapor.atlandi += 1;
            rapor.hatalar.push(`Satır ${sira + 1}: ${err instanceof Error ? err.message : "Ürün taslağı kaydedilemedi."}`);
          }
        }
        const yenilenen = await islemiYukle(admin, storeId, kayit.islemKimligi);
        if (!yenilenen?.satirlar.length) throw new Error("Ürün taslağının kalıcı kaydı doğrulanamadı.");
        guncelKayit = yenilenen;
        rapor.kaydedildi = yenilenen.satirlar.filter((satir) => satir.urunId).length;
        rapor.bekleyen = yenilenen.satirlar.length - rapor.kaydedildi;
      }
    } catch (err) {
      rapor.hatalar.push(err instanceof Error ? err.message : "Ürün taslağı kaydedilemedi.");
      rapor.atlandi = 1;
      const yenilenen = await islemiYukle(admin, storeId, kayit.islemKimligi).catch(() => null);
      if (yenilenen?.satirlar.length) guncelKayit = yenilenen;
      rapor.bekleyen = guncelKayit.satirlar.filter((satir) => !satir.urunId).length;
    }
  }
  const bagliIdler = guncelKayit.satirlar.flatMap((satir) => satir.urunId ? [satir.urunId] : []);
  rapor.kaydedildi = 0;
  if (bagliIdler.length) {
    const urunler = await admin.from("products").select("id,is_visible,fatura_kanit")
      .eq("store_id", storeId).in("id", bagliIdler);
    if (urunler.error || !Array.isArray(urunler.data)) {
      rapor.hatalar.push("Kayıtlı ürün taslakları doğrulanamadı.");
    } else {
      rapor.kaydedildi = urunler.data.filter((urun) => urun.is_visible === false).length;
      if (urunler.data.some((urun) => urun.fatura_kanit?.gorselDurumu === "aktarim-bekliyor") &&
        !rapor.hatalar.some((hata) => hata.includes("fotoğraf"))) {
        rapor.hatalar.push("Bazı ürün fotoğrafları henüz aktarılamadı. Kartları düzenleyip yeniden kaydedebilirsin.");
      }
    }
  }
  const durum = await admin.from("invoice_provider_runs")
    .update({ error_code: rapor.hatalar.length ? "FATURA_TASLAKLARI_EKSIK" : null })
    .eq("job_id", kayit.islemKimligi).eq("store_id", storeId).eq("state", "processed");
  if (durum.error) rapor.hatalar.push("Taslak kayıt durumu saklanamadı.");
  // Bekleyen satırlar hata içerse bile işlem tamamlanmış sayılamaz.
  const hazirlaniyor = rapor.bekleyen > 0;
  return {
    ...islemYaniti(guncelKayit),
    tamam: !hazirlaniyor, hazirlaniyor,
    taslaklar: faturaTaslaklari(guncelKayit.satirlar, kayit.islemKimligi),
    otomatikTaslakRaporu: rapor,
    ...(rapor.hatalar.length ? { taslakKayitUyarisi: rapor.hatalar.join(" ") } : {}),
  };
}
