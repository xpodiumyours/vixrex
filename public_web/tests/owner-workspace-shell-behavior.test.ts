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

  // Faz 4/6, Issue #91 — kod izini sürünce planın varsaydığı asimetri
  // ("Next.js, Flutter'ın yayınladığını yalnız kendi yayınlama denemesinde
  // DRAFT_STALE ile öğrenir") GERÇEK OLMADIĞI görüldü: stores tablosu zaten
  // realtime yayınına ekli, OwnerAssistantPanel zaten `vitrin_${slug}`
  // kanalını her zaman dinliyor (kaynağa göre ayrım yok — Flutter'ın
  // yayınladığı UPDATE de, Next.js'in kendi publish_working_draft'ı da aynı
  // şekilde yakalanıyor), getWorkingDraft önbelleklenmiyor, ve sürüm
  // çakışması banda zaten çıkıyor. Yeni bir broadcast kurmak yerine bu
  // zaten çalışan zinciri kilitleyen bir koruma testi ekliyoruz — yoksa
  // biri "taslakDinle"siz bir refactor'de bunu sessizce kırabilir.
  describe("Flutter'ın yayını Next.js paneline anlık yansır (zaten çalışıyor, kilitleniyor)", () => {
    const REALTIME_MIGRATION_PATH = resolve(
      __dirname,
      "../../supabase/migrations/20260806220000_enable_realtime_on_stores.sql"
    );
    const realtimeMigrationSource = readFileSync(REALTIME_MIGRATION_PATH, "utf-8");

    const SENKRON_PATH = resolve(__dirname, "../src/lib/canliVitrinSenkron.ts");
    const senkronSource = readFileSync(SENKRON_PATH, "utf-8");

    const PANEL_PATH = resolve(__dirname, "../src/app/v/[slug]/OwnerAssistantPanel.tsx");
    const panelSource = readFileSync(PANEL_PATH, "utf-8");

    const OWNER_DRAFT_HOOK_PATH = resolve(
      __dirname,
      "../src/app/v/[slug]/hooks/useOwnerDraft.ts"
    );
    const ownerDraftHookSource = readFileSync(OWNER_DRAFT_HOOK_PATH, "utf-8");

    it("stores tablosu realtime yayınına eklidir — Flutter'ın UPDATE'i dışarıdan görülebilir", () => {
      expect(realtimeMigrationSource).toContain(
        "alter publication supabase_realtime add table public.stores"
      );
    });

    it("useCanliVitrinSenkron, stores UPDATE'ini KAYNAĞA BAKMADAN dinler (yalnız slug'a göre filtreler)", () => {
      expect(senkronSource).toContain('event: "UPDATE"');
      expect(senkronSource).toContain('table: "stores"');
      expect(senkronSource).toContain("filter: `slug=eq.${slug}`");
      expect(senkronSource).toContain("router.refresh()");
    });

    it("OwnerAssistantPanel bu senkronu sahip modunda HER ZAMAN etkin bırakır (etkin=true, koşulsuz)", () => {
      // Tam tek satır eşleşmesi yerine esnek desen — ADR 0002 3. alt-fazında
      // useOwnerDraft'a üçüncü argüman (atlananAlanlar) eklenince çağrı
      // birden çok satıra yayıldı, tam metin eşleşmesi kırılgan olurdu.
      expect(panelSource).toMatch(/useOwnerDraft\(\s*slug,\s*draftData,/);
      expect(ownerDraftHookSource).toContain(
        "useCanliVitrinSenkron(slug, true, true)"
      );
    });

    it("getWorkingDraft önbelleklenmez — her router.refresh() gerçek çakışma durumunu yeniden hesaplar", () => {
      // Fonksiyonun kendi tanımı unstable_cache sarmalamıyor (getStoreData'nın
      // aksine — o 60sn revalidate ile önbellekli, taslak asla öyle olmamalı).
      const fnStart = pageSource.indexOf(
        "async function getWorkingDraft(sessionToken: string)"
      );
      const fnBody = pageSource.slice(fnStart, pageSource.indexOf("\n}\n", fnStart));
      expect(fnBody).not.toContain("unstable_cache");

      // Çağrı yeri de sarmalanmamış — doğrudan await ile çağrılıyor.
      const callSiteStart = pageSource.indexOf("draft = await getWorkingDraft(");
      expect(callSiteStart).toBeGreaterThan(-1);
      const callSiteContext = pageSource.slice(
        Math.max(0, callSiteStart - 200),
        callSiteStart
      );
      expect(callSiteContext).not.toContain("unstable_cache");
    });

    it("sürüm çakışması banda çıkar, çare zaten var olan tazeleme uç noktasına bağlıdır", () => {
      expect(shellSource).toContain("draft?.version_conflict");
      expect(shellSource).toContain("Canlı sürümü al");
      expect(shellSource).toContain('fetch("/api/owner-refresh"');
    });
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
