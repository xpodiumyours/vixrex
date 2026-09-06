export const VIXREX_SMART_ENGINE_FLAG = "vixrex_smart_engine_enabled";
export const VIXREX_SMART_ENGINE_STOREFRONT_FLAG =
  "vixrex_smart_engine_storefront_enabled";
export const VIXREX_SMART_ENGINE_BLOG_FLAG =
  "vixrex_smart_engine_blog_enabled";

export const SMART_ENGINE_DISABLED_MESSAGE =
  "Vixrex Akıllı Motor şu anda kapalı. Vitrindeki alanı seçerek düzenlemeye devam edebilirsin.";
export const BLOG_ENGINE_DISABLED_MESSAGE =
  "Vixrex Blog komutları şu anda kapalı. Blog Yönetimi ekranından devam edebilirsin.";

export interface SmartEngineFlagRow {
  flag_key?: unknown;
  is_enabled?: unknown;
}

function smartEngineFlagsFromRows(
  rows: readonly SmartEngineFlagRow[] | null | undefined
): Map<string, boolean> | null {
  if (!rows) return null;

  const flags = new Map<string, boolean>();
  for (const row of rows) {
    if (typeof row.flag_key !== "string" || typeof row.is_enabled !== "boolean") {
      continue;
    }
    flags.set(row.flag_key, row.is_enabled);
  }
  return flags;
}

/**
 * Fail-closed: global + storefront capability birlikte açık değilse storefront
 * motoru çalışmaz. Eksik/bozuk/unknown satır hiçbir zaman true üretmez.
 */
export function smartEngineStorefrontEnabledFromRows(
  rows: readonly SmartEngineFlagRow[] | null | undefined
): boolean {
  const flags = smartEngineFlagsFromRows(rows);
  if (!flags) return false;
  return (
    flags.get(VIXREX_SMART_ENGINE_FLAG) === true &&
    flags.get(VIXREX_SMART_ENGINE_STOREFRONT_FLAG) === true
  );
}

/** Blog domain de global + kendi capability flag'i ile fail-closed açılır. */
export function smartEngineBlogEnabledFromRows(
  rows: readonly SmartEngineFlagRow[] | null | undefined
): boolean {
  const flags = smartEngineFlagsFromRows(rows);
  if (!flags) return false;
  return (
    flags.get(VIXREX_SMART_ENGINE_FLAG) === true &&
    flags.get(VIXREX_SMART_ENGINE_BLOG_FLAG) === true
  );
}
