import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(__dirname, "..");
const read = (path: string) => readFileSync(resolve(ROOT, path), "utf8");

const shell = read("src/app/v/[slug]/OwnerWorkspaceShell.tsx");
const context = read("src/app/v/[slug]/OwnerDraftVersionContext.tsx");

describe("Owner authoritative draft version source", () => {
  it("draft_data ile aynı server snapshot'taki draft_version'ı provider'a verir", () => {
    expect(shell).toContain('import { OwnerDraftVersionProvider } from "./OwnerDraftVersionContext"');
    expect(shell).toContain("<OwnerDraftVersionProvider initialVersion={draft?.draft_version ?? 1}>");
    expect(shell).toContain("draftData={(draft?.draft_data ?? {}) as Record<string, unknown>}");
  });

  it("provider router refresh ile gelen yeni server version'a render sırasında eşitlenir", () => {
    expect(context).toContain("if (initialVersion !== lastInitialVersion)");
    expect(context).toContain("setDraftVersion(initialVersion)");
  });

  it("expected version için ayrı latest-version endpoint'i veya fetch kullanmaz", () => {
    expect(context).not.toContain("fetch(");
    expect(shell).not.toContain("owner-draft-version");
  });
});
