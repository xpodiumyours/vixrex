/** Fatura kart yanıtının tek sözleşmesi: biçim çözümü, alan eşanlamlıları ve kart alanları burada tanımlanır. */

import { openrouterYanitiniOku } from "@/lib/openrouterYanitAkisi";

type Kayit = Record<string, unknown>;

export const KART_SOZLESMESI_KODU = "KART_YANITI_COZULEMEDI";

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
  return Array.isArray(value) ? metin(value.find((v) => typeof v === "string")) : "";
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
  const durum = (metin(dogrulama.status) || metin(dogrulama.verification_status)
    || metin(item.verification_status) || metin(item.validation_status)
    || metin(item.match_status) || metin(item.status)) as KartDogrulamaDurumu;
  const resmiSayfa = metin(dogrulama.official_product_url) || metin(kart.official_product_url)
    || metin(kart.product_url) || metin(dogrulama.product_url);
  const gorselAdresi = metin(gorsel.image_url) || metin(kart.image_url) || ilkAdres(kart.image_urls);
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
    gorselKaynakSayfa: metin(gorsel.source_url) || metin(kart.source_url),
    aciklama: metin(kart.short_description),
    kategori: metin(kart.category_suggestion),
    dogrulamaDurumu: durum,
    dogrulanmis: durum === "verified" && Boolean(adres(resmiSayfa)),
    eslesenBilgiler,
    eksikler,
    gorselDogrulamaDurumu: metin(gorsel.verification_status) || metin(kart.image_validation_status),
    gorselHaklari: metin(gorsel.rights_status) || metin(kart.rights_status),
    tekrarGrubu: metin(item.duplicate_group),
    kanonikRowId: metin(item.canonical_row_id),
    kartDurumu: item.card_status,
    kanit: { ...dogrulama, status: durum, official_product_url: resmiSayfa, matched_attributes: eslesenBilgiler, unmatched_attributes: eksikler, media: { ...gorsel }, card_status: item.card_status },
    kaynaklar: Array.isArray(item.sources) ? item.sources.filter(nesne) : [],
    ham: item,
  };
}

async function yanitMetni(cevap: Response): Promise<string> {
  const birlesik = await openrouterYanitiniOku(cevap);
  const icerik = birlesik?.choices?.[0]?.message?.content;
  return typeof icerik === "string" ? icerik : "";
}

/** Model yanıtını (SSE ya da düz JSON; çitli, düz veya iç içe alan) kart sözleşmesine çevirir. */
export async function kartSozlesmesineCevir(hamCevap: unknown): Promise<KartSozlesmesi[]> {
  return (await kartYanitiniCoz(hamCevap)).kartlar;
}

export async function kartYanitiniCoz(hamCevap: unknown): Promise<{ govde: unknown; kartlar: KartSozlesmesi[] }> {
  const metinCevap = hamCevap instanceof Response ? await yanitMetni(hamCevap) : typeof hamCevap === "string" ? hamCevap : "";
  const kaynak = metinCevap ? adayJson(metinCevap) : hamCevap;
  if (!nesne(kaynak) || !Array.isArray(kaynak.items)) {
    throw new KartSozlesmeHatasi(KART_SOZLESMESI_KODU, metinCevap || JSON.stringify(hamCevap ?? null));
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
