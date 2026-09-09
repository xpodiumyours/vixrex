import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PUBLIC_WEB = resolve(__dirname, "..");
const REPO_ROOT = resolve(PUBLIC_WEB, "..");
const okuWeb = (path: string) => readFileSync(resolve(PUBLIC_WEB, path), "utf8");
const okuRepo = (path: string) => readFileSync(resolve(REPO_ROOT, path), "utf8");

describe("landing phone mockup parity guard — Flutter referans", () => {
  const flutterMockup = okuRepo("lib/widgets/landing/landing_hero_mockup.dart");
  const webMockup = okuWeb("src/components/landing/PhoneMockup.tsx");

  it("chat telefonun iç ekranına gömülmez; dış stack üzerinde 10px/36px overlay olur", () => {
    expect(flutterMockup).toContain("Positioned.fill(");
    expect(flutterMockup).toContain("padding: const EdgeInsets.all(10)");
    expect(flutterMockup).toContain("borderRadius: BorderRadius.circular(36)");

    expect(webMockup).toContain('className="absolute inset-[10px] z-30 overflow-hidden rounded-[36px]"');
    expect(webMockup).toContain("<LandingApkAssistant");
  });

  it("telefon slayt katmanı chat açıkken de altta kalır; chat yalnız üst overlaydir", () => {
    expect(webMockup).toContain("<PhoneMockupSlaytlari profiller={profiller} aktif={aktif} />");
    expect(webMockup).not.toContain("isChatOpen ? (\n              <LandingApkAssistant");
  });
});
