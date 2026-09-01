import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

describe("landing Flutter hesap bağlama paritesi", () => {
  it("yayın sonrası cihaz bağlı uyarısını ve Google kimlik bağlamayı gösterir", () => {
    const kaynak = oku("components/landing/LandingAsistanSohbeti.tsx");
    expect(kaynak).toContain("Vitrinini hesabına bağla");
    expect(kaynak).toContain("bu cihaza bağlı");
    expect(kaynak).toContain("supabase.auth.linkIdentity");
    expect(kaynak).toContain("sonuc.yonlendir");
  });

  it("Google dönüşünde sahip çereziyle aynı vitrini kalıcı hesaba bağlar", () => {
    const kaynak = oku("app/api/account/link-store/route.ts");
    expect(kaynak).toContain("verifyOwnerSession");
    expect(kaynak).toContain('rpc("extend_owner_session"');
    expect(kaynak).toContain('rpc("claim_store_for_user"');
  });

  it("Google dönüş sayfası yeni oturum açmadan mevcut kimlik bağını tamamlar", () => {
    const kaynak = oku("app/hesap-bagla/page.tsx");
    expect(kaynak).toContain("supabase.auth.getSession");
    expect(kaynak).toContain('fetch("/api/account/link-store"');
  });
});
