import { createHash } from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { DogrulanmisSatir } from "@/lib/faturaUrunBaglantisi";
import type { HazirUrunGirdisi } from "@/lib/productIntake";
import { normalizeProductVariants } from "@/lib/productRichData";
import { yonetilenUrunGorseliMi } from "@/lib/productImagePolicy";
import { kaynakGorselleriniHazirla, gorselsizSatirlariTamamla, sayfaGorselAlanAdlari } from "@/lib/faturaGorsel";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { kategoriBirlestir } from "@/lib/kategoriBirlesim";
import { gorselHakKaydiniRaporla } from "@/lib/faturaGorselHakDenetimi";

const PAZARYERI_VEYA_ARACI_ALANLAR = new Set([
  "trendyol.com",
  "hepsiburada.com",
  "n11.com",
  "amazon.com",
  "amazon.com.tr",
  "amazon.de",
  "ciceksepeti.com",
  "pttavm.com",
  "gittigidiyor.com",
  "morhipo.com",
  "pazarama.com",
  "idefix.com",
  "kitapyurdu.com",
  "dr.com.tr",
  "akakce.com",
  "cimri.com",
  "epey.com",
  "fiyat.com",
  "sahibinden.com",
  "letgo.com",
  "dolap.com",
  "gardrops.com",
  "zebramo.com",
  "ebay.com",
  "ebay.co.uk",
  "aliexpress.com",
  "alibaba.com",
  "temu.com",
  "shein.com",
  "etsy.com",
  "walmart.com",
  "dsmcdn.com",
  "hepsiburada.net",
  "n11cdn.com",
  "media-amazon.com",
  "ssl-images-amazon.com",
  "bit.ly",
  "tinyurl.com",
  "ty.gl",
  "amzn.to",
  "facebook.com",
  "instagram.com",
  "youtube.com",
  "tiktok.com",
  "x.com",
  "twitter.com",
  "pinterest.com",
  "linkedin.com",
  "wikipedia.org",
  "vikipedi.org",
  "sikayetvar.com",
  "eksisozluk.com",
  "openfoodfacts.org",
  "barcodelookup.com",
  "upcitemdb.com",
  "ean-search.org",
  "gtinsearch.org",
  "vertexaisearch.cloud.google.com",
]);

const MESRU_ETICARET_CDN_ALANLARI = new Set([
  "akinoncdn.com",
  "mncdn.com",
  "ticimax.cloud",
  "ideacdn.net",
  "shopify.com",
  "shopifycdn.com",
  "myikas.com",
  "ikas.com",
  "tsoftcdn.com",
  "tsoft.com.tr",
  "cloudfront.net",
  "akamaized.net",
  "imgix.net",
  "cloudinary.com",
  "fastly.net",
  "azureedge.net",
  "scene7.com",
  "mediacdn.com",
  "fashfed.com",
  "sercdn.com",
]);

const RENK_KISALTMALARI: Record<string, string> = {
  SYH: "Siyah",
  SIYAH: "Siyah",
  SİYAH: "Siyah",
  BYZ: "Beyaz",
  BEYAZ: "Beyaz",
  LCV: "Lacivert",
  LACIVERT: "Lacivert",
  LACİVERT: "Lacivert",
  MVI: "Mavi",
  MVİ: "Mavi",
  MAVI: "Mavi",
  MAVİ: "Mavi",
  KRM: "Kırmızı",
  KMZ: "Kırmızı",
  KIRMIZI: "Kırmızı",
  GRI: "Gri",
  GRİ: "Gri",
  ANT: "Antrasit",
  ANTRASIT: "Antrasit",
  ANTRASİT: "Antrasit",
  BEJ: "Bej",
  BRD: "Bordo",
  BORDO: "Bordo",
  HKI: "Haki",
  HKİ: "Haki",
  HAKI: "Haki",
  HAKİ: "Haki",
  YSL: "Yeşil",
  YESIL: "Yeşil",
  YEŞİL: "Yeşil",
  KHV: "Kahverengi",
  KAHVE: "Kahverengi",
  KAHVERENGI: "Kahverengi",
  KAHVERENGİ: "Kahverengi",
  EKR: "Ekru",
  EKRU: "Ekru",
  PMB: "Pembe",
  PEMBE: "Pembe",
  MOR: "Mor",
  SRI: "Sarı",
  SARI: "Sarı",
  TRN: "Turuncu",
  TRNC: "Turuncu",
  TURUNCU: "Turuncu",
  FME: "Füme",
  FUME: "Füme",
  FÜME: "Füme",
  IND: "İndigo",
  INDG: "İndigo",
  INDIGO: "İndigo",
  İNDİGO: "İndigo",
  KREM: "Krem",
  KML: "Camel",
  CAMEL: "Camel",
  VZN: "Vizon",
  VIZON: "Vizon",
  VİZON: "Vizon",
  TABA: "Taba",
  KOBALT: "Kobalt",
  TURKUAZ: "Turkuaz",
  HARDAL: "Hardal",
  SOMON: "Somon",
  LILA: "Lila",
  LİLA: "Lila",
  PUDRA: "Pudra",
  KOMBIN: "Kombin",
  KOMBİN: "Kombin",
};

