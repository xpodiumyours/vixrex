import { describe, expect, it, vi } from "vitest";
import {
  buildInstagramGraphUrl,
  getPublicSiteOrigin,
  normalizeStoreAuth,
  trimToEmpty,
} from "@/lib/instagramRouteUtils";

describe("instagramRouteUtils", () => {
  it("trims nullable string values to empty strings", () => {
    expect(trimToEmpty("  abc  ")).toBe("abc");
    expect(trimToEmpty("   ")).toBe("");
    expect(trimToEmpty(null)).toBe("");
  });

  it("normalizes store auth request bodies", () => {
    expect(
      normalizeStoreAuth({
        storeSlug: " test-store ",
        editToken: " token-123 ",
      }),
    ).toEqual({
      storeSlug: "test-store",
      editToken: "token-123",
    });
  });

  it("builds graph urls from the configured base url", () => {
    vi.stubEnv("INSTAGRAM_GRAPH_BASE_URL", "https://graph.example.com/base/");

    expect(buildInstagramGraphUrl("/me/media").toString()).toBe(
      "https://graph.example.com/base/me/media",
    );

    vi.unstubAllEnvs();
  });

  it("prefers NEXT_PUBLIC_SITE_URL for callback origins", () => {
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", "https://vitrinx.example");

    expect(
      getPublicSiteOrigin({
        nextUrl: new URL("http://localhost:3000/test"),
      }),
    ).toBe("https://vitrinx.example");

    vi.unstubAllEnvs();
  });
});
