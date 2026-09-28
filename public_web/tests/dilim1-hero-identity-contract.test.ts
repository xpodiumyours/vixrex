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

  it("masaüstü hero 420/440 standardını ve erken kategori başlangıcını korur", () => {
    expect(viewSource).toContain("lg:min-h-[420px] xl:min-h-[440px]");
    expect(viewSource).not.toContain("lg:min-h-[560px]");
    expect(viewSource).toContain("lg:px-12 lg:py-10");
    expect(viewSource).not.toContain("lg:px-12 lg:py-16");
  });

  it("masaüstünde aksiyonlar sağ sütunda değil kimlik bilgilerinin altında kompakt satırdadır", () => {
    expect(viewSource).toContain("mt-3 hidden flex-wrap items-center gap-2 lg:flex");
    expect(viewSource).toContain("px-3 py-1.5 text-[13px]");
    expect(viewSource).toContain("sm:flex-row md:flex-col lg:hidden");
    expect(viewSource).not.toContain("lg:w-[260px] lg:min-w-0");
  });

  it("masaüstü tipografi kompakt, mobil/tablet ölçüleri korunur", () => {
    expect(viewSource).toContain("text-3xl sm:text-5xl lg:text-[40px]");
    expect(viewSource).toContain("text-sm sm:text-base lg:text-[15px]");
    expect(viewSource).toContain("text-[26px] sm:text-4xl lg:text-[30px]");
    expect(viewSource).toContain("lg:px-12 lg:py-7");
  });

  it("uydurma Google Maps ikonu yok; mevcut pin ve gerçek WhatsApp glifi kullanılır", () => {
    expect(viewSource).not.toContain("GoogleMapsIcon");
    expect(viewSource).toContain("<MapPinIcon size={16} />");
    expect(viewSource).toContain("<MapPinIcon size={18} />");
    expect(viewSource).toContain('text-[#25D366]');
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
