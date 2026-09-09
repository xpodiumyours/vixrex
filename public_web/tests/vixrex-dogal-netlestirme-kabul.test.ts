import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  VIXREX_DOGAL_GENEL_SORU,
  vixrexBaglamsalCevapKarari,
  type VixrexBaglamKarari,
  type VixrexBekleyenBaglam,
} from "../src/lib/vixrexConversationContext";

interface Senaryo {
  id: string;
  bekleyen: VixrexBekleyenBaglam | null;
  girdi: string;
  karar: VixrexBaglamKarari;
  yazma: boolean;
}

const senaryolar = JSON.parse(
  readFileSync(
    resolve(__dirname, "../../shared/vixrex_dogal_netlestirme_senaryolari.json"),
    "utf8",
  ),
) as Senaryo[];

describe("Vixrex doğal netleştirme bağımsız kabul kümesi", () => {
  it("en az 20 konuşma senaryosu içerir", () => {
    expect(senaryolar.length).toBeGreaterThanOrEqual(20);
  });

  for (const senaryo of senaryolar) {
    it(`${senaryo.id}: bağlama göre yazma/sorma kararını verir`, () => {
      const sonuc = vixrexBaglamsalCevapKarari(senaryo.girdi, senaryo.bekleyen);
      expect(sonuc.karar).toBe(senaryo.karar);
      expect(sonuc.yazma).toBe(senaryo.yazma);
      if (!senaryo.yazma) expect(sonuc.mesaj.trim().length).toBeGreaterThan(0);
    });
  }

  it("bağlam yokken kullanıcıdan sistemin iç alan adını istemez", () => {
    const sonuc = vixrexBaglamsalCevapKarari("bunu düzelt", null);
    expect(sonuc.mesaj).toBe(VIXREX_DOGAL_GENEL_SORU);
    expect(sonuc.mesaj.toLocaleLowerCase("tr-TR")).not.toContain("hangi alan");
  });
});
