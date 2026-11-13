/**
 * Fatura görsel hakları denetimi ve kanıt derlemesi.
 *
 * `invoice_image_rights.usage_status` kayıt durumlarını derler; derlenen
 * `hakKayitDurumu` alanı ürünün `fatura_kanit.gorselKaynaklari` kaydına yazılır
 * ve SQL yayın kapısında (`publish_invoice_product`) vitrin görünürlüğünü denetler.
 */
export type GorselHakDurumu =
  | "verified_supplier_permission"
  | "verified_feed_terms"
  | "merchant_owned_media"
  | "unknown"
  | "denied"
  | "kayit_yok";

/** SQL yayin kapisinin (publish_invoice_product) kabul ettigi dogrulanmis hak durumlariyla birebir ayni liste. */
export const DOGRULANMIS_HAK_DURUMLARI: readonly string[] = [
  "verified_supplier_permission",
  "verified_feed_terms",
  "merchant_owned_media",
];

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
    const hamDurum = typeof kayit.usage_status === "string" ? kayit.usage_status : "";
    const durum: GorselHakDurumu =
      hamDurum === "denied"
        ? "denied"
        : DOGRULANMIS_HAK_DURUMLARI.includes(hamDurum)
          ? (hamDurum as GorselHakDurumu)
          : "unknown";

    const onceki = durumlar.get(adres);
    // Bir URL birden çok satırla gelirse açık ret her zaman baskındır;
    // doğrulanmış bir durum, bilinmeyeni yükseltir.
    if (onceki === "denied") continue;
    if (
      onceki === undefined ||
      durum === "denied" ||
      (onceki === "unknown" && DOGRULANMIS_HAK_DURUMLARI.includes(durum))
    ) {
      durumlar.set(adres, durum);
    }
  }
  return durumlar;
}

/**
 * Ürün fatura_kanit.gorselKaynaklari alanına görselin hak kayıt durumunu yazar.
 * SQL yayın kapısı (`publish_invoice_product`) doğrulanmamış görsellerde kartı hazır bekletir.
 */
export function gorselHakKaydiniRaporla(
  kaynakGorsel: string,
  durumlar?: ReadonlyMap<string, GorselHakDurumu>,
): { hakKayitDurumu: GorselHakDurumu; hakIncelemeGerekiyor: boolean } {
  const hakKayitDurumu = durumlar?.get(kaynakGorsel.trim()) ?? "kayit_yok";
  return {
    hakKayitDurumu,
    hakIncelemeGerekiyor: !DOGRULANMIS_HAK_DURUMLARI.includes(hakKayitDurumu),
  };
}

export function gorselIzinBekliyorMu(faturaKanit: unknown): boolean | undefined {
  const kayitlar = (faturaKanit as { gorselKaynaklari?: unknown } | null)?.gorselKaynaklari;
  if (!Array.isArray(kayitlar) || kayitlar.length === 0) return undefined;
  return kayitlar.some((kaynak) => {
    const durum = (kaynak as { hakKayitDurumu?: unknown } | null)?.hakKayitDurumu;
    return !DOGRULANMIS_HAK_DURUMLARI.includes(typeof durum === "string" ? durum : "");
  });
}
