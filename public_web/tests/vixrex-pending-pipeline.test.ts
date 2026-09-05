import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  rpc: vi.fn(async () => ({ data: null, error: null })),
}));

vi.mock("../src/lib/supabase", () => ({
  supabase: { rpc: mocks.rpc },
}));

import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

function pendingWrite() {
  return mocks.rpc.mock.calls.find(
    ([name]) => name === "set_assistant_pending_slot",
  );
}

describe("Vixrex pending pipeline v1 — Next.js", () => {
  beforeEach(() => {
    mocks.rpc.mockClear();
  });

  it("değer eksikse missing_value envelope yazar", async () => {
    const result = await handleVixrexNluMessage("Telefonu değiştir");

    expect(result.decision).toBe("needs_clarification");
    const call = pendingWrite();
    expect(call).toBeDefined();
    expect(call?.[1]).toMatchObject({
      p_slot: {
        schemaVersion: 1,
        domain: "storefront",
        kind: "missing_value",
        fieldKey: "telefon",
        anahtar: "telefon",
      },
    });
  });

  it("il/ilçe özel akışını special_flow envelope olarak yazar", async () => {
    const result = await handleVixrexNluMessage("İl İstanbul olsun");

    expect(result.decision).toBe("needs_special_flow");
    const call = pendingWrite();
    expect(call).toBeDefined();
    expect(call?.[1]).toMatchObject({
      p_slot: {
        schemaVersion: 1,
        domain: "storefront",
        kind: "special_flow",
        fieldKey: "il",
        anahtar: "il",
      },
    });
  });
});
