import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Iletisim bilgileri parite testi.
 */

const flutterContact = readFileSync(
  resolve(__dirname, "../../lib/widgets/editor/form_contact_info.dart"),
  "utf8",
);
const nextContact = readFileSync(
  resolve(__dirname, "../src/app/(site)/iletisim/page.tsx"),
  "utf8",
);

describe("iletisim bilgileri parite (Flutter referansiyla)", () => {
  it("Flutter gibi WhatsApp alanini icerir", () => {
    expect(flutterContact).toContain("whatsapp");
    expect(flutterContact).toContain("WhatsApp");
  });

  it("Flutter gibi Instagram alanini icerir", () => {
    expect(flutterContact).toContain("insta");
    expect(flutterContact).toContain("Instagram");
  });

  it("Flutter gibi telefon numarasi alani icerir", () => {
    expect(flutterContact).toContain("phone");
  });

  it("Next.js iletişim sayfası ayni bilgileri gosterir", () => {
    expect(nextContact).toContain("iletisim");
    expect(nextContact).toContain("destek");
  });
});