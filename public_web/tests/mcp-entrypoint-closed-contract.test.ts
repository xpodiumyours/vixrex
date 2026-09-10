import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const route = readFileSync(
  resolve(__dirname, "../src/app/api/mcp/route.ts"),
  "utf8"
);

describe("Claude MCP giriş noktası — OAuth öncesi güvenlik kontratı", () => {
  it("Streamable HTTP yüzeyi için GET, POST ve DELETE metodlarını ayırır", () => {
    expect(route).toContain("export async function GET");
    expect(route).toContain("export async function POST");
    expect(route).toContain("export async function DELETE");
  });

  it("OAuth ve tool yüzeyi hazır olmadan fail-closed kalır", () => {
    expect(route).toContain('error: "MCP_NOT_READY"');
    expect(route).toContain('reason: "OAUTH_REQUIRED_BEFORE_TOOL_EXPOSURE"');
    expect(route).toContain("status: 503");
    expect(route).toContain('"Cache-Control": "no-store"');
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
});
