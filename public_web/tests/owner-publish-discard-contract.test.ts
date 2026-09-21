import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// Faz 11 — yayınla / vazgeç güvenlik sözleşmesi (implementation_plan.md Faz 11).
// owner-draft ucu bloğuyla aynı desen: kaynak metin okuyan sözleşme testleri.

const publishSource = readFileSync(
  resolve(__dirname, "../src/app/api/owner-publish/route.ts"),
  "utf-8"
);
const discardSource = readFileSync(
  resolve(__dirname, "../src/app/api/owner-discard/route.ts"),
  "utf-8"
);
// 2026-08-20: yasal onay artık Vixrex Asistan'dan da verilebilir — aynı
// oturum deseni, ayrı ve dar bir RPC (accept_store_legal_consent).
const acceptLegalSource = readFileSync(
  resolve(__dirname, "../src/app/api/owner-accept-legal/route.ts"),
  "utf-8"
);
// OwnerAssistantPanel 730→128 satıra bölündü (2026-08-10); yayınla/vazgeç
// düğmeleri PublishBar bileşeninde, fetch çağrıları ve sonuç mesajları
// useOwnerActions hook'unda. Sözleşme aynı, kaynak üç dosyanın birleşimi.
const ownerPanelSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/OwnerAssistantPanel.tsx"),
  "utf-8"
);
const publishBarSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/components/PublishBar.tsx"),
  "utf-8"
);
const ownerActionsSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerActions.ts"),
  "utf-8"
);
const panelSource = ownerPanelSource + publishBarSource + ownerActionsSource;

describe("owner-publish ucu — güvenlik sözleşmesi", () => {
  it("oturum yalnız çerezden okunur, istek gövdesinden token kabul edilmez", () => {
    expect(publishSource).toContain("cookieStore.get(OWNER_SESSION_COOKIE)");
    expect(publishSource).toContain("verifyOwnerSession(ownerSessionCookie, slug)");
    expect(publishSource).not.toContain("govde.sessionToken");
    expect(publishSource).not.toContain("govde.token");
  });

  it("service-role anahtarı kullanılmaz", () => {
    expect(publishSource).not.toContain("SERVICE_ROLE");
    expect(publishSource).not.toContain("supabaseAdmin");
  });

  it("anon istemcisiyle publish_working_draft RPC'si çağrılır", () => {
    expect(publishSource).toContain("supabaseAnon().rpc(\"publish_working_draft\"");
    expect(publishSource).toContain("p_session_token: ownerSession.sessionToken");
  });

  it("başarıda /v/:slug önbelleği revalidatePath ile tazelenir", () => {
    expect(publishSource).toContain("revalidatePath(`/v/${slug}`)");
  });

  it("oturum tokenı ve taslak içeriği loglanmaz", () => {
    expect(publishSource).not.toContain("console.log");
    expect(publishSource).toContain("console.error(\"[owner-publish] publish failed:\", error.message)");
  });
});

describe("owner-discard ucu — güvenlik sözleşmesi", () => {
  it("oturum yalnız çerezden okunur, istek gövdesinden token kabul edilmez", () => {
    expect(discardSource).toContain("cookieStore.get(OWNER_SESSION_COOKIE)");
    expect(discardSource).toContain("verifyOwnerSession(ownerSessionCookie, slug)");
    expect(discardSource).not.toContain("govde.sessionToken");
    expect(discardSource).not.toContain("govde.token");
  });

  it("service-role anahtarı kullanılmaz", () => {
    expect(discardSource).not.toContain("SERVICE_ROLE");
    expect(discardSource).not.toContain("supabaseAdmin");
  });

  it("anon istemcisiyle discard_working_draft RPC'si çağrılır", () => {
    expect(discardSource).toContain("supabaseAnon().rpc(\"discard_working_draft\"");
    expect(discardSource).toContain("p_session_token: ownerSession.sessionToken");
  });

  it("başarıda /v/:slug önbelleği revalidatePath ile tazelenir", () => {
    expect(discardSource).toContain("revalidatePath(`/v/${slug}`)");
  });

  it("oturum tokenı loglanmaz", () => {
    expect(discardSource).not.toContain("console.log");
    expect(discardSource).toContain("console.error(\"[owner-discard] discard failed:\", error.message)");
  });
});

