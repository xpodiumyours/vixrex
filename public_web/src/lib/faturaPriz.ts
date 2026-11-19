import { VARSAYILAN_FATURA_PRESET } from "@/lib/faturaPresetSozlesmesi";
import {
  aciklamayaFaturaRengiEkle,
  alanAdiCikar,
  faturaRenginiCoz,
  geminiGroundingBilgileriniCikar,
  gorselAdaylariniSuz,
  kilitliResmiAlanAdiSec,
  kural32MetinTemizle,
  kural32NesneTemizle,
  resmiAlanAdiUygunMu,
  TURKIYE_FATURA_KISALTMA_TALIMATI,
} from "@/lib/faturaUrunHazirlama";

export const VARSAYILAN_PRIZ_ADRESI = "https://openrouter.ai/api/v1/chat/completions";

function geminiFaturaModeli(): string {
  return (process.env.GEMINI_FATURA_MODEL || "").trim() || "gemini-3.8-flash";
}

function geminiPrizAdresi(): string {
  return `https://generativelanguage.googleapis.com/v1beta/models/${geminiFaturaModeli()}:generateContent`;
}

export function geminiPrizAnahtari(): string {
  return (process.env.GEMINI_API_KEY || "").trim() || (process.env.GOOGLE_API_KEY || "").trim();
}

export function openRouterPrizAnahtari(): string {
  return (process.env.FATURA_PRIZ_API_KEY || "").trim() || (process.env.OPENROUTER_API_KEY || "").trim();
}

export function geminiPrizAktifMi(): boolean {
  const geminiKey = geminiPrizAnahtari();
  if (!geminiKey) return false;
  const acikAdres = (process.env.FATURA_PRIZ_URL || "").trim();
  if (!acikAdres) return true;
  return acikAdres.includes("generativelanguage.googleapis.com");
}

export function faturaPrizAdresi(): string {
  if (geminiPrizAktifMi()) {
    const acikAdres = (process.env.FATURA_PRIZ_URL || "").trim();
    if (acikAdres.includes("generativelanguage.googleapis.com")) {
      return acikAdres.includes("?key=") ? acikAdres : `${acikAdres}?key=${geminiPrizAnahtari()}`;
    }
    return `${geminiPrizAdresi()}?key=${geminiPrizAnahtari()}`;
  }
  const acikAdres = (process.env.FATURA_PRIZ_URL || "").trim();
  if (acikAdres) return acikAdres;
  const temelAdres = (process.env.OPENROUTER_BASE_URL || "").trim().replace(/\/+$/, "");
  if (temelAdres) {
    return temelAdres.endsWith("/chat/completions") ? temelAdres : `${temelAdres}/chat/completions`;
  }
  return VARSAYILAN_PRIZ_ADRESI;
}

export function faturaPrizAnahtari(): string {
  if (geminiPrizAktifMi()) {
    return geminiPrizAnahtari();
  }
  const orKey = openRouterPrizAnahtari();
  if (orKey) return orKey;
  return geminiPrizAnahtari();
}

export function faturaOkumaPresetReferansi(): string {
  const ham = (process.env.OPENROUTER_PRESET || process.env.OPENROUTER_FATURA_PRESET || VARSAYILAN_FATURA_PRESET).trim();
  return ham.startsWith("@preset/") ? ham : `@preset/${ham}`;
}

export function faturaPrizZamanSiniri(): number {
  const deger = Number(process.env.OPENROUTER_FATURA_TIMEOUT_MS ?? 240_000);
  return Number.isFinite(deger) && deger >= 30_000 && deger <= 900_000 ? deger : 240_000;
}

