/** Fatura kart yanıtının tek sözleşmesi: biçim çözümü, alan eşanlamlıları ve kart alanları burada tanımlanır. */

import { openrouterYanitiniOku } from "@/lib/openrouterYanitAkisi";

type Kayit = Record<string, unknown>;

export const KART_SOZLESMESI_KODU = "KART_YANITI_COZULEMEDI";
export const KART_KAPSAMI_KODU = "KART_KAPSAMI_EKSIK";

export type KartDogrulamaDurumu = "verified" | "ambiguous" | "not_found" | "not_researched" | "";

export interface KartSozlesmesi {
  rowId: string;
  hamSatirNo: number | null;
  ad: string;
  marka: string;
  barkod: string;
  kod: string;
  varyant: string;
  beden: string;
  adet: number | null;
  alisFiyati: number | null;
  resmiSayfa: string;
  gorselAdresi: string;
  gorselKaynakSayfa: string;
  aciklama: string;
  kategori: string;
  dogrulamaDurumu: KartDogrulamaDurumu;
  dogrulanmis: boolean;
  eslesenBilgiler: unknown[];
  eksikler: unknown[];
  gorselDogrulamaDurumu: string;
  gorselHaklari: string;
  tekrarGrubu: string;
  kanonikRowId: string;
  kartDurumu: unknown;
  kanit: Kayit;
  kaynaklar: Kayit[];
  ham: Kayit;
}

export class KartSozlesmeHatasi extends Error {
  readonly kod: string;
  readonly hamCevap: string;

  constructor(kod: string, hamCevap: string, mesaj = "Ürün kartı yanıtı okunamadı; teknik kayıt alındı.") {
    super(kod, { cause: mesaj });
    this.name = "KartSozlesmeHatasi";
    this.kod = kod;
    this.hamCevap = hamCevap;
  }
}

