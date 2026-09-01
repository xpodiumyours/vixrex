import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { nominatimAdresiniCoz } from "@/lib/konumCozumleme";

describe("GPS adres çözümleme", () => {
  it("Nominatim yanıtını Flutter ile aynı il, ilçe ve açık adres alanlarına çevirir", () => {
    expect(
      nominatimAdresiniCoz({
        display_name: "Caferağa Mahallesi, Moda Caddesi, Kadıköy, İstanbul, Türkiye",
        address: {
          road: "Moda Caddesi",
          suburb: "Caferağa Mahallesi",
          town: "Kadıköy",
          city: "İstanbul",
        },
      }),
    ).toEqual({
      provinceName: "İstanbul",
      districtName: "Kadıköy",
      address: "Caferağa Mahallesi, Moda Caddesi, Kadıköy, İstanbul",
    });
  });

  it("landing GPS sonucu görünür form alanlarına uygulanır", () => {
    const kaynak = readFileSync(
      resolve(__dirname, "../src/components/landing/LandingAsistanSohbeti.tsx"),
      "utf8",
    );

    expect(kaynak).toContain("gpsAdresiniCoz");
    expect(kaynak).toContain("setIl(cozulen.provinceName)");
    expect(kaynak).toContain("setIlce(cozulen.districtName)");
    expect(kaynak).toContain("setAdres(cozulen.address)");
  });
});
