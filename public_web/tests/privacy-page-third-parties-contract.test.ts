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
const contactSource = readFileSync(
  resolve(__dirname, "../src/app/(site)/iletisim/page.tsx"),
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

describe("R-02 — gizlilik beyanı ile yürürlükteki aydınlatma bağlantısı", () => {
  it("hesap silinince bütün kayıtların koşulsuz silindiğini vaat etmez", () => {
    expect(pageSource).not.toContain(
      "Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir."
    );
    expect(pageSource).toContain("Yasal saklama yükümlülüğü");
  });

  it("saklama açıklaması yürürlükteki KVKK aydınlatmasına yönlendirir", () => {
    expect(pageSource).toContain('href="/legal/privacy"');
  });

  it("KVKK başvuruları iletişim sayfasında sürümlü aydınlatma metnine yönlenir", () => {
    expect(contactSource).toContain('yol: "/legal/privacy"');
    expect(contactSource).toContain("KVKK Aydınlatma Metni");
  });

  it("kanıtlanmış kurumsal iletişim adresi korunur", () => {
    expect(pageSource).toContain("mailto:destek@vixrex.com");
    expect(pageSource).not.toContain("vixrex.app@gmail.com");
    expect(pageSource).not.toContain("Xpodiumyours@gmail.com");
  });
});
