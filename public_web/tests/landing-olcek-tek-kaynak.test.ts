import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

const flutterOlcek = oku("../../lib/theme/app_colors.dart");
const webOlcek = oku("../src/app/globals.css");

const dartOlcusu = (ad: string): number => {
  const eslesme = flutterOlcek.match(
    new RegExp(`static const double ${ad} = (\\d+(?:\\.\\d+)?);`),
  );
  if (!eslesme) throw new Error(`app_colors.dart içinde ${ad} yok`);
  return Number(eslesme[1]);
};

const cssOlcusu = (ad: string): number => {
  const eslesme = webOlcek.match(new RegExp(`--${ad}:\\s*(\\d+(?:\\.\\d+)?)px;`));
  if (!eslesme) throw new Error(`globals.css içinde --${ad} yok`);
  return Number(eslesme[1]);
};

const BOLUMLER: Array<{ ad: string; flutter: string; web: string; webSinif: string }> = [
  {
    ad: "hero",
    flutter: "../../lib/widgets/landing/landing_hero_section.dart",
    web: "../src/components/landing/HeroSection.tsx",
    webSinif: "pb-lp-section",
  },
  {
    ad: "değer bandı",
    flutter: "../../lib/widgets/landing/landing_value_band.dart",
    web: "../src/components/landing/ValueBand.tsx",
    webSinif: "py-lp-section",
  },
  {
    ad: "özellikler",
    flutter: "../../lib/widgets/landing/landing_features_section.dart",
    web: "../src/components/landing/FeaturesSection.tsx",
    webSinif: "py-lp-section",
  },
  {
    ad: "karşılaştırma",
    flutter: "../../lib/widgets/landing/landing_comparison_section.dart",
    web: "../src/components/landing/ComparisonSection.tsx",
    webSinif: "py-lp-section",
  },
  {
    ad: "güven bandı",
    flutter: "../../lib/widgets/landing/landing_trust_band.dart",
    web: "../src/components/landing/TrustBand.tsx",
    webSinif: "py-lp-section",
  },
  {
    ad: "üç adım",
    flutter: "../../lib/widgets/landing/landing_steps_section.dart",
    web: "../src/components/landing/StepsSection.tsx",
    webSinif: "py-lp-section",
  },
  {
    ad: "şablon kataloğu",
    flutter: "../../lib/widgets/landing/landing_template_catalog.dart",
    web: "../src/components/landing/TemplateCatalog.tsx",
    webSinif: "py-lp-section",
  },
  {
    ad: "alt çağrı",
    flutter: "../../lib/widgets/landing/landing_bottom_cta.dart",
    web: "../src/components/landing/BottomCta.tsx",
    webSinif: "py-lp-section",
  },
];

describe("Landing ölçeği tek kaynaktan gelir", () => {
  it("bölüm dikey boşluğu iki istemcide aynı sayıdır", () => {
    expect(dartOlcusu("landingSectionY")).toBe(cssOlcusu("spacing-lp-section"));
  });

  it("ana kolon genişliği iki istemcide aynı sayıdır", () => {
    expect(dartOlcusu("landingColumn")).toBe(cssOlcusu("container-lp"));
  });

  it("dar kolon genişliği iki istemcide aynı sayıdır", () => {
    expect(dartOlcusu("landingColumnNarrow")).toBe(cssOlcusu("container-lp-dar"));
  });

  it("kenar boşluğu iki istemcide aynı sayıdır", () => {
    expect(dartOlcusu("landingGutter")).toBe(cssOlcusu("lp-gutter"));
    expect(dartOlcusu("landingGutterWide")).toBe(cssOlcusu("lp-gutter-wide"));
  });

  it("mockup ölçüleri iki istemcide aynı sayıdır", () => {
    expect(dartOlcusu("landingMockupHeight")).toBe(cssOlcusu("spacing-lp-mockup"));
    expect(dartOlcusu("landingMockupBox")).toBe(cssOlcusu("spacing-lp-mockup-kutu"));
  });

  it.each(BOLUMLER)(
    "$ad bölümü iki istemcide de ölçek token'ını kullanır",
    ({ flutter, web, webSinif }) => {
      expect(oku(flutter)).toContain("AppColors.landingSectionY");
      expect(oku(web)).toContain(webSinif);
    },
  );

  it.each(BOLUMLER.filter((b) => b.ad !== "alt çağrı"))(
    "$ad bölümü ana kolon token'ını kullanır",
    ({ flutter, web }) => {
      expect(oku(flutter)).toContain("AppColors.landingColumn");
      expect(oku(web)).toContain("max-w-lp");
    },
  );

  it.each(BOLUMLER)(
    "$ad bölümü iki istemcide de kenar boşluğu kuralını kullanır",
    ({ flutter, web }) => {
      expect(oku(flutter)).toContain("yanBosluk");
      expect(oku(web)).toContain("lp-yan-bosluk");
    },
  );

  it("alt çağrı dar kolon token'ını kullanır", () => {
    expect(oku("../../lib/widgets/landing/landing_bottom_cta.dart")).toContain(
      "AppColors.landingColumnNarrow",
    );
    expect(oku("../src/components/landing/BottomCta.tsx")).toContain("max-w-lp-dar");
  });
});
