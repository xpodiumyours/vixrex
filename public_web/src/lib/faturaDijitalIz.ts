import { resolve4, resolve6 } from "node:dns/promises";
import { isIP } from "node:net";
import { createHash } from "node:crypto";
import sharp from "sharp";
import { FATURA_MIN_SOURCE_SHORT_EDGE } from "@/lib/productImagePolicy";
import type { FirmaSiteDurumu } from "@/lib/firmaSiteDurumu";
type IzinDurumu = "yok" | "bekliyor" | "var";

interface UreticiUrunu {
  kod: string;
  ad: string;
  marka: string;
  aciklama: string;
  barkod: string;
  gorseller: string[];
  kaynak: string;
  varyant?: string;
  modelAdi?: string;
}

export interface TedarikciDijitalIzi {
  anahtar: string | null;
  firma: string;
  alan: string;
  platform: string;
  izinDurumu: IzinDurumu;
  kaynak: string;
  havuzda: boolean;
  dogrulama?: {
    guc: "guclu" | "orta" | "zayif" | "dogrulanamadi" | "celisiyor";
    kanitlar: string[];
    bagliHesaplar: string[];
    katalogDosyalari: string[];
  };
}

export interface DijitalIzAramaDurumu {
  erisimHatasi: boolean;
  sinirDoldu: boolean;
  sonrakiSatir?: number;
  hatalar?: Record<string, string>;
  siteDurumu?: FirmaSiteDurumu;
  devam?: Record<string, { sonrakiSayfa: number; urunler: UreticiUrunu[] }>;
}

interface KesifBaglami {
  bitis: number;
  simdi: () => number;
  durum: DijitalIzAramaDurumu;
}

export interface DijitalIzBagimliliklari {
  fetcher?: (input: string, init?: RequestInit) => Promise<Response>;
  resolveHost?: (hostname: string) => Promise<string[]>;
}

const MAKS_YANIT_BAYT = 2 * 1024 * 1024;
const ISTEK_ZAMAN_ASIMI_MS = 2500;

function guvenliIpv4(ip: string): boolean {
  const parcalar = ip.split(".").map(Number);
  if (parcalar.length !== 4 || parcalar.some((parca) => !Number.isInteger(parca) || parca < 0 || parca > 255)) {
    return false;
  }
  const [a, b] = parcalar;
  if (a === 0 || a === 10 || a === 127 || a >= 224) return false;
  if (a === 100 && b >= 64 && b <= 127) return false;
  if (a === 169 && b === 254) return false;
  if (a === 172 && b >= 16 && b <= 31) return false;
  if (a === 192 && b === 168) return false;
  if (a === 198 && (b === 18 || b === 19)) return false;
  return true;
}

function guvenliIpv6(ip: string): boolean {
  const sade = ip.toLowerCase();
  if (sade === "::" || sade === "::1") return false;
  if (sade.startsWith("fc") || sade.startsWith("fd") || sade.startsWith("ff")) return false;
  if (/^fe[89ab]/.test(sade)) return false;
  if (sade.startsWith("::ffff:")) {
    const v4 = sade.slice("::ffff:".length);
    return isIP(v4) === 4 && guvenliIpv4(v4);
  }
  return true;
}

function guvenliIp(ip: string): boolean {
  const tur = isIP(ip);
  if (tur === 4) return guvenliIpv4(ip);
  if (tur === 6) return guvenliIpv6(ip);
  return false;
}

export async function varsayilanCoz(hostname: string): Promise<string[]> {
  const [v4, v6] = await Promise.allSettled([resolve4(hostname), resolve6(hostname)]);
  return [
    ...(v4.status === "fulfilled" ? v4.value : []),
    ...(v6.status === "fulfilled" ? v6.value : []),
  ];
}

export async function hostGuvenliMi(
  hostname: string,
  resolveHost: (hostname: string) => Promise<string[]>,
): Promise<boolean> {
  if (hostname === "localhost" || hostname.endsWith(".local")) return false;
  if (isIP(hostname)) return guvenliIp(hostname);
  const adresler = await resolveHost(hostname);
  return adresler.length > 0 && adresler.every(guvenliIp);
}

function sureVarMi(baglam: KesifBaglami | undefined): boolean {
  if (!baglam) return true;
  if (baglam.simdi() < baglam.bitis) return true;
  baglam.durum.sinirDoldu = true;
  return false;
}

function ayniSiteMi(a: string, b: string): boolean {
  const sade = (alan: string) => alan.toLowerCase().replace(/^www\./, "");
  return sade(a) === sade(b);
}

