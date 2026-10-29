export interface KategoriBirlesimi {
  anahtar: string;
  ad: string;
}

const ANA_KATEGORILER = new Set([
  "gıda",
  "içecek",
  "atıştırmalık",
  "süt ürünleri",
  "temel gıda",
  "temizlik",
  "deterjan",
  "kişisel bakım",
  "kozmetik",
  "meyve & sebze",
  "et & şarküteri",
  "donuk",
  "oyuncak",
  "kırtasiye",
  "ev & yaşam",
  "elektronik",
  "giyim",
  "ayakkabı",
  "aksesuar",
  "telefon",
]);

const ALT_ESLESMELERI: Array<{ eslesme: string; ana: string; alt: string }> = [
  { eslesme: "çikolata kaplı gofret", ana: "Atıştırmalık", alt: "Gofret" },
  { eslesme: "enerji içeceği", ana: "İçecek", alt: "Enerji İçeceği" },
  { eslesme: "gazlı içecek", ana: "İçecek", alt: "Gazlı İçecek" },
  { eslesme: "meyve suyu", ana: "İçecek", alt: "Meyve Suyu" },
  { eslesme: "bitki çay", ana: "İçecek", alt: "Çay" },
  { eslesme: "siyah çay", ana: "İçecek", alt: "Çay" },
  { eslesme: "çay", ana: "İçecek", alt: "Çay" },
  { eslesme: "türk kahve", ana: "İçecek", alt: "Kahve" },
  { eslesme: "şekerleme", ana: "Atıştırmalık", alt: "Şekerleme" },
  { eslesme: "tereyağı", ana: "Süt Ürünleri", alt: "Tereyağı" },
  { eslesme: "zeytinyağı", ana: "Gıda", alt: "Zeytinyağı" },
  { eslesme: "çikolata", ana: "Atıştırmalık", alt: "Çikolata" },
  { eslesme: "bisküvi", ana: "Atıştırmalık", alt: "Bisküvi" },
  { eslesme: "gofret", ana: "Atıştırmalık", alt: "Gofret" },
  { eslesme: "kraker", ana: "Atıştırmalık", alt: "Kraker" },
  { eslesme: "çerez", ana: "Atıştırmalık", alt: "Çerez" },
  { eslesme: "kaymak", ana: "Süt Ürünleri", alt: "Kaymak" },
  { eslesme: "yoğurt", ana: "Süt Ürünleri", alt: "Yoğurt" },
  { eslesme: "peynir", ana: "Süt Ürünleri", alt: "Peynir" },
  { eslesme: "ayran", ana: "Süt Ürünleri", alt: "Ayran" },
  { eslesme: "makarna", ana: "Gıda", alt: "Makarna" },
  { eslesme: "salça", ana: "Gıda", alt: "Salça" },
  { eslesme: "yumurta", ana: "Gıda", alt: "Yumurta" },
  { eslesme: "şeker", ana: "Gıda", alt: "Şeker" },
  { eslesme: "reçel", ana: "Gıda", alt: "Reçel" },
  { eslesme: "pirinç", ana: "Gıda", alt: "Pirinç" },
  { eslesme: "bulgur", ana: "Gıda", alt: "Bulgur" },
  { eslesme: "kahve", ana: "İçecek", alt: "Kahve" },
  { eslesme: "cips", ana: "Atıştırmalık", alt: "Cips" },
  { eslesme: "kek", ana: "Atıştırmalık", alt: "Kek" },
  { eslesme: "süt", ana: "Süt Ürünleri", alt: "Süt" },
];

function parcalar(ham: string): string[] {
  return String(ham || "")
    .replace(/\([^)]*\)/g, " ")
    .split(/[>/&|,+]+/)
    .map((parca) => parca.replace(/\s+/g, " ").trim())
    .filter(Boolean);
}

