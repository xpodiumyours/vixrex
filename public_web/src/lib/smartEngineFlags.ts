export const VIXREX_SMART_ENGINE_FLAG = "vixrex_smart_engine_enabled";
export const VIXREX_SMART_ENGINE_STOREFRONT_FLAG =
  "vixrex_smart_engine_storefront_enabled";

export const SMART_ENGINE_DISABLED_MESSAGE =
  "Vixrex Akıllı Motor şu anda kapalı. Vitrindeki alanı seçerek düzenlemeye devam edebilirsin.";

export interface SmartEngineFlagRow {
  flag_key?: unknown;
  is_enabled?: unknown;
}

/**
 * Fail-closed: iki capability satırı da açık değilse storefront motoru çalışmaz.
 * Eksik/bozuk/unknown satır hiçbir zaman true üretmez.
 */
export function smartEngineStorefrontEnabledFromRows(
  rows: readonly SmartEngineFlagRow[] | null | undefined
): boolean {
  if (!rows) return false;

  const flags = new Map<string, boolean>();
  for (const row of rows) {
    if (typeof row.flag_key !== "string" || typeof row.is_enabled !== "boolean") {
      continue;
    }
    flags.set(row.flag_key, row.is_enabled);
  }

  return (
    flags.get(VIXREX_SMART_ENGINE_FLAG) === true &&
    flags.get(VIXREX_SMART_ENGINE_STOREFRONT_FLAG) === true
  );
}
