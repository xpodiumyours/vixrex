import { describe, expect, it } from "vitest";
import { alignVariantsToDefinitions } from "../src/components/owner/OwnerRichProductFields";
import { productAttributesForTemplate } from "../src/lib/productAttributeSchema";

const giyimVaryantAlanlari = productAttributesForTemplate("fashion").filter(
  (alan) => alan.variantEligible,
);

describe("esnaf formunda varyant ekleme", () => {
  it("yeni eklenen boş varyant ekrandan silinmez", () => {
    const sonuc = alignVariantsToDefinitions(
      [{ id: "yeni-1", options: {} }],
      giyimVaryantAlanlari,
      false,
      null,
    );

    expect(sonuc).toHaveLength(1);
    expect(sonuc[0].id).toBe("yeni-1");
  });

  it("değer yazılırken satır kaybolmaz", () => {
    const sonuc = alignVariantsToDefinitions(
      [{ id: "yeni-1", options: { color: "Siyah", size: "" } }],
      giyimVaryantAlanlari,
      false,
      null,
    );

    expect(sonuc).toHaveLength(1);
    expect(sonuc[0].options).toEqual({ color: "Siyah" });
  });

  it("şablonda olmayan seçenek anahtarı temizlenir", () => {
    const sonuc = alignVariantsToDefinitions(
      [{ id: "yeni-1", options: { color: "Siyah", uydurma: "x" } }],
      giyimVaryantAlanlari,
      false,
      null,
    );

    expect(sonuc[0].options).toEqual({ color: "Siyah" });
  });

  it("hizmet ürününde varyant alanı yoksa liste boşalır", () => {
    const sonuc = alignVariantsToDefinitions([{ id: "yeni-1", options: {} }], [], true, null);
    expect(sonuc).toHaveLength(0);
  });
});
