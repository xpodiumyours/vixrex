import { createHash } from "node:crypto";
import sharp from "sharp";
import { hostGuvenliMi, varsayilanCoz, pdfKatalogGorseliniOku } from "@/lib/faturaDijitalIz";
import { gorseliSikistir, ONBELLEK_SANIYE } from "@/lib/gorselSikistir";
import {
  FATURA_MIN_SOURCE_SHORT_EDGE,
  MAX_PRODUCT_IMAGES,
  MAX_PRODUCT_IMAGE_SOURCE_BYTES,
} from "@/lib/productImagePolicy";

export type GorselRedSebebi =
  | "erisilemedi"
  | "acilmadi"
  | "gorsel-degil"
  | "cok-buyuk"
  | "cok-kucuk"
  | "logo-veya-yer-tutucu"
  | "bos"
  | "urun-fotografi-degil";

export interface KaynakGorselDogrulamasi {
  tamam: boolean;
  sebep?: GorselRedSebebi;
  genislik?: number;
  yukseklik?: number;
  tur?: string;
  bayt?: Uint8Array;
}

export interface GorselBagimliliklari {
  fetcher?: (input: string, init?: RequestInit) => Promise<Response>;
  resolveHost?: (hostname: string) => Promise<string[]>;
}

export interface HazirlananGorsel {
  url: string;
  kaynakGorsel: string;
  kaynakSayfa: string;
  genislik: number;
  yukseklik: number;
}

export interface ReddedilenGorsel {
  kaynakGorsel: string;
  sebep: GorselRedSebebi | "depoya-yazilamadi";
}

export interface GorselHazirlamaSonucu {
  gorseller: HazirlananGorsel[];
  reddedilenler: ReddedilenGorsel[];
  altyapiSorunu: boolean;
}

const ZAMAN_ASIMI_MS = 6000;
const YER_TUTUCU_ADRES = /(^|[\/_\-.])(logo|favicon|placeholder|no[-_]?image|noimage|default[-_]?image|blank|sprite|banner)([\/_\-.]|$)/i;
const EN_BOY_SINIRI = 3.5;
const BOS_SAPMA_ESIGI = 3;

function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;
  if (bayt[0] === 0xff && bayt[1] === 0xd8 && bayt[2] === 0xff) return "image/jpeg";
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (png.every((b, i) => bayt[i] === b)) return "image/png";
  const riff = [0x52, 0x49, 0x46, 0x46];
  const webp = [0x57, 0x45, 0x42, 0x50];
  if (riff.every((b, i) => bayt[i] === b) && webp.every((b, i) => bayt[8 + i] === b)) {
    return "image/webp";
  }
  return null;
}

