import { describe, expect, it } from "vitest";
import { faturaSatiriniAyikla, hamMetniSatirlaraAyir } from "@/lib/faturaSatirAyikla";

// Görüntü okuyucunun (Kilo, ücretsiz) döneceği HAM METNİ deterministik
// koda ayıran parçanın testi. Model yalnız metni transkribe eder — hangi
// kelimenin kod/beden/fiyat olduğuna bu kod karar verir.
//
// Test verisi Casper'ın GERÇEK faturasının bilinen 13 satırı
// (tool/fatura_olcum/veri/2026-09-15-satis-teklif-beklenen.json).
// Dürüstlük notu: gerçek fotoğraftan Kilo'nun tam olarak bu biçimde mi
// transkribe edeceği HENÜZ ölçülmedi — bu test yalnız "metin bu şekilde
// gelirse doğru ayrıştırılır mı" sorusuna cevap verir.

const FATURA_SATIRLARI = [
  { ham: "ELT1302 Elit Erkek Elastan Sıfır Yaka Uzun Kol 8681128321677 Siyah L 2 ad 137,00 TL 274,00 TL",
    beklenen: { model: "ELT1302", barkod: "8681128321677", varyant: "Siyah", beden: "L", adet: 2, alisBirimFiyat: 137, satirToplam: 274 } },
  { ham: "ELT1303 Elit Erkek Elastan V Yaka 8681128321974 Siyah L 3 ad 115,00 TL 345,00 TL",
    beklenen: { model: "ELT1303", barkod: "8681128321974", varyant: "Siyah", beden: "L", adet: 3, alisBirimFiyat: 115, satirToplam: 345 } },
  { ham: "ELT2203 Elit Bayan Elastan Uzun Kol 8681128326917 Siyah M 6 ad 124,00 TL 744,00 TL",
    beklenen: { model: "ELT2203", barkod: "8681128326917", varyant: "Siyah", beden: "M", adet: 6, alisBirimFiyat: 124, satirToplam: 744 } },
  { ham: "TER0101 Tut Erkek Penye Atlet 8680508918131 Beyaz 4 18 ad 63,50 TL 1.143,00 TL",
    beklenen: { model: "TER0101", barkod: "8680508918131", varyant: "Beyaz", beden: "4", adet: 18, alisBirimFiyat: 63.5, satirToplam: 1143 } },
  { ham: "TER0117 Tut Erkek Penye Düz Boxer 8681128335230 Siyah XXXL 6 ad 69,00 TL 414,00 TL",
    beklenen: { model: "TER0117", barkod: "8681128335230", varyant: "Siyah", beden: "XXXL", adet: 6, alisBirimFiyat: 69, satirToplam: 414 } },
];

describe("faturaSatiriniAyikla — tek satır", () => {
  it.each(FATURA_SATIRLARI)("$beklenen.model doğru ayrıştırılır", ({ ham, beklenen }) => {
    const sonuc = faturaSatiriniAyikla(ham);
    expect(sonuc).not.toBeNull();
    expect(sonuc!.model).toBe(beklenen.model);
    expect(sonuc!.barkod).toBe(beklenen.barkod);
    expect(sonuc!.varyant).toBe(beklenen.varyant);
    expect(sonuc!.beden).toBe(beklenen.beden);
    expect(sonuc!.adet).toBe(beklenen.adet);
    expect(sonuc!.alisBirimFiyat).toBe(beklenen.alisBirimFiyat);
    expect(sonuc!.satirToplam).toBe(beklenen.satirToplam);
  });

  it("yaş aralığı bedeni (8–10 Yaş) tek parça olarak okunur", () => {
    const sonuc = faturaSatiriniAyikla(
      "TKC0835 Tut Kız Thermal Tayt 8680508957901 Siyah 8–10 Yaş 2 ad 79,00 TL 158,00 TL",
    );
    expect(sonuc!.beden).toBe("8–10 Yaş");
    expect(sonuc!.model).toBe("TKC0835");
    expect(sonuc!.satirToplam).toBe(158);
  });

  it("yaş aralığı tire ile de (11-13 Yaş) okunur", () => {
    const sonuc = faturaSatiriniAyikla(
      "TEC0135 Tut Çocuk Thermal Alt 8680508957796 Siyah 11-13 Yaş 1 ad 81,00 TL 81,00 TL",
    );
    expect(sonuc!.beden).toContain("13");
    expect(sonuc!.adet).toBe(1);
  });

  it("yalnız tek fiyat varsa (toplam yok) alış fiyatı doğru, toplam null kalır — tahmin edilmez", () => {
    const sonuc = faturaSatiriniAyikla("ELT1306 Elit Erkek Thermal Alt 8681128332550 Siyah L 1 ad 175,00 TL");
    expect(sonuc!.alisBirimFiyat).toBe(175);
    expect(sonuc!.satirToplam).toBeNull();
  });

  it("kısa yalın rakam kod (Kul Gıda tipi: 0282) barkodla karıştırılmaz", () => {
    const sonuc = faturaSatiriniAyikla("0282 Zeytinyağlı Fasulye Konservesi 8697123456789 3 ad 45,00 TL 135,00 TL");
    expect(sonuc!.model).toBe("0282");
    expect(sonuc!.barkod).toBe("8697123456789");
    expect(sonuc!.adet).toBe(3);
  });

  it("boş satır null döner", () => {
    expect(faturaSatiriniAyikla("")).toBeNull();
    expect(faturaSatiriniAyikla("   ")).toBeNull();
  });

  it("hiçbir alan tanınamazsa bile çökmez", () => {
    const sonuc = faturaSatiriniAyikla("asdkjaslkdj qwoeiqwoe");
    // kod yok ama ad var — satır döner, taslak kapısı zaten kodsuzu eler.
    expect(sonuc).not.toBeNull();
    expect(sonuc!.model).toBe("");
  });
});

