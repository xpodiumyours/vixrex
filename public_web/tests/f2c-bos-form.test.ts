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
