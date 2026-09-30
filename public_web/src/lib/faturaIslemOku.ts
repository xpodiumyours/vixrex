import type { SupabaseClient } from "@supabase/supabase-js";
import type { EslesmisFaturaSatiri, KatalogBilgisi } from "@/lib/faturaEslestir";
import { sonucOzeti } from "@/lib/faturaEslestir";
import { durumGecerliMi } from "@/lib/faturaKartDurumu";

export interface SahipDurumu {
  satisFiyati: string;
  stok: string;
  stokOnaylandi: boolean;
  kategoriId: string;
  onayli: boolean;
  esnafGorselleri: string[];
  ozellikler: Record<string, string>;
}

export interface KayitliSatir extends EslesmisFaturaSatiri {
  sahipDurumu: SahipDurumu | null;
  urunId: string | null;
}

export interface KayitliIslem {
  islemKimligi: string;
  durum: string;
  tedarikci: string;
  tedarikciVergiNo: string;
  tedarikciAdres: string;
  tedarikciSite: string;
  belgeAdedi: number | null;
  belgeToplami: number | null;
  belgeUyarisi: string | null;
  belge: {
    belgeTuru: string;
    belgeNo: string;
    belgeTarihi: string | null;
    malBedeli: number | null;
    kdvTutari: number | null;
    indirimTutari: number | null;
    odenecekToplam: number | null;
  };
  satirlar: KayitliSatir[];
}

export interface IslemOzeti {
  islemKimligi: string;
  durum: string;
  tedarikci: string;
  olusturma: string;
  satirSayisi: number;
}

function sayiVeyaNull(deger: unknown): number | null {
  if (deger === null || deger === undefined || deger === "") return null;
  const n = Number(deger);
  return Number.isFinite(n) ? n : null;
}

function metin(deger: unknown, sinir: number): string {
  return typeof deger === "string" ? deger.slice(0, sinir) : "";
}

export function sahipDurumunuTemizle(ham: unknown): SahipDurumu | null {
  if (!ham || typeof ham !== "object") return null;
  const girdi = ham as Record<string, unknown>;
  const gorseller = Array.isArray(girdi.esnafGorselleri)
    ? girdi.esnafGorselleri
        .filter((adres): adres is string => typeof adres === "string" && adres.startsWith("https://"))
        .map((adres) => adres.slice(0, 500))
        .slice(0, 11)
    : [];
  const ozellikler: Record<string, string> = {};
  if (girdi.ozellikler && typeof girdi.ozellikler === "object" && !Array.isArray(girdi.ozellikler)) {
    for (const [anahtar, deger] of Object.entries(girdi.ozellikler as Record<string, unknown>).slice(0, 20)) {
      if (typeof deger === "string" && anahtar.length <= 40) ozellikler[anahtar] = deger.slice(0, 200);
    }
  }
  return {
    ozellikler,
    satisFiyati: metin(girdi.satisFiyati, 20),
    stok: metin(girdi.stok, 10),
    stokOnaylandi: girdi.stokOnaylandi === true,
    kategoriId: metin(girdi.kategoriId, 64),
    onayli: girdi.onayli === true,
    esnafGorselleri: gorseller,
  };
}

export async function islemiYukle(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
): Promise<KayitliIslem | null> {
  const is = await admin
    .from("invoice_jobs")
    .select(
      "id,status,supplier_name,supplier_tax_id,supplier_address,supplier_site,document_adet,document_total,document_warning,document_type,document_no,document_date,goods_total,vat_total,discount_total,payable_total",
    )
    .eq("id", islemKimligi)
    .eq("store_id", storeId)
    .maybeSingle();
  if (!is.data?.id) return null;

  const satirlar = await admin
    .from("invoice_job_lines")
    .select(
      "id,line_index,raw_line,model,product_name,barcode,variant_name,size_text,qty,unit_price,line_total,confidence,outcome,brand,warning,catalog_snapshot,conflict_snapshot,owner_state,product_id",
    )
    .eq("job_id", islemKimligi)
    .order("line_index", { ascending: true });
  const kayitlar = Array.isArray(satirlar.data) ? satirlar.data : [];

  return {
    islemKimligi: String(is.data.id),
    durum: String(is.data.status ?? ""),
    tedarikci: String(is.data.supplier_name ?? ""),
    tedarikciVergiNo: String(is.data.supplier_tax_id ?? ""),
    tedarikciAdres: String(is.data.supplier_address ?? ""),
    tedarikciSite: String(is.data.supplier_site ?? ""),
    belgeAdedi: sayiVeyaNull(is.data.document_adet),
    belgeToplami: sayiVeyaNull(is.data.document_total),
    belgeUyarisi: is.data.document_warning ? String(is.data.document_warning) : null,
    belge: {
      belgeTuru: String(is.data.document_type ?? ""),
      belgeNo: String(is.data.document_no ?? ""),
      belgeTarihi: is.data.document_date ? String(is.data.document_date) : null,
      malBedeli: sayiVeyaNull(is.data.goods_total),
      kdvTutari: sayiVeyaNull(is.data.vat_total),
      indirimTutari: sayiVeyaNull(is.data.discount_total),
      odenecekToplam: sayiVeyaNull(is.data.payable_total),
    },
    satirlar: kayitlar.map((kayit) => ({
      hamSatir: String(kayit.raw_line ?? ""),
      model: String(kayit.model ?? ""),
      ad: String(kayit.product_name ?? ""),
      barkod: String(kayit.barcode ?? ""),
      varyant: String(kayit.variant_name ?? ""),
      beden: String(kayit.size_text ?? ""),
      marka: String(kayit.brand ?? ""),
      adet: sayiVeyaNull(kayit.qty),
      alisBirimFiyat: sayiVeyaNull(kayit.unit_price),
      satirToplam: sayiVeyaNull(kayit.line_total),
      guven: sayiVeyaNull(kayit.confidence) ?? 0,
      katalog: (kayit.catalog_snapshot as KatalogBilgisi | null) ?? null,
      sonuc: durumGecerliMi(kayit.outcome) ? kayit.outcome : "eksik",
      celiski: (kayit.conflict_snapshot as EslesmisFaturaSatiri["celiski"]) ?? undefined,
      uyari: kayit.warning ? String(kayit.warning) : undefined,
      sahipDurumu: sahipDurumunuTemizle(kayit.owner_state),
      urunId: kayit.product_id ? String(kayit.product_id) : null,
    })),
  };
}

