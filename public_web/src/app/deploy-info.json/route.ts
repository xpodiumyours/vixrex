import { NextResponse } from "next/server";

const builtAt = new Date().toISOString();

export function GET() {
  const commit = process.env.VERCEL_GIT_COMMIT_SHA || "unknown";
  const sentryConfigured = Boolean(process.env.NEXT_PUBLIC_SENTRY_DSN);
  const sentryEnvironment = process.env.VERCEL_ENV || "development";

  return NextResponse.json(
    {
      commit,
      builtAt,
      sentryConfigured,
      sentryRelease: sentryConfigured ? `vixrex-public@${commit}` : null,
      sentryEnvironment,
    },
    {
      headers: {
        "Cache-Control": "no-store, max-age=0, must-revalidate",
      },
    }
  );
}
