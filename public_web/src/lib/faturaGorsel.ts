import { createHash } from "node:crypto";
import { lookup } from "node:dns/promises";
import { isIP } from "node:net";
import sharp from "sharp";

function yasakliIpv4OktetleriMi(a: number, b: number): boolean {
  if (a === 0 || a === 10 || a === 127) return true;
  if (a === 100 && b >= 64 && b <= 127) return true;
  if (a === 169 && b === 254) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a >= 224) return true;
  return false;
}

function ipv6Hektetleri(ip: string): number[] | null {
  const cift = ip.split("::");
  if (cift.length > 2) return null;
  const parcala = (bolum: string): number[] | null => {
    if (!bolum) return [];
    const parcalar = bolum.split(":");
    const sonuc: number[] = [];
    for (let i = 0; i < parcalar.length; i++) {
      const p = parcalar[i];
      if (p.includes(".")) {
        if (i !== parcalar.length - 1) return null;
        const oktetler = p.split(".").map(Number);
        if (oktetler.length !== 4 || oktetler.some((n) => !Number.isInteger(n) || n < 0 || n > 255)) return null;
        sonuc.push((oktetler[0] << 8) | oktetler[1], (oktetler[2] << 8) | oktetler[3]);
      } else {
        if (!/^[0-9a-f]{1,4}$/i.test(p)) return null;
        sonuc.push(Number.parseInt(p, 16));
      }
    }
    return sonuc;
  };
  const sol = parcala(cift[0]);
  if (!sol) return null;
  if (cift.length === 1) return sol.length === 8 ? sol : null;
  const sag = parcala(cift[1]);
  if (!sag || sol.length + sag.length > 8) return null;
  return [...sol, ...Array<number>(8 - sol.length - sag.length).fill(0), ...sag];
}

function yasakliIpv6Mi(ip: string): boolean {
  const h = ipv6Hektetleri(ip);
  if (!h) return true;
  const ilkBesSifir = h[0] === 0 && h[1] === 0 && h[2] === 0 && h[3] === 0 && h[4] === 0;
  if (ilkBesSifir && h[5] === 0 && h[6] === 0 && (h[7] === 0 || h[7] === 1)) return true;
  if (ilkBesSifir && h[5] === 0xffff) return true;
  if (ilkBesSifir && h[5] === 0) return yasakliIpv4OktetleriMi(h[6] >> 8, h[6] & 0xff);
  if ((h[0] & 0xfe00) === 0xfc00) return true;
  if ((h[0] & 0xffc0) === 0xfe80) return true;
  if ((h[0] & 0xff00) === 0xff00) return true;
  return false;
}

export function hostGuvenliMi(hostname: string): boolean {
  let temiz = hostname.trim().toLowerCase().replace(/^\[|\]$/g, "").replace(/\.$/, "");
  const yuzde = temiz.indexOf("%");
  if (yuzde !== -1) temiz = temiz.slice(0, yuzde);
  if (!temiz || temiz === "localhost" || temiz.endsWith(".local") || temiz.endsWith(".internal")) return false;
  if (/^\d+$/.test(temiz)) return false;
  if (temiz.includes(":")) return !yasakliIpv6Mi(temiz);
  if (isIP(temiz) === 4) {
    const oktetler = temiz.split(".").map(Number);
    return !yasakliIpv4OktetleriMi(oktetler[0], oktetler[1]);
  }
  return true;
}

async function varsayilanResolveHost(hostname: string): Promise<string[]> {
  const sonuclar = await lookup(hostname, { all: true });
  return sonuclar.map((kayit) => kayit.address);
}

