import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

/**
 * GAP-09 / GAP-10-13 — Konum adımı label ve içerik paritesi.
 * Flutter lib/widgets/editor/location_editor_section.dart ve
 * lib/screens/vixrex_onboarding_chat_screen.dart referans.
 */
describe("GAP-09 konum adımı label ve erişilebilirlik", () => {
  const kaynak = oku("src/components/landing/LandingAsistanSohbeti.tsx");

  it("İl etiketi görünür ve select ile ilişkilendirilmiş", () => {
    expect(kaynak).toContain('htmlFor="asistan-il"');
    expect(kaynak).toContain('id="asistan-il"');
    expect(kaynak).toMatch(/İl\s*<span[^>]*>\s*\*\s*<\/span>/);
  });

  it("İlçe etiketi görünür ve select ile ilişkilendirilmiş", () => {
    expect(kaynak).toContain('htmlFor="asistan-ilce"');
    expect(kaynak).toContain('id="asistan-ilce"');
    expect(kaynak).toMatch(/İlçe\s*<span[^>]*>\s*\*\s*<\/span>/);
  });

  it("Açık adres etiketi görünür ve input ile ilişkilendirilmiş", () => {
    expect(kaynak).toContain('htmlFor="asistan-adres"');
    expect(kaynak).toContain('id="asistan-adres"');
    expect(kaynak).toMatch(/Açık Adres.*\*/);
  });

  it("placeholder yalnızca label yerine kullanılmamış — label var", () => {
    // Yalnız placeholder ile geçiştirme testi: label olmalı
    const labelCount = (kaynak.match(/htmlFor="asistan-/g) || []).length;
    expect(labelCount).toBeGreaterThanOrEqual(3);
  });

  it("zorunlu alanlar aria-required ve kırmızı yıldız içeriyor", () => {
    expect(kaynak).toContain('aria-required="true"');
    expect(kaynak).toContain('text-red-500');
  });

  it("hata mesajı role=alert ve aria-describedby ile alanlara bağlı", () => {
    expect(kaynak).toContain('role="alert"');
    expect(kaynak).toContain('aria-describedby');
    expect(kaynak).toContain('asistan-konum-hata');
  });

  it("konum adımında header ve input erişilebilirlik doğru", () => {
    // inputlar aria-required true, selectler de
    const requiredCount = (kaynak.match(/aria-required="true"/g) || []).length;
    expect(requiredCount).toBeGreaterThanOrEqual(3);
  });
});

describe("GAP-10 açık adres placeholder paritesi", () => {
  const kaynak = oku("src/components/landing/LandingAsistanSohbeti.tsx");

  it("Flutter örneği ile aynı placeholder kullanılıyor", () => {
    expect(kaynak).toContain("Örn: Çatalmeşe Mah. 207. Sokak No: 12");
  });
});

describe("GAP-11 GPS sırası paritesi", () => {
  const kaynak = oku("src/components/landing/LandingAsistanSohbeti.tsx");

  it("GPS butonu selectler ve adres inputundan sonra gelmeli", () => {
    const ilIndex = kaynak.indexOf('htmlFor="asistan-il"');
    const ilceIndex = kaynak.indexOf('htmlFor="asistan-ilce"');
    const adresIndex = kaynak.indexOf('htmlFor="asistan-adres"');
    const gpsIndex = kaynak.indexOf("GPS ile Konumumu Al");
    expect(ilIndex).toBeGreaterThan(-1);
    expect(ilceIndex).toBeGreaterThan(-1);
    expect(adresIndex).toBeGreaterThan(-1);
    expect(gpsIndex).toBeGreaterThan(-1);
    expect(ilIndex).toBeLessThan(gpsIndex);
    expect(ilceIndex).toBeLessThan(gpsIndex);
    expect(adresIndex).toBeLessThan(gpsIndex);
  });
});

describe("GAP-12/13 buton metni ve helper paritesi", () => {
  const kaynak = oku("src/components/landing/LandingAsistanSohbeti.tsx");

  it("onay butonu Flutter ile aynı metinde", () => {
    expect(kaynak).toContain("Konumu onayla, devam");
  });

  it("helper metin Devam etmek için: ... mevcut", () => {
    expect(kaynak).toContain("Devam etmek için:");
    expect(kaynak).toContain("konumEksigi()");
    expect(kaynak).toContain('id="asistan-konum-yardim"');
  });

  it("disabled durumu konumEksigi ile hesaplanıyor", () => {
    expect(kaynak).toContain("disabled={!!konumEksigi()}");
  });
});

describe("GAP-21 adres doğrulama entegrasyonu", () => {
  const kaynak = oku("src/components/landing/LandingAsistanSohbeti.tsx");
  const validator = oku("src/lib/addressValidator.ts");

  it("LandingAsistanSohbeti addressValidator kullanıyor", () => {
    expect(kaynak).toContain('from "@/lib/addressValidator"');
    expect(kaynak).toContain("addressHataMesaji");
  });

  it("konumuKaydet Flutter ile aynı hata mesajlarını kullanıyor", () => {
    expect(kaynak).toContain("İl ve ilçe gerekli. GPS ile bul ya da listeden seç.");
    expect(kaynak).toContain("addressHataMesaji(adres)");
  });

  it("addressValidator Flutter kurallarını içeriyor", () => {
    expect(validator).toContain("ADDRESS_MIN_LENGTH = 10");
    expect(validator).toContain("YER_BELIRTECLERI");
    expect(validator).toContain("cad");
    expect(validator).toContain("sok");
  });
});
