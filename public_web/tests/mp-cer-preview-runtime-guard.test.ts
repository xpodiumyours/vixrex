import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({ createClient: vi.fn(() => ({kind: "test-client"})) }));
vi.mock("server-only", () => ({}));
vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));

describe("MP-CER C0 — gerçek sunucu bağlantı koruması", () => {
  beforeEach(() => {
    vi.resetModules();
    mocks.createClient.mockClear();
    vi.stubEnv("VERCEL_ENV", "preview");
    vi.stubEnv("VERCEL_GIT_COMMIT_REF", "fix/fatura-cerrahi-birlesik-20261010");
    vi.stubEnv("SUPABASE_SERVICE_ROLE_KEY", "sadece-unit-test-sunucu-tokeni");
  });
  afterEach(() => vi.unstubAllEnvs());

  it("C0 Preview yanlışlıkla production URL görürse hiçbir yönetici istemcisi oluşturmaz", async () => {
    vi.stubEnv("SUPABASE_URL", "https://chfulefxczbgurtgavtp.supabase.co");
    const { getSupabaseAdmin } = await import("@/lib/supabaseAdmin");
    expect(() => getSupabaseAdmin()).toThrow("MP_CER_PREVIEW_DB_MUST_BE_ISOLATED");
    expect(mocks.createClient).not.toHaveBeenCalled();
  });

  it("C0 Preview izole test URL ile bağlantı oluşturabilir", async () => {
    vi.stubEnv("SUPABASE_URL", "https://nfivinvdlxhyxsoxzarh.supabase.co");
    const { getSupabaseAdmin } = await import("@/lib/supabaseAdmin");
    expect(getSupabaseAdmin()).toEqual({kind: "test-client"});
    expect(mocks.createClient).toHaveBeenCalledOnce();
  });

  it("sunucu anahtarı yoksa istemci açılmaz; publishable anahtar yetmez", async () => {
    vi.stubEnv("SUPABASE_URL", "https://nfivinvdlxhyxsoxzarh.supabase.co");
    vi.stubEnv("SUPABASE_SERVICE_ROLE_KEY", "");
    const { getSupabaseAdmin } = await import("@/lib/supabaseAdmin");
    expect(() => getSupabaseAdmin()).toThrow("SUPABASE_SERVICE_ROLE_KEY is missing");
    expect(mocks.createClient).not.toHaveBeenCalled();
  });
});
