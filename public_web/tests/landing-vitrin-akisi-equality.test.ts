import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

function appRouteVarMi(route: string): boolean {
  const parcalar = route.replace(/^\//, "").split("/").filter(Boolean);
  return [
    resolve(KOK, "src/app", ...parcalar, "page.tsx"),
    resolve(KOK, "src/app/(site)", ...parcalar, "page.tsx"),
  ].some(existsSync);
}

describe("landing vitrin oluşturma akışı Flutter referansıyla eşit", () => {
  it("düğme var olan Vixrex Asistanı açar ve işletme adını sonraki adıma taşır", () => {
    const hero = oku("src/components/landing/HeroSection.tsx");
    const wrapper = oku("src/components/landing/LandingChatWrapper.tsx");
    const bottomCta = oku("src/components/landing/BottomCta.tsx");
    const sohbet = oku("src/components/landing/LandingAsistanSohbeti.tsx");

    const action = hero.match(/<form[\s\S]*?action="([^"]+)"/)?.[1];
    if (action) {
      expect(
        appRouteVarMi(action),
        `Landing düğmesi ${action} adresine gidiyor fakat bu route yok; yeni ` +
          "sayfa üretmek yerine mevcut Vixrex Asistan akışına bağlanmalı.",
      ).toBe(true);
    }

    expect(hero).toContain("onStartAssistant(isletmeAdi.trim())");
    expect(wrapper).toContain("handleStartAssistant");
    expect(wrapper).toContain("initialAssistantName={initialAssistantName}");
    expect(bottomCta).toContain("onStartAssistant");
    expect(sohbet).toContain("initialName");
    expect(sohbet).toContain("name: initialName.trim()");
  });

  it("APK mobil açılış hareketini birebir korur: 768px / 560px / 450ms easeOutCubic", () => {
    const flutterLanding = oku("../lib/screens/landing_screen.dart");
    const wrapper = oku("src/components/landing/LandingChatWrapper.tsx");
    const phoneMockup = oku("src/components/landing/PhoneMockup.tsx");

    expect(flutterLanding).toContain("final isMobile = MediaQuery.sizeOf(context).width <= 768");
    expect(flutterLanding).toContain("final targetOffset = isMobile ? 560.0 : 0.0");
    expect(flutterLanding).toContain("duration: const Duration(milliseconds: 450)");
    expect(flutterLanding).toContain("curve: Curves.easeOutCubic");

    expect(wrapper).toContain("window.innerWidth <= 768 ? 560 : 0");
    expect(wrapper).toContain("const sure = 450");
    expect(wrapper).toContain("1 - Math.pow(1 - oran, 3)");
    expect(wrapper).not.toContain("scrollIntoView");
    expect(phoneMockup).toContain("<LandingAsistanSohbeti");
  });
});
