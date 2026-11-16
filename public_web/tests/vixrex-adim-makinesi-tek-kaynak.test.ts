import { describe, expect, it } from "vitest";
import {
  ASISTAN_ADIMLARI,
  asistanHandoffOlustur,
  type AsistanCevaplari,
} from "@/lib/landingAsistanAkisi";
import { handoffAdimDevami } from "@/lib/assistantHandoff";
import katalog from "../../shared/vixrex_mesajlar.json";

const akisAdimlari = (katalog as { akis: { id: string }[] }).akis.map(
  (adim) => adim.id
);

describe("kurulum adım makinesi tek kaynaktan beslenir", () => {
  it("akış sırası ortak katalogla aynı", () => {
    expect(ASISTAN_ADIMLARI.map((adim) => adim.alan)).toEqual([
      "name",
      "category",
      "whatsapp",
      "location",
      "legal",
      "publish",
    ]);
    expect(akisAdimlari).toEqual([
      "name",
      "category",
      "whatsapp",
      "location",
      "legal",
      "publish",
      "share",
    ]);
  });

  it("her kurulum adımının handoff devam cümlesi vardır", () => {
    for (const adim of akisAdimlari) {
      const devam = handoffAdimDevami(adim);
      if (adim === "share") {
        expect(devam, "yayın sonrası paylaşım adımı kurulum hatırlatması taşımaz").toBeNull();
        continue;
      }
      expect(
        devam,
        `${adim} adımı panelde karşılıksız kaldı`
      ).not.toBeNull();
    }
  });

  it("kısmi cevaplarda tamamlanan adımlar önek olarak büyür", () => {
    let cevaplar: AsistanCevaplari = {};
    const beklenen: string[] = [];

    const adimlar: Array<{ ekle: AsistanCevaplari; adim: string }> = [
      { ekle: { name: "Ada Kahve" }, adim: "name" },
      { ekle: { kategori: "Kafe & Lokanta" }, adim: "category" },
      { ekle: { whatsapp: "905551234567" }, adim: "whatsapp" },
      {
        ekle: {
          province_name: "İstanbul",
          district_name: "Kadıköy",
          address: "Moda Caddesi 1",
        },
        adim: "location",
      },
      { ekle: { legal_consent: true }, adim: "legal" },
      { ekle: {}, adim: "publishing" },
    ];
    const sonrakiAdimlar = [
      "category",
      "whatsapp",
      "location",
      "legal",
      "publishing",
      "done",
    ];

    for (const [index, adim] of adimlar.entries()) {
      cevaplar = { ...cevaplar, ...adim.ekle };
      beklenen.push(adim.adim);

      const handoff = asistanHandoffOlustur(cevaplar, {
        yayinlandi: index === adimlar.length - 1,
      });

      expect(handoff.completed_steps).toEqual(beklenen);
      expect(handoff.next_step).toBe(sonrakiAdimlar[index]);
      expect(handoff.messages).toHaveLength(1 + beklenen.length * 2);
    }
  });
});
