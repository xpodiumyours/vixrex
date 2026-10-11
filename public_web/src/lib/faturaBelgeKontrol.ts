import type { HamFaturaSatiri } from "@/lib/faturaEslestir";

export interface BelgeUyumu {
  uyumlu: boolean;
  /** Uyumsuzsa esnafa gösterilecek, jargonsuz sebep. */
  sebep: string | null;
  okunanAdet: number;
  okunanToplam: number;
  belgeAdedi: number | null;
  belgeToplami: number | null;
  /** Farkli olcu birimleri birbiriyle toplanmaz. Bu bayrak UI'da gorunur. */
  adetKarsilastirildi: boolean;
}

/**
 * Okunan satırları belgenin kendi toplamıyla karşılaştırır.
 *
 * Tutmuyorsa AKIŞ DURUR — eksik/yanlış okunmuş satırla ürün kartı üretmek,
 * esnafa yanlış stok ve yanlış alış fiyatı yazmak demektir. Tahminle
 * düzeltme yapılmaz.
 *
 * Belge toplamı hiç okunamadıysa karşılaştırma yapılamaz; bu da uyumsuzluk
 * sayılır — ölçemediğimiz şeyi "doğru" diye geçiremeyiz.
 */
export function belgeGercegiUyuyorMu(
  satirlar: HamFaturaSatiri[],
  ozet: BelgeOzeti,
): BelgeUyumu {
  const okunanAdet = satirlar.reduce((t, s) => t + (s.adet ?? 0), 0);
  const okunanToplam = satirlar.reduce((t, s) => t + (s.satirToplam ?? 0), 0);
  const birimNormalize = (girdi: string | undefined) => {
    const deger = (girdi ?? "").trim().toLocaleLowerCase("tr-TR").replace(/[.]$/, "");
    return ["ad", "adet", "pcs", "piece"].includes(deger) ? "adet" : deger || "belirtilmedi";
  };
  const karmaBirim = new Set(satirlar.map((satir) => birimNormalize(satir.birim))).size > 1;

  const temel = {
    okunanAdet,
    adetKarsilastirildi: !karmaBirim && ozet.adet !== null,
    okunanToplam,
    belgeAdedi: ozet.adet,
    belgeToplami: ozet.toplam,
  };

  if (ozet.adet === null && ozet.toplam === null) {
    return { ...temel, uyumlu: false, sebep: "Belgenin toplam satırı okunamadı." };
  }

  const eksikler: string[] = [];
  for (const [index, satir] of satirlar.entries()) {
    if (satir.adet === null || !Number.isFinite(satir.adet) ||
        satir.alisBirimFiyat === null || !Number.isFinite(satir.alisBirimFiyat) ||
        satir.satirToplam === null || !Number.isFinite(satir.satirToplam)) {
      eksikler.push((index + 1) + ". ürünün miktarı veya fiyatı okunamadı");
      continue;
    }
    if (Math.abs(satir.adet * satir.alisBirimFiyat - satir.satirToplam) > 0.05) {
      eksikler.push((index + 1) + ". ürünün miktar × birim fiyat hesabı tutmuyor");
    }
  }
  if (!karmaBirim && ozet.adet !== null && ozet.adet !== okunanAdet) {
    eksikler.push(`adet ${okunanAdet} okundu, belgede ${ozet.adet} yazıyor`);
  }
  // Kuruş yuvarlamasına tolerans; bunun ötesi gerçek uyumsuzluktur.
  if (ozet.toplam !== null && Math.abs(ozet.toplam - okunanToplam) > 0.05) {
    eksikler.push(
      `tutar ${okunanToplam.toFixed(2)} TL okundu, belgede ${ozet.toplam.toFixed(2)} TL yazıyor`,
    );
  }

  if (eksikler.length === 0) return { ...temel, uyumlu: true, sebep: null };

  return {
    ...temel,
    uyumlu: false,
    sebep: `Fatura tam okunamadı (${eksikler.join("; ")}).`,
  };
}

export function belgeVergiToplamiUyuyorMu(girdi: {
  malBedeli: number | null;
  kdvTutari: number | null;
  indirimTutari: number | null;
  odenecekToplam: number | null;
}): { uyumlu: boolean; denetlendi: boolean; sebep: string | null } {
  const { malBedeli, kdvTutari, odenecekToplam } = girdi;
  if (malBedeli === null || kdvTutari === null || odenecekToplam === null) {
    return { uyumlu: true, denetlendi: false, sebep: null };
  }
  const indirim = girdi.indirimTutari ?? 0;
  const eslesiyor = (tutar: number) => Math.abs(tutar - odenecekToplam) <= 0.05;
  // "mal bedeli" bu sözleşmede KDV HARİÇ tutardır.
  // Mal bedeli zaten KDV dahilmiş gibi ikinci bir olası denklem deneyerek
  // yanlış OCR alanlarını doğrulanmış saymak yasaktır (UBL MonetaryTotal).
  const vergiHaricMalBedeli = malBedeli + kdvTutari - indirim;
  if (eslesiyor(vergiHaricMalBedeli)) {
    return { uyumlu: true, denetlendi: true, sebep: null };
  }
  return {
    uyumlu: false,
    denetlendi: true,
    sebep: "Belgedeki mal bedeli, KDV, indirim ve ödenecek toplam uyuşmuyor.",
  };
}