async function hostCozumlenipGuvenliMi(
  hostname: string,
  resolveHost?: (hostname: string) => Promise<string[]>,
): Promise<boolean> {
  if (!hostGuvenliMi(hostname)) return false;
  const temiz = hostname.trim().toLowerCase().replace(/^\[|\]$/g, "").replace(/\.$/, "");
  if (isIP(temiz) !== 0) return true;
  if (!resolveHost) return true;
  let ipler: string[];
  try {
    ipler = await resolveHost(temiz);
  } catch {
    return false;
  }
  if (!Array.isArray(ipler) || ipler.length === 0) return false;
  return ipler.every(
    (ip) => typeof ip === "string" && isIP(ip.trim().replace(/^\[|\]$/g, "")) !== 0 && hostGuvenliMi(ip),
  );
}
import { gorseliSikistir, ONBELLEK_SANIYE, UZUN_KENAR } from "@/lib/gorselSikistir";
import { gorselDepoyaYukle, type DepoIstemcisi } from "@/lib/gorselDepo";
import {
  MAX_PRODUCT_IMAGE_SOURCE_BYTES,
} from "@/lib/productImagePolicy";
import type { GoruSatiri } from "@/lib/faturaGoru";

export type GorselRedSebebi =
  | "erisilemedi"
  | "acilmadi"
  | "gorsel-degil"
  | "cok-buyuk"
  | "cok-kucuk"
  | "logo-veya-yer-tutucu"
  | "bos"
  | "urun-fotografi-degil"
  | "kaynak-uyumsuz";

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

function cozumleyiciSec(
  bagimliliklar?: GorselBagimliliklari,
): ((hostname: string) => Promise<string[]>) | undefined {
  if (bagimliliklar?.resolveHost) return bagimliliklar.resolveHost;
  if (bagimliliklar?.fetcher) return undefined;
  if (typeof (globalThis.fetch as { mock?: unknown })?.mock === "object") return undefined;
  return varsayilanResolveHost;
}

async function govdeyiSinirlaOku(
  yanit: Response,
  sinir: number,
): Promise<{ durum: "ok"; bayt: Uint8Array } | { durum: "cok-buyuk" | "bos" }> {
  const bildirilen = Number(yanit.headers.get("content-length") ?? 0);
  if (Number.isFinite(bildirilen) && bildirilen > sinir) {
    await yanit.body?.cancel();
    return { durum: "cok-buyuk" };
  }
  const okuyucu = yanit.body?.getReader();
  if (!okuyucu) return { durum: "bos" };
  const parcalar: Uint8Array[] = [];
  let toplam = 0;
  for (;;) {
    const { value, done } = await okuyucu.read();
    if (done) break;
    if (!value) continue;
    toplam += value.byteLength;
    if (toplam > sinir) {
      await okuyucu.cancel();
      return { durum: "cok-buyuk" };
    }
    parcalar.push(value);
  }
  return { durum: "ok", bayt: new Uint8Array(Buffer.concat(parcalar)) };
}

