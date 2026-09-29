import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Gizlilik politikası — üçüncü taraf beyanı sözleşmesi (issue #292).
 *
 * Önceki metin "Verileriniz üçüncü taraflarla paylaşılmaz. Tek istisna,
 * yasal zorunluluklardır." diyordu — bu yanlıştı, çünkü Google Analytics,
 * reCAPTCHA, Sentry ve Cloudflare Turnstile'a gerçekten veri gidiyor.
 * Bu test, yanlış beyanın geri gelmediğini ve gerçek sağlayıcıların
 * listelendiğini doğrular — birisi ileride yeni bir üçüncü taraf
 * entegrasyonu eklerse (ör. yeni bir analytics/ödeme sağlayıcısı) bu
 * sayfayı unutmasın diye de bir hatırlatıcı.
 */

const pageSource = readFileSync(
  resolve(__dirname, "../src/app/privacy/page.tsx"),
  "utf-8"
);

const siparisPaneli = readFileSync(
  resolve(__dirname, "../src/components/SiparisPaneli.tsx"),
  "utf-8"
);

describe("Gizlilik politikası — üçüncü taraf paylaşımı doğru beyan ediyor", () => {
  it("'üçüncü taraflarla paylaşılmaz' yanlış beyanı YOK", () => {
    expect(pageSource).not.toContain(
      "Verileriniz üçüncü taraflarla paylaşılmaz"
    );
  });

  it.each([
    "Supabase",
    "Vercel",
    "Google Analytics",
    "Google reCAPTCHA",
    "Cloudflare Turnstile",
    "Sentry",
    "Meta / Instagram",
    "PayTR",
    "OneSignal",
  ])("gerçekten kullanılan sağlayıcı listeleniyor: %s", (provider) => {
    expect(pageSource).toContain(provider);
  });
});

describe("Gizlilik politikası — sipariş verisi beyan ediliyor", () => {
  it("sipariş verisi, toplanan veriler arasında sayılıyor", () => {
    expect(pageSource).toContain("Sipariş verileri:");
  });

  it("PayTR beyanı sipariş ödemesini de kapsıyor", () => {
    expect(pageSource).toContain("siparişin online ödemesi");
  });

  it("sipariş verisi için silme yolu yazılı", () => {
    expect(pageSource).toContain("silinmesini talep etmek");
  });

  it("sipariş formu gizlilik politikasına bağlanıyor", () => {
    expect(siparisPaneli).toContain('href="/privacy"');
  });
});
