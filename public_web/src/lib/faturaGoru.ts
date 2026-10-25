import { FATURA_JSON_ISTEGI, VARSAYILAN_FATURA_PRESET } from "@/lib/faturaPresetSozlesmesi";
import { openrouterYanitiniOku } from "@/lib/openrouterYanitAkisi";
import { normalizeProductMetadata, type ProductAttributeValue } from "@/lib/productRichData";
export { VARSAYILAN_FATURA_PRESET } from "@/lib/faturaPresetSozlesmesi";

/** Fatura görselini OpenRouter'a gönderir. Araştırma ve doğrulama mevcut preset'te kalır. */
export const GORU_MODELI = process.env.OPENROUTER_MODEL || "openai/gpt-5.6-luna";
export type UrunOzelligi = ProductAttributeValue;
export type KartKaynagi = string | Record<string, unknown>;

export interface GoruSatiri {
  /** Vixrex tarafından fatura satır sırasından atanır; modelden alınmaz. */
  rowId?: string;
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
  siteAciklama?: string;
  siteGorsel?: string;
  siteGorseller?: string[];
  siteSayfa?: string;
  siteKategori?: string;
  siteMarka?: string;
  siteUretici?: string;
  siteVaryant?: string;
  gorselKullanimDurumu?: string;
  satirNo?: number | null;
  uretici?: string;
  gramaj?: string;
  ozellikler?: UrunOzelligi[];
  dogrulamaDurumu?: string;
  eslesenBilgiler?: unknown;
  eksikler?: string[];
  gorselDogrulamaDurumu?: string;
  kaynaklar?: KartKaynagi[];
}

export interface GoruSonucu {
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
  maliyet: number | null;
  gercekMaliyet?: number | null;
  girdiToken: number;
  ciktiToken: number;
  akilToken: number;
  belgeEkleri?: unknown;
  gruplar?: unknown[];
  uyarilar?: string[];
}

