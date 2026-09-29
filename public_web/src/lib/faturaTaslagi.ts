import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";

export const FATURA_TASLAK_KAYNAGI = "invoice";

export interface FaturaTaslagi {
  name: string;
  description: string;
  brand: string | null;
  barcode: string | null;
  model: string;
  imageUrls: string[];
  gorselAdaylari: string[];
  izinDurumu: "yok" | "bekliyor" | "var";
  kaynak: string;
  sonuc: string;
  islemKimligi: string | null;
  sourceType: string;
  ownerApproved: boolean;
  isVisible: boolean;
}

export function satirdanFaturaTaslagi(
  satir: EslesmisFaturaSatiri,
  islemKimligi: string | null = null,
): FaturaTaslagi | null {
  const katalog = satir.katalog;
  if (!katalog) return null;

  const ad = katalog.resmiAd.trim() || satir.ad.trim();
  if (!ad) return null;

  return {
    name: ad,
    description: katalog.aciklama.trim(),
    brand: katalog.marka.trim() || null,
    barcode: satir.barkod.trim() || satir.model.trim() || null,
    model: satir.model.trim(),
    imageUrls: katalog.gorseller,
    gorselAdaylari: katalog.gorselAdaylari,
    izinDurumu: katalog.izinDurumu,
    kaynak: katalog.kaynak,
    sonuc: satir.sonuc,
    islemKimligi,
    sourceType: FATURA_TASLAK_KAYNAGI,
    ownerApproved: false,
    isVisible: false,
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
