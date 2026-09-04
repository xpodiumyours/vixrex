import { describe, expect, it } from "vitest";
import { seciliAlaniBirakmaliMi } from "@/app/v/[slug]/hooks/useFieldSelection";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

const isletmeAdi = FIELD_BY_KEY.get("isletmeAdi")!;
const whatsapp = FIELD_BY_KEY.get("whatsapp")!;

describe("seciliAlaniBirakmaliMi — rehber seçimi serbest NLU'yu kilitlemez", () => {
  it("seçili alanın düz cevabında seçim korunur", () => {
    expect(seciliAlaniBirakmaliMi("Konak Kafe", isletmeAdi)).toBe(false);
  });

  it("seçili alan açıkça tarif edilirse seçim korunur", () => {
    expect(seciliAlaniBirakmaliMi("işletme adım Konak Kafe", isletmeAdi)).toBe(false);
  });

  it("esnaf başka alanı tarif etmeye başlarsa seçim bırakılır ve mesaj NLU'ya gider", () => {
    expect(
      seciliAlaniBirakmaliMi("whatsapp numaram 0542 180 25 73", isletmeAdi),
    ).toBe(true);
  });

  it("ters yönde de çalışır: whatsapp seçiliyken işletme adı mesajı seçimi bırakır", () => {
    expect(seciliAlaniBirakmaliMi("işletme adım Konak Kafe", whatsapp)).toBe(true);
  });

  it("seçili alan yoksa gereksiz temizleme yapılmaz", () => {
    expect(seciliAlaniBirakmaliMi("işletme adım Konak Kafe", null)).toBe(false);
  });
});
