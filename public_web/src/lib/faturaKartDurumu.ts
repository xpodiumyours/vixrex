import { MIN_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";

export type KartDurumu = "kanitli" | "eksik" | "celiski" | "iz-yok";

export const KART_DURUMLARI: readonly KartDurumu[] = ["kanitli", "eksik", "celiski", "iz-yok"];

export const KART_DURUM_ETIKETI: Record<KartDurumu, string> = {
  kanitli: "Kanıtlı",
  eksik: "Eksik bilgi",
  celiski: "Çelişki",
  "iz-yok": "İz bulunamadı",
};

export function durumGecerliMi(deger: unknown): deger is KartDurumu {
  return typeof deger === "string" && (KART_DURUMLARI as readonly string[]).includes(deger);
}

export interface YayinGirdisi {
  durum: KartDurumu;
  satisFiyati: number | null;
  stok: number | null;
  stokOnaylandi: boolean;
  onaylandi: boolean;
  gorselSayisi: number;
}

export function yayinEksikleri(girdi: YayinGirdisi): string[] {
  const eksikler: string[] = [];

  if (girdi.durum !== "kanitli") {
    eksikler.push("Satır kanıtlı değil; bu satırdan kart yayına çıkmaz.");
  }
  if (girdi.satisFiyati === null || !(girdi.satisFiyati > 0)) {
    eksikler.push("Satış fiyatı girilmedi.");
  }
  if (!girdi.stokOnaylandi) {
    eksikler.push("Stok onaylanmadı; faturadaki adet öneridir.");
  }
  if (girdi.stok === null || !Number.isInteger(girdi.stok) || girdi.stok < 0) {
    eksikler.push("Stok adedi geçersiz.");
  }
  if (girdi.gorselSayisi < MIN_PRODUCT_IMAGES) {
    eksikler.push(
      `En az ${MIN_PRODUCT_IMAGES} fotoğraf gerekiyor; kartta ${girdi.gorselSayisi} fotoğraf var.`,
    );
  }
  if (!girdi.onaylandi) {
    eksikler.push("Kart onaylanmadı.");
  }

  return eksikler;
}

export function karttaKullanilabilirGorseller(
  satir: EslesmisFaturaSatiri,
  esnafGorselleri: string[] = [],
): string[] {
  // Kilitli kapsam: üretici fotoğrafı karta girer ve yayınlanır; kullanım
  // izni sonra, çalışan sistemle istenir. İzin takibi sunucu kayıtlarındadır
  // (fatura_kanit.ureticiGorsel, invoice_image_rights), kartta değil.
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
}

export interface KartDegerlendirmesi {
  durum: KartDurumu;
  yayinaHazir: boolean;
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

  return { durum, yayinaHazir: eksikler.length === 0, eksikler, gorseller };
}

export interface DurumBilgisi {
  etiket: string;
  detay: string;
  adaylar: Array<{ ad: string; kaynak: string }>;
}

export function durumBilgisi(satir: EslesmisFaturaSatiri): DurumBilgisi {
  const etiket = KART_DURUM_ETIKETI[satir.sonuc] ?? KART_DURUM_ETIKETI.eksik;

  if (satir.sonuc === "celiski") {
    const adaylar = satir.celiski?.adaylar ?? [];
    const dayanak = satir.celiski?.dayanak === "barkod" ? "barkod" : "ürün kodu";
    return {
      etiket,
      detay:
        adaylar.length > 0
          ? `Aynı ${dayanak} ${adaylar.length} farklı ürüne düşüyor; hangisi olduğunu sen seçmelisin.`
          : "Aynı kod birden çok ürüne düşüyor; eşleşme kurulmadı.",
      adaylar,
    };
  }

  if (satir.sonuc === "iz-yok") {
    return {
      etiket,
      detay: "Bu satırın resmî ürün kaynağı bulunamadı. Tahmin yapılmadı.",
      adaylar: [],
    };
  }

  if (satir.sonuc === "eksik") {
    return {
      etiket,
      detay: satir.uyari ?? "Ürün kimliği ya da kaynağı eksik.",
      adaylar: [],
    };
  }

  return {
    etiket,
    detay: satir.uyari ?? "",
    adaylar: [],
  };
}
