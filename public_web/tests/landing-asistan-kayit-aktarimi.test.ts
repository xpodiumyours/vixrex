import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import {
  taslagiKaydet,
  taslagiOku,
  type AsistanCevaplari,
} from "@/lib/landingAsistanAkisi";

const KOK = resolve(__dirname, "..");
const oncekiWindow = Object.getOwnPropertyDescriptor(globalThis, "window");

afterEach(() => {
  if (oncekiWindow) {
    Object.defineProperty(globalThis, "window", oncekiWindow);
  } else {
    Reflect.deleteProperty(globalThis, "window");
  }
});

describe("landing asistanı kayıt sonrası devamlılık", () => {
  it("toplanan cevapları kayıt sayfasından sonra vitrin oluşturma adımına taşır", () => {
    const hafiza = new Map<string, string>();
    const sessionStorage = {
      get length() {
        return hafiza.size;
      },
      clear: () => hafiza.clear(),
      getItem: (anahtar: string) => hafiza.get(anahtar) ?? null,
      key: (index: number) => [...hafiza.keys()][index] ?? null,
      removeItem: (anahtar: string) => hafiza.delete(anahtar),
      setItem: (anahtar: string, deger: string) => hafiza.set(anahtar, deger),
    } satisfies Storage;
    Object.defineProperty(globalThis, "window", {
      configurable: true,
      value: { sessionStorage },
    });

    const cevaplar: AsistanCevaplari = {
      name: "Ada Kahve",
      kategori: "Kafe",
      whatsapp: "905551234567",
      province_name: "İstanbul",
      district_name: "Kadıköy",
      address: "Moda Caddesi 1",
    };
    taslagiKaydet(cevaplar);

    expect(taslagiOku()).toEqual(cevaplar);

    const kayitSayfasi = readFileSync(
      resolve(KOK, "src/app/kayit/page.tsx"),
      "utf8",
    );
    const sahipSayfasi = readFileSync(
      resolve(KOK, "src/app/app/page.tsx"),
      "utf8",
    );
    expect(kayitSayfasi).not.toContain("taslagiTemizle");
    expect(sahipSayfasi).toContain("const taslak = taslagiOku()");
    expect(sahipSayfasi).toContain(
      "body: JSON.stringify({ name: yeniAd.trim(), ...asistanTaslagi })",
    );
  });
});
