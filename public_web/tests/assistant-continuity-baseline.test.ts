import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Vixrex Asistan sürekliliği — PR 1 başlangıç sözleşmesi.
 *
 * Bu test üretim davranışını değiştirmez. Landing → Flutter kurulum →
 * tek kullanımlık sahip oturumu → Next.js sahip çalışma alanı hattında
 * korunacak mevcut sınırları kilitler. Bilinen devamlılık eksikleri
 * `it.todo` olarak görünür tutulur; yanlış davranış doğru kabul edilmez.
 */

const flutter = (path: string) =>
  readFileSync(resolve(__dirname, "../..", path), "utf-8");
const next = (path: string) =>
  readFileSync(resolve(__dirname, "..", path), "utf-8");

const landingSource = flutter("lib/screens/landing_screen.dart");
const homeShellSource = flutter("lib/screens/home_shell_screen.dart");
const vixrexScreenSource = flutter("lib/screens/vixrex_screen.dart");
const onboardingSource = flutter(
  "lib/screens/vixrex_onboarding_chat_screen.dart"
);
// Faz D (Tek Asistan planı, Flutter): kurulum sohbetinin adım makinesi ve
// yayınlama/sahip-çalışma-alanı çağrıları buraya taşındı — ekran artık
// bunları doğrudan içermez, VixRexOnboardingController üzerinden çağırır.
const onboardingControllerSource = flutter(
  "lib/controllers/vixrex_onboarding_controller.dart"
);
const flutterAvatarSource = flutter("lib/widgets/vixrex_avatar.dart");
const ownerPreviewSource = flutter("lib/services/owner_preview_service.dart");

const ownerEntryRouteSource = next("src/app/api/owner-session/route.ts");
const ownerPageSource = next("src/app/v/[slug]/page.tsx");
const ownerShellSource = next("src/app/v/[slug]/OwnerWorkspaceShell.tsx");
const ownerPanelSource = next("src/app/v/[slug]/OwnerAssistantPanel.tsx");
// Faz G3 (Tek Asistan planı, G3.1): panel içi başlık (avatar 36 + halo)
// ChatTopBar bileşenine çıkarıldı — sürekliliği kanıtlayan iki avatar
// çağrısından biri artık orada.
const ownerTopBarSource = next(
  "src/app/v/[slug]/components/ChatTopBar.tsx"
);
const ownerChatSource = next("src/app/v/[slug]/hooks/useOwnerChat.ts");
const nextAvatarSource = next(
  "src/app/v/[slug]/components/VixrexAvatar.tsx"
);