export const TURKIYE_FATURA_KISALTMA_TALIMATI = [
  "Türkiye toptan fatura kısaltmalarını otomatik çözümle: SLM=Slim Fit, REG=Regular Fit, OVS=Oversize, RLX=Relaxed Fit, SYH=Siyah, BYZ=Beyaz, LCV=Lacivert, MVI=Mavi, KRM=Kırmızı/Krem, GRI=Gri, ANT=Antrasit, BEJ=Bej, BRD=Bordo, HKI=Haki, YSL=Yeşil, PNT=Pantolon, GMLK=Gömlek, TSH/TSRT=Tişört, SWT=Sweatshirt, CKT=Ceket, KZK=Kazak, DNM=Denim, KDN=Kadın, ERK=Erkek, CCK=Çocuk, PMK=Pamuk, ELST=Elastan, UK=Uzun Kol, KK=Kısa Kol, SY=Sıfır Yaka, VY=V Yaka. Hangi sektör olursa olsun faturadaki kısaltmaları, renk/beden/ölçü kodlarını ve sektörel terimleri faturanın bağlamından otomatik çözümleyip tam tüketici diline aç.",
  "Akıllı kademeli eşleme uygula: Faturadaki model kodu veya barkodu üretici/marka resmî web sitesinde arayıp doğrula; ürün bulunduğunda faturadaki kısaltmalı satır yerine üretici sayfasındaki tüketici dostu tam ürün adını al ve faturadaki renk bilgisini kısaltmadan açarak ürün açıklamasında net belirt.",
  "Toptan faturalarda model kodları bazen yalın/tekil (ör. 11375) yazılırken üreticinin sitesinde veya kataloğunda paketli/tireli/varyantlı (ör. 11375-78, 11375-55, 1013-1 vb.) kodlarla yer alabilir; tersine faturada model kodu renk/beden ekleriyle bitişik veya tireli yazılmışsa (ör. 167-1-3XL, 049-19-3XL, 328-1-4), sondaki renk ve beden eklerini ayırarak baştaki kök model numarası ve açılmış ürün adıyla da arama yap; model kodu önekiyle, kök model numarasıyla veya barkodla eşleştiğinde de ürünü doğrulanmış resmî ürün kabul et ve görsellerini al.",
  "Doğrulanmış her ürün kartında sayfadaki birincil/ana mankenli stüdyo fotoğrafını selected_image_url alanına, diğer renk ve açı fotoğraflarını image_urls dizisine ekle; akinoncdn.com, mncdn.com, ticimax.cloud, ideacdn.net, shopify.com, myikas.com gibi kurumsal e-ticaret CDN görsellerini koru ve doğrulanan ürünü kesinlikle görselsiz bırakma.",
].join("\n");

const HASSAS_ALAN_ANAHTARLARI = new Set([
  "vergino",
  "vergi_no",
  "vkn",
  "tckn",
  "tc_kimlik_no",
  "tc_no",
  "ettn",
  "iban",
  "taxid",
  "tax_id",
  "tedarikcivergino",
  "suppliertaxid",
  "supplier_tax_id",
  "supplier_name",
  "suppliername",
  "supplier_address",
  "supplieraddress",
  "tedarikci",
  "tedarikci_adres",
  "tedarikciadres",
  "iskonto",
  "discount",
  "vade",
  "tevkifat",
  "dipnot",
  "cari_kodu",
  "carikodu",
  "musteri_no",
  "musterino",
  "irsaliye",
  "vergi_dairesi",
  "vergidairesi",
  "seri_no",
  "serino",
  "faturano",
  "fatura_no",
  "invoiceno",
  "invoice_no",
]);

export function kural32MetinTemizle(metin: string): string {
  if (!metin) return "";
  return metin
    .replace(/\bTR\d{2}(?:\s?[0-9A-Z]{4}){5}\s?[0-9A-Z]{2}\b/gi, "")
    .replace(/\bTR\d{2}[0-9A-Z]{22,24}\b/gi, "")
    .replace(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi, "")
    .replace(/\b\d{10,11}\b/g, "")
    .replace(/(^|[\s,.;:(\[\-])%?\s*\d+(?:[.,]\d+)?\s*%?\s*(?:[oöOÖ]zel\s+|genel\s+|sat[iıIİ]r\s+)?[iİıI]skonto(?:\s+(?:oran[iıIİ]|tutar[iıIİ]))?(?=$|[\s,.;:)\]\-])/gi, "$1")
    .replace(/(^|[\s,.;:(\[\-])(?:[oöOÖ]zel\s+|genel\s+|sat[iıIİ]r\s+)?[iİıI]skonto(?:\s+(?:oran[iıIİ]|tutar[iıIİ]))?(?:\s*[:\-]?\s*%?\s*\d+(?:[.,]\d+)?\s*%?(?:\s*(?:tl|try|usd|eur|₺|\$|€))?)?(?=$|[\s,.;:)\]\-])/gi, "$1")
    .replace(/\b\d+\s*(?:g[uüUÜ]n|ay|y[iıIİ]l)\s+vade(?:li|si)?(?=$|[\s,.;:)\]\-])/gi, "")
    .replace(/(^|[\s,.;:(\[\-])(?:[oöOÖ]deme\s+)?vade(?:\s+(?:fark[iıIİ]|tarihi|g[uüUÜ]n[uüUÜ]|s[uüUÜ]resi)|si)?(?:\s*[:\-]?\s*\d+\s*(?:g[uüUÜ]n|ay|y[iıIİ]l)?)?(?=$|[\s,.;:)\]\-])/gi, "$1")
    .replace(/\s+/g, " ")
    .trim();
}

export function alanAdiCikar(deger: unknown): string {
  if (typeof deger !== "string") return "";
  const ham = deger.trim();
  if (!ham || /\s/.test(ham)) return "";
  if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(ham) && !/^https?:/i.test(ham)) return "";
  let url: URL;
  try {
    url = new URL(ham.includes("://") ? ham : `https://${ham}`);
  } catch {
    return "";
  }
  if (!["https:", "http:"].includes(url.protocol) || url.username || url.password) return "";
  const host = url.hostname.toLocaleLowerCase("tr-TR").replace(/^www\./, "").replace(/\.$/, "");
  if (!host || !host.includes(".") || host === "localhost" || host.endsWith(".local")) return "";
  if (/^\d{1,3}(?:\.\d{1,3}){3}$/.test(host) || host.includes(":")) return "";
  return host;
}

export function pazaryeriVeyaAraciMi(deger: unknown): boolean {
  const host = alanAdiCikar(deger);
  if (!host) return true;
  for (const alan of PAZARYERI_VEYA_ARACI_ALANLAR) {
    if (host === alan || host.endsWith(`.${alan}`)) return true;
  }
  return false;
}

export function kilitliResmiAlanAdiSec(kaynaklar: readonly unknown[]): string | null {
  for (const kaynak of kaynaklar) {
    const alan = alanAdiCikar(kaynak);
    if (alan && !pazaryeriVeyaAraciMi(alan)) return alan;
  }
  return null;
}

export function mesruEticaretCdnMi(deger: unknown): boolean {
  const host = alanAdiCikar(deger);
  if (!host || pazaryeriVeyaAraciMi(host)) return false;
  for (const alan of MESRU_ETICARET_CDN_ALANLARI) {
    if (host === alan || host.endsWith(`.${alan}`)) return true;
  }
  return false;
}

