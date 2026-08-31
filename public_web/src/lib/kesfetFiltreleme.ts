import type { BusinessTemplateGroup } from "./businessCategories";

export type KesfetFiltreleri = {
  sorgu: string;
  grup: BusinessTemplateGroup | undefined;
  kategoriKimligi: string | null;
  sadeceFavoriler: boolean;
  favoriAdlari: readonly string[];
  sadeceKiralik: boolean;
};

export type FiltrelenebilirVitrin = {
  ad: string;
  aciklama: string;
  kategoriEtiketi: string;
  kategoriKimligi: string | null;
  konum: string;
  urunAdlari: string[];
  kiralikMi: boolean;
};

function aramaMetni(deger: string): string {
  return deger.trim().toLocaleLowerCase("tr-TR");
}

export function kesfetVitrinleriniFiltrele<T extends FiltrelenebilirVitrin>(
  vitrinler: readonly T[],
  filtreler: KesfetFiltreleri,
  kategoriGruplari: ReadonlyMap<string, BusinessTemplateGroup>
): T[] {
  const aranan = aramaMetni(filtreler.sorgu);

  return vitrinler.filter((vitrin) => {
    if (filtreler.sadeceKiralik && !vitrin.kiralikMi) return false;
    if (
      filtreler.grup !== undefined &&
      (!vitrin.kategoriKimligi ||
        kategoriGruplari.get(vitrin.kategoriKimligi) !== filtreler.grup)
    ) {
      return false;
    }
    if (
      filtreler.kategoriKimligi &&
      vitrin.kategoriKimligi !== filtreler.kategoriKimligi
    ) {
      return false;
    }
    if (
      filtreler.sadeceFavoriler &&
      !filtreler.favoriAdlari.includes(vitrin.ad)
    ) {
      return false;
    }
    if (!aranan) return true;

    return [
      vitrin.ad,
      vitrin.aciklama,
      vitrin.kategoriEtiketi,
      vitrin.konum,
      ...vitrin.urunAdlari,
    ].some((deger) => aramaMetni(deger).includes(aranan));
  });
}
