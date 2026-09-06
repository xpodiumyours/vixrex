import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(__dirname, "..");
const source = readFileSync(
  resolve(ROOT, "src/app/v/[slug]/hooks/useOwnerActions.ts"),
  "utf8",
);
const panelSource = readFileSync(
  resolve(ROOT, "src/app/v/[slug]/OwnerAssistantPanel.tsx"),
  "utf8",
);
const fieldInputSource = readFileSync(
  resolve(ROOT, "src/app/v/[slug]/components/FieldInputArea.tsx"),
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

  it("bonus alanlar legacy owner-draft yerine tek authoritative command kullanır", () => {
    const block = between(
      "export async function bonusAlanlariCikarVeKaydet(",
      "export function useOwnerActions({",
    );
    expect(block).toContain("executeSmartEngineCommand({");
    expect(block).toContain("initialDraftVersion");
    expect(block).toContain("onDraftVersion(commandResult.draftVersion)");
    expect(block).toContain('payload: `geri_al:command:${commandResult.commandId}`');
    expect(block).not.toContain('fetch("/api/owner-draft"');
  });

  it("seçili rich-text ana alan + bonusları aynı authoritative command'a koyar", () => {
    const block = between(
      "if (richTextMotorEnabled) {",
      'const yanit = await fetch("/api/owner-draft"',
    );
    expect(block).toContain("executeSmartEngineCommand({");
    expect(block).toContain("initialDraftVersion: draftVersion");
    expect(block).toContain("bonusAlanlar.map");
    expect(block).toContain("setDraftVersion(commandResult.draftVersion)");
    expect(block).toContain('payload: `geri_al:command:${commandResult.commandId}`');
  });

  it("legacy owner-draft'a source smart_engine göndermez", () => {
    expect(source).not.toContain('source: "smart_engine"');
  });

  it("çalışma saatlerini bonus/rich-text generic mutation'a sokmaz", () => {
    expect(source).toContain('if (anahtar === "calismaSaatleri") return null');
    expect(source).toContain('alan.anahtar !== "calismaSaatleri"');
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

  it("landing intent bridge aynı server-loaded draft version context'ini bonus command'a verir", () => {
    expect(panelSource).toContain('useOwnerDraftVersion();');
    expect(panelSource).toContain("draftVersion,\n          setDraftVersion,");
  });

  it("GPS düğmesi 5 ayrı field write yerine tek location-bundle route'una gider", () => {
    expect(fieldInputSource).toContain('fetch("/api/owner-location-bundle"');
    expect(fieldInputSource).toContain("expectedDraftVersion: draftVersion");
    expect(fieldInputSource).toContain("setDraftVersion(body.taslakSurumu!)");
    expect(fieldInputSource).toContain("commandId = crypto.randomUUID()");
    expect(fieldInputSource).not.toContain("onClick={onGpsKonumAl}");
    expect(fieldInputSource).not.toContain('fetch("/api/owner-draft"');
    expect(fieldInputSource).not.toContain("Promise.all");
  });

  it("GPS success yalnız authoritative response sonrası lifecycle success olur", () => {
    const fetchIndex = fieldInputSource.indexOf('fetch("/api/owner-location-bundle"');
    const responseCheckIndex = fieldInputSource.indexOf("!response.ok || !body?.tamam", fetchIndex);
    const versionIndex = fieldInputSource.indexOf("setDraftVersion(body.taslakSurumu!)", responseCheckIndex);
    const successIndex = fieldInputSource.indexOf('status: "succeeded"', versionIndex);

    expect(fetchIndex).toBeGreaterThanOrEqual(0);
    expect(responseCheckIndex).toBeGreaterThan(fetchIndex);
    expect(versionIndex).toBeGreaterThan(responseCheckIndex);
    expect(successIndex).toBeGreaterThan(versionIndex);
  });
});
