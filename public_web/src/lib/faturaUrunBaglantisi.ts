import type { SupabaseClient } from "@supabase/supabase-js";
import { durumGecerliMi, type KartDurumu } from "@/lib/faturaKartDurumu";
import { normalizeProductMetadata, normalizeProductVariants } from "@/lib/productRichData";
import { updateRichCoreProduct } from "@/lib/productCoreServer";
import { gorselHakKayitlariniDerle, type GorselHakDurumu } from "@/lib/faturaGorselHakDenetimi";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface DogrulanmisSatir {
  satirId: string;
  sonuc: KartDurumu;
  urunId: string | null;
  izinliGorseller: Set<string>;
  /** Salt-okunur denetim: bu alan yayin izni yerine gecmez ve yayini durdurmaz. */
  gorselHakDurumlari?: ReadonlyMap<string, GorselHakDurumu>;
  katalog: Record<string, unknown> | null;
  alisBirimFiyati: number | null;
  varyant: string;
  beden: string;
}

export async function satiriDogrula(
  admin: SupabaseClient,
  storeId: string,
  kimlik: { islemKimligi?: unknown; satirSirasi?: unknown },
  _iddia: KartDurumu,
): Promise<DogrulanmisSatir | null> {
  void _iddia;
  const islemKimligi = typeof kimlik.islemKimligi === "string" ? kimlik.islemKimligi.trim() : "";
  const sira = kimlik.satirSirasi;
  if (!KIMLIK.test(islemKimligi) || typeof sira !== "number" || !Number.isInteger(sira) || sira < 0) {
    return null;
  }

  const is = await admin
    .from("invoice_jobs")
    .select("id")
    .eq("id", islemKimligi)
    .eq("store_id", storeId)
    .maybeSingle();
  if (!is.data?.id) return null;

  const satir = await admin
    .from("invoice_job_lines")
    .select("id,outcome,product_id,catalog_snapshot,unit_price,variant_name,size_text")
    .eq("job_id", islemKimligi)
    .eq("line_index", sira)
    .maybeSingle();
  if (!satir.data?.id) return null;

  // Kullanım izni: kümeye yalnızca açıkça `denied` işaretlenmemiş görseller girer.
  // `unknown` bilinçli olarak KALIR — kilitli kapsam: üretici fotoğrafı karta
  // girer ve yayınlanır, izin turu sonra yürür (bkz. products/batch yorumu).
  // Süzgeç Dart/TS tarafında, `.neq()` ile değil: SQL'de `usage_status <> 'denied'`
  // NULL satırı da düşürür; yazılmamış usage_status 'denied' sayılmamalı.
  const gorseller = await admin
    .from("invoice_image_rights")
    .select("image_url,usage_status")
    .eq("line_id", satir.data.id);
  const hakKayitlari = Array.isArray(gorseller.data) ? gorseller.data : [];
  // Mevcut davranis korunur: unknown karta girebilir, acik ret engellenir.
  const izinli = new Set<string>(
    hakKayitlari
      .filter((kayit) => String(kayit.usage_status ?? "") !== "denied")
      .map((kayit) => String(kayit.image_url ?? "").trim())
      .filter(Boolean),
  );
  const hakDurumlari = gorselHakKayitlariniDerle(hakKayitlari);

  if (gorseller.error) return null;

  return {
    katalog: satir.data.catalog_snapshot && typeof satir.data.catalog_snapshot === "object" ? satir.data.catalog_snapshot : null,
    alisBirimFiyati: typeof satir.data.unit_price === "number" ? satir.data.unit_price : null,
    satirId: String(satir.data.id),
    sonuc: durumGecerliMi(satir.data.outcome) ? satir.data.outcome : "eksik",
    urunId: satir.data.product_id ? String(satir.data.product_id) : null,
    izinliGorseller: izinli,
    gorselHakDurumlari: hakDurumlari,
    varyant: String(satir.data.variant_name ?? ""),
    beden: String(satir.data.size_text ?? ""),
  };
}

export async function satiriUrunleBagla(
  admin: SupabaseClient,
  satirId: string,
  urunId: string,
): Promise<boolean> {
  const { error } = await admin
    .from("invoice_job_lines")
    .update({ product_id: urunId, product_linked_at: new Date().toISOString() })
    .eq("id", satirId);
  return !error;
}

