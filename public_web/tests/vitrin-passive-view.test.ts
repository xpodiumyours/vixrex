import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const tracker = readFileSync(
  resolve(__dirname, "../src/components/ProductViewTracker.tsx"),
  "utf8",
);
const route = readFileSync(
  resolve(__dirname, "../src/app/api/vitrin-engagement/route.ts"),
  "utf8",
);

describe("Vitrin Ölçer pasif ürün görüntüleme kapısı", () => {
  it("ürün görüntüleme tarayıcıdan doğrudan Supabase RPC'ye gitmez", () => {
    expect(tracker).toContain('fetch("/api/vitrin-engagement"');
    expect(tracker).not.toContain('.rpc("record_vitrin_engagement"');
  });

  it("sunucu kapısı yalnız product_view kabul eder ve bot filtresi uygular", () => {
    expect(route).toContain('eventType !== "product_view"');
    expect(route).toContain("isLikelyBotUserAgent");
    expect(route).toContain('getSupabaseAdmin().rpc("record_vitrin_engagement_v2"');
  });
});
