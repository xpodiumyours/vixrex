export interface UreticiUrunu {
  kod: string;
  ad: string;
  marka: string;
  aciklama: string;
  barkod: string;
  gorseller: string[];
  kaynak: string;
  varyant?: string;
  modelAdi?: string;
}

export type IzinDurumu = "yok" | "bekliyor" | "var";

export function alanAdiTemizle(deger: string): string {
  const ham = deger.trim();
  if (!ham) return "";
  try {
    const url = new URL(ham.includes("://") ? ham : `https://${ham}`);
    return url.hostname.toLowerCase().replace(/^www\./, "").replace(/\.$/, "");
  } catch {
    return "";
  }
}

/**
 * Fotoğraf taşıma (kilitli kapsam: önce çalışan sistem).
 *
 * Üreticinin fotoğrafları taslağa ve yayına girer; kullanım izni sonra,
 * çalışan sistemle istenir. İzin takibi `invoice_image_rights` (okuma anında)
 * ve `products.fatura_kanit.ureticiGorsel` (yazım anında) kayıtlarından yürür.
 * `izinDurumu` artık bilgi olarak taşınır, engel olarak değil.
 */
export function gorselKapisi(urun: UreticiUrunu, _izinDurumu: IzinDurumu): UreticiUrunu {
  void _izinDurumu;
  return urun;
}
