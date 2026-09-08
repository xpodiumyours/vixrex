import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

describe("landing tam yüzey Flutter referans paritesi", () => {
  it("değer bandı 820 constraint eşiği, 5/4 oranı ve mobil merkez hizasını korur", () => {
    const flutter = oku("../lib/widgets/landing/landing_value_band.dart");
    const web = oku("src/components/landing/ValueBand.tsx");
    expect(flutter).toContain("constraints.maxWidth > 820");
    expect(flutter).toContain("Expanded(flex: 5, child: copy)");
    expect(flutter).toContain("Expanded(flex: 4, child: chips)");
    expect(web).toContain("min-[869px]:flex-row");
    expect(web).toContain("min-[869px]:basis-5/9");
    expect(web).toContain("min-[869px]:basis-4/9");
    expect(web).toContain("text-center min-[869px]:basis-5/9 min-[869px]:text-left");
  });

  it("özellik kartları Flutter 680/1040 constraint eşikleri ve Material ikonlarıyla çalışır", () => {
    const flutter = oku("../lib/widgets/landing/landing_features_section.dart");
    const card = oku("../lib/widgets/landing/landing_value_card.dart");
    const web = oku("src/components/landing/FeaturesSection.tsx");
    expect(flutter).toContain("constraints.maxWidth > 1040");
    expect(flutter).toContain("constraints.maxWidth > 680");
    expect(card).toContain("width: 54");
    expect(card).toContain("size: 26");
    expect(card).toContain("const SizedBox(width: 15)");
    expect(web).toContain("min-[729px]:block");
    expect(web).toContain("min-[1089px]:w-[calc(25%_-_13.5px)]");
    for (const icon of ["bolt", "contact_phone", "share", "edit_note"]) {
      expect(web).toContain(`ikon: "${icon}"`);
    }
  });

  it("karşılaştırma paneli 820 eşiği, 26 padding, 46 yön oku ve gerçek Flutter ikonlarını korur", () => {
    const flutter = oku("../lib/widgets/landing/landing_comparison_section.dart");
    const panel = oku("../lib/widgets/landing/landing_setup_panel.dart");
    const web = oku("src/components/landing/ComparisonSection.tsx");
    expect(flutter).toContain("constraints.maxWidth > 820");
    expect(panel).toContain("padding: const EdgeInsets.all(26)");
    expect(flutter).toContain("width: 46");
    expect(web).toContain("min-[869px]:flex-row");
    expect(web).toContain("p-[26px]");
    expect(web).toContain("h-[46px] w-[46px]");
    for (const icon of ["language", "tune", "chat_bubble_outline", "qr_code_2", "support_agent"]) {
      expect(web).toContain(`"${icon}"`);
    }
  });

  it("güven bandı Flutter'daki beş farklı Material ikonu kullanır", () => {
    const flutter = oku("../lib/widgets/landing/landing_trust_band.dart");
    const web = oku("src/components/landing/TrustBand.tsx");
    for (const [flutterIcon, webIcon] of [
      ["credit_card_off_rounded", "credit_card_off"],
      ["percent_rounded", "percent"],
      ["code_off_rounded", "code_off"],
      ["qr_code_2_rounded", "qr_code_2"],
      ["chat_bubble_rounded", "chat_bubble"],
    ]) {
      expect(flutter).toContain(flutterIcon);
      expect(web).toContain(`"${webIcon}"`);
    }
  });

  it("üç adım bölümü Flutter 800 constraint eşiği ve 28 mobil aralığına bağlıdır", () => {
    const flutter = oku("../lib/widgets/landing/landing_steps_section.dart");
    const web = oku("src/components/landing/StepsSection.tsx");
    expect(flutter).toContain("constraints.maxWidth > 800");
    expect(flutter).toContain("width: 60");
    expect(flutter).toContain("bottom: 28");
    expect(web).toContain("min-[849px]:flex-row");
    expect(web).toContain("h-[60px] w-[60px]");
    expect(web).toContain("mb-7");
  });

  it("hazır şablon katalog görünümü Flutter'ın 20 kartını ve grid ölçülerini taşır", () => {
    const flutterCategories = oku("../lib/widgets/landing/landing_template_category.dart");
    const flutterCatalog = oku("../lib/widgets/landing/landing_template_catalog.dart");
    const flutterCard = oku("../lib/widgets/landing/landing_template_card.dart");
    const web = oku("src/components/landing/TemplateCatalog.tsx");
    const flutterCount = (flutterCategories.match(/TemplateCategory\(/g) ?? []).length - 1;
    const webCount = (web.match(/\{ key: "/g) ?? []).length;
    expect(flutterCount).toBe(20);
    expect(webCount).toBe(20);
    expect(flutterCatalog).toContain("fontSize: 28");
    expect(flutterCatalog).toContain("childAspectRatio: 0.85");
    expect(flutterCard).toContain("BorderRadius.circular(20)");
    expect(web).toContain("text-[28px]");
    expect(web).toContain("aspect-[0.85]");
    expect(web).toContain("rounded-[20px]");
    expect(web).toContain("min-[649px]:grid-cols-3");
    expect(web).toContain("min-[949px]:grid-cols-4");
  });

  it("alt CTA Flutter boşluklarını korur; web yalnız kontrast güvenliği için renk istisnası tutar", () => {
    const flutter = oku("../lib/widgets/landing/landing_bottom_cta.dart");
    const web = oku("src/components/landing/BottomCta.tsx");
    expect(flutter).toContain("vertical: 88");
    expect(flutter).toContain("maxWidth: 800");
    expect(flutter).toContain("fontSize: 36");
    expect(flutter).toContain("const SizedBox(height: 24)");
    expect(flutter).toContain("const SizedBox(height: 48)");
    expect(web).toContain("py-[88px]");
    expect(web).toContain("max-w-[800px]");
    expect(web).toContain("text-[36px]");
    expect(web).toContain("mt-6");
    expect(web).toContain("mt-12");
    expect(web).toContain("WCAG 2.2 1.4.3");
  });

  it("yüzen Vixrex rozeti Flutter 60px, 220px balon, 6sn kapanma ve 1800ms hareket sözleşmesinde", () => {
    const flutter = oku("../lib/widgets/chatbot_badge.dart");
    const web = oku("src/components/landing/MascotFab.tsx");
    const css = oku("src/components/landing/landingFlutterParity.module.css");
    expect(flutter).toContain("_vixrexBadgeSize = 60");
    expect(flutter).toContain("maxWidth: 220");
    expect(flutter).toContain("Duration(seconds: 6)");
    expect(flutter).toContain("Duration(milliseconds: 1800)");
    expect(web).toContain("h-[60px] w-[60px]");
    expect(web).toContain("max-w-[220px]");
    expect(web).toContain("6000");
    expect(css).toContain("1800ms ease-in-out infinite alternate");
  });
});
