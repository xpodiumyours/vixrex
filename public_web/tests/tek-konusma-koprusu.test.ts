import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Tek konuşma köprüsü (UI/UX cilası devamı, 2026-09-02) — landing'in
 * niyet akışı artık `assistant_conversations`'a yazıyor; sahip paneli ve
 * Keşfet'in Vixrex sekmesi (SharedVixrexAssistant) aynı auth.uid() ile
 * aynı konuşmayı devralıyor. Anonim Supabase Auth oturumu (signInAnonymously)
 * köprüyü kurar, Google linkIdentity() aynı uid'i koruduğu için konuşma
 * hesap bağlanınca da kaybolmaz.
 */
describe("assistantConversation.ts — anonim oturum artık dışlanmıyor", () => {
  const kaynak = oku("lib/assistantConversation.ts");

  it("loadSharedAssistantContext yalnız oturum yokluğuna bakar, is_anonymous'a değil", () => {
    expect(kaynak).toContain("if (!session) {");
    expect(kaynak).not.toContain("session.user.is_anonymous");
  });

  it("ensureAnonymousSession dışa açık — oturum yoksa signInAnonymously çağırır", () => {
    expect(kaynak).toContain("export async function ensureAnonymousSession");
    expect(kaynak).toContain("supabase.auth.signInAnonymously()");
  });

  it("landing'in kendi metinleriyle ham mesaj yazabileceği bir yol var", () => {
    expect(kaynak).toContain("export async function appendRawSharedAssistantMessage");
    expect(kaynak).toContain("export { ensureConversation as ensureSharedAssistantConversation };");
  });
});

describe("useOwnerChat.ts — anonim oturum artık dışlanmıyor", () => {
  const kaynak = oku("app/v/[slug]/hooks/useOwnerChat.ts");

  it("fetchAndSync ve lazy-resolve is_anonymous kontrolü kaldırıldı", () => {
    expect(kaynak).not.toContain("is_anonymous");
  });
});

describe("Landing — niyet akışı konuşma köprüsünü kurar", () => {
  const kaynak = oku("components/landing/LandingAsistanSohbeti.tsx");

  it("Hazır Vitrin Seç tıklanınca niyet sorusu DB'ye yazılır", () => {
    expect(kaynak).toContain("void niyetSohbetiKaydet([");
    expect(kaynak).toContain("NIYET_KATEGORI_SORUSU");
  });

  it("kategori seçilince kullanıcı + asistan mesajı yazılır, yönlendirme engellenmez", () => {
    const idxKaydet = kaynak.indexOf("void niyetSohbetiKaydet([", kaynak.indexOf("KategoriGrid"));
    const idxPush = kaynak.indexOf("router.push(hedef);");
    expect(idxKaydet).toBeGreaterThan(-1);
    expect(idxPush).toBeGreaterThan(idxKaydet); // yazma navigasyonu bloklamıyor, önce tetiklenip sonra push ediliyor
  });

  it("hata sessizce yutulur — akış hiçbir zaman bloklanmaz", () => {
    expect(kaynak).toContain("Konuşma köprüsü opsiyonel bir zenginleştirme — akışı hiç bloklamaz.");
  });

  it("Sıfırdan Oluştur / Bakınıyorum dallarında konuşma köprüsü tetiklenmez", () => {
    const sifirdanBlok = kaynak.slice(
      kaynak.indexOf('setGirdi(\'\'); setAdim(0);'),
      kaynak.indexOf("</div>", kaynak.indexOf('setGirdi(\'\'); setAdim(0);'))
    );
    expect(sifirdanBlok).not.toContain("niyetSohbetiKaydet");
  });
});
