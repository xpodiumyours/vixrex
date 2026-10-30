import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import ManufacturerProductSource from "@/components/ManufacturerProductSource";

const render = (url?: string, verificationStatus?: string) => renderToStaticMarkup(
  createElement(ManufacturerProductSource, {
    source: url === undefined ? undefined : { url, verificationStatus },
  }),
);

describe("ManufacturerProductSource", () => {
  it("üretici kaynağı güvenli dış bağlantı olarak gösterilir", () => {
    const html = render("https://example.com/products/coffee", "Doğrulandı");
    expect(html).toContain("Üretici ürün kaynağı");
    expect(html).toContain('target="_blank"');
    expect(html).toContain('rel="noopener noreferrer"');
  });
  it("iç eşleşme durumu tüketiciye gösterilmez", () => {
    for (const durum of ["Doğrulandı", "? Belirsiz", "Bulunamadı"]) {
      const html = render("https://example.com/product", durum);
      expect(html).not.toContain(durum);
      expect(html).not.toContain("eşleşme");
      expect(html).not.toContain("OpenRouter");
    }
  });
  it.each(["javascript:alert(1)", "https://user:password@example.com/product", "  "])(
    "geçersiz veya kimlik bilgili kaynağı göstermez: %s", (url) => expect(render(url)).toBe(""),
  );
  it("kaynak gelmemişse bağlantı üretmez", () => expect(render()).toBe(""));
});
