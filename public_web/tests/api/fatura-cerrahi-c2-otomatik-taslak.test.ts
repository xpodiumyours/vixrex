import { describe, expect, it } from "vitest";
import { otomatikTaslakAdayi } from "@/lib/faturaTaslakAdayi";

describe("C2 — kaynağı bilinen ürünün otomatik taslağı", () => {
  const kaynak = {
    model: "RESMI-001", barkod: "", sonuc: "eksik",
    katalog: { resmiAd: "Üretici model", kaynak: "https://uretici.example/model", dayanak: "kod" },
  };
  it("fotoğrafı henüz bulunmasa da kimliği kodla eşleşen ürünü kaybetmez", () => {
    expect(otomatikTaslakAdayi(kaynak)).toBe(true);
  });
  it("kimlik çelişkisi, bulunmayan kaynak ve koda dair kanıt yoksa reddeder", () => {
    expect(otomatikTaslakAdayi({ ...kaynak, sonuc: "celiski" })).toBe(false);
    expect(otomatikTaslakAdayi({ ...kaynak, katalog: null })).toBe(false);
    expect(otomatikTaslakAdayi({ ...kaynak, model: "" })).toBe(false);
    expect(otomatikTaslakAdayi({ ...kaynak, katalog: { ...kaynak.katalog, kaynak: "http://uretici.example" } })).toBe(false);
  });
  it("yalnız benzer ürün adına dayanan, doğrulanmamış adayı otomatik kaydetmez", () => {
    expect(otomatikTaslakAdayi({ ...kaynak, katalog: { ...kaynak.katalog, dayanak: "ad" } })).toBe(false);
  });
});
