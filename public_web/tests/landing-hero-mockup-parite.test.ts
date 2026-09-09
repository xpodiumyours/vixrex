import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

/**
 * Landing telefon mockup paritesi — 2026-09-08 CANLI denetimden doğdu.
 *
 * Yöntem: eski denetim raporlarına güvenilmedi. İki uygulama da bugünün
 * koduyla çalıştırıldı (Flutter Web :5001, Next :3000), Playwright ile
 * masaüstü+mobil ekran görüntüleri alındı ve farklar iki kaynak kodda
 * tek tek doğrulandı. Bu testler düzeltmenin geri dönmesini kilitler.
 *
 * Flutter referansları:
 *  - lib/widgets/landing/landing_hero_mockup.dart (rozetler + noktalar)
 *  - lib/widgets/landing/phone_mockup.dart (telefon iç yapısı)
 *  - lib/screens/landing_screen.dart (rozet metinleri)
 */
describe("landing telefon mockup Flutter referansıyla eşit (2026-09-08 canlı denetim)", () => {
  const flutterMockup = oku("../lib/widgets/landing/landing_hero_mockup.dart");
  const flutterPhone = oku("../lib/widgets/landing/phone_mockup.dart");
  const mockup = oku("src/components/landing/PhoneMockup.tsx");
  const slaytlar = oku("src/components/landing/PhoneMockupSlaytlari.tsx");
  const profiller = oku("src/components/landing/mockupProfilleri.ts");

  it("slayt noktaları telefonun DIŞINDA: 32px alt boşluk, aktif 24×8 / pasif 8×8, 260ms", () => {
    // Flutter: noktalar mockup Column'unun devamı (telefon gövdesinin kardeşi)
    expect(flutterMockup).toContain("const SizedBox(height: 32)");
    expect(flutterMockup).toContain("width: isActive ? 24 : 8");
    expect(flutterMockup).toContain("duration: const Duration(milliseconds: 260)");

    // Next: noktalar PhoneMockup'ta, telefon gövdesiyle kardeş
    expect(mockup).toContain("Slayt gösterge noktaları");
    expect(mockup).toContain("duration-[260ms]");
    expect(mockup).toContain('sira === aktif ? "w-6 bg-lp-primary" : "w-2 bg-lp-border"');
    // Eski hata: noktalar telefonun İÇİNDEYDİ — geri dönmesin.
    expect(slaytlar).not.toContain("Slayt gösterge noktaları");
  });

  it("yüzen rozetler aktif slayttan beslenir; etiket rengine göre tahmin edilmez", () => {
    expect(flutterMockup).toContain("activeProfile.badgeText");
    expect(flutterMockup).toContain("activeProfile.secondaryBadgeText");

    // Slayt state'i ortak ata PhoneMockup'ta; rozetler aynı profilden okur.
    expect(mockup).toContain("const [aktif, setAktif] = useState(0)");
    expect(mockup).toContain("profil.uStRozet.metin");
    expect(mockup).toContain("profil.altRozet.metin");

    // Kırılgan renk-ternary'si kaldırıldı; metinler tek kaynaktan gelir.
    expect(mockup).not.toContain('"#FF5A1F" ?');
    expect(slaytlar).not.toContain('"#FF5A1F" ?');
    expect(slaytlar).toContain("{profil.uStRozet.metin}");
    for (const metin of [
      "Galeri",
      "QR kod",
      "Menü",
      "Yol tarifi",
      "Randevu",
      "Instagram",
      "WhatsApp",
      "Konum",
    ]) {
      expect(profiller).toContain(`metin: "${metin}"`);
    }
  });

  it("rozet konumu Flutter ile eşit: sağ üst 100, sol ALT 120 (üstte değil)", () => {
    expect(flutterMockup).toContain("right: isNarrow ? -14 : -40");
    expect(flutterMockup).toContain("left: isNarrow ? -12 : -30");
    expect(mockup).toContain("-right-[14px] top-[100px]");
    expect(mockup).toContain("min-[408px]:-right-[40px]");
    expect(mockup).toContain("-left-[12px] bottom-[120px]");
    expect(mockup).toContain("min-[408px]:-left-[30px]");
    // Eski hata: sol rozet top-[72px] ile üstteydi.
    expect(mockup).not.toContain("top-[72px]");
  });

  it("rozet stili Flutter _buildFloatingBadge ile eşit: koyu zemin, mavi kenarlık", () => {
    expect(flutterMockup).toContain("AppColors.surface.withValues(alpha: 0.92)");
    expect(flutterMockup).toContain("primary.withValues(alpha: 0.28)");
    expect(mockup).toContain("border-lp-primary/30 bg-lp-surface/[0.92]");
    // Eski hata: beyaz zeminli rounded-full rozet.
    expect(mockup).not.toContain("bg-white/[0.92]");
  });

  it("kapak: 22px çentik boşluğu + 156px yükseklik (196px sapma düzeltildi)", () => {
    expect(flutterPhone).toContain("const SizedBox(height: 22)");
    expect(flutterPhone).toContain("height: 156");
    expect(slaytlar).toContain("mt-[22px] h-[156px]");
    expect(slaytlar).not.toContain("h-[196px]");
  });

  it("'Vitrin hazır' kartı Flutter stiliyle eşit; bağlantı sayısı profilden gelir", () => {
    expect(flutterPhone).toContain("'Vitrin hazır'");
    expect(flutterPhone).toContain("profile.links.length");
    expect(slaytlar).toContain("border-lp-border bg-lp-bg-light");
    expect(slaytlar).toContain("{profil.eylemSatirlari.length} bağlantı");
    // Eski hata: her profilde sabit "2 bağlantı" yazıyordu.
    expect(slaytlar).not.toContain(">2 bağlantı<");
  });

  it("slayt sırası tek sahipli: 4s döngü PhoneMockup'ta, Slaytlari saf çizim", () => {
    expect(mockup).toContain("4000");
    expect(slaytlar).not.toContain("setInterval");
    expect(slaytlar).toContain("aktif: number");
  });
});
