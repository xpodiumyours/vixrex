/**
 * Fatura fotoğrafını okuyan TEK yer.
 *
 * Telefon uygulaması da web de `/api/fatura-oku` ucuna gider; o uç da buraya.
 * İkinci bir "okuma beyni" yoktur.
 *
 * Sağlayıcı: OpenRouter Responses API, model `openai/gpt-5.6-luna`. Anahtar `OPENROUTER_API_KEY`.
 *
 * Neden bu model — 2026-09-26'da gerçek faturayla (fis_4, 13 satır / 75 adet /
 * 6.034,00 TL) ölçüldü:
 *   gpt-5.6-luna      13/13 satır, 75/75 adet, 6.034 TL, 0 yanlış  ~7 kuruş
 *   gpt-5.4-mini      12/13 satır, 74/75 adet, 5 doğru adet        ~19 kuruş
 *   claude-sonnet     13/13 satır, 75/75 adet ama yalnız 5 doğru   ~4 TL
 *   ücretsiz modeller hiçbiri tutturamadı
 * luna üç kez üst üste hatasız okudu; hem en doğru hem en ucuz olduğu için
 * seçildi. Model adı bu ölçümden sonra değiştirilmedi. Fotoğraf dosyası depoda
 * olmadığı için çağrı ayarları (OpenRouter üzerinden, görsel detail original, akıl yürütme
 * kapalı/düşük) yeni bir doğruluk iddiası taşımaz.
 *
 * Çıktı katı JSON şemasına uymak zorundadır. Yine de doğru kabul edilmez —
 * `belgeGercegiUyuyorMu` satır toplamlarını belgenin kendi toplamıyla
 * karşılaştırır. Tutmayan okuma vitrine yazılmaz.
 */

import sharp from "sharp";
import { createHash } from "node:crypto";
import { kisiselVeriTemizle } from "@/lib/faturaKisiselVeri";
import { alanAdiTemizle } from "@/lib/firmaArama";


const ADRES = "https://openrouter.ai/api/v1/responses";
export const GORU_MODELI = "openai/gpt-5.6-luna";
export const CIKTI_TOKEN_TAVANI = 16384;
export const UZUN_KENAR_SINIRI = 65535;
const GIRDI_DOLAR = 0.2 / 1_000_000;
const ONBELLEK_DOLAR = 0.02 / 1_000_000;
const CIKTI_DOLAR = 1.2 / 1_000_000;

export interface GoruSatiri {
  hamSatir: string;
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  marka: string;
  adet: number | null;
  birim: string;
  birimFiyat: number | null;
  tutar: number | null;
  okumaGuveni: number | null;
}

export interface GoruSonucu {
  /** Faturayı kesen firma. Belgede yazmıyorsa boş — tahmin edilmez. */
  tedarikci: string;
  tedarikciVergiNo: string;
  tedarikciAdres: string;
  tedarikciSite: string;
  satirlar: GoruSatiri[];
  belgeAdedi: number | null;
  belgeToplami: number | null;
  belgeTuru: string;
  belgeNo: string;
  belgeTarihi: string;
  malBedeli: number | null;
  kdvTutari: number | null;
  indirimTutari: number | null;
  odenecekToplam: number | null;
  /** Günlük maliyet limiti için kullanılan değer: tahmin olabilir. */
  maliyet: number | null;
  /** Yalnız OpenRouter usage.cost alanından, bilinmiyorsa null. */
  gercekMaliyet?: number | null;
  girdiToken: number;
  ciktiToken: number;
  akilToken: number;
}

