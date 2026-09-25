import { describe, expect, it } from "vitest";
import {
  duzMetin,
  htmlCoz,
  normalizeBarkod,
  normalizeKod,
  ozet,
  urunuNormalle,
  urunleriNormalle,
} from "../../scripts/katalog/_ortak.mjs";

// Ürün havuzu toplayıcısının ortak kuralları. Bu kurallar bozulursa
// kataloğa yanlış kod, yanlış barkod ya da bozuk metin girer ve faturayla
// eşleştirme sessizce yanlış çalışır.

describe("kod normalleştirme", () => {
  it("boşluk, tire ve noktayı atar, büyük harfe çevirir", () => {
    expect(normalizeKod(" elt-1302 ")).toBe("ELT1302");
    expect(normalizeKod("ELT 1302")).toBe("ELT1302");
    expect(normalizeKod("elt_1302")).toBe("ELT1302");
    expect(normalizeKod("elt.1302")).toBe("ELT1302");
  });

  it("boş ve tanımsız değerde boş döner", () => {
    expect(normalizeKod("")).toBe("");
    expect(normalizeKod("   ")).toBe("");
    expect(normalizeKod(null)).toBe("");
    expect(normalizeKod(undefined)).toBe("");
  });
});

describe("barkod normalleştirme", () => {
  it("yalnız 8-14 haneli sayıyı barkod kabul eder", () => {
    expect(normalizeBarkod("8681128384160")).toBe("8681128384160");
    expect(normalizeBarkod("86 8112 838 4160")).toBe("8681128384160");
    expect(normalizeBarkod("12345678")).toBe("12345678");
  });

  it("ürün kodu olan değerleri barkod saymaz", () => {
    // 46003L bir model kodu, barkod değil: içinde harf var.
    expect(normalizeBarkod("46003L")).toBe("");
    expect(normalizeBarkod("BAH001")).toBe("");
  });

  it("7 haneli ve 15 haneli değeri reddeder", () => {
    expect(normalizeBarkod("1234567")).toBe("");
    expect(normalizeBarkod("123456789012345")).toBe("");
  });
});

describe("bozuk metin temizleme", () => {
  it("HTML varlıklarını gerçek karaktere çevirir", () => {
    expect(htmlCoz("Dört Mevsim &#038; Külot")).toBe("Dört Mevsim & Külot");
    expect(htmlCoz("A &amp; B")).toBe("A & B");
    expect(htmlCoz("&quot;tırnak&quot;")).toBe('"tırnak"');
  });

  it("etiketleri atar, metni korur", () => {
    expect(duzMetin("<p>Merhaba <b>dünya</b></p>")).toBe("Merhaba dünya");
    expect(duzMetin("Satır<br>sonu")).toBe("Satır sonu");
  });

  it("script ve style içeriğini metne katmaz", () => {
    expect(duzMetin("<script>kotu()</script>Görünür metin")).toBe("Görünür metin");
    expect(duzMetin("<style>.a{color:red}</style>Temiz")).toBe("Temiz");
  });
});

describe("ürün normalleştirme", () => {
  it("kodu olmayan ürünü kataloğa almaz", () => {
    expect(urunuNormalle({ kod: "", ad: "Ürün" }, "https://a")).toBeNull();
    expect(urunuNormalle({ ad: "Ürün" }, "https://a")).toBeNull();
  });

  it("tek standart biçimi üretir", () => {
    const urun = urunuNormalle(
      {
        kod: " elt-1302 ",
        ad: "ELT1302  Elit  Fanila",
        marka: "Tutku Elit",
        aciklama: "",
        barkod: "8681128384160",
        gorseller: ["https://cdn.example/1.jpg"],
      },
      "https://sehermensucat.com",
    );

    expect(urun).not.toBeNull();
    expect(urun!.kod).toBe("ELT1302");
    expect(urun!.ad).toBe("ELT1302 Elit Fanila");
    expect(urun!.barkod).toBe("8681128384160");
    expect(urun!.gorseller).toEqual(["https://cdn.example/1.jpg"]);
    expect(urun!.kaynak).toBe("https://sehermensucat.com");
  });

  it("tekrarlanan ve adres olmayan görselleri atar", () => {
    const urun = urunuNormalle(
      {
        kod: "A1",
        ad: "Ürün",
        gorseller: ["https://a/1.jpg", "https://a/1.jpg", "/yerel.png", "", null],
      },
      "https://a",
    );

    expect(urun!.gorseller).toEqual(["https://a/1.jpg"]);
  });

  it("aynı kodu iki kez yazmaz ve koda göre sıralar", () => {
    const urunler = urunleriNormalle(
      [
        { kod: "B2", ad: "İkinci" },
        { kod: "A1", ad: "Birinci" },
        { kod: "b-2", ad: "Tekrar" },
      ],
      "https://a",
    );

    expect(urunler.map((u) => u.kod)).toEqual(["A1", "B2"]);
    expect(urunler[1].ad).toBe("İkinci");
  });
});

describe("özet sayıları", () => {
  it("ölçülen her alanı ayrı sayar", () => {
    const urunler = urunleriNormalle(
      [
        { kod: "A1", ad: "Ürün", aciklama: "Açıklama", barkod: "8681128384160", gorseller: ["https://a/1.jpg", "https://a/2.jpg"] },
        { kod: "B2", ad: "Ürün", gorseller: ["https://a/3.jpg"] },
        { kod: "C3", ad: "" },
      ],
      "https://a",
    );

    expect(ozet(urunler)).toEqual({
      urun: 3,
      barkodlu: 1,
      adli: 2,
      aciklamali: 1,
      fotografli: 2,
      fotograf: 3,
    });
  });

  it("boş listede sıfır döner", () => {
    expect(ozet([])).toEqual({
      urun: 0,
      barkodlu: 0,
      adli: 0,
      aciklamali: 0,
      fotografli: 0,
      fotograf: 0,
    });
  });
});
