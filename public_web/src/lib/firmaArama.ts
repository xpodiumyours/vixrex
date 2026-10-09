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

// Pazar yeri, sosyal ağ, video ve sözlük adresleri firmanın resmi sitesi
// sayılmaz — buralardan eşleşme kurulmaz.
const RESMI_SITE_OLMAYANLAR = [
  "sahibinden.com",
  "trendyol.com",
  "hepsiburada.com",
  "amazon.",
  "n11.com",
  "ciceksepeti.com",
  "facebook.com",
  "instagram.com",
  "linkedin.com",
  "youtube.com",
  "x.com",
  "twitter.com",
  "tiktok.com",
  "wikipedia.org",
  "eksisozluk.com",
];

function resmiSiteOlmayan(alan: string): boolean {
  return RESMI_SITE_OLMAYANLAR.some((kalip) => alan === kalip || alan.endsWith(`.${kalip}`) || alan.includes(kalip));
}

export function resmiSiteSayilmaz(alan: string): boolean {
  const temiz = alanAdiTemizle(alan);
  return !temiz || resmiSiteOlmayan(temiz);
}