export async function kaynakGorseliniDogrula(
  adres: string,
  bagimliliklar: GorselBagimliliklari = {},
): Promise<KaynakGorselDogrulamasi> {
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;

  let url: URL;
  try {
    url = new URL(adres);
  } catch {
    return { tamam: false, sebep: "acilmadi" };
  }
  if (url.protocol !== "https:" || url.username || url.password || url.port) {
    return { tamam: false, sebep: "acilmadi" };
  }
  if (YER_TUTUCU_ADRES.test(decodeURIComponent(url.pathname))) {
    return { tamam: false, sebep: "logo-veya-yer-tutucu" };
  }
  if (!(await hostGuvenliMi(url.hostname, resolveHost))) {
    return { tamam: false, sebep: "erisilemedi" };
  }

  let bayt: Uint8Array;
  if (new URLSearchParams(url.hash.slice(1)).has("vixrex-page")) {
    const sonuc = await pdfKatalogGorseliniOku(adres, { fetcher, resolveHost });
    if (!sonuc) return { tamam: false, sebep: "acilmadi" };
    bayt = sonuc;
  } else {
  let yanit: Response;
  try {
    yanit = await fetcher(url.toString(), {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(ZAMAN_ASIMI_MS),
      headers: { accept: "image/jpeg,image/png,image/webp" },
    });
  } catch {
    return { tamam: false, sebep: "erisilemedi" };
  }
  if (yanit.status >= 500) return { tamam: false, sebep: "erisilemedi" };
  if (yanit.status !== 200) return { tamam: false, sebep: "acilmadi" };

  const bildirilen = Number(yanit.headers.get("content-length") ?? 0);
  if (Number.isFinite(bildirilen) && bildirilen > MAX_PRODUCT_IMAGE_SOURCE_BYTES) {
    return { tamam: false, sebep: "cok-buyuk" };
  }

  try {
    bayt = new Uint8Array(await yanit.arrayBuffer());
  } catch {
    return { tamam: false, sebep: "erisilemedi" };
  }
  }
  if (bayt.byteLength > MAX_PRODUCT_IMAGE_SOURCE_BYTES) {
    return { tamam: false, sebep: "cok-buyuk" };
  }

  const tur = gercekTur(bayt);
  if (!tur) return { tamam: false, sebep: "gorsel-degil" };

  let genislik: number;
  let yukseklik: number;
  let bos: boolean;
  try {
    const goruntu = sharp(Buffer.from(bayt));
    const bilgi = await goruntu.metadata();
    genislik = bilgi.width ?? 0;
    yukseklik = bilgi.height ?? 0;
    const istatistik = await sharp(Buffer.from(bayt)).stats();
    bos = istatistik.channels.every((kanal) => kanal.stdev < BOS_SAPMA_ESIGI);
  } catch {
    return { tamam: false, sebep: "gorsel-degil" };
  }

  if (genislik <= 0 || yukseklik <= 0) return { tamam: false, sebep: "gorsel-degil" };
  if (Math.min(genislik, yukseklik) < FATURA_MIN_SOURCE_SHORT_EDGE) {
    return { tamam: false, sebep: "cok-kucuk", genislik, yukseklik };
  }
  if (bos) return { tamam: false, sebep: "bos", genislik, yukseklik };
  if (Math.max(genislik, yukseklik) / Math.min(genislik, yukseklik) > EN_BOY_SINIRI) {
    return { tamam: false, sebep: "urun-fotografi-degil", genislik, yukseklik };
  }

  return { tamam: true, genislik, yukseklik, tur, bayt };
}

const KART_REDDI = new Set<GorselRedSebebi>([
  "erisilemedi",
  "acilmadi",
  "gorsel-degil",
  "cok-buyuk",
  "cok-kucuk",
  "logo-veya-yer-tutucu",
  "bos",
  "urun-fotografi-degil",
]);

function sadeMetin(deger: string): string {
  return deger
    .toLocaleLowerCase("tr-TR")
    .replace(/ç/g, "c")
    .replace(/ğ/g, "g")
    .replace(/ı/g, "i")
    .replace(/ö/g, "o")
    .replace(/ş/g, "s")
    .replace(/ü/g, "u");
}

function htmlMetni(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ")
    .trim();
}

function cozulmus(deger: string): string {
  return deger.replace(/&amp;/g, "&").replace(/&quot;/g, "\"").trim();
}

function mutlakHttps(kaynak: string, sayfa: string): string {
  try {
    const url = new URL(kaynak, sayfa);
    if (url.protocol !== "https:" || url.username || url.password || url.port) return "";
    return url.toString();
  } catch {
    return "";
  }
}

function gorselAdresi(deger: unknown, sayfa: string): string {
  if (typeof deger === "string") return mutlakHttps(cozulmus(deger), sayfa);
  if (Array.isArray(deger)) {
    for (const oge of deger) {
      const bulunan = gorselAdresi(oge, sayfa);
      if (bulunan) return bulunan;
    }
    return "";
  }
  if (deger && typeof deger === "object" && "url" in deger) {
    return gorselAdresi((deger as { url?: unknown }).url, sayfa);
  }
  return "";
}

function urunKaydi(dugum: unknown): { name?: unknown; description?: unknown; image?: unknown } | null {
  if (!dugum || typeof dugum !== "object") return null;
  const kayit = dugum as { "@type"?: unknown; "@graph"?: unknown };
  const tur = kayit["@type"];
  const turler = (Array.isArray(tur) ? tur : [tur]).map((parca) => String(parca ?? "").toLowerCase());
  if (turler.includes("product")) return kayit as { name?: unknown; description?: unknown; image?: unknown };
  const grafik = kayit["@graph"];
  if (Array.isArray(grafik)) {
    for (const alt of grafik) {
      const bulunan = urunKaydi(alt);
      if (bulunan) return bulunan;
    }
  }
  return null;
}

