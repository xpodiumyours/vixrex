export type FiyatAyarModu =
  | "setExact"
  | "increasePercent"
  | "decreasePercent"
  | "increaseAmount"
  | "decreaseAmount";

export function fiyatAyristir(ham: string): number | null {
  let temiz = ham.trim().replace(/[^\d,.]/g, "");
  if (!temiz) return null;
  if (temiz.includes(",") && temiz.includes(".")) {
    temiz = temiz.split(".").join("").split(",").join(".");
  } else if (temiz.includes(",")) {
    temiz = temiz.split(",").join(".");
  }
  const sayi = Number(temiz);
  return Number.isFinite(sayi) ? sayi : null;
}

export function fiyatBicimle(tutar: number): string {
  const yuvarli = Number(tutar.toFixed(2));
  const tamKisim = Math.trunc(yuvarli);
  const kesirKisim = Math.abs(Math.round((yuvarli - tamKisim) * 100));
  const tamMetin = Math.abs(tamKisim)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  const isaret = yuvarli < 0 ? "-" : "";
  return `${isaret}${tamMetin},${kesirKisim.toString().padStart(2, "0")} TL`;
}

export interface FiyatUrunGirdisi {
  id: string;
  priceText: string;
}

export interface FiyatUygulaSonuc {
  guncellenen: Array<{ id: string; priceText: string }>;
  atlanan: string[];
}

export function fiyatUygula(
  urunler: FiyatUrunGirdisi[],
  mod: FiyatAyarModu,
  deger: number,
): FiyatUygulaSonuc {
  const guncellenen: Array<{ id: string; priceText: string }> = [];
  const atlanan: string[] = [];

  for (const urun of urunler) {
    if (mod === "setExact") {
      guncellenen.push({ id: urun.id, priceText: fiyatBicimle(deger) });
      continue;
    }
    const mevcut = fiyatAyristir(urun.priceText);
    if (mevcut === null) {
      atlanan.push(urun.id);
      continue;
    }
    let sonraki: number;
    if (mod === "increasePercent") sonraki = mevcut * (1 + deger / 100);
    else if (mod === "decreasePercent") sonraki = mevcut * (1 - deger / 100);
    else if (mod === "increaseAmount") sonraki = mevcut + deger;
    else sonraki = mevcut - deger;
    guncellenen.push({ id: urun.id, priceText: fiyatBicimle(sonraki < 0 ? 0 : sonraki) });
  }

  return { guncellenen, atlanan };
}