function sayi(deger: unknown): number | null {
  if (typeof deger === "number") return Number.isFinite(deger) ? deger : null;
  if (typeof deger !== "string" || !deger.trim()) return null;
  const ham = deger.trim();
  const temiz = ham.includes(",") ? ham.replace(/\./g, "").replace(",", ".") : ham;
  const n = Number(temiz);
  return Number.isFinite(n) ? n : null;
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

function nesne(deger: unknown): deger is Record<string, unknown> {
  return deger !== null && typeof deger === "object" && !Array.isArray(deger);
}

function tamAlanlar(deger: unknown, alanlar: string[]): deger is Record<string, unknown> {
  return nesne(deger) && Object.keys(deger).length === alanlar.length && alanlar.every((alan) => Object.hasOwn(deger, alan));
}

function nullableMetin(deger: unknown): boolean { return deger === null || typeof deger === "string"; }
function nullableSayi(deger: unknown): boolean { return deger === null || (typeof deger === "number" && Number.isFinite(deger)); }

function invoiceReadV1GecerliMi(deger: unknown): deger is Record<string, unknown> {
  const top = ["contract_version", "document", "items", "warnings"];
  const doc = ["document_type", "document_number", "document_date", "supplier", "buyer", "currency", "totals"];
  const supplier = ["name", "tax_id", "address", "website_printed_on_invoice"];
  const buyer = ["name", "tax_id"];
  const totals = ["goods", "vat", "discount", "payable"];
  const row = ["invoice_row_number", "raw_text", "product_name", "brand", "manufacturer_printed", "model_or_code", "gtin", "variant_text", "quantity", "unit", "purchase_unit_price", "line_total", "read_confidence"];
  if (!tamAlanlar(deger, top) || deger.contract_version !== "vixrex.invoice-read/1.0" ||
      !tamAlanlar(deger.document, doc) || !Array.isArray(deger.items) || !deger.items.length ||
      !Array.isArray(deger.warnings) || !deger.warnings.every((x) => typeof x === "string")) return false;
  const belge = deger.document as Record<string, unknown>;
  const supplierValue = belge.supplier as Record<string, unknown>;
  const buyerValue = belge.buyer as Record<string, unknown>;
  const totalsValue = belge.totals as Record<string, unknown>;
  if (![belge.document_type, belge.document_number, belge.document_date, belge.currency].every(nullableMetin) ||
      !tamAlanlar(supplierValue, supplier) || !supplier.every((x) => nullableMetin(supplierValue[x])) ||
      !tamAlanlar(buyerValue, buyer) || !buyer.every((x) => nullableMetin(buyerValue[x])) ||
      !tamAlanlar(totalsValue, totals) || !totals.every((x) => nullableSayi(totalsValue[x]))) return false;
  return (deger.items as Record<string, unknown>[]).every((satir) => {
    if (!tamAlanlar(satir, row)) return false;
    const confidence = satir.read_confidence;
    return row.filter((x) => x !== "raw_text" && x !== "quantity" && x !== "purchase_unit_price" && x !== "line_total" && x !== "read_confidence")
      .every((x) => nullableMetin(satir[x])) &&
      typeof satir.raw_text === "string" && Boolean(satir.raw_text.trim()) &&
      nullableSayi(satir.quantity) && nullableSayi(satir.purchase_unit_price) && nullableSayi(satir.line_total) &&
      (confidence === null || (typeof confidence === "number" && Number.isFinite(confidence) && confidence >= 0 && confidence <= 1));
  });
}

function metinListesi(deger: unknown): string[] {
  return Array.isArray(deger) ? deger.map((item) =>
    typeof item === "string" ? item : JSON.stringify(item),
  ).filter((item): item is string => typeof item === "string" && Boolean(item.trim())) : [];
}

function webAdresi(deger: unknown): deger is string {
  if (typeof deger !== "string") return false;
  try {
    const url = new URL(deger);
    return ["https:", "http:"].includes(url.protocol) && !url.username && !url.password;
  } catch { return false; }
}

/** JSON çözümleme taşıma kontrolüdür; ürün kimliğini/kanıtını değerlendirmez. */
function katalogJsonunuOkuEski(icerik: string): GoruSonucu {
  let cozulen: unknown;
  try {
    const temiz = icerik.trim().replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
    cozulen = JSON.parse(temiz);
  } catch { throw new Error("OKUMA_COZULEMEDI"); }
  if (!nesne(cozulen) || !Array.isArray(cozulen.satirlar) || !cozulen.satirlar.every(nesne)) {
    throw new Error("OKUMA_COZULEMEDI");
  }
  const satirlar = cozulen.satirlar.map((s): GoruSatiri => {
    const adresler = Array.isArray(s.site_gorseller) ? s.site_gorseller : [s.site_gorsel];
    const gorseller = [...new Set(adresler.filter(webAdresi))];
    const hamOzellikler = s.ozellikler ?? s.site_ozellikler;
    const ozellikler = normalizeProductMetadata({ lunaInvoice: true, attributes: hamOzellikler }).attributes ?? [];
    const guven = sayi(s.okuma_guveni);
    return {
      hamSatir: metin(s.ham_satir), model: metin(s.model), ad: metin(s.ad),
      barkod: metin(s.barkod), varyant: metin(s.varyant), beden: metin(s.beden), marka: metin(s.marka),
      adet: sayi(s.adet), birim: metin(s.birim), birimFiyat: sayi(s.birim_fiyat), tutar: sayi(s.tutar),
      okumaGuveni: guven !== null && guven >= 0 && guven <= 1 ? guven : null,
      siteAciklama: metin(s.site_aciklama), siteGorsel: gorseller[0] ?? "", siteGorseller: gorseller,
      siteSayfa: webAdresi(s.site_sayfa) ? s.site_sayfa : "", siteKategori: metin(s.kategori), satirNo: sayi(s.satir_no),
      uretici: metin(s.uretici), gramaj: metin(s.gramaj), ozellikler,
      dogrulamaDurumu: metin(s.dogrulama_durumu), eslesenBilgiler: s.eslesen_bilgiler ?? [],
      eksikler: metinListesi(s.eksikler), gorselDogrulamaDurumu: metin(s.gorsel_dogrulama_durumu),
      kaynaklar: Array.isArray(s.kaynaklar) ? s.kaynaklar.filter((k): k is KartKaynagi =>
        typeof k === "string" || nesne(k)) : [],
    };
  });
  return {
    tedarikci: metin(cozulen.tedarikci), tedarikciVergiNo: metin(cozulen.tedarikci_vergi_no),
    tedarikciAdres: metin(cozulen.tedarikci_adres), tedarikciSite: metin(cozulen.tedarikci_site), satirlar,
    belgeAdedi: sayi(cozulen.toplam_adet), belgeToplami: sayi(cozulen.toplam_tutar),
    belgeTuru: metin(cozulen.belge_turu) || "fatura", belgeNo: metin(cozulen.belge_no),
    belgeTarihi: metin(cozulen.belge_tarihi), malBedeli: sayi(cozulen.mal_bedeli),
    kdvTutari: sayi(cozulen.kdv_tutari), indirimTutari: sayi(cozulen.indirim_tutari),
    odenecekToplam: sayi(cozulen.odenecek_toplam), belgeEkleri: cozulen.belge_ekleri ?? {},
    gruplar: Array.isArray(cozulen.gruplar) ? cozulen.gruplar : [], uyarilar: metinListesi(cozulen.uyarilar),
    maliyet: null, girdiToken: 0, ciktiToken: 0, akilToken: 0,
  };
}

/** Platformdan bağımsız invoice-read/1.0 sözleşmesini Vixrex'in iç modeline çevirir. */
function invoiceReadV1iniEsle(deger: unknown): GoruSonucu {
  if (!invoiceReadV1GecerliMi(deger)) throw new Error("OKUMA_COZULEMEDI");
  const belge = deger.document as Record<string, unknown>;
  const tedarikci = belge.supplier as Record<string, unknown>;
  const alici = belge.buyer as Record<string, unknown>;
  const toplamlar = belge.totals as Record<string, unknown>;
  const satirlar = (deger.items as Record<string, unknown>[]).map((s, i): GoruSatiri => {
    const guven = sayi(s.read_confidence);
    const hamMetin = s.raw_text as string;
    return {
      rowId: `row-${String(i + 1).padStart(4, "0")}`,
      hamSatir: hamMetin.trim(), model: metin(s.model_or_code),
      ad: metin(s.product_name) || hamMetin.trim(), barkod: metin(s.gtin),
      varyant: metin(s.variant_text), beden: "", marka: metin(s.brand),
      adet: sayi(s.quantity), birim: metin(s.unit),
      birimFiyat: sayi(s.purchase_unit_price), tutar: sayi(s.line_total),
      okumaGuveni: guven !== null && guven >= 0 && guven <= 1 ? guven : null,
      siteAciklama: "", siteGorsel: "", siteGorseller: [], siteSayfa: "",
      siteKategori: "", satirNo: sayi(s.invoice_row_number),
      uretici: metin(s.manufacturer_printed), gramaj: metin(s.variant_text),
      ozellikler: [], dogrulamaDurumu: "", eslesenBilgiler: [], eksikler: [],
      gorselDogrulamaDurumu: "", kaynaklar: [],
    };
  });
  const miktarlar = satirlar.map((s) => s.adet);
  const belgeAdedi = miktarlar.every((n) => n !== null)
    ? miktarlar.reduce<number>((toplam, n) => toplam + (n ?? 0), 0) : null;
  return {
    tedarikci: metin(tedarikci.name), tedarikciVergiNo: metin(tedarikci.tax_id),
    tedarikciAdres: metin(tedarikci.address),
    tedarikciSite: metin(tedarikci.website_printed_on_invoice), satirlar,
    belgeAdedi, belgeToplami: sayi(toplamlar.payable),
    belgeTuru: metin(belge.document_type) || "fatura",
    belgeNo: metin(belge.document_number), belgeTarihi: metin(belge.document_date),
    malBedeli: sayi(toplamlar.goods), kdvTutari: sayi(toplamlar.vat),
    indirimTutari: sayi(toplamlar.discount), odenecekToplam: sayi(toplamlar.payable),
    belgeEkleri: { buyer: alici, currency: metin(belge.currency) || null },
    gruplar: [], uyarilar: metinListesi(deger.warnings),
    maliyet: null, girdiToken: 0, ciktiToken: 0, akilToken: 0,
  };
}

/** Yeni sözleşmeyi tercih eder; geçiş boyunca eski cevap biçimini de okuyabilir. */
export function katalogJsonunuOku(icerik: string): GoruSonucu {
  let cozulen: unknown;
  try {
    const temiz = icerik.trim().replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
    cozulen = JSON.parse(temiz);
  } catch { throw new Error("OKUMA_COZULEMEDI"); }
  if (nesne(cozulen) && cozulen.contract_version === "vixrex.invoice-read/1.0") {
    return invoiceReadV1iniEsle(cozulen);
  }
  return katalogJsonunuOkuEski(icerik);
}

export function faturaPresetReferansi(): string {
  const ham = (process.env.OPENROUTER_PRESET || process.env.OPENROUTER_FATURA_PRESET || VARSAYILAN_FATURA_PRESET).trim();
  return ham.startsWith("@preset/") ? ham : `@preset/${ham}`;
}

/** Aynı gövde hem üretimde hem gerçek API smoke testinde kullanılır. */
export function faturaIstekGovdesi(dataUrl: string | string[]): Record<string, unknown> {
  const icerik = (Array.isArray(dataUrl) ? dataUrl : [dataUrl]).map((url) =>
    url.startsWith("data:application/pdf;")
      ? { type: "file", file: { filename: "fatura.pdf", file_data: url } }
      : { type: "image_url", image_url: { url } },
  );
  return {
    model: faturaPresetReferansi(), stream: true,
    response_format: { type: "json_object" },
    provider: { require_parameters: true },
    messages: [{ role: "user", content: [{ type: "text", text: FATURA_JSON_ISTEGI }, ...icerik] }],
  };
}

export async function faturayiOku(dataUrl: string | string[]): Promise<GoruSonucu> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  // Uzun araştırma işleyicisinde ayarlanabilir; Vercel senkron uç varsayılanı 240 saniyedir.
  const ayar = Number(process.env.OPENROUTER_FATURA_TIMEOUT_MS ?? 240_000);
  const zamanSiniri = Number.isFinite(ayar) && ayar >= 30_000 && ayar <= 900_000 ? ayar : 240_000;
  let cevap: Response;
  try {
    cevap = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST", headers: {
        "Content-Type": "application/json", Authorization: `Bearer ${anahtar}`,
        "HTTP-Referer": "https://vixrex.com", "X-Title": "Vixrex Fatura",
      }, body: JSON.stringify(faturaIstekGovdesi(dataUrl)), signal: AbortSignal.timeout(zamanSiniri),
    });
  } catch (hata) {
    if (hata instanceof Error && ["TimeoutError", "AbortError"].includes(hata.name)) {
      throw new Error("OKUYUCU_ZAMAN_ASIMI");
    }
    throw new Error("OKUYUCU_CEVAP_VERMEDI", { cause: hata });
  }
  return faturaYanitiniOku(cevap);
}