export interface AlanAdiUygunlukSecenekleri {
  gorsel?: boolean;
  izinliGorselAlanlari?: readonly string[];
}

export function resmiAlanAdiUygunMu(
  adayUrl: unknown,
  kilitliResmiAlan?: string | null,
  secenekler?: AlanAdiUygunlukSecenekleri,
): boolean {
  if (typeof adayUrl !== "string") return false;
  let url: URL;
  try {
    url = new URL(adayUrl.trim());
  } catch {
    return false;
  }
  if (!["https:", "http:"].includes(url.protocol) || url.username || url.password) return false;
  const adayHost = alanAdiCikar(url.hostname);
  if (!adayHost || pazaryeriVeyaAraciMi(adayHost)) return false;
  const kilitli = alanAdiCikar(kilitliResmiAlan);
  if (!kilitli || pazaryeriVeyaAraciMi(kilitli)) return true;
  if (adayHost === kilitli || adayHost.endsWith(`.${kilitli}`)) return true;
  if (secenekler?.gorsel !== false && mesruEticaretCdnMi(adayHost)) return true;
  if (!secenekler?.gorsel) return false;
  for (const izinli of secenekler.izinliGorselAlanlari ?? []) {
    const temiz = alanAdiCikar(izinli);
    if (temiz && !pazaryeriVeyaAraciMi(temiz) && (adayHost === temiz || adayHost.endsWith(`.${temiz}`))) {
      return true;
    }
  }
  return false;
}

export function faturaRenginiCoz(varyant: unknown, urunAdi?: unknown, hamSatir?: unknown): string {
  const varyantMetin = metinDegeri(varyant);
  if (varyantMetin) {
    const parcalar = varyantMetin.split(/[\s/,;|·\-_.]+/).filter(Boolean);
    for (const parca of parcalar) {
      const anahtar = parca.toLocaleUpperCase("tr-TR");
      if (Object.hasOwn(RENK_KISALTMALARI, anahtar)) {
        return RENK_KISALTMALARI[anahtar];
      }
    }
  }
  for (const metin of [urunAdi, hamSatir].map(metinDegeri).filter(Boolean)) {
    const parcalar = metin.split(/[\s/,;|·\-_.]+/).filter(Boolean);
    for (let i = parcalar.length - 1; i >= 0; i--) {
      const anahtar = parcalar[i].toLocaleUpperCase("tr-TR");
      if (Object.hasOwn(RENK_KISALTMALARI, anahtar)) {
        return RENK_KISALTMALARI[anahtar];
      }
    }
  }
  return "";
}

export function aciklamayaFaturaRengiEkle(aciklama: string, faturaRengi: string): string {
  const temizAciklama = metinDegeri(aciklama);
  const temizRenk = metinDegeri(faturaRengi);
  if (!temizRenk) return temizAciklama;
  if (temizAciklama.toLocaleLowerCase("tr-TR").includes(temizRenk.toLocaleLowerCase("tr-TR"))) {
    return temizAciklama;
  }
  return temizAciklama ? `${temizAciklama} · Renk: ${temizRenk}` : `Renk: ${temizRenk}`;
}

function hassasAnahtarMi(anahtar: string): boolean {
  const temiz = anahtar.toLocaleLowerCase("tr-TR").replace(/[^a-z0-9_]/g, "");
  return HASSAS_ALAN_ANAHTARLARI.has(temiz) || HASSAS_ALAN_ANAHTARLARI.has(temiz.replace(/_/g, ""));
}

function kural32DegerTemizle(deger: unknown, derinlik: number): unknown {
  if (derinlik > 6 || deger === null || typeof deger !== "object") return deger;
  if (Array.isArray(deger)) {
    return deger
      .filter((eleman) => {
        if (!eleman || typeof eleman !== "object" || Array.isArray(eleman)) return true;
        const kayit = eleman as Record<string, unknown>;
        return !hassasAnahtarMi(String(kayit.key ?? "")) && !hassasAnahtarMi(String(kayit.label ?? ""));
      })
      .map((eleman) => kural32DegerTemizle(eleman, derinlik + 1));
  }
  if (Object.getPrototypeOf(deger) !== Object.prototype) return deger;
  const temiz: Record<string, unknown> = {};
  for (const [anahtar, alt] of Object.entries(deger as Record<string, unknown>)) {
    if (hassasAnahtarMi(anahtar)) continue;
    temiz[anahtar] = kural32DegerTemizle(alt, derinlik + 1);
  }
  return temiz;
}

export function kural32NesneTemizle(kayit: Record<string, unknown>): Record<string, unknown> {
  return kural32DegerTemizle(kayit, 0) as Record<string, unknown>;
}

const GEMINI_GROUNDING_ADRESI =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";
const GROUNDING_ZAMAN_ASIMI_MS = 15_000;

export interface GroundingAramaGirdisi {
  urunAdi: string;
  marka?: string | null;
  model?: string | null;
  barkod?: string | null;
  varyant?: string | null;
  beden?: string | null;
  tedarikci?: string | null;
  tedarikciSite?: string | null;
  kilitliAlanAdi?: string | null;
}

export interface GroundingEslesmeSonucu {
  resmiAlanAdi: string;
  resmiSayfa: string;
  resmiAd: string;
  marka: string;
  aciklama: string;
  kategori: string;
  selectedImageUrl?: string | null;
  gorseller: string[];
  groundingKaynaklari: string[];
}

function geminiAramaAnahtari(): string {
  return (process.env.GEMINI_API_KEY || "").trim() || (process.env.GOOGLE_API_KEY || "").trim();
}

