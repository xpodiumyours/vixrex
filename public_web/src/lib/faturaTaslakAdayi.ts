/** Kaynak kanıtı olmayan fatura satırından otomatik kart uydurulmaz. */
export function otomatikTaslakAdayi(satir: {
  model?: string | null;
  barkod?: string | null;
  sonuc?: string;
  katalog?: { resmiAd?: string | null; kaynak?: string | null; dayanak?: string | null } | null;
}): boolean {
  const kaynak = satir.katalog;
  if (!kaynak?.resmiAd?.trim() || !kaynak.kaynak?.startsWith("https://")) return false;
  if (satir.sonuc === "celiski" || satir.sonuc === "iz-yok") return false;
  if (kaynak.dayanak === "kod") return Boolean(satir.model?.trim());
  if (kaynak.dayanak === "barkod") return Boolean(satir.barkod?.trim());
  return kaynak.dayanak === "ad" && satir.sonuc === "kanitli";
}
