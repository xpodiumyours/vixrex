import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  handoffAdimDevami,
  ownerChatInitialMessages,
  parseAssistantHandoff,
} from "@/lib/assistantHandoff";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const rapor: HazirlikRaporu = {
  temelTamam: false,
  yuzde: 40,
  doluSayisi: 4,
  toplamSayisi: 10,
  eksikler: [],
  sonrakiAdim: "Hakkımızda metni eklerseniz vitriniz daha güçlü görünür.",
};

const DUZENLEME_ISTEGI =
  "Değiştirmek istediğin yazıya vitrinde tıkla — buradan düzenleriz.";

describe("yarım kalan kurulum adımı sahip sohbetine taşınır", () => {
  it("akış adımı handoff diline çevrilir", () => {
    expect(handoffAdimDevami("location")).toContain("Konum bilgisi");
    expect(handoffAdimDevami("address")).toBe(handoffAdimDevami("location"));
    expect(handoffAdimDevami("publish")).toContain("Yayınlama");
    expect(handoffAdimDevami("share")).toBeNull();
    expect(handoffAdimDevami("bilinmeyen-adim")).toBeNull();
    expect(handoffAdimDevami(null)).toBeNull();
  });

  it("handoff yokken devam cümlesi selamlamanın ardına eklenir", () => {
    const mesajlar = ownerChatInitialMessages(rapor, null, "legal");
    const metinler = mesajlar.map((mesaj) => mesaj.metin);

    expect(metinler[0]).toContain("%40");
    expect(metinler).toContain(
      "Yasal onay adımından kaldığımız yerden devam edelim."
    );
    expect(metinler.at(-1)).toBe(DUZENLEME_ISTEGI);
  });

  it("panel flow_state bootstrap yapmaz (altyapı yok)", () => {
    const panel = oku("src/app/v/[slug]/OwnerAssistantPanel.tsx");
    expect(panel).not.toContain("get_owner_workspace_bootstrap");
  });

  it("gerçek handoff varken adım devamı ikinci kez eklenmez", () => {
    const handoff = parseAssistantHandoff({
      version: 1,
      completed_steps: ["name"],
      next_step: "category",
      messages: [
        { role: "assistant", text: "İşletme adını yazalım." },
        { role: "user", text: "Ada Kahve" },
      ],
    });

    const metinler = ownerChatInitialMessages(rapor, handoff, "legal").map(
      (mesaj) => mesaj.metin
    );

    expect(metinler).not.toContain(
      "Yasal onay adımından kaldığımız yerden devam edelim."
    );
    expect(metinler.at(-1)).toBe(DUZENLEME_ISTEGI);
  });
});

describe("sahip sohbeti 15 saniyede bir tazelenir", () => {
  const kaynak = oku("src/app/v/[slug]/hooks/useOwnerChat.ts");

  it("nabız aralığı Flutter'daki zamanlayıcıyla aynı", () => {
    expect(kaynak).toContain("}, 15_000);");
    expect(kaynak).toContain("window.clearInterval(pollId)");
  });

  it("sekme görünür değilken ağ trafiği üretmez", () => {
    expect(kaynak).toContain('document.visibilityState === "visible"');
  });

  it("tam içerik karşılaştırması yapar — düzeltme ve silme de yansır", () => {
    expect(kaynak).toContain("mapped.every(");
    expect(kaynak).not.toContain("mapped.length > prev.length");
  });

  it("sunucudan gelen geçmiş başka bir konuşmayla ezilmez", () => {
    expect(kaynak).toContain("conv.id !== initialConversationId");
  });

  it("tazeleme 'kaldığın yerden' cümlesini silmez", () => {
    expect(kaynak).toContain("handoff ? null : handoffAdimDevami(akisAdimi)");
    expect(kaynak).toContain("devamiKoru(");
  });
});

describe("ilk boyama sunucudaki konuşmayla açılır", () => {
  it("sahip sayfası konuşmayı yalnız sahip modunda okur", () => {
    const sayfa = oku("src/app/v/[slug]/page.tsx");

    expect(sayfa).toContain("loadAssistantMessagesForStore(params.slug");
    expect(sayfa).toMatch(/isOwnerMode && draft[\s\S]*?assistantHistory/);
    expect(sayfa).toContain(
      "initialAssistantMessages={assistantHistory.messages}"
    );
    expect(sayfa).toContain(
      "initialAssistantConversationId={assistantHistory.conversationId}"
    );
  });

  it("konuşma okuması RLS'i atlatan yönetici istemcisiyle ve dar kapsamda", () => {
    const sunucu = oku("src/lib/assistantConversationServer.ts");

    expect(sunucu).toContain('import "server-only"');
    expect(sunucu).toContain('.from("stores")');
    expect(sunucu).toContain("if (!userId) return BOS;");
    expect(sunucu).toContain('.eq("user_id", userId)');
    expect(sunucu).toContain('.order("seq", { ascending: false })');
    expect(sunucu).toContain(".limit(500)");
  });

  it("kabuk ve panel sunucu geçmişini sohbete aktarır", () => {
    const kabuk = oku("src/app/v/[slug]/OwnerWorkspaceShell.tsx");
    const panel = oku("src/app/v/[slug]/OwnerAssistantPanel.tsx");

    expect(kabuk).toContain(
      "initialDbMessages={initialAssistantMessages ?? null}"
    );
    expect(kabuk).toContain(
      "initialConversationId={initialAssistantConversationId ?? null}"
    );
    expect(panel).toContain("initialDbMessages: initialDbMessages ?? undefined");
    expect(panel).toContain(
      "initialConversationId: initialConversationId ?? undefined"
    );
  });
});
