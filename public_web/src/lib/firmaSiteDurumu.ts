export type FirmaSiteDurumu =
  | { durum: "dogrulandi"; adres: string }
  | { durum: "bulunamadi" }
  | { durum: "arama_kapali" }
  | { durum: "firma_yok" };

export function firmaSiteCumlesi(durum: FirmaSiteDurumu | null | undefined): string {
  if (durum?.durum === "dogrulandi") return durum.adres;
  if (durum?.durum === "firma_yok") return "Firma adı belgede yazmıyor";
  if (durum?.durum === "arama_kapali") return "Site bulunamadı. İnternette arama henüz bağlı değil.";
  return "Site bulunamadı";
}

export function firmaSiteDurumuKur(girdi: {
  firmaAdi: string;
  dogrulananAdres: string | null;
  aramaKapali: boolean;
}): FirmaSiteDurumu {
  if (!girdi.firmaAdi.trim()) return { durum: "firma_yok" };
  if (girdi.dogrulananAdres) return { durum: "dogrulandi", adres: girdi.dogrulananAdres };
  if (girdi.aramaKapali) return { durum: "arama_kapali" };
  return { durum: "bulunamadi" };
}

export function belgedeYazi(deger: string | null | undefined): string {
  const temiz = (deger ?? "").trim();
  return temiz || "Belgede yazmıyor";
}