export async function urunuGeriAl(
  admin: SupabaseClient,
  storeId: string,
  urunId: string,
): Promise<void> {
  const { error } = await admin.from("products").delete().eq("id", urunId).eq("store_id", storeId);
  if (error) {
    console.error("[faturaUrunBaglantisi] yarim urun geri alinamadi:", error.message);
  }
}

export interface MevcutUrunOzeti {
  id: string;
  stockQuantity: number | null;
  stockStatus: string | null;
  gorunur: boolean;
}

export async function mevcutUrunuOku(
  admin: SupabaseClient,
  storeId: string,
  urunId: string,
): Promise<MevcutUrunOzeti | null> {
  const { data } = await admin
    .from("products")
    .select("id,stock_quantity,stock_status,is_visible")
    .eq("id", urunId)
    .eq("store_id", storeId)
    .maybeSingle();
  if (!data?.id) return null;
  return {
    id: String(data.id),
    stockQuantity: typeof data.stock_quantity === "number" ? data.stock_quantity : null,
    stockStatus: typeof data.stock_status === "string" ? data.stock_status : null,
    gorunur: data.is_visible === true,
  };
}

const URUN_ALANLARI =
  "id,slug,name,description,price_text,price_amount,image_urls,category_id,stock_status,stock_quantity,old_price_amount,badge_tag,fulfillment_region,brand,barcode,metadata,variants,is_visible,is_active";

const HARF_KATLAMA: Record<string, string> = {
  ş: "s",
  ı: "i",
  ğ: "g",
  ü: "u",
  ö: "o",
  ç: "c",
  â: "a",
  î: "i",
  û: "u",
};

function harfKatla(metin: string): string {
  return metin
    .toLocaleLowerCase("tr-TR")
    .replace(/[şığüöçâîû]/g, (harf) => HARF_KATLAMA[harf] ?? harf)
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function urunAdAnahtari(deger: unknown): string {
  return harfKatla(String(deger ?? ""));
}

const MIKTAR_KALIBI = /(\d+(?:[.,]\d+)?)\s*(kg|g|gr|gram|ml|cl|lt|l|litre|adet)\b/;

function urunAdGovdesi(deger: unknown, marka: unknown): string {
  const katlanmis = harfKatla(String(deger ?? "").replace(/\([^)]*\)/g, " "));
  const markaKatlanmis = harfKatla(String(marka ?? ""));
  const markasiz =
    markaKatlanmis && katlanmis.startsWith(`${markaKatlanmis} `)
      ? katlanmis.slice(markaKatlanmis.length + 1)
      : katlanmis;
  return markasiz.replace(MIKTAR_KALIBI, " ").replace(/\s+/g, " ").trim();
}

function miktarImzasi(deger: unknown): string | null {
  const eslesme = MIKTAR_KALIBI.exec(harfKatla(String(deger ?? "")));
  if (!eslesme) return null;
  const deger_ = Number(eslesme[1].replace(",", "."));
  if (!Number.isFinite(deger_) || deger_ <= 0) return null;
  switch (eslesme[2]) {
    case "kg":
      return `${Math.round(deger_ * 1000)} g`;
    case "g":
    case "gr":
    case "gram":
      return `${Math.round(deger_)} g`;
    case "ml":
      return `${Math.round(deger_)} ml`;
    case "cl":
      return `${Math.round(deger_ * 10)} ml`;
    case "l":
    case "lt":
    case "litre":
      return `${Math.round(deger_ * 1000)} ml`;
    default:
      return `${Math.round(deger_)} adet`;
  }
}

function varyantImzalari(deger: unknown): Set<string> {
  const liste = Array.isArray(deger) ? deger : [];
  const imzalar = new Set<string>();
  for (const varyant of liste) {
    const secenekler =
      varyant && typeof varyant === "object"
        ? ((varyant as { options?: Record<string, unknown> }).options ?? {})
        : {};
    const imza = Object.values(secenekler)
      .map((secenek) => String(secenek ?? "").toLocaleLowerCase("tr-TR").trim())
      .filter(Boolean)
      .sort()
      .join("|");
    if (imza) imzalar.add(imza);
  }
  return imzalar;
}

function varyantlarUyusuyor(bir: unknown, iki: unknown): boolean {
  const birImza = varyantImzalari(bir);
  const ikiImza = varyantImzalari(iki);
  if (birImza.size === 0 && ikiImza.size === 0) return true;
  for (const imza of birImza) if (ikiImza.has(imza)) return true;
  return false;
}