export function faturaPrizBasliklari(anahtar: string): Record<string, string> {
  if (geminiPrizAktifMi()) {
    return { "Content-Type": "application/json" };
  }
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${anahtar}`,
    "HTTP-Referer": "https://vixrex.com",
    "X-Title": "Vixrex Fatura",
  };
}

function dataUrlToGeminiPart(url: string): Record<string, unknown> {
  const eslesme = /^data:([^;,]+)(?:;[^,]*)?;base64,([\s\S]+)$/.exec(url);
  if (eslesme) {
    return { inlineData: { mimeType: eslesme[1], data: eslesme[2] } };
  }
  return { fileData: { fileUri: url } };
}

function icerikParcasiniCevir(parca: unknown): Record<string, unknown> | null {
  if (typeof parca === "string") return { text: parca };
  if (!parca || typeof parca !== "object") return null;
  const o = parca as Record<string, unknown>;
  if (o.type === "text" && typeof o.text === "string") {
    return { text: o.text };
  }
  if (o.type === "image_url" && o.image_url && typeof o.image_url === "object") {
    const url = (o.image_url as Record<string, unknown>).url;
    if (typeof url === "string" && url) return dataUrlToGeminiPart(url);
  }
  if (o.type === "file" && o.file && typeof o.file === "object") {
    const fileData = (o.file as Record<string, unknown>).file_data;
    if (typeof fileData === "string" && fileData) return dataUrlToGeminiPart(fileData);
  }
  return null;
}

function mesajParcalarListesi(icerik: unknown): Array<Record<string, unknown>> {
  if (typeof icerik === "string") return icerik ? [{ text: icerik }] : [];
  if (!Array.isArray(icerik)) return [];
  return icerik.map(icerikParcasiniCevir).filter((p): p is Record<string, unknown> => p !== null);
}

export function geminiGovdesineCevir(govde: Record<string, unknown>): Record<string, unknown> {
  if (Array.isArray(govde.contents) || !Array.isArray(govde.messages)) return govde;
  const contents: Array<{ role: string; parts: Array<Record<string, unknown>> }> = [];
  const systemParts: Array<Record<string, unknown>> = [];
  for (const mesaj of govde.messages) {
    if (!mesaj || typeof mesaj !== "object") continue;
    const m = mesaj as Record<string, unknown>;
    const parts = mesajParcalarListesi(m.content);
    if (!parts.length) continue;
    if (m.role === "system") {
      systemParts.push(...parts);
      continue;
    }
    contents.push({ role: m.role === "assistant" ? "model" : "user", parts });
  }
  const sonuc: Record<string, unknown> = { contents };
  if (systemParts.length) sonuc.systemInstruction = { parts: systemParts };
  const rf = govde.response_format as Record<string, unknown> | undefined;
  if (rf && typeof rf === "object") {
    const rfType = String(rf.type ?? "");
    if (rfType === "json_schema") {
      const jsonSchemaObj = rf.json_schema as Record<string, unknown> | undefined;
      const sema = jsonSchemaObj && typeof jsonSchemaObj === "object" ? jsonSchemaObj.schema : undefined;
      sonuc.generationConfig = {
        responseMimeType: "application/json",
        ...(sema && typeof sema === "object" ? { responseJsonSchema: sema } : {}),
      };
    } else if (rfType === "json_object") {
      sonuc.generationConfig = { responseMimeType: "application/json" };
    }
  }
  return sonuc;
}

async function geminiYanitiniOpenRouterBicimineCevir(yanit: Response): Promise<Response> {
  if (!yanit.ok || typeof yanit.clone !== "function") return yanit;
  const veri = await yanit.clone().json().catch(() => null) as Record<string, unknown> | null;
  if (!veri || !Array.isArray(veri.candidates) || Array.isArray(veri.choices)) return yanit;
  const aday = (veri.candidates[0] ?? {}) as Record<string, unknown>;
  const icerikNesnesi = (aday.content ?? {}) as Record<string, unknown>;
  const hamParcalar = Array.isArray(icerikNesnesi.parts) ? icerikNesnesi.parts : [];
  const metinParcalari = hamParcalar
    .filter((p): p is Record<string, unknown> => Boolean(p && typeof p === "object" && typeof (p as Record<string, unknown>).text === "string" && (p as Record<string, unknown>).thought !== true))
    .map((p) => String(p.text));
  const icerik = metinParcalari.join("");
  const hamNeden = typeof aday.finishReason === "string" ? aday.finishReason : "STOP";
  const finishReason = hamNeden === "MAX_TOKENS" ? "length" : hamNeden === "STOP" ? "stop" : "content_filter";
  const usageMeta = (veri.usageMetadata ?? {}) as Record<string, unknown>;
  const openrouterYanit = {
    id: typeof veri.responseId === "string" ? veri.responseId : null,
    model: typeof veri.modelVersion === "string" ? veri.modelVersion : geminiFaturaModeli(),
    choices: [{
      finish_reason: finishReason,
      message: {
        content: icerik,
        ...(finishReason === "content_filter" && !icerik ? { refusal: hamNeden } : {}),
      },
    }],
    usage: {
      prompt_tokens: Number(usageMeta.promptTokenCount ?? 0),
      completion_tokens: Number(usageMeta.candidatesTokenCount ?? 0),
      ...(usageMeta.thoughtsTokenCount !== undefined
        ? { completion_tokens_details: { reasoning_tokens: Number(usageMeta.thoughtsTokenCount ?? 0) } }
        : {}),
    },
  };
  return new Response(JSON.stringify(openrouterYanit), {
    status: yanit.status,
    statusText: yanit.statusText,
    headers: { "Content-Type": "application/json" },
  });
}

export async function faturaPrizIstegiGonder(govde: Record<string, unknown>): Promise<Response> {
  const anahtar = faturaPrizAnahtari();
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  const geminiAktif = geminiPrizAktifMi();
  const istekGovdesi = geminiAktif ? geminiGovdesineCevir(govde) : govde;
  try {
    const yanit = await fetch(faturaPrizAdresi(), {
      method: "POST",
      headers: faturaPrizBasliklari(anahtar),
      body: JSON.stringify(istekGovdesi),
      signal: AbortSignal.timeout(faturaPrizZamanSiniri()),
    });
    return geminiAktif ? await geminiYanitiniOpenRouterBicimineCevir(yanit) : yanit;
  } catch (hata) {
    if (hata instanceof Error && ["TimeoutError", "AbortError"].includes(hata.name)) {
      throw new Error("OKUYUCU_ZAMAN_ASIMI");
    }
    throw new Error("OKUYUCU_CEVAP_VERMEDI", { cause: hata });
  }
}

export interface GoogleFaturaUrunKarti {
  row_id: string;
  title: string;
  brand: string | null;
  model: string | null;
  barcode: string | null;
  variant: string | null;
  size: string | null;
  quantity: number | null;
  unit: string | null;
  unit_price: number | null;
  category: string | null;
  short_description: string | null;
  official_domain: string | null;
  official_product_url: string | null;
  selected_image_url: string | null;
  image_urls: string[];
  grounding_sources: string[];
}

export const GOOGLE_FATURA_URUN_KARTI_SEMASI = {
  type: "object",
  additionalProperties: false,
  required: ["items"],
  properties: {
    items: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "row_id",
          "title",
          "brand",
          "model",
          "barcode",
          "variant",
          "size",
          "quantity",
          "unit",
          "unit_price",
          "category",
          "short_description",
          "official_domain",
          "official_product_url",
          "selected_image_url",
          "image_urls",
        ],
        properties: {
          row_id: { type: "string" },
          title: { type: "string" },
          brand: { type: ["string", "null"] },
          model: { type: ["string", "null"] },
          barcode: { type: ["string", "null"] },
          variant: { type: ["string", "null"] },
          size: { type: ["string", "null"] },
          quantity: { type: ["number", "null"] },
          unit: { type: ["string", "null"] },
          unit_price: { type: ["number", "null"] },
          category: { type: ["string", "null"] },
          short_description: { type: ["string", "null"] },
          official_domain: { type: ["string", "null"] },
          official_product_url: { type: ["string", "null"] },
          selected_image_url: { type: ["string", "null"] },
          image_urls: {
            type: "array",
            items: { type: "string" },
          },
        },
      },
    },
  },
} as const;

const GOOGLE_FATURA_URUN_KARTI_ISTEMI = [
  "Fatura görsellerindeki satılabilir ürün kalemlerini çıkar ve her ürün için Google Search ve urlContext kullanarak resmî üretici/marka ürün kartını tek seferde oluştur.",
  TURKIYE_FATURA_KISALTMA_TALIMATI,
  "Üretici/toptancı ve esnaf VKN/TCKN, IBAN, adres, cari kodu, ETTN, fatura numarası, seri, saat, özel iskonto ve vade/çek/dipnot gibi ticari sırları kesinlikle yok say ve çıktıda yer verme.",
  "Ürünün birim alış fiyatını faturadan kâr marjı verisi olarak okuyup sayısal değerle unit_price alanına yaz (okunamazsa null döndür); alış fiyatını short_description veya title alanlarına yazma.",
  "Trendyol, Hepsiburada, N11, Amazon, Çiçeksepeti, PttAVM, Akakçe, Cimri, Epey, Sahibinden gibi pazaryeri veya aracı siteleri kesinlikle kullanma; yalnızca resmî üretici/marka alan adını (official_domain), resmî ürün sayfasını (official_product_url), birincil görseli (selected_image_url) ve resmî ürün/CDN görsellerini (image_urls) döndür.",
  "Doğrulanmış bir resmî ürün sayfası bulunamazsa tahmin yürütme; official_domain, official_product_url ve selected_image_url alanlarını null, image_urls alanını [] döndür.",
].join("\n");

function metinVeyaNull(deger: unknown): string | null {
  if (typeof deger !== "string") return null;
  const temiz = deger.trim();
  return temiz ? temiz : null;
}

function temizMetinVeyaNull(deger: unknown): string | null {
  const ham = metinVeyaNull(deger);
  if (!ham) return null;
  const temiz = kural32MetinTemizle(ham);
  return temiz ? temiz : null;
}

function googleJsonMetniniCoz(ham: string): Record<string, unknown> | null {
  const temiz = ham.trim();
  if (!temiz) return null;
  const parcalar = temiz
    .split("```")
    .map((parca) => parca.replace(/^json\s*/i, "").trim())
    .filter(Boolean);
  for (const aday of [temiz, ...parcalar]) {
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

function googleFaturaYanitiniCoz(veri: unknown): GoogleFaturaUrunKarti[] {
  if (!veri || typeof veri !== "object") return [];
  const adaylar = (veri as { candidates?: unknown }).candidates;
  if (!Array.isArray(adaylar) || !adaylar.length) return [];
  const aday = adaylar[0];
  if (!aday || typeof aday !== "object") return [];
  const adayKaydi = aday as Record<string, unknown>;
  const icerik = adayKaydi.content as { parts?: unknown } | undefined;
  const parcalar = Array.isArray(icerik?.parts) ? icerik.parts : [];
  const hamMetin = parcalar
    .filter(
      (p): p is Record<string, unknown> =>
        Boolean(
          p &&
            typeof p === "object" &&
            typeof (p as Record<string, unknown>).text === "string" &&
            (p as Record<string, unknown>).thought !== true,
        ),
    )
    .map((p) => String(p.text))
    .join("");
  const cozulmus = googleJsonMetniniCoz(hamMetin);
  const hamItems = Array.isArray(cozulmus?.items) ? cozulmus.items : [];
  if (!hamItems.length) return [];

  const { webUrller, gorselUrller } = geminiGroundingBilgileriniCikar(adayKaydi);
  const kartlar: GoogleFaturaUrunKarti[] = [];

  hamItems.forEach((hamItem, sira) => {
    if (!hamItem || typeof hamItem !== "object" || Array.isArray(hamItem)) return;
    const temiz = kural32NesneTemizle(hamItem as Record<string, unknown>);
    const title = temizMetinVeyaNull(temiz.title);
    if (!title) return;

    const tekSatirFallback = hamItems.length === 1 ? kilitliResmiAlanAdiSec(webUrller) : null;
    const tespitEdilenAlan =
      kilitliResmiAlanAdiSec([temiz.official_domain, temiz.official_product_url]) ?? tekSatirFallback;

    let officialProductUrl: string | null = null;
    if (tespitEdilenAlan) {
      const adaySayfa = metinVeyaNull(temiz.official_product_url);
      if (adaySayfa && resmiAlanAdiUygunMu(adaySayfa, tespitEdilenAlan, { gorsel: false })) {
        officialProductUrl = adaySayfa;
      } else {
        officialProductUrl =
          webUrller.find((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan, { gorsel: false })) ?? null;
      }
    }

    const officialDomain = tespitEdilenAlan
      ? alanAdiCikar(officialProductUrl) || tespitEdilenAlan
      : null;

    const hamGorseller = Array.isArray(temiz.image_urls) ? temiz.image_urls : [];
    const tumAdaylar = [...hamGorseller, ...gorselUrller];
    const imageUrls = tespitEdilenAlan
      ? gorselAdaylariniSuz({
          adaylar: tumAdaylar,
          seciliGorsel: temiz.selected_image_url,
          tespitEdilenAlan,
        })
      : [];

    const groundingSources = tespitEdilenAlan
      ? webUrller.filter((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan, { gorsel: false }))
      : [];

    const variant = temizMetinVeyaNull(temiz.variant);
    const faturaRengi = faturaRenginiCoz(variant, title);
    const hamAciklama = temizMetinVeyaNull(temiz.short_description) ?? "";
    const aciklama = aciklamayaFaturaRengiEkle(hamAciklama, faturaRengi);

    kartlar.push({
      row_id: metinVeyaNull(temiz.row_id) ?? String(sira + 1),
      title,
      brand: temizMetinVeyaNull(temiz.brand),
      model: temizMetinVeyaNull(temiz.model),
      barcode: metinVeyaNull(temiz.barcode),
      variant,
      size: temizMetinVeyaNull(temiz.size),
      quantity:
        typeof temiz.quantity === "number" && Number.isFinite(temiz.quantity)
          ? temiz.quantity
          : null,
      unit: temizMetinVeyaNull(temiz.unit),
      unit_price:
        typeof temiz.unit_price === "number" && Number.isFinite(temiz.unit_price) && temiz.unit_price >= 0
          ? temiz.unit_price
          : null,
      category: temizMetinVeyaNull(temiz.category),
      short_description: aciklama ? aciklama : null,
      official_domain: officialDomain,
      official_product_url: officialProductUrl,
      selected_image_url: imageUrls[0] ?? null,
      image_urls: imageUrls,
      grounding_sources: groundingSources,
    });
  });

  return kartlar;
}

export async function googleFaturaUrunKartlariUret(
  fotograflar: string | string[],
  fetcher: typeof fetch = globalThis.fetch,
): Promise<GoogleFaturaUrunKarti[]> {
  const liste = (Array.isArray(fotograflar) ? fotograflar : [fotograflar])
    .map((deger) => (typeof deger === "string" ? deger.trim() : ""))
    .filter(Boolean);
  if (!liste.length) return [];

  const anahtar = geminiPrizAnahtari();
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");

  const parcalar = [
    { text: GOOGLE_FATURA_URUN_KARTI_ISTEMI },
    ...liste.map(dataUrlToGeminiPart),
  ];

  let yanit: Response;
  try {
    yanit = await fetcher(
      `${geminiPrizAdresi()}?key=${encodeURIComponent(anahtar)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: parcalar }],
          tools: [
            { googleSearch: {} },
            { urlContext: {} },
          ],
          generationConfig: {
            temperature: 0.1,
            responseMimeType: "application/json",
            responseJsonSchema: GOOGLE_FATURA_URUN_KARTI_SEMASI,
          },
        }),
        signal: AbortSignal.timeout(faturaPrizZamanSiniri()),
      },
    );
  } catch (hata) {
    if (hata instanceof Error && ["TimeoutError", "AbortError"].includes(hata.name)) {
      throw new Error("OKUYUCU_ZAMAN_ASIMI");
    }
    throw new Error("OKUYUCU_CEVAP_VERMEDI", { cause: hata });
  }

  if (!yanit.ok) {
    const hamHata = typeof yanit.text === "function" ? await yanit.text().catch(() => "") : "";
    const temizHata = hamHata.replace(/([?&]key=)[^&\s"']+/gi, "$1***").slice(0, 300);
    console.warn("[faturaPriz] Gemini yanıt hatası:", { status: yanit.status, body: temizHata });
    throw new Error("OKUYUCU_CEVAP_VERMEDI");
  }

  const veri = (await yanit.json().catch(() => null)) as Record<string, unknown> | null;
  return googleFaturaYanitiniCoz(veri);
}