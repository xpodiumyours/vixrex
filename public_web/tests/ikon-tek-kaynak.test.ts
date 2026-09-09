import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import sharp from "sharp";
import { describe, expect, it } from "vitest";

/**
 * Uygulama ikonu — TEK GÖRÜNÜM kilidi.
 *
 * 2026-09-09'da ölçüldüğünde ürünün ikonları üç ayrı hâldeydi:
 *   - Android uygulaması: hâlâ Flutter'ın varsayılan kuş ikonu, beyaz rozet
 *     içinde (uyarlanabilir ikon tanımı hiç yoktu).
 *   - Flutter web: beş ikon dosyası da Flutter varsayılanı.
 *   - Next.js: ikon yoktu.
 *
 * Furkan: "her yerde Vixrex bu olmalı." Hepsi tek kaynaktan (maskot) ve tek
 * zeminden (#050B1A) üretildi. Bu test farkı ölçmez; yeniden ayrışmasını
 * engeller — biri tek bir yüzeyde ikonu değiştirirse yakalanır.
 *
 * Zemin, web manifest'indeki `background_color` ve Android'deki
 * `ic_launcher_background` ile AYNI olmalı: açılış ekranı, ikon ve uygulama
 * zemini arasında renk sıçraması olmasın.
 */

const KOK = resolve(__dirname, "../..");
const ZEMIN = "#050B1A";

/** Düz zeminli ikonlar — köşe pikseli marka zemini olmalı. */
const DUZ_IKONLAR = [
  // Next.js — telefona kurulan web uygulaması
  "public_web/public/icon-192.png",
  "public_web/public/icon-512.png",
  "public_web/public/icon-maskable-512.png",
  "public_web/public/apple-icon-180.png",
  "public_web/src/app/icon.png",
  // Flutter web
  "web/favicon.png",
  "web/icons/Icon-192.png",
  "web/icons/Icon-512.png",
  "web/icons/Icon-maskable-192.png",
  "web/icons/Icon-maskable-512.png",
  // Android — eski tarz launcher ikonu
  "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
  "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
  "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
  "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
  "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
];

/** Uyarlanabilir ikonun ön planı — zemini AYRI katman, saydam olmalı. */
const ON_PLANLAR = [
  "android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png",
  "android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png",
  "android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png",
  "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png",
  "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png",
];

async function kosePikseli(gorecelYol: string): Promise<string> {
  const { data } = await sharp(resolve(KOK, gorecelYol))
    .extract({ left: 0, top: 0, width: 1, height: 1 })
    .raw()
    .toBuffer({ resolveWithObject: true });
  return (
    "#" +
    [data[0], data[1], data[2]]
      .map((v) => v.toString(16).padStart(2, "0"))
      .join("")
      .toUpperCase()
  );
}

describe("uygulama ikonu — her yüzeyde aynı", () => {
  it("bütün ikon dosyaları duruyor", () => {
    for (const yol of [...DUZ_IKONLAR, ...ON_PLANLAR]) {
      expect(existsSync(resolve(KOK, yol)), `eksik: ${yol}`).toBe(true);
    }
  });

  it("hepsi marka zeminini kullanıyor", async () => {
    const sapanlar: string[] = [];
    for (const yol of DUZ_IKONLAR) {
      const renk = await kosePikseli(yol);
      if (renk !== ZEMIN) sapanlar.push(`${yol} → ${renk}`);
    }
    expect(
      sapanlar,
      `İkon zemini ${ZEMIN} olmalı — web manifest background_color ve ` +
        "Android ic_launcher_background ile aynı. Sapan dosya, ürünün bir " +
        "yüzeyinde farklı ikon gösterir."
    ).toEqual([]);
  });

  it("uyarlanabilir ikonun ön planı saydam", async () => {
    // Saydam değilse Android zemin katmanını göremez, ikon kare kutuya döner.
    for (const yol of ON_PLANLAR) {
      const bilgi = await sharp(resolve(KOK, yol)).metadata();
      expect(bilgi.hasAlpha, `${yol} saydam değil`).toBe(true);
    }
  });

  it("tarayıcı sekmesi ikonu (favicon.ico) maskottan üretilmiş", () => {
    // 2026-09-09: `app/icon.png` eklenmişti ama Next sekmede favicon.ico'yu
    // sunuyor; eski 25 KB'lık dosya duruyordu ve sekmede maskot GÖRÜNMÜYORDU.
    // Yeniden üretildi: 16/32/48 px, PNG gömülü ICO.
    const ico = readFileSync(resolve(KOK, "public_web/src/app/favicon.ico"));
    expect(ico[0] === 0 && ico[1] === 0 && ico[2] === 1 && ico[3] === 0, "ICO değil").toBe(true);
    const girisSayisi = ico.readUInt16LE(4);
    expect(girisSayisi, "16/32/48 olmak üzere üç boyut bekleniyor").toBe(3);
    expect(ico.length).toBeLessThan(20000); // eski dosya 25 KB'dı
  });

  it("Android uyarlanabilir ikon tanımı yerinde", () => {
    // Bu dosya olmadan Android eski ikonu beyaz rozet içine koyar —
    // ana ekranda diğer uygulamalar gibi durmaz.
    expect(
      existsSync(resolve(KOK, "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"))
    ).toBe(true);
    expect(
      existsSync(resolve(KOK, "android/app/src/main/res/values/colors.xml"))
    ).toBe(true);
  });
});
