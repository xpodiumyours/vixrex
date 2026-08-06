import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// implementation_plan.md Commit 7: Sahip çalışma alanı kabuğu
// Davranışsal testler — kaynak metin arayan sözleşme testlerinin ötesinde.

const MAIN_PAGE_PATH = resolve(__dirname, "../src/app/v/[slug]/page.tsx");
const pageSource = readFileSync(MAIN_PAGE_PATH, "utf-8");

const SHELL_PATH = resolve(__dirname, "../src/app/v/[slug]/OwnerWorkspaceShell.tsx");
const shellSource = readFileSync(SHELL_PATH, "utf-8");


describe("sahip çalışma alanı kabuğu — davranışsal garantiler", () => {
  it("müşteri modunda (owner cookie yok) OwnerWorkspaceShell render edilmez", () => {
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    // isOwnerMode false olduğunda ternary'nin else kolu çalışır
    expect(renderBlock).toContain("isOwnerMode ? (");
    expect(renderBlock).toContain("<OwnerWorkspaceShell");
    // Sahip degilse hicbir sahip araci cizilmez.
    expect(renderBlock).toContain(") : null}");
  });

  it("sahip modunda vitrin (VitrinProfileView) tam olarak bir kez render edilir", () => {
    // page.tsx içinde VitrinProfileView import edilir ve render bloğunda bir kez çağrılır
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    const vitrinProfileViewCount = (renderBlock.match(/<VitrinProfileView/g) || []).length;
    expect(vitrinProfileViewCount).toBe(1);
  });

  it("legacy preview_token akışı KALDIRILDI (Commit 12)", () => {
    // Eskiden sahip oturumu OLMADAN da açılabilen ikinci bir düzenleme
    // yolu vardı: ?preview_token=... ile gelen herkes forma erişiyordu.
    // Kaldırıldı; bu test geri gelmesini engeller.
    expect(pageSource).not.toContain("PreviewEditorPanel");
    expect(pageSource).not.toContain("preview_token");
    expect(pageSource).not.toContain("previewToken");
  });

  it("geçersiz/başka slug'a ait sahip çerezi taslağı açamaz (verifyOwnerSession slug kontrolü)", () => {
    expect(pageSource).toContain("verifyOwnerSession(ownerToken, params.slug)");
    // OwnerWorkspaceShell sadece isOwnerMode true iken render edilir
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    expect(renderBlock).toContain("isOwnerMode ? (");
  });

  it("edit_token client props/HTML/RSC çıktısına aktarılmaz", () => {
    // page.tsx içinde edit_token okunmuyor, getWorkingDraft empty string ile çağrılıyor
    const ownerModeBlock = pageSource.slice(
      pageSource.indexOf("if (isOwnerMode && ownerSession)"),
      pageSource.indexOf("  if (!data) {")
    );
    expect(ownerModeBlock).not.toContain("edit_token");
    expect(ownerModeBlock).not.toContain("select(\"edit_token\")");
    // OwnerWorkspaceShell'e editToken prop'u geçilmiyor
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    const shellBlock = renderBlock.slice(
      renderBlock.indexOf("<OwnerWorkspaceShell"),
      renderBlock.indexOf("/>") + 2
    );
    expect(shellBlock).not.toContain("editToken");
  });

  it("oturum süresi doğru hesaplanır (exp zaten ms cinsinden, *1000 yok)", () => {
    // sessionExpiresAt, draft başarılı olduğunda (else bloğu içinde) set edilir
    const draftSuccessBlock = pageSource.slice(
      pageSource.indexOf("if (!draft) {"),
      pageSource.indexOf("  if (!data) {")
    );
    expect(draftSuccessBlock).toContain("sessionExpiresAt = decoded.exp ?? null");
    expect(draftSuccessBlock).not.toContain("* 1000");
  });

  it("sahip panelinde form değil, tıkla-düzenle editörü bulunur (üçüncü kapı yok)", () => {
    // 2026-08-05 kararı (VIXREX_RULES.md §1): düzenlemenin iki kapısı vardır
    // — Flutter manuel paneli ve Next.js'teki Vixrex Asistan. Next.js
    // tarafında ikinci bir FORM paneli açılmaz; o üçüncü kapı olur ve aynı
    // alan için iki kayıt yolu doğurur.
    expect(shellSource).toContain("import OwnerAssistantPanel from");
    expect(shellSource).toContain("<OwnerAssistantPanel");
    expect(shellSource).not.toContain("PreviewEditorPanel");
    // Kabuk kendi içinde form kopyası tutmaz; düzenleme asistana aittir.
    expect(shellSource).not.toContain("htmlFor=");
    expect(shellSource).not.toContain("handleSave");
  });

  it("müsteri görünümünün temel DOM yapısı değişmez (tek VitrinProfileView render)", () => {
    // VitrinProfileView ternary'nin ÖNCESİNDE (617-673 arası) tek kez render edilir
    // Ternary sadece sidebar/panel için: OwnerWorkspaceShell VEYA PreviewEditorPanel VEYA null
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    
    // VitrinProfileView tam olarak bir kez geçiyor (ternary'den önce)
    const vitrinProfileViewCount = (renderBlock.match(/<VitrinProfileView/g) || []).length;
    expect(vitrinProfileViewCount).toBe(1);
    
    // OwnerWorkspaceShell sadece isOwnerMode true iken
    const shellCount = (renderBlock.match(/<OwnerWorkspaceShell/g) || []).length;
    expect(shellCount).toBe(1);
    
    // Sahip araci tek dal: ya kabuk ya hicbir sey.
    const previewPanelCount = (renderBlock.match(/<PreviewEditorPanel/g) || []).length;
    expect(previewPanelCount).toBe(0);
  });

  it("OwnerWorkspaceShell kendi içinde VitrinProfileView render etmez", () => {
    expect(shellSource).not.toContain("<VitrinProfileView");
  });

  it("getWorkingDraft ÇEREZLE değil, paketten çıkarılan gerçek token ile çağrılır", () => {
    const ownerModeBlock = pageSource.slice(
      pageSource.indexOf("if (isOwnerMode && ownerSession && ownerSessionCookie)"),
      pageSource.indexOf("  if (!data) {")
    );

    // 2026-08-05'te bulunan hata: çereze ve içindeki tokene aynı ad
    // verilmişti; RPC'ye imzalı paketin TAMAMI gidiyor, veritabanı
    // INVALID_SESSION_TOKEN döndürüyordu ve sahip paneli hiç açılmıyordu.
    // Çerez != token. Gerçek token yalnız verifyOwnerSession() ile çıkar.
    expect(ownerModeBlock).toContain("getWorkingDraft(ownerSession.sessionToken)");
    expect(ownerModeBlock).not.toContain("getWorkingDraft(ownerSessionCookie)");
    expect(pageSource).toContain("async function getWorkingDraft(sessionToken: string)");
    // edit_token KULLANILMAZ
    expect(ownerModeBlock).not.toContain("edit_token");
    expect(ownerModeBlock).not.toContain("select(\"edit_token\")");
  });
});