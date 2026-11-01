import { createHash } from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import { describe, expect, it, vi } from "vitest";
import { ownerSessionStillActive } from "@/lib/ownerSessionValidity";

const session = {
  storeId: "11111111-1111-4111-8111-111111111111",
  slug: "esnaf",
  sessionToken: "a".repeat(64),
};

function fakeAdmin(data: unknown, error: unknown = null) {
  const query: Record<string, ReturnType<typeof vi.fn>> = {};
  for (const name of ["select", "eq", "not", "gt"]) {
    query[name] = vi.fn(() => query);
  }
  query.maybeSingle = vi.fn(async () => ({ data, error }));
  const from = vi.fn(() => query);
  return { admin: { from } as unknown as SupabaseClient, query, from };
}

describe("#611: imzalı sahip oturumunun DB geçerliliği", () => {
  it("geçerli, tüketilmiş, süresi dolmamış kayda izin verir; tokenın sadece hashini arar", async () => {
    const { admin, from, query } = fakeAdmin({ store_id: session.storeId });
    expect(await ownerSessionStillActive(admin, session)).toBe(true);
    expect(from).toHaveBeenCalledWith("owner_sessions");
    expect(query.eq).toHaveBeenCalledWith(
      "session_token_hash",
      createHash("sha256").update(session.sessionToken).digest("hex"),
    );
    expect(query.eq).toHaveBeenCalledWith("store_id", session.storeId);
    expect(query.not).toHaveBeenCalledWith("consumed_at", "is", null);
    expect(query.gt).toHaveBeenCalledWith("expires_at", expect.any(String));
  });

  it("iptal edilip silinmiş veya süresi dolmuş oturuma izin vermez", async () => {
    const { admin } = fakeAdmin(null);
    expect(await ownerSessionStillActive(admin, session)).toBe(false);
  });

  it("başka mağazaya bağlı oturum geçerli kabul edilmez", async () => {
    const { admin } = fakeAdmin({ store_id: "22222222-2222-4222-8222-222222222222" });
    expect(await ownerSessionStillActive(admin, session)).toBe(false);
  });

  it("veritabanı hatasında güvenli kapanır ve tokenı loglamaz", async () => {
    const { admin } = fakeAdmin(null, { code: "DB_UNAVAILABLE" });
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    try {
      expect(await ownerSessionStillActive(admin, session)).toBe(false);
      expect(log).toHaveBeenCalledWith("[owner-session] session lookup failed", { code: "DB_UNAVAILABLE" });
      expect(JSON.stringify(log.mock.calls)).not.toContain(session.sessionToken);
    } finally { log.mockRestore(); }
  });

  it("beklenmedik sorgu hatasında da güvenli kapanır", async () => {
    const { admin, query } = fakeAdmin(null);
    query.maybeSingle.mockRejectedValue(new Error("network"));
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    try {
      expect(await ownerSessionStillActive(admin, session)).toBe(false);
      expect(log).toHaveBeenCalledWith("[owner-session] session lookup failed", { code: "OWNER_SESSION_LOOKUP_EXCEPTION" });
    } finally { log.mockRestore(); }
  });
});