describe("Vixrex Asistan sürekliliği — korunan mevcut akış", () => {
  it("Landing işletme adını aynı Flutter editör state'ine taşır", () => {
    expect(landingSource).toContain("_storeNameController.text.trim()");
    expect(landingSource).toContain("initialIndex: 2");
    expect(landingSource).toContain(
      "initialVitrinName: initialVitrinName"
    );
    // "Vixrex Asistan tek oturum" işiyle (#129) editör artık paylaşılan bir
    // singleton (VixRexSessionController) — initialVitrinName hâlâ aynı
    // yere akıyor, yalnız çağrı `_editorController.initialize(...)`'dan
    // `VixRexSessionController.ensureInitialized(...)`'a taşındı.
    expect(homeShellSource).toContain(
      "VixRexSessionController.ensureInitialized(\n      widget.initialVitrinName"
    );
    expect(vixrexScreenSource).toContain(
      "VixRexOnboardingChatScreen("
    );
    expect(vixrexScreenSource).toContain(
      "editorController: widget.editorController"
    );
    expect(vixrexScreenSource).toContain(
      "editorInitialization: widget.editorInitialization"
    );
  });

  it("altı zorunlu kurulum adımı ve yayın durumu korunur", () => {
    for (const step of [
      "name",
      "category",
      "whatsapp",
      "location",
      "legal",
      "publishing",
    ]) {
      expect(onboardingSource, `${step} adımı kaybolmuş`).toContain(step);
    }
    expect(onboardingControllerSource).toContain("_editor.publish()");
  });

  it("kurulumun birincil kapısı güvenli sahip çalışma alanıdır", () => {
    expect(onboardingSource).toContain("'Vitrinini aç'");
    expect(onboardingSource).toContain("_onboarding.openOwnerWorkspace(");
    expect(onboardingControllerSource).toContain(
      "Future<void> openOwnerWorkspace("
    );
    expect(onboardingControllerSource).toContain(
      "_editor.openOwnerPreview("
    );
    expect(ownerPreviewSource).toContain(
      "buildOwnerSessionEntryLink(slug, code)"
    );
  });

  it("kalıcı edit_token URL'ye çıkmadan tek kullanımlık kod temiz URL'ye çevrilir", () => {
    expect(ownerEntryRouteSource).toContain(
      'url.searchParams.get("ocode")'
    );
    expect(ownerEntryRouteSource).toContain(
      'supabase.rpc("consume_owner_session"'
    );
    expect(ownerEntryRouteSource).toContain(
      "response.cookies.set(OWNER_SESSION_COOKIE"
    );
    expect(ownerEntryRouteSource).toContain(
      "const destination = new URL(`/v/${slug}`, url)"
    );
    expect(ownerEntryRouteSource).toContain(
      "NextResponse.redirect(destination, 303)"
    );
  });

  it("Next.js sahip paneli yalnız doğrulanmış sahip modunda açılır", () => {
    expect(ownerPageSource).toContain(
      "verifyOwnerSession(ownerSessionCookie, params.slug)"
    );
    expect(ownerPageSource).toContain(
      "getWorkingDraft(ownerSession.sessionToken)"
    );
    expect(ownerPageSource).toContain("if (!draft) {");
    expect(ownerPageSource).toContain("isOwnerMode = false");
    expect(ownerPageSource).toContain("{isOwnerMode ? (");
    expect(ownerPageSource).toContain("<OwnerWorkspaceShell");
  });

  it("mevcut tıkla-düzenle, taslak ve yayın araçları tek OwnerAssistantPanel'de kalır", () => {
    expect(ownerShellSource).toContain("<OwnerAssistantPanel");
    expect(ownerShellSource).not.toContain("PreviewEditorPanel");
    for (const hook of [
      "useOwnerDraft",
      "useOwnerChat",
      "useFieldSelection",
      "useOwnerActions",
    ]) {
      expect(ownerPanelSource).toContain(hook);
    }
  });

  it("manuel Flutter paneli kurtarma yolu olarak korunur", () => {
    expect(onboardingSource).toContain("'Detaylı formu aç'");
    expect(onboardingSource).toContain("_navigateAfterHandoff");
  });

  it("Flutter ve Next.js aynı canonical Vixrex maskotunu kullanır", () => {
    const canonicalAsset = "assets/images/vixrex_v_crystal_mascot.png";
    const flutterMascot = readFileSync(
      resolve(__dirname, "../..", canonicalAsset)
    );
    const nextMascot = readFileSync(
      resolve(__dirname, "../public/vixrex_v_crystal_mascot.png")
    );

    expect(flutterAvatarSource).toContain(canonicalAsset);
    expect(nextMascot.equals(flutterMascot)).toBe(true);
    expect(nextAvatarSource).toContain(
      'src="/vixrex_v_crystal_mascot.png"'
    );
    expect(ownerPanelSource).toContain("<VixrexAvatar size={28} decorative />");
    expect(ownerTopBarSource).toContain(
      "<VixrexAvatar size={36} halo decorative />"
    );
    expect(ownerPanelSource).toContain("aria-expanded={acik}");
    expect(ownerPanelSource).not.toContain("🦊");
    expect(nextAvatarSource).toContain('alt={decorative ? "" : "Vixrex"}');
  });
});

describe("Vixrex Asistan sürekliliği — sonraki PR kabul hedefleri", () => {
  it.todo(
    "birincil Flutter CTA transcript'i owner workspace açılmadan önce devreder"
  );
  it("Next.js sahip asistanı sürümlü ve güvenli handoff state alır", () => {
    expect(ownerPageSource).toContain("parseAssistantHandoff(draft.assistant_handoff)");
    expect(ownerPageSource).toContain("assistantHandoff={assistantHandoff}");
    expect(ownerShellSource).toContain("assistantHandoff={assistantHandoff}");
    expect(ownerPanelSource).toContain("useOwnerChat(rapor, assistantHandoff)");
  });

  it("Next.js tekrar selam vermeden handoff'taki sıradaki adımdan devam eder", () => {
    expect(ownerChatSource).toContain("ownerChatInitialMessages(rapor, handoff)");
  });
});
