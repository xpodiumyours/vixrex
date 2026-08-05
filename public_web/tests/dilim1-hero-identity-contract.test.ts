import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const pageSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/page.tsx"),
  "utf-8"
);
const viewSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

describe("Dilim 1 hero kimlik alanları", () => {
  it("page heroBadge/phone/email prop’larını view’a geçirir", () => {
    expect(pageSource).toContain("heroBadge={displayHeroBadge || null}");
    expect(pageSource).toContain("phone={displayPhone || null}");
    expect(pageSource).toContain("phoneUrl={phoneUrl}");
    expect(pageSource).toContain("email={displayEmail || null}");
    expect(pageSource).toContain('tel:+${phoneDigits}');
  });

  it("view boş alanları gizler ve sahte e-posta/puan kullanmaz", () => {
    expect(viewSource).toContain("heroButonlari.length > 0 &&");
    expect(viewSource).toContain("heroActions(profile,");
    expect(viewSource).toContain("displayBadge &&");
    expect(viewSource).toContain("hasPhone &&");
    expect(viewSource).toContain("displayEmail &&");
    expect(viewSource).not.toContain("merhaba@${storeSlug}.com");
    expect(viewSource).not.toContain("4.9 (128 değerlendirme)");
  });
});