export function ayniUrunMu(
  mevcut: Record<string, unknown>,
  girdi: Record<string, unknown>,
): boolean {
  if (urunAdAnahtari(mevcut.brand) !== urunAdAnahtari(girdi.brand)) return false;
  const govdeMevcut = urunAdGovdesi(mevcut.name, mevcut.brand);
  const govdeGirdi = urunAdGovdesi(girdi.name, girdi.brand);
  if (!govdeMevcut || !govdeGirdi || govdeMevcut !== govdeGirdi) return false;
  const miktarMevcut = miktarImzasi(mevcut.name);
  const miktarGirdi = miktarImzasi(girdi.name);
  if (miktarMevcut && miktarGirdi && miktarMevcut !== miktarGirdi) return false;
  return varyantlarUyusuyor(mevcut.variants, girdi.variants);
}

export async function ayniUrunuBul(
  admin: SupabaseClient,
  storeId: string,
  girdi: Record<string, unknown>,
): Promise<Record<string, unknown> | null> {
  const barkod = String(girdi.barcode ?? "").trim();
  if (barkod) {
    const { data } = await admin
      .from("products")
      .select(URUN_ALANLARI)
      .eq("store_id", storeId)
      .eq("barcode", barkod)
      .eq("is_active", true)
      .maybeSingle();
    if (data?.id && varyantlarUyusuyor(data.variants, girdi.variants)) return data as Record<string, unknown>;
  }
  if (!urunAdAnahtari(girdi.name)) return null;
  const { data } = await admin.from("products").select(URUN_ALANLARI).eq("store_id", storeId);
  for (const urun of Array.isArray(data) ? data : []) {
    if (urun.is_active === false) continue;
    if (!ayniUrunMu(urun as Record<string, unknown>, girdi)) continue;
    return urun as Record<string, unknown>;
  }
  return null;
}

function metadataMiktari(kayit: Record<string, unknown>): string | null {
  const metadata = kayit.metadata;
  if (!metadata || typeof metadata !== "object") return null;
  const ozellikler = (metadata as { attributes?: unknown }).attributes;
  if (!Array.isArray(ozellikler)) return null;
  for (const ozellik of ozellikler) {
    if (!ozellik || typeof ozellik !== "object") continue;
    const kayitOzellik = ozellik as { key?: unknown; value?: unknown };
    if (String(kayitOzellik.key ?? "").toLocaleLowerCase("tr-TR") !== "netquantity") continue;
    const imza = miktarImzasi(kayitOzellik.value);
    if (imza) return imza;
  }
  return null;
}

/** Ad yazmıyorsa "Gramaj / hacim" alanından; ikisi de yoksa null. */
function urunMiktari(kayit: Record<string, unknown>): string | null {
  return miktarImzasi(kayit.name) ?? metadataMiktari(kayit);
}

function kelimeler(metin: string): string[] {
  return metin.split(" ").filter((kelime) => kelime.length >= 3);
}

export function ortakKelimeVar(bir: string, iki: string): boolean {
  const birKume = new Set(kelimeler(bir));
  return kelimeler(iki).some((kelime) => birKume.has(kelime));
}

function govdeDigeriniKapsiyor(bir: string, iki: string): boolean {
  const birKume = new Set(kelimeler(bir));
  const ikiKume = new Set(kelimeler(iki));
  if (birKume.size === 0 || ikiKume.size === 0) return false;
  const [kucuk, buyuk] = birKume.size <= ikiKume.size ? [birKume, ikiKume] : [ikiKume, birKume];
  for (const kelime of kucuk) if (!buyuk.has(kelime)) return false;
  return true;
}

/**
 * "Aynı ürün olabilir" sorusunun kuralı. Bu fonksiyon KART BİRLEŞTİRMEZ;
 * yalnız esnafa sorulacak bir aday üretir. Tahminle birleştirme yapılmaz.
 *
 * Soru yalnız barkodsuz satırda sorulur. Aynı marka + aynı miktar + farklı ad
 * yazımı gerekir; iki farklı barkod asla aday olmaz.
 */
