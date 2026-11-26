import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { isTestOrDenemeStore } from "@/lib/testStoreFilter";

describe("VitrinKarti İncele butonu stilleri", () => {
  it("hem kiralık hem normal karttaki İncele Link butonları text-lp-primary ve border-lp-primary kullanır, text-white veya bg-blue-500/15 içermez", () => {
    const kaynak = readFileSync(
      resolve(process.cwd(), "src/components/kesfet/VitrinKarti.tsx"),
      "utf8"
    );
    const inceleLinkleri = kaynak.match(
      /<Link\s+href=\{`\/v\/\$\{vitrin\.slug\}`\}\s+className="[^"]*"\s*>\s*<DukkanIkonu\s*\/>\s*İncele\s*<\/Link>/g
    );

    expect(inceleLinkleri).not.toBeNull();
    expect(inceleLinkleri).toHaveLength(2);

    for (const linkHtml of inceleLinkleri ?? []) {
      expect(linkHtml).toContain("text-lp-primary");
      expect(linkHtml).toContain("border-lp-primary");
      expect(linkHtml).not.toContain("text-white");
      expect(linkHtml).not.toContain("bg-blue-500/15");
    }
  });
});

describe("isTestOrDenemeStore", () => {
  it("is_demo === true olan resmi kiralık şablonları her zaman korur", () => {
    expect(
      isTestOrDenemeStore({
        name: "Test Kiralık Vitrin",
        slug: "deneme-sablon-mw123456",
        is_demo: true,
      })
    ).toBe(false);
  });

  it("is_demo !== true olup adı veya slug'ı test/deneme/aasd/sssss/dename/-mw... içeren kayıtları eler", () => {
    const elenecekler = [
      { name: "Test Market", slug: "market-1", is_demo: false },
      { name: "Normal Market", slug: "test-market", is_demo: false },
      { name: "Deneme Dükkan", slug: "dukkan-1", is_demo: null },
      { name: "Dükkan", slug: "deneme-dukkan", is_demo: false },
      { name: "aasd", slug: "aasd-1", is_demo: false },
      { name: "Mağaza", slug: "sssss-magaza", is_demo: false },
      { name: "Dename Vitrin", slug: "vitrin-1", is_demo: false },
      { name: "Gerçek İsim", slug: "dukkan-mw1a2b3c", is_demo: false },
    ];

    for (const kayit of elenecekler) {
      expect(isTestOrDenemeStore(kayit)).toBe(true);
    }
  });

  it("gerçek vitrinleri ve boş alanlı kayıtları elemez", () => {
    expect(
      isTestOrDenemeStore({
        name: "Karadeniz Pide & Kebap",
        slug: "karadeniz-pide-kebap",
        is_demo: false,
      })
    ).toBe(false);
    expect(
      isTestOrDenemeStore({
        name: null,
        slug: null,
        is_demo: null,
      })
    ).toBe(false);
  });
});
