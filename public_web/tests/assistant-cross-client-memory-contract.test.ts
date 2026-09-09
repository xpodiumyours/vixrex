import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

function read(path: string): string {
  return readFileSync(resolve(__dirname, "../..", path), "utf8");
}

describe("Vixrex Assistant Flutter ↔ Next.js pending hafıza sözleşmesi", () => {
  it("Flutter repository Next.js ile aynı pending-slot RPC'lerini kullanır", () => {
    const dartRepo = read("lib/repositories/vixrex_conversation_repository.dart");
    const nextPipeline = read("public_web/src/lib/vixrexNluPipeline.ts");

    for (const rpc of ["get_assistant_pending_slot", "set_assistant_pending_slot"]) {
      expect(dartRepo).toContain(rpc);
      expect(nextPipeline).toContain(rpc);
    }
  });

  it("Flutter kalıcı hesapta Supabase'i kanonik, SharedPreferences'i cache/fallback tutar", () => {
    const memory = read("lib/services/vixrex_nlu/vixrex_conversation_memory.dart");
    expect(memory).toContain("_conversationRepository.canSync");
    expect(memory).toContain("loadPendingSlot()");
    expect(memory).toContain("savePendingSlot(slot.toJson())");
    expect(memory).toContain("savePendingSlot(null)");
    expect(memory).toContain("SharedPreferences.getInstance()");
  });

  it("Flutter ve Next niyet resolver'ları başlangıç + örtüşme güvenlik sınırını birlikte taşır", () => {
    const dartResolver = read("lib/services/vixrex_nlu/vixrex_intent_resolver.dart");
    const nextResolver = read("public_web/src/lib/vixrexIntentResolver.ts");
    expect(dartResolver).toContain("_niyetEslesmesiBul");
    expect(nextResolver).toContain("niyetEslesmesiBul");
    expect(dartResolver).toContain("doluAraliklar");
    expect(nextResolver).toContain("doluAraliklar");
  });

  it("Flutter ve Next pipeline aç/kapat doğal komutunu tip katmanında işler", () => {
    const dartPipeline = read("lib/services/vixrex_nlu/vixrex_nlu_pipeline.dart");
    const nextPipeline = read("public_web/src/lib/vixrexNluPipeline.ts");
    expect(dartPipeline).toContain("_extractPipelineValue");
    expect(nextPipeline).toContain("extractPipelineValue");
    for (const token of ["goster", "gizle", "kapat"]) {
      expect(dartPipeline).toContain(`'${token}'`);
      expect(nextPipeline).toContain(`"${token}"`);
    }
  });
});
