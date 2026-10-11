import { createHash } from "node:crypto";
import sharp from "sharp";
import { hostGuvenliMi, varsayilanCoz, pdfKatalogGorseliniOku } from "@/lib/faturaDijitalIz";
import { gorseliSikistir, ONBELLEK_SANIYE, UZUN_KENAR } from "@/lib/gorselSikistir";
import {
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
  if (!(await hostGuvenliMi(url.hostname, resolveHost))) {
    return { tamam: false, sebep: "erisilemedi" };
  }

  let bayt: Uint8Array;
  if (new URLSearchParams(url.hash.slice(1)).has("vixrex-page")) {
    const sonuc = await pdfKatalogGorseliniOku(adres, { fetcher, resolveHost });
    if (!sonuc) return { tamam: false, sebep: "acilmadi" };
    bayt = sonuc;
  } else {
    let yanit: Response | null = null;
    const gorulenler = new Set<string>();
    const signal = AbortSignal.timeout(ZAMAN_ASIMI_MS);
    try {
      for (let adim = 0; adim <= 5; adim++) {
        if (url.protocol !== "https:" || url.username || url.password || url.port || gorulenler.has(url.href)) {
          return { tamam: false, sebep: "acilmadi" };
        }
        if (!(await hostGuvenliMi(url.hostname, resolveHost))) {
          return { tamam: false, sebep: "erisilemedi" };
        }
        gorulenler.add(url.href);
        yanit = await fetcher(url.toString(), {
          method: "GET", redirect: "manual", signal,
          headers: { accept: "image/avif,image/webp,image/png,image/jpeg,image/svg+xml,image/*" },
        });
        if (![301, 302, 303, 307, 308].includes(yanit.status)) break;
        const hedef = yanit.headers.get("location");
        await yanit.body?.cancel();
        if (!hedef) return { tamam: false, sebep: "acilmadi" };
        url = new URL(hedef, url);
      }
      if (!yanit || yanit.status >= 500) return { tamam: false, sebep: "erisilemedi" };
      if (yanit.status !== 200) return { tamam: false, sebep: "acilmadi" };
      const bildirilen = Number(yanit.headers.get("content-length") ?? 0);
      if (Number.isFinite(bildirilen) && bildirilen > MAX_PRODUCT_IMAGE_SOURCE_BYTES) {
        await yanit.body?.cancel();
        return { tamam: false, sebep: "cok-buyuk" };
      }
      const okuyucu = yanit.body?.getReader();
      if (!okuyucu) return { tamam: false, sebep: "acilmadi" };
      const parcalar: Uint8Array[] = [];
      let toplam = 0;
      for (;;) {
        const { value, done } = await okuyucu.read();
        if (done) break;
        toplam += value.byteLength;
        if (toplam > MAX_PRODUCT_IMAGE_SOURCE_BYTES) {
          await okuyucu.cancel();
          return { tamam: false, sebep: "cok-buyuk" };
        }
        parcalar.push(value);
      }
      bayt = new Uint8Array(Buffer.concat(parcalar));
    } catch {
      return { tamam: false, sebep: "erisilemedi" };
    }
  }
  if (bayt.byteLength > MAX_PRODUCT_IMAGE_SOURCE_BYTES) {
    return { tamam: false, sebep: "cok-buyuk" };
  }

  let tur: string;

  let genislik: number;
  let yukseklik: number;
  try {
    const goruntu = sharp(Buffer.from(bayt));
    const bilgi = await goruntu.metadata();
    const turler: Record<string, string> = { jpeg: "image/jpeg", png: "image/png", webp: "image/webp" };
    tur = turler[bilgi.format ?? ""];
    genislik = bilgi.width ?? 0;
    yukseklik = bilgi.height ?? 0;
    if (!tur) {
      const donusum = await goruntu.rotate().resize({
        width: UZUN_KENAR, height: UZUN_KENAR, fit: "inside", withoutEnlargement: true,
      }).webp().toBuffer({ resolveWithObject: true });
      bayt = new Uint8Array(donusum.data);
      genislik = donusum.info.width;
      yukseklik = donusum.info.height;
      tur = "image/webp";
    }
  } catch {
    return { tamam: false, sebep: "gorsel-degil" };
  }

  if (genislik <= 0 || yukseklik <= 0) return { tamam: false, sebep: "gorsel-degil" };

  return { tamam: true, genislik, yukseklik, tur, bayt };
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
