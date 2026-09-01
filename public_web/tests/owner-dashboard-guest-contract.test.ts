import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const oku = (path: string) =>
  readFileSync(resolve(__dirname, path), "utf-8");

const dashboard = oku("../src/app/app/page.tsx");
const route = oku("../src/app/api/owner-dashboard/route.ts");
const ownerSession = oku("../src/lib/ownerSession.ts");
const editor = oku("../src/components/owner/VitrinimEditor.tsx");

describe("Vitrinim misafir sahiplik geçişi", () => {
  it("Supabase hesabı yokken önce mevcut sahip çerezini dener", () => {
    const sessionBlock = dashboard.slice(
      dashboard.indexOf("if (!session)"),
      dashboard.indexOf("setUser(session.user)")
    );
    expect(sessionBlock).toContain("misafirVitrininiGetir()");
    expect(sessionBlock.indexOf("misafirVitrininiGetir()")).toBeLessThan(
      sessionBlock.indexOf('router.push("/giris")')
    );
  });

  it("manuel paneli HMAC sahip çerezi ve sunucu taslağıyla açar", () => {
    expect(route).toContain("OWNER_SESSION_COOKIE");
    expect(route).toContain("verifyOwnerSession(");
    expect(route).toContain('"get_working_draft_for_session"');
    expect(route).toContain('.eq("id", ownerSession.storeId)');
    expect(route).toContain('.eq("slug", ownerSession.slug)');
    expect(route).not.toContain("sessionToken:");
  });

  it("misafir paneli yenilemede hesap RPC'sine dönmez", () => {
    expect(dashboard).toContain("if (misafirSahip)");
    expect(dashboard).toContain("await misafirVitrininiGetir(false)");
  });

  it("manuel panel açık kaldıkça sahip oturumunu yeniler", () => {
    expect(editor).toContain('fetch("/api/owner-session-extend"');
    expect(editor).toContain("5 * 60 * 1000");
  });

  it("slug verilmediğinde yalnız imzası doğrulanmış çerezdeki slugı kabul eder", () => {
    expect(ownerSession).toContain("slug?: string");
    expect(ownerSession).toContain("if (slug && parsed.slug !== slug) return null");
  });
});
