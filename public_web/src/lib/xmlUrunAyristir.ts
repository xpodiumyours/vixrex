export interface XmlUrunKaydi {
  name: string;
  description: string;
  priceText: string;
  category: string;
  stockStatus: string;
  imageUrls: string[];
  brand: string | null;
}

export interface XmlHataliSatir {
  satir: number;
  mesaj: string;
}

export interface XmlAyristirmaSonuc {
  ok: boolean;
  hata?: string;
  urunler: XmlUrunKaydi[];
  hataliSatirlar: XmlHataliSatir[];
}

const URUN_ETIKETLERI = [
  "product",
  "urun",
  "item",
  "record",
  "entry",
  "ürün",
  "mahsul",
  "mal",
  "kalem",
  "stok",
];

const AD_TAKMALARI = [
  "urunadi",
  "urunad",
  "urun",
  "adi",
  "ad",
  "name",
  "urunname",
  "baslik",
  "title",
  "product",
  "productname",
  "isim",
  "adi ",
  "urunadii",
  "urun adi",
  "urun adı",
  "mahsul",
  "mal",
  "kalem",
  "stokadi",
  "stokname",
  "urununadi",
  "urunun adi",
  "urunun adı",
];

const FIYAT_TAKMALARI = [
  "fiyat",
  "price",
  "fiyatitl",
  "satisfiyati",
  "satis",
  "tutar",
  "amount",
  "saleprice",
  "alisfiyati",
  "listprice",
  "fiyat ",
  "fiyatidr",
  "fiyatı",
  "satis fiyati",
  "satis fiyatı",
  "fiyat bilgisi",
  "fiyatinfo",
];

const ACIKLAMA_TAKMALARI = [
  "aciklama",
  "description",
  "detay",
  "detail",
  "not",
  "note",
  "ozet",
  "summary",
  "aciklama ",
  "urunaciklama",
  "urun aciklamasi",
  "urun açıklaması",
  "aciklama bilgisi",
];

const KATEGORI_TAKMALARI = [
  "kategori",
  "category",
  "kat",
  "grup",
  "group",
  "turu",
  "type",
  "kategoriadi",
  "kategori adi",
  "kategori adı",
  "kategoriismi",
  "kategori ismi",
];

const STOK_TAKMALARI = [
  "stok",
  "stock",
  "stokdurumu",
  "stockstatus",
  "stokdurum",
  "stok ",
  "stokmiktari",
  "stok miktarı",
  "adet",
  "quantity",
  "miktar",
  "stok bilgisi",
];

const GORSEL_TAKMALARI = [
  "gorselurl",
  "gorsel",
  "imageurl",
  "image",
  "foto",
  "fotoğraf",
  "resim",
  "kapak",
  "cover",
  "gorsel ",
  "fotourl",
  "foto url",
  "resimurl",
  "gorseladresi",
  "görsel",
  "img",
  "src",
  "gorsel1",
  "gorsel2",
  "gorsel3",
  "image1",
  "image2",
  "foto1",
  "foto2",
  "resim1",
  "resim2",
];

const MARKA_TAKMALARI = ["brand", "marka", "markaadi", "marka adi", "marka adı", "uretici", "manufacturer"];

function etiketAdiNormallestir(deger: string): string {
  return deger
    .toLowerCase()
    .replace(/[üû]/g, "u")
    .replace(/[öo]/g, "o")
    .replace(/[çc]/g, "c")
    .replace(/[şs]/g, "s")
    .replace(/[ğg]/g, "g")
    .replace(/[iiî]/g, "i")
    .replace(/[^a-z0-9]/g, "");
}

function alanCikar(icerik: string): Record<string, string> {
  const alanlar: Record<string, string> = {};
  const desen = /<([^\/>]+)>([^<]*)<\/\1>/gi;
  for (const eslesme of icerik.matchAll(desen)) {
    const anahtar = (eslesme[1] ?? "").toLowerCase().trim();
    const deger = (eslesme[2] ?? "").trim();
    if (anahtar && deger) alanlar[anahtar] = deger;
  }
  return alanlar;
}

function urunOgeleriniCikar(xml: string): Array<Record<string, string>> {
  const ogeler: Array<Record<string, string>> = [];
  for (const etiket of URUN_ETIKETLERI) {
    const desen = new RegExp(`<${etiket}[^>]*>([\\s\\S]*?)</${etiket}>`, "gi");
    const eslesmeler = xml.matchAll(desen);
    let eslesmeVar = false;
    for (const eslesme of eslesmeler) {
      eslesmeVar = true;
      const alanlar = alanCikar(eslesme[1] ?? "");
      if (Object.keys(alanlar).length > 0) ogeler.push(alanlar);
    }
    if (eslesmeVar) break;
  }
  if (ogeler.length === 0) {
    const alanlar = alanCikar(xml);
    if (Object.keys(alanlar).length > 0) ogeler.push(alanlar);
  }
  return ogeler;
}

