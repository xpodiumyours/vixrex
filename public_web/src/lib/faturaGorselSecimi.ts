import sharp from "sharp";
import { faturaYanitMetniniOku, type GoruSatiri } from "@/lib/faturaGoru";
import { kaynakGorseliniDogrula, type GorselBagimliliklari } from "@/lib/faturaGorsel";
import { FATURA_MIN_SOURCE_SHORT_EDGE } from "@/lib/productImagePolicy";

export const GORSEL_SECIM_PRESET = "@preset/urun-gorsel-secim";

export interface GorselSecimBagimliliklari extends GorselBagimliliklari {
  modelCagrisi?: (govde: Record<string, unknown>) => Promise<Response>;
}

interface SecimKarari {
  secilen: number | null;
  sira: number[];
  red: number[];
}

const SECIM_ZAMAN_ASIMI_MS = 120_000;

function nesne(deger: unknown): deger is Record<string, unknown> {
  return typeof deger === "object" && deger !== null && !Array.isArray(deger);
}

function tamSayi(deger: unknown): number | null {
  return typeof deger === "number" && Number.isInteger(deger) ? deger : null;
}

function sayiDizisi(deger: unknown): number[] {
  return Array.isArray(deger)
    ? deger.map(tamSayi).filter((x): x is number => x !== null)
    : [];
}

function secimKararlariniOku(cozulen: unknown): Map<string, SecimKarari> {
  const kararlar = new Map<string, SecimKarari>();
  if (!nesne(cozulen) || !Array.isArray(cozulen.secimler)) return kararlar;
  for (const kayit of cozulen.secimler) {
    if (!nesne(kayit) || typeof kayit.row_id !== "string" || kararlar.has(kayit.row_id)) continue;
    kararlar.set(kayit.row_id, {
      secilen: tamSayi(kayit.secilen),
      sira: sayiDizisi(kayit.sira),
      red: sayiDizisi(kayit.red),
    });
  }
  return kararlar;
}

export function gorselSecimIstekGovdesi(
  girdiler: Array<{ row_id: string; ad: string; marka: string; aday_indeksleri: number[] }>,
  veriUrler: string[],
): Record<string, unknown> {
  const metin = [
    "Her satır için resmî sayfasından toplanan aday ürün görselleri gönderilmiştir; her satırın adayları kendi başlığının ardından kendi grubunda gelir.",
    JSON.stringify({ satirlar: girdiler }),
    "Her satırın başlığından sonra gelen görseller o satırın adaylarıdır ve verilen sırayla satır içinde 0'dan numaralandırılır. Çıktı indeksleri bu satır içi numaralardır.",
    "Presetindeki seçim kurallarına uygun tek JSON çıktısını üret.",
  ].join("\n");
  const icerik: Array<Record<string, unknown>> = [{ type: "text", text: metin }];
  for (const girdi of girdiler) {
    icerik.push({
      type: "text",
      text: `Satır ${girdi.row_id} — ${girdi.ad}${girdi.marka ? ` (${girdi.marka})` : ""} adayları, sırayla 0..${girdi.aday_indeksleri.length - 1}:`,
    });
    for (const indeks of girdi.aday_indeksleri) {
      icerik.push({ type: "image_url", image_url: { url: veriUrler[indeks] } });
    }
  }
  return {
    model: GORSEL_SECIM_PRESET,
    stream: true,
    response_format: { type: "json_object" },
    provider: { require_parameters: true },
    messages: [{ role: "user", content: icerik }],
  };
}

async function kucukVeriUrl(bayt: Uint8Array): Promise<string> {
  const kucuk = await sharp(Buffer.from(bayt))
    .resize({ width: 512, height: 512, fit: "inside" })
    .webp({ quality: 70 })
    .toBuffer();
  return `data:image/webp;base64,${kucuk.toString("base64")}`;
}

async function varsayilanModelCagrisi(govde: Record<string, unknown>): Promise<Response> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  return fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
      "HTTP-Referer": "https://vixrex.com",
      "X-Title": "Vixrex Fatura",
    },
    body: JSON.stringify(govde),
    signal: AbortSignal.timeout(SECIM_ZAMAN_ASIMI_MS),
  });
}

