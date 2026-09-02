import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Faz C3 (Tek Asistan planı, 2026-09-02) — "Kirala" artık Keşfet'ten
 * ayrılmadan çalışıyor (useKesfetKirala.ts). Bu KASITLI bir kopya,
 * `/rent-demo/page.tsx`'in (Flutter harici tarayıcı + eski APK'lar hâlâ
 * doğrudan kullanıyor) refactor'ü DEĞİL — o dosyaya dokunulmadı.
 *
 * Güvenlik sözleşmesi (api/rent-demo/route.ts okunarak doğrulandı):
 * asıl zorunlu kapı client IP HMAC parmak izi + start_demo_trial
 * RPC'sindeki oran sınırı — reCAPTCHA yumuşak/ek sinyal. Bu testler
 * hook'un aynı native-form-POST mekaniğini koruduğunu kilitler.
 */
describe("useKesfetKirala — /rent-demo/page.tsx ile aynı güvenlik mekaniği", () => {
  const kaynak = oku("lib/useKesfetKirala.ts");
  const kopruSayfasi = oku("app/rent-demo/page.tsx");

  it("/rent-demo/page.tsx'e dokunulmadı — Flutter/eski APK'lar için hâlâ orada", () => {
    expect(kopruSayfasi).toContain("RentDemoIcerik");
    expect(kopruSayfasi).toContain('action="/api/rent-demo"');
  });

  it("misafir yolunda gerçek form POST'a geçiyor — fetch değil", () => {
    expect(kaynak).toContain('if (durum === "gonderiliyor" && token && formRef.current) {');
    expect(kaynak).toContain("formRef.current.submit();");
  });

  it("hesaplı kullanıcı önce kontrol ediliyor — misafir/hesaplı dalları /rent-demo ile aynı", () => {
    expect(kaynak).toContain("const kaliciHesapVar = session?.user != null && !session.user.is_anonymous;");
    expect(kaynak).toContain('fetch("/api/rent-demo/hesap"');
  });

  it("hesap gerekiyor ama giriş DUVARI değil — misafir yolu bilinçli tercihle hâlâ açık", () => {
    // UI/UX görünüm fazı (2026-09-02): hesabı olmayan ziyaretçi artık
    // otomatik misafir kiralamıyor, önce "Google ile devam et" görüyor
    // (hesapGerekli). Ama /giris?next= gibi kesin bir duvar da yok —
    // misafirDevamEt() ile eski akış hâlâ bilinçli olarak seçilebilir.
    expect(kaynak).not.toContain("/giris?next=");
    expect(kaynak).toContain('"hesapGerekli"');
    expect(kaynak).toContain("function misafirDevamEt()");
  });

  it("zaten vitrini olan kullanıcı 409'da yönlendirilmiyor, bilgilendiriliyor", () => {
    expect(kaynak).toContain('"zatenVitriniVar"');
    expect(kaynak).toContain("kiralamaYaniti.status === 409");
  });
});
