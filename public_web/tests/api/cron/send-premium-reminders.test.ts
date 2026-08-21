import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const mockRpc = vi.fn();
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({ rpc: mockRpc }),
}));

import { GET } from "@/app/api/cron/send-premium-reminders/route";

const CANDIDATE = {
  store_id: "11111111-1111-1111-1111-111111111111",
  user_id: "22222222-2222-2222-2222-222222222222",
  store_slug: "kiralik-butik-ab12cd34",
  store_name: "Atmosfer Butik",
  premium_expires_at: new Date(Date.now() + 2 * 86_400_000).toISOString(),
};

function cronRequest(secret?: string) {
  return new NextRequest("http://localhost/api/cron/send-premium-reminders", {
    headers: secret ? { authorization: `Bearer ${secret}` } : {},
  });
}

function setConfiguredEnv() {
  process.env.CRON_SECRET = "test-cron-secret";
  process.env.ONESIGNAL_APP_ID = "test-app-id";
  process.env.ONESIGNAL_REST_API_KEY = "test-rest-key";
}

describe("GET /api/cron/send-premium-reminders — güvenlik", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    delete process.env.CRON_SECRET;
    delete process.env.ONESIGNAL_APP_ID;
    delete process.env.ONESIGNAL_REST_API_KEY;
  });

  it("CRON_SECRET tanımlı değilse fail-closed 503 döner, RPC çağrılmaz", async () => {
    const res = await GET(cronRequest("herhangi-bir-deger"));
    expect(res.status).toBe(503);
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("CRON_SECRET tanımlı ama başlık eşleşmiyorsa 401 döner", async () => {
    process.env.CRON_SECRET = "gercek-secret";
    const res = await GET(cronRequest("yanlis-secret"));
    expect(res.status).toBe(401);
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("Authorization başlığı hiç yoksa 401 döner", async () => {
    process.env.CRON_SECRET = "gercek-secret";
    const res = await GET(cronRequest());
    expect(res.status).toBe(401);
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("OneSignal kimlikleri eksikse fail-closed 503 döner, RPC çağrılmaz", async () => {
    process.env.CRON_SECRET = "gercek-secret";
    const res = await GET(cronRequest("gercek-secret"));
    expect(res.status).toBe(503);
    expect(mockRpc).not.toHaveBeenCalled();
  });
});

describe("GET /api/cron/send-premium-reminders — gönderim akışı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setConfiguredEnv();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("aday yoksa hiçbir push denenmez, targeted/sent 0 döner", async () => {
    mockRpc.mockResolvedValue({ data: [], error: null });
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);

    const res = await GET(cronRequest("test-cron-secret"));
    const json = await res.json();

    expect(json).toEqual({ ok: true, targeted: 0, sent: 0, failed: 0 });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("başarılı push sonrası mark RPC'sini AYNI adayın verisiyle çağırır", async () => {
    mockRpc.mockImplementation((fn: string) => {
      if (fn === "list_premium_expiry_reminder_candidates") {
        return Promise.resolve({ data: [CANDIDATE], error: null });
      }
      return Promise.resolve({ data: null, error: null });
    });
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, text: async () => "" });
    vi.stubGlobal("fetch", fetchMock);

    const res = await GET(cronRequest("test-cron-secret"));
    const json = await res.json();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.onesignal.com/notifications");
    const body = JSON.parse(init.body as string);
    expect(body.app_id).toBe("test-app-id");
    expect(body.include_aliases.external_id).toEqual([CANDIDATE.user_id]);
    expect(body.data.storeSlug).toBe(CANDIDATE.store_slug);

    expect(mockRpc).toHaveBeenCalledWith("mark_premium_expiry_reminder_sent", {
      p_store_id: CANDIDATE.store_id,
      p_premium_expires_at: CANDIDATE.premium_expires_at,
    });
    expect(json).toEqual({ ok: true, targeted: 1, sent: 1, failed: 0 });
  });

  it("OneSignal başarısız olursa MARK ÇAĞRILMAZ — bir sonraki cron'da tekrar denensin", async () => {
    mockRpc.mockImplementation((fn: string) => {
      if (fn === "list_premium_expiry_reminder_candidates") {
        return Promise.resolve({ data: [CANDIDATE], error: null });
      }
      return Promise.resolve({ data: null, error: null });
    });
    const fetchMock = vi
      .fn()
      .mockResolvedValue({ ok: false, text: async () => "OneSignal error" });
    vi.stubGlobal("fetch", fetchMock);

    const res = await GET(cronRequest("test-cron-secret"));
    const json = await res.json();

    expect(mockRpc).not.toHaveBeenCalledWith(
      "mark_premium_expiry_reminder_sent",
      expect.anything()
    );
    expect(json).toEqual({ ok: true, targeted: 1, sent: 0, failed: 1 });
  });

  it("RPC listesi hata dönerse 500 döner, hiçbir push denenmez", async () => {
    mockRpc.mockResolvedValue({ data: null, error: { message: "boom" } });
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);

    const res = await GET(cronRequest("test-cron-secret"));
    expect(res.status).toBe(500);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
