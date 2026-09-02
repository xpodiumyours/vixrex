import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * UI/UX görünüm fazı (2026-09-02) — Keşfet'te "uyarla" anı artık hesap
 * istiyor: hesabı olmayan ziyaretçi "Google ile devam et" görür,
 * linkIdentity() ile /kesfet-hesap-bagla üzerinden rent_demo_canonical'a
 * (hesap zorunlu, is_permanent_user ile korunur) bağlanır.
 */
describe("useKesfetKirala — hesapGerekli akışı", () => {
  const kaynak = oku("lib/useKesfetKirala.ts");

  it("hesabı olmayan ziyaretçi artık otomatik misafir kiralamıyor", () => {
    expect(kaynak).toContain('setDurum("hesapGerekli");');
  });

  it("Google ile bağlanma /kesfet-hesap-bagla'ya yönlendirir", () => {
    expect(kaynak).toContain("supabase.auth.linkIdentity({");
    expect(kaynak).toContain("/kesfet-hesap-bagla?slug=");
  });

  it("oturum yoksa önce signInAnonymously ile geçici kimlik kurulur (linkIdentity'nin bağlanacağı)", () => {
    expect(kaynak).toContain("supabase.auth.signInAnonymously()");
  });
});

describe("/kesfet-hesap-bagla — Google dönüş noktası", () => {
  const kaynak = oku("app/kesfet-hesap-bagla/page.tsx");

  it("rent_demo_canonical'ı /api/rent-demo/hesap üzerinden çağırır", () => {
    expect(kaynak).toContain('fetch("/api/rent-demo/hesap"');
  });

  it("409 (zaten vitrini var) durumunda mevcut vitrine yönlendirir", () => {
    expect(kaynak).toContain('yanit.status === 409');
  });

  it("anonim oturumla buraya düşülürse hata gösterir, sessizce ilerlemez", () => {
    expect(kaynak).toContain("session.user.is_anonymous");
  });
});

describe("Keşfet — Vixrex sekmesi landing'den gelince otomatik açılır", () => {
  it("kategori param'ı varsa (landing niyet akışı) sekme elle tıklanmayı beklemez", () => {
    const kaynak = oku("components/kesfet/KesfetIcerik.tsx");
    expect(kaynak).toContain('=== "1" ||\n        ilkKategoriKimligi');
  });
});