/** Senkron ve kalıcı işleyici aynı tamamlanmış OpenRouter yanıtını çözümler. */
export async function faturaYanitMetniniOku(cevap: Response) {
  let ham;
  try { ham = await openrouterYanitiniOku(cevap); }
  catch (hata) {
    if (hata instanceof Error && ["TimeoutError", "AbortError"].includes(hata.name)) {
      throw new Error("OKUYUCU_ZAMAN_ASIMI", { cause: hata });
    }
    if (hata instanceof Error && hata.message.startsWith("OKUYUCU_")) throw hata;
    throw new Error("OKUYUCU_CEVAP_VERMEDI", { cause: hata });
  }
  if (!cevap.ok || ham?.error) {
    if (cevap.status === 404 || Number(ham?.error?.code) === 404) throw new Error("OKUYUCU_MODEL_BULUNAMADI");
    if (cevap.status === 429 || Number(ham?.error?.code) === 429) {
      throw new Error(ham?.error?.message?.includes("free-models-per-day")
        ? "OKUYUCU_UCRETSIZ_KOTA_DOLDU" : "OKUYUCU_ISTEK_SINIRI");
    }
    throw new Error(cevap.status === 402 || ham?.error?.code === "insufficient_quota"
      ? "OKUYUCU_BAKIYE_BITTI" : "OKUYUCU_CEVAP_VERMEDI");
  }
  const secim = ham?.choices?.[0];
  if (secim?.finish_reason === "length") throw new Error("OKUYUCU_EKSIK_CEVAP");
  if (secim?.message?.tool_calls?.length) throw new Error("OKUYUCU_TAMAMLANMADI");
  if (secim?.message?.refusal) throw new Error("OKUYUCU_CEVAP_VERMEDI");
  const icerik = secim?.message?.content;
  if (typeof icerik !== "string" || !icerik.trim()) throw new Error("FOTOGRAFTA_YAZI_YOK");
  const usage = ham?.usage;
  return {
    icerik, maliyet: sayi(usage?.cost), gercekMaliyet: sayi(usage?.cost),
    girdiToken: Number(usage?.prompt_tokens ?? usage?.input_tokens ?? 0),
    ciktiToken: Number(usage?.completion_tokens ?? usage?.output_tokens ?? 0),
    akilToken: Number(usage?.completion_tokens_details?.reasoning_tokens ?? 0),
  };
}

/** Fatura okuyucusunun JSON biçimini, kart preset'inden bağımsız çözümler. */
export async function faturaYanitiniOku(cevap: Response): Promise<GoruSonucu> {
  const { icerik, ...kullanim } = await faturaYanitMetniniOku(cevap);
  return { ...katalogJsonunuOku(icerik), ...kullanim };
}
