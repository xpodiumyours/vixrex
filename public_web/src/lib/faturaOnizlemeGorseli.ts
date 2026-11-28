export function onizlemeKartiGorseli(adres: unknown): string | null {
  if (typeof adres !== "string") return null;
  const temiz = adres.trim();
  if (!temiz) return null;
  try {
    const url = new URL(temiz);
    if (url.protocol !== "https:") return null;
    // Eski Supabase depo adresleri (path ile birlikte doğrulanır).
    if (url.hostname.endsWith(".supabase.co") && url.pathname.includes("/storage/v1/object/public/")) {
      return temiz;
    }
    // Yeni Cloudflare R2 / CDN depo adresleri (2026-11-25 sonrası).
    if (url.hostname === "cdn.vixrex.com" || url.hostname.endsWith(".r2.dev")) {
      return temiz;
    }
    return null;
  } catch {
    return null;
  }
}
