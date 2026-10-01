import type { SupabaseClient } from "@supabase/supabase-js";
import { durumGecerliMi, type KartDurumu } from "@/lib/faturaKartDurumu";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface DogrulanmisSatir {
  satirId: string;
  sonuc: KartDurumu;
  urunId: string | null;
  izinliGorseller: Set<string>;
  katalog: Record<string, unknown> | null;
  alisBirimFiyati: number | null;
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
    .select("id,outcome,product_id,catalog_snapshot,unit_price")
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
  const izinli = new Set<string>(
    (Array.isArray(gorseller.data) ? gorseller.data : [])
      .filter((kayit) => String(kayit.usage_status ?? "") !== "denied")
      .map((kayit) => String(kayit.image_url ?? "").trim())
      .filter(Boolean),
  );

  if (gorseller.error) return null;

  return {
    katalog: satir.data.catalog_snapshot && typeof satir.data.catalog_snapshot === "object" ? satir.data.catalog_snapshot : null,
    alisBirimFiyati: typeof satir.data.unit_price === "number" ? satir.data.unit_price : null,
    satirId: String(satir.data.id),
    sonuc: durumGecerliMi(satir.data.outcome) ? satir.data.outcome : "eksik",
    urunId: satir.data.product_id ? String(satir.data.product_id) : null,
    izinliGorseller: izinli,
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

export async function faturaUrununuKaydet(
  admin: SupabaseClient,
  args: { storeId: string; editToken: string; satirId: string; girdi: Record<string, unknown>; kanit: Record<string, unknown>; alisFiyati: number | null },
): Promise<{ id: string; slug: string; created: boolean; kayit: "yeni" | "guncellendi" | "mevcut" }> {
  const { data, error } = await admin.rpc("save_invoice_product", {
    p_store_id: args.storeId,
    p_edit_token: args.editToken,
    p_line_id: args.satirId,
    p_product: args.girdi,
    p_evidence: args.kanit,
    p_purchase_price: args.alisFiyati,
  });
  if (error || data?.success !== true || !data.id) throw new Error(error?.message || "FATURA_KAYDI_TAMAMLANAMADI");
  return { id: String(data.id), slug: String(data.slug ?? ""), created: data.created === true, kayit: data.kayit };
}