function alanBul(alanlar: Record<string, string>, takmalar: readonly string[]): string {
  for (const takma of takmalar) {
    for (const [anahtar, deger] of Object.entries(alanlar)) {
      if (etiketAdiNormallestir(anahtar) === takma) return deger;
    }
  }
  return "";
}

function gorselleriBul(alanlar: Record<string, string>): string[] {
  const adresler: string[] = [];
  for (const takma of GORSEL_TAKMALARI) {
    for (const [anahtar, deger] of Object.entries(alanlar)) {
      if (etiketAdiNormallestir(anahtar) !== takma) continue;
      const adres = deger.trim();
      if (adres && (adres.startsWith("http") || adres.startsWith("//"))) adresler.push(adres);
    }
  }
  return adresler.slice(0, 4);
}

function fiyatiNormallestir(ham: string): string {
  if (!ham) return "";
  let normal = ham
    .replace(/\b(TL|TRY|₺|tl|try)\b/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (!normal) return "";

  const sonVirgul = normal.lastIndexOf(",");
  const sonNokta = normal.lastIndexOf(".");

  if (sonVirgul !== -1 && sonNokta !== -1) {
    const ondalikAyiraci = sonVirgul > sonNokta ? "," : ".";
    const binlikAyiraci = ondalikAyiraci === "," ? "." : ",";
    normal = normal.split(binlikAyiraci).join("");
    if (ondalikAyiraci === ",") normal = normal.split(",").join(".");
  } else if (sonVirgul !== -1) {
    const parcalar = normal.split(",");
    if (parcalar.length === 2 && parcalar[1].length <= 2) {
      normal = normal.split(",").join(".");
    } else {
      normal = normal.split(",").join("");
    }
  }

  const sayi = Number(normal);
  if (!Number.isFinite(sayi)) return ham.trim();
  return sayi % 1 === 0 ? String(Math.trunc(sayi)) : sayi.toFixed(2);
}

function stokDurumuNormallestir(ham: string): string {
  const kucuk = ham.toLowerCase();
  if (
    kucuk === "0" ||
    kucuk.includes("tükendi") ||
    kucuk.includes("yok") ||
    kucuk.includes("out of stock") ||
    kucuk.includes("sold out")
  ) {
    return "Tükendi";
  }
  if (
    kucuk.includes("son") ||
    kucuk.includes("az") ||
    kucuk.includes("limit") ||
    kucuk.includes("low") ||
    kucuk.includes("hurry")
  ) {
    return "Son birkaç adet";
  }
  return "Mevcut";
}

function alanlardanUrunUret(
  alanlar: Record<string, string>,
  satir: number,
): { urun?: XmlUrunKaydi; hata?: XmlHataliSatir } {
  const ad = alanBul(alanlar, AD_TAKMALARI);
  if (!ad) {
    return { hata: { satir, mesaj: "Ürün adı bulunamadı, satır atlandı." } };
  }
  const aciklama = alanBul(alanlar, ACIKLAMA_TAKMALARI);
  const kategori = alanBul(alanlar, KATEGORI_TAKMALARI);
  const marka = alanBul(alanlar, MARKA_TAKMALARI);
  return {
    urun: {
      name: ad,
      description: aciklama,
      priceText: fiyatiNormallestir(alanBul(alanlar, FIYAT_TAKMALARI)),
      category: kategori || "Genel",
      stockStatus: stokDurumuNormallestir(alanBul(alanlar, STOK_TAKMALARI)),
      imageUrls: gorselleriBul(alanlar),
      brand: marka || null,
    },
  };
}

export function xmlAyristir(xmlIcerik: string): XmlAyristirmaSonuc {
  try {
    const ogeler = urunOgeleriniCikar(xmlIcerik);
    if (ogeler.length === 0) {
      return { ok: false, hata: "XML dosyasında ürün bulunamadı.", urunler: [], hataliSatirlar: [] };
    }
    const urunler: XmlUrunKaydi[] = [];
    const hataliSatirlar: XmlHataliSatir[] = [];
    ogeler.forEach((alanlar, indeks) => {
      const sonuc = alanlardanUrunUret(alanlar, indeks + 1);
      if (sonuc.urun) urunler.push(sonuc.urun);
      if (sonuc.hata) hataliSatirlar.push(sonuc.hata);
    });
    return { ok: true, urunler, hataliSatirlar };
  } catch {
    return { ok: false, hata: "XML okuma hatası.", urunler: [], hataliSatirlar: [] };
  }
}
