import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import IletisimPage from "@/app/(site)/iletisim/page";

function renderIletisim() {
  return renderToStaticMarkup(createElement(IletisimPage));
}

describe("iletişim yüzeyi — gerçek render", () => {
  it("destek iletişimini ve konu bağlantılarını gerçekten çizer", () => {
    const html = renderIletisim();

    expect(html).toContain("Bize ulaşın");
    expect(html).toContain('href="mailto:destek@vixrex.com"');
    expect(html).toContain("destek@vixrex.com");
    expect(html).toContain("Vitrin ve hesap desteği");
    expect(html).toContain('href="/yardim"');
    expect(html).toContain("Yasal konular ve veri talepleri");
    expect(html).toContain('href="/privacy"');
  });

  it("yasal bilgi listesini gerçek HTML olarak çizer", () => {
    const html = renderIletisim();

    expect(html).toContain("<dl");
    expect(html).toContain("Ticaret unvanı");
    expect(html).toContain("Faaliyet konusu");
  });

  it.todo(
    "Esnaf WhatsApp / Instagram / telefon alanları bu public destek sayfasında yok; eski parite testi yanlış yüzey eşlemesini yeşil gösteriyordu",
  );
});