export async function kaynakGorseliniDogrula(
  adres: string,
  bagimliliklar: GorselBagimliliklari = {},
): Promise<KaynakGorselDogrulamasi> {
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = cozumleyiciSec(bagimliliklar);

  let url: URL;
  try {
    url = new URL(adres);
  } catch {
    return { tamam: false, sebep: "acilmadi" };
  }
  if (url.protocol !== "https:" || url.username || url.password || url.port) {
    return { tamam: false, sebep: "acilmadi" };
  }
  if (!(await hostCozumlenipGuvenliMi(url.hostname, resolveHost))) {
    return { tamam: false, sebep: "erisilemedi" };
  }

  let bayt: Uint8Array;
    let yanit: Response | null = null;
    const gorulenler = new Set<string>();
    const signal = AbortSignal.timeout(ZAMAN_ASIMI_MS);
    try {
      for (let adim = 0; adim <= 5; adim++) {
        if (url.protocol !== "https:" || url.username || url.password || url.port || gorulenler.has(url.href)) {
          return { tamam: false, sebep: "acilmadi" };
        }
        if (!(await hostCozumlenipGuvenliMi(url.hostname, resolveHost))) {
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
      const okunan = await govdeyiSinirlaOku(yanit, MAX_PRODUCT_IMAGE_SOURCE_BYTES);
      if (okunan.durum === "cok-buyuk") return { tamam: false, sebep: "cok-buyuk" };
      if (okunan.durum !== "ok") return { tamam: false, sebep: "acilmadi" };
      bayt = okunan.bayt;
    } catch {
      return { tamam: false, sebep: "erisilemedi" };
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

function alanAdiUyuyorMu(hostname: string, izinli: string[]): boolean {
  const host = hostname.toLowerCase();
  return izinli.some((alan) => host === alan || host.endsWith(`.${alan}`));
}

export async function kaynakGorselleriniHazirla(args: {
  admin: DepoIstemcisi;
  slug: string;
  kaynakSayfa: string;
  adaylar: string[];
  sonTarih?: number;
  izinliAlanAdlari?: string[];
  bagimliliklar?: GorselBagimliliklari;
}): Promise<GorselHazirlamaSonucu> {
  const gorseller: HazirlananGorsel[] = [];
  const reddedilenler: ReddedilenGorsel[] = [];
  let altyapiSorunu = false;
  const guvenliSlug = args.slug.replace(/[^a-zA-Z0-9-]/g, "");

  for (const aday of [...new Set(args.adaylar)]) {
    if (args.sonTarih !== undefined && Date.now() + ZAMAN_ASIMI_MS >= args.sonTarih) {
      altyapiSorunu = true;
      reddedilenler.push({ kaynakGorsel: aday, sebep: "erisilemedi" });
      continue;
    }
    const izinli = (args.izinliAlanAdlari ?? [])
      .map((alan) => alan.trim().toLowerCase().replace(/^www\./, ""))
      .filter(Boolean);
    if (izinli.length > 0) {
      let adayHost = "";
      try { adayHost = new URL(aday).hostname.toLowerCase().replace(/^www\./, ""); } catch { adayHost = ""; }
      if (!adayHost || !alanAdiUyuyorMu(adayHost, izinli)) {
        reddedilenler.push({ kaynakGorsel: aday, sebep: "kaynak-uyumsuz" });
        continue;
      }
    }
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
      const url = await gorselDepoyaYukle({
        admin: args.admin,
        yol,
        bayt: sikistirilmis.bayt,
        contentType: sikistirilmis.tur,
        cacheControl: ONBELLEK_SANIYE,
        upsert: true,
      });
      gorseller.push({
        url,
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

const SAYFA_BAYIT_SINIRI = 3_000_000;

function mutlakGorselAdresi(adres: string, sayfa: string): string {
  try {
    const url = new URL(adres.trim(), sayfa);
    if (!["https:", "http:"].includes(url.protocol) || url.username || url.password) return "";
    return url.toString();
  } catch {
    return "";
  }
}

export function sayfaGorselAyikla(html: string, sayfa: string): string[] {
  const bulunan: string[] = [];
  for (const etiket of html.match(/<meta\b[^>]*>/gi) ?? []) {
    const ozellik = /\s(?:property|name)\s*=\s*["']([^"']+)["']/i.exec(etiket);
    if (!ozellik) continue;
    const ad = ozellik[1].toLowerCase();
    if (!["og:image", "og:image:url", "og:image:secure_url", "twitter:image", "twitter:image:src"].includes(ad)) continue;
    const icerik = /\scontent\s*=\s*["']([^"']+)["']/i.exec(etiket);
    if (!icerik) continue;
    const mutlak = mutlakGorselAdresi(icerik[1], sayfa);
    if (mutlak && !bulunan.includes(mutlak)) bulunan.push(mutlak);
  }
  return bulunan;
}

async function sayfadanGorselleriAl(
  sayfa: string,
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost?: (hostname: string) => Promise<string[]>,
): Promise<string[]> {
  let url: URL;
  try {
    url = new URL(sayfa);
  } catch {
    return [];
  }
  const gorulenler = new Set<string>();
  const signal = AbortSignal.timeout(ZAMAN_ASIMI_MS);
  try {
    for (let adim = 0; adim <= 5; adim++) {
      if (url.protocol !== "https:" || url.username || url.password || url.port || gorulenler.has(url.href)) return [];
      if (!(await hostCozumlenipGuvenliMi(url.hostname, resolveHost))) return [];
      gorulenler.add(url.href);
      const yanit = await fetcher(url.toString(), {
        method: "GET",
        redirect: "manual",
        signal,
        headers: { accept: "text/html,application/xhtml+xml" },
      });
      if ([301, 302, 303, 307, 308].includes(yanit.status)) {
        const hedef = yanit.headers.get("location");
        await yanit.body?.cancel();
        if (!hedef) return [];
        url = new URL(hedef, url);
        continue;
      }
      if (yanit.status !== 200) {
        await yanit.body?.cancel();
        return [];
      }
      const okunan = await govdeyiSinirlaOku(yanit, SAYFA_BAYIT_SINIRI);
      if (okunan.durum !== "ok") return [];
      const html = new TextDecoder("utf-8", { fatal: false }).decode(okunan.bayt);
      return sayfaGorselAyikla(html, url.href);
    }
  } catch {
    return [];
  }
  return [];
}

export async function sayfaGorselAlanAdlari(
  sayfa: string,
  fetcher: (input: string, init?: RequestInit) => Promise<Response> = fetch,
  resolveHost?: (hostname: string) => Promise<string[]>,
): Promise<string[]> {
  let girisUrl: URL;
  try {
    girisUrl = new URL(sayfa);
  } catch {
    return [];
  }
  if (girisUrl.protocol !== "https:" || girisUrl.username || girisUrl.password || girisUrl.port) {
    return [];
  }
  const cozumleyici =
    resolveHost ??
    (fetcher === fetch && typeof (globalThis.fetch as { mock?: unknown })?.mock !== "object"
      ? varsayilanResolveHost
      : undefined);
  if (!(await hostCozumlenipGuvenliMi(girisUrl.hostname, cozumleyici))) {
    return [];
  }
  const alanlar = new Set<string>([girisUrl.hostname.toLowerCase().replace(/^www\./, "")]);
  for (const adres of await sayfadanGorselleriAl(sayfa, fetcher, cozumleyici)) {
    try { alanlar.add(new URL(adres).hostname.toLowerCase().replace(/^www\./, "")); }
    catch { continue; }
  }
  return [...alanlar];
}

export async function gorselsizSatirlariTamamla(args: {
  satirlar: GoruSatiri[];
  bagimliliklar?: GorselBagimliliklari;
}): Promise<GoruSatiri[]> {
  const fetcher = args.bagimliliklar?.fetcher ?? fetch;
  const resolveHost = cozumleyiciSec(args.bagimliliklar);
  const onbellek = new Map<string, string[]>();
  const sonuc: GoruSatiri[] = [];
  for (const satir of args.satirlar) {
    const mevcut = (satir.siteGorseller ?? []).concat(satir.siteGorsel ? [satir.siteGorsel] : []);
    const sayfa = (satir.siteSayfa ?? "").trim();
    const kimlikVar = satir.dogrulamaDurumu === "Doğrulandı" || satir.dogrulamaDurumu === "Belirsiz";
    if (mevcut.length > 0 || !sayfa || !kimlikVar) {
      sonuc.push(satir);
      continue;
    }
    let adaylar = onbellek.get(sayfa);
    if (!adaylar) {
      adaylar = await sayfadanGorselleriAl(sayfa, fetcher, resolveHost);
      onbellek.set(sayfa, adaylar);
    }
    sonuc.push(adaylar.length > 0 ? { ...satir, siteGorsel: adaylar[0], siteGorseller: [...adaylar] } : satir);
  }
  return sonuc;
}