describe("hamMetniSatirlaraAyir — tüm fatura", () => {
  it("gerçek faturanın bilinen 13 satırının tamamı çıkar, sıra korunur", () => {
    const metin = [
      "Satış Teklif Formu - 15.09.2026",
      "ELT1302 Elit Erkek Elastan Sıfır Yaka Uzun Kol 8681128321677 Siyah L 2 ad 137,00 TL 274,00 TL",
      "ELT1303 Elit Erkek Elastan V Yaka 8681128321974 Siyah L 3 ad 115,00 TL 345,00 TL",
      "ELT1306 Elit Erkek Thermal Alt 8681128332550 Siyah L 1 ad 175,00 TL 175,00 TL",
      "ELT2203 Elit Bayan Elastan Uzun Kol 8681128326917 Siyah M 6 ad 124,00 TL 744,00 TL",
      "ELT2204 Elit Bayan Elastan Balık Yaka 8681128344164 Beyaz M 1 ad 81,00 TL 81,00 TL",
      "TEC0135 Tut Çocuk Thermal Alt 8680508957796 Siyah 11-13 Yaş 1 ad 81,00 TL 81,00 TL",
      "TER0101 Tut Erkek Penye Atlet 8680508918131 Beyaz 4 18 ad 63,50 TL 1.143,00 TL",
      "TER0114 Tut Erkek Likralı Boxer 8680508921971 Siyah L 17 ad 63,50 TL 1.079,50 TL",
      "TER0117 Tut Erkek Penye Düz Boxer 8680508923388 Siyah XL 13 ad 63,50 TL 825,50 TL",
      "TER0117 Tut Erkek Penye Düz Boxer 8681128335230 Siyah XXXL 6 ad 69,00 TL 414,00 TL",
      "TER0125 Tut Erkek Thermal Alt 8681128300931 Siyah M 2 ad 135,00 TL 270,00 TL",
      "TER0126 Tut Erkek Thermal Fanila 8681128304748 Siyah M 3 ad 148,00 TL 444,00 TL",
      "TKC0835 Tut Kız Thermal Tayt 8680508957901 Siyah 8-10 Yaş 2 ad 79,00 TL 158,00 TL",
      "Toplam: 75 adet 6.034,00 TL",
    ].join("\n");

    const tumSatirlar = hamMetniSatirlaraAyir(metin);

    // "Toplam:" satırı bilinen desenle elenir. Başlık satırı ("Satış Teklif
    // Formu - 15.09.2026") elenmez — kod yoktur ama bunu elemek YANLIŞ
    // pozitif riskini artırır (gerçek bir ürün adı da kodsuz gelebilir).
    // Bu yüzden ayrım burada değil, kodu olmayan satırı reddeden yayın
    // kapısında (faturaEslestir/batch route) yapılır.
    const satirlar = tumSatirlar.filter((s) => s.model);
    expect(satirlar).toHaveLength(13);
    expect(satirlar.map((s) => s.model)).toEqual([
      "ELT1302", "ELT1303", "ELT1306", "ELT2203", "ELT2204", "TEC0135",
      "TER0101", "TER0114", "TER0117", "TER0117", "TER0125", "TER0126", "TKC0835",
    ]);

    const toplamAdet = satirlar.reduce((t, s) => t + (s.adet ?? 0), 0);
    const toplamTutar = satirlar.reduce((t, s) => t + (s.satirToplam ?? 0), 0);

    // Faturanın kendi bilinen toplamlarıyla birebir eşleşir.
    expect(toplamAdet).toBe(75);
    expect(Math.round(toplamTutar * 100) / 100).toBe(6034);
  });

  it("boş metin boş liste döner, çökmez", () => {
    expect(hamMetniSatirlaraAyir("")).toEqual([]);
    expect(hamMetniSatirlaraAyir("\n\n\n")).toEqual([]);
  });
});
