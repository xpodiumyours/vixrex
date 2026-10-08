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
  apiAnahtari?: string;
  model?: string;
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

const LUNA_ADRES = "https://openrouter.ai/api/v1/responses";
const LUNA_MODEL = "openai/gpt-5.6-luna";

function lunaCiktiMetni(govde: { output_text?: unknown; output?: unknown }): string {
  if (typeof govde.output_text === "string" && govde.output_text.trim()) return govde.output_text;
  if (!Array.isArray(govde.output)) return "";
  const parcalar: string[] = [];
  for (const oge of govde.output) {
    const kayit = oge as { type?: unknown; content?: unknown };
    if (kayit.type !== "message" || !Array.isArray(kayit.content)) continue;
    for (const icerik of kayit.content) {
      const parca = icerik as { type?: unknown; text?: unknown };
      if (parca.type === "output_text" && typeof parca.text === "string") parcalar.push(parca.text);
    }
  }
  return parcalar.join("");
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

  const govde = htmlMetni(html);
  if (!govde) return "";
  const sayfaMetni = govde.length > 6000 ? govde.slice(0, 6000) : govde;

  const anahtar = (bagimliliklar.apiAnahtari ?? process.env.OPENROUTER_API_KEY ?? "").trim();
  if (!anahtar) return "";

  const model = (bagimliliklar.model ?? LUNA_MODEL).trim() || LUNA_MODEL;
  const kimlikSatiri = [kimlik.model, kimlik.ad].map((p) => p.trim()).filter(Boolean).join(" / ") || "ürün";
  let lunaGovde: { output_text?: unknown; output?: unknown } | null = null;
  try {
    const lunaYanit = await fetcher(LUNA_ADRES, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${anahtar}` },
      signal: AbortSignal.timeout(60000),
      body: JSON.stringify({
        model,
        max_output_tokens: 512,
        reasoning: { effort: "none" },
        text: {
          format: {
            type: "json_schema",
            name: "urun_aciklama",
            strict: true,
            schema: {
              type: "object",
              additionalProperties: false,
              required: ["aciklama"],
              properties: { aciklama: { type: "string" } },
            },
          },
        },
        input: [{
          role: "user",
          content: [{
            type: "input_text",
            text: `Bu sayfa metni "${kimlikSatiri}" ürününe mi ait? Aitse ürün açıklamasını sayfadaki cümlelerle döndür, uydurma. Değilse boş döndür.\nSAYFA:\n${sayfaMetni}`,
          }],
        }],
      }),
    });
    if (!lunaYanit.ok) return "";
    lunaGovde = (await lunaYanit.json().catch(() => null)) as typeof lunaGovde;
  } catch {
    return "";
  }
  if (!lunaGovde) return "";
  let aciklama = "";
  try {
    aciklama = String((JSON.parse(lunaCiktiMetni(lunaGovde)) as { aciklama?: unknown }).aciklama ?? "").trim();
  } catch {
    return "";
  }
  if (!aciklama) return "";
  const sadeAciklama = sadeMetin(aciklama).replace(/\s+/g, " ").trim();
  const sadeSayfa = sadeMetin(sayfaMetni).replace(/\s+/g, " ").trim();
  if (!sadeAciklama || !sadeSayfa.includes(sadeAciklama.slice(0, Math.min(40, sadeAciklama.length)))) return "";
  return aciklama.slice(0, 500);
}

export async function kartaGirecekGorsel(
  adres: string,
  kimlik: { model: string; ad: string } = { model: "", ad: "" },
  bagimliliklar: GorselBagimliliklari = {},
): Promise<string> {
  const temiz = adres.trim();
  if (!temiz) return "";
  let url: URL;
  try {
    url = new URL(temiz);
  } catch {
    return "";
  }
  if (url.protocol !== "https:" || url.username || url.password || url.port) return "";
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;
  if (!(await hostGuvenliMi(url.hostname, resolveHost))) return "";

  const anahtar = (bagimliliklar.apiAnahtari ?? process.env.OPENROUTER_API_KEY ?? "").trim();
  if (!anahtar) return "";

  let bayt: Uint8Array;
  try {
    const yanit = await fetcher(url.toString(), {
      method: "GET",
      redirect: "manual",
      signal: AbortSignal.timeout(ZAMAN_ASIMI_MS),
      headers: { accept: "image/jpeg,image/png,image/webp" },
    });
    if (yanit.status !== 200) return "";
    bayt = new Uint8Array(await yanit.arrayBuffer());
  } catch {
    return "";
  }
  if (bayt.byteLength > MAX_PRODUCT_IMAGE_SOURCE_BYTES) return "";
  const tur = gercekTur(bayt);
  if (!tur) return "";
  try {
    const bilgi = await sharp(Buffer.from(bayt)).metadata();
    const genislik = bilgi.width ?? 0;
    const yukseklik = bilgi.height ?? 0;
    if (!genislik || !yukseklik || Math.min(genislik, yukseklik) < FATURA_MIN_SOURCE_SHORT_EDGE) return "";
  } catch {
    return "";
  }

  const model = (bagimliliklar.model ?? LUNA_MODEL).trim() || LUNA_MODEL;
  const kimlikSatiri = [kimlik.model, kimlik.ad].map((p) => p.trim()).filter(Boolean).join(" / ") || "ürün";
  const dataUrl = `data:${tur};base64,${Buffer.from(bayt).toString("base64")}`;
  let lunaGovde: { output_text?: unknown; output?: unknown } | null = null;
  try {
    const lunaYanit = await fetcher(LUNA_ADRES, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${anahtar}` },
      signal: AbortSignal.timeout(60000),
      body: JSON.stringify({
        model,
        max_output_tokens: 256,
        reasoning: { effort: "none" },
        text: {
          format: {
            type: "json_schema",
            name: "gorsel_karar",
            strict: true,
            schema: {
              type: "object",
              additionalProperties: false,
              required: ["uygun"],
              properties: { uygun: { type: "boolean" } },
            },
          },
        },
        input: [{
          role: "user",
          content: [
            { type: "input_text", text: `Bu görsel "${kimlikSatiri}" ürününün gerçek ürün fotoğrafı mı? Logo, boş zemin, banner, yer tutucu ise uygun değildir. Yalnız JSON döndür.` },
            { type: "input_image", image_url: dataUrl, detail: "low" },
          ],
        }],
      }),
    });
    if (!lunaYanit.ok) return "";
    lunaGovde = (await lunaYanit.json().catch(() => null)) as typeof lunaGovde;
  } catch {
    return "";
  }
  if (!lunaGovde) return "";
  try {
    const uygun = (JSON.parse(lunaCiktiMetni(lunaGovde)) as { uygun?: unknown }).uygun;
    return uygun === true ? temiz : "";
  } catch {
    return "";
  }
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
