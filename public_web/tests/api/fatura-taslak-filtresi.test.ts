import { describe, expect, it } from "vitest";
import { taslakUrunMu } from "@/lib/faturaTaslakFiltresi";
describe("yalnız taslaklar", () => {
  it("yalnız açıkça gizli ürünleri seçer ve eski ürünlerin durumunu değiştirmez", () => {
    const urunler = [{ id: "taslak", is_visible: false }, { id: "yayinda", is_visible: true }, { id: "eski", is_visible: null }, { id: "belirsiz" }];
    expect(urunler.filter(taslakUrunMu).map(urun => urun.id)).toEqual(["taslak"]);
    expect(urunler[2].is_visible).toBeNull();
  });
});
