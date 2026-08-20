import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  from: vi.fn(),
  isSupabaseConfigured: vi.fn(),
  paytrEnv: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    from: mocks.from,
  },
  isSupabaseConfigured: mocks.isSupabaseConfigured,
}));

vi.mock("@/lib/paytr", () => ({
  paytrEnv: mocks.paytrEnv,
}));

import { GET } from "@/app/api/health/route";

function databaseQuery(error: { message: string } | null = null) {
  const abortSignal = vi.fn().mockResolvedValue({ data: [], error });
  const limit = vi.fn(() => ({ abortSignal }));
  const select = vi.fn(() => ({ limit }));
  mocks.from.mockReturnValue({ select });
  return { select, limit, abortSignal };
}

describe("GET /api/health", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.isSupabaseConfigured.mockReturnValue(true);
    mocks.paytrEnv.mockReturnValue({
      merchantId: "secret-id",
      merchantKey: "secret-key",
      merchantSalt: "secret-salt",
      merchantPass: "secret-pass",
    });
    databaseQuery();
  });

  it("çekirdek bağımlılıklar hazırsa 200 döner", async () => {
    const response = await GET();
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(body).toEqual({
      status: "ok",
      checkedAt: expect.any(String),
      checks: {
        application: { status: "ok" },
        database: { status: "ok" },
        paytr: { status: "configured" },
      },
    });
    expect(mocks.from).toHaveBeenCalledWith("stores");
    expect(JSON.stringify(body)).not.toContain("secret-");
  });

  it("Supabase ayarı eksikse ağ çağrısı yapmadan 503 döner", async () => {
    mocks.isSupabaseConfigured.mockReturnValue(false);

    const response = await GET();
    const body = await response.json();

    expect(response.status).toBe(503);
    expect(body.status).toBe("unhealthy");
    expect(body.checks.database).toEqual({ status: "error" });
    expect(mocks.from).not.toHaveBeenCalled();
  });

  it("veritabanı hatasını dışarı sızdırmadan 503 döner", async () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    databaseQuery({ message: "internal database detail" });

    const response = await GET();
    const body = await response.json();

    expect(response.status).toBe(503);
    expect(body.checks.database).toEqual({ status: "error" });
    expect(JSON.stringify(body)).not.toContain("internal database detail");
    expect(errorSpy).toHaveBeenCalledWith("[health] database check failed");
    errorSpy.mockRestore();
  });

  it("PayTR yapılandırılmamışsa 503 döner", async () => {
    mocks.paytrEnv.mockReturnValue(null);

    const response = await GET();
    const body = await response.json();

    expect(response.status).toBe(503);
    expect(body.status).toBe("unhealthy");
    expect(body.checks.paytr).toEqual({ status: "unconfigured" });
  });
});
