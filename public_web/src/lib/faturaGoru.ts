
import sharp from "sharp";
import { createHash } from "node:crypto";
import { kisiselVeriTemizle } from "@/lib/faturaKisiselVeri";
import { alanAdiTemizle } from "@/lib/firmaArama";
import type { LunaKaynakKaniti } from "@/lib/faturaEslestir";


const ADRES = "https://openrouter.ai/api/v1/responses";
export const UZUN_KENAR_SINIRI = 65535;
const GIRDI_DOLAR = 0.2 / 1_000_000;
const ONBELLEK_DOLAR = 0.02 / 1_000_000;
const CIKTI_DOLAR = 1.2 / 1_000_000;

function presetModeli(alan: "OPENROUTER_INVOICE_PRESET" | "OPENROUTER_PRODUCT_PRESET"): string {
  const ad = process.env[alan]?.trim();
  if (!ad) throw new Error("OKUYUCU_PRESET_HAZIR_DEGIL");
  return ad.startsWith("@preset/") ? ad : `@preset/${ad}`;
}

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

function alanYazi() {
  return { type: "string" as const };
}

function alanSayi() {
  return { type: ["number", "null"] as const };
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
    tedarikci: alanYazi(),
    tedarikci_vergi_no: alanYazi(),
    tedarikci_adres: alanYazi(),
    tedarikci_site: alanYazi(),
    belge_turu: alanYazi(),
    belge_no: alanYazi(),
    belge_tarihi: alanYazi(),
    satirlar: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["ham_satir", "model", "ad", "barkod", "varyant", "beden", "marka", "adet", "birim", "birim_fiyat", "tutar", "okuma_guveni"],
        properties: {
          ham_satir: alanYazi(),
          model: alanYazi(),
          ad: alanYazi(),
          barkod: alanYazi(),
          varyant: alanYazi(),
          beden: alanYazi(),
          marka: alanYazi(),
          adet: alanSayi(),
          birim: alanYazi(),
          birim_fiyat: alanSayi(),
          tutar: alanSayi(),
          okuma_guveni: {
            type: "number",
          },
        },
      },
    },
    toplam_adet: alanSayi(),
    toplam_tutar: alanSayi(),
    mal_bedeli: alanSayi(),
    kdv_tutari: alanSayi(),
    indirim_tutari: alanSayi(),
    odenecek_toplam: alanSayi(),
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
  kaynakKaniti?: LunaKaynakKaniti;
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
    eslesti: { type: "boolean" },
    urun_adi: alanYazi(),
    aciklama: alanYazi(),
    kaynak_sayfa: alanYazi(),
    gorsel_adresi: alanYazi(),
    kanit: alanYazi(),
    site_kodu: alanYazi(),
    site_barkodu: alanYazi(),
    site_markasi: alanYazi(),
    site_rengi: alanYazi(),
    site_bedeni: alanYazi(),
    fotograf_rengi_dogrulandi: { type: "boolean" },
    gorsel_adresleri: { type: "array", items: alanYazi() },
    kategori: alanYazi(),
    ozellikler: {
      type: "array", items: {
        type: "object", additionalProperties: false, required: ["key", "label", "value"],
        properties: {
          key: alanYazi(),
          label: alanYazi(),
          value: alanYazi(),
        },
      },
    },
    urun_varyantlari: {
      type: "array", items: {
        type: "object", additionalProperties: false, required: ["id", "secenekler", "barkod", "gorseller"],
        properties: {
          id: alanYazi(),
          secenekler: { type: "array", items: {
            type: "object", additionalProperties: false, required: ["key", "value"],
            properties: { key: alanYazi(), value: alanYazi() },
          } },
          barkod: alanYazi(),
          gorseller: { type: "array", items: alanYazi() },
        },
      },
    },
    eslesme_dayanagi: {
      type: "string",
      enum: ["barkod", "kod", "ad-ve-ozellik", "eslesmedi"],
    },
  },
} as const;

export function satirAramaIstegi(girdi: { alan: string; model: string; ad: string; barkod: string; marka?: string; varyant?: string; beden?: string; tedarikci?: string }) {
  const alan = alanAdiTemizle(girdi.alan);
  const sorgu = [girdi.model, girdi.ad, girdi.barkod].map((p) => p.trim()).filter(Boolean).join(" ");
  if (!sorgu) return null;
  return {
    model: presetModeli("OPENROUTER_PRODUCT_PRESET"),
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
): Pick<SatirAramasi, "ad" | "gorsel" | "sayfa" | "aciklama" | "dayanak" | "marka" | "gorseller" | "kategori" | "ozellikler" | "urunVaryantlari" | "kaynakKaniti"> | null {
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
  const kaynakKaniti: LunaKaynakKaniti = {
    kanit: metin(veri.kanit), siteKodu: metin(veri.site_kodu),
    siteBarkodu: metin(veri.site_barkodu), siteMarkasi: metin(veri.site_markasi),
    siteRengi: metin(veri.site_rengi), siteBedeni: metin(veri.site_bedeni),
    fotografRengiDogrulandi: veri.fotograf_rengi_dogrulandi === true,
    eslesmeDayanagi: metin(veri.eslesme_dayanagi),
  };
  return { ad, marka: metin(veri.site_markasi), aciklama: metin(veri.aciklama), gorsel: gorseller[0] || "", gorseller,
    sayfa, dayanak, kategori: metin(veri.kategori), ozellikler, urunVaryantlari, kaynakKaniti };
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
    kaynakKaniti: bulunan?.kaynakKaniti,
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
    model: presetModeli("OPENROUTER_INVOICE_PRESET"),
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
      model: presetModeli("OPENROUTER_INVOICE_PRESET"),
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