export async function adayGorselleriniSec(args: {
  satirlar: GoruSatiri[];
  bagimliliklar?: GorselSecimBagimliliklari;
}): Promise<GoruSatiri[]> {
  const { satirlar } = args;
  const girdiler: Array<{ row_id: string; ad: string; marka: string; aday_indeksleri: number[] }> = [];
  const veriUrler: string[] = [];
  const satirPozisyonlari = new Map<string, number[]>();
  const tumPozisyonlari = new Map<string, number[]>();

  for (let i = 0; i < satirlar.length; i++) {
    const satir = satirlar[i];
    const adaylar = satir.siteGorseller ?? [];
    if (adaylar.length < 2) continue;
    const row_id = String(i + 1);
    const dogrulanan: Array<{ yerel: number; bayt: Uint8Array; kisaKenar: number }> = [];
    for (let yerel = 0; yerel < adaylar.length; yerel++) {
      const kontrol = await kaynakGorseliniDogrula(adaylar[yerel], args.bagimliliklar);
      if (!kontrol.tamam || !kontrol.bayt) continue;
      const kisaKenar = Math.min(kontrol.genislik ?? 0, kontrol.yukseklik ?? 0);
      dogrulanan.push({ yerel, bayt: kontrol.bayt, kisaKenar });
    }
    if (!dogrulanan.length) continue;
    const esigiGecen = dogrulanan.filter((aday) => aday.kisaKenar >= FATURA_MIN_SOURCE_SHORT_EDGE);
    const modeleGiden = esigiGecen.length
      ? esigiGecen
      : [...dogrulanan].sort((a, b) => b.kisaKenar - a.kisaKenar);
    const aday_indeksleri: number[] = [];
    for (const aday of modeleGiden) {
      aday_indeksleri.push(veriUrler.length);
      veriUrler.push(await kucukVeriUrl(aday.bayt));
    }
    girdiler.push({ row_id, ad: satir.ad, marka: satir.marka, aday_indeksleri });
    satirPozisyonlari.set(row_id, modeleGiden.map((aday) => aday.yerel));
    tumPozisyonlari.set(
      row_id,
      [...dogrulanan]
        .sort((a, b) => {
          const aBuyuk = a.kisaKenar >= FATURA_MIN_SOURCE_SHORT_EDGE ? 1 : 0;
          const bBuyuk = b.kisaKenar >= FATURA_MIN_SOURCE_SHORT_EDGE ? 1 : 0;
          if (aBuyuk !== bBuyuk) return bBuyuk - aBuyuk;
          if (a.kisaKenar !== b.kisaKenar) return b.kisaKenar - a.kisaKenar;
          return a.yerel - b.yerel;
        })
        .map((aday) => aday.yerel),
    );
  }
  if (!girdiler.length) return satirlar;

  let kararlar: Map<string, SecimKarari>;
  try {
    const cagri = args.bagimliliklar?.modelCagrisi ?? varsayilanModelCagrisi;
    const yanit = await cagri(gorselSecimIstekGovdesi(girdiler, veriUrler));
    const { icerik } = await faturaYanitMetniniOku(yanit);
    kararlar = secimKararlariniOku(JSON.parse(icerik));
  } catch {
    return satirlar;
  }

  const sonuc = [...satirlar];
  for (const [row_id, karar] of kararlar) {
    const pozisyonlar = satirPozisyonlari.get(row_id);
    const siraIndex = Number(row_id) - 1;
    const satir = Number.isInteger(siraIndex) ? satirlar[siraIndex] : undefined;
    if (!pozisyonlar || !satir) continue;
    const adaylar = satir.siteGorseller ?? [];
    const kabul = new Set<number>();
    const dizilim: number[] = [];
    const ekle = (aday: number | null) => {
      if (aday === null || aday < 0 || aday >= pozisyonlar.length) return;
      const y = pozisyonlar[aday];
      if (kabul.has(y)) return;
      kabul.add(y);
      dizilim.push(y);
    };
    ekle(karar.secilen);
    for (const aday of karar.sira) ekle(aday);
    const elenenler = new Set<number>();
    for (const aday of karar.red) {
      if (aday < 0 || aday >= pozisyonlar.length) continue;
      const y = pozisyonlar[aday];
      if (kabul.has(y)) continue;
      elenenler.add(y);
    }
    const siraliPozisyonlar = [
      ...(tumPozisyonlari.get(row_id) ?? []),
      ...adaylar
        .map((_, y) => y)
        .filter((y) => !(tumPozisyonlari.get(row_id) ?? []).includes(y)),
    ];
    const kalan = siraliPozisyonlar.filter((y) => !kabul.has(y) && !elenenler.has(y));
    const sonDizilim = [...dizilim, ...kalan];
    if (!sonDizilim.length) continue;
    const yeniListe = sonDizilim.map((y) => adaylar[y]);
    sonuc[siraIndex] = { ...satir, siteGorsel: yeniListe[0], siteGorseller: yeniListe };
  }
  return sonuc;
}
