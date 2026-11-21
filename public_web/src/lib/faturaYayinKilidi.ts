export interface FaturaSahipGirdisi {
  priceAmount: number | null | undefined;
  stockQuantity: number | null | undefined;
  mevcutOwnerState: Record<string, unknown> | null;
  mevcutFaturaKanit: Record<string, unknown> | null;
}

export interface FaturaSahipSonucu {
  ownerState: Record<string, unknown>;
  faturaKanitGuncellemesi: Record<string, unknown>;
}

export function faturaSahipGuncellemesi(
  girdi: FaturaSahipGirdisi,
): FaturaSahipSonucu | null {
  const { priceAmount, stockQuantity, mevcutOwnerState, mevcutFaturaKanit } = girdi;
  if (priceAmount == null || priceAmount <= 0) return null;
  if (stockQuantity == null) return null;
  if (stockQuantity < 0) return null;

  return {
    ownerState: {
      ...mevcutOwnerState,
      satisFiyati: String(priceAmount),
      stok: stockQuantity,
      onayli: true,
    },
    faturaKanitGuncellemesi: {
      ...mevcutFaturaKanit,
      esnafOnayladi: true,
    },
  };
}
