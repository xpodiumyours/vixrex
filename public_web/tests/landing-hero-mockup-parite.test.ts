import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

describe("landing telefon mockup sinematik vitrin sözleşmesi", () => {
  const flutterMockup = oku("../lib/widgets/landing/landing_hero_mockup.dart");
  const mockup = oku("src/components/landing/PhoneMockup.tsx");
  const slaytlar = oku("src/components/landing/PhoneMockupSlaytlari.tsx");
  const profiller = oku("src/components/landing/mockupProfilleri.ts");

  it("slayt noktaları telefonun DIŞINDA, tıklanabilir ve 260ms geçişlidir", () => {
    expect(flutterMockup).toContain("width: isActive ? 24 : 8");
    expect(flutterMockup).toContain("duration: const Duration(milliseconds: 260)");

    expect(mockup).toContain("Slayt gösterge noktaları");
    expect(mockup).toContain("duration-[260ms]");
    expect(mockup).toContain('sira === aktif ? "w-6 bg-lp-primary" : "w-2 bg-lp-border"');
    expect(mockup).toContain('<button');
    expect(mockup).toContain('setAktif(sira)');
    expect(slaytlar).not.toContain("Slayt gösterge noktaları");
  });

  it("telefon kasası 3D eğimli başlar, sohbet açılınca düzleşir ve tıklanabilir", () => {
    expect(mockup).toContain("lp-phone-chassis");
    expect(mockup).toContain("lp-phone-chassis-straight");
    expect(mockup).toContain("onOpenChat?.()");
  });

  it("slaytlar yeni mobil vitrin kartı düzenini ve R2 şablonlarını kullanır", () => {
    expect(profiller).toContain("kategoriSablonHaritasi");
    expect(profiller).not.toContain("data:image/");
    expect(slaytlar).not.toContain("data:image/");
    expect(slaytlar).toContain("profil.basHarfler");
    expect(slaytlar).toContain("profil.konumSatiri");
    expect(slaytlar).toContain("profil.calismaSaati");
    expect(slaytlar).toContain("profil.aksiyonHaplari");
    expect(slaytlar).toContain("profil.vitrinKartlari");
    expect(slaytlar).toContain("profil.bolumBasligi");
  });

  it("telefon slaytlarında sahte puan veya değerlendirme metni bulunmaz", () => {
    const svgHaricSlaytlar = slaytlar.replace(/<svg[\s\S]*?<\/svg>/g, "");
    const birlesik = `${profiller}\n${svgHaricSlaytlar}`;
    expect(birlesik).not.toContain("★");
    expect(birlesik).not.toContain("4.9");
    expect(birlesik).not.toContain("4.8");
    expect(birlesik.toLocaleLowerCase("tr-TR")).not.toContain("değerlendirme");
  });

  it("slayt sırası tek sahipli: 4s döngü PhoneMockup'ta ve sohbet açıkken duraklar, Slaytlari saf çizim", () => {
    expect(mockup).toContain("4000");
    expect(mockup).toContain("if (profiller.length < 2 || isChatOpen) return;");
    expect(slaytlar).not.toContain("setInterval");
    expect(slaytlar).toContain("aktif: number");
  });
});
