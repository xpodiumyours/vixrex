const DEFAULT_SITE_URL = "https://vixrex-public.vercel.app";
const LOCAL_DEV_SITE_URL = "http://localhost:3000";

// Uygulamanın (esnaf paneli) adresi. Vitrin adresinden AYRIDIR.
const DEFAULT_APP_URL = "https://vixrex-app.vercel.app";

/**
 * Esnafın vitrin kurduğu uygulamanın adresi.
 *
 * NEDEN BURADA: 2026-08-07'ye kadar vitrin sayfasında üç yerde
 * `https://vixrex.com` elle yazılıydı. O alan adı kayıtlı bile değil —
 * "Vitrin Oluştur" ve "Bu vitrini kirala" düğmeleri hiçbir yere gitmiyordu,
 * paylaşım kutusunda da ölü bir adres yazıyordu. Adres tek yerden gelsin ki
 * gerçek alan adı bağlandığında tek değişiklikle her yer düzelsin.
 */
export function getAppUrl() {
  const configured = process.env.NEXT_PUBLIC_APP_URL?.trim();
  if (!configured) return DEFAULT_APP_URL;
  try {
    return new URL(configured).origin;
  } catch {
    return DEFAULT_APP_URL;
  }
}

export function getSiteUrl() {
  const configured = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (configured) {
    try {
      return new URL(configured).origin;
    } catch {
      // fall through
    }
  }

  if (process.env.NODE_ENV === "development") {
    return LOCAL_DEV_SITE_URL;
  }

  return DEFAULT_SITE_URL;
}

export function buildSiteUrl(path = "/") {
  return new URL(path, `${getSiteUrl()}/`).toString();
}

export function isExternalHttpUrl(value: string) {
  if (!value.startsWith("http")) return false;

  try {
    const target = new URL(value);
    const site = new URL(getSiteUrl());
    return target.hostname !== site.hostname && target.hostname !== "localhost";
  } catch {
    return false;
  }
}
