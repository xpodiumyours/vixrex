/**
 * PR3-C9: Güvenli dönüş hedefi allowlist
 * Açık yönlendirme açığını kapatır. Yalnız izin verilen
 * internal path'lere izin verir; aksi halde /app döner.
 */

const ALLOWLIST_PREFIXES = [
  "/app",
  "/v/",
  "/kesfet",
  "/legal",
  "/privacy",
  "/yardim",
  "/hakkimizda",
  "/iletisim",
  "/blog",
] as const;

const ALLOWLIST_EXACT = new Set<string>([
  "/",
  "/app",
  "/kesfet",
  "/giris",
  "/kayit",
  "/legal",
  "/privacy",
]);

export function guvenliDonusYolu(aday: string | null): string {
  if (!aday || !aday.startsWith("/") || aday.startsWith("//")) return "/app";
  // query ve hash'i ayır, sadece path'e bak
  const path = aday.split("?")[0]!.split("#")[0]!;
  if (ALLOWLIST_EXACT.has(path)) return aday;
  for (const prefix of ALLOWLIST_PREFIXES) {
    if (path === prefix || path.startsWith(prefix + "/") || path.startsWith(prefix + "?") || path.startsWith(prefix)) {
      // /v/ için ek kontrol: /v/:slug olmalı, boş değil
      if (prefix === "/v/" && path === "/v/") return "/app";
      return aday;
    }
  }
  return "/app";
}
