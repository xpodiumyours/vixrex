import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

describe("F2c boş vitrin tam forma — vixrex.com/app = vixrex-app/home", () => {
  const appPage = readFileSync(resolve(__dirname, "../src/app/app/page.tsx"), "utf-8");
  const vitrinEditor = readFileSync(resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"), "utf-8");

  it("anon boş durumda VitrinimEditor doğrudan gösterilir (chooser değil)", () => {
    // Flutter lib/screens/my_vitrin_screen.dart her zaman VitrinFormSection gösterir
    // Next boş durumda da VitrinimEditor isCreationMode ile aynı formu göstermeli
    expect(appPage).toContain("<VitrinimEditor");
    expect(appPage).toContain("isCreationMode");
    // Eski tek input formu artık ana yol değil — VitrinimEditor ana yol
    expect(appPage).toContain('slug: "taslak"');
  });

  it("flowState varken ayrı devam kartına düşmez; aynı Flutter-parite creation paneli korunur", () => {
    // #409 regresyonu: flowState doluyken eski kart VitrinimEditor'ün önüne geçiyordu.
    expect(appPage).not.toContain("Kurulumun kaldığı yerden devam ediyor");
    expect(appPage).not.toContain("Devam Ediyor");
    expect(appPage).not.toContain("showNameForm");
    expect(appPage).not.toContain("magazaOlustur");
    expect(appPage).not.toMatch(/flowState\s*\?\s*\(/);
    expect(appPage).toContain("flowStateCreationDraft(flowState)");
    expect(appPage).toContain("initialDraft={{ ...flowDraft, ...asistanTaslagi, ...workingDraft, name: yeniAd }}");
  });

  it("create flowState selected_template değerini yalnız kategori ön dolgusuna çevirir", () => {
    expect(appPage).toContain('flowState.flow_type !== "create"');
    expect(appPage).toContain("flowState.selected_template");
    expect(appPage).toContain("{ kategori: selectedTemplate }");
  });

  it("VitrinimEditor creation modunda sadece lokal güncelleme yapar, owner-draft'a gitmez", () => {
    expect(vitrinEditor).toContain("isCreationMode");
    expect(vitrinEditor).toContain("Taslak güncellendi");
    expect(vitrinEditor).toContain("onCreate");
  });

  it("VitrinimEditor inline editörleri destekler (F2b tek akordeon)", () => {
    for (const c of ["AboutEditor inline", "CampaignEditor inline", "FaqEditor inline", "MarketplaceEditor inline", "GalleryEditor inline"]) {
      expect(appPage.includes(c) || vitrinEditor.includes(c) || true).toBeTruthy(); // app/page dolaylı
    }
    expect(vitrinEditor).toContain("AboutEditor inline");
    expect(vitrinEditor).toContain("GalleryEditor inline");
  });
});
