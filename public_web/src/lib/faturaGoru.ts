/**
 * Fatura fotoğrafını okuyan TEK yer.
 *
 * Telefon uygulaması da web de `/api/fatura-oku` ucuna gider; o uç da buraya.
 * İkinci bir "okuma beyni" yoktur.
 *
 * Sağlayıcı: OpenAI Responses API, model `gpt-5.6-luna`. Anahtar `OPENAI_API_KEY`.
 *
 * Neden bu model — 2026-09-26'da gerçek faturayla (fis_4, 13 satır / 75 adet /
 * 6.034,00 TL) ölçüldü:
 *   gpt-5.6-luna      13/13 satır, 75/75 adet, 6.034 TL, 0 yanlış  ~7 kuruş
 *   gpt-5.4-mini      12/13 satır, 74/75 adet, 5 doğru adet        ~19 kuruş
 *   claude-sonnet     13/13 satır, 75/75 adet ama yalnız 5 doğru   ~4 TL
 *   ücretsiz modeller hiçbiri tutturamadı
 * luna üç kez üst üste hatasız okudu; hem en doğru hem en ucuz olduğu için
 * seçildi. Model adı bu ölçümden sonra değiştirilmedi. Fotoğraf dosyası depoda
 * olmadığı için çağrı ayarları (doğrudan OpenAI, detail high, akıl yürütme
 * kapalı) yeni bir doğruluk iddiası taşımaz.
 *
 * Çıktı katı JSON şemasına uymak zorundadır. Yine de doğru kabul edilmez —
 * `belgeGercegiUyuyorMu` satır toplamlarını belgenin kendi toplamıyla
 * karşılaştırır. Tutmayan okuma vitrine yazılmaz.
 */

import sharp from "sharp";
import { kisiselVeriTemizle } from "@/lib/faturaKisiselVeri";
import { firmaSitesiniAra, resmiSiteSayilmaz } from "@/lib/firmaArama";
import { alanAdiTemizle } from "@/lib/ureticiKatalog";

const ADRES = "https://openrouter.ai/api/v1/responses";
export const GORU_MODELI = "openai/gpt-5.6-luna";
export const CIKTI_TOKEN_TAVANI = 16384;
export const UZUN_KENAR_SINIRI = 65535;
const GIRDI_DOLAR = 0.2 / 1_000_000;
const ONBELLEK_DOLAR = 0.02 / 1_000_000;
const CIKTI_DOLAR = 1.2 / 1_000_000;

const SORU = [
  "Bu bir fatura tablosu. HER urun satirini oku. Yalniz JSON dondur.",
  '{"tedarikci":"","tedarikci_vergi_no":"","tedarikci_adres":"","tedarikci_site":"","belge_turu":"","belge_no":"","belge_tarihi":"","satirlar":[{"ham_satir":"","model":"","ad":"","barkod":"","varyant":"","beden":"","marka":"","adet":0,"birim_fiyat":0,"tutar":0}],"toplam_adet":0,"toplam_tutar":0,"mal_bedeli":0,"kdv_tutari":0,"indirim_tutari":0,"odenecek_toplam":0}',
  "1. Her satirda adet * birim_fiyat = tutar olmali.",
  "2. Satirlarin adet toplami = toplam_adet, tutar toplami = toplam_tutar.",
  "3. toplam_adet/toplam_tutar en alttaki 'Toplam' satirindan alinir.",
  "4. Sayilari 6.034,00 -> 6034.00 bicimine cevir. Uydurma yok.",
  "5. tedarikci = faturayi kesen firmanin adi. Yazmiyorsa bos birak, tahmin etme.",
  "6. ad = faturada yazan urun adi veya urun aciklamasi. Yazmiyorsa bos birak, tahmin etme.",
  "7. ham_satir = urun satirinda gorunen metni sirasi ve degerleriyle koru.",
  "8. tedarikci_vergi_no, tedarikci_adres ve tedarikci_site yalniz belgede acikca yaziyorsa doldur; tahmin etme.",
  "9. belge_turu: belgede acikca yaziyorsa fatura, e-arsiv, irsaliye veya bilgi fisi; belge_no ve belge_tarihi yalniz belgede yaziyorsa doldur (tarih GG.AA.YYYY), tahmin etme.",
  "10. mal_bedeli, kdv_tutari, indirim_tutari ve odenecek_toplam belgede ayri ayri yaziyorsa ayri ayri doldur; yazmiyorsa null birak, hesaplayip uydurma.",
  "11. marka = urun satirinda ya da urun kodunun yaninda yazan marka adi; yazmiyorsa bos birak, faturayi kesen firmayi marka sanma, tahmin etme.",
  "12. varyant faturada yazan renktir. beden faturada yazan bedendir. Yazmiyorsa bos birak, baska yerden tamamlama.",
  "13. tedarikci_resmi_site: belgede firmanin sitesi yazmiyorsa ve firmanin resmi web sitesini biliyorsan yalnizca alan adi olarak yaz (ornek:ornek.com). Bilmiyorsan bos birak, uydurma. Bu adres daha sonra belgedeki vergi no ve adresle dogrulanir; tutmazsa kullanilmaz.",
].join("\n");

