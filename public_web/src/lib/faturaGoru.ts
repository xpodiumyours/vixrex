import { FATURA_JSON_ISTEGI, VARSAYILAN_FATURA_PRESET } from "@/lib/faturaPresetSozlesmesi";
import { openrouterYanitiniOku } from "@/lib/openrouterYanitAkisi";
import { normalizeProductMetadata, type ProductAttributeValue } from "@/lib/productRichData";
export { VARSAYILAN_FATURA_PRESET } from "@/lib/faturaPresetSozlesmesi";

/** Fatura görselini OpenRouter'a gönderir. Araştırma ve doğrulama mevcut preset'te kalır. */
export const GORU_MODELI = process.env.OPENROUTER_MODEL || "openai/gpt-5.6-luna";
export type UrunOzelligi = ProductAttributeValue;
export type KartKaynagi = string | Record<string, unknown>;

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
  siteAciklama?: string;
  siteGorsel?: string;
  siteGorseller?: string[];
  siteSayfa?: string;
  siteKategori?: string;
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
export function katalogJsonunuOku(icerik: string): GoruSonucu {
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

export async function faturaYanitiniOku(cevap: Response): Promise<GoruSonucu> {
  const { icerik, ...kullanim } = await faturaYanitMetniniOku(cevap);
  return { ...katalogJsonunuOku(icerik), ...kullanim };
}