function altDizeEslesir(kucuk: string, altDize: string): boolean {
  let yer = kucuk.indexOf(altDize);
  while (yer >= 0) {
    const onceki = yer === 0 ? " " : kucuk[yer - 1];
    const sonraki = kucuk[yer + altDize.length] ?? " ";
    const onceHarf = /\p{L}/u.test(onceki);
    const sonHarf = /\p{L}/u.test(sonraki);
    if (!onceHarf && (!sonHarf || "aeıioöuü".includes(sonraki))) return true;
    yer = kucuk.indexOf(altDize, yer + 1);
  }
  return false;
}

function kucult(metin: string): string {
  return metin
    .toLocaleLowerCase("tr-TR")
    .replace(/\s+/g, " ")
    .trim();
}

interface Eslesme {
  tur: "alt" | "ana" | "bilinmeyen";
  anahtarParcalar: string[];
  ad: string;
}

function parcaEslesmesi(parca: string): Eslesme {
  const kucuk = kucult(parca);
  for (const kayit of ALT_ESLESMELERI) {
    if (kucult(kayit.eslesme) === kucuk) {
      return {
        tur: "alt",
        anahtarParcalar: [kucult(kayit.ana), kucult(kayit.alt)],
        ad: `${kayit.ana} / ${kayit.alt}`,
      };
    }
  }
  if (ANA_KATEGORILER.has(kucuk)) {
    return { tur: "ana", anahtarParcalar: [kucuk], ad: parca };
  }
  for (const kayit of ALT_ESLESMELERI) {
    if (altDizeEslesir(kucuk, kucult(kayit.eslesme))) {
      return {
        tur: "alt",
        anahtarParcalar: [kucult(kayit.ana), kucult(kayit.alt)],
        ad: `${kayit.ana} / ${kayit.alt}`,
      };
    }
  }
  return { tur: "bilinmeyen", anahtarParcalar: [kucuk], ad: parca };
}

function anahtarUret(parcalar: string[]): string {
  return [...new Set(parcalar.map(kucult))].sort().join(" | ");
}

export function kategoriAnahtari(ham: string): string {
  return kategoriBirlestir(ham).anahtar;
}

export function kategoriBirlestir(ham: string): KategoriBirlesimi {
  const hamParcalar = parcalar(ham);
  if (hamParcalar.length === 0) return { anahtar: "", ad: "" };

  const eslesmeler = hamParcalar.map((parca) => parcaEslesmesi(parca));
  const altAdaylar = eslesmeler
    .map((eslesme, sira) => ({ eslesme, sira }))
    .filter(({ eslesme }) => eslesme.tur === "alt");
  const sirali = [...altAdaylar].sort((a, b) => {
    const fark = b.eslesme.anahtarParcalar.join(" ").length - a.eslesme.anahtarParcalar.join(" ").length;
    return fark !== 0 ? fark : a.eslesme.ad.localeCompare(b.eslesme.ad, "tr");
  });
  const secili =
    sirali.find(({ eslesme, sira }) =>
      hamParcalar.some(
        (parca, digerSira) =>
          digerSira !== sira && kucult(parca) === eslesme.anahtarParcalar[0],
      ),
    ) ?? sirali[0];

  if (secili) {
    return { anahtar: anahtarUret(secili.eslesme.anahtarParcalar), ad: secili.eslesme.ad };
  }

  const anaAday = eslesmeler.find((eslesme) => eslesme.tur === "ana");
  if (anaAday) {
    const digerleri = eslesmeler.filter((eslesme) => eslesme !== anaAday);
    return {
      anahtar: anahtarUret([anaAday.ad, ...digerleri.map((eslesme) => eslesme.ad)]),
      ad: [anaAday, ...digerleri].map((eslesme) => eslesme.ad).join(" / "),
    };
  }

  return {
    anahtar: anahtarUret(eslesmeler.map((eslesme) => eslesme.ad)),
    ad: eslesmeler.map((eslesme) => eslesme.ad).join(" / "),
  };
}
