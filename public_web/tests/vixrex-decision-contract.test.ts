import { describe, expect, it, vi } from "vitest";

vi.mock("../src/lib/supabase", () => ({
  supabase: {
    rpc: vi.fn(async () => ({ data: null, error: null })),
  },
}));

import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

describe("Vixrex 5.3 pure decision contract — Next.js", () => {
  it("tek alan typed action üretir, persistence başarısı iddia etmez", async () => {
    const result = await handleVixrexNluMessage(
      "Telefonu 0212 123 45 67 yap",
    );

    expect(result.decision).toBe("validated_action");
    expect(result.actions).toHaveLength(1);
    expect(result.actions[0]).toMatchObject({
      contractVersion: 1,
      domain: "storefront",
      actionType: "set_field",
      fieldKey: "telefon",
    });
    expect(result.message).not.toContain("Kaydettim");
  });

  it("iki bağımsız alan tek canonical action grubu üretir", async () => {
    const result = await handleVixrexNluMessage(
      "Telefonu 0212 123 45 67 yap, Instagramı aymira yap",
    );

    expect(result.decision).toBe("validated_action_group");
    expect(result.actions.map((action) => action.fieldKey)).toEqual([
      "telefon",
      "instagram",
    ]);
    expect(result.message).not.toContain("Kaydettim");
  });

  it("günsüz çalışma saati cümlesini generic mutation yapmaz", async () => {
    const result = await handleVixrexNluMessage(
      "Çalışma saatlerini 09:00-18:00 yap",
    );

    expect(result.decision).toBe("needs_special_flow");
    expect(result.actions).toEqual([]);
    expect(result.anahtar).toBe("calismaSaatleri");
    expect(result.message).toContain("Hangi günler");
    expect(result.message).not.toContain("Kaydettim");
  });
});