export async function hamGet(
  adres: string,
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
  baglam?: KesifBaglami,
  yonlendirmeHakki = 1,
): Promise<{ durum: number; govde: string; bayt: Uint8Array } | null> {
  if (!sureVarMi(baglam)) return null;
  let url: URL;
  try {
    url = new URL(adres);
  } catch {
    return null;
  }
  if (url.protocol !== "https:" || url.username || url.password || url.port) return null;
  if (!(await hostGuvenliMi(url.hostname, resolveHost))) {
    if (baglam) baglam.durum.erisimHatasi = true;
    return null;
  }

  let response: Response;
  try {
    response = await fetcher(url.toString(), {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(ISTEK_ZAMAN_ASIMI_MS),
      headers: { accept: "application/json, text/html, application/xml, text/xml, application/pdf" },
    });
  } catch {
    if (baglam) baglam.durum.erisimHatasi = true;
    return null;
  }

  if (response.status >= 300 && response.status < 400) {
    const yonlenen = response.headers.get("location");
    if (yonlendirmeHakki > 0 && yonlenen) {
      try {
        const hedef = new URL(yonlenen, url);
        if (hedef.protocol === "https:" && ayniSiteMi(hedef.hostname, url.hostname)) {
          return hamGet(hedef.toString(), fetcher, resolveHost, baglam, yonlendirmeHakki - 1);
        }
      } catch {
        if (baglam) baglam.durum.erisimHatasi = true;
        return null;
      }
    }
    if (baglam) baglam.durum.erisimHatasi = true;
    return null;
  }
  const sinir = /application\/pdf/i.test(response.headers.get("content-type") ?? "")
    ? 20 * 1024 * 1024 : MAKS_YANIT_BAYT;
  const uzunluk = Number(response.headers.get("content-length") ?? 0);
  if (Number.isFinite(uzunluk) && uzunluk > sinir) {
    await response.body?.cancel();
    if (baglam) baglam.durum.erisimHatasi = true;
    return null;
  }
  const okuyucu = response.body?.getReader();
  if (!okuyucu) return null;
  const parcalar: Uint8Array[] = [];
  let boyut = 0;
  try {
    for (;;) {
      const { done, value } = await okuyucu.read();
      if (done) break;
      boyut += value.byteLength;
      if (boyut > sinir) {
        await okuyucu.cancel();
        if (baglam) baglam.durum.erisimHatasi = true;
        return null;
      }
      parcalar.push(value);
    }
  } catch {
    if (baglam) baglam.durum.erisimHatasi = true;
    return null;
  } finally {
    okuyucu.releaseLock();
  }
  const bayt = new Uint8Array(Buffer.concat(parcalar));
  return { durum: response.status, govde: Buffer.from(bayt).toString("utf8"), bayt };
}

interface PdfResmi {
  data: Uint8Array;
  width: number;
  height: number;
  kind: number;
}

async function pdfyiAc(
  adres: string,
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
  baglam?: KesifBaglami,
) {
  const yanit = await hamGet(adres, fetcher, resolveHost, baglam);
  if (!yanit || yanit.durum !== 200 ||
    Buffer.from(yanit.bayt.subarray(0, 5)).toString("ascii") !== "%PDF-") {
    if (baglam) baglam.durum.erisimHatasi = true;
    return null;
  }
  const pdfjs = await import("pdfjs-dist/legacy/build/pdf.mjs");
  const yukleme = pdfjs.getDocument({
    data: yanit.bayt.slice(),
    useSystemFonts: false, disableFontFace: true,
  });
  try {
    const belge = await yukleme.promise;
    return { belge, yukleme, pdfjs, ozet: createHash("sha256").update(yanit.bayt).digest("hex") };
  } catch (hata) {
    await yukleme.destroy();
    throw hata;
  }
}

async function pdfResimleri(
  sayfa: import("pdfjs-dist/types/src/display/api").PDFPageProxy,
  imageOp: number,
): Promise<Array<{ indeks: number; resim: PdfResmi }>> {
  const ops = await sayfa.getOperatorList();
  const sonuc: Array<{ indeks: number; resim: PdfResmi }> = [];
  let indeks = 0;
  for (let i = 0; i < ops.fnArray.length; i++) {
    if (ops.fnArray[i] !== imageOp) continue;
    const kimlik = ops.argsArray[i][0] as string;
    const mevcut = indeks++;
    const resim = await new Promise<PdfResmi | null>((resolve) => {
      const timer = setTimeout(() => resolve(null), 2500);
      sayfa.objs.get(kimlik, (deger: PdfResmi) => {
        clearTimeout(timer);
        resolve(deger ?? null);
      });
    });
    if (!resim?.data || Math.min(resim.width, resim.height) < FATURA_MIN_SOURCE_SHORT_EDGE ||
      resim.width * resim.height > 12_000_000 || (resim.kind !== 2 && resim.kind !== 3)) continue;
    sonuc.push({ indeks: mevcut, resim });
  }
  return sonuc;
}

export async function pdfKatalogGorseliniOku(
  adres: string,
  bagimliliklar: Pick<DijitalIzBagimliliklari, "fetcher" | "resolveHost"> = {},
): Promise<Uint8Array | null> {
  let url: URL;
  try { url = new URL(adres); } catch { return null; }
  const p = new URLSearchParams(url.hash.slice(1));
  const no = Number(p.get("vixrex-page"));
  const indeks = Number(p.get("vixrex-image"));
  const ozet = p.get("vixrex-sha256") ?? "";
  if (!Number.isInteger(no) || no < 1 || !Number.isInteger(indeks) || indeks < 0 ||
    !/^[a-f0-9]{64}$/.test(ozet)) return null;
  url.hash = "";
  let acilan: Awaited<ReturnType<typeof pdfyiAc>> = null;
  try {
    acilan = await pdfyiAc(url.toString(), bagimliliklar.fetcher ?? fetch,
      bagimliliklar.resolveHost ?? varsayilanCoz);
    if (!acilan || acilan.ozet !== ozet || no > acilan.belge.numPages) return null;
    const sayfa = await acilan.belge.getPage(no);
    const resimler = await pdfResimleri(sayfa, acilan.pdfjs.OPS.paintImageXObject);
    const resim = resimler.find((r) => r.indeks === indeks)?.resim;
    if (!resim) return null;
    return new Uint8Array(await sharp(Buffer.from(resim.data), {
      raw: { width: resim.width, height: resim.height, channels: resim.kind === 3 ? 4 : 3 },
    }).png().toBuffer());
  } catch { return null; }
  finally { await acilan?.yukleme.destroy(); }
}