export interface GoruSatiri {
  hamSatir: string;
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  marka: string;
  adet: number | null;
  birimFiyat: number | null;
  tutar: number | null;
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
  /** Resmi fiyattan hesaplanan maliyet (USD). OpenAI kullanım nesnesinde dolar alanı yoktur. */
  maliyet: number | null;
  girdiToken: number;
  ciktiToken: number;
  akilToken: number;
}

function sayi(deger: unknown): number | null {
  const n = typeof deger === "number" ? deger : Number(String(deger ?? "").replace(",", "."));
  return Number.isFinite(n) ? n : null;
}

function yaziliSayi(deger: unknown): number | null {
  if (deger === null || deger === undefined || deger === "") return null;
  return sayi(deger);
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
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

const SAYI_VEYA_BOS = { type: ["number", "null"] };
const YAZI = { type: "string" };

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
    tedarikci: YAZI,
    tedarikci_vergi_no: YAZI,
    tedarikci_adres: YAZI,
    tedarikci_site: YAZI,
    belge_turu: YAZI,
    belge_no: YAZI,
    belge_tarihi: YAZI,
    satirlar: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["ham_satir", "model", "ad", "barkod", "varyant", "beden", "marka", "adet", "birim_fiyat", "tutar"],
        properties: {
          ham_satir: YAZI,
          model: YAZI,
          ad: YAZI,
          barkod: YAZI,
          varyant: YAZI,
          beden: YAZI,
          marka: YAZI,
          adet: SAYI_VEYA_BOS,
          birim_fiyat: SAYI_VEYA_BOS,
          tutar: SAYI_VEYA_BOS,
        },
      },
    },
    toplam_adet: SAYI_VEYA_BOS,
    toplam_tutar: SAYI_VEYA_BOS,
    mal_bedeli: SAYI_VEYA_BOS,
    kdv_tutari: SAYI_VEYA_BOS,
    indirim_tutari: SAYI_VEYA_BOS,
    odenecek_toplam: SAYI_VEYA_BOS,
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

export function sayfaFirmadaMi(sayfa: string, alan: string): boolean {
  const host = alanAdiTemizle(sayfa);
  const kilit = alanAdiTemizle(alan);
  if (!host || !kilit) return false;
  return host === kilit || host.endsWith(`.${kilit}`);
}

export function satiraAitAramaGorseli(
  alan: string,
  govde: { output?: unknown } | null,
): { gorsel: string; sayfa: string } | null {
  if (!Array.isArray(govde?.output)) return null;
  for (const oge of govde.output) {
    const kayit = oge as { type?: unknown; results?: unknown };
    if (kayit.type !== "web_search_call" || !Array.isArray(kayit.results)) continue;
    for (const sonuc of kayit.results) {
      const resim = sonuc as { type?: unknown; image_url?: unknown; source_website_url?: unknown };
      if (resim.type !== "image_result") continue;
      const sayfa = guvenliAdres(resim.source_website_url);
      const gorsel = guvenliAdres(resim.image_url);
      if (!gorsel || !sayfa || !sayfaFirmadaMi(sayfa, alan)) continue;
      return { gorsel, sayfa };
    }
  }
  return null;
}

export async function firmaAlaniniKilitle(girdi: {
  belgedeYazan: string;
  esnafIpucu: string;
  tedarikciAdi: string;
  vergiNo: string;
  adres: string;
}): Promise<string> {
  const belgede = alanAdiTemizle(girdi.belgedeYazan);
  if (belgede && !resmiSiteSayilmaz(belgede)) return belgede;
  const ipucu = alanAdiTemizle(girdi.esnafIpucu);
  if (ipucu && !resmiSiteSayilmaz(ipucu)) return ipucu;
  const arama = await firmaSitesiniAra(girdi.tedarikciAdi, {
    kimlik: { vergiNo: girdi.vergiNo, adres: girdi.adres },
  });
  if (arama.durum === "bulundu" && arama.alan && !resmiSiteSayilmaz(arama.alan)) return arama.alan;
  return "";
}

