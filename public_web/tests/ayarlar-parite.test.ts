import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Ayarlar parite testi.
 */

const flutterSettings = readFileSync(
  resolve(__dirname, "../../lib/screens/app_settings_screen.dart"),
  "utf8",
);
const nextSettings = readFileSync(
  resolve(__dirname, "../src/app/app/ayarlar/page.tsx"),
  "utf8",
);

describe("ayarlar parite (Flutter referansiyla)", () => {
  it("Flutter gibi bildirim tercihlerini icerir", () => {
    expect(flutterSettings).toContain("NotificationPreferencesService");
    expect(flutterSettings).toContain("bookingPushEnabled");
  });

  it("Flutter gibi veri indirme (KVKK) sunar", () => {
    expect(flutterSettings).toContain("_exportingData");
    expect(nextSettings).toContain("verileriDisaAktar");
  });

  it("Flutter gibi hesap silme sunar", () => {
    expect(flutterSettings).toContain("_deletingAccount");
    expect(nextSettings).toContain("hesap");
  });

  it("Flutter gibi yasal linkler icerir", () => {
    expect(flutterSettings).toContain("legal_screen");
    expect(nextSettings).toContain("Gizlilik");
  });

  it("Flutter gibi profil yonlendirmesi yapar", () => {
    expect(nextSettings).toContain("profil");
  });
});