function sayi(deger: unknown): number | null {
  if (deger === null || deger === undefined || (typeof deger === "string" && !deger.trim())) return null;
  const n = typeof deger === "number" ? deger : Number(String(deger).replace(",", "."));
  return Number.isFinite(n) ? n : null;
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

function guvenAraligi(deger: number | null): number | null {
  if (deger === null) return null;
  return Math.min(1, Math.max(0, deger));
}

function guvenliAdres(deger: unknown): string {
  const adres = metin(deger);
  if (!adres.startsWith("https://")) return "";
  try {
    const cozulen = new URL(adres);
    if (cozulen.protocol !== "https:") return "";
    return cozulen.toString();
  } catch {
    return "";
  }
}

function alanYazi(description: string) {
  return { type: "string" as const, description };
}

function alanSayi(description: string) {
  return { type: ["number", "null"] as const, description };
}

const FATURA_SEMA = {
  type: "object",
  additionalProperties: false,
  required: [
    "tedarikci",
    "tedarikci_vergi_no",
    "tedarikci_adres",
    "tedarikci_site",
    "belge_turu",
    "belge_no",
    "belge_tarihi",
    "satirlar",
    "toplam_adet",
    "toplam_tutar",
    "mal_bedeli",
    "kdv_tutari",
    "indirim_tutari",
    "odenecek_toplam",
  ],
  properties: {
    tedarikci: alanYazi("Supplier name printed on the invoice. Empty if not printed. Do not invent."),
    tedarikci_vergi_no: alanYazi("Tax number printed on the invoice. Empty if not printed. Do not invent."),
    tedarikci_adres: alanYazi("Supplier address printed on the invoice. Empty if not printed. Do not invent."),
    tedarikci_site: alanYazi("Supplier website printed on the invoice. Empty if not printed. Do not invent."),
    belge_turu: alanYazi("Document type as printed (fatura, e-arsiv, irsaliye, bilgi fisi). Empty if not printed."),
    belge_no: alanYazi("Document number as printed. Empty if not printed. Do not invent."),
    belge_tarihi: alanYazi("Document date as printed, DD.MM.YYYY. Empty if not printed. Do not invent."),
    satirlar: {
      type: "array",
      description: "Product lines from the invoice table. Do not invent lines.",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["ham_satir", "model", "ad", "barkod", "varyant", "beden", "marka", "adet", "birim", "birim_fiyat", "tutar", "okuma_guveni"],
        properties: {
          ham_satir: alanYazi("Full line text in original order and values."),
          model: alanYazi("Product code as printed. Empty if not printed. Do not invent."),
          ad: alanYazi("Product name or description as printed. Empty if not printed. Do not invent."),
          barkod: alanYazi("Barcode digits as printed. Empty if not printed. Do not invent."),
          varyant: alanYazi("Color as printed. Empty if not printed. Do not fill from elsewhere."),
          beden: alanYazi("Size as printed. Empty if not printed. Do not fill from elsewhere."),
          marka: alanYazi("Brand on the line or next to the code. Empty if not printed. Do not use the supplier as brand."),
          adet: alanSayi("Quantity as printed. Null if not printed. Do not invent."),
          birim: alanYazi("Measure unit printed on the invoice line (Adet, KG, LT, M, Paket). Empty if not printed. Do not invent. Separate from quantity."),
          birim_fiyat: alanSayi("Unit price as printed. Null if not printed. Do not invent."),
          tutar: alanSayi("Line amount as printed. Null if not printed. Do not invent."),
          okuma_guveni: {
            type: "number",
            description: "0 to 1. Near 1 if text and numbers are clear; lower if blurry, cut, struck through, or uncertain.",
          },
        },
      },
    },
    toplam_adet: alanSayi("Quantity total from the bottom Totals row. Null if not printed. Do not compute."),
    toplam_tutar: alanSayi("Amount total from the bottom Totals row. Null if not printed. Do not compute."),
    mal_bedeli: alanSayi("Only tax-exclusive goods net subtotal as explicitly labeled on invoice; never tax-inclusive total. Null if ambiguous."),
    kdv_tutari: alanSayi("VAT as printed. Null if not printed. Do not compute."),
    indirim_tutari: alanSayi("Discount as printed. Null if not printed. Do not compute."),
    odenecek_toplam: alanSayi("Amount payable as printed. Null if not printed. Do not compute."),
  },
};

export function dolarHesapla(girdi: number, cikti: number, onbellek: number): number {
  const taze = Math.max(0, girdi - onbellek);
  return taze * GIRDI_DOLAR + onbellek * ONBELLEK_DOLAR + cikti * CIKTI_DOLAR;
}

