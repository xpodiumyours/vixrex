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


export async function urunSayfasindaGorselKaniti(
  kaynakSayfa: string,
  gorselAdresi: string,
  varyant: string,
  bagimliliklar: GorselBagimliliklari = {},
): Promise<{ kaynakAlintisi: string } | null> {
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;
  let sayfa: URL;
  let gorsel: URL;
  try {
    sayfa = new URL(kaynakSayfa);
    gorsel = new URL(gorselAdresi);
  } catch {
    return null;
  }
  if (
    sayfa.protocol !== "https:" || sayfa.username || sayfa.password || sayfa.port ||
    gorsel.protocol !== "https:" || gorsel.username || gorsel.password || gorsel.port ||
    !(await hostGuvenliMi(sayfa.hostname, resolveHost))
  ) return null;

  let cevap: Response;
  try {
    cevap = await fetcher(sayfa.toString(), {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(ZAMAN_ASIMI_MS),
      headers: { accept: "text/html,application/xhtml+xml" },
    });
  } catch {
    return null;
  }
  const tur = cevap.headers.get("content-type") ?? "";
  if (cevap.status !== 200 || !/^(text\/html|application\/xhtml\+xml)/i.test(tur)) return null;
  const MAKS_SAYFA_BAYT = 2 * 1024 * 1024;
  const bildirilen = Number(cevap.headers.get("content-length") ?? 0);
  if (Number.isFinite(bildirilen) && bildirilen > MAKS_SAYFA_BAYT) return null;
  const oku = cevap.body?.getReader();
  if (!oku) return null;
  const parcalar: Uint8Array[] = [];
  let toplam = 0;
  try {
    while (true) {
      const { done, value } = await oku.read();
      if (done) break;
      toplam += value.byteLength;
      if (toplam > MAKS_SAYFA_BAYT) {
        await oku.cancel();
        return null;
      }
      parcalar.push(value);
    }
  } catch {
    return null;
  }
  const bayt = new Uint8Array(toplam);
  let offset = 0;
  for (const parca of parcalar) {
    bayt.set(parca, offset);
    offset += parca.byteLength;
  }
  const html = new TextDecoder().decode(bayt)
    .replaceAll("&amp;", "&")
    .replaceAll("&#38;", "&")
    .replaceAll("\\/","/")
    .replaceAll("\\u0026", "&")
    .replaceAll("\\u002F", "/");
  const adres = gorsel.toString();
  const konum = html.indexOf(adres);
  if (konum < 0) return null;
  const baslangic = Math.max(0, konum - 260);
  const bitis = Math.min(html.length, konum + adres.length + 260);
  const kaynakAlintisi = html.slice(baslangic, bitis).replace(/\s+/g, " ").trim();
  if (varyant.trim() && !kaynakAlintisi.toLocaleLowerCase("tr-TR").includes(varyant.trim().toLocaleLowerCase("tr-TR"))) {
    return null;
  }
  return { kaynakAlintisi };
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
