import { describe, expect, it } from "vitest";
import { ensureVixrexNluSession } from "@/lib/vixrexNluPipeline";

describe("ensureVixrexNluSession — auth kesintisi akıllı motoru kapatmaz", () => {
  it("oturum hazırlanırsa true döner", async () => {
    await expect(ensureVixrexNluSession(async () => true)).resolves.toBe(true);
  });

  it("oturum hazırlanamazsa false döner", async () => {
    await expect(ensureVixrexNluSession(async () => false)).resolves.toBe(false);
  });

  it("auth/ağ çağrısı hata fırlatsa bile dışarı hata taşımaz", async () => {
    await expect(
      ensureVixrexNluSession(async () => {
        throw new Error("network down");
      }),
    ).resolves.toBe(false);
  });
});
