import { createHash } from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { DogrulanmisSatir } from "@/lib/faturaUrunBaglantisi";
import type { HazirUrunGirdisi } from "@/lib/productIntake";
import { normalizeProductVariants } from "@/lib/productRichData";
import { yonetilenUrunGorseliMi } from "@/lib/productImagePolicy";
import { kaynakGorselleriniHazirla, sayfaGorselAlanAdlari } from "@/lib/faturaGorsel";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { kategoriBirlestir } from "@/lib/kategoriBirlesim";

export async function kayitliFaturaKatalogunuUygula(args: {
  admin: SupabaseClient;
  storeId: string;
  editToken: string;
  girdi: HazirUrunGirdisi;
  satir: DogrulanmisSatir;
  kategoriOnbellegi: Map<string, { id: string; templateKey: string }>;
}): Promise<string | null> {
  const { admin, storeId, editToken, girdi, satir, kategoriOnbellegi } = args;
  if (satir.sonuc !== "kanitli" && !satir.katalog) return null;
  const katalog = satir.katalog;
  if (!katalog || typeof katalog.resmiAd !== "string" || typeof katalog.kaynak !== "string") {
    return "Kayıtlı resmî ürün kaynağı eksik; yeniden eşleştir.";
  }
  girdi.name = katalog.resmiAd;
  girdi.description = typeof katalog.aciklama === "string" ? katalog.aciklama : "";
  girdi.brand = typeof katalog.marka === "string" ? katalog.marka : null;
  if (Array.isArray(katalog.gorseller)) {
    girdi.imageUrls = katalog.gorseller.filter((url): url is string => typeof url === "string");
  }
  girdi.metadata = {
    ...girdi.metadata,
    attributes: [],
    manufacturerSource: undefined,
    ...faturaKatalogMetadatasi(katalog),
  };
  const varyantlar = Array.isArray(katalog.urunVaryantlari) ? katalog.urunVaryantlari : [];
  girdi.variants = normalizeProductVariants(varyantlar.map((raw) => {
    const variant = raw && typeof raw === "object" ? raw as Record<string, unknown> : {};
    const secenekler = Array.isArray(variant.secenekler) ? variant.secenekler : [];
    const options: Record<string, string> = {};
    for (const secenek of secenekler) {
      if (!secenek || typeof secenek !== "object") continue;
      const option = secenek as Record<string, unknown>;
      if (typeof option.key === "string" && typeof option.value === "string") options[option.key] = option.value;
    }
    return { id: variant.id, options, barcode: variant.barkod, imageUrls: variant.gorseller };
  }), true);
  const lunaKategori = typeof katalog.kategori === "string" ? katalog.kategori.trim() : "";
  if (!lunaKategori) return null;
  const birlesik = kategoriBirlestir(lunaKategori);
  const anahtar = birlesik.anahtar;
  let kategori = kategoriOnbellegi.get(anahtar);
  if (!kategori) {
    const mevcutlar = await admin.from("product_categories").select("id,name,product_template_key")
      .eq("store_id", storeId);
    if (mevcutlar.error) return "Luna'nın kategorisi okunamadı; tekrar dene.";
    const eslesen = (Array.isArray(mevcutlar.data) ? mevcutlar.data : []).find(
      (satir: { name?: string | null; id?: unknown; product_template_key?: string | null }) =>
        kategoriBirlestir(String(satir.name ?? "")).anahtar === anahtar,
    );
    if (eslesen) {
      kategori = { id: String(eslesen.id), templateKey: eslesen.product_template_key || "generic" };
    } else {
      const ekleme = await admin.rpc("upsert_store_category_v2", {
        p_store_id: storeId, p_edit_token: editToken,
        p_name: birlesik.ad, p_template_key: "generic",
        p_slug: `luna-${createHash("sha256").update(anahtar).digest("hex").slice(0, 24)}`,
      });
      if (!ekleme.error && ekleme.data?.success === true && typeof ekleme.data.id === "string") {
        kategori = { id: ekleme.data.id, templateKey: "generic" };
      }
    }
    if (!kategori) return "Luna'nın kategorisi kaydedilemedi; tekrar dene.";
    kategoriOnbellegi.set(anahtar, kategori);
  }
  girdi.categoryId = kategori.id;
  girdi.metadata = { ...girdi.metadata, templateKey: kategori.templateKey };
  return null;
}

