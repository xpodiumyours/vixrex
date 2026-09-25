import { existsSync, readFileSync, readdirSync } from "node:fs";
import path from "node:path";

// Üretici/tedarikçi ürün kataloğu — faturadaki kodu firmanın kendi yayınladığı
// ürün bilgisine bağlar.
//
// Veri kaynağı: firmanın sitesinde herkese açık yayınladığı ürün verisi.
// Toplama betikleri: public_web/scripts/katalog/ (bkz. scripts/katalog/rapor.json)
// Katalog dosyaları: public_web/data/katalog/uretici-katalog-<firma>.json
//
// İki kural hiç değişmez:
//   1. TAHMİN YOK — eşleşme yalnız barkod veya model kodu birebir tuttuğunda
//      kurulur. Ada bakarak eşleştirme yapılmaz.
//   2. İZİN KAPISI — firmanın fotoğrafları ancak izinDurumu "var" olduğunda
//      kullanılır. İzin yoksa ürünün adı/açıklaması gelir, fotoğrafı gelmez.
//
// Kataloglar `src/` dışında tutulur ve ilk kullanımda diskten okunur: toplam
// hacim megabaytları bulduğu için Next.js paketine gömülmesi yanlış olur.
//
// NOT (büyüme): havuz daha da büyüdüğünde kataloglar veritabanına taşınmalı ve
// eşleşme indeksli sorguyla yapılmalıdır; dosya okuma her soğuk başlangıçta
// tüm katalogları belleğe alır.

export interface UreticiUrunu {
  kod: string;
  ad: string;
  marka: string;
  aciklama: string;
  barkod: string;
  gorseller: string[];
  kaynak: string;
}

export type IzinDurumu = "yok" | "bekliyor" | "var";

export interface UreticiFirmasi {
  anahtar: string;
  ad: string;
  alan: string;
  /** Firmanın görsel/veri kullanım izni. "var" olmadıkça fotoğraf kullanılmaz. */
  izinDurumu: IzinDurumu;
}

/**
 * Havuzdaki firmalar — İZİN LİSTESİ BURASIDIR.
 *
 * Bir firmaya yazılı izin alındığında yalnız buradaki `izinDurumu` "var"
 * yapılır; fotoğrafları o zaman kullanılmaya başlar. Katalog dosyası eksikse
 * firma eşleştirmeye girmez.
 */
const URETICILER: UreticiFirmasi[] = [
  { anahtar: "seher-mensucat", ad: "Seher Mensucat", alan: "sehermensucat.com", izinDurumu: "bekliyor" },
  { anahtar: "toptan-ic-giyim-pazari", ad: "Toptan İç Giyim Pazarı", alan: "toptanicgiyimpazari.com", izinDurumu: "yok" },
  { anahtar: "iste-canta", ad: "İşte Çanta", alan: "istecanta.com", izinDurumu: "yok" },
  { anahtar: "santral-gida", ad: "Santral Gıda", alan: "santralgida.com", izinDurumu: "yok" },
  { anahtar: "alireis-toptan-gida", ad: "Alireis Toptan Gıda", alan: "alireis.com", izinDurumu: "yok" },
  { anahtar: "berrak-icgiyim", ad: "Berrak İçGiyim", alan: "berrakicgiyim.com.tr", izinDurumu: "yok" },
  { anahtar: "erdem-icgiyim", ad: "Erdem İçGiyim", alan: "erdemicgiyim.com", izinDurumu: "yok" },
  { anahtar: "kinzi-toptan", ad: "Kinzi Toptan", alan: "kinzitoptan.com", izinDurumu: "yok" },
  { anahtar: "koza-icgiyim", ad: "Koza İçGiyim", alan: "kozaicgiyim.com", izinDurumu: "yok" },
  { anahtar: "sec-salca-konserve", ad: "Seç Salça Konserve", alan: "secsalca.com.tr", izinDurumu: "yok" },
  { anahtar: "kaya-zeytin-salih-kaya-gida", ad: "Kaya Zeytin (Salih Kaya Gıda)", alan: "kayazeytin.com.tr", izinDurumu: "yok" },
  { anahtar: "kul-gida", ad: "Kul Gıda", alan: "kulgida.com", izinDurumu: "yok" },
  { anahtar: "aycenk-gida", ad: "Aycenk Gıda", alan: "aycenk.com", izinDurumu: "yok" },
  { anahtar: "voltaj", ad: "Voltaj", alan: "voltaj.com.tr", izinDurumu: "yok" },
  { anahtar: "saphori", ad: "Saphori", alan: "saphori.com", izinDurumu: "yok" },
  { anahtar: "emek-toptan", ad: "Emek Toptan", alan: "emektoptan.com", izinDurumu: "yok" },
];

const DOSYA_DUZENI = /^uretici-katalog-(.+)\.json$/;

function katalogKlasoru(): string {
  const adaylar = [
    path.resolve(process.cwd(), "data", "katalog"),
    path.resolve(process.cwd(), "public_web", "data", "katalog"),
  ];
  return adaylar.find((yol) => existsSync(yol)) ?? adaylar[0];
}

