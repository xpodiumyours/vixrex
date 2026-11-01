import { afterEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { COOKIE_CONSENT_KEY, parseConsentSnapshot, writeConsent } from "../src/lib/cookieConsent";

const banner = readFileSync(resolve(__dirname, "../src/components/cookie-consent/CookieBanner.tsx"), "utf8");
const loader = readFileSync(resolve(__dirname, "../src/components/cookie-consent/AnalyticsLoader.tsx"), "utf8");

afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
});

describe("R02-CEREZ-01: değiştirilebilir çerez tercihleri", () => {
  it("bozuk veya string değerleri yanlışlıkla açık rıza saymaz", () => {
    expect(parseConsentSnapshot(JSON.stringify({ analytics: "false", marketing: "false" }))).toBeNull();
    expect(parseConsentSnapshot(JSON.stringify({ analytics: false, marketing: false }))?.analytics).toBe(false);
  });

  it("kayıtlı tercihleri yeniden açabilen erişilebilir denetim vardır", () => {
    expect(banner).toContain('aria-label="Çerez tercihlerini yeniden düzenle"');
    expect(banner).toContain("setAnalytics(existingConsent.analytics)");
    expect(banner).toContain("setMarketing(existingConsent.marketing)");
    expect(banner).toContain("setReopened(true)");
    expect(banner).toContain("Vazgeç");
  });

  it("analitik izni geri alınırken Google Analytics aynı olay içinde devre dışı bırakılır", () => {
    const values = new Map<string, string>();
    const dispatchEvent = vi.fn();
    vi.stubEnv("NEXT_PUBLIC_GA_ID", "G-VIXREX-TEST");
    vi.stubGlobal("CustomEvent", class { constructor(public type: string, public init: object) {} });
    vi.stubGlobal("window", {
      localStorage: { setItem: (key: string, value: string) => values.set(key, value) },
      dispatchEvent,
    });

    writeConsent({ analytics: true, marketing: false });
    expect((window as unknown as Record<string, unknown>)["ga-disable-G-VIXREX-TEST"]).toBe(false);

    writeConsent({ analytics: false, marketing: false });
    expect((window as unknown as Record<string, unknown>)["ga-disable-G-VIXREX-TEST"]).toBe(true);
    expect(JSON.parse(values.get(COOKIE_CONSENT_KEY) ?? "{}").analytics).toBe(false);
    expect(dispatchEvent).toHaveBeenCalledTimes(2);
  });

  it("yeniden yüklenen sayfada da Google Analytics engeli uygulanır", () => {
    expect(loader).toContain("useEffect");
    expect(loader).toContain("ga-disable-");
    expect(loader).toContain("!analyticsAllowed");
    expect(loader).toContain("if (!GA_ID || !analyticsAllowed) return null;");
  });

  it("analitik rızası geri alınınca yalnız Google Analytics çerezlerini temizler", () => {
    const deletions: string[] = [];
    const saved = new Map<string, string>();
    vi.stubEnv("NEXT_PUBLIC_GA_ID", "G-VIXREX-TEST");
    vi.stubGlobal("CustomEvent", class { constructor(public type: string, public init: object) {} });
    vi.stubGlobal("document", {
      get cookie() { return "_ga=client; _ga_TEST=session; _gid=legacy; vixrex_session=retain"; },
      set cookie(value: string) { deletions.push(value); },
    });
    vi.stubGlobal("window", {
      location: { hostname: "www.vixrex.com" },
      localStorage: { setItem: (key: string, value: string) => saved.set(key, value) },
      dispatchEvent: vi.fn(),
    });

    writeConsent({ analytics: false, marketing: false });

    expect(deletions.some((item) => item.startsWith("_ga=;") && item.includes("Domain=vixrex.com"))).toBe(true);
    expect(deletions.some((item) => item.startsWith("_ga_TEST=;"))).toBe(true);
    expect(deletions.some((item) => item.startsWith("_gid=;"))).toBe(true);
    expect(deletions.some((item) => item.startsWith("vixrex_session=;"))).toBe(false);
    expect(saved.has(COOKIE_CONSENT_KEY)).toBe(true);
    expect((window as unknown as Record<string, unknown>)["ga-disable-G-VIXREX-TEST"]).toBe(true);
  });
});
