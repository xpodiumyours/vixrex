import { resolve4, resolve6 } from "node:dns/promises";
import { isIP } from "node:net";
import { createHash } from "node:crypto";
import sharp from "sharp";
import { FATURA_MIN_SOURCE_SHORT_EDGE } from "@/lib/productImagePolicy";
import {
  firmaHavuzKaydiniBul,
  gorselKapisi,
  type IzinDurumu,
  type UreticiUrunu,
} from "@/lib/ureticiKatalog";

export interface TedarikciDijitalIzi {
  anahtar: string | null;
  firma: string;
  alan: string;
  platform: string;
  izinDurumu: IzinDurumu;
  kaynak: string;
  havuzda: boolean;
  dogrulama?: import("@/lib/firmaDogrula").FirmaDogrulamasi;
}

export interface DijitalIzSatiri {
  model: string;
  barkod: string;
  marka?: string;
  varyant?: string;
  beden?: string;
}

export interface DijitalUrunEslesmesi {
  urun: UreticiUrunu;
  dayanak: "kod" | "barkod";
  gorselAdaylari: string[];
}

export interface DijitalIzCeliskisi {
  celiski: true;
  dayanak: "kod" | "barkod";
  adaylar: Array<{ ad: string; kaynak: string }>;
}

export type DijitalIzHedefi = DijitalUrunEslesmesi | DijitalIzCeliskisi;

export interface DijitalIzAramaDurumu {
  erisimHatasi: boolean;
  sinirDoldu: boolean;
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
  durum?: DijitalIzAramaDurumu;
  tedarikciKimligi?: { vergiNo: string; adres: string };
  simdi?: () => number;
  kesifButcesiMs?: number;
  /** Firma resmi site araması (Brave). Verilmezse ortam anahtarı kullanılır. */
  firmaArama?: import("@/lib/firmaArama").FirmaAramaBagimliliklari;
}

const MAKS_YANIT_BAYT = 2 * 1024 * 1024;
const MAKS_SAYFA = 8;
const MAKS_SAYFA_OKUMA = 12;
const MAKS_ALT_HARITA = 6;
const MAKS_ARAMA_ADAYI = 5;
const KESIF_BUTCESI_MS = 20000;
const ISTEK_ZAMAN_ASIMI_MS = 2500;

function alanAdiTemizle(deger: string): string {
  const ham = deger.trim();
  if (!ham) return "";
  try {
    const url = new URL(ham.includes("://") ? ham : `https://${ham}`);
    return url.hostname.toLowerCase().replace(/^www\./, "").replace(/\.$/, "");
  } catch {
    return "";
  }
}

function normalizeKod(value: string): string {
  return value.trim().toUpperCase().replace(/[\s._\-/]/g, "");
}

function normalizeBarkod(value: string): string {
  return value.replace(/\D/g, "");
}

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

async function jsonGet(
  adres: string,
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
  baglam?: KesifBaglami,
): Promise<{ durum: number; veri: unknown } | null> {
  const ham = await hamGet(adres, fetcher, resolveHost, baglam);
  if (!ham) return null;

  try {
    return { durum: ham.durum, veri: JSON.parse(ham.govde) };
  } catch {
    return { durum: ham.durum, veri: null };
  }
}

