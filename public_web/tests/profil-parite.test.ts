import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Profil parite testi.
 *
 * Kural: Flutter ProfileScreen ile Next.js /app/profil ayni öğeleri gösterir.
 */

const flutterProfile = readFileSync(
  resolve(__dirname, "../../lib/screens/profile_screen.dart"),
  "utf8",
);
const nextProfile = readFileSync(
  resolve(__dirname, "../src/app/app/profil/page.tsx"),
  "utf8",
);

describe("profil parite (Flutter referansiyla)", () => {
  it("Flutter gibi vitrin linkini gosterir", () => {
    expect(flutterProfile).toContain("publicLink");
    expect(nextProfile).toMatch(/storeSlug|store\.slug/);
  });

  it("Flutter gibi QR kodu gosterir", () => {
    expect(flutterProfile).toContain("onShowQr");
    expect(nextProfile).toContain("VitrinQrSheet");
  });

  it("Flutter gibi linki kopyalar", () => {
    expect(flutterProfile).toContain("onCopyLink");
    expect(nextProfile).toMatch(/copy|kopyala/i);
  });

  it("Flutter gibi kullanici bilgilerini gosterir", () => {
    expect(flutterProfile).toContain("AuthService");
    expect(nextProfile).toContain("user");
  });

  it("Flutter gibi ayarlara link verir", () => {
    expect(flutterProfile).toContain("AppSettingsScreen");
    expect(nextProfile).toContain("ayarlar");
  });
});