export function islemYaniti(islem: KayitliIslem): Record<string, unknown> {
  return {
    tamam: true,
    tekrar: true,
    satirlar: islem.satirlar,
    belgeToplami: islem.belgeToplami,
    belgeAdedi: islem.belgeAdedi,
    ...(islem.belgeUyarisi ? { belgeUyarisi: islem.belgeUyarisi } : {}),
    tedarikci: islem.tedarikci,
    tedarikciVergiNo: islem.tedarikciVergiNo,
    tedarikciAdres: islem.tedarikciAdres,
    tedarikciSite: islem.tedarikciSite,
    katalogEslesmesi: islem.satirlar.filter((satir) => satir.katalog !== null).length,
    sonucOzeti: sonucOzeti(islem.satirlar),
    islemKimligi: islem.islemKimligi,
    belge: islem.belge,
    ayniAlisveris: [],
  };
}

export async function islemleriListele(
  admin: SupabaseClient,
  storeId: string,
): Promise<IslemOzeti[]> {
  const isler = await admin
    .from("invoice_jobs")
    .select("id,status,supplier_name,created_at")
    .eq("store_id", storeId)
    .order("created_at", { ascending: false })
    .limit(20);
  const kayitlar = Array.isArray(isler.data) ? isler.data : [];

  const sonuc: IslemOzeti[] = [];
  for (const kayit of kayitlar) {
    const say = await admin
      .from("invoice_job_lines")
      .select("id", { count: "exact", head: true })
      .eq("job_id", kayit.id);
    sonuc.push({
      islemKimligi: String(kayit.id),
      durum: String(kayit.status ?? ""),
      tedarikci: String(kayit.supplier_name ?? ""),
      olusturma: String(kayit.created_at ?? ""),
      satirSayisi: say.count ?? 0,
    });
  }
  return sonuc;
}

export async function urundenIslemBul(
  admin: SupabaseClient,
  storeId: string,
  urunId: string,
): Promise<string | null> {
  const satir = await admin
    .from("invoice_job_lines")
    .select("job_id")
    .eq("product_id", urunId)
    .limit(1)
    .maybeSingle();
  const islemKimligi = satir.data?.job_id ? String(satir.data.job_id) : "";
  if (!islemKimligi) return null;

  const is = await admin
    .from("invoice_jobs")
    .select("id")
    .eq("id", islemKimligi)
    .eq("store_id", storeId)
    .maybeSingle();
  return is.data?.id ? String(is.data.id) : null;
}

export async function parmakIzindenIslemBul(
  admin: SupabaseClient,
  storeId: string,
  parmakIzi: string,
): Promise<string | null> {
  const is = await admin
    .from("invoice_jobs")
    .select("id")
    .eq("store_id", storeId)
    .eq("document_fingerprint", parmakIzi)
    .maybeSingle();
  if (!is.data?.id) return null;
  const say = await admin
    .from("invoice_job_lines")
    .select("id", { count: "exact", head: true })
    .eq("job_id", is.data.id);
  return (say.count ?? 0) > 0 ? String(is.data.id) : null;
}

export async function sahipDurumlariniKaydet(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
  guncellemeler: Array<{ satirSirasi: number; sahipDurumu: SahipDurumu }>,
): Promise<boolean> {
  const is = await admin
    .from("invoice_jobs")
    .select("id")
    .eq("id", islemKimligi)
    .eq("store_id", storeId)
    .maybeSingle();
  if (!is.data?.id) return false;

  const simdi = new Date().toISOString();
  for (const guncelleme of guncellemeler) {
    const { error } = await admin
      .from("invoice_job_lines")
      .update({ owner_state: guncelleme.sahipDurumu, owner_state_updated_at: simdi })
      .eq("job_id", islemKimligi)
      .eq("line_index", guncelleme.satirSirasi);
    if (error) return false;
  }
  return true;
}