function metinDegeri(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

function jsonGovdeCoz(ham: string): Record<string, unknown> | null {
  const temiz = ham.trim();
  if (!temiz) return null;
  const parcalar = temiz
    .split("```")
    .map((parca) => parca.replace(/^json\s*/i, "").trim())
    .filter(Boolean);
  const adaylar = [temiz, ...parcalar];
  const bas = temiz.indexOf("{");
  const son = temiz.lastIndexOf("}");
  if (bas >= 0 && son > bas) adaylar.push(temiz.slice(bas, son + 1));
  for (const aday of adaylar) {
    try {
      const cozulen = JSON.parse(aday);
      if (cozulen && typeof cozulen === "object" && !Array.isArray(cozulen)) {
        return cozulen as Record<string, unknown>;
      }
    } catch {
      continue;
    }
  }
  return null;
}

export function geminiGroundingBilgileriniCikar(
  aday: Record<string, unknown>,
  resmiAlan?: string | null,
  izinliGorselAlanlari?: readonly string[],
): { webUrller: string[]; gorselUrller: string[] } {
  const webUrller: string[] = [];
  const gorselUrller: string[] = [];
  const ekleWeb = (ham: unknown) => {
    const uri = metinDegeri(ham);
    if (uri && resmiAlanAdiUygunMu(uri, null, { gorsel: false }) && !webUrller.includes(uri)) {
      webUrller.push(uri);
    }
  };
  const ekleGorsel = (ham: unknown) => {
    const uri = metinDegeri(ham);
    if (
      uri &&
      resmiAlanAdiUygunMu(uri, resmiAlan ?? null, { gorsel: true, izinliGorselAlanlari }) &&
      !gorselUrller.includes(uri)
    ) {
      gorselUrller.push(uri);
    }
  };
  const meta = aday.groundingMetadata;
  const chunks = meta && typeof meta === "object" ? (meta as { groundingChunks?: unknown }).groundingChunks : null;
  if (Array.isArray(chunks)) {
    for (const chunk of chunks) {
      if (!chunk || typeof chunk !== "object") continue;
      const web = (chunk as { web?: unknown }).web;
      if (web && typeof web === "object") {
        const uri = metinDegeri((web as { uri?: unknown }).uri);
        ekleWeb(uri);
        if (/\.(?:png|jpe?g|webp|avif|gif)(?:\?.*)?$/i.test(uri)) ekleGorsel(uri);
      }
      const img = (chunk as { image?: unknown }).image;
      if (img && typeof img === "object") {
        const imgKaydi = img as { imageUri?: unknown; uri?: unknown; sourceUri?: unknown };
        ekleGorsel(imgKaydi.imageUri ?? imgKaydi.uri);
        ekleWeb(imgKaydi.sourceUri);
      }
    }
  }
  const urlCtx = aday.urlContextMetadata;
  const urlMetaList = urlCtx && typeof urlCtx === "object" ? (urlCtx as { urlMetadata?: unknown }).urlMetadata : null;
  if (Array.isArray(urlMetaList)) {
    for (const kayit of urlMetaList) {
      if (!kayit || typeof kayit !== "object") continue;
      const durum = metinDegeri((kayit as { urlRetrievalStatus?: unknown }).urlRetrievalStatus);
      if (durum && durum !== "URL_RETRIEVAL_STATUS_SUCCESS") continue;
      ekleWeb((kayit as { retrievedUrl?: unknown }).retrievedUrl);
    }
  }
  return { webUrller, gorselUrller };
}

function groundingUrlListesi(aday: Record<string, unknown>): string[] {
  return geminiGroundingBilgileriniCikar(aday).webUrller;
}

function groundingGorselListesi(
  aday: Record<string, unknown>,
  resmiAlan: string,
  izinliGorselAlanlari?: readonly string[],
): string[] {
  return geminiGroundingBilgileriniCikar(aday, resmiAlan, izinliGorselAlanlari).gorselUrller;
}

const LOGO_URL_DESENI =
  /(?:^|[/._-])(logo|brand[-_]?logo|marka[-_]?logo|favicon|site[-_]?logo|header[-_]?logo)(?:$|[/._-])/i;

export function logoGorselUrliMi(adres: string): boolean {
  try {
    const url = new URL(adres);
    return LOGO_URL_DESENI.test(url.pathname);
  } catch {
    return false;
  }
}

export function gorselAdaylariniSuz(args: {
  adaylar: readonly unknown[];
  seciliGorsel?: unknown;
  tespitEdilenAlan: string | null;
  izinliGorselAlanlari?: readonly string[];
}): string[] {
  const hamSirali = [args.seciliGorsel, ...args.adaylar];
  const sonuc: string[] = [];
  for (const ham of hamSirali) {
    const url = metinDegeri(ham);
    if (!url || !url.startsWith("https://") || pazaryeriVeyaAraciMi(url)) continue;
    if (logoGorselUrliMi(url)) continue;
    if (!resmiAlanAdiUygunMu(url, args.tespitEdilenAlan, { gorsel: true, izinliGorselAlanlari: args.izinliGorselAlanlari })) {
      continue;
    }
    if (!sonuc.includes(url)) sonuc.push(url);
  }
  return sonuc;
}

export async function resmiSayfadanGorselleriTamamla(args: {
  resmiSayfa: string;
  tespitEdilenAlan: string | null;
  mevcutAdaylar: readonly unknown[];
  seciliGorsel?: unknown;
  fetcher?: typeof fetch;
}): Promise<{ selectedImageUrl: string | null; gorseller: string[]; izinliGorselAlanlari: string[] }> {
  const fetcher = args.fetcher ?? globalThis.fetch;
  let gorseller = gorselAdaylariniSuz({
    adaylar: args.mevcutAdaylar,
    seciliGorsel: args.seciliGorsel,
    tespitEdilenAlan: args.tespitEdilenAlan,
  });
  const elenmisPazaryeriDisiVar = [args.seciliGorsel, ...args.mevcutAdaylar]
    .map(metinDegeri)
    .some((url) => url.startsWith("https://") && !pazaryeriVeyaAraciMi(url) && !gorseller.includes(url));
  let izinliGorselAlanlari: string[] = [];
  if (args.resmiSayfa.startsWith("https://") && (gorseller.length === 0 || elenmisPazaryeriDisiVar)) {
    izinliGorselAlanlari = await sayfaGorselAlanAdlari(args.resmiSayfa, fetcher).catch(() => []);
    if (izinliGorselAlanlari.length > 0) {
      gorseller = gorselAdaylariniSuz({
        adaylar: args.mevcutAdaylar,
        seciliGorsel: args.seciliGorsel,
        tespitEdilenAlan: args.tespitEdilenAlan,
        izinliGorselAlanlari,
      });
    }
    if (gorseller.length === 0) {
      const tamamlanan = await gorselsizSatirlariTamamla({
        satirlar: [
          {
            hamSatir: "",
            model: "",
            ad: "",
            barkod: "",
            varyant: "",
            beden: "",
            marka: "",
            adet: null,
            birim: "",
            birimFiyat: null,
            tutar: null,
            okumaGuveni: 1,
            siteSayfa: args.resmiSayfa,
            dogrulamaDurumu: "Doğrulandı",
          },
        ],
        bagimliliklar: { fetcher },
      }).catch(() => []);
      const sayfaGorselleri = tamamlanan[0]?.siteGorseller ?? [];
      if (sayfaGorselleri.length > 0) {
        const alanlar = sayfaGorselleri.map((u) => alanAdiCikar(u)).filter(Boolean);
        izinliGorselAlanlari = [...new Set([...izinliGorselAlanlari, ...alanlar])];
        gorseller = gorselAdaylariniSuz({
          adaylar: [...sayfaGorselleri, ...args.mevcutAdaylar],
          seciliGorsel: args.seciliGorsel ?? sayfaGorselleri[0],
          tespitEdilenAlan: args.tespitEdilenAlan,
          izinliGorselAlanlari,
        });
      }
    }
  }
  return {
    selectedImageUrl: gorseller[0] ?? null,
    gorseller,
    izinliGorselAlanlari,
  };
}

export function groundingIstemiOlustur(
  girdi: GroundingAramaGirdisi,
  kilitliAlan: string | null,
): string {
  const temiz = kural32NesneTemizle(girdi as unknown as Record<string, unknown>) as Record<string, unknown>;
  const kimlik = {
    product_name: kural32MetinTemizle(metinDegeri(temiz.urunAdi ?? temiz.product_name)),
    brand: kural32MetinTemizle(metinDegeri(temiz.marka ?? temiz.brand)),
    model: kural32MetinTemizle(metinDegeri(temiz.model)),
    barcode: metinDegeri(temiz.barkod ?? temiz.barcode),
    variant: metinDegeri(temiz.varyant ?? temiz.variant),
    size: metinDegeri(temiz.beden ?? temiz.size),
    supplier: kural32MetinTemizle(metinDegeri(temiz.tedarikci ?? temiz.supplier)),
    ...(kilitliAlan ? { locked_official_domain: kilitliAlan } : {}),
  };
  const aramaKurali = kilitliAlan
    ? `Resmî üretici alan adı ${kilitliAlan} olarak kilitlidir. Aramayı yalnızca site:${kilitliAlan} içinde daralt ve başka hiçbir domain döndürme.`
    : "Önce ürünün/markanın tek resmî üretici veya marka alan adını (official_domain) belirle, ardından aramayı site:<official_domain> içinde daraltarak resmî ürün sayfasını bul.";
  const ekTalimat = (process.env.GEMINI_FATURA_EK_TALIMAT || "").trim();
  return [
    "Google Search ve urlContext kullanarak aşağıdaki ürün için resmî üretici/marka web sitesini ve doğrudan ürün sayfasını tek seferde eşleştir.",
    aramaKurali,
    TURKIYE_FATURA_KISALTMA_TALIMATI,
    "official_domain, official_product_url, selected_image_url ve image_urls alanları için pazaryeri/aracı siteleri (Trendyol, Hepsiburada, N11, Amazon, Çiçeksepeti, PttAVM, Akakçe, Cimri, Epey, Sahibinden vb.) kesinlikle kullanma ve döndürme; ancak ürünün hangi markaya ait olduğunu (brand) tespit ederken üreticinin kendi sitesinde listelenmeyen kodlar için pazaryeri veya toptancı sayfalarındaki ürün başlıklarından yararlanabilirsin.",
    "Doğrulanmış bir resmî ürün sayfası yoksa tahmin yürütme; official_product_url değerini null döndür.",
    ...(ekTalimat ? [ekTalimat] : []),
    "Yalnızca geçerli JSON nesnesi döndür:",
    '{"official_domain":string|null,"official_product_url":string|null,"official_name":string|null,"brand":string|null,"description":string|null,"category":string|null,"selected_image_url":string|null,"image_urls":string[]}',
    JSON.stringify(kimlik),
  ].join("\n");
}

export function groundingYanitiniCoz(
  veri: unknown,
  kilitliAlan: string | null,
  izinliGorselAlanlari?: readonly string[],
): GroundingEslesmeSonucu | null {
  if (!veri || typeof veri !== "object") return null;
  const adaylar = (veri as { candidates?: unknown }).candidates;
  if (!Array.isArray(adaylar) || !adaylar.length) return null;
  const aday = adaylar[0];
  if (!aday || typeof aday !== "object") return null;
  const adayKaydi = aday as Record<string, unknown>;
  const icerik = adayKaydi.content as { parts?: unknown } | undefined;
  const parcalar = Array.isArray(icerik?.parts) ? icerik.parts : [];
  const hamMetin = parcalar
    .filter(
      (p): p is Record<string, unknown> =>
        Boolean(p && typeof p === "object" && typeof (p as Record<string, unknown>).text === "string" && (p as Record<string, unknown>).thought !== true),
    )
    .map((p) => String(p.text))
    .join("");
  const cozulmus = jsonGovdeCoz(hamMetin);
  const groundedUrller = groundingUrlListesi(adayKaydi);
  const jsonAlan = cozulmus ? (cozulmus.official_domain ?? cozulmus.resmi_alan_adi) : null;
  const jsonSayfa = cozulmus ? metinDegeri(cozulmus.official_product_url ?? cozulmus.resmi_sayfa) : "";

  const tespitEdilenAlan = kilitliAlan
    ? kilitliAlan
    : kilitliResmiAlanAdiSec([jsonAlan, jsonSayfa, ...groundedUrller]);
  if (!tespitEdilenAlan || pazaryeriVeyaAraciMi(tespitEdilenAlan)) return null;

  let resmiSayfa = "";
  if (jsonSayfa) {
    if (resmiAlanAdiUygunMu(jsonSayfa, tespitEdilenAlan, { gorsel: false })) {
      resmiSayfa = jsonSayfa;
    } else {
      const kilitliGrounded = groundedUrller.find((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan, { gorsel: false }));
      if (!kilitliGrounded) return null;
      resmiSayfa = kilitliGrounded;
    }
  } else {
    resmiSayfa = groundedUrller.find((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan, { gorsel: false })) ?? "";
  }
  if (!resmiSayfa || !resmiAlanAdiUygunMu(resmiSayfa, tespitEdilenAlan, { gorsel: false })) return null;

  const hamGorseller = [
    ...(Array.isArray(cozulmus?.image_urls) ? cozulmus.image_urls : []),
    ...(Array.isArray(cozulmus?.gorseller) ? cozulmus.gorseller : []),
    ...(Array.isArray(cozulmus?.images) ? cozulmus.images : []),
    ...groundingGorselListesi(adayKaydi, tespitEdilenAlan, izinliGorselAlanlari),
  ];
  const seciliGorsel = cozulmus?.selected_image_url ?? cozulmus?.image_url;
  const gorseller = gorselAdaylariniSuz({
    adaylar: hamGorseller,
    seciliGorsel,
    tespitEdilenAlan,
    izinliGorselAlanlari,
  });

  const temiz = kural32NesneTemizle({
    official_name: cozulmus?.official_name ?? cozulmus?.resmi_ad,
    brand: cozulmus?.brand ?? cozulmus?.marka,
    description: cozulmus?.description ?? cozulmus?.aciklama,
    category: cozulmus?.category ?? cozulmus?.kategori,
  });

  return {
    resmiAlanAdi: alanAdiCikar(resmiSayfa) || tespitEdilenAlan,
    resmiSayfa,
    resmiAd: metinDegeri(temiz.official_name),
    marka: metinDegeri(temiz.brand),
    aciklama: metinDegeri(temiz.description),
    kategori: metinDegeri(temiz.category),
    selectedImageUrl: gorseller[0] ?? null,
    gorseller,
    groundingKaynaklari: groundedUrller.filter((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan, { gorsel: false })),
  };
}

export async function resmiUrunSayfasiGroundingIleBul(
  girdi: GroundingAramaGirdisi,
  fetcher: typeof fetch = globalThis.fetch,
): Promise<GroundingEslesmeSonucu | null> {
  const apiKey = geminiAramaAnahtari();
  if (!apiKey) return null;
  const temizGirdi = kural32NesneTemizle(girdi as unknown as Record<string, unknown>) as unknown as GroundingAramaGirdisi;
  const aramaTerimiVar = [temizGirdi.urunAdi, temizGirdi.marka, temizGirdi.model, temizGirdi.barkod].some((deger) =>
    Boolean(metinDegeri(deger)),
  );
  if (!aramaTerimiVar) return null;

  const kilitliAlan = kilitliResmiAlanAdiSec([temizGirdi.kilitliAlanAdi, temizGirdi.tedarikciSite]);
  try {
    const yanit = await fetcher(
      GEMINI_GROUNDING_ADRESI,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify({
          contents: [
            {
              role: "user",
              parts: [{ text: groundingIstemiOlustur(temizGirdi, kilitliAlan) }],
            },
          ],
          tools: [
            { googleSearch: {} },
            { urlContext: {} },
          ],
          generationConfig: { temperature: 0.1 },
        }),
        signal: AbortSignal.timeout(GROUNDING_ZAMAN_ASIMI_MS),
      },
    );
    if (!yanit.ok) return null;
    const veri = await yanit.json().catch(() => null);
    const sonuc = groundingYanitiniCoz(veri, kilitliAlan);
    if (!sonuc) return null;
    const faturaRengi = faturaRenginiCoz(temizGirdi.varyant, temizGirdi.urunAdi);
    const aciklama = aciklamayaFaturaRengiEkle(sonuc.aciklama, faturaRengi);
    if (sonuc.gorseller.length > 0) {
      return { ...sonuc, aciklama, selectedImageUrl: sonuc.gorseller[0] };
    }
    const tamamlanan = await resmiSayfadanGorselleriTamamla({
      resmiSayfa: sonuc.resmiSayfa,
      tespitEdilenAlan: sonuc.resmiAlanAdi,
      mevcutAdaylar: [],
      fetcher,
    });
    const finalSonuc = tamamlanan.izinliGorselAlanlari.length > 0
      ? groundingYanitiniCoz(veri, kilitliAlan, tamamlanan.izinliGorselAlanlari) ?? sonuc
      : sonuc;
    const gorseller = [...new Set([...finalSonuc.gorseller, ...tamamlanan.gorseller])];
    return {
      ...finalSonuc,
      aciklama,
      selectedImageUrl: gorseller[0] ?? null,
      gorseller,
    };
  } catch {
    return null;
  }
}

