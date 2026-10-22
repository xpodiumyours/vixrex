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
  it("belirsiz sonucu doğrulandıya çevirmez", () => {
    const html = render("https://example.com/product", "? Belirsiz");
    expect(html).toContain("? Belirsiz");
    expect(html).not.toContain("Doğrulandı");
  });
  it.each(["javascript:alert(1)", "https://user:password@example.com/product", "  "])(
    "geçersiz veya kimlik bilgili kaynağı göstermez: %s", (url) => expect(render(url)).toBe(""),
  );
  it("kaynak gelmemişse bağlantı üretmez", () => expect(render()).toBe(""));
});
