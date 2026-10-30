import type { SupabaseClient } from "@supabase/supabase-js";

export interface FaturaOzetGirdisi {
  islemKimligi: string;
  satirSayisi: number;
  kartSayisi: number;
  gorselliSayisi: number | null;
  sureSaniye: number | null;
  hataKodu?: string | null;
}

export function faturaOzetSatiri(girdi: FaturaOzetGirdisi): string {
  const sure = girdi.sureSaniye === null ? "?" : String(Math.max(0, Math.round(girdi.sureSaniye)));
  const gorselli = girdi.gorselliSayisi === null ? "?" : String(girdi.gorselliSayisi);
  return `Fatura ${girdi.islemKimligi} → ${girdi.satirSayisi} satır → ${girdi.kartSayisi} kart → ${gorselli} görselli → ${sure} sn → hata: ${girdi.hataKodu || "yok"}`;
}

export async function faturaBaslangicZamani(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
): Promise<string | null> {
  try {
    const { data } = await admin.from("invoice_jobs").select("created_at")
      .eq("id", islemKimligi).eq("store_id", storeId).maybeSingle();
    const zaman = data?.created_at;
    return typeof zaman === "string" && Number.isFinite(Date.parse(zaman)) ? zaman : null;
  } catch {
    return null;
  }
}

export function gecenSaniye(baslangic: string | null): number | null {
  if (!baslangic) return null;
  const fark = Date.now() - Date.parse(baslangic);
  return Number.isFinite(fark) && fark >= 0 ? fark / 1000 : null;
}

export async function faturaOzetiniKaydet(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
  ozetSatiri: string,
): Promise<void> {
  try {
    const { data } = await admin.from("invoice_jobs").select("discovery_state")
      .eq("id", islemKimligi).eq("store_id", storeId).maybeSingle();
    if (!data) return;
    const mevcut = data.discovery_state && typeof data.discovery_state === "object"
      ? data.discovery_state as Record<string, unknown> : {};
    await admin.from("invoice_jobs").update({ discovery_state: { ...mevcut, ozetSatiri } })
      .eq("id", islemKimligi).eq("store_id", storeId);
  } catch {
    return;
  }
}
