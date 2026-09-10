import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const ownerChat = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerChat.ts"),
  "utf8"
);
const sharedConversation = readFileSync(
  resolve(__dirname, "../src/lib/assistantConversation.ts"),
  "utf8"
);

describe("Vixrex Assistant owner → ortak konuşma devamlılığı", () => {
  it("owner panelindeki yeni Assistant cevaplarını operasyonel message_key ile damgalar", () => {
    expect(ownerChat).toContain('const OWNER_RUNTIME_MESSAGE_KEY = "owner_runtime"');
    expect(ownerChat).toContain(
      'p_message_key: role === "assistant" ? OWNER_RUNTIME_MESSAGE_KEY : null'
    );
  });

  it("kullanıcı mesajlarını katalog damgasına zorlamaz", () => {
    expect(ownerChat).toContain('role === "assistant" ? OWNER_RUNTIME_MESSAGE_KEY : null');
  });

  it("ortak konuşma okuyucusu message_key taşıyan Assistant satırlarını gösterir", () => {
    expect(sharedConversation).toContain("if (message.role === \"user\") return true");
    expect(sharedConversation).toContain(
      "return message.message_key !== null && message.message_key !== undefined"
    );
  });
});
