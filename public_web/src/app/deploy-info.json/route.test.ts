import { afterEach, describe, expect, it } from "vitest";
import { GET } from "./route";

describe("GET /deploy-info.json", () => {
  const originalCommit = process.env.VERCEL_GIT_COMMIT_SHA;
  const originalDsn = process.env.NEXT_PUBLIC_SENTRY_DSN;
  const originalVercelEnv = process.env.VERCEL_ENV;

  afterEach(() => {
    process.env.VERCEL_GIT_COMMIT_SHA = originalCommit;
    process.env.NEXT_PUBLIC_SENTRY_DSN = originalDsn;
    process.env.VERCEL_ENV = originalVercelEnv;
  });

  it("commit sha ve sentry bilgisi yoksa guvenli varsayimlar doner", async () => {
    delete process.env.VERCEL_GIT_COMMIT_SHA;
    delete process.env.NEXT_PUBLIC_SENTRY_DSN;
    delete process.env.VERCEL_ENV;

    const response = GET();
    const body = await response.json();

    expect(body.commit).toBe("unknown");
    expect(body.sentryConfigured).toBe(false);
    expect(body.sentryRelease).toBeNull();
    expect(body.sentryEnvironment).toBe("development");
  });

  it("vercel ortam degiskenleri varken canli deploy bilgisini yansitir", async () => {
    process.env.VERCEL_GIT_COMMIT_SHA = "abc123";
    process.env.NEXT_PUBLIC_SENTRY_DSN = "https://example.test/1";
    process.env.VERCEL_ENV = "production";

    const response = GET();

    expect(response.headers.get("Cache-Control")).toBe(
      "no-store, max-age=0, must-revalidate"
    );

    const body = await response.json();
    expect(body.commit).toBe("abc123");
    expect(body.sentryConfigured).toBe(true);
    expect(body.sentryRelease).toBe("vixrex-public@abc123");
    expect(body.sentryEnvironment).toBe("production");
  });

  it("her cagride ayni build zaman damgasini dondurur", async () => {
    const first = await GET().json();
    const second = await GET().json();

    expect(first.builtAt).toBe(second.builtAt);
  });
});