export async function goruntuyuSinirla(
  bayt: Uint8Array,
  tur: string,
): Promise<{ bayt: Buffer; tur: string }> {
  const buf = Buffer.from(bayt);
  const duz = await sharp(buf, { failOn: "none" }).rotate().toBuffer();
  const bilgi = await sharp(duz, { failOn: "none" }).metadata();
  const uzun = Math.max(bilgi.width ?? 0, bilgi.height ?? 0);
  if (!uzun || uzun <= UZUN_KENAR_SINIRI) return { bayt: duz, tur };
  const yeniden = sharp(duz, { failOn: "none" }).resize({
    width: UZUN_KENAR_SINIRI,
    height: UZUN_KENAR_SINIRI,
    fit: "inside",
    withoutEnlargement: true,
  });
  if (tur === "image/png") return { bayt: await yeniden.png().toBuffer(), tur };
  if (tur === "image/webp") return { bayt: await yeniden.webp().toBuffer(), tur };
  return { bayt: await yeniden.jpeg({ quality: 82 }).toBuffer(), tur: "image/jpeg" };
}

function ciktiMetni(govde: { output_text?: unknown; output?: unknown }): string {
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

export class ArastirmaHatasi extends Error {
  readonly kullanim: Pick<GoruSonucu, "maliyet" | "gercekMaliyet" | "girdiToken" | "ciktiToken" | "akilToken">;

  constructor(kod: string, govde: { usage?: unknown } | null) {
    super(kod);
    this.kullanim = kullanimOku(govde);
  }
}

export interface SatirAramasi {
  dayanak: "kod" | "barkod" | "ad" | null;
  ad: string;
  marka?: string;
  gorsel: string;
  sayfa: string;
  aciklama: string;
  gorseller?: string[];
  kategori?: string;
  ozellikler?: Array<{ key: string; label: string; value: string }>;
  urunVaryantlari?: Array<{ id: string; secenekler: Array<{ key: string; value: string }>; barkod: string; gorseller: string[] }>;
  maliyet: number | null;
  gercekMaliyet?: number | null;
  girdiToken: number;
  ciktiToken: number;
  akilToken: number;
}

const URUN_KAYNAK_SEMASI = {
  type: "object",
  additionalProperties: false,
  required: ["eslesti", "urun_adi", "aciklama", "kaynak_sayfa", "gorsel_adresi", "kanit", "eslesme_dayanagi", "site_kodu", "site_barkodu", "site_markasi", "site_rengi", "site_bedeni", "fotograf_rengi_dogrulandi", "gorsel_adresleri", "kategori", "ozellikler", "urun_varyantlari"],
  properties: {
    eslesti: { type: "boolean", description: "True only when the official product page was fetched and this exact invoice item matches." },
    urun_adi: alanYazi("Exact name of the matched product on the fetched official page. Never invent."),
    aciklama: alanYazi("Factual product information from the fetched page. Never invent."),
    kaynak_sayfa: alanYazi("Full https URL of the official product page actually fetched. Not merely a search result."),
    gorsel_adresi: alanYazi("Real https image URL present in fetched page data. Empty if none found. Never invent."),
    kanit: alanYazi("Specific source evidence supporting the invoice item's product identity and variant."),
    site_kodu: alanYazi("Product code seen on FETCHED page, not copied from invoice. Empty if absent."),
    site_barkodu: alanYazi("Barcode seen on FETCHED page, not copied from invoice. Empty if absent."),
    site_markasi: alanYazi("Brand seen on FETCHED product page, empty if absent."),
    site_rengi: alanYazi("Color/variant seen on FETCHED product page, empty if absent."),
    site_bedeni: alanYazi("Size/variant seen on FETCHED product page, empty if absent."),
    fotograf_rengi_dogrulandi: { type: "boolean", description: "True only if fetched source links the exact image to the invoice color, false if ambiguous." },
    gorsel_adresleri: { type: "array", items: alanYazi("Actual original image URL exposed by the fetched official product page. Never invent.") },
    kategori: alanYazi("Select the appropriate product category yourself from the identified official product and its actual use; the source need not explicitly label the category. Empty only if product identity is unknown."),
    ozellikler: {
      type: "array", items: {
        type: "object", additionalProperties: false, required: ["key", "label", "value"],
        properties: {
          key: alanYazi("Product attribute key supported by official product data."),
          label: alanYazi("Human-readable product attribute label."),
          value: alanYazi("Actual product attribute value, never invent."),
        },
      },
    },
    urun_varyantlari: {
      type: "array", items: {
        type: "object", additionalProperties: false, required: ["id", "secenekler", "barkod", "gorseller"],
        properties: {
          id: alanYazi("Stable product variant identifier from the official page."),
          secenekler: { type: "array", items: {
            type: "object", additionalProperties: false, required: ["key", "value"],
            properties: { key: alanYazi("Variant attribute key."), value: alanYazi("Actual variant value.") },
          } },
          barkod: alanYazi("Barcode on official page, empty if missing."),
          gorseller: { type: "array", items: alanYazi("Original variant image URL on official page.") },
        },
      },
    },
    eslesme_dayanagi: {
      type: "string",
      enum: ["barkod", "kod", "ad-ve-ozellik", "eslesmedi"],
      description: "Evidence for the match, otherwise eslesmedi.",
    },
  },
} as const;

export function satirAramaIstegi(girdi: { alan: string; model: string; ad: string; barkod: string; marka?: string; varyant?: string; beden?: string; tedarikci?: string }) {
  const alan = alanAdiTemizle(girdi.alan);
  const sorgu = [girdi.model, girdi.ad, girdi.barkod].map((p) => p.trim()).filter(Boolean).join(" ");
  if (!sorgu) return null;
  return {
    model: GORU_MODELI,
    max_output_tokens: CIKTI_TOKEN_TAVANI,
    provider: { require_parameters: true },
    tools: [
      { type: "openrouter:web_search", parameters: { engine: "auto" } },
      { type: "openrouter:web_fetch", parameters: { engine: "openrouter" } },
    ],
    text: {
      format: { type: "json_schema", name: "fatura_urun_kaynagi", strict: true, schema: URUN_KAYNAK_SEMASI },
    },
    input: JSON.stringify({
      invoice_issuer_website: alan,
      invoice_issuer_name: girdi.tedarikci || "",
      invoice_product_code: girdi.model,
      invoice_barcode: girdi.barkod,
      invoice_product_name: girdi.ad,
      invoice_brand: girdi.marka || "",
      invoice_color: girdi.varyant || "",
      invoice_size: girdi.beden || "",
    }),
  };
}

export function satirAramaCevabi(
  girdi: { alan: string; model: string; ad: string; barkod: string; marka?: string; varyant?: string; beden?: string },
  govde: { status?: unknown; output_text?: unknown; output?: unknown; usage?: unknown } | null,
): Pick<SatirAramasi, "ad" | "gorsel" | "sayfa" | "aciklama" | "dayanak" | "marka" | "gorseller" | "kategori" | "ozellikler" | "urunVaryantlari"> | null {
  if (!govde || (govde.status !== undefined && govde.status !== "completed")) throw new ArastirmaHatasi("ARASTIRMA_YARIM_KALDI", govde);
  let veri: Record<string, unknown>;
  try {
    veri = JSON.parse(ciktiMetni(govde)) as Record<string, unknown>;
  } catch {
    throw new ArastirmaHatasi("ARASTIRMA_COZULEMEDI", govde);
  }
  if (!veri || Array.isArray(veri) || typeof veri.eslesti !== "boolean") throw new ArastirmaHatasi("ARASTIRMA_COZULEMEDI", govde);
  if (veri.eslesti !== true) return null;
  if (typeof veri.urun_adi !== "string" || typeof veri.kaynak_sayfa !== "string") throw new ArastirmaHatasi("ARASTIRMA_COZULEMEDI", govde);
  const sayfa = guvenliAdres(veri.kaynak_sayfa);
  if (!sayfa) return null;
  const ad = metin(veri.urun_adi);
  const gorsel = guvenliAdres(veri.gorsel_adresi);
  if (!ad) return null;
  // Classification is Luna's decision, not a barcode/code comparison engine.
  const dayanak = veri.eslesme_dayanagi === "barkod" ? "barkod"
    : veri.eslesme_dayanagi === "kod" ? "kod" : "ad";
  const gorseller = [...new Set([gorsel, ...(Array.isArray(veri.gorsel_adresleri) ? veri.gorsel_adresleri.map(guvenliAdres) : [])].filter(Boolean))];
  const ozellikler = Array.isArray(veri.ozellikler) ? veri.ozellikler.flatMap((ham) => {
    if (!ham || typeof ham !== "object" || Array.isArray(ham)) return [];
    const alan = ham as Record<string, unknown>;
    const key = metin(alan.key), value = metin(alan.value);
    return key && value ? [{ key, label: metin(alan.label) || key, value }] : [];
  }) : [];
  const urunVaryantlari = Array.isArray(veri.urun_varyantlari) ? veri.urun_varyantlari.flatMap((ham) => {
    if (!ham || typeof ham !== "object" || Array.isArray(ham)) return [];
    const alan = ham as Record<string, unknown>, id = metin(alan.id);
    const secenekler = Array.isArray(alan.secenekler) ? alan.secenekler.flatMap((secenek) => {
      if (!secenek || typeof secenek !== "object" || Array.isArray(secenek)) return [];
      const option = secenek as Record<string, unknown>, key = metin(option.key), value = metin(option.value);
      return key && value ? [{ key, value }] : [];
    }) : [];
    const kimlikVerisi = secenekler.length > 0
      ? secenekler.map(({ key, value }) => [key, value]).sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b)))
      : [metin(alan.barkod), alan.gorseller];
    const teknikId = id || `luna-${createHash("sha256").update(JSON.stringify([sayfa, kimlikVerisi])).digest("hex").slice(0, 24)}`;
    return [{ id: teknikId, secenekler, barkod: metin(alan.barkod),
      gorseller: Array.isArray(alan.gorseller) ? alan.gorseller.map(guvenliAdres).filter(Boolean) : [] }];
  }) : [];
  return { ad, marka: metin(veri.site_markasi), aciklama: metin(veri.aciklama), gorsel: gorseller[0] || "", gorseller,
    sayfa, dayanak, kategori: metin(veri.kategori), ozellikler, urunVaryantlari };
}

