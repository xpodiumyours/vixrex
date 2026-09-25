import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// 2026-09-25 sözleşmesi: asistan hata yollarında SESSİZ YUTMA YOK.
// Kök neden: esnaf aynı değeri tekrar tekrar yazıyordu, asistan her
// seferinde soruyu tekrar ediyordu; API hatası (oturum süresi vb.)
// hiçbir zaman ekrana çıkmıyordu.
const dosya = join(
  import.meta.dirname,
  "..",
  "src/app/v/[slug]/hooks/useOwnerActions.ts",
);

describe("asistan sessiz yutma sözleşmesi", () => {
  const kaynak = readFileSync(dosya, "utf8");

  it("döngü kırıcı eşiği tanımlı ve 2", () => {
    expect(kaynak).toContain("DONGU_KIRICI_ESIK = 2");
  });

  it("döngü kırıcı aynı (alan, girdi) tekrarında doğrudan kaydı dener", () => {
    expect(kaynak).toContain("sonReddedilenRef");
    expect(kaynak).toContain("kaydetSeciliAlana(metin)");
    expect(kaynak).toContain("doğrudan kaydetmeyi deniyorum");
  });

  it("alan kayıt yolu API'nin gerçek hata mesajını sohbete yazar", () => {
    expect(kaynak).toMatch(/govde\?\.hata \?\? "Kaydedilemedi\./);
  });

  it("bonus kayıt yolunda sessiz return kalmadı", () => {
    const bonus = kaynak.slice(
      kaynak.indexOf("export async function bonusAlanlariCikarVeKaydet"),
      kaynak.indexOf("export function useOwnerActions"),
    );
    expect(bonus).not.toMatch(/if \(!yanit\.ok\) return;/);
    expect(bonus).toContain("Ek alanlar kaydedilemedi");
    expect(bonus).toContain("esnaf haberdar edilir");
  });

  it("kaydetSeciliAlana alan yoksa yönlendirir — sessizce döndürmez", () => {
    expect(kaynak).toContain("Önce vitrinde düzenlenecek bir yere tıkla.");
  });

  it("döngü kırıcı alan seçili DEĞİLKEN de çalışır: bonus kayıt + net yönlendirme", () => {
    expect(kaynak).toContain("içinden tanıdığım bilgileri kaydetmeyi deniyorum");
    expect(kaynak).toContain("İşletme adı için lütfen vitrindeki İŞLETME ADI yazısına tıkla");
  });
});
