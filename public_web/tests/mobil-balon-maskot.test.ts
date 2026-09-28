import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const oku = (p: string) => readFileSync(resolve(__dirname, p), "utf8");
const panel = oku("../src/app/v/[slug]/OwnerAssistantPanel.tsx");
const input = oku("../src/app/v/[slug]/components/FieldInputArea.tsx");
const top = oku("../src/app/v/[slug]/components/ChatTopBar.tsx");
const balon = oku("../src/app/v/[slug]/components/SpotlightGuide.tsx");

describe("mobil sahiplik asistanı — compact composer + çekmece", () => {
  it("varsayılan mobil yüz mesaj kutusudur; maskot SAĞDA trailing olarak gelir", () => {
    expect(panel).toContain('data-vixrex-mobile-dock="true"');
    expect(panel).toContain("<FieldInputArea\n            compact");
    expect(panel).toContain('trailing={');
    expect(panel).toContain("<VixrexAvatar size={44} decorative />");
    expect(panel).toContain('aria-label="Sohbet geçmişini aç"');

    const bas = panel.indexOf('data-vixrex-mobile-dock="true"');
    const bitis = panel.indexOf('data-vixrex-mobile-details=', bas);
    const dock = panel.slice(bas, bitis);
    expect(dock).not.toContain("rapor.");
    expect(dock).not.toContain("eksikTemelSayisi");
  });

  it("compact composer tek satır mesaj alanı ve küçük 36px gönder düğmesi kullanır", () => {
    expect(input).toContain("if (compact) {");
    expect(input).toContain('placeholder="Mesajını yaz…"');
    expect(input).toContain('className="grid h-9 w-9');
    expect(input).toContain('<path d="M4 12h13" />');
    expect(input).toContain('<path d="M12 6l6 6-6 6" />');
    expect(input).toContain("{trailing}");
  });

  it("compact composer gönderince eski launcher'ı kapatmaya çalışmaz", () => {
    expect(input).toContain("!compact &&");
  });

  it("yukarı sürükleme sohbet geçmişini açar", () => {
    expect(panel).toContain("mobilTutamakBasla");
    expect(panel).toContain("mobilTutamakBitir");
    expect(panel).toContain("if (fark > 28)");
    expect(panel).toContain("mobilGecmisiAc();");
    expect(panel).toContain("setMobilGecmisAcik(true)");
  });

  it("aşağı sürükleme geçmişi compact composer'a döndürür", () => {
    expect(top).toContain("olay.clientY - baslangic > 28");
    expect(top).toContain("onKapat()");
    expect(top).toContain('aria-label="Sohbet geçmişini küçültmek için aşağı çek"');
  });

  it("mobil geçmiş ayrı state'tir; masaüstü acik davranışı korunur", () => {
    expect(panel).toContain("mobilGecmisAcik");
    expect(panel).toContain("(masaustu ? acik : mobilGecmisAcik || haritaAcik)");
    expect(panel).toContain("vixrex-owner-assistant-shell fixed");
    expect(panel).toContain("lg:w-[var(--owner-rail-w)]");
  });

  it("mobil geçmiş masaüstü yönetim yüzünden yapısal olarak ayrıdır", () => {
    expect(panel).toContain("!masaustu && mobilGecmisAcik && !haritaAcik");
    expect(panel).toContain("!masaustu && haritaAcik");
    expect(panel).toContain("{masaustu ? (");
    expect(panel).toContain('data-vixrex-desktop-tabs="true"');
  });

  it("genişletilmiş mobil başlıkta canonical maskot sağdadır", () => {
    expect(top).toContain("order-4 relative shrink-0 sm:order-1");
    expect(top).toContain("<VixrexAvatar size={38} halo decorative />");
  });

  it("alan seçimi mobilde büyük geçmiş panelini zorla açmaz", () => {
    expect(panel).toContain("setMobilGecmisAcik(false)");
    expect(panel).toContain('window.matchMedia("(min-width: 640px)")');
  });
});

describe("mobil spotlight klavyeyi biliyor", () => {
  it("pencere değil görünen alan ölçülür", () => {
    expect(balon).toContain("window.visualViewport");
    expect(balon).toContain("gv?.offsetTop");
  });

  it("klavye açılıp kapanınca yeniden konumlanır", () => {
    expect(balon).toContain(
      'window.visualViewport?.addEventListener("resize", konumuGuncelle)',
    );
    expect(balon).toContain(
      'window.visualViewport?.removeEventListener("resize", konumuGuncelle)',
    );
  });

  it("yüksekliği tahmin etmez, gerçek boyunu ölçer", () => {
    expect(balon).toContain("balonRef");
    expect(balon).toContain("setBalonYukseklik");
  });

  it("altına/üstüne sığmıyorsa görünen bandın dibine sabitlenir", () => {
    expect(balon).toContain("const altaSigar");
    expect(balon).toContain("const usteSigar");
    expect(balon).toContain("balonUst = bandAlt - 8 - yukseklik");
  });

  it("balon görünen bandın üstünden taşmaz", () => {
    expect(balon).toContain("balonUst = Math.max(bandUst + 8, balonUst)");
  });

  it("dibe sabitlenmiş balonda ok çizilmez", () => {
    expect(balon).toContain('const okGorunur = balonYeri !== "sabit"');
    expect(balon).toContain("{okGorunur && (");
  });
});


describe("masaüstü düzeni mobil compact yüzü bozmaz", () => {
  it("telefon dock'u hâlâ yalnız sm altında ve maskot trailing sağdadır", () => {
    expect(panel).toContain('data-vixrex-mobile-dock="true"');
    expect(panel).toContain("sm:hidden");
    expect(panel).toContain("trailing={");
    expect(panel).toContain("<VixrexAvatar size={44} decorative />");
  });
});
