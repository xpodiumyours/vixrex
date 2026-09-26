import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const panel = readFileSync(resolve(__dirname, "../src/components/ProductCommercePanel.tsx"), "utf8");
const dock = readFileSync(resolve(__dirname, "../src/components/VitrinCartDock.tsx"), "utf8");
const quick = readFileSync(resolve(__dirname, "../src/components/ProductQuickView.tsx"), "utf8");
const quickBase = readFileSync(resolve(__dirname, "../src/components/ProductQuickViewBase.tsx"), "utf8");
const storePage = readFileSync(resolve(__dirname, "../src/app/v/[slug]/page.tsx"), "utf8");

describe("Vitrin Ölçer müşteri etkileşim sözleşmesi", () => {
  it("sahip önizlemesinde beğeni, yorum ve sepet üretmez", () => {
    expect(panel).toContain("enabled?: boolean");
    expect(panel).toContain("if (!enabled) return null");
    expect(dock).toContain("if (!trackingEnabled || items.length === 0) return null");
    expect(quick).toContain("commerceEnabled={trackingEnabled}");
    expect(quickBase).toContain("enabled={commerceEnabled}");
    expect(storePage).toContain("trackingEnabled={!isOwnerMode}");
  });

  it("beğeni ve yorum doğrudan tabloya değil RPC'ye gider", () => {
    expect(panel).toContain('supabase.rpc("toggle_product_like"');
    expect(panel).toContain('supabase.rpc("create_product_comment"');
    expect(panel).not.toMatch(/\.from\(["']vitrin_product_/);
  });

  it("beğeni de yorum gibi kalıcı hesap ister", () => {
    expect(panel).toContain("Beğenmek için Google ile giriş yapmalısın.");
    expect(panel).toContain("session.user.is_anonymous");
  });

  it("yorum kalıcı hesap kapısını istemcide de gösterir", () => {
    expect(panel).toContain("session.user.is_anonymous");
    expect(panel).toContain("Google ile giriş yap");
  });

  it("WhatsApp sekmesini ölçüm ağ çağrılarını beklemeden kullanıcı tıklaması içinde açar", () => {
    const openIndex = dock.indexOf('link.click()');
    const trackingIndex = dock.indexOf('void Promise.all');
    expect(openIndex).toBeGreaterThan(-1);
    expect(trackingIndex).toBeGreaterThan(openIndex);
  });

  it("sepet ürünü stok tavanıyla birlikte saklar ve UI stok üstüne çıkmaz", () => {
    expect(panel).toContain("maxQuantity: stockQuantity");
    expect(dock).toContain("item.quantity >= item.maxQuantity");
    expect(dock).toContain("Stok sınırı");
  });

  it("sepet WhatsApp geçişini ayrı dönüşüm olayı olarak ölçer", () => {
    expect(dock).toContain('eventType: "cart_whatsapp_order"');
    expect(dock).toContain("order_key: orderKey");
    expect(dock).toContain("productSlug: item.productSlug");
    expect(dock).toContain('eventType: "whatsapp_click"');
  });
});
