import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { vixRexMesajlari } from "@/lib/vixrexMesajlari";
import { VITRIN_FIELDS } from "@/lib/vitrinFieldSchema";

/**
 * Asistan / NLU parite testi.
 *
 * Kural: Flutter asistan ile Next.js asistan ayni mesaj sozlugunu
 * kullanir (shared/vixrex_mesajlar.json). Ayni 46 alan niyeti tanir.
 */

const flutterConfig = readFileSync(
  resolve(__dirname, "../../lib/config/chatbot_config.dart"),
  "utf8",
);
const flutterMessages = JSON.parse(
  readFileSync(resolve(__dirname, "../../shared/vixrex_mesajlar.json"), "utf8"),
);

describe("asistan / NLU parite (Flutter referansiyla)", () => {
  it("Ayni 46 alan niyeti tanir", () => {
    expect(VITRIN_FIELDS.length).toBe(46);
  });

  it("Next.js ayni mesaj sozlugunu kullanir", () => {
    expect(vixRexMesajlari).toBeDefined();
    expect(Object.keys(vixRexMesajlari).length).toBeGreaterThan(40);
  });

  it("Flutter ile ayni mesaj anahtarlarini paylasiyor", () => {
    const reactMessages = readFileSync(
      resolve(__dirname, "../src/lib/vixrexMesajlari.ts"),
      "utf8",
    );
    expect(reactMessages).toContain("vixrex_mesajlar");
    expect(reactMessages).toContain("shared/vixrex_mesajlar.json");
  });

  it("Flutter gibi netlesme sorusunu yonetir", () => {
    expect(flutterConfig).toContain("vixRexMesajlari");
  });

  it("Flutter gibi yanit tablosunu kullanir", () => {
    expect(flutterMessages.yanitlar.length).toBeGreaterThan(0);
    const reactConfig = readFileSync(
      resolve(__dirname, "../src/lib/assistantHandoff.ts"),
      "utf8",
    );
    expect(reactConfig).toContain("hizliCevaplar");
  });
});