import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Landing güven bandı paritesi", () => {
  const flutterTrust = oku("../../lib/widgets/landing/landing_trust_band.dart");
  const webTrust = oku("../src/components/landing/TrustBand.tsx");

  it("beş rozet metni iki tarafta aynıdır", () => {
    const rozetler = [
      "Kredi kartı gerekmez",
      "Satıştan komisyon alınmaz",
      "Kodsuz kurulum",
      "Link ve QR kod hazırdır",
      "WhatsApp ile doğrudan iletişim",
    ];
    for (const rozet of rozetler) {
      expect(flutterTrust).toContain(rozet);
      expect(webTrust).toContain(rozet);
    }
  });

  it("başlık ve kabuk ölçüleri Flutter ile aynıdır", () => {
    expect(flutterTrust).toContain("Başlarken sürpriz yok");
    expect(webTrust).toContain("Başlarken sürpriz yok");
    expect(flutterTrust).toContain("maxWidth: 1100");
    expect(webTrust).toContain("max-w-[1100px]");
    expect(flutterTrust).toContain("vertical: 56");
    expect(webTrust).toContain("py-14");
    expect(flutterTrust).toContain("fontSize: 30");
    expect(webTrust).toContain("text-[30px]");
  });

  it("rozet geometrisi Flutter ile aynıdır", () => {
    expect(flutterTrust).toContain("spacing: 12");
    expect(webTrust).toContain("gap-3");
    expect(flutterTrust).toContain("horizontal: 16");
    expect(flutterTrust).toContain("vertical: 12");
    expect(webTrust).toContain("px-4 py-3");
    expect(flutterTrust).toContain("BorderRadius.circular(999)");
    expect(webTrust).toContain("rounded-full");
    expect(flutterTrust).toContain("fontSize: 13");
    expect(webTrust).toContain("text-[13px]");
    expect(flutterTrust).toContain("size: 18");
    expect(webTrust).toContain("boyut={18}");
  });
});

describe("Landing üç adım paritesi", () => {
  const flutterSteps = oku("../../lib/widgets/landing/landing_steps_section.dart");
  const webSteps = oku("../src/components/landing/StepsSection.tsx");

  it("üç adım başlığı ve açıklaması iki tarafta aynıdır", () => {
    const adimlar: Array<[string, string]> = [
      ["Vitrininizi kurun", "ürün ve hizmetlerini ekle"],
      ["Yayınla", "QR kodunuzu hazır edin"],
      ["Müşterilerinize duyurun", "QR kod ile paylaşın"],
    ];
    for (const [baslik, aciklamaParcasi] of adimlar) {
      expect(flutterSteps).toContain(baslik);
      expect(webSteps).toContain(baslik);
      expect(flutterSteps).toContain(aciklamaParcasi);
      expect(webSteps).toContain(aciklamaParcasi);
    }
    expect(flutterSteps).toContain("Üç adımda dijital vitrinin hazır");
    expect(webSteps).toContain("Üç adımda dijital vitrinin hazır");
  });

  it("kabuk ve başlık ölçüleri Flutter ile aynıdır", () => {
    expect(flutterSteps).toContain("maxWidth: 1200");
    expect(webSteps).toContain("max-w-[1200px]");
    expect(flutterSteps).toContain("vertical: 76");
    expect(webSteps).toContain("py-[76px]");
    expect(flutterSteps).toContain("fontSize: 36");
    expect(webSteps).toContain("text-[36px]");
    expect(flutterSteps).toContain("height: 56");
    expect(webSteps).toContain("mt-14");
  });

  it("adım rozeti ve metin ölçüleri Flutter ile aynıdır", () => {
    expect(flutterSteps).toContain("width: 60");
    expect(flutterSteps).toContain("height: 60");
    expect(webSteps).toContain("h-[60px] w-[60px]");
    expect(flutterSteps).toContain("width: 2");
    expect(webSteps).toContain("border-2");
    expect(flutterSteps).toContain("fontSize: 24");
    expect(webSteps).toContain("text-[24px]");
    expect(flutterSteps).toContain("fontSize: 18");
    expect(webSteps).toContain("text-[18px]");
    expect(flutterSteps).toContain("fontSize: 14");
    expect(webSteps).toContain("text-[14px]");
    expect(flutterSteps).toContain("height: 1.45");
    expect(webSteps).toContain("leading-[1.45]");
  });

  it("masaüstünde üç sütun düzeni iki tarafta aynıdır", () => {
    expect(flutterSteps).toContain("maxWidth > 800");
    expect(webSteps).toContain("md:grid-cols-3");
  });
});