export function ayniUrunOlabilirMi(
  mevcut: Record<string, unknown>,
  girdi: Record<string, unknown>,
): boolean {
  if (String(girdi.barcode ?? "").trim()) return false;
  const marka = urunAdAnahtari(girdi.brand);
  if (!marka || marka !== urunAdAnahtari(mevcut.brand)) return false;

  const govdeGirdi = urunAdGovdesi(girdi.name, girdi.brand);
  const govdeMevcut = urunAdGovdesi(mevcut.name, mevcut.brand);
  if (!govdeGirdi || !govdeMevcut || govdeGirdi === govdeMevcut) return false;

  const miktarGirdi = urunMiktari(girdi);
  const miktarMevcut = urunMiktari(mevcut);

  // Miktar iki tarafta da yazıyorsa aynı olmalı: 250 ml ile 330 ml ayrı üründür.
  if (miktarGirdi && miktarMevcut && miktarGirdi !== miktarMevcut) return false;

  const ayniOlcu = Boolean(miktarGirdi && miktarMevcut) && ortakKelimeVar(govdeGirdi, govdeMevcut);
  // Miktar yazmıyorsa daha dar bir kapı: biri diğerinin kelimelerini kapsamalı
  // (ör. "kristal toz şeker" / "toz şeker polietilen ambalaj").
  const kapsananAd = govdeDigeriniKapsiyor(govdeGirdi, govdeMevcut);
  if (!ayniOlcu && !kapsananAd) return false;

  return varyantlarUyusuyor(mevcut.variants, girdi.variants);
}

export async function ayniUrunAdayiBul(
  admin: SupabaseClient,
  storeId: string,
  girdi: Record<string, unknown>,
): Promise<Record<string, unknown> | null> {
  if (String(girdi.barcode ?? "").trim()) return null;
  if (!urunAdAnahtari(girdi.name)) return null;
  const { data } = await admin.from("products").select(URUN_ALANLARI).eq("store_id", storeId);
  for (const urun of Array.isArray(data) ? data : []) {
    if (urun.is_active === false) continue;
    if (!ayniUrunOlabilirMi(urun as Record<string, unknown>, girdi)) continue;
    return urun as Record<string, unknown>;
  }
  return null;
}

export type FaturaKayitSonucu =
  | { durum: "kaydedildi"; id: string; slug: string; created: boolean; kayit: "yeni" | "guncellendi" | "mevcut" }
  | { durum: "onay-bekliyor"; aday: { id: string; ad: string } };

interface KayitGirdisi {
  storeId: string;
  editToken: string;
  satirId: string;
  girdi: Record<string, unknown>;
  alisFiyati: number | null;
}

async function urunKimligiyleOku(
  admin: SupabaseClient,
  storeId: string,
  urunId: string,
): Promise<Record<string, unknown> | null> {
  const { data } = await admin
    .from("products")
    .select(URUN_ALANLARI)
    .eq("store_id", storeId)
    .eq("id", urunId)
    .maybeSingle();
  if (!data?.id || data.is_active === false) return null;
  return data as Record<string, unknown>;
}

/** Var olan karta bağlar: stok toplanır, mevcut fiyat korunur, fotoğraflar birleşir. */
async function mevcudaBagla(
  admin: SupabaseClient,
  args: KayitGirdisi,
  mevcut: Record<string, unknown>,
): Promise<FaturaKayitSonucu | null> {
  const baglandi = await satiriUrunleBagla(admin, args.satirId, String(mevcut.id));
  if (!baglandi) return null;

  const mevcutStok = typeof mevcut.stock_quantity === "number" ? mevcut.stock_quantity : null;
  const eklenenStok = typeof args.girdi.stockQuantity === "number" ? args.girdi.stockQuantity : null;
  const yeniStok =
    mevcutStok == null && eklenenStok == null ? null : (mevcutStok ?? 0) + (eklenenStok ?? 0);
  const gorseller = [
    ...new Set([
      ...(Array.isArray(mevcut.image_urls) ? mevcut.image_urls.map((adres) => String(adres)) : []),
      ...(Array.isArray(args.girdi.imageUrls) ? args.girdi.imageUrls.map((adres) => String(adres)) : []),
    ]),
  ];
  await updateRichCoreProduct({
    admin,
    productId: String(mevcut.id),
    editToken: args.editToken,
    name: String(mevcut.name ?? args.girdi.name ?? ""),
    description: String(mevcut.description ?? args.girdi.description ?? ""),
    priceText: String(mevcut.price_text ?? args.girdi.priceText ?? ""),
    priceAmount:
      typeof mevcut.price_amount === "number"
        ? mevcut.price_amount
        : typeof args.girdi.priceAmount === "number"
          ? args.girdi.priceAmount
          : null,
    imageUrls: gorseller,
    categoryId: String(mevcut.category_id ?? args.girdi.categoryId ?? ""),
    stockStatus: String(mevcut.stock_status ?? args.girdi.stockStatus ?? ""),
    stockQuantity: yeniStok,
    oldPriceAmount: typeof mevcut.old_price_amount === "number" ? mevcut.old_price_amount : null,
    badgeTag: typeof mevcut.badge_tag === "string" ? mevcut.badge_tag : null,
    fulfillmentRegion: typeof mevcut.fulfillment_region === "string" ? mevcut.fulfillment_region : null,
    brand: typeof mevcut.brand === "string" ? mevcut.brand : null,
    barcode: String(mevcut.barcode ?? args.girdi.barcode ?? ""),
    metadata: normalizeProductMetadata(mevcut.metadata),
    variants: normalizeProductVariants(mevcut.variants),
    isVisible: mevcut.is_visible !== false,
  });
  if (typeof args.alisFiyati === "number" && args.alisFiyati > 0) {
    await admin
      .from("product_purchase_prices")
      .upsert(
        {
          product_id: String(mevcut.id),
          store_id: args.storeId,
          amount: args.alisFiyati,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "product_id" },
      );
  }
  return {
    durum: "kaydedildi",
    id: String(mevcut.id),
    slug: String(mevcut.slug ?? ""),
    created: false,
    kayit: "guncellendi",
  };
}

