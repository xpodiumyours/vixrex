export const COOKIE_CONSENT_KEY = "vixrex_cookie_consent";
const COOKIE_CONSENT_EVENT = "vixrex-cookie-consent";

export type CookieConsent = {
  necessary: true;
  analytics: boolean;
  marketing: boolean;
  updatedAt: string;
};

export function defaultConsent(): CookieConsent {
  return {
    necessary: true,
    analytics: false,
    marketing: false,
    updatedAt: new Date().toISOString(),
  };
}

export function parseConsentSnapshot(raw: string | null): CookieConsent | null {
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as Partial<CookieConsent>;
    if (typeof parsed.analytics !== "boolean" || typeof parsed.marketing !== "boolean") return null;
    return {
      necessary: true,
      analytics: Boolean(parsed.analytics),
      marketing: Boolean(parsed.marketing),
      updatedAt:
        typeof parsed.updatedAt === "string"
          ? parsed.updatedAt
          : new Date().toISOString(),
    };
  } catch {
    return null;
  }
}

export function readConsentSnapshot(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return window.localStorage.getItem(COOKIE_CONSENT_KEY);
  } catch {
    return null;
  }
}

export function readConsent(): CookieConsent | null {
  return parseConsentSnapshot(readConsentSnapshot());
}

export function subscribeToConsent(onStoreChange: () => void): () => void {
  if (typeof window === "undefined") return () => undefined;
  window.addEventListener(COOKIE_CONSENT_EVENT, onStoreChange);
  return () => window.removeEventListener(COOKIE_CONSENT_EVENT, onStoreChange);
}

function clearAnalyticsCookies(): void {
  if (typeof document === "undefined") return;

  try {
    const names = document.cookie
      .split(";")
      .map((cookie) => cookie.trim().split("=")[0])
      .filter((name) => /^_ga(?:_|$)|^_gid$|^_gat(?:_|$)|^_gac_/.test(name));

    if (!names.length) return;

    const labels = window.location.hostname.split(".");
    const domains = [""];
    for (let i = 0; i < labels.length - 1; i++) {
      domains.push(labels.slice(i).join("."));
    }

    for (const name of names) {
      for (const domain of domains) {
        document.cookie = `${name}=; Max-Age=0; Path=/; SameSite=Lax${domain ? `; Domain=${domain}` : ""}`;
      }
    }
  } catch {
    return;
  }
}

export function writeConsent(
  partial: Pick<CookieConsent, "analytics" | "marketing">,
): CookieConsent {
  const value: CookieConsent = {
    necessary: true,
    analytics: partial.analytics,
    marketing: partial.marketing,
    updatedAt: new Date().toISOString(),
  };
  window.localStorage.setItem(COOKIE_CONSENT_KEY, JSON.stringify(value));
  const measurementId = process.env.NEXT_PUBLIC_GA_ID;
  if (measurementId) {
    (window as unknown as Record<string, unknown>)[`ga-disable-${measurementId}`] = !value.analytics;
  }
  if (!value.analytics) clearAnalyticsCookies();
  window.dispatchEvent(new CustomEvent(COOKIE_CONSENT_EVENT, { detail: value }));
  return value;
}
