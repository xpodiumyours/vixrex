import { createHash } from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { DogrulanmisSatir } from "@/lib/faturaUrunBaglantisi";
import type { HazirUrunGirdisi } from "@/lib/productIntake";
import { normalizeProductVariants } from "@/lib/productRichData";
import { yonetilenUrunGorseliMi } from "@/lib/productImagePolicy";
import { kaynakGorselleriniHazirla } from "@/lib/faturaGorsel";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { kategoriBirlestir } from "@/lib/kategoriBirlesim";
import { gorselHakKaydiniRaporla } from "@/lib/faturaGorselHakDenetimi";

const PAZARYERI_VEYA_ARACI_ALANLAR = new Set([
  "trendyol.com",
  "hepsiburada.com",
  "n11.com",
  "amazon.com",
  "amazon.com.tr",
  "amazon.de",
  "ciceksepeti.com",
  "pttavm.com",
  "gittigidiyor.com",
  "morhipo.com",
  "pazarama.com",
  "idefix.com",
  "kitapyurdu.com",
  "dr.com.tr",
  "akakce.com",
  "cimri.com",
  "epey.com",
  "fiyat.com",
  "sahibinden.com",
  "letgo.com",
  "dolap.com",
  "gardrops.com",
  "zebramo.com",
  "ebay.com",
  "ebay.co.uk",
  "aliexpress.com",
  "alibaba.com",
  "temu.com",
  "shein.com",
  "etsy.com",
  "walmart.com",
  "bit.ly",
  "tinyurl.com",
  "ty.gl",
  "amzn.to",
  "facebook.com",
  "instagram.com",
  "youtube.com",
  "tiktok.com",
  "x.com",
  "twitter.com",
  "pinterest.com",
  "linkedin.com",
  "wikipedia.org",
  "vikipedi.org",
  "sikayetvar.com",
  "eksisozluk.com",
  "openfoodfacts.org",
  "barcodelookup.com",
  "upcitemdb.com",
  "ean-search.org",
  "gtinsearch.org",
  "vertexaisearch.cloud.google.com",
]);

const HASSAS_ALAN_ANAHTARLARI = new Set([
  "vergino",
  "vergi_no",
  "vkn",
  "taxid",
  "tax_id",
  "tedarikcivergino",
  "suppliertaxid",
  "supplier_tax_id",
  "alisfiyati",
  "alis_fiyati",
  "alisbirimfiyat",
  "alisbirimfiyati",
  "unitprice",
  "unit_price",
  "purchaseprice",
  "purchase_price",
  "purchasepriceamount",
  "purchase_price_amount",
  "toptanfiyat",
  "toptan_fiyat",
  "wholesaleprice",
  "wholesale_price",
]);

export function alanAdiCikar(deger: unknown): string {
  if (typeof deger !== "string") return "";
  const ham = deger.trim();
  if (!ham || /\s/.test(ham)) return "";
  if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(ham) && !/^https?:/i.test(ham)) return "";
  let url: URL;
  try {
    url = new URL(ham.includes("://") ? ham : `https://${ham}`);
  } catch {
    return "";
  }
  if (!["https:", "http:"].includes(url.protocol) || url.username || url.password) return "";
  const host = url.hostname.toLocaleLowerCase("tr-TR").replace(/^www\./, "").replace(/\.$/, "");
  if (!host || !host.includes(".") || host === "localhost" || host.endsWith(".local")) return "";
  if (/^\d{1,3}(?:\.\d{1,3}){3}$/.test(host) || host.includes(":")) return "";
  return host;
}

export function pazaryeriVeyaAraciMi(deger: unknown): boolean {
  const host = alanAdiCikar(deger);
  if (!host) return true;
  for (const alan of PAZARYERI_VEYA_ARACI_ALANLAR) {
    if (host === alan || host.endsWith(`.${alan}`)) return true;
  }
  return false;
}

export function kilitliResmiAlanAdiSec(kaynaklar: readonly unknown[]): string | null {
  for (const kaynak of kaynaklar) {
    const alan = alanAdiCikar(kaynak);
    if (alan && !pazaryeriVeyaAraciMi(alan)) return alan;
  }
  return null;
}

