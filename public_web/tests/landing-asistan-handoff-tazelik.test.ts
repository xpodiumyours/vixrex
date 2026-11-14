import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  ASISTAN_ADIMLARI,
  asistanHandoffOlustur,
  yayinCevaplariHazirla,
  type AsistanCevaplari,
} from "@/lib/landingAsistanAkisi";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const tamCevaplar: AsistanCevaplari = {
  name: "Ada Kahve",
  kategori: "Kafe & Lokanta",
  whatsapp: "905551234567",
  province_name: "İstanbul",
  district_name: "Kadıköy",
  address: "Moda Caddesi 1",
};

const tumOnaylar = { aydinlatma: true, sartlar: true, acikRiza: true };

describe("landing asistanı konuşma aktarımı taze ve eksiksiz", () => {
  it("handoff yalnız gerçekten cevaplanan adımları taşır", () => {
    const handoff = asistanHandoffOlustur({ name: "Ada Kahve" });

    expect(handoff.completed_steps).toEqual(["name"]);
    expect(handoff.next_step).toBe("category");
    expect(handoff.messages).toHaveLength(3);
    for (const mesaj of handoff.messages) {
      expect(mesaj.text.trim()).not.toBe("");
    }
  });

  it("cevaplanmayan adımın sorusu geçmişe yazılmaz", () => {
    const handoff = asistanHandoffOlustur({ name: "Ada Kahve" });
    const metinler = handoff.messages.map((mesaj) => mesaj.text);

    for (const alan of ["whatsapp", "location", "legal"] as const) {
      const adim = ASISTAN_ADIMLARI.find((aday) => aday.alan === alan)!;
      expect(
        metinler,
        `${alan} adımı cevaplanmadan geçmişe yazıldı`
      ).not.toContain(`${adim.baslik}\n${adim.aciklama}`);
    }
  });

  it("konum üç alandan biri girilince tek adım olarak tamamlanır", () => {
    const handoff = asistanHandoffOlustur({
      ...tamCevaplar,
      province_name: "İstanbul",
      district_name: "",
      address: "",
    });

    expect(
      handoff.completed_steps.filter((adim) => adim === "location")
    ).toHaveLength(1);
    expect(handoff.completed_steps).not.toContain("legal");
    expect(handoff.next_step).toBe("legal");
  });

  it("yasal onay handoff'u yeniden üretir; yayın ancak gerçek yayında tamamlanır", () => {
    const onayli = yayinCevaplariHazirla(tamCevaplar, tumOnaylar);

    expect(onayli.legal_consent).toBe(true);
    expect(onayli.assistant_handoff?.completed_steps).toEqual([
      "name",
      "category",
      "whatsapp",
      "location",
      "legal",
    ]);
    expect(onayli.assistant_handoff?.next_step).toBe("publishing");

    const yayinli = yayinCevaplariHazirla(tamCevaplar, tumOnaylar, {
      yayinlandi: true,
    });

    expect(yayinli.assistant_handoff?.completed_steps).toEqual([
      "name",
      "category",
      "whatsapp",
      "location",
      "legal",
      "publishing",
    ]);
    expect(yayinli.assistant_handoff?.next_step).toBe("done");
    expect(yayinli.assistant_handoff?.messages.length).toBeLessThanOrEqual(24);
  });

  it("bileşen yasal onayda tazeler, yayın başarısından sonra kaydeder", () => {
    const kaynak = oku("src/components/landing/LandingAsistanSohbeti.tsx");

    expect(kaynak).toContain("yayinCevaplariHazirla(");
    expect(kaynak).toContain("{ yayinlandi: true }");

    const hataKapisi = kaynak.indexOf("if (!res.ok)");
    const basariliKayit = kaynak.indexOf("taslagiKaydet(yayinCevaplari)");
    expect(hataKapisi).toBeGreaterThan(-1);
    expect(basariliKayit).toBeGreaterThan(hataKapisi);
  });
});
