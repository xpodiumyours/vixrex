import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const panel = readFileSync(resolve(__dirname, "../src/components/ProductCommercePanel.tsx"), "utf8");
const dock = readFileSync(resolve(__dirname, "../src/components/VitrinCartDock.tsx"), "utf8");

describe("Vitrin Ölçer müşteri etkileşim sözleşmesi", () => {
  it("sahip önizlemesinde beğeni, yorum ve sepet üretmez", () => {
    expect(panel).toContain("ownerPreviewActive");
    expect(dock).toContain("ownerPreviewActive");
  });

  it("beğeni ve yorum doğrudan tabloya değil RPC'ye gider", () => {
    expect(panel).toContain('supabase.rpc("toggle_product_like"');
    expect(panel).toContain('supabase.rpc("create_product_comment"');
    expect(panel).not.toMatch(/\.from\(["']vitrin_product_/);
  });

  it("yorum kalıcı hesap kapısını istemcide de gösterir", () => {
    expect(panel).toContain("session.user.is_anonymous");
    expect(panel).toContain("Google ile giriş yap");
  });

  it("sepet WhatsApp geçişini ayrı dönüşüm olayı olarak ölçer", () => {
    expect(dock).toContain('eventType: "cart_whatsapp_order"');
    expect(dock).toContain("order_key: orderKey");
    expect(dock).toContain("productSlug: item.productSlug");
    expect(dock).toContain('eventType: "whatsapp_click"');
  });
});