export function resmiAlanAdiUygunMu(adayUrl: unknown, kilitliResmiAlan?: string | null): boolean {
  if (typeof adayUrl !== "string") return false;
  let url: URL;
  try {
    url = new URL(adayUrl.trim());
  } catch {
    return false;
  }
  if (!["https:", "http:"].includes(url.protocol) || url.username || url.password) return false;
  const adayHost = alanAdiCikar(url.hostname);
  if (!adayHost || pazaryeriVeyaAraciMi(adayHost)) return false;
  const kilitli = alanAdiCikar(kilitliResmiAlan);
  if (!kilitli || pazaryeriVeyaAraciMi(kilitli)) return true;
  return adayHost === kilitli || adayHost.endsWith(`.${kilitli}`);
}

function hassasAnahtarMi(anahtar: string): boolean {
  const temiz = anahtar.toLocaleLowerCase("tr-TR").replace(/[^a-z0-9_]/g, "");
  return HASSAS_ALAN_ANAHTARLARI.has(temiz) || HASSAS_ALAN_ANAHTARLARI.has(temiz.replace(/_/g, ""));
}

function kural32DegerTemizle(deger: unknown, derinlik: number): unknown {
  if (derinlik > 6 || deger === null || typeof deger !== "object") return deger;
  if (Array.isArray(deger)) {
    return deger
      .filter((eleman) => {
        if (!eleman || typeof eleman !== "object" || Array.isArray(eleman)) return true;
        const kayit = eleman as Record<string, unknown>;
        return !hassasAnahtarMi(String(kayit.key ?? "")) && !hassasAnahtarMi(String(kayit.label ?? ""));
      })
      .map((eleman) => kural32DegerTemizle(eleman, derinlik + 1));
  }
  if (Object.getPrototypeOf(deger) !== Object.prototype) return deger;
  const temiz: Record<string, unknown> = {};
  for (const [anahtar, alt] of Object.entries(deger as Record<string, unknown>)) {
    if (hassasAnahtarMi(anahtar)) continue;
    temiz[anahtar] = kural32DegerTemizle(alt, derinlik + 1);
  }
  return temiz;
}

export function kural32NesneTemizle(kayit: Record<string, unknown>): Record<string, unknown> {
  return kural32DegerTemizle(kayit, 0) as Record<string, unknown>;
}

const GEMINI_GROUNDING_ADRESI =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";
const GROUNDING_ZAMAN_ASIMI_MS = 15_000;

export interface GroundingAramaGirdisi {
  urunAdi: string;
  marka?: string | null;
  model?: string | null;
  barkod?: string | null;
  varyant?: string | null;
  beden?: string | null;
  tedarikci?: string | null;
  tedarikciSite?: string | null;
  kilitliAlanAdi?: string | null;
}

export interface GroundingEslesmeSonucu {
  resmiAlanAdi: string;
  resmiSayfa: string;
  resmiAd: string;
  marka: string;
  aciklama: string;
  kategori: string;
  gorseller: string[];
  groundingKaynaklari: string[];
}

function geminiAramaAnahtari(): string {
  return (process.env.GEMINI_API_KEY || "").trim() || (process.env.GOOGLE_API_KEY || "").trim();
}