export async function satirSitesindeAra(girdi: {
  alan: string;
  model: string;
  ad: string;
  barkod: string;
  marka?: string;
  varyant?: string;
  beden?: string;
  tedarikci?: string;
}): Promise<SatirAramasi> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  const istek = satirAramaIstegi(girdi);
  if (!istek) throw new Error("SITE_YOK_VEYA_SATIR_BOS");
  const cevap = await fetch(ADRES, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${anahtar}` },
    body: JSON.stringify(istek),
  });
  if (!cevap.ok) {
    const hataGovdesi = await cevap.json().catch(() => null);
    const kod = (hataGovdesi as { error?: { code?: string } } | null)?.error?.code;
    throw new Error(
      cevap.status === 402 || kod === "insufficient_quota" ? "OKUYUCU_BAKIYE_BITTI" : "OKUYUCU_CEVAP_VERMEDI",
    );
  }
  const govde = await cevap.json().catch(() => null);
  const bulunan = satirAramaCevabi(girdi, govde);
  return {
    ad: bulunan?.ad ?? "",
    marka: bulunan?.marka ?? "",
    dayanak: bulunan?.dayanak ?? null,
    gorsel: bulunan?.gorsel ?? "",
    sayfa: bulunan?.sayfa ?? "",
    aciklama: bulunan?.aciklama ?? "",
    gorseller: bulunan?.gorseller ?? [],
    kategori: bulunan?.kategori ?? "",
    ozellikler: bulunan?.ozellikler ?? [],
    urunVaryantlari: bulunan?.urunVaryantlari ?? [],
    ...kullanimOku(govde),
  };
}

/**
 * Fotoğrafı okur. Hata durumunda `Error` fırlatır — çağıran uç kullanıcıya
 * ne olduğunu kendi diliyle söyler.
 */

/**
 * PDF de aynı Luna okumasını ve JSON şemasını kullanır.
 * OpenRouter'ın resmî PDF girdisi yalnız /chat/completions yolundadır;
 * görsel Responses API yolunu değiştirmeden sonuçları ortak GoruSonucu'na
 * çeviririz. Ayrı ürün araştırması / ek OCR kodu yoktur.
 */
export function pdfLunaIstegi(dataUrl: string) {
  if (!/^data:application\/pdf;base64,[A-Za-z0-9+/=]+$/.test(dataUrl)) {
    throw new Error("FATURA_PDF_GECERSIZ");
  }
  return {
    model: GORU_MODELI,
    max_completion_tokens: CIKTI_TOKEN_TAVANI,
    reasoning: { effort: "none" as const },
    provider: { require_parameters: true },
    response_format: {
      type: "json_schema" as const,
      json_schema: { name: "fatura_okuma", strict: true, schema: FATURA_SEMA },
    },
    plugins: [{ id: "file-parser", pdf: { engine: "mistral-ocr" } }],
    messages: [{
      role: "user" as const,
      content: [
        { type: "file" as const, file: { filename: "fatura.pdf", file_data: dataUrl } },
      ],
    }],
  };
}

export async function faturayiOku(dataUrl: string | string[]): Promise<GoruSonucu> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  const pdfGirdisi = typeof dataUrl === "string" && dataUrl.startsWith("data:application/pdf;");
  const pdfIstegi = pdfGirdisi ? pdfLunaIstegi(dataUrl) : null;
  const cevap = await fetch(pdfIstegi ? "https://openrouter.ai/api/v1/chat/completions" : ADRES, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
    },
    body: JSON.stringify(pdfIstegi ?? {
      model: GORU_MODELI,
      max_output_tokens: CIKTI_TOKEN_TAVANI,
      reasoning: { effort: "none" },
      provider: { require_parameters: true },
      text: {
        format: {
          type: "json_schema",
          name: "fatura_okuma",
          strict: true,
          schema: FATURA_SEMA,
        },
      },
      input: [
        {
          role: "user",
          content: [
            ...(Array.isArray(dataUrl) ? dataUrl : [dataUrl]).map((url) => ({
              type: "input_image" as const, image_url: url, detail: "original" as const,
            })),
          ],
        },
      ],
    }),
  });

  if (!cevap.ok) {
    const hataGovdesi = await cevap.json().catch(() => null);
    const kod = (hataGovdesi as { error?: { code?: string } } | null)?.error?.code;
    throw new Error(
      cevap.status === 402 || kod === "insufficient_quota" ? "OKUYUCU_BAKIYE_BITTI" : "OKUYUCU_CEVAP_VERMEDI",
    );
  }

  const hamCevap = await cevap.json().catch(() => null);
  // Chat Completions PDF cevabını var olan Responses okuma sözleşmesine uyarla.
  // İçerik boş, kesilmiş veya tamamlanmamışsa başarı üretme.
  const pdfMesaji = pdfIstegi ? hamCevap?.choices?.[0] : null;
  if (pdfIstegi && (
    !pdfMesaji || pdfMesaji.finish_reason !== "stop" ||
    typeof pdfMesaji.message?.content !== "string" || !pdfMesaji.message.content.trim()
  )) throw new Error("OKUMA_YARIM_KALDI");
  const pdfUsage = hamCevap?.usage;
  const govde = pdfIstegi ? {
    status: "completed",
    output_text: pdfMesaji.message.content,
    usage: {
      input_tokens: pdfUsage?.input_tokens ?? pdfUsage?.prompt_tokens ?? 0,
      output_tokens: pdfUsage?.output_tokens ?? pdfUsage?.completion_tokens ?? 0,
      cost: pdfUsage?.cost ?? null,
      input_tokens_details: { cached_tokens: pdfUsage?.prompt_tokens_details?.cached_tokens ?? 0 },
      output_tokens_details: { reasoning_tokens: pdfUsage?.completion_tokens_details?.reasoning_tokens ?? 0 },
    },
  } : hamCevap;
  if (govde?.status === "incomplete") throw new Error("OKUMA_YARIM_KALDI");
  const ham = ciktiMetni(govde ?? {});
  if (!ham.trim()) throw new Error("FOTOGRAFTA_YAZI_YOK");

  let cozulen: unknown;
  try {
    cozulen = JSON.parse(ham);
  } catch {
    throw new Error("OKUMA_COZULEMEDI");
  }

  const kok = cozulen as {
    tedarikci?: unknown;
    tedarikci_vergi_no?: unknown;
    tedarikci_adres?: unknown;
    tedarikci_site?: unknown;
    belge_turu?: unknown;
    belge_no?: unknown;
    belge_tarihi?: unknown;
    satirlar?: unknown;
    toplam_adet?: unknown;
    toplam_tutar?: unknown;
    mal_bedeli?: unknown;
    kdv_tutari?: unknown;
    indirim_tutari?: unknown;
    odenecek_toplam?: unknown;
  };
  const hamSatirlar = Array.isArray(kok.satirlar) ? kok.satirlar : [];

  // KVKK veri minimizasyonu: modelin okuduğu serbest metin T.C. Kimlik No veya
  // vergi numarası içerebilir. Sistem bunlara ihtiyaç duymaz (eşleştirme stok
  // kodu/barkodla yapılır; tedarikçi doğrulaması OCR çıktısından gelmez), bu
  // yüzden model yanlılıkla satıra karıştırmış olsa bile SİLİNİR. Satırın
  // geri kalanına dokunulmaz — OCR doğrulaması bozulmasın diye.
  // Ayrıntı ve kapsam: src/lib/faturaKisiselVeri.ts
  const satirlar: GoruSatiri[] = hamSatirlar.map((girdi) => {
    const s = girdi as Record<string, unknown>;
    return {
      hamSatir: kisiselVeriTemizle(metin(s.ham_satir)),
      model: metin(s.model),
      ad: metin(s.ad),
      barkod: metin(s.barkod),
      varyant: metin(s.varyant),
      beden: metin(s.beden),
      marka: metin(s.marka),
      adet: sayi(s.adet),
      birim: metin(s.birim),
      birimFiyat: sayi(s.birim_fiyat),
      tutar: sayi(s.tutar),
      okumaGuveni: guvenAraligi(sayi(s.okuma_guveni)),
    };
  });

  return {
    tedarikci: metin(kok.tedarikci),
    tedarikciVergiNo: metin(kok.tedarikci_vergi_no),
    tedarikciAdres: metin(kok.tedarikci_adres),
    tedarikciSite: metin(kok.tedarikci_site),
    satirlar,
    belgeAdedi: sayi(kok.toplam_adet),
    belgeToplami: sayi(kok.toplam_tutar),
    belgeTuru: metin(kok.belge_turu),
    belgeNo: metin(kok.belge_no),
    belgeTarihi: metin(kok.belge_tarihi),
    malBedeli: sayi(kok.mal_bedeli),
    kdvTutari: sayi(kok.kdv_tutari),
    indirimTutari: sayi(kok.indirim_tutari),
    odenecekToplam: sayi(kok.odenecek_toplam),
    ...kullanimOku(govde),
  };
}

function kullanimOku(govde: { usage?: unknown } | null): Pick<GoruSonucu, "maliyet" | "gercekMaliyet" | "girdiToken" | "ciktiToken" | "akilToken"> {
  const kullanim = (govde?.usage ?? {}) as {
    input_tokens?: unknown;
    output_tokens?: unknown;
    cost?: unknown;
    input_tokens_details?: { cached_tokens?: unknown };
    output_tokens_details?: { reasoning_tokens?: unknown };
  };
  const girdiToken = sayi(kullanim.input_tokens) ?? 0;
  const ciktiToken = sayi(kullanim.output_tokens) ?? 0;
  const onbellek = sayi(kullanim.input_tokens_details?.cached_tokens) ?? 0;
  const akilToken = sayi(kullanim.output_tokens_details?.reasoning_tokens) ?? 0;
  const platformMaliyeti = typeof kullanim.cost === "number" ? sayi(kullanim.cost) : null;
  return {
    girdiToken,
    ciktiToken,
    akilToken,
    maliyet: platformMaliyeti ?? dolarHesapla(girdiToken, ciktiToken, onbellek),
    gercekMaliyet: platformMaliyeti !== null && platformMaliyeti >= 0 ? platformMaliyeti : null,
  };
}
