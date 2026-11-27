import { describe, expect, it } from "vitest";
import {
  faturaAliciMetniniTemizle,
  faturaAlicidanVitrinTaslagiUret,
} from "../src/lib/faturaVitrinTaslagi";

describe("faturaVitrinTaslagi", () => {
  it("alici bos veya null geldiginde mevcut taslagi ezmez", () => {
    const mevcut = { name: "Aksakal İç Giyim", province_name: "İstanbul" };
    expect(faturaAlicidanVitrinTaslagiUret(mevcut, null)).toEqual(mevcut);
    expect(faturaAlicidanVitrinTaslagiUret(mevcut, {})).toEqual(mevcut);
  });

  it("VKN, TCKN, IBAN ve ticari sir etiketlerini taslaktan temizler", () => {
    const ham =
      "Aksakal Ticaret VKN: 1234567890 TR330006100519786457841326 28024630522 iskonto: %15";
    const temiz = faturaAliciMetniniTemizle(ham);
    expect(temiz).toBe("Aksakal Ticaret");
    expect(temiz).not.toMatch(/\d{10,11}/);
    expect(temiz).not.toMatch(/TR\d{24}/i);
  });

  it("temiz alici alanlarini bos alanlara yazar, dolu alanlari korur", () => {
    const mevcut = { name: "Mevcut Ad" };
    const sonuc = faturaAlicidanVitrinTaslagiUret(mevcut, {
      ad: "Faturadaki Ad",
      adres: "Esenevler Mah. No:18 VKN:9876543210",
      il: "İstanbul",
      ilce: "Ümraniye",
    });
    expect(sonuc.name).toBe("Mevcut Ad");
    expect(sonuc.address).toBe("Esenevler Mah. No:18");
    expect(sonuc.province_name).toBe("İstanbul");
    expect(sonuc.district_name).toBe("Ümraniye");
  });
});