function metaIcerik(html: string, anahtar: string, alan: "property" | "name"): string {
  const ilk = new RegExp(`<meta[^>]+${alan}=["']${anahtar}["'][^>]+content=["']([^"']+)["']`, "i").exec(html)?.[1];
  const ters = new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+${alan}=["']${anahtar}["']`, "i").exec(html)?.[1];
  return cozulmus(ilk || ters || "");
}

export function sayfadakiUrun(html: string, sayfa: string): { ad: string; aciklama: string; gorsel: string } {
  let ad = "";
  let aciklama = "";
  let gorsel = "";
  const parcalar = html.match(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi) ?? [];
  for (const parca of parcalar) {
    const govde = parca.replace(/^<script[^>]*>/i, "").replace(/<\/script>$/i, "").trim();
    let cozulen: unknown;
    try {
      cozulen = JSON.parse(govde);
    } catch {
      continue;
    }
    const urun = urunKaydi(cozulen);
    if (!urun) continue;
    if (!ad && typeof urun.name === "string") ad = urun.name.trim();
    if (!aciklama && typeof urun.description === "string") aciklama = htmlMetni(urun.description).slice(0, 500);
    if (!gorsel) gorsel = gorselAdresi(urun.image, sayfa);
    if (ad && aciklama && gorsel) break;
  }
  if (!ad) ad = htmlMetni(metaIcerik(html, "og:title", "property")).slice(0, 300);
  if (!aciklama) aciklama = htmlMetni(metaIcerik(html, "description", "name")).slice(0, 500);
  if (!gorsel) gorsel = mutlakHttps(metaIcerik(html, "og:image", "property"), sayfa);
  return { ad, aciklama, gorsel };
}

export async function sayfadanUrunKaydi(
  adres: string,
  kimlik: { model: string; ad: string },
  bagimliliklar: GorselBagimliliklari = {},
): Promise<{ ad: string; aciklama: string; gorsel: string } | null> {
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;
  let url: URL;
  try {
    url = new URL(adres);
  } catch {
    return null;
  }
  if (url.protocol !== "https:" || url.username || url.password || url.port) return null;
  if (!(await hostGuvenliMi(url.hostname, resolveHost))) return null;
  let yanit: Response;
  try {
    yanit = await fetcher(url.toString(), {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(ZAMAN_ASIMI_MS),
      headers: { accept: "text/html" },
    });
  } catch {
    return null;
  }
  if (yanit.status !== 200) return null;
  let html = "";
  try {
    html = await yanit.text();
  } catch {
    return null;
  }
  if (html.length > 1_000_000) html = html.slice(0, 1_000_000);
  const sadeGovde = sadeMetin(htmlMetni(html));
  const anahtarlar = [kimlik.model, kimlik.ad].map((parca) => parca.trim()).filter((parca) => parca.length >= 3);
  if (!anahtarlar.some((parca) => sadeGovde.includes(sadeMetin(parca)))) return null;
  const kayit = sayfadakiUrun(html, adres);
  if (!kayit.gorsel) return null;
  return kayit;
}

export async function sayfadanUrunAciklamasi(
  adres: string,
  kimlik: { model: string; ad: string },
  bagimliliklar: GorselBagimliliklari = {},
): Promise<string> {
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;
  let url: URL;
  try {
    url = new URL(adres);
  } catch {
    return "";
  }
  if (url.protocol !== "https:" || url.username || url.password || url.port) return "";
  if (!(await hostGuvenliMi(url.hostname, resolveHost))) return "";

  let yanit: Response;
  try {
    yanit = await fetcher(url.toString(), {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(ZAMAN_ASIMI_MS),
      headers: { accept: "text/html" },
    });
  } catch {
    return "";
  }
  if (yanit.status !== 200) return "";
  let html = "";
  try {
    html = await yanit.text();
  } catch {
    return "";
  }
  if (html.length > 1_000_000) html = html.slice(0, 1_000_000);

  const meta = html.match(/<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i)?.[1]
    ?? html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+name=["']description["']/i)?.[1]
    ?? "";
  const metaMetin = htmlMetni(meta);
  const govde = htmlMetni(html);
  const sadeGovde = sadeMetin(`${metaMetin} ${govde}`);
  const anahtarlar = [kimlik.model, kimlik.ad]
    .map((parca) => parca.trim())
    .filter((parca) => parca.length >= 3);
  const tutan = anahtarlar.find((parca) => sadeGovde.includes(sadeMetin(parca)));
  if (!tutan) return "";

  if (metaMetin && sadeMetin(metaMetin).includes(sadeMetin(tutan))) return metaMetin.slice(0, 500);

  const yer = sadeGovde.indexOf(sadeMetin(tutan));
  const bas = Math.max(0, yer - 80);
  return govde.slice(bas, bas + 320).trim();
}

export async function kartaGirecekGorsel(
  adres: string,
  bagimliliklar: GorselBagimliliklari = {},
): Promise<string> {
  const temiz = adres.trim();
  if (!temiz) return "";
  const sonuc = await kaynakGorseliniDogrula(temiz, bagimliliklar);
  if (sonuc.tamam) return temiz;
  if (sonuc.sebep && KART_REDDI.has(sonuc.sebep)) return "";
  return temiz;
}

interface DepoIstemcisi {
  storage: {
    from: (kova: string) => {
      upload: (
        yol: string,
        bayt: Uint8Array,
        secenekler: { contentType: string; cacheControl: string; upsert: boolean },
      ) => Promise<{ error: { message: string } | null }>;
      getPublicUrl: (yol: string) => { data: { publicUrl: string } };
    };
  };
}

export async function kaynakGorselleriniHazirla(args: {
  admin: DepoIstemcisi;
  slug: string;
  kaynakSayfa: string;
  adaylar: string[];
  bagimliliklar?: GorselBagimliliklari;
}): Promise<GorselHazirlamaSonucu> {
  const gorseller: HazirlananGorsel[] = [];
  const reddedilenler: ReddedilenGorsel[] = [];
  let altyapiSorunu = false;
  const guvenliSlug = args.slug.replace(/[^a-zA-Z0-9-]/g, "");

  for (const aday of [...new Set(args.adaylar)]) {
    if (gorseller.length >= MAX_PRODUCT_IMAGES) break;

    const kontrol = await kaynakGorseliniDogrula(aday, args.bagimliliklar);
    if (!kontrol.tamam || !kontrol.bayt || !kontrol.tur) {
      const sebep = kontrol.sebep ?? "acilmadi";
      if (sebep === "erisilemedi") altyapiSorunu = true;
      reddedilenler.push({ kaynakGorsel: aday, sebep });
      continue;
    }

    try {
      const sikistirilmis = await gorseliSikistir(kontrol.bayt, kontrol.tur);
      const ozet = createHash("sha256").update(kontrol.bayt).digest("hex").slice(0, 24);
      const yol = `${guvenliSlug}/products/fatura/${ozet}.${sikistirilmis.uzanti}`;
      const { error } = await args.admin.storage.from("shelf-images").upload(yol, sikistirilmis.bayt, {
        contentType: sikistirilmis.tur,
        cacheControl: ONBELLEK_SANIYE,
        upsert: true,
      });
      if (error) {
        altyapiSorunu = true;
        reddedilenler.push({ kaynakGorsel: aday, sebep: "depoya-yazilamadi" });
        continue;
      }
      const { data } = args.admin.storage.from("shelf-images").getPublicUrl(yol);
      gorseller.push({
        url: data.publicUrl,
        kaynakGorsel: aday,
        kaynakSayfa: args.kaynakSayfa,
        genislik: kontrol.genislik ?? 0,
        yukseklik: kontrol.yukseklik ?? 0,
      });
    } catch {
      altyapiSorunu = true;
      reddedilenler.push({ kaynakGorsel: aday, sebep: "depoya-yazilamadi" });
    }
  }

  return { gorseller, reddedilenler, altyapiSorunu };
}
