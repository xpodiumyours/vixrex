import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Sözleşme testi: Public kök navigasyonu.
 *
 * 2026-08-26'DA TERSİNE ÇEVRİLDİ (#344). Bu dosya önceden şunu kilitliyordu:
 * "`/` kök isteği 307 ile app hosta redirect eder." O davranış artık YANLIŞ
 * ve bilinçli olarak kaldırıldı.
 *
 * NEDEN: kök uygulamaya yönlendiği sürece Google'ın okuyabileceği tek yüzey
 * `/v/{slug}` vitrin sayfalarıydı; platformun kendisi (ana sayfa, Keşfet
 * dizini, kategori sayfaları) arama sonuçlarında hiç yoktu. Yönlendirme hem
 * `next.config.ts`'in `redirects()` bloğunda hem `src/app/page.tsx` içinde
 * iki kez tanımlıydı, ikisi de silindi. Kök artık gerçek, sunucuda üretilen
 * bir sayfa.
 *
 * Test SİLİNMEDİ, güncellendi: aynı yüzeyi bu sefer ters yönde bekçilik
 * ediyor — yönlendirme sessizce geri gelirse ana sayfa yine görünmez olur.
 * Hâlâ geçerli olan iki iddia (kök bağlantısının tam sayfa navigasyonu ve
 * `_rsc` istisnasının bulunmaması) aynen korundu.
 */

const nextConfigPath = resolve(__dirname, "../../next.config.ts");
const configSource = readFileSync(nextConfigPath, "utf-8");

const rootPagePath = resolve(__dirname, "../../src/app/(site)/page.tsx");
const rootPageSource = readFileSync(rootPagePath, "utf-8");

const profileViewPath = resolve(
  __dirname,
  "../../src/app/v/[slug]/VitrinProfileView.tsx",
);
const profileViewSource = readFileSync(profileViewPath, "utf-8");

describe("Public kök navigasyon sözleşmesi", () => {
  it("next.config.ts artık kök redirect'i BARINDIRMAZ", () => {
    expect(configSource).not.toContain("redirects()");
    expect(configSource).not.toContain('source: "/"');
  });

  it("kök sayfa uygulamaya yönlendirmez, gerçek içerik döner", () => {
    expect(rootPageSource).not.toContain('from "next/navigation"');
    expect(rootPageSource).toContain("export default async function HomePage");
  });

  it("_rsc missing istisnası yoktur — kökte koşullu yönlendirme kalmadı", () => {
    expect(configSource).not.toContain("_rsc");
    expect(configSource).not.toContain("missing");
  });

  it("sayfadaki kök bağlantısı <a href=\"/\"> tam sayfa navigasyonudur", () => {
    expect(profileViewSource).toContain('<a href="/"');
    expect(profileViewSource).not.toContain('<Link href="/"');
  });
});
