import seherKatalog from "@/data/uretici-katalog-seher.json";

// Üretici ürün kataloğu — faturadaki kodu üreticinin kendi yayınladığı
// ürün bilgisine bağlar.
//
// Veri kaynağı: üreticinin sitesinde herkese açık yayınladığı yapılandırılmış
// ürün verisi (JSON-LD). Tahmin yok: yalnız kod birebir tuttuğunda eşleşir.
//
// Bu dosya yalnız sunucuda okunur; 200 KB'lık katalog tarayıcıya inmez.

export interface UreticiUrunu {
  kod: string;
  ad: string;
  marka: string;
  aciklama: string;
  barkod: string;
  gorseller: string[];
  kaynak: string;
}

export interface UreticiFirmasi {
  anahtar: string;
  ad: string;
  alan: string;
  /** Üreticinin görsel/veri kullanım izni. Alınmadıkça görsel kullanılmaz. */
  izinDurumu: "yok" | "bekliyor" | "var";
}

const FIRMALAR: UreticiFirmasi[] = [
  {
    anahtar: "seher-mensucat",
    ad: "Seher Mensucat",
    alan: "sehermensucat.com",
    izinDurumu: "bekliyor",
  },
];

const KATALOGLAR: Record<string, UreticiUrunu[]> = {
  "seher-mensucat": seherKatalog as UreticiUrunu[],
};

function normalizeKod(value: string): string {
  return value.trim().toUpperCase().replace(/[\s._-]/g, "");
}

function normalizeBarkod(value: string): string {
  return value.replace(/\D/g, "");
}

interface Dizin {
  koda: Map<string, UreticiUrunu>;
  barkoda: Map<string, UreticiUrunu>;
  firma: UreticiFirmasi;
}

let dizinlerOnbellek: Dizin[] | null = null;

function dizinler(): Dizin[] {
  if (dizinlerOnbellek) return dizinlerOnbellek;

  dizinlerOnbellek = FIRMALAR.map((firma) => {
    const urunler = KATALOGLAR[firma.anahtar] ?? [];
    const koda = new Map<string, UreticiUrunu>();
    const barkoda = new Map<string, UreticiUrunu>();

    for (const urun of urunler) {
      const kod = normalizeKod(urun.kod);
      if (kod && !koda.has(kod)) koda.set(kod, urun);

      const barkod = normalizeBarkod(urun.barkod ?? "");
      if (barkod.length >= 8 && !barkoda.has(barkod)) barkoda.set(barkod, urun);
    }

    return { koda, barkoda, firma };
  });

  return dizinlerOnbellek;
}

export interface KatalogEslesmesi {
  urun: UreticiUrunu;
  firma: UreticiFirmasi;
  /** Eşleşmenin neye dayandığı. Kanıt olmadan eşleşme kurulmaz. */
  dayanak: "kod" | "barkod";
}

/**
 * Faturadan okunan model kodu veya barkodu üretici kataloğunda arar.
 *
 * Sıra kanıt gücüne göredir: önce barkod (tek ürünü gösterir), sonra model
 * kodu. İkisi de tutmazsa eşleşme yoktur — ada bakarak tahmin yapılmaz.
 */
export function ureticiUrunuBul(args: {
  model?: string | null;
  barkod?: string | null;
}): KatalogEslesmesi | null {
  const barkod = normalizeBarkod(args.barkod ?? "");
  const model = normalizeKod(args.model ?? "");

  for (const dizin of dizinler()) {
    if (barkod.length >= 8) {
      const urun = dizin.barkoda.get(barkod);
      if (urun) return { urun, firma: dizin.firma, dayanak: "barkod" };
    }
  }

  for (const dizin of dizinler()) {
    if (model.length >= 4) {
      const urun = dizin.koda.get(model);
      if (urun) return { urun, firma: dizin.firma, dayanak: "kod" };
    }
  }

  return null;
}

/** Katalogdaki firma sayısı ve ürün sayısı — durum göstermek için. */
export function katalogOzeti(): Array<{ firma: string; urun: number; izin: string }> {
  return dizinler().map((dizin) => ({
    firma: dizin.firma.ad,
    urun: dizin.koda.size,
    izin: dizin.firma.izinDurumu,
  }));
}