function metinDegeri(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

function jsonGovdeCoz(ham: string): Record<string, unknown> | null {
  const temiz = ham.trim();
  if (!temiz) return null;
  const parcalar = temiz
    .split("```")
    .map((parca) => parca.replace(/^json\s*/i, "").trim())
    .filter(Boolean);
  const adaylar = [temiz, ...parcalar];
  const bas = temiz.indexOf("{");
  const son = temiz.lastIndexOf("}");
  if (bas >= 0 && son > bas) adaylar.push(temiz.slice(bas, son + 1));
  for (const aday of adaylar) {
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

function groundingUrlListesi(aday: Record<string, unknown>): string[] {
  const meta = aday.groundingMetadata;
  if (!meta || typeof meta !== "object") return [];
  const chunks = (meta as { groundingChunks?: unknown }).groundingChunks;
  if (!Array.isArray(chunks)) return [];
  const urller: string[] = [];
  for (const chunk of chunks) {
    if (!chunk || typeof chunk !== "object") continue;
    const web = (chunk as { web?: unknown }).web;
    if (!web || typeof web !== "object") continue;
    const uri = metinDegeri((web as { uri?: unknown }).uri);
    if (!uri || !resmiAlanAdiUygunMu(uri)) continue;
    if (!urller.includes(uri)) urller.push(uri);
  }
  return urller;
}

function groundingIstemiOlustur(
  girdi: GroundingAramaGirdisi,
  kilitliAlan: string | null,
): string {
  const kimlik = {
    product_name: metinDegeri(girdi.urunAdi),
    brand: metinDegeri(girdi.marka),
    model: metinDegeri(girdi.model),
    barcode: metinDegeri(girdi.barkod),
    variant: metinDegeri(girdi.varyant),
    size: metinDegeri(girdi.beden),
    supplier: metinDegeri(girdi.tedarikci),
    ...(kilitliAlan ? { locked_official_domain: kilitliAlan } : {}),
  };
  const aramaKurali = kilitliAlan
    ? `Resmî üretici alan adı ${kilitliAlan} olarak kilitlidir. Aramayı yalnızca site:${kilitliAlan} içinde daralt ve başka hiçbir domain döndürme.`
    : "Önce ürünün/markanın tek resmî üretici veya marka alan adını (official_domain) belirle, ardından aramayı site:<official_domain> içinde daraltarak resmî ürün sayfasını bul.";
  return [
    "Google Search kullanarak aşağıdaki ürün için resmî üretici/marka web sitesini ve doğrudan ürün sayfasını tek seferde eşleştir.",
    aramaKurali,
    "Trendyol, Hepsiburada, N11, Amazon, Çiçeksepeti, PttAVM, Akakçe, Cimri, Epey, Sahibinden gibi pazaryeri veya aracı siteleri kesinlikle kullanma ve döndürme.",
    "Doğrulanmış bir resmî ürün sayfası yoksa tahmin yürütme; official_product_url değerini null döndür.",
    "Yalnızca geçerli JSON nesnesi döndür:",
    '{"official_domain":string|null,"official_product_url":string|null,"official_name":string|null,"brand":string|null,"description":string|null,"category":string|null,"image_urls":string[]}',
    JSON.stringify(kimlik),
  ].join("\n");
}

function groundingYanitiniCoz(
  veri: unknown,
  kilitliAlan: string | null,
): GroundingEslesmeSonucu | null {
  if (!veri || typeof veri !== "object") return null;
  const adaylar = (veri as { candidates?: unknown }).candidates;
  if (!Array.isArray(adaylar) || !adaylar.length) return null;
  const aday = adaylar[0];
  if (!aday || typeof aday !== "object") return null;
  const adayKaydi = aday as Record<string, unknown>;
  const icerik = adayKaydi.content as { parts?: unknown } | undefined;
  const parcalar = Array.isArray(icerik?.parts) ? icerik.parts : [];
  const hamMetin = parcalar
    .filter(
      (p): p is Record<string, unknown> =>
        Boolean(p && typeof p === "object" && typeof (p as Record<string, unknown>).text === "string" && (p as Record<string, unknown>).thought !== true),
    )
    .map((p) => String(p.text))
    .join("");
  const cozulmus = jsonGovdeCoz(hamMetin);
  const groundedUrller = groundingUrlListesi(adayKaydi);
  const jsonAlan = cozulmus ? (cozulmus.official_domain ?? cozulmus.resmi_alan_adi) : null;
  const jsonSayfa = cozulmus ? metinDegeri(cozulmus.official_product_url ?? cozulmus.resmi_sayfa) : "";

  const tespitEdilenAlan = kilitliAlan
    ? kilitliAlan
    : kilitliResmiAlanAdiSec([jsonAlan, jsonSayfa, ...groundedUrller]);
  if (!tespitEdilenAlan || pazaryeriVeyaAraciMi(tespitEdilenAlan)) return null;

  let resmiSayfa = "";
  if (jsonSayfa) {
    if (resmiAlanAdiUygunMu(jsonSayfa, tespitEdilenAlan)) {
      resmiSayfa = jsonSayfa;
    } else {
      const kilitliGrounded = groundedUrller.find((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan));
      if (!kilitliGrounded) return null;
      resmiSayfa = kilitliGrounded;
    }
  } else {
    resmiSayfa = groundedUrller.find((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan)) ?? "";
  }
  if (!resmiSayfa || !resmiAlanAdiUygunMu(resmiSayfa, tespitEdilenAlan)) return null;

  const hamGorseller = Array.isArray(cozulmus?.image_urls) ? cozulmus.image_urls : [];
  const gorseller = hamGorseller
    .map((url) => metinDegeri(url))
    .filter((url) => url.startsWith("https://") && !pazaryeriVeyaAraciMi(url));

  const temiz = kural32NesneTemizle({
    official_name: cozulmus?.official_name ?? cozulmus?.resmi_ad,
    brand: cozulmus?.brand ?? cozulmus?.marka,
    description: cozulmus?.description ?? cozulmus?.aciklama,
    category: cozulmus?.category ?? cozulmus?.kategori,
  });

  return {
    resmiAlanAdi: alanAdiCikar(resmiSayfa) || tespitEdilenAlan,
    resmiSayfa,
    resmiAd: metinDegeri(temiz.official_name),
    marka: metinDegeri(temiz.brand),
    aciklama: metinDegeri(temiz.description),
    kategori: metinDegeri(temiz.category),
    gorseller: [...new Set(gorseller)],
    groundingKaynaklari: groundedUrller.filter((url) => resmiAlanAdiUygunMu(url, tespitEdilenAlan)),
  };
}

export async function resmiUrunSayfasiGroundingIleBul(
  girdi: GroundingAramaGirdisi,
  fetcher: typeof fetch = globalThis.fetch,
): Promise<GroundingEslesmeSonucu | null> {
  const apiKey = geminiAramaAnahtari();
  if (!apiKey) return null;
  const aramaTerimiVar = [girdi.urunAdi, girdi.marka, girdi.model, girdi.barkod].some((deger) =>
    Boolean(metinDegeri(deger)),
  );
  if (!aramaTerimiVar) return null;

  const kilitliAlan = kilitliResmiAlanAdiSec([girdi.kilitliAlanAdi, girdi.tedarikciSite]);
  try {
    const yanit = await fetcher(
      `${GEMINI_GROUNDING_ADRESI}?key=${encodeURIComponent(apiKey)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [
            {
              role: "user",
              parts: [{ text: groundingIstemiOlustur(girdi, kilitliAlan) }],
            },
          ],
          tools: [{ google_search: {} }],
          generationConfig: { temperature: 0.1 },
        }),
        signal: AbortSignal.timeout(GROUNDING_ZAMAN_ASIMI_MS),
      },
    );
    if (!yanit.ok) return null;
    const veri = await yanit.json().catch(() => null);
    return groundingYanitiniCoz(veri, kilitliAlan);
  } catch {
    return null;
  }
}

export async function kayitliFaturaKatalogunuUygula(args: {
  admin: SupabaseClient;
  storeId: string;
  editToken: string;
  girdi: HazirUrunGirdisi;
  satir: DogrulanmisSatir;
  kategoriOnbellegi: Map<string, { id: string; templateKey: string }>;
  fetcher?: typeof fetch;
}): Promise<string | null> {
  const { admin, storeId, editToken, girdi, satir, kategoriOnbellegi } = args;
  const hamKatalog =
    satir.katalog && typeof satir.katalog === "object"
      ? kural32NesneTemizle(satir.katalog)
      : null;
  const kilitliAlanAdi = kilitliResmiAlanAdiSec([
    satir.resmiAlanAdi,
    hamKatalog?.official_domain,
    hamKatalog?.resmiAlanAdi,
    hamKatalog?.kaynak,
  ]);
  const mevcutKaynak = typeof hamKatalog?.kaynak === "string" ? hamKatalog.kaynak.trim() : "";
  const mevcutKaynakPazaryeri = Boolean(mevcutKaynak) && pazaryeriVeyaAraciMi(mevcutKaynak);
  const mevcutKaynakGecerli =
    Boolean(mevcutKaynak) && resmiAlanAdiUygunMu(mevcutKaynak, kilitliAlanAdi);
  const mevcutResmiAdGecerli =
    typeof hamKatalog?.resmiAd === "string" && Boolean(hamKatalog.resmiAd.trim());

  let katalog = hamKatalog;
  const groundingGerekli =
    !katalog ||
    !mevcutResmiAdGecerli ||
    mevcutKaynakPazaryeri ||
    (Boolean(mevcutKaynak) && !mevcutKaynakGecerli) ||
    (!mevcutKaynak && satir.sonuc !== "kanitli");

  if (groundingGerekli && geminiAramaAnahtari()) {
    const grounding = await resmiUrunSayfasiGroundingIleBul(
      {
        urunAdi: metinDegeri(satir.urunAdi) || metinDegeri(girdi.name),
        marka: metinDegeri(satir.marka) || metinDegeri(girdi.brand) || metinDegeri(katalog?.marka) || null,
        model: metinDegeri(satir.model) || null,
        barkod: metinDegeri(satir.barkod) || metinDegeri(girdi.barcode) || null,
        varyant: satir.varyant || null,
        beden: satir.beden || null,
        tedarikci: satir.tedarikci || null,
        tedarikciSite: satir.tedarikciSite || null,
        kilitliAlanAdi,
      },
      args.fetcher,
    );
    if (grounding) {
      katalog = kural32NesneTemizle({
        ...(katalog ?? {}),
        resmiAd: grounding.resmiAd || metinDegeri(katalog?.resmiAd) || metinDegeri(girdi.name),
        marka: grounding.marka || metinDegeri(katalog?.marka),
        aciklama: grounding.aciklama || metinDegeri(katalog?.aciklama),
        kategori: grounding.kategori || metinDegeri(katalog?.kategori),
        kaynak: grounding.resmiSayfa,
        official_domain: grounding.resmiAlanAdi,
        resmiAlanAdi: grounding.resmiAlanAdi,
        dogrulamaDurumu: "Doğrulandı",
        groundingKaynaklari: grounding.groundingKaynaklari,
      });
      satir.katalog = katalog;
      satir.resmiAlanAdi = grounding.resmiAlanAdi;
    }
  }

  if (katalog && typeof katalog.kaynak === "string" && katalog.kaynak.trim() && pazaryeriVeyaAraciMi(katalog.kaynak)) {
    katalog.kaynak = "";
  }

  if (satir.sonuc !== "kanitli" && !katalog) return null;
  if (!katalog || typeof katalog.resmiAd !== "string" || typeof katalog.kaynak !== "string") {
    return "Kayıtlı resmî ürün kaynağı eksik; yeniden eşleştir.";
  }
  if (satir.sonuc === "kanitli" && !katalog.kaynak.trim() && mevcutKaynakPazaryeri) {
    return "Kayıtlı resmî ürün kaynağı eksik; yeniden eşleştir.";
  }
  if (katalog.resmiAd.trim()) girdi.name = katalog.resmiAd.trim();
  girdi.description = typeof katalog.aciklama === "string" ? katalog.aciklama : "";
  girdi.brand = typeof katalog.marka === "string" ? katalog.marka : null;
  if (Array.isArray(katalog.gorseller)) {
    const ureticiGorselleri = katalog.gorseller.filter(
      (url): url is string => typeof url === "string" && !pazaryeriVeyaAraciMi(url),
    );
    girdi.imageUrls = [...new Set([...ureticiGorselleri, ...girdi.imageUrls])];
  }
  girdi.metadata = kural32NesneTemizle({
    ...girdi.metadata,
    attributes: [],
    manufacturerSource: undefined,
    ...faturaKatalogMetadatasi(katalog),
  });
  const varyantlar = Array.isArray(katalog.urunVaryantlari) ? katalog.urunVaryantlari : [];
  girdi.variants = normalizeProductVariants(varyantlar.map((raw) => {
    const variant = raw && typeof raw === "object" ? raw as Record<string, unknown> : {};
    const secenekler = Array.isArray(variant.secenekler) ? variant.secenekler : [];
    const options: Record<string, string> = {};
    for (const secenek of secenekler) {
      if (!secenek || typeof secenek !== "object") continue;
      const option = secenek as Record<string, unknown>;
      if (typeof option.key === "string" && typeof option.value === "string") options[option.key] = option.value;
    }
    return { id: variant.id, options, barcode: variant.barkod, imageUrls: variant.gorseller };
  }), true);
  const lunaKategori = typeof katalog.kategori === "string" ? katalog.kategori.trim() : "";
  if (!lunaKategori) return null;
  if (typeof admin?.from !== "function") return null;
  const birlesik = kategoriBirlestir(lunaKategori);
  const anahtar = birlesik.anahtar;
  let kategori = kategoriOnbellegi.get(anahtar);
  if (!kategori) {
    const mevcutlar = await admin.from("product_categories").select("id,name,product_template_key")
      .eq("store_id", storeId);
    if (mevcutlar.error) return "Luna'nın kategorisi okunamadı; tekrar dene.";
    const eslesen = (Array.isArray(mevcutlar.data) ? mevcutlar.data : []).find(
      (satir: { name?: string | null; id?: unknown; product_template_key?: string | null }) =>
        kategoriBirlestir(String(satir.name ?? "")).anahtar === anahtar,
    );
    if (eslesen) {
      kategori = { id: String(eslesen.id), templateKey: eslesen.product_template_key || "generic" };
    } else {
      const ekleme = await admin.rpc("upsert_store_category_v2", {
        p_store_id: storeId, p_edit_token: editToken,
        p_name: birlesik.ad, p_template_key: "generic",
        p_slug: `luna-${createHash("sha256").update(anahtar).digest("hex").slice(0, 24)}`,
      });
      if (!ekleme.error && ekleme.data?.success === true && typeof ekleme.data.id === "string") {
        kategori = { id: ekleme.data.id, templateKey: "generic" };
      }
    }
    if (!kategori) return "Luna'nın kategorisi kaydedilemedi; tekrar dene.";
    kategoriOnbellegi.set(anahtar, kategori);
  }
  girdi.categoryId = kategori.id;
  girdi.metadata = kural32NesneTemizle({ ...girdi.metadata, templateKey: kategori.templateKey });
  return null;
}

export async function faturaUrunGorselleriniAktar(args: {
  admin: SupabaseClient;
  slug: string;
  girdi: HazirUrunGirdisi;
  satir: DogrulanmisSatir;
  sonTarih?: number;
}) {
  const { admin, slug, girdi, satir } = args;
  const kaynakGorselleri = girdi.imageUrls.filter(
    (adres) => yonetilenUrunGorseliMi(adres) || satir.izinliGorseller.has(adres.trim()),
  );
  const disGorseller = kaynakGorselleri.filter((adres) => !yonetilenUrunGorseliMi(adres));
  let urunGorselleri = kaynakGorselleri;
  let gorselDurumu = "";
  let gorselKaynaklari: Array<Record<string, unknown>> = [];
  let gorselRedleri: Array<{ kaynakGorsel: string; sebep: string }> = [];
  const aktarilacakGorseller = [...new Set([...disGorseller,
    ...girdi.variants.flatMap((variant) => variant.imageUrls ?? [])
      .filter((url) => !yonetilenUrunGorseliMi(url) && satir.izinliGorseller.has(url.trim())),
  ])];
  if (aktarilacakGorseller.length > 0) {
    const hamKaynak = typeof satir.katalog?.kaynak === "string" ? satir.katalog.kaynak : "";
    const kaynakSayfa = hamKaynak && !pazaryeriVeyaAraciMi(hamKaynak) ? hamKaynak : "";
    const hazir = await kaynakGorselleriniHazirla({
      admin, slug,
      kaynakSayfa,
      adaylar: aktarilacakGorseller,
      sonTarih: args.sonTarih,
    });
    gorselRedleri = hazir.reddedilenler.map((red) => ({ kaynakGorsel: red.kaynakGorsel, sebep: String(red.sebep) }));
    const depodaki = new Map(hazir.gorseller.map((gorsel) => [gorsel.kaynakGorsel, gorsel]));
    const altyapiHatasi = hazir.reddedilenler.some((red) => red.sebep !== "kaynak-uyumsuz");
    urunGorselleri = kaynakGorselleri.flatMap((adres) => {
      if (yonetilenUrunGorseliMi(adres)) return [adres];
      const kopya = depodaki.get(adres);
      return kopya ? [kopya.url] : [];
    });
    gorselKaynaklari = hazir.gorseller.map((gorsel) => ({
      depoUrl: gorsel.url, kaynakGorsel: gorsel.kaynakGorsel,
      kaynakSayfa: gorsel.kaynakSayfa, genislik: gorsel.genislik, yukseklik: gorsel.yukseklik,
      ...gorselHakKaydiniRaporla(gorsel.kaynakGorsel, satir.gorselHakDurumlari),
    }));
    gorselDurumu = altyapiHatasi ? "aktarim-bekliyor" : urunGorselleri.length === 0 ? "gorsel-yok" : "depoda";
  }
  const depoGorselleri = new Map(gorselKaynaklari.map((kaynak) =>
    [String(kaynak.kaynakGorsel || ""), String(kaynak.depoUrl || "")]));
  girdi.variants = girdi.variants.map((variant) => ({
    ...variant,
    imageUrls: variant.imageUrls?.map((url) =>
      depoGorselleri.get(url) || (yonetilenUrunGorseliMi(url) ? url : "")).filter(Boolean),
  }));
  if (!gorselDurumu) gorselDurumu = urunGorselleri.length === 0 ? "gorsel-yok" : "depoda";
  return { urunGorselleri, gorselDurumu, gorselKaynaklari, gorselRedleri };
}
