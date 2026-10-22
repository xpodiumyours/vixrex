import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import type { ProductAttributeValue } from "@/lib/productRichData";

export const FATURA_TASLAK_KAYNAGI = "invoice";

export interface FaturaTaslagi {
  name: string;
  description: string;
  brand: string | null;
  barcode: string | null;
  model: string;
  imageUrls: string[];
  kategori: string;
  ozellikler: ProductAttributeValue[];
  urunVaryantlari: Array<{ id: string; secenekler: Array<{ key: string; value: string }>; barkod: string; gorseller: string[] }>;
  gorselAdaylari: string[];
  izinDurumu: "yok" | "bekliyor" | "var";
  kaynak: string;
  kaynakFirma: string;
  dayanak: "kod" | "barkod" | "ad";
  sonuc: string;
  celiski: EslesmisFaturaSatiri["celiski"];
  uyari: string | null;
  alisBirimFiyat: number | null;
  stokOnerisi: number | null;
  stokOnaylandi: boolean;
  satisFiyati: number | null;
  islemKimligi: string | null;
  sourceType: string;
  ownerApproved: boolean;
  isVisible: boolean;
  satirNo?: number | null;
  uretici?: string;
  gramaj?: string;
  dogrulamaDurumu?: string;
  eslesenBilgiler?: unknown;
  eksikler?: string[];
  gorselDogrulamaDurumu?: string;
  kaynaklar?: Array<string | Record<string, unknown>>;
}

export function satirdanFaturaTaslagi(
  satir: EslesmisFaturaSatiri,
  islemKimligi: string | null = null,
): FaturaTaslagi | null {
  const katalog = satir.katalog;
  if (!katalog) return null;

  const ad = (katalog.resmiAd ?? "").trim() || (satir.ad ?? "").trim();
  if (!ad) return null;

  return {
    name: ad,
    description: (katalog.aciklama ?? "").trim(),
    brand: (katalog.marka ?? "").trim() || null,
    barcode: (satir.barkod ?? "").trim() || null,
    model: (satir.model ?? "").trim(),
    // Kilitli kapsam: üretici fotoğrafı taslağa girer; kullanım izni sonra,
    // çalışan sistemle istenir (izin takibi sunucu kayıtlarındadır).
    imageUrls: katalog.gorseller,
    kategori: katalog.kategori ?? "",
    ozellikler: katalog.ozellikler ?? [],
    urunVaryantlari: katalog.urunVaryantlari ?? [],
    gorselAdaylari: katalog.gorselAdaylari,
    izinDurumu: katalog.izinDurumu,
    kaynak: katalog.kaynak,
    kaynakFirma: katalog.kaynakFirma || katalog.firma,
    dayanak: katalog.dayanak,
    sonuc: satir.sonuc,
    celiski: satir.celiski,
    uyari: satir.uyari ?? null,
    alisBirimFiyat: satir.alisBirimFiyat,
    stokOnerisi: satir.adet,
    stokOnaylandi: false,
    satisFiyati: null,
    islemKimligi,
    sourceType: FATURA_TASLAK_KAYNAGI,
    ownerApproved: false,
    isVisible: false,
    satirNo: katalog.satirNo,
    uretici: katalog.uretici,
    gramaj: katalog.gramaj,
    dogrulamaDurumu: katalog.dogrulamaDurumu,
    eslesenBilgiler: katalog.eslesenBilgiler,
    eksikler: katalog.eksikler ?? [],
    gorselDogrulamaDurumu: katalog.gorselDogrulamaDurumu,
    kaynaklar: katalog.kaynaklar ?? [],
  };
}

export function faturaTaslaklari(
  satirlar: EslesmisFaturaSatiri[],
  islemKimligi: string | null = null,
): FaturaTaslagi[] {
  return satirlar
    .map((satir) => satirdanFaturaTaslagi(satir, islemKimligi))
    .filter((taslak): taslak is FaturaTaslagi => taslak !== null);
}
