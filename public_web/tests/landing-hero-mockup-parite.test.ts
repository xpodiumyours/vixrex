import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

describe("landing telefon mockup Flutter referansıyla eşit", () => {
  const flutterMockup = oku("../lib/widgets/landing/landing_hero_mockup.dart");
  const flutterPhone = oku("../lib/widgets/landing/phone_mockup.dart");
  const flutterLanding = oku("../lib/screens/landing_screen.dart");
  const mockup = oku("src/components/landing/PhoneMockup.tsx");
  const slaytlar = oku("src/components/landing/PhoneMockupSlaytlari.tsx");
  const profiller = oku("src/components/landing/mockupProfilleri.ts");
  const apkAssistant = oku("src/components/landing/LandingApkAssistant.tsx");

  it("telefon dış gövdesi Flutter 325×640 ölçüsünde ve 640/700 ölçeğinde", () => {
    expect(flutterPhone).toContain("width: 325");
    expect(flutterPhone).toContain("height: 640");
    expect(flutterPhone).toContain("constraints.maxHeight / 700");
    expect(mockup).toContain("h-[640px] w-[325px]");
    expect(mockup).toContain("scale-[0.9142857]");
  });

  it("slayt noktaları telefon dışında: 32px boşluk, 24×8 / 8×8, 260ms", () => {
    expect(flutterMockup).toContain("const SizedBox(height: 32)");
    expect(flutterMockup).toContain("width: isActive ? 24 : 8");
    expect(flutterMockup).toContain("duration: const Duration(milliseconds: 260)");
    expect(mockup).toContain("mt-8 flex items-center justify-center");
    expect(mockup).toContain("duration-[260ms]");
    expect(mockup).toContain('sira === aktif ? "w-6 bg-lp-primary" : "w-2 bg-lp-border"');
    expect(slaytlar).not.toContain("duration-[260ms]");
  });

  it("yüzen rozetler aktif slayttan beslenir ve Flutter Material ikon adlarını kullanır", () => {
    expect(flutterMockup).toContain("activeProfile.badgeText");
    expect(flutterMockup).toContain("activeProfile.secondaryBadgeText");
    expect(mockup).toContain("profil.uStRozet.metin");
    expect(mockup).toContain("profil.altRozet.metin");
    expect(mockup).toContain("<MaterialRoundIcon name={profil.uStRozet.simge}");
    expect(mockup).toContain("<MaterialRoundIcon name={profil.altRozet.simge}");

    for (const ikon of [
      "photo_library",
      "qr_code_2",
      "menu_book",
      "directions",
      "calendar_month",
      "camera_alt",
      "chat_bubble",
      "location_on",
    ]) {
      expect(profiller).toContain(`simge: "${ikon}"`);
    }
    expect(profiller).not.toMatch(/[🖼📱📖📍📅📷💬]/u);
  });

  it("rozet konumu Flutter ile eşit: sağ üst 100, sol alt 120; dar eşik 408 viewport", () => {
    expect(flutterMockup).toContain("right: isNarrow ? -14 : -40");
    expect(flutterMockup).toContain("left: isNarrow ? -12 : -30");
    expect(mockup).toContain("-right-[14px] top-[100px]");
    expect(mockup).toContain("min-[408px]:-right-[40px]");
    expect(mockup).toContain("-left-[12px] bottom-[120px]");
    expect(mockup).toContain("min-[408px]:-left-[30px]");
  });

  it("kapak yapısı Flutter gibi: 22px çentik boşluğu + 156px kapak + 40px ana ikon + 24px ad", () => {
    expect(flutterPhone).toContain("const SizedBox(height: 22)");
    expect(flutterPhone).toContain("height: 156");
    expect(flutterPhone).toContain("width: 40");
    expect(flutterPhone).toContain("fontSize: 24");
    expect(slaytlar).toContain('h-[22px] shrink-0');
    expect(slaytlar).toContain('h-[156px]');
    expect(slaytlar).toContain('h-10 w-10');
    expect(slaytlar).toContain('text-[24px]');
  });

  it("demo mockup tıklaması Flutter gibi yayınlanmış demo vitrine gider", () => {
    for (const slug of [
      "demo-aymira-giyim",
      "demo-lezzet-duragi",
      "demo-nova-kuafor",
      "demo-teknofix",
    ]) {
      expect(flutterLanding).toContain(`'${slug}'`);
      expect(profiller).toContain(`demoSlug: "${slug}"`);
    }
    expect(profiller).toContain('hedefUrl: `/v/${tanim.demoSlug}`');
    expect(mockup).toContain("href={profil.hedefUrl}");
  });

  it("landing mockup asistanı ayrı state makinesi kurmaz; gerçek onboarding yüzeyine doğrudan delege eder", () => {
    expect(flutterMockup).toContain("VixRexOnboardingChatScreen(");
    expect(apkAssistant).toContain("<LandingAsistanSohbeti");
    expect(apkAssistant).not.toContain('useState<"welcome" | "name" | "chat">');
    expect(apkAssistant).not.toContain("Evet, Oluşturalım");
  });

  it("slayt sırası tek sahipli: Flutter 16s / 4 profil = web 4s", () => {
    expect(flutterLanding).toContain("duration: const Duration(seconds: 16)");
    expect(mockup).toContain("4000");
    expect(slaytlar).not.toContain("setInterval");
  });
});
