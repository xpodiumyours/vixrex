import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PUBLIC_WEB = resolve(__dirname, "..");
const REPO_ROOT = resolve(PUBLIC_WEB, "..");
const okuWeb = (path: string) => readFileSync(resolve(PUBLIC_WEB, path), "utf8");
const okuRepo = (path: string) => readFileSync(resolve(REPO_ROOT, path), "utf8");

describe("landing responsive parity guard — Flutter referans", () => {
  const flutterHero = okuRepo("lib/widgets/landing/landing_hero_section.dart");
  const webHero = okuWeb("src/components/landing/HeroSection.tsx");
  const flutterValueBand = okuRepo("lib/widgets/landing/landing_value_band.dart");
  const webValueBand = okuWeb("src/components/landing/ValueBand.tsx");

  it("hero formu viewport değil kendi 500px container genişliğine göre satıra geçer", () => {
    expect(flutterHero).toContain("formConstraints.maxWidth > 500");
    expect(webHero).toContain('className="mt-8 @container"');
    expect(webHero).toContain("@min-[500px]:flex-row");
    expect(webHero).not.toContain("min-[500px]:flex-row min-[500px]:items-center");
  });

  it("güven rozetleri Flutter 14px yatay padding ve 8px ikon boşluğunu korur", () => {
    expect(flutterHero).toContain("horizontal: 14, vertical: 8");
    expect(flutterHero).toContain("const SizedBox(width: 8)");
    expect(webHero).toContain("gap-2 rounded-[20px]");
    expect(webHero).toContain("px-3.5 py-2 text-[12px]");
  });

  it("değer bandı Flutter 5:4 kolon oranını korur", () => {
    expect(flutterValueBand).toContain("Expanded(flex: 5, child: copy)");
    expect(flutterValueBand).toContain("Expanded(flex: 4, child: chips)");
    expect(webValueBand).toContain('className="md:flex-[5]"');
    expect(webValueBand).toContain("md:flex-[4] md:justify-end");
  });
});
