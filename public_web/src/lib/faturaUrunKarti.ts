import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";

export type FaturaUrunKartiEslesmeDurumu = "eslesti" | "eslesmedi";

export interface FaturaUrunKartiTaslagi {
  key: string;
  eslesmeDurumu: FaturaUrunKartiEslesmeDurumu;
  name: string;
  description: string;
  imageUrls: string[];
  brand: string | null;
  barcode: string | null;
  stockQuantity: number | null;
  sourceType: "invoice";
  externalProductId: string | null;
  purchasePriceAmount: number | null;
  metadata: { identifiers?: { sku?: string } };
  variants: Array<{
    id: string;
    options: Record<string, string>;
    stockQuantity?: number;
  }>;
  isVisible: false;
  katalog: {
    firma: string;
    dayanak: "kod" | "barkod";
    izinDurumu: "yok" | "bekliyor" | "var";
    kaynak: string;
  } | null;
  eksikler: string[];
}

function temiz(deger: string | null | undefined): string {
  return (deger ?? "").trim();
}

function kartAdi(satir: EslesmisFaturaSatiri): string {
  return (
    temiz(satir.katalog?.resmiAd) ||
    temiz(satir.ad) ||
    temiz(satir.model) ||
    temiz(satir.barkod) ||
    "Ürün"
  );
}

function kartAciklamasi(satir: EslesmisFaturaSatiri, ad: string): string {
  const resmi = temiz(satir.katalog?.aciklama);
  if (resmi) return resmi;
  const bilgiler: string[] = [];
  if (temiz(satir.varyant)) bilgiler.push(`Renk: ${temiz(satir.varyant)}`);
  if (temiz(satir.beden)) bilgiler.push(`Beden: ${temiz(satir.beden)}`);
  if (satir.adet !== null) bilgiler.push(`Faturadaki miktar: ${satir.adet} adet`);
  return bilgiler.length > 0 ? `${ad}. ${bilgiler.join(", ")}.` : ad;
}

function varyantlar(satir: EslesmisFaturaSatiri, index: number) {
  const renk = temiz(satir.varyant);
  const beden = temiz(satir.beden);
  if (!renk && !beden) return [];
  const temel = temiz(satir.model) || temiz(satir.barkod) || String(index + 1);
  const stok = satir.adet !== null && Number.isInteger(satir.adet) && satir.adet >= 0
    ? satir.adet
    : undefined;
  return [
    {
      id: `fatura-${temel.toLocaleLowerCase("tr-TR")}-${index + 1}`,
      options: {
        ...(renk ? { color: renk } : {}),
        ...(beden ? { size: beden } : {}),
      },
      ...(stok !== undefined ? { stockQuantity: stok } : {}),
    },
  ];
}

export function faturaSatiriniKartaDonustur(
  satir: EslesmisFaturaSatiri,
  index = 0,
): FaturaUrunKartiTaslagi {
  const katalog = satir.katalog;
  const eslesti = katalog !== null;
  const ad = kartAdi(satir);
  const barkod = temiz(satir.barkod) || null;
  const model = temiz(satir.model);
  const externalProductId = barkod || model || null;
  const imageUrls = katalog?.gorseller.map((adres) => adres.trim()).filter(Boolean) ?? [];
  const eksikler: string[] = [];

  if (!eslesti) eksikler.push("Dijital ürün eşleşmesi bulunamadı.");
  if (eslesti && imageUrls.length === 0) {
    if (katalog?.izinDurumu === "var") eksikler.push("Ürün görseli bulunamadı.");
    else eksikler.push("Üretici görsel kullanım izni yok veya bekliyor.");
  }
  if (eslesti) eksikler.push("Satış fiyatı esnaf tarafından belirlenmeli.");

  return {
    key: `${externalProductId || "satir"}-${index + 1}`,
    eslesmeDurumu: eslesti ? "eslesti" : "eslesmedi",
    name: ad,
    description: kartAciklamasi(satir, ad),
    imageUrls,
    brand: temiz(katalog?.marka) || null,
    barcode: barkod,
    stockQuantity:
      satir.adet !== null && Number.isInteger(satir.adet) && satir.adet >= 0 ? satir.adet : null,
    sourceType: "invoice",
    externalProductId,
    purchasePriceAmount: satir.alisBirimFiyat,
    metadata: model ? { identifiers: { sku: model } } : {},
    variants: varyantlar(satir, index),
    isVisible: false,
    katalog: katalog
      ? {
          firma: katalog.firma,
          dayanak: katalog.dayanak,
          izinDurumu: katalog.izinDurumu,
          kaynak: katalog.kaynak,
        }
      : null,
    eksikler,
  };
}

export function faturaSatirlariniKartlaraDonustur(
  satirlar: EslesmisFaturaSatiri[],
): FaturaUrunKartiTaslagi[] {
  return satirlar.map((satir, index) => faturaSatiriniKartaDonustur(satir, index));
}
