import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";

export type KartDurumu = "kanitli" | "eksik" | "celiski" | "iz-yok";

export const KART_DURUMLARI: readonly KartDurumu[] = ["kanitli", "eksik", "celiski", "iz-yok"];

export const KART_DURUM_ETIKETI: Record<KartDurumu, string> = {
  kanitli: "Hazır",
  eksik: "Taslak",
  celiski: "Çelişki",
  "iz-yok": "Taslak",
};

export function durumGecerliMi(deger: unknown): deger is KartDurumu {
  return typeof deger === "string" && (KART_DURUMLARI as readonly string[]).includes(deger);
}

export const ONAY_EKSIGI = "Kart onaylanmadı.";

export interface YayinGirdisi {
  durum: KartDurumu;
  satisFiyati: number | null;
  stok: number | null;
  stokOnaylandi: boolean;
  onaylandi: boolean;
  gorselSayisi: number;
  sablonEksikleri?: string[];
}

/**
 * Esnafın vitrine yayına alabilmesi için gereken TEK şart:
 * Satış fiyatının girilmiş olması ve esnafın onay vermiş olmasıdır.
 * Resim adedi veya yapay puanlama vitrine çıkmayı engellemez.
 */
export function yayinEksikleri(girdi: YayinGirdisi): string[] {
  const eksikler: string[] = [];

  if (girdi.satisFiyati === null || !(girdi.satisFiyati > 0)) {
    eksikler.push("Satış fiyatı girilmedi.");
  }
  if (!girdi.onaylandi) {
    eksikler.push(ONAY_EKSIGI);
  }

  return eksikler;
}

export function karttaKullanilabilirGorseller(
  satir: EslesmisFaturaSatiri,
  esnafGorselleri: string[] = [],
): string[] {
  const katalog = satir.katalog;
  const ureticiGorselleri = katalog ? katalog.gorseller.filter(Boolean) : [];
  return [...new Set([...ureticiGorselleri, ...esnafGorselleri.filter(Boolean)])];
}

export interface KartGirdisi {
  satir: EslesmisFaturaSatiri;
  satisFiyati?: number | null;
  stok?: number | null;
  stokOnaylandi?: boolean;
  esnafGorselleri?: string[];
  onaylandi?: boolean;
  templateKey?: string | null;
  sablonEksikleri?: string[];
}

export interface KartDegerlendirmesi {
  durum: KartDurumu;
  yayinaHazir: boolean;
  onaylanabilir: boolean;
  bilgiEksikleri: string[];
  eksikler: string[];
  gorseller: string[];
}

export function kartDegerlendir(girdi: KartGirdisi): KartDegerlendirmesi {
  const durum = girdi.satir.sonuc;
  const gorseller = karttaKullanilabilirGorseller(girdi.satir, girdi.esnafGorselleri);

  const eksikler = yayinEksikleri({
    durum,
    satisFiyati: girdi.satisFiyati ?? null,
    stok: girdi.stok ?? null,
    stokOnaylandi: girdi.stokOnaylandi === true,
    onaylandi: girdi.onaylandi === true,
    gorselSayisi: gorseller.length,
  });

  const bilgiEksikleri = eksikler.filter((eksik) => eksik !== ONAY_EKSIGI);

  return {
    durum,
    yayinaHazir: eksikler.length === 0,
    onaylanabilir: bilgiEksikleri.length === 0,
    bilgiEksikleri,
    eksikler,
    gorseller,
  };
}

export interface DurumBilgisi {
  etiket: string;
  detay: string;
  adaylar: Array<{ ad: string; kaynak: string }>;
}

export function durumBilgisi(satir: EslesmisFaturaSatiri): DurumBilgisi {
  const etiket = KART_DURUM_ETIKETI[satir.sonuc] ?? "Hazır";
  return {
    etiket,
    detay: satir.uyari ?? "",
    adaylar: [],
  };
}
