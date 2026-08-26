import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const nextConfig = readFileSync(
  resolve(__dirname, "../next.config.ts"),
  "utf-8"
);
const anaSayfa = readFileSync(
  resolve(__dirname, "../src/app/(site)/page.tsx"),
  "utf-8"
);
const flutterVercel = readFileSync(
  resolve(__dirname, "../../vercel.json"),
  "utf-8"
);

/**
 * Ana kapı sözleşmesi (#344, 2026-08-26).
 *
 * 2026-08-26'ya kadar `/` iki ayrı yerde birden uygulamaya yönlendiriliyordu:
 * `next.config.ts`'in `redirects()` bloğunda (platform seviyesinde, sayfa
 * hiç çalışmadan) ve `src/app/page.tsx` içindeki `redirect(getAppUrl())`
 * çağrısında. Sonuç: Google'ın okuyabildiği tek yüzey `/v/{slug}` vitrin
 * sayfalarıydı, platformun kendisi arama sonuçlarında hiç yoktu.
 *
 * Bu test o yönlendirmelerin geri gelmesini engeller. Yönlendirme sessizce
 * geri eklenirse ana sayfa yeniden görünmez olur ve kimse fark etmez.
 */
describe("ana kapı — Next kökü sahiplenir, uygulamaya yönlendirmez", () => {
  it("next.config.ts'te redirects() bloğu yok", () => {
    expect(nextConfig).not.toContain("redirects()");
    expect(nextConfig).not.toContain("getAppUrl");
  });

  it("kök sayfa gerçek bir sayfa döner, redirect çağırmaz", () => {
    // Yorum metni değil, gerçek bağımlılık kontrol edilir: yönlendirme
    // yapmanın tek yolu bu iki modülden birini içe aktarmaktır.
    expect(anaSayfa).not.toContain('from "next/navigation"');
    expect(anaSayfa).not.toContain('from "@/lib/siteUrl"');
    expect(anaSayfa).toContain("export default async function HomePage");
  });

  it("kök sayfa dosyası duruyor (statik Flutter index'i kökü kapmasın)", () => {
    expect(anaSayfa.trim().length).toBeGreaterThan(0);
  });

  it("Flutter yüzeyi aramadan çıkarıldı ama içerik yollarını devretmeye devam eder", () => {
    // noindex: aynı içerik iki adreste indekslenip birbirinin sinyalini
    // bölmesin. Robots.txt ile ENGELLEMEK yanlış olurdu — tarayıcı sayfayı
    // hiç çekmezse noindex başlığını da hiç okuyamaz.
    expect(flutterVercel).toContain("X-Robots-Tag");
    expect(flutterVercel).toContain("noindex, nofollow");

    // Bu üç yönlendirme, uygulama adresinin içerik URL'lerini public
    // yüzeye devretmesini sağlar; kaldırılırsa vitrinler iki yerden birden
    // servis edilir.
    expect(flutterVercel).toContain("/v/:path*");
    expect(flutterVercel).toContain("/sitemap.xml");
    expect(flutterVercel).toContain("/robots.txt");
  });
});
