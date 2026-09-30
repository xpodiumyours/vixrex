import { alanAdiTemizle } from "@/lib/ureticiKatalog";

// Firmanın resmi sitesini internette bulma (kilitli kapsam kararı).
//
// 55 firmalık havuz SADECE hızlı yoldur (jeton tasarrufu): listedeki firma
// aranmadan bulunur. Listede OLMAYAN firma için adı internette aratılır;
// eşleşen resmi alan adı bulunursa aynı keşif (Shopify/Woo/sitemap+JSON-LD)
// oradan yürür. El yazısı notlar, kısaltmalar bizi bağlamaz — dijitalde
// eşleşen firmayla köprü kurulur.
//
// Arama sonucu KALICI saklanmaz (sağlayıcı koşulu): bulunan alan adı yalnız
// bu işlemin belleğinde tutulur, sonraki faturada yeniden aranır.
//
// Sağlayıcı: Brave Web Search (ücretsiz katman). Anahtar yoksa arama sessizce
// atlanır — akış durmaz, esnaf site ipucu yazarak devam edebilir.

export interface FirmaAramaBagimliliklari {
  fetcher?: (input: string, init?: RequestInit) => Promise<Response>;
  apiAnahtari?: string;
}

export type FirmaAramaDurumu =
  | { durum: "kapali"; sebep: string }
  | { durum: "bulunamadi"; sebep: string }
  | { durum: "bulundu"; alan: string; kaynak: string };

const ARAMA_ZAMAN_ASIMI_MS = 4000;

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

function firmaJetonlari(ad: string): string[] {
  const duraklar = new Set([
    "a", "s", "ltd", "sti", "tic", "san", "ve", "ile", "the", "of", "co", "ltdsti",
  ]);
  return ad
    .toLocaleLowerCase("tr")
    .replace(/[^a-zçğıöşü0-9\s]/g, " ")
    .split(/\s+/)
    .map((parca) => parca.trim())
    .filter((parca) => parca.length >= 3 && !duraklar.has(parca));
}

function alanFimayaUyarMi(alan: string, jetonlar: string[]): boolean {
  if (jetonlar.length === 0) return false;
  const ceviri = (s: string) =>
    s
      .replace(/ç/g, "c")
      .replace(/ğ/g, "g")
      .replace(/ı/g, "i")
      .replace(/ö/g, "o")
      .replace(/ş/g, "s")
      .replace(/ü/g, "u");
  const kucukAlan = alan.toLowerCase();
  const duz = ceviri(kucukAlan).replace(/\./g, "");
  const ham = kucukAlan.replace(/\./g, "");
  const etiketler = ceviri(kucukAlan).split(/[^a-z0-9]+/).filter(Boolean);
  const hamEtiketler = kucukAlan.split(/[^a-zçğıöşü0-9]+/).filter(Boolean);

  const jetonEslesiyorMu = (jeton: string): boolean => {
    const sade = ceviri(jeton);
    if (sade.length < 3) return false;
    if (duz.includes(sade) || ham.includes(jeton)) return true;
    const cekirdek = duz.replace(/comtr|com|net|org/g, "");
    if (cekirdek.length >= 3 && (jeton.includes(cekirdek) || sade.includes(cekirdek)))
      return true;
    return false;
  };

  const eslesenler = jetonlar.filter(jetonEslesiyorMu);
  // Sıkı eşik: tek-kelime substring yetmez — kısa markalarda (Eti/Ülker/Tutku)
  // yanlış pozitif kurar. En az 2 jetonun alanda geçmesi gerekir; tek jeton
  // ancak alanın tam kelimesiyse (ulker == ulker.com etiketi) kabul edilir.
  if (eslesenler.length >= 2) return true;
  if (eslesenler.length === 1) {
    const tek = eslesenler[0];
    const sadeTek = ceviri(tek);
    return (
      etiketler.some((etiket) => etiket === sadeTek) ||
      hamEtiketler.some((etiket) => etiket === tek)
    );
  }
  return false;
}

function resmiSiteOlmayan(alan: string): boolean {
  return RESMI_SITE_OLMAYANLAR.some((kalip) => alan === kalip || alan.endsWith(`.${kalip}`) || alan.includes(kalip));
}

export async function firmaSitesiniAra(
  tedarikciAdi: string,
  bagimliliklar: FirmaAramaBagimliliklari = {},
): Promise<FirmaAramaDurumu> {
  const ad = tedarikciAdi.trim();
  if (ad.length < 3) return { durum: "bulunamadi", sebep: "Firma adı okunamadı." };

  const anahtar = (bagimliliklar.apiAnahtari ?? process.env.BRAVE_SEARCH_API_KEY ?? "").trim();
  if (!anahtar) {
    return {
      durum: "kapali",
      sebep: "Arama servisi bağlı değil; firmanın sitesini yazarak devam edilebilir.",
    };
  }

  const fetcher = bagimliliklar.fetcher ?? fetch;
  const jetonlar = firmaJetonlari(ad);

  let yanit: Response;
  try {
    const url = `https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(`${ad} resmi site`)}&count=5`;
    yanit = await fetcher(url, {
      headers: { Accept: "application/json", "X-Subscription-Token": anahtar },
      signal: AbortSignal.timeout(ARAMA_ZAMAN_ASIMI_MS),
    });
  } catch {
    return { durum: "bulunamadi", sebep: "Arama servisine ulaşılamadı." };
  }

  if (!yanit.ok) {
    return { durum: "bulunamadi", sebep: "Arama servisi yanıt vermedi." };
  }

  let govde: unknown;
  try {
    govde = await yanit.json();
  } catch {
    return { durum: "bulunamadi", sebep: "Arama yanıtı okunamadı." };
  }

  const sonuclar = (govde as { web?: { results?: Array<{ url?: unknown; title?: unknown }> } })?.web
    ?.results;
  if (!Array.isArray(sonuclar)) return { durum: "bulunamadi", sebep: "Arama sonuç vermedi." };

  for (const sonuc of sonuclar) {
    const adres = typeof sonuc?.url === "string" ? sonuc.url : "";
    const alan = alanAdiTemizle(adres);
    if (!alan || resmiSiteOlmayan(alan)) continue;
    if (!alanFimayaUyarMi(alan, jetonlar)) continue;
    return { durum: "bulundu", alan, kaynak: `https://${alan}` };
  }

  return { durum: "bulunamadi", sebep: "Firmanın resmi sitesi aramada bulunamadı." };
}
