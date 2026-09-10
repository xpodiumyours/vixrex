import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const route = readFileSync(
  resolve(__dirname, "../src/app/api/mcp/route.ts"),
  "utf8"
);
const control = readFileSync(
  resolve(__dirname, "../src/lib/mcp/control.ts"),
  "utf8"
);

describe("Claude MCP giriş noktası — OAuth öncesi güvenlik kontratı", () => {
  it("Streamable HTTP yüzeyi için GET, POST ve DELETE metodlarını ayırır", () => {
    expect(route).toContain("export async function GET");
    expect(route).toContain("export async function POST");
    expect(route).toContain("export async function DELETE");
  });

  it("fail-closed hatasını tek düzenlenebilir kaynaktan alır", () => {
    expect(route).toContain('import { MCP_ERRORS } from "@/lib/mcp/control"');
    expect(route).toContain("MCP_ERRORS.notReady");
    expect(route).not.toContain("MCP_NOT_READY");
    expect(route).not.toContain("OAUTH_REQUIRED_BEFORE_TOOL_EXPOSURE");
    expect(control).toContain('code: "MCP_NOT_READY"');
    expect(control).toContain('reason: "OAUTH_REQUIRED_BEFORE_TOOL_EXPOSURE"');
    expect(control).toContain("status: 503");
  });

  it("MCP çalışmasını açık güvenli alanlarla sınırlar", () => {
    expect(control).toContain('"public_web/src/app/api/mcp/"');
    expect(control).toContain('"public_web/src/lib/mcp/"');
    expect(control).toContain('"public_web/tests/mcp-"');
    expect(control).toContain("approvalRequired");
    expect(control).toContain('"supabase/"');
    expect(control).toContain('"shared/"');
    expect(control).toContain('"lib/"');
    expect(control).toContain('"public_web/src/app/api/owner-"');
    expect(control).toContain('"public_web/src/lib/vitrinFieldSchema.ts"');
    expect(control).toContain('prohibitedTargets: ["main", "production-supabase"]');
  });

  it("kapalı giriş noktası Supabase veya Vixrex yazma yüzeyine erişmez", () => {
    expect(route).not.toMatch(/@supabase|createClient|service_role|SERVICE_ROLE/i);
    expect(route).not.toMatch(/\.from\(|\.rpc\(|update_owned_working_draft_fields/);
    expect(route).not.toMatch(/get_my_store|update_my_store_fields|publish_my_store/);
  });

  it("istemciden user_id veya store_id alarak sahiplik seçmez", () => {
    expect(route).not.toMatch(/user_id|store_id/);
    expect(route).not.toMatch(/request\.json|req\.json/);
  });

  it("yeni MCP üretim koduna yorum satırı eklenmez", () => {
    expect(route).not.toMatch(/^\s*\/\//m);
    expect(control).not.toMatch(/^\s*\/\//m);
  });
});
