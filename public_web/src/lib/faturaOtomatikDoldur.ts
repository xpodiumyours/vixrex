import { productAttributesForTemplate } from "@/lib/productAttributeSchema";

export interface OtomatikKategori {
  id: string;
  name: string;
  product_template_key?: string | null;
}

const ANAHTAR_KELIMELER: Record<string, string[]> = {
  fashion: [
    "takim", "tisort", "pantolon", "gomlek", "elbise", "etek", "corap", "atlet", "boxer", "kulot",
    "sweat", "mont", "ceket", "kazak", "hirka", "pijama", "esofman", "sort", "bluz", "tayt",
    "mayo", "bere", "sal", "termal", "penye", "interlok", "sutyen", "body",
  ],
  food: [
    "biskuvi", "cikolata", "gofret", "cay", "kahve", "makarna", "seker", "yag", "sut", "gida",
    "cips", "kraker", "konserve", "salca", "bakliyat", "pirinc", "bulgur", "recel", "bal",
    "kek", "sos", "tuz", "baharat", "corba", "icecek", "meyve", "sebze",
  ],
  beauty: [
    "sampuan", "krem", "parfum", "deodorant", "dis macunu", "ruj", "sac", "cilt", "tiras",
    "kolonya", "losyon", "makyaj", "oje",
  ],
  home: [
    "deterjan", "temizlik", "camasir", "sabun", "havlu", "nevresim", "carsaf", "battaniye",
    "yastik", "perde", "bardak", "tabak", "tencere", "supurge", "cop", "pecete", "mendil",
  ],
  electronics: ["kulaklik", "sarj", "kablo", "pil", "telefon", "adaptor", "hoparlor", "ampul"],
  automotive: ["oto", "lastik", "motor yagi", "silecek", "akü", "aku"],
};

function sadelestir(ham: string): string {
  return ham
    .toLocaleLowerCase("tr-TR")
    .replace(/ç/g, "c")
    .replace(/ğ/g, "g")
    .replace(/ı/g, "i")
    .replace(/ö/g, "o")
    .replace(/ş/g, "s")
    .replace(/ü/g, "u")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function sablonTahmini(metin: string): string | null {
  const sade = ` ${sadelestir(metin)} `;
  let enIyi: string | null = null;
  let enYuksek = 0;
  for (const [sablon, kelimeler] of Object.entries(ANAHTAR_KELIMELER)) {
    const puan = kelimeler.filter((kelime) => sade.includes(` ${kelime}`)).length;
    if (puan > enYuksek) {
      enYuksek = puan;
      enIyi = sablon;
    }
  }
  return enIyi;
}

export function kategoriSec(
  satir: { ad: string; marka?: string; resmiAd?: string },
  kategoriler: OtomatikKategori[],
): string {
  if (kategoriler.length === 0) return "";
  const metin = [satir.resmiAd, satir.ad, satir.marka].filter(Boolean).join(" ");

  const sade = ` ${sadelestir(metin)} `;
  const adEslesmesi = kategoriler.find((kategori) => {
    const kategoriAdi = sadelestir(kategori.name);
    return kategoriAdi.length >= 4 && sade.includes(` ${kategoriAdi}`);
  });
  if (adEslesmesi) return adEslesmesi.id;

  const sablon = sablonTahmini(metin);
  if (sablon) {
    const sablonEslesmesi = kategoriler.find((kategori) => kategori.product_template_key === sablon);
    if (sablonEslesmesi) return sablonEslesmesi.id;
  }
  return kategoriler[0].id;
}

export interface OtomatikOzellik {
  key: string;
  value: string;
}

const CINSIYET: Array<[RegExp, string]> = [
  [/\bunisex\b/, "unisex"],
  [/\b(cocuk|bebek)\b/, "cocuk"],
  [/\b(kadin|bayan)\b/, "kadin"],
  [/\berkek\b/, "erkek"],
];

const NET_MIKTAR = /(\d+(?:[.,]\d+)?)\s?(kg|gr|g|ml|lt|l|cl)\b/;

export function otomatikOzellikler(
  satir: { ad: string; resmiAd?: string; varyant?: string; beden?: string },
  sablonAnahtari: string | null | undefined,
): OtomatikOzellik[] {
  const gecerli = new Set(productAttributesForTemplate(sablonAnahtari).map((ozellik) => ozellik.key));
  const sade = sadelestir([satir.resmiAd, satir.ad].filter(Boolean).join(" "));
  const sonuc: OtomatikOzellik[] = [];

  if (gecerli.has("gender")) {
    const eslesen = CINSIYET.find(([kalip]) => kalip.test(sade));
    if (eslesen) sonuc.push({ key: "gender", value: eslesen[1] });
  }
  if (gecerli.has("netQuantity")) {
    const miktar = NET_MIKTAR.exec(sade);
    if (miktar) sonuc.push({ key: "netQuantity", value: `${miktar[1].replace(",", ".")} ${miktar[2]}` });
  }
  return sonuc;
}
