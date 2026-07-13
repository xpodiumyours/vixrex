const DEFAULT_SITE_URL = "https://vixrex-public.vercel.app";

export function getSiteUrl() {
  const configured = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (!configured) return DEFAULT_SITE_URL;

  try {
    return new URL(configured).origin;
  } catch {
    return DEFAULT_SITE_URL;
  }
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
