import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";

const { rpcMock } = vi.hoisted(() => ({ rpcMock: vi.fn() }));
vi.mock("../src/lib/supabase", () => ({ supabase: { rpc: rpcMock } }));

import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

type Senaryo = {
  anahtar: string;
  cumle: string;
  deger?: string | number | boolean | null;
  outcome: "handled" | "needsSpecialFlow";
};

const fixture = JSON.parse(
  readFileSync(
    resolve(__dirname, "../../shared/vixrex_esnaf_dili_kabul.json"),
    "utf8",
  ),
) as { senaryolar: Senaryo[] };

describe("Araştırma temelli esnaf dili — Next.js gerçek pipeline", () => {
  beforeEach(() => {
    rpcMock.mockReset();
    rpcMock.mockImplementation(async (name: string, params?: unknown) => {
      if (name === "get_assistant_pending_slot") return { data: null, error: null };
      if (name === "set_assistant_pending_slot") return { data: params ?? null, error: null };
      return { data: null, error: null };
    });
  });

  it("ortak kabul kümesi 46 alanın tamamını kapsar", () => {
    expect(fixture.senaryolar).toHaveLength(46);
    expect(new Set(fixture.senaryolar.map((s) => s.anahtar)).size).toBe(46);
  });

  for (const s of fixture.senaryolar) {
    it(`${s.anahtar}: ${s.cumle}`, async () => {
      const sonuc = await handleVixrexNluMessage(s.cumle);
      expect(sonuc.outcome).toBe(s.outcome);
      expect(sonuc.anahtar).toBe(s.anahtar);
      if (s.outcome === "handled") {
        expect(sonuc.deger).toEqual(s.deger);
        expect(sonuc.tumu).toEqual([
          expect.objectContaining({ anahtar: s.anahtar, deger: s.deger }),
        ]);
      } else {
        expect(sonuc.tumu).toBeUndefined();
      }
    });
  }
});