/** Katalog dosyalarını diskten okur. Bozuk dosya tüm akışı durdurmaz. */
function kataloglariYukle(): Map<string, UreticiUrunu[]> {
  const harita = new Map<string, UreticiUrunu[]>();
  const klasor = katalogKlasoru();

  let dosyalar: string[] = [];
  try {
    dosyalar = readdirSync(klasor);
  } catch {
    return harita;
  }

  for (const dosya of dosyalar) {
    const eslesme = DOSYA_DUZENI.exec(dosya);
    if (!eslesme) continue;

    try {
      const icerik: unknown = JSON.parse(readFileSync(path.join(klasor, dosya), "utf8"));
      if (Array.isArray(icerik)) harita.set(eslesme[1], icerik as UreticiUrunu[]);
    } catch (hata) {
      // Sessizce yutmak yanlış olur: hangi dosyanın okunamadığı görünmeli.
      console.error(
        `[ureticiKatalog] ${dosya} okunamadı:`,
        hata instanceof Error ? hata.message : "bilinmeyen hata",
      );
    }
  }

  return harita;
}

function normalizeKod(value: string): string {
  return value.trim().toUpperCase().replace(/[\s._\-/]/g, "");
}

function normalizeBarkod(value: string): string {
  return value.replace(/\D/g, "");
}

interface Dizin {
  koda: Map<string, UreticiUrunu>;
  barkoda: Map<string, UreticiUrunu>;
  firma: UreticiFirmasi;
  gorselIzniVar: boolean;
}

let dizinlerOnbellek: Dizin[] | null = null;

function dizinler(): Dizin[] {
  if (dizinlerOnbellek) return dizinlerOnbellek;

  const kataloglar = kataloglariYukle();

  // Dosya adı ile firma anahtarı tutmazsa koca bir katalog sessizce
  // eşleştirme dışı kalır. Bu yüzden açıkça uyarılır.
  const taninmayan = [...kataloglar.keys()].filter(
    (anahtar) => !URETICILER.some((firma) => firma.anahtar === anahtar),
  );
  if (taninmayan.length > 0) {
    console.error(
      `[ureticiKatalog] firma listesinde karşılığı olmayan katalog dosyası: ${taninmayan.join(", ")} — bu ürünler eşleştirmeye girmiyor.`,
    );
  }

  dizinlerOnbellek = URETICILER.map((firma) => {
    const katalog = kataloglar.get(firma.anahtar) ?? [];
    const koda = new Map<string, UreticiUrunu>();
    const barkoda = new Map<string, UreticiUrunu>();

    for (const urun of katalog) {
      const kod = normalizeKod(urun.kod);
      if (kod && !koda.has(kod)) koda.set(kod, urun);

      const barkod = normalizeBarkod(urun.barkod ?? "");
      if (barkod.length >= 8 && !barkoda.has(barkod)) barkoda.set(barkod, urun);
    }

    return { koda, barkoda, firma, gorselIzniVar: firma.izinDurumu === "var" };
  });

  return dizinlerOnbellek;
}

/**
 * İzin kapısı: firmanın fotoğrafları yalnız izin "var" olduğunda geçer.
 * İzin yoksa ürünün diğer bilgileri korunur, fotoğraflar boşaltılır.
 */
export function gorselKapisi(urun: UreticiUrunu, izinDurumu: IzinDurumu): UreticiUrunu {
  return izinDurumu === "var" ? urun : { ...urun, gorseller: [] };
}

export interface KatalogEslesmesi {
  /** Katalogdaki ürün. Fotoğraflar izin kapısından geçmiştir. */
  urun: UreticiUrunu;
  firma: UreticiFirmasi;
  /** Eşleşmenin neye dayandığı. Kanıt olmadan eşleşme kurulmaz. */
  dayanak: "kod" | "barkod";
  /** Firmanın fotoğraf kullanım izni var mı. Yoksa `urun.gorseller` boştur. */
  gorselIzniVar: boolean;
}

/**
 * Faturadan okunan model kodu veya barkodu üretici kataloğunda arar.
 *
 * Sıra kanıt gücüne göredir: önce barkod (tek ürünü gösterir), sonra model
 * kodu. İkisi de tutmazsa eşleşme yoktur — ada bakarak tahmin yapılmaz.
 *
 * Fotoğraf yalnız firmanın izni "var" ise döner. Böylece izinsiz görsel
 * akışın hiçbir yerine sızamaz.
 */
export function ureticiUrunuBul(args: {
  model?: string | null;
  barkod?: string | null;
}): KatalogEslesmesi | null {
  const barkod = normalizeBarkod(args.barkod ?? "");
  const model = normalizeKod(args.model ?? "");

  const eslesme = (() => {
    if (barkod.length >= 8) {
      for (const dizin of dizinler()) {
        const urun = dizin.barkoda.get(barkod);
        if (urun) return { dizin, urun, dayanak: "barkod" as const };
      }
    }

    if (model.length >= 4) {
      for (const dizin of dizinler()) {
        const urun = dizin.koda.get(model);
        if (urun) return { dizin, urun, dayanak: "kod" as const };
      }
    }

    return null;
  })();

  if (!eslesme) return null;

  const { dizin, urun, dayanak } = eslesme;

  return {
    urun: gorselKapisi(urun, dizin.firma.izinDurumu),
    firma: dizin.firma,
    dayanak,
    gorselIzniVar: dizin.gorselIzniVar,
  };
}

/** Katalogdaki firma sayısı, ürün sayısı ve izin durumu — durum göstermek için. */
export function katalogOzeti(): Array<{
  anahtar: string;
  firma: string;
  urun: number;
  izin: IzinDurumu;
}> {
  return dizinler().map((dizin) => ({
    anahtar: dizin.firma.anahtar,
    firma: dizin.firma.ad,
    urun: dizin.koda.size,
    izin: dizin.firma.izinDurumu,
  }));
}
