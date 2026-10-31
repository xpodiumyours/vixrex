/**
 * Fatura görsel hakları için salt-okunur gölge denetimi.
 *
 * DİKKAT: invoice_image_rights.usage_status bir kayıt durumudur; bu alan tek
 * başına imzalı marka lisansının varlığını kanıtlamaz. Yayın uygunluğu,
 * eski deny kapısı ve esnaf onayı burada DEĞİŞTİRİLMEZ.
 */
export type GorselHakDurumu =
  | "verified_supplier_permission"
  | "unknown"
  | "denied"
  | "kayit_yok";

export interface GorselHakSatiri {
  image_url?: unknown;
  usage_status?: unknown;
}

export function gorselHakKayitlariniDerle(
  kayitlar: readonly GorselHakSatiri[],
): ReadonlyMap<string, GorselHakDurumu> {
  const durumlar = new Map<string, GorselHakDurumu>();
  for (const kayit of kayitlar) {
    const adres = typeof kayit.image_url === "string" ? kayit.image_url.trim() : "";
    if (!adres) continue;

    // Yeni/bilinmeyen değerleri izin verilmiş sayma.
    const durum: GorselHakDurumu =
      kayit.usage_status === "denied"
        ? "denied"
        : kayit.usage_status === "verified_supplier_permission"
          ? "verified_supplier_permission"
          : "unknown";

    const onceki = durumlar.get(adres);
    // Bir URL birden çok satırla gelirse açık ret her zaman baskındır.
    if (
      onceki === undefined ||
      durum === "denied" ||
      (onceki === "unknown" && durum === "verified_supplier_permission")
    ) {
      if (onceki !== "denied") durumlar.set(adres, durum);
    }
  }
  return durumlar;
}

/**
 * Ürün fatura_kanit.gorselKaynaklari alanına yalnızca ek kanıt yazar.
 * Buradaki işaretler hiçbir kartı engellemez, gizlemez veya yayımlamaz.
 */
export function gorselHakKaydiniRaporla(
  kaynakGorsel: string,
  durumlar?: ReadonlyMap<string, GorselHakDurumu>,
): { hakKayitDurumu: GorselHakDurumu; hakIncelemeGerekiyor: boolean } {
  const hakKayitDurumu = durumlar?.get(kaynakGorsel.trim()) ?? "kayit_yok";
  return {
    hakKayitDurumu,
    hakIncelemeGerekiyor: hakKayitDurumu !== "verified_supplier_permission",
  };
}
