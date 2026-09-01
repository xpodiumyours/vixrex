import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const root = resolve(process.cwd(), "..");
const read = (path: string) => readFileSync(resolve(root, path), "utf8");

describe("Flutter ve Next.js tek Vixrex konuşmasını paylaşır", () => {
  it("iki istemci aynı konuşma RPC'lerini kullanır", () => {
    const nextAdapter = read("public_web/src/lib/assistantConversation.ts");
    const flutterAdapter = read(
      "lib/repositories/vixrex_conversation_repository.dart",
    );

    for (const rpc of ["get_assistant_conversation", "append_assistant_message"]) {
      expect(nextAdapter).toContain(rpc);
      expect(flutterAdapter).toContain(rpc);
    }
  });

  it("Keşfet Vixrex düğmesi landing'e gitmez, paneli açar", () => {
    const sidebar = read("public_web/src/components/kesfet/KesfetYanMenu.tsx");
    const explore = read("public_web/src/components/kesfet/KesfetIcerik.tsx");

    expect(sidebar).not.toContain('/#vixrex-hero');
    expect(sidebar).toContain("onClick={vixrexAc}");
    expect(explore).toContain("<SharedVixrexAssistant");
  });

  it("Flutter yerel geçmişi yalnız önbellek olarak tutup uzak geçmişle birleştirir", () => {
    const service = read("lib/services/chatbot_service.dart");

    expect(service).toContain("VixrexConversationRepository");
    expect(service).toContain("loadMessages()");
    expect(service).toContain("syncMessages(local)");
  });

  it("veritabanında kullanıcı başına tek ve idempotent konuşma sağlar", () => {
    const migration = read(
      "supabase/migrations/20260901003000_ensure_single_assistant_conversation.sql",
    );

    expect(migration).toContain("ensure_assistant_conversation");
    expect(migration).toContain("get_assistant_conversation");
    expect(migration).toContain("where user_id = v_user_id");
    expect(migration).toContain("limit 500");
  });
});