function nesne(value: unknown): value is Kayit {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function metin(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function sayi(value: unknown): number | null {
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  const ham = metin(value).replace(/\s/g, "");
  if (!ham) return null;
  const temiz = ham.includes(",") ? ham.replace(/\./g, "").replace(",", ".") : ham;
  const sayi = Number(temiz);
  return Number.isFinite(sayi) ? sayi : null;
}

export function adres(value: unknown): string {
  const text = metin(value);
  try {
    const url = new URL(text);
    return ["https:", "http:"].includes(url.protocol) && !url.username && !url.password ? text : "";
  } catch { return ""; }
}

function ilkAdres(value: unknown): string {
  if (!Array.isArray(value)) return "";
  for (const eleman of value) {
    if (typeof eleman === "string" && adres(eleman)) return metin(eleman);
    if (nesne(eleman) && adres(eleman.url ?? eleman.image_url)) {
      return metin(eleman.url ?? eleman.image_url);
    }
  }
  return "";
}

function ilkKaynakAdres(value: unknown): string {
  if (!Array.isArray(value)) return "";
  for (const eleman of value) {
    if (nesne(eleman) && adres(eleman.source_url ?? eleman.page_url)) {
      return metin(eleman.source_url ?? eleman.page_url);
    }
  }
  return "";
}

function doluDizi(ana: unknown, yedek: unknown): unknown[] {
  if (Array.isArray(ana) && ana.length) return ana;
  return Array.isArray(yedek) ? yedek : [];
}

function adayJson(ham: string): unknown {
  const govde = ham;
  const parcalar = govde.split("```").map((parca) => parca.replace(/^json\s*/i, "").trim()).filter(Boolean);
  const adaylar = [govde.trim(), ...parcalar];
  const bas = govde.indexOf("{");
  const son = govde.lastIndexOf("}");
  if (bas >= 0 && son > bas) adaylar.push(govde.slice(bas, son + 1));
  for (const aday of adaylar) {
    try { return JSON.parse(aday); } catch { continue; }
  }
  return null;
}

function kartKaydi(item: Kayit): Kayit {
  const ic = nesne(item.vixrex_product_json) ? item.vixrex_product_json : {};
  return { ...item, ...ic };
}

export function tekKartSozlesmesi(item: Kayit): KartSozlesmesi {
  const kart = kartKaydi(item);
  const dogrulama: Kayit = nesne(item.validation) ? item.validation : {};
  const gorsel: Kayit = nesne(item.media) ? item.media : {};
  const gorselDogrulamaNesnesi: Kayit = nesne(kart.image_validation) ? kart.image_validation : {};
  const durum = (metin(dogrulama.status) || metin(dogrulama.verification_status)
    || metin(item.verification_status) || metin(item.validation_status)
    || metin(item.match_status) || metin(item.status)) as KartDogrulamaDurumu;
  const resmiKaniti = metin(dogrulama.official_product_url) || metin(kart.official_product_url)
    || metin(kart.product_url) || metin(dogrulama.product_url);
  const adayGorsel = ilkAdres(gorsel.image_candidates) || ilkAdres(kart.image_candidates);
  const adayKaynak = ilkKaynakAdres(gorsel.image_candidates) || ilkKaynakAdres(kart.image_candidates);
  const gorselAdresi = metin(gorsel.image_url) || metin(kart.image_url) || ilkAdres(kart.image_urls) || adayGorsel;
  const gorselKaynakSayfa = metin(gorsel.source_url) || metin(kart.source_url)
    || metin(gorselDogrulamaNesnesi.source_url) || adayKaynak;
  const resmiSayfa = resmiKaniti || gorselKaynakSayfa;
  const gorselDogrulama = metin(gorsel.verification_status) || metin(kart.image_validation_status)
    || metin(gorselDogrulamaNesnesi.status);
  const gorselHaklari = metin(gorsel.rights_status) || metin(kart.rights_status)
    || metin(gorselDogrulamaNesnesi.rights_status);
  const rowId = metin(item.row_id) || metin(item.rowId);
  const fatura = nesne(item.invoice_data) ? item.invoice_data : {};
  const eslesenBilgiler = doluDizi(dogrulama.matched_attributes, kart.matched_attributes);
  const eksikler = doluDizi(dogrulama.unmatched_attributes, kart.unmatched_attributes);
  return {
    rowId,
    hamSatirNo: sayi(kart.satir_no ?? item.satir_no),
    ad: metin(kart.title),
    marka: metin(kart.brand),
    barkod: metin(kart.barcode) || metin(item.barcode),
    kod: metin(kart.code) || metin(item.code),
    varyant: metin(kart.variant),
    beden: metin(item.beden ?? kart.size),
    adet: sayi(fatura.quantity ?? kart.net_quantity),
    alisFiyati: sayi(fatura.unit_price),
    resmiSayfa,
    gorselAdresi,
    gorselKaynakSayfa,
    aciklama: metin(kart.short_description),
    kategori: metin(kart.category_suggestion),
    dogrulamaDurumu: durum,
    dogrulanmis: durum === "verified" && Boolean(adres(resmiKaniti)),
    eslesenBilgiler,
    eksikler,
    gorselDogrulamaDurumu: gorselDogrulama,
    gorselHaklari,
    tekrarGrubu: metin(item.duplicate_group),
    kanonikRowId: metin(item.canonical_row_id),
    kartDurumu: item.card_status,
    kanit: { ...dogrulama, status: durum, official_product_url: adres(resmiKaniti), matched_attributes: eslesenBilgiler, unmatched_attributes: eksikler, media: { ...gorsel, image_url: gorselAdresi, source_url: gorselKaynakSayfa, verification_status: gorselDogrulama, rights_status: gorselHaklari }, card_status: item.card_status },
    kaynaklar: Array.isArray(item.sources) ? item.sources.filter(nesne) : [],
    ham: item,
  };
}


type Denetim = (deger: unknown) => boolean;
const diziMetin = (deger: unknown): boolean => Array.isArray(deger) && deger.every((x) => typeof x === "string");
const metinTipi = (deger: unknown): boolean => typeof deger === "string";
const metinVeyaNull = (deger: unknown): boolean => deger === null || metinTipi(deger);
const sayiVeyaNull = (deger: unknown): boolean => deger === null || (typeof deger === "number" && Number.isFinite(deger));
const tamSayi = (deger: unknown): boolean => typeof deger === "number" && Number.isInteger(deger);
const tamSayiVeyaNull = (deger: unknown): boolean => deger === null || tamSayi(deger);
const sabit = (...secenekler: string[]): Denetim => (deger) => typeof deger === "string" && secenekler.includes(deger);

function tamAlanlar(deger: unknown, alanlar: Record<string, Denetim>): boolean {
  if (!nesne(deger)) return false;
  const beklenen = Object.keys(alanlar);
  return Object.keys(deger).length === beklenen.length &&
    beklenen.every((anahtar) => Object.hasOwn(deger, anahtar) && alanlar[anahtar](deger[anahtar]));
}

const girdiSemasi = (deger: unknown): boolean => tamAlanlar(deger, {
  quantity: sayiVeyaNull, unit: metinVeyaNull, unit_price: sayiVeyaNull, total_amount: sayiVeyaNull,
});
const urunSemasi = (deger: unknown): boolean => tamAlanlar(deger, {
  title: metinTipi, brand: metinTipi, category_suggestion: metinVeyaNull,
  variant: metinVeyaNull, short_description: metinVeyaNull,
  consumer_sale_price: sayiVeyaNull, stock_quantity: tamSayiVeyaNull,
});
const dogrulamaSemasi = (deger: unknown): boolean => tamAlanlar(deger, {
  status: sabit("verified", "ambiguous", "not_found", "not_researched"),
  official_domain: metinVeyaNull, official_product_url: metinVeyaNull,
  matched_attributes: diziMetin, unmatched_attributes: diziMetin,
});
const gorselSemasi = (deger: unknown): boolean => tamAlanlar(deger, {
  image_url: metinVeyaNull, source_url: metinVeyaNull,
  verification_status: metinVeyaNull, rights_status: metinVeyaNull,
});
const satirSemasi = (deger: unknown): boolean => tamAlanlar(deger, {
  row_id: metinTipi, raw_invoice_line: metinTipi, brand: metinTipi,
  barcode: metinVeyaNull, code: metinVeyaNull, invoice_data: girdiSemasi,
  vixrex_product_json: urunSemasi, validation: dogrulamaSemasi,
  media: gorselSemasi, card_status: sabit("draft"),
  duplicate_group: metinVeyaNull, canonical_row_id: metinVeyaNull,
});
const ozetSemasi = (deger: unknown): boolean => tamAlanlar(deger, {
  total_rows: tamSayi, verified_count: tamSayi,
  draft_count: tamSayi, not_found_count: tamSayi,
});

function katiKartYanitiDogrula(kaynak: Kayit, beklenenSatirlar?: readonly string[]): string | null {
  if (!tamAlanlar(kaynak, { items: Array.isArray, summary: ozetSemasi })) return "items/summary şeması";
  const items = kaynak.items as unknown[];
  const ozet = kaynak.summary as { total_rows: number };
  if (!items.length || ozet.total_rows !== items.length) return "summary.total_rows";
  const gorulen = new Set<string>();
  const gruplar = new Map<string, Array<{ rowId: string; kanonik: string }>>();
  for (let i = 0; i < items.length; i++) {
    const deger = items[i];
    if (!satirSemasi(deger)) return `items[${i}] şeması`;
    const item = deger as Kayit;
    const rowId = item.row_id as string;
    const urun = item.vixrex_product_json as Kayit;
    if (urun.consumer_sale_price !== null || urun.stock_quantity !== null) return `items[${i}] satış fiyatı/stok`;
    if (!/^[1-9]\d*$/.test(rowId) || gorulen.has(rowId)) return `items[${i}].row_id`;
    gorulen.add(rowId);
    const grup = item.duplicate_group as string | null;
    const kanonik = item.canonical_row_id as string | null;
    if (grup !== null && (grup.length > 128 || grup.trim() !== grup || !grup)) {
      return `items[${i}].duplicate_group`;
    }
    if (grup === null && kanonik === null) continue;
    if (!grup || !kanonik || !/^[1-9]\d*$/.test(kanonik)) return `items[${i}].canonical_row_id`;
    gruplar.set(grup, [...(gruplar.get(grup) ?? []), { rowId, kanonik }]);
  }
  if (beklenenSatirlar &&
    (gorulen.size !== beklenenSatirlar.length || beklenenSatirlar.some((id) => !gorulen.has(id)))) {
    return "faturanın row_id kümesi";
  }
  for (const [grup, uyeler] of gruplar) {
    const idler = new Set(uyeler.map((u) => u.rowId));
    const kanonik = uyeler[0].kanonik;
    if (uyeler.length < 2 || !idler.has(kanonik) ||
      uyeler.some((u) => u.kanonik !== kanonik) ||
      !uyeler.some((u) => u.rowId === kanonik && u.kanonik === kanonik)) {
      return `duplicate_group ${grup}`;
    }
  }
  return null;
}

async function yanitMetni(cevap: Response): Promise<string> {
  const birlesik = await openrouterYanitiniOku(cevap);
  const icerik = birlesik?.choices?.[0]?.message?.content;
  return typeof icerik === "string" ? icerik : "";
}

export async function kartSozlesmesineCevir(hamCevap: unknown): Promise<KartSozlesmesi[]> {
  return (await kartYanitiniCoz(hamCevap)).kartlar;
}

export async function kartYanitiniCoz(
  hamCevap: unknown,
  secenekler: { beklenenSatirlar?: readonly string[]; eskiAkis?: boolean } = {},
): Promise<{ govde: unknown; kartlar: KartSozlesmesi[] }> {
  const metinCevap = hamCevap instanceof Response ? await yanitMetni(hamCevap) : typeof hamCevap === "string" ? hamCevap : "";
  const kaynak = metinCevap ? adayJson(metinCevap) : hamCevap;
  if (!nesne(kaynak) || !Array.isArray(kaynak.items)) {
    throw new KartSozlesmeHatasi(KART_SOZLESMESI_KODU, metinCevap || JSON.stringify(hamCevap ?? null));
  }
  const hamKayit = metinCevap || JSON.stringify(hamCevap ?? null);
  if (!secenekler.eskiAkis) {
    const hata = katiKartYanitiDogrula(kaynak, secenekler.beklenenSatirlar);
    if (hata) throw new KartSozlesmeHatasi(KART_SOZLESMESI_KODU, hamKayit, `Kart sözleşmesi geçersiz: ${hata}`);
  }
  const gorulen = new Set<string>();
  const kartlar: KartSozlesmesi[] = [];
  for (const item of kaynak.items) {
    if (!nesne(item)) continue;
    const kart = tekKartSozlesmesi(item);
    if (!kart.rowId || gorulen.has(kart.rowId)) continue;
    gorulen.add(kart.rowId);
    kartlar.push(kart);
  }
  if (!kartlar.length) {
    throw new KartSozlesmeHatasi(KART_SOZLESMESI_KODU, metinCevap || JSON.stringify(hamCevap ?? null));
  }
  return { govde: kaynak, kartlar };
}
