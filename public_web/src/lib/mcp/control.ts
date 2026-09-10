export const MCP_WORK_AREAS = {
  editableNow: [
    "public_web/src/app/api/mcp/",
    "public_web/src/lib/mcp/",
    "public_web/tests/mcp-",
  ],
  approvalRequired: [
    "public_web/package.json",
    "public_web/package-lock.json",
    "public_web/src/app/api/owner-",
    "public_web/src/lib/vitrinFieldSchema.ts",
    "supabase/",
    "shared/",
    "lib/",
    ".github/",
    "CLAUDE.md",
  ],
  prohibitedTargets: ["main", "production-supabase"],
} as const;

export const MCP_ERRORS = {
  notReady: {
    code: "MCP_NOT_READY",
    reason: "OAUTH_REQUIRED_BEFORE_TOOL_EXPOSURE",
    status: 503,
  },
} as const;

export type McpErrorKey = keyof typeof MCP_ERRORS;
