import { describe, it, expect, vi, afterEach } from "vitest";
import { getSiteUrl, buildSiteUrl, isExternalHttpUrl } from "@/lib/siteUrl";

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("getSiteUrl", () => {
  it("returns default URL when env is not set", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "");
    expect(getSiteUrl()).toBe("https://vitrinx.app");
  });

  it("returns origin from configured URL", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://staging.vitrinx.app/some/path");
    expect(getSiteUrl()).toBe("https://staging.vitrinx.app");
  });

  it("falls back to default for invalid URL", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "not-a-url");
    expect(getSiteUrl()).toBe("https://vitrinx.app");
  });
});

describe("buildSiteUrl", () => {
  it("builds a full URL from a path", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://vitrinx.app");
    expect(buildSiteUrl("/v/my-store")).toBe("https://vitrinx.app/v/my-store");
  });

  it("defaults to root when no path given", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://vitrinx.app");
    expect(buildSiteUrl()).toBe("https://vitrinx.app/");
  });
});

describe("isExternalHttpUrl", () => {
  it("returns false for non-http strings", () => {
    expect(isExternalHttpUrl("/relative/path")).toBe(false);
    expect(isExternalHttpUrl("ftp://example.com")).toBe(false);
  });

  it("returns false for the same hostname as the site", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://vitrinx.app");
    expect(isExternalHttpUrl("https://vitrinx.app/page")).toBe(false);
  });

  it("returns true for external http/https URLs", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://vitrinx.app");
    expect(isExternalHttpUrl("https://instagram.com/p/abc")).toBe(true);
  });

  it("returns false for localhost URLs", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://vitrinx.app");
    expect(isExternalHttpUrl("http://localhost:3000")).toBe(false);
  });
});