export async function kayitliFaturaKatalogunuUygula(args: {
  admin: SupabaseClient;
  storeId: string;
  editToken: string;
  girdi: HazirUrunGirdisi;
  satir: DogrulanmisSatir;
  kategoriOnbellegi: Map<string, { id: string; templateKey: string }>;
  fetcher?: typeof fetch;
}): Promise<string | null> {
  const { admin, storeId, editToken, girdi, satir, kategoriOnbellegi } = args;
  const hamKatalog =
    satir.katalog && typeof satir.katalog === "object"
      ? kural32NesneTemizle(satir.katalog)
      : null;
  const kilitliAlanAdi = kilitliResmiAlanAdiSec([
    satir.resmiAlanAdi,
    hamKatalog?.official_domain,
    hamKatalog?.resmiAlanAdi,
    hamKatalog?.kaynak,
    hamKatalog?.siteSayfa,
    hamKatalog?.official_product_url,
  ]);
  const mevcutKaynak =
    (typeof hamKatalog?.kaynak === "string" ? hamKatalog.kaynak.trim() : "") ||
    (typeof hamKatalog?.siteSayfa === "string" ? hamKatalog.siteSayfa.trim() : "") ||
    (typeof hamKatalog?.official_product_url === "string"
      ? hamKatalog.official_product_url.trim()
      : "");
  const mevcutKaynakPazaryeri = Boolean(mevcutKaynak) && pazaryeriVeyaAraciMi(mevcutKaynak);
  const mevcutKaynakGecerli =
    Boolean(mevcutKaynak) && resmiAlanAdiUygunMu(mevcutKaynak, kilitliAlanAdi, { gorsel: false });
  const mevcutResmiAdGecerli =
    typeof hamKatalog?.resmiAd === "string" && Boolean(hamKatalog.resmiAd.trim());

  let katalog =
    hamKatalog && !hamKatalog.kaynak && mevcutKaynak
      ? { ...hamKatalog, kaynak: mevcutKaynak }
      : hamKatalog;
  const googleSokettenHazir =
    Boolean(katalog) &&
    mevcutResmiAdGecerli &&
    mevcutKaynakGecerli &&
    !mevcutKaynakPazaryeri &&
    (satir.izinliGorseller?.size ?? 0) > 0;
  const groundingGerekli =
    !googleSokettenHazir &&
    (!katalog ||
      !mevcutResmiAdGecerli ||
      mevcutKaynakPazaryeri ||
      (Boolean(mevcutKaynak) && !mevcutKaynakGecerli) ||
      (!mevcutKaynak && satir.sonuc !== "kanitli"));

  if (groundingGerekli && geminiAramaAnahtari()) {
    const grounding = await resmiUrunSayfasiGroundingIleBul(
      {
        urunAdi: metinDegeri(satir.urunAdi) || metinDegeri(girdi.name),
        marka: metinDegeri(satir.marka) || metinDegeri(girdi.brand) || metinDegeri(katalog?.marka) || null,
        model: metinDegeri(satir.model) || null,
        barkod: metinDegeri(satir.barkod) || metinDegeri(girdi.barcode) || null,
        varyant: satir.varyant || null,
        beden: satir.beden || null,
        tedarikci: satir.tedarikci || null,
        tedarikciSite: satir.tedarikciSite || null,
        kilitliAlanAdi,
      },
      args.fetcher,
    );
    if (grounding) {
      const faturaRengiGrounding =
        metinDegeri(katalog?.faturaRengi) ||
        faturaRenginiCoz(satir.varyant || katalog?.varyant, satir.urunAdi || girdi.name);
      katalog = kural32NesneTemizle({
        ...(katalog ?? {}),
        resmiAd: grounding.resmiAd || metinDegeri(katalog?.resmiAd) || metinDegeri(girdi.name),
        marka: grounding.marka || metinDegeri(katalog?.marka),
        aciklama: grounding.aciklama || metinDegeri(katalog?.aciklama),
        kategori: grounding.kategori || metinDegeri(katalog?.kategori),
        kaynak: grounding.resmiSayfa,
        official_domain: grounding.resmiAlanAdi,
        resmiAlanAdi: grounding.resmiAlanAdi,
        dogrulamaDurumu: "Doğrulandı",
        groundingKaynaklari: grounding.groundingKaynaklari,
        selected_image_url: grounding.selectedImageUrl ?? grounding.gorseller[0] ?? null,
        gorseller: grounding.gorseller,
        gorselAdaylari: grounding.gorseller,
        ...(faturaRengiGrounding ? { faturaRengi: faturaRengiGrounding } : {}),
      });
      satir.katalog = katalog;
      satir.resmiAlanAdi = grounding.resmiAlanAdi;
      for (const url of grounding.gorseller) {
        if (url.trim() && satir.gorselHakDurumlari?.get(url.trim()) !== "denied") {
          satir.izinliGorseller?.add(url.trim());
        }
      }
    }
  }

  if (katalog && typeof katalog.kaynak === "string" && katalog.kaynak.trim() && pazaryeriVeyaAraciMi(katalog.kaynak)) {
    katalog.kaynak = "";
  }

  if (satir.sonuc !== "kanitli" && !katalog) return null;
  if (!katalog || typeof katalog.resmiAd !== "string" || typeof katalog.kaynak !== "string") {
    return "Kayıtlı resmî ürün kaynağı eksik; yeniden eşleştir.";
  }
  if (satir.sonuc === "kanitli" && !katalog.kaynak.trim() && mevcutKaynakPazaryeri) {
    return "Kayıtlı resmî ürün kaynağı eksik; yeniden eşleştir.";
  }
  if (katalog.resmiAd.trim()) girdi.name = katalog.resmiAd.trim();
  const faturaRengi =
    metinDegeri(katalog.faturaRengi) ||
    faturaRenginiCoz(satir.varyant || katalog.varyant, satir.urunAdi || girdi.name);
  if (faturaRengi) katalog.faturaRengi = faturaRengi;
  satir.katalog = katalog;
  girdi.description = aciklamayaFaturaRengiEkle(
    typeof katalog.aciklama === "string" ? katalog.aciklama : "",
    faturaRengi,
  );
  girdi.brand = typeof katalog.marka === "string" ? katalog.marka : null;
  const gorselKaynagiListesi = [
    katalog.selected_image_url,
    ...(Array.isArray(katalog.gorseller) ? katalog.gorseller : []),
    ...(Array.isArray(katalog.gorselAdaylari) ? katalog.gorselAdaylari : []),
  ];
  const ureticiGorselleri = [
    ...new Set(
      gorselKaynagiListesi
        .map((url) => metinDegeri(url))
        .filter((url) => url.startsWith("https://") && !pazaryeriVeyaAraciMi(url)),
    ),
  ];
  if (ureticiGorselleri.length > 0) {
    girdi.imageUrls = [...new Set([...ureticiGorselleri, ...girdi.imageUrls])];
    for (const url of ureticiGorselleri) {
      if (satir.gorselHakDurumlari?.get(url) !== "denied") {
        satir.izinliGorseller?.add(url);
      }
    }
  } else if (
    girdi.imageUrls.length === 0 &&
    katalog.kaynak.startsWith("https://") &&
    !pazaryeriVeyaAraciMi(katalog.kaynak) &&
    (args.fetcher || satir.sonuc === "kanitli")
  ) {
    const kurtarilan = await resmiSayfadanGorselleriTamamla({
      resmiSayfa: katalog.kaynak,
      tespitEdilenAlan: kilitliAlanAdi || alanAdiCikar(katalog.kaynak),
      mevcutAdaylar: [],
      fetcher: args.fetcher,
    });
    if (kurtarilan.gorseller.length > 0) {
      girdi.imageUrls = [...kurtarilan.gorseller];
      katalog.selected_image_url = kurtarilan.selectedImageUrl;
      katalog.gorseller = kurtarilan.gorseller;
      katalog.gorselAdaylari = kurtarilan.gorseller;
      for (const url of kurtarilan.gorseller) {
        if (satir.gorselHakDurumlari?.get(url) !== "denied") {
          satir.izinliGorseller?.add(url);
        }
      }
    }
  }
  girdi.metadata = kural32NesneTemizle({
    ...girdi.metadata,
    attributes: [],
    manufacturerSource: undefined,
    ...faturaKatalogMetadatasi(katalog),
  });
  const varyantlar = Array.isArray(katalog.urunVaryantlari) ? katalog.urunVaryantlari : [];
  girdi.variants = normalizeProductVariants(varyantlar.map((raw) => {
    const variant = raw && typeof raw === "object" ? raw as Record<string, unknown> : {};
    const secenekler = Array.isArray(variant.secenekler) ? variant.secenekler : [];
    const options: Record<string, string> = {};
    for (const secenek of secenekler) {
      if (!secenek || typeof secenek !== "object") continue;
      const option = secenek as Record<string, unknown>;
      if (typeof option.key === "string" && typeof option.value === "string") options[option.key] = option.value;
    }
    return { id: variant.id, options, barcode: variant.barkod, imageUrls: variant.gorseller };
  }), true);
  const lunaKategori = typeof katalog.kategori === "string" ? katalog.kategori.trim() : "";
  if (!lunaKategori) return null;
  if (typeof admin?.from !== "function") return null;
  const birlesik = kategoriBirlestir(lunaKategori);
  const anahtar = birlesik.anahtar;
  let kategori = kategoriOnbellegi.get(anahtar);
  if (!kategori) {
    const mevcutlar = await admin.from("product_categories").select("id,name,product_template_key")
      .eq("store_id", storeId);
    if (mevcutlar.error) return "Luna'nın kategorisi okunamadı; tekrar dene.";
    const eslesen = (Array.isArray(mevcutlar.data) ? mevcutlar.data : []).find(
      (satir: { name?: string | null; id?: unknown; product_template_key?: string | null }) =>
        kategoriBirlestir(String(satir.name ?? "")).anahtar === anahtar,
    );
    if (eslesen) {
      kategori = { id: String(eslesen.id), templateKey: eslesen.product_template_key || "generic" };
    } else {
      const ekleme = await admin.rpc("upsert_store_category_v2", {
        p_store_id: storeId, p_edit_token: editToken,
        p_name: birlesik.ad, p_template_key: "generic",
        p_slug: `luna-${createHash("sha256").update(anahtar).digest("hex").slice(0, 24)}`,
      });
      if (!ekleme.error && ekleme.data?.success === true && typeof ekleme.data.id === "string") {
        kategori = { id: ekleme.data.id, templateKey: "generic" };
      }
    }
    if (!kategori) return "Luna'nın kategorisi kaydedilemedi; tekrar dene.";
    kategoriOnbellegi.set(anahtar, kategori);
  }
  girdi.categoryId = kategori.id;
  girdi.metadata = kural32NesneTemizle({ ...girdi.metadata, templateKey: kategori.templateKey });
  return null;
}

