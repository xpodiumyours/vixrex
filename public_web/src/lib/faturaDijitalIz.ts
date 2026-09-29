import { resolve4, resolve6 } from "node:dns/promises";
import { isIP } from "node:net";
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
}

export interface DijitalIzSatiri {
  model: string;
  barkod: string;
}

export interface DijitalUrunEslesmesi {
  urun: UreticiUrunu;
  dayanak: "kod" | "barkod";
}

export interface DijitalIzBagimliliklari {
  fetcher?: (input: string, init?: RequestInit) => Promise<Response>;
  resolveHost?: (hostname: string) => Promise<string[]>;
}

const MAKS_YANIT_BAYT = 2 * 1024 * 1024;
const MAKS_SAYFA = 3;
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

async function varsayilanCoz(hostname: string): Promise<string[]> {
  const [v4, v6] = await Promise.allSettled([resolve4(hostname), resolve6(hostname)]);
  return [
    ...(v4.status === "fulfilled" ? v4.value : []),
    ...(v6.status === "fulfilled" ? v6.value : []),
  ];
}

async function hostGuvenliMi(
  hostname: string,
  resolveHost: (hostname: string) => Promise<string[]>,
): Promise<boolean> {
  if (hostname === "localhost" || hostname.endsWith(".local")) return false;
  if (isIP(hostname)) return guvenliIp(hostname);
  const adresler = await resolveHost(hostname);
  return adresler.length > 0 && adresler.every(guvenliIp);
}

async function jsonGet(
  adres: string,
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
): Promise<{ durum: number; veri: unknown } | null> {
  let url: URL;
  try {
    url = new URL(adres);
  } catch {
    return null;
  }
  if (url.protocol !== "https:" || url.username || url.password || url.port) return null;
  if (!(await hostGuvenliMi(url.hostname, resolveHost))) return null;

  let response: Response;
  try {
    response = await fetcher(url.toString(), {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(ISTEK_ZAMAN_ASIMI_MS),
      headers: { accept: "application/json" },
    });
  } catch {
    return null;
  }

  if (response.status >= 300 && response.status < 400) return null;
  const uzunluk = Number(response.headers.get("content-length") ?? 0);
  if (Number.isFinite(uzunluk) && uzunluk > MAKS_YANIT_BAYT) return null;

  const bayt = await response.arrayBuffer();
  if (bayt.byteLength > MAKS_YANIT_BAYT) return null;

  try {
    return { durum: response.status, veri: JSON.parse(Buffer.from(bayt).toString("utf8")) };
  } catch {
    return { durum: response.status, veri: null };
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
        barkod: String(varyant.barcode ?? "").trim() || kod,
        gorseller,
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
        barkod: kod,
        gorseller,
        kaynak: String(ham.permalink ?? "") || `https://${alan}`,
      } satisfies UreticiUrunu;
    })
    .filter((urun): urun is UreticiUrunu => urun !== null);
}

function hedefBul(
  urunler: UreticiUrunu[],
  satirlar: DijitalIzSatiri[],
  izinDurumu: IzinDurumu,
): Array<DijitalUrunEslesmesi | null> {
  const koda = new Map<string, UreticiUrunu>();
  const barkoda = new Map<string, UreticiUrunu>();
  for (const urun of urunler) {
    const kod = normalizeKod(urun.kod);
    if (kod && !koda.has(kod)) koda.set(kod, urun);
    const barkod = normalizeBarkod(urun.barkod);
    if (barkod.length >= 8 && !barkoda.has(barkod)) barkoda.set(barkod, urun);
  }

  return satirlar.map((satir) => {
    const barkod = normalizeBarkod(satir.barkod);
    if (barkod.length >= 8) {
      const urun = barkoda.get(barkod);
      if (urun) return { urun: gorselKapisi(urun, izinDurumu), dayanak: "barkod" as const };
    }

    const model = normalizeKod(satir.model);
    if (model.length >= 4) {
      const urun = koda.get(model);
      if (urun) return { urun: gorselKapisi(urun, izinDurumu), dayanak: "kod" as const };
    }

    return null;
  });
}

async function shopifyAra(
  iz: TedarikciDijitalIzi,
  satirlar: DijitalIzSatiri[],
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
): Promise<Array<DijitalUrunEslesmesi | null>> {
  const urunler: UreticiUrunu[] = [];
  for (let sayfa = 1; sayfa <= MAKS_SAYFA; sayfa++) {
    const sonuc = await jsonGet(
      `https://${iz.alan}/products.json?limit=250&page=${sayfa}`,
      fetcher,
      resolveHost,
    );
    if (!sonuc || sonuc.durum !== 200) break;
    const yeni = shopifyUrunleri(sonuc.veri, iz.alan);
    if (yeni.length === 0) break;
    urunler.push(...yeni);
    const bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
    if (bulunan.every((eslesme) => eslesme !== null)) return bulunan;
  }
  return hedefBul(urunler, satirlar, iz.izinDurumu);
}

async function wooAra(
  iz: TedarikciDijitalIzi,
  satirlar: DijitalIzSatiri[],
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  resolveHost: (hostname: string) => Promise<string[]>,
): Promise<Array<DijitalUrunEslesmesi | null>> {
  const urunler: UreticiUrunu[] = [];
  for (let sayfa = 1; sayfa <= MAKS_SAYFA; sayfa++) {
    const sonuc = await jsonGet(
      `https://${iz.alan}/wp-json/wc/store/v1/products?per_page=100&page=${sayfa}`,
      fetcher,
      resolveHost,
    );
    if (!sonuc || sonuc.durum !== 200) break;
    const yeni = wooUrunleri(sonuc.veri, iz.alan);
    if (yeni.length === 0) break;
    urunler.push(...yeni);
    const bulunan = hedefBul(urunler, satirlar, iz.izinDurumu);
    if (bulunan.every((eslesme) => eslesme !== null)) return bulunan;
  }
  return hedefBul(urunler, satirlar, iz.izinDurumu);
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
): Promise<Array<DijitalUrunEslesmesi | null>> {
  if (satirlar.length === 0) return [];
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;

  if (iz.platform === "shopify") return shopifyAra(iz, satirlar, fetcher, resolveHost);
  if (iz.platform === "woocommerce") return wooAra(iz, satirlar, fetcher, resolveHost);

  const shopify = await shopifyAra(iz, satirlar, fetcher, resolveHost);
  if (shopify.some((eslesme) => eslesme !== null)) return shopify;
  return wooAra(iz, satirlar, fetcher, resolveHost);
}
