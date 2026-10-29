import { describe, expect, it } from "vitest";
import { kategoriAnahtari, kategoriBirlestir } from "../src/lib/kategoriBirlesim";

describe("kategori birleştirme", () => {
  it("ayraç farkını tek biçime çevirir", () => {
    expect(kategoriBirlestir("Gıda / Şeker")).toEqual(kategoriBirlestir("Gıda > Şeker"));
    expect(kategoriBirlestir("Gıda / Şeker").ad).toBe("Gıda / Şeker");
    expect(kategoriBirlestir("Süt Ürünleri > Peynir").ad).toBe("Süt Ürünleri / Peynir");
    expect(kategoriBirlestir("İçecek & Gazlı İçecek").ad).toBe("İçecek / Gazlı İçecek");
  });

  it("parantezli eki ve sıralama farkını yakalar", () => {
    expect(kategoriBirlestir("İçecek > Gazlı İçecek (Kola)")).toEqual(
      kategoriBirlestir("İçecek / Gazlı İçecek"),
    );
    expect(kategoriBirlestir("Bisküvi / Atıştırmalık")).toEqual(
      kategoriBirlestir("Atıştırmalık > Bisküvi"),
    );
    expect(kategoriBirlestir("Bisküvi / Atıştırmalık").ad).toBe("Atıştırmalık / Bisküvi");
    expect(kategoriBirlestir("Atıştırmalık > Sandviç Bisküvi").ad).toBe("Atıştırmalık / Bisküvi");
    expect(kategoriBirlestir("Atıştırmalık > Çikolata Kaplı Gofret").ad).toBe("Atıştırmalık / Gofret");
  });

  it("üst kategori farklı yazılsa da aynı alt kategori tek olur", () => {
    expect(kategoriBirlestir("Gıda / Süt")).toEqual(kategoriBirlestir("Süt Ürünleri / Süt"));
    expect(kategoriBirlestir("Süt Ürünleri > Süt")).toEqual(kategoriBirlestir("Süt Ürünleri / Süt"));
    expect(kategoriBirlestir("Gıda / Süt").ad).toBe("Süt Ürünleri / Süt");
    expect(kategoriBirlestir("Gıda / Çay")).toEqual(kategoriBirlestir("İçecek > Siyah Çay"));
    expect(kategoriBirlestir("İçecek > Siyah Çay").ad).toBe("İçecek / Çay");
    expect(kategoriBirlestir("Makarna / Unlu Mamuller")).toEqual(kategoriBirlestir("Gıda > Makarna"));
    expect(kategoriBirlestir("Konserve / Salça").ad).toBe("Gıda / Salça");
  });

  it("tek başına yazılan alt kategori de aynı anahtara düşer", () => {
    expect(kategoriAnahtari("Kek")).toBe(kategoriAnahtari("Atıştırmalık > Kek"));
    expect(kategoriBirlestir("Kek").ad).toBe("Atıştırmalık / Kek");
  });

  it("bilinmeyen adları bozmadan tek biçime alır", () => {
    expect(kategoriBirlestir("Telefon Ekran & Batarya D").ad).toBe("Telefon Ekran / Batarya D");
    expect(kategoriAnahtari("Telefon Ekran & Batarya D")).toBe(kategoriAnahtari("Batarya D / Telefon Ekran"));
    expect(kategoriBirlestir("Özel Tasarım").ad).toBe("Özel Tasarım");
    expect(kategoriBirlestir("").anahtar).toBe("");
  });
});
