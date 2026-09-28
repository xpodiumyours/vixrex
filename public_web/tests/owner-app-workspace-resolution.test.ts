import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const appPage = readFileSync(
  resolve(__dirname, "../src/app/app/page.tsx"),
  "utf8"
);
const ownerBridge = readFileSync(
  resolve(__dirname, "../src/app/api/owner-workspace/current/route.ts"),
  "utf8"
);
const vitrinEditor = readFileSync(
  resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"),
  "utf8"
);
const flutterRouter = readFileSync(
  resolve(__dirname, "../../lib/config/app_router.dart"),
  "utf8"
);

describe("/app sahip çalışma alanı çözümleme matrisi", () => {
  it("Flutter Web referansı /app -> Vitrinim (index 0) olarak kilitlidir", () => {
    expect(flutterRouter).toContain(
      "GoRoute(\n        path: app,\n        builder: (context, state) => const HomeShellScreen(initialIndex: 0)"
    );
  });

  it("hesaba bağlı vitrin birincil kaynak olmaya devam eder", () => {
    const accountBootstrap = appPage.indexOf('"get_owner_workspace_bootstrap"');
    const ownerCookieBridge = appPage.indexOf('fetch("/api/owner-workspace/current"');
    expect(accountBootstrap).toBeGreaterThan(-1);
    expect(ownerCookieBridge).toBeGreaterThan(accountBootstrap);
  });

  it("hesapta vitrin yoksa geçerli owner cookie aynı working_draft + kataloğu açar", () => {
    expect(appPage).toContain('fetch("/api/owner-workspace/current"');
    expect(ownerBridge).toContain("OWNER_SESSION_COOKIE");
    expect(ownerBridge).toContain("verifyOwnerSession(ownerSessionCookie, hintedSlug)");
    expect(ownerBridge).toContain('"get_working_draft_for_session"');
    expect(ownerBridge).toContain('"get_owner_catalog_for_session"');
    expect(ownerBridge).toContain('"cache-control": "private, no-store"');
  });

  it("owner session tokenı istemciye dönmez", () => {
    expect(ownerBridge).not.toMatch(/sessionToken\s*:/);
    expect(ownerBridge).not.toContain('"session_token"');
    expect(ownerBridge).not.toMatch(/ownerSessionCookie\\s*:/);
  });

  it("eski flowState /app ekranını ele geçiremez", () => {
    expect(appPage).not.toContain("Kurulumun kaldığı yerden devam ediyor");
    expect(appPage).not.toContain("Sıradaki adım:");
    expect(appPage).not.toContain("setFlowState");
    expect(appPage).not.toContain("{flowState ? (");
  });

  it("vitrin yoksa doğrudan manuel VitrinimEditor creation modu açılır", () => {
    expect(appPage).toContain("<VitrinimEditor");
    expect(appPage).toContain("isCreationMode");
    expect(appPage).toContain('slug: "taslak"');
  });

  it("manuel panel mevcut owner-draft yazma yolunu kullanır", () => {
    expect(vitrinEditor).toContain('/api/owner-draft');
  });
});
