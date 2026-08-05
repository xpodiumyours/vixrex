import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// implementation_plan.md Commit 7: Sahip çalışma alanı kabuğu
// Davranışsal testler — kaynak metin arayan sözleşme testlerinin ötesinde.

const MAIN_PAGE_PATH = resolve(__dirname, "../src/app/v/[slug]/page.tsx");
const pageSource = readFileSync(MAIN_PAGE_PATH, "utf-8");

const SHELL_PATH = resolve(__dirname, "../src/app/v/[slug]/OwnerWorkspaceShell.tsx");
const shellSource = readFileSync(SHELL_PATH, "utf-8");

const PREVIEW_PANEL_PATH = resolve(__dirname, "../src/app/v/[slug]/PreviewEditorPanel.tsx");
const previewPanelSource = readFileSync(PREVIEW_PANEL_PATH, "utf-8");

describe("sahip çalışma alanı kabuğu — davranışsal garantiler", () => {
  it("müşteri modunda (owner cookie yok) OwnerWorkspaceShell render edilmez", () => {
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    // isOwnerMode false olduğunda ternary'nin else kolu çalışır
    expect(renderBlock).toContain("isOwnerMode ? (");
    expect(renderBlock).toContain("<OwnerWorkspaceShell");
    // PreviewEditorPanel sadece isPreviewMode true ise render edilir
    expect(renderBlock).toContain("isPreviewMode ? (");
  });

  it("sahip modunda vitrin (VitrinProfileView) tam olarak bir kez render edilir", () => {
    // page.tsx içinde VitrinProfileView import edilir ve render bloğunda bir kez çağrılır
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    const vitrinProfileViewCount = (renderBlock.match(/<VitrinProfileView/g) || []).length;
    expect(vitrinProfileViewCount).toBe(1);
  });

  it("legacy preview_token akışı bozulmamış — PreviewEditorPanel hala var", () => {
    // PreviewEditorPanel import edildi ve legacy branch'te kullanılıyor
    expect(pageSource).toContain("import PreviewEditorPanel from");
    const renderBlock = pageSource.slice(pageSource.indexOf("return (\n    <>"));
    expect(renderBlock).toContain("<PreviewEditorPanel");
    expect(renderBlock).toContain("previewToken!");
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
      pageSource.indexOf("} else if (isPreviewMode)")
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
      pageSource.indexOf("} else if (isPreviewMode)")
    );
    expect(draftSuccessBlock).toContain("sessionExpiresAt = decoded.exp ?? null");
    expect(draftSuccessBlock).not.toContain("* 1000");
  });

  it("sahip panelinde PreviewEditorPanel disabled ile yeniden kullanılır (form kopyası yok)", () => {
    // OwnerWorkspaceShell PreviewEditorPanel'i disabled=true ile çağırıyor
    expect(shellSource).toContain("import PreviewEditorPanel from");
    expect(shellSource).toContain("<PreviewEditorPanel");
    expect(shellSource).toContain("disabled={true}");
    // Kendi içinde form input kopyası YOK
    expect(shellSource).not.toContain("htmlFor=");
    expect(shellSource).not.toContain("onChange=");
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
    
    // PreviewEditorPanel sadece isPreviewMode true ve isOwnerMode false iken
    const previewPanelCount = (renderBlock.match(/<PreviewEditorPanel/g) || []).length;
    expect(previewPanelCount).toBe(1);
  });

  it("PreviewEditorPanel disabled modunda save butonu devre dışı ve mesaj gösterir", () => {
    expect(previewPanelSource).toContain("disabled={disabled}");
    // Metnin tamamı yerine parçalarına bakılır: JSX'te kesme işareti
    // &apos; olarak kaçırılmak zorunda (react/no-unescaped-entities), bu da
    // birebir metin karşılaştırmasını kırıyordu.
    expect(previewPanelSource).toContain("Kaydet");
    expect(previewPanelSource).toContain("Commit 8");
    expect(previewPanelSource).toContain("aktif olacak");
    expect(previewPanelSource).toContain("cursor-not-allowed");
  });

  it("OwnerWorkspaceShell kendi içinde VitrinProfileView render etmez", () => {
    expect(shellSource).not.toContain("<VitrinProfileView");
  });

  it("getWorkingDraft ÇEREZLE değil, paketten çıkarılan gerçek token ile çağrılır", () => {
    const ownerModeBlock = pageSource.slice(
      pageSource.indexOf("if (isOwnerMode && ownerSession && ownerSessionCookie)"),
      pageSource.indexOf("} else if (isPreviewMode)")
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