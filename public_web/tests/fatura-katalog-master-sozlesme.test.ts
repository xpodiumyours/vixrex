import { existsSync, readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const kok = resolve(__dirname, "../..");
const sozlesme = JSON.parse(
  readFileSync(resolve(kok, "shared/fatura_katalog_kanit_sozlesmesi.json"), "utf8"),
) as { core_rule: string; rules: Array<{ id: string }> };

function havuzDosyasiVar(): boolean {
  const klasor = resolve(kok, "public_web/data/katalog");
  if (!existsSync(klasor)) return false;
  return readdirSync(klasor).some((ad) => /^uretici-katalog-/.test(ad) || ad === "_firmalar.json");
}

describe("uretici urun havuzu yok kilidi", () => {
  it("Casper 2026-10-09: havuz dosyasi geri gelmez", () => {
    expect(havuzDosyasiVar()).toBe(false);
    expect(existsSync(resolve(kok, "public_web/scripts/katalog"))).toBe(false);
    expect(existsSync(resolve(kok, "public_web/src/lib/ureticiKatalog.ts"))).toBe(false);
    expect(existsSync(resolve(kok, "tool/fatura_havuz_olc.mjs"))).toBe(false);
  });

  it("zayif kanitta tahmin etmeme ve yayin onayi kurallarini korur", () => {
    expect(sozlesme.core_rule).toBe("strong_trace_auto_prepare_partial_trace_ask_weak_trace_no_guess");
    expect(sozlesme.rules.map((r) => r.id)).toEqual(
      expect.arrayContaining([
        "no_guess_on_weak_product_identity",
        "merchant_approval_required_for_publish",
        "purchase_price_is_not_sale_price",
      ]),
    );
  });
});
