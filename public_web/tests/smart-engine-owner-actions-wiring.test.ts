import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(__dirname, "..");
const source = readFileSync(
  resolve(ROOT, "src/app/v/[slug]/hooks/useOwnerActions.ts"),
  "utf8",
);

function between(start: string, end: string): string {
  const from = source.indexOf(start);
  const to = source.indexOf(end, from + start.length);
  expect(from).toBeGreaterThanOrEqual(0);
  expect(to).toBeGreaterThan(from);
  return source.slice(from, to);
}

describe("useOwnerActions authoritative smart-engine wiring", () => {
  it("serbest metin çok-alanlı yolu command orchestrator + server-snapshot version kullanır", () => {
    const block = between(
      "const commandResult = await executeSmartEngineCommand({",
      "const alan = seciliAlan;",
    );

    expect(block).toContain("initialDraftVersion: draftVersion");
    expect(block).toContain("setDraftVersion(commandResult.draftVersion)");
    expect(block).toContain("commandResult.succeeded");
    expect(block).toContain("commandResult.failed");
    expect(block).toContain("commandResult.stopped");
    expect(block).not.toContain('fetch("/api/owner-draft"');
  });

  it("yeni onay kartı field listesi değil command receipt undo taşır", () => {
    expect(source).toContain('payload: `geri_al:command:${commandResult.commandId}`');
  });

  it("manuel seçili alan yolu mevcut owner-draft kanalında kalır", () => {
    const selectedBlock = between(
      "const alan = seciliAlan;",
      "// Yalnız isteğe bağlı alanlarda gösterilen",
    );
    expect(selectedBlock).toContain('fetch("/api/owner-draft"');
  });
});
