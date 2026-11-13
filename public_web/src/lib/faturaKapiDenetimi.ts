/** Fatura → ürün kartı hattının modelden bağımsız denetimleri. Ağ erişimi yok, saf hesap. */

import { normalizeGoogleGtin } from "@/lib/productStructuredData";

export type DenetimSonucu = { gecti: boolean; kod: string; mesaj: string };

const TOLERANS = 0.01;

export function gtinBicimindeMi(barkod: string | null | undefined): boolean {
  const temiz = String(barkod ?? "").replace(/[\s-]+/g, "");
  return /^(?:\d{8}|\d{12}|\d{13}|\d{14})$/.test(temiz);
}

/** null: barkod GTIN biçiminde değil (yerel/model kodu) — denetim uygulanmaz. */
export function barkodDenetimi(barkod: string | null | undefined): DenetimSonucu | null {
  if (!gtinBicimindeMi(barkod)) return null;
  const temiz = String(barkod ?? "").replace(/[\s-]+/g, "");
  if (normalizeGoogleGtin(temiz)) return null;
  return {
    gecti: false,
    kod: "BARKOD_KONTROL_HANESI",
    mesaj: `Barkod kontrol hanesi tutmadı (${temiz}); okunan değer kimlik olarak kullanılmadı.`,
  };
}

export function satirAritmetigiDenetimi(satir: {
  adet?: number | null;
  birimFiyat?: number | null;
  tutar?: number | null;
}): DenetimSonucu | null {
  const { adet, birimFiyat, tutar } = satir;
  if (typeof adet !== "number" || typeof birimFiyat !== "number" || typeof tutar !== "number") return null;
  if (Math.abs(adet * birimFiyat - tutar) <= TOLERANS) return null;
  return {
    gecti: false,
    kod: "SATIR_ARITMETIGI",
    mesaj: `Satır aritmetiği tutmadı: ${adet} × ${birimFiyat} ≠ ${tutar}.`,
  };
}

export function belgeAritmetigiDenetimi(
  satirToplamlari: Array<number | null>,
  basiliToplam: number | null,
): DenetimSonucu | null {
  const toplam = satirToplamlari.filter((deger): deger is number => typeof deger === "number");
  if (typeof basiliToplam !== "number" || !toplam.length) return null;
  if (satirToplamlari.some((deger) => typeof deger !== "number")) return null;
  const hesap = toplam.reduce((a, b) => a + b, 0);
  if (Math.abs(hesap - basiliToplam) <= TOLERANS) return null;
  return {
    gecti: false,
    kod: "BELGE_ARITMETIGI",
    mesaj: `Satır toplamı ${hesap} ile belgede basılı toplam ${basiliToplam} tutmuyor.`,
  };
}

function alanAdi(deger: unknown): string {
  const metin = String(deger ?? "").trim();
  if (!metin) return "";
  try {
    const adres = new URL(metin.includes("://") ? metin : `https://${metin}`);
    return adres.hostname.toLocaleLowerCase("tr-TR").replace(/^www\./, "");
  } catch {
    return "";
  }
}

export function kaynakDenetimi(args: {
  resmiSayfa: string;
  kaynaklar: unknown[];
  officialDomain?: string;
}): DenetimSonucu | null {
  const beklenen = alanAdi(args.officialDomain);
  const sayfaAlani = alanAdi(args.resmiSayfa);
  if (beklenen && sayfaAlani && sayfaAlani !== beklenen && !sayfaAlani.endsWith(`.${beklenen}`)) {
    return {
      gecti: false,
      kod: "ALAN_ADI_UYUSMUYOR",
      mesaj: `Resmî ürün sayfasının alan adı (${sayfaAlani}) doğrulanan alan adıyla (${beklenen}) uyuşmuyor.`,
    };
  }
  const adresler = args.kaynaklar
    .map((kaynak) => (kaynak && typeof kaynak === "object"
      ? String((kaynak as Record<string, unknown>).url ?? "")
      : ""))
    .filter(Boolean);
  if (!adresler.length) {
    return {
      gecti: false,
      kod: "KAYNAK_KAYDI_YOK",
      mesaj: "Kart resmî sayfayı gösteriyor ama açılan sayfanın kayıt kaydı yok; doğrulama iddiası kanıtsız.",
    };
  }
  if (adresler.includes(args.resmiSayfa)) return null;
  return {
    gecti: false,
    kod: "KAYNAK_UYUSMUYOR",
    mesaj: "Kartın gösterdiği resmî adres, kayıt listesindeki açılan sayfalardan biri değil.",
  };
}
