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
const panelSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/OwnerAssistantPanel.tsx"),
  "utf-8"
);

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
      "Yaptığınız tüm değişiklikler silinecek ve vitrin son yayınlanan hâline dönecek. Emin misiniz?"
    );
  });

  it("yayınlama beklerken düğme kilitlenir ve 'Yayınlanıyor…' gösterir", () => {
    expect(panelSource).toContain("Yayınlanıyor…");
    expect(panelSource).toContain("disabled={yayinlaniyor}");
  });

  it("başarılı yayın ve silme sonrası sayfa tazelenir", () => {
    expect(panelSource).toContain(
      "Vitrininiz yayınlandı. Müşterileriniz artık yeni hâlini görüyor."
    );
    expect(panelSource).toContain(
      "Değişiklikler silindi. Vitrin son yayınlanan hâlinde."
    );
  });
});
