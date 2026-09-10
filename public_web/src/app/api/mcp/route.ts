// Claude remote MCP giriş noktası.
// OAuth kimliği ve Vixrex kullanıcı yetkilendirmesi tamamlanmadan hiçbir
// tool veya Supabase veri erişimi açılmaz. Bu dosya bilerek fail-closed'tur.

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const MCP_CLOSED_BODY = JSON.stringify({
  error: "MCP_NOT_READY",
  reason: "OAUTH_REQUIRED_BEFORE_TOOL_EXPOSURE",
});

function mcpClosedResponse(): Response {
  return new Response(MCP_CLOSED_BODY, {
    status: 503,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      Allow: "GET, POST, DELETE",
    },
  });
}

export async function GET(): Promise<Response> {
  return mcpClosedResponse();
}

export async function POST(): Promise<Response> {
  return mcpClosedResponse();
}

export async function DELETE(): Promise<Response> {
  return mcpClosedResponse();
}