export async function faturaUrunGorselleriniAktar(args: {
  admin: SupabaseClient;
  slug: string;
  girdi: HazirUrunGirdisi;
  satir: DogrulanmisSatir;
  sonTarih?: number;
}) {
  const { admin, slug, girdi, satir } = args;
  const kaynakGorselleri = girdi.imageUrls.filter(
    (adres) => yonetilenUrunGorseliMi(adres) || satir.izinliGorseller.has(adres.trim()),
  );
  const disGorseller = kaynakGorselleri.filter((adres) => !yonetilenUrunGorseliMi(adres));
  let urunGorselleri = kaynakGorselleri;
  let gorselDurumu = "";
  let gorselKaynaklari: Array<Record<string, unknown>> = [];
  let gorselRedleri: Array<{ kaynakGorsel: string; sebep: string }> = [];
  const aktarilacakGorseller = [...new Set([...disGorseller,
    ...girdi.variants.flatMap((variant) => variant.imageUrls ?? [])
      .filter((url) => !yonetilenUrunGorseliMi(url) && satir.izinliGorseller.has(url.trim())),
  ])];
  if (aktarilacakGorseller.length > 0) {
    const hamKaynak = typeof satir.katalog?.kaynak === "string" ? satir.katalog.kaynak : "";
    const kaynakSayfa = hamKaynak && !pazaryeriVeyaAraciMi(hamKaynak) ? hamKaynak : "";
    const hazir = await kaynakGorselleriniHazirla({
      admin, slug,
      kaynakSayfa,
      adaylar: aktarilacakGorseller,
      sonTarih: args.sonTarih,
    });
    gorselRedleri = hazir.reddedilenler.map((red) => ({ kaynakGorsel: red.kaynakGorsel, sebep: String(red.sebep) }));
    const depodaki = new Map(hazir.gorseller.map((gorsel) => [gorsel.kaynakGorsel, gorsel]));
    const altyapiHatasi = hazir.reddedilenler.some((red) => red.sebep !== "kaynak-uyumsuz");
    urunGorselleri = kaynakGorselleri.flatMap((adres) => {
      if (yonetilenUrunGorseliMi(adres)) return [adres];
      const kopya = depodaki.get(adres);
      return kopya ? [kopya.url] : [];
    });
    gorselKaynaklari = hazir.gorseller.map((gorsel) => ({
      depoUrl: gorsel.url, kaynakGorsel: gorsel.kaynakGorsel,
      kaynakSayfa: gorsel.kaynakSayfa, genislik: gorsel.genislik, yukseklik: gorsel.yukseklik,
      ...gorselHakKaydiniRaporla(gorsel.kaynakGorsel, satir.gorselHakDurumlari),
    }));
    gorselDurumu = altyapiHatasi ? "aktarim-bekliyor" : urunGorselleri.length === 0 ? "gorsel-yok" : "depoda";
  }
  const depoGorselleri = new Map(gorselKaynaklari.map((kaynak) =>
    [String(kaynak.kaynakGorsel || ""), String(kaynak.depoUrl || "")]));
  girdi.variants = girdi.variants.map((variant) => ({
    ...variant,
    imageUrls: variant.imageUrls?.map((url) =>
      depoGorselleri.get(url) || (yonetilenUrunGorseliMi(url) ? url : "")).filter(Boolean),
  }));
  if (!gorselDurumu) gorselDurumu = urunGorselleri.length === 0 ? "gorsel-yok" : "depoda";
  return { urunGorselleri, gorselDurumu, gorselKaynaklari, gorselRedleri };
}
