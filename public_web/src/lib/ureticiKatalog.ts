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
 * Havuzdaki firmalar — İZİN LİSTESİ TEK KAYNAKTAN GELİR.
 *
 * Görsel/veri kullanım izni yalnız `scripts/katalog/firmalar.json` içinde
 * tutulur; oradan `data/katalog/_firmalar.json` üretilir (üreteç:
 * `scripts/katalog/izin-listesi-uret.mjs`). Buraya elle firma yazılmaz —
 * yazılırsa izin iki yerde tutulur ve biri unutulup izinsiz fotoğraf sızar.
 *
 * Bir firmaya yazılı izin alındığında `firmalar.json` içinde `izin` alanı
 * "var" yapılır ve üreteç yeniden koşulur.
 */
function firmalariYukle(): UreticiFirmasi[] {
  const yol = path.join(katalogKlasoru(), "_firmalar.json");
  try {
    const icerik: unknown = JSON.parse(readFileSync(yol, "utf8"));
    if (!Array.isArray(icerik)) throw new Error("liste bekleniyordu");
    return icerik.map((ham) => {
      const firma = ham as Partial<UreticiFirmasi>;
      // Tanınmayan izin değeri asla "var" sayılmaz; güvenli tarafa düşülür.
      const izinDurumu: IzinDurumu =
        firma.izinDurumu === "var" || firma.izinDurumu === "bekliyor" ? firma.izinDurumu : "yok";
      return {
        anahtar: String(firma.anahtar ?? ""),
        ad: String(firma.ad ?? ""),
        alan: String(firma.alan ?? ""),
        izinDurumu,
      };
    });
  } catch (hata) {
    // Liste okunamazsa hiçbir firma eşleştirmeye girmez. Bu bilinçli: izin
    // bilgisi olmadan eşleşme kurmak, izinsiz görseli yayına açma riskidir.
    console.error(
      `[ureticiKatalog] izin listesi okunamadi (${yol}):`,
      hata instanceof Error ? hata.message : "bilinmeyen hata",
    );
    return [];
  }
}

let ureticilerOnbellek: UreticiFirmasi[] | null = null;

function ureticiler(): UreticiFirmasi[] {
  if (!ureticilerOnbellek) ureticilerOnbellek = firmalariYukle();
  return ureticilerOnbellek;
}

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
    (anahtar) => !ureticiler().some((firma) => firma.anahtar === anahtar),
  );
  if (taninmayan.length > 0) {
    console.error(
      `[ureticiKatalog] firma listesinde karşılığı olmayan katalog dosyası: ${taninmayan.join(", ")} — bu ürünler eşleştirmeye girmiyor.`,
    );
  }

  dizinlerOnbellek = ureticiler().map((firma) => {
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

let izinsizGorsellerOnbellek: Set<string> | null = null;

/**
 * İzni olmayan firmaların katalogdaki bütün fotoğraf adresleri.
 *
 * `gorselKapisi` eşleştirme sırasında fotoğrafı zaten boşaltır; bu küme ikinci
 * ve asıl savunmadır: tarayıcıdan gelen istek, adresi başka yoldan öğrenip
 * doğrudan yayın ucuna gönderse bile sunucu onu tanır ve durdurur.
 */
function izinsizGorseller(): Set<string> {
  if (izinsizGorsellerOnbellek) return izinsizGorsellerOnbellek;

  const kume = new Set<string>();
  const kataloglar = kataloglariYukle();

  for (const firma of ureticiler()) {
    if (firma.izinDurumu === "var") continue;
    for (const urun of kataloglar.get(firma.anahtar) ?? []) {
      for (const adres of urun.gorseller ?? []) {
        const temiz = adres.trim();
        if (temiz) kume.add(temiz);
      }
    }
  }

  izinsizGorsellerOnbellek = kume;
  return kume;
}

/**
 * Bu fotoğraf adresi, görsel izni olmayan bir üreticinin kataloğundan mı?
 *
 * Esnafın kendi çektiği fotoğraf bu kümede olmadığı için serbestçe geçer.
 */
export function izinsizUreticiGorseli(adres: unknown): boolean {
  return typeof adres === "string" && izinsizGorseller().has(adres.trim());
}
