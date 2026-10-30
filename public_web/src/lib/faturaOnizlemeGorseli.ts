export function onizlemeKartiGorseli(adres: unknown): string | null {
  if (typeof adres !== "string") return null;
  const temiz = adres.trim();
  if (!temiz) return null;
  try {
    const url = new URL(temiz);
    if (url.protocol !== "https:") return null;
    if (!url.hostname.endsWith(".supabase.co")) return null;
    if (!url.pathname.includes("/storage/v1/object/public/")) return null;
    return temiz;
  } catch {
    return null;
  }
}
