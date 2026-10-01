import { describe, expect, it } from "vitest";
import { kisiselVeriTemizle, tcknGecerliMi } from "@/lib/faturaKisiselVeri";

/**
 * KVKK veri minimizasyonu — fatura metninden T.C. Kimlik No ve vergi numarası
 * silinir. Test verileri 2026-10-01 tarihli gerçek fatura incelemesinden
 * türetildi (müşteri kimliği bu depoda tutulmaz; yalnız yapı örnek).
 */

describe("tcknGecerliMi", () => {
  it("geçerli T.C. Kimlik No'yu kabul eder", () => {
    expect(tcknGecerliMi("10000000140")).toBe(true);
    expect(tcknGecerliMi("28132026695")).toBe(true);
  });

  it("hatalı kontrol hanesini reddeder", () => {
    expect(tcknGecerliMi("10000000148")).toBe(false);
    expect(tcknGecerliMi("28132026690")).toBe(false);
  });

  it("10 haneyi (vergi no uzunluğu) TCKN saymaz", () => {
    expect(tcknGecerliMi("2813202669")).toBe(false);
  });

  it("0 ile başlayan numarayı reddeder", () => {
    expect(tcknGecerliMi("01234567890")).toBe(false);
  });
});

describe("kisiselVeriTemizle", () => {
  it("fatura satırındaki T.C. Kimlik No'yu siler", () => {
    const satir = "ISILAY INTERLOK PENYE ERKEK TACIN 8 AD T.C.K.N 28132026695";
    expect(kisiselVeriTemizle(satir)).toBe("ISILAY INTERLOK PENYE ERKEK TACIN 8 AD T.C.K.N ");
  });

  it("yazımsız (etiketsiz) geçerli T.C. Kimlik No'yu yine de siler", () => {
    const satir = "16747 ISILAY INTERLOK 8 AD 28132026695 3.600,00 TL";
    expect(kisiselVeriTemizle(satir)).not.toContain("28132026695");
  });

  it("Kimlik No etiketli numarayı siler", () => {
    expect(kisiselVeriTemizle("Alıcı Kimlik No : 28132026695")).not.toContain("28132026695");
  });

  it("Vergi No etiketli numarayı siler", () => {
    const metin = "Vergi No 1234567890";
    expect(kisiselVeriTemizle(metin)).not.toContain("1234567890");
  });

  it("VKN kısaltmasını tanır", () => {
    expect(kisiselVeriTemizle("VKN: 9876543210")).not.toContain("9876543210");
  });

  it("ürün satırını korur — stok kodu, adet, fiyat ve tutar bozulmaz", () => {
    const satir = "16747 ISILAY INTERLOK PENYE ERKEK TACIN 8 AD 450,00 TL 3.600,00 TL";
    expect(kisiselVeriTemizle(satir)).toBe(satir);
  });

  it("5 haneli stok kodunu silmez", () => {
    expect(kisiselVeriTemizle("Stok Kodu: 16747")).toBe("Stok Kodu: 16747");
  });

  it("bağlamsız 10 haneli rakamı silmez (ürün kodu olabilir)", () => {
    expect(kisiselVeriTemizle("1234567890")).toBe("1234567890");
  });

  it("alıcı adını, adresini ve satır bilgisine dokunmaz", () => {
    const satir = "MURAT KANLIKÖYKÖY / ÇAYALARMEŞE 16747 8 AD 450,00";
    expect(kisiselVeriTemizle(satir)).toBe(satir);
  });

  it("birden çok kimlik numarasını siler", () => {
    const metin = "TCKN 10000000140 ve Vergi No 1234567890";
    const temiz = kisiselVeriTemizle(metin);
    expect(temiz).not.toContain("10000000140");
    expect(temiz).not.toContain("1234567890");
  });

  it("boş ve tanımsız girdide çökmez", () => {
    expect(kisiselVeriTemizle("")).toBe("");
    expect(kisiselVeriTemizle(undefined as unknown as string)).toBe(undefined as unknown as string);
  });

  it("temizlenecek veri yoksa metni birebir aynen döndürür", () => {
    const metin = "NET TUTAR: 3.960,00 TL";
    expect(kisiselVeriTemizle(metin)).toBe(metin);
  });
});