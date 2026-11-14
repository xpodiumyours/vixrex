import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "../..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const flutterDepo = oku("lib/repositories/vixrex_conversation_repository.dart");
const flutterHandoff = oku("lib/models/assistant_handoff.dart");
const webKopru = oku("public_web/src/lib/assistantConversation.ts");
const webSohbet = oku("public_web/src/app/v/[slug]/hooks/useOwnerChat.ts");

describe("anonim oturum iki istemcide de aynı konuşmayı sürdürür", () => {
  it("Flutter anonim kullanıcıyı kalıcı konuşmadan dışlamaz", () => {
    expect(flutterDepo).toContain("if (user == null) return null;");
    expect(flutterDepo).not.toContain("user.isAnonymous");
  });

  it("web köprüsü ve sahip sohbeti anonim oturumu dışlamaz", () => {
    expect(webKopru).not.toContain("is_anonymous");
    expect(webSohbet).not.toContain("is_anonymous");
  });

  it("iki istemci de aynı konuşma RPC'lerini kullanır", () => {
    for (const rpc of ["get_assistant_conversation", "append_assistant_message"]) {
      expect(flutterDepo).toContain(rpc);
      expect(webKopru).toContain(rpc);
    }
  });

  it("handoff mesaj bütçesi iki uçta da son 24'ü korur", () => {
    expect(flutterHandoff).toContain("normalized.length <= 24");
    expect(flutterHandoff).toContain("sublist(normalized.length - 24)");
    expect(flutterHandoff).toContain("removeAt(0)");
    expect(flutterHandoff).not.toContain("sublist(0, 24)");
  });

  it("yerel ve uzak geçmiş aynı kimlikle birleşir — çift balon üretmez", () => {
    const servis = oku("lib/services/chatbot_service.dart");

    expect(servis).toContain("'flutter-${message.id}'");
    expect(servis).toContain("!remoteIds.contains(paylasilanKimlik)");
  });
});
