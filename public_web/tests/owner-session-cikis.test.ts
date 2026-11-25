import { describe, expect, it, vi } from "vitest";

vi.mock("@/lib/supabase", () => ({ supabase: { rpc: vi.fn() } }));

import { DELETE } from "../src/app/api/owner-session/route";
import { OWNER_SESSION_COOKIE } from "../src/lib/ownerSession";

describe("çıkışta sahip önizleme çerezi", () => {
  it("DELETE boş değer ve Max-Age=0 ile çerezi siler, önbelleği kapatır", async () => {
    const response = await DELETE();
    const setCookie = response.headers.get("set-cookie") ?? "";

    expect(response.status).toBe(200);
    expect(setCookie).toContain(`${OWNER_SESSION_COOKIE}=`);
    expect(setCookie).toMatch(/Max-Age=0/i);
    expect(setCookie).toContain("Path=/");
    expect(setCookie).toContain("HttpOnly");
    expect(response.headers.get("cache-control")).toBe("no-store");
  });
});
