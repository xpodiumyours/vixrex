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

function gecerliIsoTarih(deger: unknown): string | null {
  return typeof deger === "string" && Number.isFinite(Date.parse(deger)) ? deger : null;
}

export async function faturaBaslangicZamani(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
): Promise<string | null> {
  try {
    const { data } = await admin.from("invoice_jobs").select("created_at, discovery_state")
      .eq("id", islemKimligi).eq("store_id", storeId).maybeSingle();
    const aramaDurumu = data?.discovery_state && typeof data.discovery_state === "object"
      ? (data.discovery_state as Record<string, unknown>)
      : null;
    const islemBaslangici = gecerliIsoTarih(aramaDurumu?.baslangicZamani);
    if (islemBaslangici) return islemBaslangici;

    const jobCreatedAt = gecerliIsoTarih(data?.created_at);
    try {
      const { data: runData } = await admin.from("invoice_provider_runs").select("created_at")
        .eq("job_id", islemKimligi).eq("store_id", storeId).maybeSingle();
      const runCreatedAt = gecerliIsoTarih(runData?.created_at);
      if (runCreatedAt && (!jobCreatedAt || Date.parse(runCreatedAt) < Date.parse(jobCreatedAt))) {
        return runCreatedAt;
      }
    } catch {
    }
    return jobCreatedAt;
  } catch {
    return null;
  }
}

export function gecenSaniye(baslangic: string | null): number | null {
  if (!baslangic) return null;
  const fark = Date.now() - Date.parse(baslangic);
  return Number.isFinite(fark) && fark >= 0 ? fark / 1000 : null;
}

function hataliOzetMi(ozet: string): boolean {
  return /hata:\s*(?!yok\b)\S+/i.test(ozet);
}

export function tamamlanmisOzetSatiri(discoveryState: unknown): string | null {
  if (!discoveryState || typeof discoveryState !== "object") return null;
  const ozet = (discoveryState as Record<string, unknown>).ozetSatiri;
  if (typeof ozet !== "string") return null;
  const temiz = ozet.trim();
  return temiz && !hataliOzetMi(temiz) ? temiz : null;
}

export async function mevcutFaturaOzeti(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
): Promise<string | null> {
  try {
    const { data } = await admin.from("invoice_jobs").select("discovery_state")
      .eq("id", islemKimligi).eq("store_id", storeId).maybeSingle();
    return tamamlanmisOzetSatiri(data?.discovery_state);
  } catch {
    return null;
  }
}

export async function faturaOzetiniKaydet(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
  ozetSatiri: string,
): Promise<string> {
  try {
    const { data } = await admin.from("invoice_jobs").select("discovery_state")
      .eq("id", islemKimligi).eq("store_id", storeId).maybeSingle();
    if (!data) return ozetSatiri;
    const mevcut = data.discovery_state && typeof data.discovery_state === "object"
      ? data.discovery_state as Record<string, unknown> : {};
    const donmusOzet = tamamlanmisOzetSatiri(mevcut);
    if (donmusOzet && !hataliOzetMi(ozetSatiri)) return donmusOzet;
    await admin.from("invoice_jobs").update({ discovery_state: { ...mevcut, ozetSatiri } })
      .eq("id", islemKimligi).eq("store_id", storeId);
    return ozetSatiri;
  } catch {
    return ozetSatiri;
  }
}
