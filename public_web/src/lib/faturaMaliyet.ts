import type { SupabaseClient } from "@supabase/supabase-js";
import type { GoruSonucu } from "@/lib/faturaGoru";

export const GUNLUK_MALIYET_TAVANI_USD = 1;
export const ARAMA_UCETI_USD = 0.02;

export function aramaCagrisiSigarMi(harcananUsd: number): boolean {
  return harcananUsd + ARAMA_UCETI_USD < GUNLUK_MALIYET_TAVANI_USD;
}

export function gunlukTavanDolduMu(harcananUsd: number): boolean {
  return harcananUsd >= GUNLUK_MALIYET_TAVANI_USD;
}

export function istanbulGunuBaslangici(simdi: Date): string {
  const parcalar = new Intl.DateTimeFormat("en-US", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(simdi);
  const deger = (tur: string) => Number(parcalar.find((parca) => parca.type === tur)?.value);
  const yil = deger("year");
  const ay = deger("month");
  const gun = deger("day");
  const saat = deger("hour");
  const dakika = deger("minute");
  const saniye = deger("second");
  const duvar = Date.UTC(yil, ay - 1, gun, saat, dakika, saniye);
  const kayma = duvar - simdi.getTime();
  return new Date(Date.UTC(yil, ay - 1, gun, 0, 0, 0) - kayma).toISOString();
}

export async function bugunkuMaliyetUsd(admin: SupabaseClient, magazaId: string, simdi = new Date()): Promise<number> {
  const { data, error } = await admin
    .from("invoice_read_usage")
    .select("cost_usd")
    .eq("store_id", magazaId)
    .gte("created_at", istanbulGunuBaslangici(simdi));
  if (error) throw new Error("MALIYET_OKUNAMADI");
  return (data ?? []).reduce((toplam, satir) => toplam + (Number(satir.cost_usd) || 0), 0);
}

export async function kullanimKaydet(
  admin: SupabaseClient,
  magazaId: string,
  okuma: Pick<GoruSonucu, "maliyet" | "girdiToken" | "ciktiToken" | "akilToken">,
): Promise<void> {
  const { error } = await admin.from("invoice_read_usage").insert({
    store_id: magazaId,
    input_tokens: okuma.girdiToken,
    output_tokens: okuma.ciktiToken,
    reasoning_tokens: okuma.akilToken,
    cost_usd: okuma.maliyet ?? 0,
  });
  if (error) throw new Error("MALIYET_YAZILAMADI");
}
