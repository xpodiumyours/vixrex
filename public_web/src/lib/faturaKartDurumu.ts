import { MIN_FATURA_IMAGES } from "@/lib/productImagePolicy";
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
  if (girdi.gorselSayisi < MIN_FATURA_IMAGES) {
    eksikler.push(
      // Faturaya özel min 1; diğer girişler 3 kalır (MIN_PRODUCT_IMAGES).
      `En az ${MIN_FATURA_IMAGES} fotoğraf gerekiyor; kartta ${girdi.gorselSayisi} fotoğraf var.`,
    );
  }
  if (!girdi.onaylandi) {
    eksikler.push("Kart onaylanmadı.");
  }

  return eksikler;
}

function gorselAdresiGecerliMi(adres: string): boolean {
  const temiz = adres.trim();
  if (!temiz) return false;
  // Kırık/logo/kapak sızmasın: yalnız güvenli https ürün görseli karta girer.
  if (!/^https:\/\//i.test(temiz)) return false;
  if (temiz.length > 500) return false;
  const kucuk = temiz.toLowerCase();
  if (kucuk.includes("logo") || kucuk.includes("placeholder") || kucuk.includes("blank")) return false;
  return true;
}

export function karttaKullanilabilirGorseller(
  satir: EslesmisFaturaSatiri,
  esnafGorselleri: string[] = [],
): string[] {
  // Kilitli kapsam: üretici fotoğrafı karta girer ve yayınlanır; kullanım
  // izni sonra, çalışan sistemle istenir. İzin takibi sunucu kayıtlarındadır
  // (fatura_kanit.ureticiGorsel, invoice_image_rights), kartta değil.
  const katalog = satir.katalog;
  const ureticiGorselleri = katalog ? katalog.gorseller.filter(gorselAdresiGecerliMi) : [];
  const esnaf = esnafGorselleri.filter(gorselAdresiGecerliMi);
  return [...new Set([...ureticiGorselleri, ...esnaf])].slice(0, 11);
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
  /** Kartı onayla butonu kapısı: kanıtlı + fiyat>0 + stok geçerli + >=1 görsel. */
  onaylanabilir: boolean;
  /** Yayın kapısı: onaylanabilir + stokOnaylandi + onaylandi. */
  yayinaHazir: boolean;
  eksikler: string[];
  gorseller: string[];
}

export function kartDegerlendir(girdi: KartGirdisi): KartDegerlendirmesi {
  const durum = girdi.satir.sonuc;
  const gorseller = karttaKullanilabilirGorseller(girdi.satir, girdi.esnafGorselleri);
  const satisFiyati = girdi.satisFiyati ?? null;
  const stok = girdi.stok ?? null;
  const gorselSayisi = gorseller.length;

  const eksikler = yayinEksikleri({
    durum,
    satisFiyati,
    stok,
    stokOnaylandi: girdi.stokOnaylandi === true,
    onaylandi: girdi.onaylandi === true,
    gorselSayisi,
  });

  // Onay kilidi ayrımı: "Kartı onayla" butonu onaylanabilir'e bakar; onaylandi
  // + stokOnaylandi yalnız yayın kapısında aranır. Çoğaltma yok: onay bayrakları
  // true varsayılarak aynı yayinEksikleri yeniden kullanılır.
  const onayEksikleri = yayinEksikleri({
    durum,
    satisFiyati,
    stok,
    stokOnaylandi: true,
    onaylandi: true,
    gorselSayisi,
  });

  return {
    durum,
    onaylanabilir: onayEksikleri.length === 0,
    yayinaHazir: eksikler.length === 0,
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