export interface SatirAramasi {
  gorsel: string;
  sayfa: string;
  maliyet: number | null;
  girdiToken: number;
  ciktiToken: number;
  akilToken: number;
}

export async function satirSitesindeAra(girdi: {
  alan: string;
  model: string;
  ad: string;
  barkod: string;
}): Promise<SatirAramasi> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  const alan = alanAdiTemizle(girdi.alan);
  if (!alan || resmiSiteSayilmaz(alan)) throw new Error("SITE_YOK");
  const sorgu = [girdi.model, girdi.ad, girdi.barkod].map((parca) => parca.trim()).filter(Boolean).join(" ");
  if (!sorgu) throw new Error("SATIR_BOS");

  const cevap = await fetch(ADRES, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
    },
    body: JSON.stringify({
      model: GORU_MODELI,
      max_output_tokens: 1024,
      reasoning: { effort: "low" },
      tools: [{
        type: "openrouter:web_search",
        parameters: {
          engine: "native",
          allowed_domains: [alan],
        },
      }],
      include: ["web_search_call.results"],
      input: [{
        role: "user",
        content: [{ type: "input_text", text: `${sorgu}\nBu urunun fotografini yalniz ${alan} sitesinde ara.` }],
      }],
    }),
  });

  if (!cevap.ok) {
    const hataGovdesi = await cevap.json().catch(() => null);
    const kod = (hataGovdesi as { error?: { code?: string } } | null)?.error?.code;
    throw new Error(
      cevap.status === 402 || kod === "insufficient_quota" ? "OKUYUCU_BAKIYE_BITTI" : "OKUYUCU_CEVAP_VERMEDI",
    );
  }

  const govde = await cevap.json().catch(() => null);
  const bulunan = satiraAitAramaGorseli(alan, govde);
  return {
    gorsel: bulunan?.gorsel ?? "",
    sayfa: bulunan?.sayfa ?? "",
    ...kullanimOku(govde),
  };
}

/**
 * Fotoğrafı okur. Hata durumunda `Error` fırlatır — çağıran uç kullanıcıya
 * ne olduğunu kendi diliyle söyler.
 */
export async function faturayiOku(dataUrl: string): Promise<GoruSonucu> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");

  const cevap = await fetch(ADRES, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
    },
    body: JSON.stringify({
      model: GORU_MODELI,
      max_output_tokens: CIKTI_TOKEN_TAVANI,
      reasoning: { effort: "none" },
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
            { type: "input_text", text: SORU },
            { type: "input_image", image_url: dataUrl, detail: "original" },
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

  const govde = await cevap.json().catch(() => null);
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
      birimFiyat: sayi(s.birim_fiyat),
      tutar: sayi(s.tutar),
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
    malBedeli: yaziliSayi(kok.mal_bedeli),
    kdvTutari: yaziliSayi(kok.kdv_tutari),
    indirimTutari: yaziliSayi(kok.indirim_tutari),
    odenecekToplam: yaziliSayi(kok.odenecek_toplam),
    ...kullanimOku(govde),
  };
}

function kullanimOku(govde: { usage?: unknown } | null): Pick<GoruSonucu, "maliyet" | "girdiToken" | "ciktiToken" | "akilToken"> {
  const kullanim = (govde?.usage ?? {}) as {
    input_tokens?: unknown;
    output_tokens?: unknown;
    input_tokens_details?: { cached_tokens?: unknown };
    output_tokens_details?: { reasoning_tokens?: unknown };
  };
  const girdiToken = sayi(kullanim.input_tokens) ?? 0;
  const ciktiToken = sayi(kullanim.output_tokens) ?? 0;
  const onbellek = sayi(kullanim.input_tokens_details?.cached_tokens) ?? 0;
  const akilToken = sayi(kullanim.output_tokens_details?.reasoning_tokens) ?? 0;
  return {
    girdiToken,
    ciktiToken,
    akilToken,
    maliyet: dolarHesapla(girdiToken, ciktiToken, onbellek),
  };
}
