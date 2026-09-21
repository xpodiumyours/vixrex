import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const pageSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/page.tsx"),
  "utf-8"
);
const viewSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

describe("Dilim 1 hero kimlik alanları", () => {
  it("page heroBadge/phone/email prop’larını view’a geçirir", () => {
    expect(pageSource).toContain("heroBadge={displayHeroBadge || null}");
    expect(pageSource).toContain("phone={displayPhone || null}");
    expect(pageSource).toContain("phoneUrl={phoneUrl}");
    expect(pageSource).toContain("email={displayEmail || null}");
    expect(pageSource).toContain('tel:+${phoneDigits}');
  });

  it("view boş alanları gizler ve sahte e-posta/puan kullanmaz", () => {
    expect(viewSource).toContain("heroButonlari.length > 0 &&");
    expect(viewSource).toContain("heroActions(profile,");
    // 28 Ağustos: rozet artık `displayBadge` ile çizilmiyor.
    // `displayBadge` boşken KATEGORİYE düşüyordu, bu yüzden rozet ile
    // hemen altındaki kimlik satırı aynı kelimeyi yazıyor ve sayfa
    // "her bilgi iki kez" görünüyordu. Rozet artık yalnız sahibin
    // yazdığı ÖZEL metinle (`heroBadge`) çıkıyor; kategori kimlik
    // satırında tek kez duruyor. Testin niyeti aynı — boş alan
    // gösterilmesin — koşul daha da sıkılaştı.
    expect(viewSource).toContain("heroBadge && heroBadge.trim() &&");
    expect(viewSource).toContain("hasPhone &&");
    expect(viewSource).toContain("displayEmail &&");
    expect(viewSource).not.toContain("merhaba@${storeSlug}.com");
    expect(viewSource).not.toContain("4.9 (128 değerlendirme)");
  });

  it("masaüstü hero ortak yükseklik standardını ve sıkı kategori aralığını korur", () => {
    expect(viewSource).toContain(
      "lg:min-h-[420px] xl:min-h-[440px] 2xl:min-h-[460px]"
    );
    expect(viewSource).not.toContain("lg:min-h-[560px]");
    expect(viewSource).toContain("lg:px-12 lg:py-10");
    expect(viewSource).not.toContain("lg:px-12 lg:py-16");
  });

  it("yalnız doğrulanmış işletmede güven rozeti gösterir", () => {
    expect(pageSource).toContain("business_verified_at");
    expect(pageSource).toContain("PUBLIC_STORE_SELECT_WITH_VERIFICATION");
    expect(pageSource).toContain(
      "isBusinessVerified={Boolean(store.business_verified_at)}"
    );
    expect(viewSource).toContain("isBusinessVerified &&");
    expect(viewSource).toContain("Doğrulanmış işletme");
    expect(viewSource).not.toContain("Doğrulanmamış işletme");
  });
});