export async function faturaUrunGorselleriniAktar(args: {
  admin: SupabaseClient;
  slug: string;
  girdi: HazirUrunGirdisi;
  satir: DogrulanmisSatir;
  sonTarih?: number;
}) {
  const { admin, slug, girdi, satir } = args;
  const kaynakGorselleri = girdi.imageUrls.filter(
    (adres) => yonetilenUrunGorseliMi(adres) || satir.izinliGorseller.has(adres.trim()),
  );
  const disGorseller = kaynakGorselleri.filter((adres) => !yonetilenUrunGorseliMi(adres));
  let urunGorselleri = kaynakGorselleri;
  let gorselDurumu = "";
  let gorselKaynaklari: Array<Record<string, unknown>> = [];
  let gorselRedleri: Array<{ kaynakGorsel: string; sebep: string }> = [];
  const resmiSayfa = typeof satir.katalog?.kaynak === "string" ? satir.katalog.kaynak.trim() : "";
  const resmiAlanlar = resmiSayfa ? await sayfaGorselAlanAdlari(resmiSayfa) : [];
  const aktarilacakGorseller = [...new Set([...disGorseller,
    ...girdi.variants.flatMap((variant) => variant.imageUrls ?? []).filter((url) => !yonetilenUrunGorseliMi(url)),
  ])];
  if (aktarilacakGorseller.length > 0) {
    const hazir = await kaynakGorselleriniHazirla({
      admin, slug,
      kaynakSayfa: typeof satir.katalog?.kaynak === "string" ? satir.katalog.kaynak : "",
      adaylar: aktarilacakGorseller,
      sonTarih: args.sonTarih,
      izinliAlanAdlari: resmiAlanlar,
    });
    gorselRedleri = hazir.reddedilenler.map((red) => ({ kaynakGorsel: red.kaynakGorsel, sebep: String(red.sebep) }));
    const depodaki = new Map(hazir.gorseller.map((gorsel) => [gorsel.kaynakGorsel, gorsel]));
    const altyapiHatasi = hazir.reddedilenler.some((red) => red.sebep !== "kaynak-uyumsuz");
    urunGorselleri = kaynakGorselleri.flatMap((adres) => {
      if (yonetilenUrunGorseliMi(adres)) return [adres];
      const kopya = depodaki.get(adres);
      return kopya ? [kopya.url] : [];
    });
    gorselKaynaklari = hazir.gorseller.map((gorsel) => ({
      depoUrl: gorsel.url, kaynakGorsel: gorsel.kaynakGorsel,
      kaynakSayfa: gorsel.kaynakSayfa, genislik: gorsel.genislik, yukseklik: gorsel.yukseklik,
    }));
    gorselDurumu = altyapiHatasi ? "aktarim-bekliyor" : urunGorselleri.length === 0 ? "gorsel-yok" : "depoda";
  }
  const depoGorselleri = new Map(gorselKaynaklari.map((kaynak) =>
    [String(kaynak.kaynakGorsel || ""), String(kaynak.depoUrl || "")]));
  girdi.variants = girdi.variants.map((variant) => ({
    ...variant,
    imageUrls: variant.imageUrls?.map((url) =>
      depoGorselleri.get(url) || (yonetilenUrunGorseliMi(url) ? url : "")).filter(Boolean),
  }));
  if (!gorselDurumu) gorselDurumu = urunGorselleri.length === 0 ? "gorsel-yok" : "depoda";
  return { urunGorselleri, gorselDurumu, gorselKaynaklari, gorselRedleri };
}