export async function faturaUrununuKaydet(
  admin: SupabaseClient,
  args: { storeId: string; editToken: string; satirId: string; girdi: Record<string, unknown>; kanit: Record<string, unknown>; alisFiyati: number | null },
): Promise<FaturaKayitSonucu> {
  let satirDurumu = await admin
    .from("invoice_job_lines")
    .select("product_id,merge_candidate_product_id,merge_decision")
    .eq("id", args.satirId)
    .maybeSingle();
  // Kolonlar henüz yoksa (migration sırası): satır kaydı durmaz, yalnız kilit kapalı kalır.
  if (satirDurumu.error) {
    satirDurumu = await admin
      .from("invoice_job_lines")
      .select("product_id")
      .eq("id", args.satirId)
      .maybeSingle();
  }
  const bagliSatir = Boolean(satirDurumu.data?.product_id);
  if (!satirDurumu.error && !bagliSatir) {
    const mevcut = await ayniUrunuBul(admin, args.storeId, args.girdi);
    if (mevcut) {
      const baglanan = await mevcudaBagla(admin, args, mevcut);
      if (baglanan) return baglanan;
    }

    // Barkodsuz satır: ad yazımı farklıysa aynı ürün olup olmadığı makinece
    // kanıtlanamaz. Kart sessizce açılmaz; aday gösterilip esnafa sorulur.
    if (!String(args.girdi.barcode ?? "").trim()) {
      const karar = String(satirDurumu.data?.merge_decision ?? "");
      if (karar !== "ayri") {
        const kayitliAdayId = String(satirDurumu.data?.merge_candidate_product_id ?? "");
        const aday = kayitliAdayId
          ? await urunKimligiyleOku(admin, args.storeId, kayitliAdayId)
          : await ayniUrunAdayiBul(admin, args.storeId, args.girdi);
        if (aday) {
          if (karar === "birlestir") {
            const baglanan = await mevcudaBagla(admin, args, aday);
            if (baglanan) return baglanan;
          } else if (String(aday.id) !== kayitliAdayId) {
            await admin
              .from("invoice_job_lines")
              .update({ merge_candidate_product_id: String(aday.id) })
              .eq("id", args.satirId);
          }
          return {
            durum: "onay-bekliyor",
            aday: { id: String(aday.id), ad: String(aday.name ?? "") },
          };
        }
      }
    }
  }
  const { data, error } = await admin.rpc("save_invoice_product", {
    p_store_id: args.storeId,
    p_edit_token: args.editToken,
    p_line_id: args.satirId,
    p_product: args.girdi,
    p_evidence: args.kanit,
    p_purchase_price: args.alisFiyati,
  });
  if (error || data?.success !== true || !data.id) throw new Error(error?.message || "FATURA_KAYDI_TAMAMLANAMADI");
  return {
    durum: "kaydedildi",
    id: String(data.id),
    slug: String(data.slug ?? ""),
    created: data.created === true,
    kayit: data.kayit,
  };
}
