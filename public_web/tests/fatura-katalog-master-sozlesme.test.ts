import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

type Firma = { anahtar: string; sektor: string; izin: "yok" | "bekliyor" | "var" };

const kok = resolve(__dirname, "../..");
const firmalar = JSON.parse(
  readFileSync(resolve(kok, "public_web/scripts/katalog/firmalar.json"), "utf8"),
) as Firma[];
const katalogDosyalari = readdirSync(resolve(kok, "public_web/data/katalog")).filter(
  (ad) => /^uretici-katalog-.+\.json$/.test(ad),
);
const sozlesme = JSON.parse(
  readFileSync(resolve(kok, "shared/fatura_katalog_kanit_sozlesmesi.json"), "utf8"),
) as { core_rule: string; rules: Array<{ id: string }> };

describe("faturadan kataloga master kapsam kilidi", () => {
  it("55 firma havuzunu, 16 hazir katalogu ve 39 katalog bekleyen firmayi korur", () => {
    expect(firmalar).toHaveLength(55);
    expect(katalogDosyalari).toHaveLength(16);
    expect(firmalar.length - katalogDosyalari.length).toBe(39);
  });

  it("tekstil ve gida senaryolarini havuzda birlikte tutar", () => {
    expect(firmalar.filter((f) => f.sektor === "Tekstil")).toHaveLength(37);
    expect(firmalar.filter((f) => f.sektor === "Gıda")).toHaveLength(18);
  });

  it("izin durumunu tek kaynakta olculebilir tutar", () => {
    expect(firmalar.filter((f) => f.izin === "yok")).toHaveLength(54);
    expect(firmalar.filter((f) => f.izin === "bekliyor")).toHaveLength(1);
    expect(firmalar.filter((f) => f.izin === "var")).toHaveLength(0);
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
