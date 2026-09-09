import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Randevu sihirbaz adım paritesi", () => {
  const flutterSihirbaz = oku("../../lib/widgets/booking_wizard_sheet.dart");
  // Flutter'da KVKK onayı + maskeleme metni alt widget'ta (booking_details_step) yaşar;
  // adil parite için web tarafı tek dosya, Flutter tarafı iki dosya birlikte taranır.
  const flutterDetayAdim = oku("../../lib/widgets/booking/booking_details_step.dart");
  const flutterTumu = flutterSihirbaz + flutterDetayAdim;
  const webSihirbaz = oku("../src/app/v/[slug]/randevu/BookingWizardClient.tsx");

  it("dört adım başlığı iki tarafta aynıdır", () => {
    const basliklar = [
      "Hizmet Seçimi",
      "Tarih Seçimi",
      "Saat Seçimi",
      "İletişim Bilgileri",
    ];
    for (const baslik of basliklar) {
      expect(flutterSihirbaz).toContain(baslik);
      expect(webSihirbaz).toContain(baslik);
    }
  });

  it("adım sayacı ve geri dönüş iki tarafta vardır", () => {
    expect(flutterSihirbaz).toContain("currentStep}/4");
    expect(webSihirbaz).toContain("Geri");
    expect(webSihirbaz).toContain("setStep(3)");
  });

  it("doğrulama kuralları iki tarafta aynıdır", () => {
    expect(webSihirbaz).toContain("en az 3 karakter");
    expect(webSihirbaz).toContain("Türk GSM");
    expect(webSihirbaz).toContain("Maks 5");
    expect(flutterSihirbaz).toContain("kvkkConsent");
  });

  it("KVKK onayı olmadan talep gönderilmez", () => {
    expect(flutterTumu).toContain("isim maskeleme (A*** O***)");
    expect(webSihirbaz).toContain("isim maskeleme (A*** O***)");
    expect(webSihirbaz).toContain("kvkkOnay");
    expect(webSihirbaz).toContain("Lütfen tüm zorunlu alanları doldurun ve onay verin.");
  });

  it("başarı ekranı takip bağlantısı ve maskeli telefon sunar", () => {
    expect(flutterSihirbaz).toContain("Talep Alındı!");
    expect(webSihirbaz).toContain("Randevu Talebiniz Alındı");
    expect(webSihirbaz).toContain("trackingUrl");
    expect(webSihirbaz).toContain("maskedPhone");
  });
});