describe("owner-accept-legal ucu — güvenlik sözleşmesi", () => {
  it("oturum yalnız çerezden okunur, istek gövdesinden token kabul edilmez", () => {
    expect(acceptLegalSource).toContain("cookieStore.get(OWNER_SESSION_COOKIE)");
    expect(acceptLegalSource).toContain("verifyOwnerSession(ownerSessionCookie, slug)");
    expect(acceptLegalSource).not.toContain("govde.sessionToken");
    expect(acceptLegalSource).not.toContain("govde.token");
  });

  it("service-role anahtarı kullanılmaz", () => {
    expect(acceptLegalSource).not.toContain("SERVICE_ROLE");
    expect(acceptLegalSource).not.toContain("supabaseAdmin");
  });

  it("anon istemcisiyle accept_store_legal_consent RPC'si çağrılır", () => {
    expect(acceptLegalSource).toContain(
      "supabaseAnon().rpc(\"accept_store_legal_consent\""
    );
    expect(acceptLegalSource).toContain("p_session_token: ownerSession.sessionToken");
  });

  it("oturum tokenı loglanmaz", () => {
    expect(acceptLegalSource).not.toContain("console.log");
    expect(acceptLegalSource).toContain(
      "console.error(\"[owner-accept-legal] accept failed:\", error.message)"
    );
  });
});

describe("panel — yayınla / vazgeç sözleşmesi", () => {
  it("iki düğme de panelin altında: Yayınla ve Değişiklikleri bırak", () => {
    expect(panelSource).toContain("/api/owner-publish");
    expect(panelSource).toContain("/api/owner-discard");
    expect(panelSource).toContain("Yayınla");
    expect(panelSource).toContain("Değişiklikleri bırak");
  });

  it("silme tek tıkla olmaz — önce onay adımı vardır", () => {
    expect(panelSource).toContain("silmeOnayi");
    expect(panelSource).toContain("Evet, sil");
    expect(panelSource).toContain("Vazgeç");
    expect(panelSource).toContain(
      "Yaptığın tüm değişiklikler silinecek ve vitrin son yayınlanan hâline dönecek. Emin misin?"
    );
  });

  it("yayınlama beklerken düğme kilitlenir ve 'Yayınlanıyor…' gösterir", () => {
    expect(panelSource).toContain("Yayınlanıyor…");
    expect(panelSource).toContain("disabled={yayinlaniyor}");
  });

  it("başarılı yayın ve silme sonrası sayfa tazelenir", () => {
    expect(panelSource).toContain(
      "Vitrinin yayınlandı. Müşterilerin artık yeni hâlini görüyor."
    );
    expect(panelSource).toContain(
      "Değişiklikler silindi. Vitrin son yayınlanan hâlinde."
    );
  });

  it("yasal onay verilmeden PublishBar yayın eylemini kilitli tutar", () => {
    expect(panelSource).toContain("/api/owner-accept-legal");
    expect(publishBarSource).toContain("yasalOnayli");
    expect(publishBarSource).toMatch(
      /disabled=\{\s*yayinlaniyor \|\| !yasalOnayli \|\|/
    );
  });

  it("masaüstünde ikinci yayın düğmesi gizlense de güvenlik kontrolleri korunur", () => {
    expect(ownerPanelSource).toContain("showPublishButton={false}");
    expect(publishBarSource).toContain("showPublishButton = true");
    expect(publishBarSource).toContain("Değişiklikleri bırak");
    expect(publishBarSource).toContain("Aydınlatma Metni");
  });
});
