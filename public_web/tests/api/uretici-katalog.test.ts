import { readdirSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";
import {
  gorselKapisi,
  katalogOzeti,
  ureticiUrunuBul,
  type UreticiUrunu,
} from "@/lib/ureticiKatalog";

// Üretici/tedarikçi kataloğu — faturadaki kod, firmanın kendi yayınladığı
// ürüne bağlanır.
//
// Kural: eşleşme yalnız barkod veya model kodu birebir tuttuğunda kurulur.
// Ada bakarak tahmin yapılmaz; tutmazsa satır faturadaki hâliyle kalır.
// Fotoğraf ise ancak firmanın izni "var" ise kullanılır.

/** Casper'ın gerçek faturasındaki 12 model kodu. */
const FATURA_KODLARI = [
  "ELT1302",
  "ELT1303",
  "ELT1306",
  "ELT2203",
  "ELT2204",
  "TEC0135",
  "TER0101",
  "TER0114",
  "TER0117",
  "TER0125",
  "TER0126",
  "TKC0835",
];

/** Toplayıcının sitelerden çektiği, gıda firmalarına ait gerçek kodlar. */
const YENI_FIRMA_KODLARI = ["BAH001", "BOUNTY", "8697880540010", "KP160", "0282"];

describe("üretici kataloğu — yükleme", () => {
  it("birden çok firma yüklü ve toplam ürün sayısı binlerle ifade edilir", () => {
    const ozet = katalogOzeti();
    expect(ozet.length).toBeGreaterThanOrEqual(7);

    const toplam = ozet.reduce((t, firma) => t + firma.urun, 0);
    expect(toplam).toBeGreaterThan(4000);
  });

  it("izni verilmemiş firma 'var' olarak görünmez", () => {
    for (const firma of katalogOzeti()) {
      expect(["yok", "bekliyor"]).toContain(firma.izin);
    }
  });

  it("her katalog dosyasının firma listesinde karşılığı var", () => {
    // Dosya adı ile firma anahtarı tutmazsa koca bir katalog sessizce
    // eşleştirme dışı kalır (bir kez başımıza geldi).
    const klasor = path.resolve(process.cwd(), "data", "katalog");
    const dosyalar = readdirSync(klasor)
      .filter((ad) => /^uretici-katalog-.+\.json$/.test(ad))
      .map((ad) => ad.replace(/^uretici-katalog-/, "").replace(/\.json$/, ""));

    const anahtarlar = katalogOzeti().map((firma) => firma.anahtar);
    expect(dosyalar.length).toBeGreaterThan(0);

    for (const dosya of dosyalar) {
      expect(anahtarlar, `katalog dosyası eşleşmiyor: ${dosya}`).toContain(dosya);
    }
  });

  it("her katalog dosyası gerçekten ürün taşıyor", () => {
    for (const firma of katalogOzeti()) {
      expect(firma.urun, `${firma.anahtar} boş`).toBeGreaterThan(0);
    }
  });
});

describe("üretici kataloğu — eşleştirme", () => {
  it("gerçek faturadaki 12 kodun hepsi katalogda bulunur", () => {
    const bulunan = FATURA_KODLARI.filter((kod) => ureticiUrunuBul({ model: kod }) !== null);
    expect(bulunan).toHaveLength(FATURA_KODLARI.length);
  });

  it("toplanan yeni firmaların kodları da bulunur", () => {
    for (const kod of YENI_FIRMA_KODLARI) {
      expect(ureticiUrunuBul({ model: kod }), kod).not.toBeNull();
    }
  });

  it("resmî ad ve marka faturadaki ham addan daha zengin gelir", () => {
    const eslesme = ureticiUrunuBul({ model: "ELT1302" });
    expect(eslesme!.urun.ad).toContain("ELT1302");
    expect(eslesme!.urun.marka).toBeTruthy();
    expect(eslesme!.dayanak).toBe("kod");
  });

  it("model kodu küçük harf veya boşluklu gelse de eşleşir", () => {
    expect(ureticiUrunuBul({ model: " elt1302 " })).not.toBeNull();
    expect(ureticiUrunuBul({ model: "elt-1302" })).not.toBeNull();
  });

  it("barkod eşleşmesi model kodundan önce gelir", () => {
    const koddan = ureticiUrunuBul({ model: "ELT1302" });
    const barkod = koddan!.urun.barkod;
    expect(barkod.length).toBeGreaterThanOrEqual(8);

    const barkoddan = ureticiUrunuBul({ model: "TER0101", barkod });
    expect(barkoddan!.dayanak).toBe("barkod");
    expect(barkoddan!.urun.kod).toBe("ELT1302");
  });

  it("katalogda olmayan kod için tahmin üretmez", () => {
    expect(ureticiUrunuBul({ model: "ZZZ9999" })).toBeNull();
    expect(ureticiUrunuBul({ model: "", barkod: "" })).toBeNull();
    expect(ureticiUrunuBul({ model: null, barkod: null })).toBeNull();
  });

  it("çok kısa kod yanlışlıkla eşleşmez", () => {
    expect(ureticiUrunuBul({ model: "ELT" })).toBeNull();
    // "KP1" katalogda var ama 3 karakter; yanlış eşleşmeyi önlemek için
    // 4 karakterden kısa kodlar aranmaz.
    expect(ureticiUrunuBul({ model: "KP1" })).toBeNull();
  });
});

describe("görsel izin kapısı", () => {
  const urun: UreticiUrunu = {
    kod: "TEST1",
    ad: "TEST1 Örnek Ürün",
    marka: "Örnek Marka",
    aciklama: "Örnek açıklama",
    barkod: "",
    gorseller: ["https://ornek.example/1.jpg", "https://ornek.example/2.jpg"],
    kaynak: "https://ornek.example/urun",
  };

  it("izin yokken ve izin beklerken fotoğraf geçmez", () => {
    expect(gorselKapisi(urun, "yok").gorseller).toHaveLength(0);
    expect(gorselKapisi(urun, "bekliyor").gorseller).toHaveLength(0);
  });

  it("izin 'var' iken fotoğraf geçer, diğer bilgiler korunur", () => {
    const gecen = gorselKapisi(urun, "var");
    expect(gecen.gorseller).toEqual(urun.gorseller);
    expect(gecen.ad).toBe(urun.ad);
    expect(gecen.kod).toBe(urun.kod);
  });

  it("kapı girdi ürünü değiştirmez", () => {
    gorselKapisi(urun, "yok");
    expect(urun.gorseller).toHaveLength(2);
  });

  it("izni olmayan firmadan gelen eşleşmede fotoğraf boş, durum açıkça bildirilir", () => {
    const eslesme = ureticiUrunuBul({ model: "ELT1302" });
    expect(eslesme).not.toBeNull();
    expect(eslesme!.firma.izinDurumu).not.toBe("var");
    expect(eslesme!.gorselIzniVar).toBe(false);
    expect(eslesme!.urun.gorseller).toHaveLength(0);
  });

  it("ürünün kendisi ve kodu kapıdan sonra da gelir", () => {
    const eslesme = ureticiUrunuBul({ model: "ELT1302" });
    expect(eslesme!.urun.kod).toBe("ELT1302");
    expect(eslesme!.urun.ad).toContain("Elit");
    expect(eslesme!.urun.kaynak).toContain("sehermensucat.com");
  });
});