function shopifyUrunleri(veri: unknown, alan: string): UreticiUrunu[] {
  const govde = veri as { products?: unknown[] };
  if (!Array.isArray(govde?.products)) return [];
  const sonuc: UreticiUrunu[] = [];

  for (const hamDeger of govde.products) {
    const ham = (hamDeger ?? {}) as Record<string, unknown>;
    const ad = String(ham.title ?? "");
    const marka = String(ham.vendor ?? "");
    const aciklama = String(ham.body_html ?? "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
    const gorseller = (Array.isArray(ham.images) ? ham.images : [])
      .map((gorsel) => {
        if (typeof gorsel === "string") return gorsel;
        return String((gorsel as Record<string, unknown>)?.src ?? "");
      })
      .filter(Boolean);
    const kaynak = ham.handle ? `https://${alan}/products/${String(ham.handle)}` : `https://${alan}`;
    const varyantlar = Array.isArray(ham.variants) ? ham.variants : [];

    for (const varyantDeger of varyantlar) {
      const varyant = (varyantDeger ?? {}) as Record<string, unknown>;
      const kod = String(varyant.sku ?? "").trim();
      if (!kod) continue;
      const baslik = String(varyant.title ?? "");
      sonuc.push({
        kod,
        ad: baslik && baslik !== "Default Title" ? `${ad} — ${baslik}` : ad,
        marka,
        aciklama,
        barkod: String(varyant.barcode ?? "").trim(),
        varyant: baslik === "Default Title" ? "" : baslik,
        gorseller: typeof varyant.featured_image === "object" && varyant.featured_image
          ? [String((varyant.featured_image as Record<string, unknown>).src ?? "")].filter(Boolean)
          : gorseller,
        kaynak,
      });
    }
  }

  return sonuc;
}

function wooUrunleri(veri: unknown, alan: string): UreticiUrunu[] {
  if (!Array.isArray(veri)) return [];
  return veri
    .map((hamDeger) => {
      const ham = (hamDeger ?? {}) as Record<string, unknown>;
      const kod = String(ham.sku ?? "").trim();
      if (!kod) return null;
      const markalar = Array.isArray(ham.brands)
        ? ham.brands
            .map((marka) => String((marka as Record<string, unknown>)?.name ?? ""))
            .filter(Boolean)
            .join(", ")
        : "";
      const gorseller = (Array.isArray(ham.images) ? ham.images : [])
        .map((gorsel) => String((gorsel as Record<string, unknown>)?.src ?? ""))
        .filter(Boolean);
      const aciklama = String(ham.short_description || ham.description || "")
        .replace(/<[^>]+>/g, " ")
        .replace(/\s+/g, " ")
        .trim();
      return {
        kod,
        ad: String(ham.name ?? ""),
        marka: markalar,
        aciklama,
        barkod: "",
        gorseller,
        kaynak: String(ham.permalink ?? "") || `https://${alan}`,
      } satisfies UreticiUrunu;
    })
    .filter((urun): urun is UreticiUrunu => urun !== null);
}

function urunKimligi(urun: UreticiUrunu): string {
  return `${urun.kaynak?.trim() || urun.ad}|${urun.varyant ?? ""}`;
}

function hedefBul(
  urunler: UreticiUrunu[],
  satirlar: DijitalIzSatiri[],
  izinDurumu: IzinDurumu,
): Array<DijitalIzHedefi | null> {
  const koda = new Map<string, UreticiUrunu[]>();
  const barkoda = new Map<string, UreticiUrunu[]>();
  const yaz = (harita: Map<string, UreticiUrunu[]>, anahtar: string, urun: UreticiUrunu) => {
    if (!anahtar) return;
    const liste = harita.get(anahtar) ?? [];
    if (!liste.some((mevcut) => urunKimligi(mevcut) === urunKimligi(urun))) liste.push(urun);
    harita.set(anahtar, liste);
  };

  for (const urun of urunler) {
    yaz(koda, normalizeKod(urun.kod), urun);
    const barkod = normalizeBarkod(urun.barkod);
    if (barkod.length >= 8) yaz(barkoda, barkod, urun);
  }

  const karar = (tumAdaylar: UreticiUrunu[], dayanak: "kod" | "barkod", satir: DijitalIzSatiri): DijitalIzHedefi | null => {
    const marka = (satir.marka ?? "").trim().toLocaleLowerCase("tr-TR");
    const secenekler = [satir.varyant, satir.beden].filter(Boolean)
      .flatMap((s) => s!.split(/[\/|,;]+/)).map(normalizeKod).filter(Boolean);
    const adaylar = tumAdaylar.filter((urun) => {
      if (marka && urun.marka && urun.marka.trim().toLocaleLowerCase("tr-TR") !== marka) return false;
      const kaynakSecenekleri = (urun.varyant ?? "").split(/[\/|,;]+/).map(normalizeKod).filter(Boolean);
      if (secenekler.length > 0 && secenekler.some((secenek) => !kaynakSecenekleri.includes(secenek))) return false;
      return true;
    });
    if (adaylar.length === 0) return null;
    const kimlikler = [...new Set(adaylar.map(urunKimligi))];
    if (kimlikler.length > 1) {
      return {
        celiski: true,
        dayanak,
        adaylar: kimlikler.map((kimlik) => {
          const urun = adaylar.find((aday) => urunKimligi(aday) === kimlik) as UreticiUrunu;
          return { ad: urun.ad, kaynak: urun.kaynak };
        }),
      };
    }
    const urun = adaylar[0];
    return {
      urun: gorselKapisi(urun, izinDurumu),
      dayanak,
      gorselAdaylari: urun.gorseller ?? [],
    };
  };

  return satirlar.map((satir) => {
    const barkod = normalizeBarkod(satir.barkod);
    if (barkod.length >= 8) {
      const sonuc = karar(barkoda.get(barkod) ?? [], "barkod", satir);
      if (sonuc) return sonuc;
    }

    const model = normalizeKod(satir.model);
    if (model.length >= 4) {
      const sonuc = karar(koda.get(model) ?? [], "kod", satir);
      if (sonuc) return sonuc;
    }

    return null;
  });
}

function eslesmeyenIndeksler(bulunan: Array<DijitalIzHedefi | null>): number[] {
  return bulunan.map((hedef, indeks) => (hedef === null ? indeks : -1)).filter((indeks) => indeks >= 0);
}

function aramaKodu(satir: DijitalIzSatiri): string {
  const barkod = normalizeBarkod(satir.barkod);
  if (barkod.length >= 8) return barkod;
  const model = satir.model.trim();
  return normalizeKod(model).length >= 4 ? model : "";
}

async function shopifyAra(
  iz: TedarikciDijitalIzi,
  satirlar: DijitalIzSatiri[],
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
  baglam: KesifBaglami,
): Promise<Array<DijitalIzHedefi | null>> {
  const anahtar = `shopify:${iz.alan}`;
  const devam = (baglam.durum.devam ??= {});
  const kayit = devam[anahtar] ??= { sonrakiSayfa: 1, urunler: [] };
  const urunler = kayit.urunler;
  const baslangic = kayit.sonrakiSayfa;
  for (let sayfa = baslangic; sayfa < baslangic + MAKS_SAYFA; sayfa++) {
    const sonuc = await jsonGet(
      `https://${iz.alan}/products.json?limit=250&page=${sayfa}`,
      fetcher,
      resolveHost,
      baglam,
    );
    if (!sonuc || sonuc.durum !== 200) break;
    const yeni = shopifyUrunleri(sonuc.veri, iz.alan);
    if (yeni.length === 0) break;
    urunler.push(...yeni);
    kayit.sonrakiSayfa = sayfa + 1;
    const bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
    if (bulunan.every((eslesme) => eslesme !== null)) return bulunan;
  }

  let bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
  for (const indeks of eslesmeyenIndeksler(bulunan)) {
    const kod = aramaKodu(satirlar[indeks]);
    if (!kod) continue;
    const oneri = await jsonGet(
      `https://${iz.alan}/search/suggest.json?q=${encodeURIComponent(kod)}&resources[type]=product&resources[limit]=${MAKS_ARAMA_ADAYI}`,
      fetcher,
      resolveHost,
      baglam,
    );
    if (!oneri || oneri.durum !== 200) continue;
    const sonuclar = (
      oneri.veri as { resources?: { results?: { products?: Array<{ handle?: unknown }> } } }
    )?.resources?.results?.products;
    if (!Array.isArray(sonuclar)) continue;
    for (const aday of sonuclar.slice(0, MAKS_ARAMA_ADAYI)) {
      const handle = typeof aday?.handle === "string" ? aday.handle : "";
      if (!handle) continue;
      const detay = await jsonGet(
        `https://${iz.alan}/products/${encodeURIComponent(handle)}.json`,
        fetcher,
        resolveHost,
        baglam,
      );
      if (!detay || detay.durum !== 200) continue;
      const urun = (detay.veri as { product?: unknown })?.product;
      if (!urun) continue;
      urunler.push(...shopifyUrunleri({ products: [urun] }, iz.alan));
    }
    bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
  }
  return bulunan;
}

async function wooAra(
  iz: TedarikciDijitalIzi,
  satirlar: DijitalIzSatiri[],
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
  baglam: KesifBaglami,
): Promise<Array<DijitalIzHedefi | null>> {
  const anahtar = `woocommerce:${iz.alan}`;
  const devam = (baglam.durum.devam ??= {});
  const kayit = devam[anahtar] ??= { sonrakiSayfa: 1, urunler: [] };
  const urunler = kayit.urunler;
  const baslangic = kayit.sonrakiSayfa;
  for (let sayfa = baslangic; sayfa < baslangic + MAKS_SAYFA; sayfa++) {
    const sonuc = await jsonGet(
      `https://${iz.alan}/wp-json/wc/store/v1/products?per_page=100&page=${sayfa}`,
      fetcher,
      resolveHost,
      baglam,
    );
    if (!sonuc || sonuc.durum !== 200) break;
    const yeni = wooUrunleri(sonuc.veri, iz.alan);
    if (yeni.length === 0) break;
    urunler.push(...yeni);
    kayit.sonrakiSayfa = sayfa + 1;
    const bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
    if (bulunan.every((eslesme) => eslesme !== null)) return bulunan;
  }

  let bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
  for (const indeks of eslesmeyenIndeksler(bulunan)) {
    const kod = aramaKodu(satirlar[indeks]);
    if (!kod) continue;
    for (const parametre of ["sku", "search"]) {
      const sonuc = await jsonGet(
        `https://${iz.alan}/wp-json/wc/store/v1/products?${parametre}=${encodeURIComponent(kod)}&per_page=${MAKS_ARAMA_ADAYI * 4}`,
        fetcher,
        resolveHost,
        baglam,
      );
      if (!sonuc || sonuc.durum !== 200) continue;
      urunler.push(...wooUrunleri(sonuc.veri, iz.alan));
      bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
      if (bulunan[indeks] !== null) break;
    }
  }
  return bulunan;
}

function xmlLocBul(metin: string): string[] {
  const loclar: string[] = [];
  const desen = /<loc>\s*([^<]+)\s*<\/loc>/gi;
  let eslesme: RegExpExecArray | null;
  while ((eslesme = desen.exec(metin)) !== null) loclar.push(eslesme[1].trim());
  return loclar;
}

function jsonLdUrunleri(html: string, sayfaAdresi: string): UreticiUrunu[] {
  const parcalar: unknown[] = [];
  const desen = /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let eslesme: RegExpExecArray | null;
  while ((eslesme = desen.exec(html)) !== null) {
    try {
      parcalar.push(JSON.parse(eslesme[1]));
    } catch {
      continue;
    }
  }

  const nesneler: Array<Record<string, unknown>> = [];
  const tara = (deger: unknown) => {
    if (Array.isArray(deger)) {
      for (const og of deger) tara(og);
      return;
    }
    if (!deger || typeof deger !== "object") return;
    const nesne = deger as Record<string, unknown>;
    if (Array.isArray(nesne["@graph"])) tara(nesne["@graph"]);
    if (nesne.itemListElement) tara(nesne.itemListElement);
    if (nesne.item) tara(nesne.item);
    if (nesne.hasVariant) tara(nesne.hasVariant);
    nesneler.push(nesne);
  };
  for (const parca of parcalar) tara(parca);

  const sonuc: UreticiUrunu[] = [];
  for (const nesne of nesneler) {
    const hamTur = nesne["@type"];
    const tipler = Array.isArray(hamTur) ? hamTur.map(String) : [String(hamTur ?? "")];
    if (!tipler.includes("Product")) continue;

    const ad = String(nesne.name ?? "").trim();
    const kod = String(nesne.sku ?? nesne.mpn ?? "").trim();
    const barkod = String(nesne.gtin13 ?? nesne.gtin12 ?? nesne.gtin ?? "").trim();
    if (!ad && !kod && !barkod) continue;

    const hamMarka = nesne.brand;
    const marka =
      typeof hamMarka === "string"
        ? hamMarka.trim()
        : String((hamMarka as Record<string, unknown> | null)?.name ?? "").trim();

    const hamGorsel = nesne.image;
    const gorseller = (Array.isArray(hamGorsel) ? hamGorsel : [hamGorsel])
      .map((gorsel) =>
        typeof gorsel === "string"
          ? gorsel
          : String((gorsel as Record<string, unknown> | null)?.url ?? ""),
      )
      .filter((gorsel) => gorsel.startsWith("http"));

    const aciklama = String(nesne.description ?? "")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    const adres = String(nesne.url ?? "").trim();

    sonuc.push({
      kod: kod || barkod,
      ad,
      marka,
      aciklama,
      barkod,
      varyant: [
        typeof nesne.color === "string" ? nesne.color : "",
        typeof nesne.size === "string" || typeof nesne.size === "number"
          ? String(nesne.size) : String((nesne.size as Record<string, unknown> | null)?.name ?? ""),
      ].filter(Boolean).join(" / "),
      gorseller,
      kaynak: adres.startsWith("http") ? adres : sayfaAdresi,
    });
  }

  return sonuc;
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

async function resmiKataloglariAra(
  iz: TedarikciDijitalIzi,
  satirlar: DijitalIzSatiri[],
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
  baglam: KesifBaglami,
): Promise<Array<DijitalIzHedefi | null>> {
  let dogrulama = iz.dogrulama;
  if (!dogrulama && iz.havuzda && sureVarMi(baglam)) {
    const { siteFirmayaAitMi } = await import("@/lib/firmaDogrula");
    const aday = await siteFirmayaAitMi(iz.alan,
      { ad: iz.firma, vergiNo: "", adres: "" }, { fetcher, resolveHost });
    if (aday.guc === "guclu" || aday.guc === "orta") dogrulama = aday;
  }
  const urunler: UreticiUrunu[] = [];
  const pdfler = new Set(dogrulama?.katalogDosyalari ?? []);
  for (const hesap of dogrulama?.bagliHesaplar ?? []) {
    if (!sureVarMi(baglam)) break;
    const sayfa = await hamGet(hesap, fetcher, resolveHost, baglam);
    if (!sayfa || sayfa.durum !== 200) {
      baglam.durum.erisimHatasi = true;
      continue;
    }
    const bulunan = jsonLdUrunleri(sayfa.govde, hesap);
    urunler.push(...bulunan);
    const hrefler = /href\s*=\s*["']([^"']+)["']/gi;
    let link: RegExpExecArray | null;
    let pdfVar = false;
    while ((link = hrefler.exec(sayfa.govde)) !== null) {
      try {
        const aday = new URL(link[1].replace(/&amp;/g, "&"), hesap);
        if (aday.protocol === "https:" && /\.pdf$/i.test(aday.pathname) &&
          (ayniSiteMi(aday.hostname, iz.alan) || ayniSiteMi(aday.hostname, new URL(hesap).hostname))) {
          pdfler.add(aday.toString());
          pdfVar = true;
        }
      } catch { continue; }
    }
    if (bulunan.length === 0 && !pdfVar) baglam.durum.erisimHatasi = true;
  }
  for (const adres of pdfler) {
    if (!sureVarMi(baglam)) break;
    let acilan: Awaited<ReturnType<typeof pdfyiAc>> = null;
    try {
      acilan = await pdfyiAc(adres, fetcher, resolveHost, baglam);
      if (!acilan) continue;
      const devam = (baglam.durum.devam ??= {});
      const hedefKimligi = createHash("sha256").update(JSON.stringify(
        satirlar.map((s) => [s.model, s.barkod, s.marka ?? "", s.varyant ?? "", s.beden ?? ""])
          .sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b))),
      )).digest("hex").slice(0, 24);
      const kayit = devam[`pdf:${adres}:${acilan.ozet}:${hedefKimligi}`] ??=
        { sonrakiSayfa: 1, urunler: [] };
      const bitis = Math.min(acilan.belge.numPages, kayit.sonrakiSayfa + MAKS_SAYFA_OKUMA - 1);
      for (let no = kayit.sonrakiSayfa; no <= bitis; no++) {
        if (!sureVarMi(baglam)) break;
        const sayfa = await acilan.belge.getPage(no);
        const icerik = await sayfa.getTextContent();
        const metin = icerik.items.flatMap((item) => "str" in item ? [item.str] : []).join(" ");
        const kodlar = [...new Set([...metin.matchAll(
          /(?:model|sku|ürün\s*kodu|urun\s*kodu|kod)\s*[:#-]?\s*([A-Z0-9][A-Z0-9._/-]{3,})/gi,
        )].map((m) => normalizeKod(m[1])))];
        const barkodlar = [...new Set([...metin.matchAll(
          /(?:gtin|ean|barkod)\s*[:#-]?\s*(\d{8,14})(?!\d)/gi,
        )].map((m) => m[1]).filter((b) => [8, 12, 13, 14].includes(b.length)))];
        const hedefler = satirlar.filter((s) =>
          (s.model && kodlar.includes(normalizeKod(s.model))) ||
          (s.barkod && barkodlar.includes(normalizeBarkod(s.barkod))));
        const resimler = await pdfResimleri(sayfa, acilan.pdfjs.OPS.paintImageXObject);
        if (kodlar.length <= 1 && barkodlar.length <= 1 && kodlar.length + barkodlar.length > 0 &&
          hedefler.length > 0 && resimler.length === 1) {
          const kaynak = new URL(adres);
          kaynak.hash = `page=${no}`;
          const gorsel = new URL(adres);
          gorsel.hash = new URLSearchParams({
            "vixrex-page": String(no), "vixrex-image": String(resimler[0].indeks),
            "vixrex-sha256": acilan.ozet,
          }).toString();
          const urun: UreticiUrunu = {
            kod: kodlar[0] ?? "", barkod: barkodlar[0] ?? "",
            ad: metin.trim(), aciklama: metin.trim(), marka: "",
            gorseller: [gorsel.toString()], kaynak: kaynak.toString(),
          };
          kayit.urunler.push(urun);
        }
        kayit.sonrakiSayfa = no + 1;
        sayfa.cleanup();
      }
      if (kayit.sonrakiSayfa <= acilan.belge.numPages) {
        baglam.durum.sinirDoldu = true;
      } else {
        urunler.push(...kayit.urunler);
      }
    } catch { baglam.durum.erisimHatasi = true; }
    finally { await acilan?.yukleme.destroy(); }
  }
  return hedefBul(urunler, satirlar, iz.izinDurumu);
}

function slugKodu(loc: string): string {
  try {
    return new URL(loc).pathname.toUpperCase().replace(/[^A-Z0-9]/g, "");
  } catch {
    return "";
  }
}

async function sayfaAra(
  iz: TedarikciDijitalIzi,
  satirlar: DijitalIzSatiri[],
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
  baglam: KesifBaglami,
): Promise<Array<DijitalIzHedefi | null>> {
  const bos = () => satirlar.map(() => null);

  const kok = await hamGet(`https://${iz.alan}/sitemap.xml`, fetcher, resolveHost, baglam);
  if (!kok || kok.durum !== 200) return bos();

  let loclar = xmlLocBul(kok.govde);
  if (/<sitemapindex/i.test(kok.govde)) {
    const altHaritalar = loclar.filter((loc) => loc.startsWith("https://"));
    const urunHaritalari = altHaritalar.filter((loc) => /product|urun|shop|magaza/i.test(slugAdi(loc)));
    const okunacak = (urunHaritalari.length > 0 ? urunHaritalari : altHaritalar).slice(0, MAKS_ALT_HARITA);
    loclar = [];
    for (const adres of okunacak) {
      const alt = await hamGet(adres, fetcher, resolveHost, baglam);
      if (!alt || alt.durum !== 200) continue;
      loclar.push(...xmlLocBul(alt.govde));
    }
  }

  const haric = /\/(blog|category|kategori|etiket|tag|page|sayfa)(\/|$)/i;
  const yol = (loc: string) => {
    try {
      return new URL(loc).pathname;
    } catch {
      return "";
    }
  };
  const urunSayfalari = loclar.filter((loc) => loc.startsWith("https://") && !haric.test(yol(loc)));
  const oncelikli = urunSayfalari.filter((loc) => /\/(products?|urun)(\/|$)/i.test(yol(loc)));
  const havuz = oncelikli.length > 0 ? oncelikli : urunSayfalari;
  if (havuz.length === 0) return bos();

  const kodlar = satirlar
    .flatMap((satir) => [normalizeKod(satir.model), normalizeBarkod(satir.barkod)])
    .filter((kod) => kod.length >= 4);
  const kodluAdresler = havuz.filter((loc) => {
    const slug = slugKodu(loc);
    return kodlar.some((kod) => slug.includes(kod));
  });
  const devam = (baglam.durum.devam ??= {});
  const kayit = devam[`sitemap:${iz.alan}`] ??= { sonrakiSayfa: 1, urunler: [] };
  const adresler = [...new Set([...kodluAdresler, ...havuz])];
  const secilen = adresler.slice(kayit.sonrakiSayfa - 1, kayit.sonrakiSayfa - 1 + MAKS_SAYFA_OKUMA);
  const urunler = kayit.urunler;
  for (const adres of secilen) {
    const sayfa = await hamGet(adres, fetcher, resolveHost, baglam);
    if (!sayfa || sayfa.durum !== 200) continue;
    urunler.push(...jsonLdUrunleri(sayfa.govde, adres));
    kayit.sonrakiSayfa = adresler.indexOf(adres) + 2;
    const bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
    if (bulunan.every((hedef) => hedef !== null)) return bulunan;
  }

  return hedefBul(urunler, satirlar, iz.izinDurumu);
}

function slugAdi(loc: string): string {
  try {
    return new URL(loc).pathname.split("/").pop() ?? "";
  } catch {
    return "";
  }
}

export function tedarikciDijitalIziBul(
  tedarikciAdi: string,
  tedarikciSite = "",
): TedarikciDijitalIzi | null {
  const havuzFirmasi = firmaHavuzKaydiniBul(tedarikciAdi, tedarikciSite);
  if (havuzFirmasi) {
    const alan = alanAdiTemizle(havuzFirmasi.site);
    if (!alan) return null;
    return {
      anahtar: havuzFirmasi.anahtar,
      firma: havuzFirmasi.ad,
      alan,
      platform: havuzFirmasi.platform.toLowerCase(),
      izinDurumu: havuzFirmasi.izinDurumu,
      kaynak: `https://${alan}`,
      havuzda: true,
    };
  }

  const alan = alanAdiTemizle(tedarikciSite);
  if (!alan) return null;
  return {
    anahtar: null,
    firma: tedarikciAdi.trim() || alan,
    alan,
    platform: "",
    izinDurumu: "yok",
    kaynak: `https://${alan}`,
    havuzda: false,
  };
}

export async function dinamikUrunIzleriniBul(
  satirlar: DijitalIzSatiri[],
  iz: TedarikciDijitalIzi,
  bagimliliklar: DijitalIzBagimliliklari = {},
): Promise<Array<DijitalIzHedefi | null>> {
  if (satirlar.length === 0) return [];
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;
  const durum = bagimliliklar.durum ?? { erisimHatasi: false, sinirDoldu: false };
  const simdi = bagimliliklar.simdi ?? Date.now;
  const baglam: KesifBaglami = {
    bitis: simdi() + (bagimliliklar.kesifButcesiMs ?? KESIF_BUTCESI_MS),
    simdi,
    durum,
  };

  let sonuc: Array<DijitalIzHedefi | null>;
  if (iz.platform === "shopify") {
    sonuc = await shopifyAra(iz, satirlar, fetcher, resolveHost, baglam);
  } else if (iz.platform === "woocommerce") {
    sonuc = await wooAra(iz, satirlar, fetcher, resolveHost, baglam);
  } else {
    const shopify = await shopifyAra(iz, satirlar, fetcher, resolveHost, baglam);
    sonuc = shopify.some((hedef) => hedef !== null)
      ? shopify
      : await wooAra(iz, satirlar, fetcher, resolveHost, baglam);
  }

  if (sonuc.every((hedef) => hedef !== null)) return sonuc;

  const sayfa = await sayfaAra(iz, satirlar, fetcher, resolveHost, baglam);
  const birlesik = sonuc.map((hedef, indeks) => hedef ?? sayfa[indeks]);
  if (birlesik.every((hedef) => hedef !== null)) return birlesik;
  const katalog = await resmiKataloglariAra(iz, satirlar, fetcher, resolveHost, baglam);
  return birlesik.map((hedef, indeks) => hedef ?? katalog[indeks]);
}
