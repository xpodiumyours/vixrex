import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(__dirname, "..");
const source = readFileSync(
  resolve(ROOT, "src/app/v/[slug]/hooks/useFieldRestore.ts"),
  "utf8",
);

describe("useFieldRestore smart-engine Undo wiring", () => {
  it("command token authoritative receipt Undo'ya gider", () => {
    expect(source).toContain('anahtarlar[0]?.startsWith("command:")');
    expect(source).toContain("undoSmartEngineCommand({");
    expect(source).toContain("commandId: commandToken");
    expect(source).toContain("setDraftVersion(sonuc.draftVersion)");
  });

  it("manual tek alan canlıya dön davranışı ayrı kalır", () => {
    expect(source).toContain('fetch("/api/owner-draft-restore"');
    expect(source).toContain("const canliyaDondur = useCallback");
  });

  it("authoritative Undo client alan listesi üretmez", () => {
    const commandStart = source.indexOf("if (commandToken) {");
    const legacyStart = source.indexOf("const alanlar = anahtarlar", commandStart);
    expect(commandStart).toBeGreaterThanOrEqual(0);
    expect(legacyStart).toBeGreaterThan(commandStart);
    const commandBlock = source.slice(commandStart, legacyStart);
    expect(commandBlock).not.toContain("FIELD_BY_KEY");
    expect(commandBlock).not.toContain("owner-draft-restore");
  });
});
