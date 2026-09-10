import { MCP_ERRORS } from "@/lib/mcp/control";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

function mcpClosedResponse(): Response {
  const error = MCP_ERRORS.notReady;

  return new Response(
    JSON.stringify({
      error: error.code,
      reason: error.reason,
    }),
    {
      status: error.status,
      headers: {
        "Cache-Control": "no-store",
        "Content-Type": "application/json; charset=utf-8",
        Allow: "GET, POST, DELETE",
      },
    }
  );
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
