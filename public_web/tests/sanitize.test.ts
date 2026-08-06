import { describe, expect, it } from "vitest";
import { sanitizeHtml } from "../src/lib/sanitize";

// Blog içeriğini esnaf yazıyor ve sayfaya dangerouslySetInnerHTML ile
// basılıyor. Girdi güvenilmez, çıktı herkese görünür — bu testler o
// sınırın bekçisi.

describe("sanitizeHtml — XSS", () => {
  it("script etiketini atar", () => {
    const c = sanitizeHtml('<p>merhaba</p><script>alert(1)</script>');
    expect(c).not.toContain("<script");
    expect(c).toContain("merhaba");
  });

  it("İÇ İÇE GEÇMİŞ script'i atar — eski regex sürümü burada düşüyordu", () => {
    // Regex tek geçişte içteki <script>'i silince geriye çalışan bir
    // <script> kalıyordu. Kütüphane ayrıştırarak çalıştığı için kalmaz.
    const c = sanitizeHtml("<scr<script>ipt>alert(1)</scr</script>ipt>");
    expect(c.toLowerCase()).not.toContain("<script");
  });

  it("satır içi olay yakalayıcıları atar", () => {
    for (const kotu of [
      '<img src=x onerror="alert(1)">',
      '<p onclick="alert(1)">metin</p>',
      "<p ONMOUSEOVER=alert(1)>metin</p>",
      '<a href="#" oNlOaD="alert(1)">bağlantı</a>',
    ]) {
      const c = sanitizeHtml(kotu);
      expect(c.toLowerCase(), kotu).not.toMatch(/on\w+\s*=/);
      expect(c.toLowerCase(), kotu).not.toContain("alert(1)");
    }
  });

  it("javascript: ve data: adreslerini atar", () => {
    for (const kotu of [
      '<a href="javascript:alert(1)">tıkla</a>',
      "<a href=javascript:alert(1)>tıkla</a>",
      '<a href="JaVaScRiPt:alert(1)">tıkla</a>',
      '<a href="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==">tıkla</a>',
    ]) {
      const c = sanitizeHtml(kotu).toLowerCase();
      expect(c, kotu).not.toContain("javascript:");
      expect(c, kotu).not.toContain("data:text/html");
    }
  });

  it("iframe, object, embed, form ve style atılır", () => {
    const c = sanitizeHtml(
      '<iframe src="x"></iframe><object data="x"></object>' +
        '<embed src="x"><form><input name="a"></form><style>body{display:none}</style>'
    ).toLowerCase();
    for (const e of ["<iframe", "<object", "<embed", "<form", "<input", "<style"]) {
      expect(c, e).not.toContain(e);
    }
  });

  it("style ve id öznitelikleri düşer — sayfa düzeni ele geçirilemez", () => {
    const c = sanitizeHtml('<p style="position:fixed;inset:0" id="kapak">metin</p>');
    expect(c).not.toContain("style=");
    expect(c).not.toContain("id=");
    expect(c).toContain("metin");
  });
});

describe("sanitizeHtml — meşru içerik korunur", () => {
  it("temel biçimlendirme kalır", () => {
    const c = sanitizeHtml(
      "<p>Bir <strong>kalın</strong> ve <em>eğik</em> yazı.</p><ul><li>madde</li></ul>"
    );
    expect(c).toContain("<strong>kalın</strong>");
    expect(c).toContain("<em>eğik</em>");
    expect(c).toContain("<li>madde</li>");
  });

  it("güvenli bağlantı kalır ve nofollow kazanır", () => {
    const c = sanitizeHtml('<a href="https://vixrex.com">site</a>');
    expect(c).toContain('href="https://vixrex.com"');
    expect(c).toContain("noopener");
    expect(c).toContain("nofollow");
  });

  it("mailto ve tel bağlantıları kalır", () => {
    expect(sanitizeHtml('<a href="mailto:a@b.com">yaz</a>')).toContain("mailto:");
    expect(sanitizeHtml('<a href="tel:+905551234567">ara</a>')).toContain("tel:");
  });

  it("izinsiz etiketin içindeki yazı kaybolmaz", () => {
    const c = sanitizeHtml("<div><span>görünmeli</span></div>");
    expect(c).toContain("görünmeli");
  });

  it("boş girdi boş döner", () => {
    expect(sanitizeHtml("")).toBe("");
  });
});
