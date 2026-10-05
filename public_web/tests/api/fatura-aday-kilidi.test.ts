import { describe, expect, it } from "vitest";
import {
  faturaSatiriniEslestir,
  satiriAdayaKilitle,
  type HamFaturaSatiri,
} from "@/lib/faturaEslestir";

function satir(model: string): HamFaturaSatiri {
  return {
    model,
    ad: "atlet",
    barkod: "",
    varyant: "",
    beden: "",
    adet: 2,
    alisBirimFiyat: 10,
    satirToplam: 20,
    guven: 0.9,
  };
}

describe("fatura satırında birden çok firma adayı", () => {
  it("aynı kod iki firmada kart uydurmaz, seçilecek aday bırakır", () => {
    const sonuc = faturaSatiriniEslestir(satir("ELT1001"));
    expect(sonuc.sonuc).toBe("celiski");
    expect(sonuc.katalog).toBeNull();
    expect(sonuc.celiski?.adaylar.length).toBeGreaterThan(1);
  });

  it("esnaf adayı seçince satır kanıtlı karta kilitlenir", () => {
    const sonuc = faturaSatiriniEslestir(satir("ELT1001"));
    const kaynak = sonuc.celiski?.adaylar[0]?.kaynak ?? "";
    expect(kaynak).not.toBe("");
    const kilit = satiriAdayaKilitle(sonuc, kaynak);
    expect(kilit).not.toBeNull();
    expect(kilit!.sonuc).toBe("kanitli");
    expect(kilit!.katalog?.kaynak).toBe(kaynak);
    expect(kilit!.celiski).toBeUndefined();
    expect(kilit!.katalog?.gorseller.length).toBeGreaterThan(0);
    expect(["yok", "bekliyor", "var"]).toContain(kilit!.katalog?.izinDurumu);
  });

  it("listede olmayan kaynağı kilitlemez", () => {
    const sonuc = faturaSatiriniEslestir(satir("ELT1001"));
    expect(satiriAdayaKilitle(sonuc, "https://olmayan.example/urun")).toBeNull();
  });
});
