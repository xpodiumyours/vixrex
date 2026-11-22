import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";

const {
  mockAnonRpc,
  mockAdminRpc,
  mockVerifyRecaptchaToken,
  mockGetSupabaseAdmin,
  mockGetClientIp,
  mockFingerprintClient,
} = vi.hoisted(() => ({
  mockAnonRpc: vi.fn(),
  mockAdminRpc: vi.fn(),
  mockVerifyRecaptchaToken: vi.fn(),
  mockGetSupabaseAdmin: vi.fn(),
  mockGetClientIp: vi.fn(),
  mockFingerprintClient: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: { rpc: mockAnonRpc },
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: mockGetSupabaseAdmin,
}));

vi.mock("@/lib/rentDemoSecurity", () => ({
  getClientIp: mockGetClientIp,
  fingerprintClient: mockFingerprintClient,
}));

vi.mock("@/lib/recaptchaServer", () => ({
  verifyRecaptchaToken: (...args: unknown[]) => mockVerifyRecaptchaToken(...args),
}));

import { POST } from "@/app/api/create-booking/route";

const tableMigrationSql = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20261121224000_urun_ayirtma_rezervasyon.sql"),
  "utf8",
);
const securityMigrationSql = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20261122103000_product_hold_guvenlik_ve_bildirim.sql"),
  "utf8",
);
const commercePanelSource = readFileSync(
  resolve(__dirname, "../src/components/ProductCommercePanel.tsx"),
  "utf8",
);

function makeRequest(body: Record<string, unknown>) {
  return new Request("http://localhost/api/create-booking", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

const validHoldBody = {
  kind: "product_hold",
  storeSlug: "kadikoy-butik",
  productSlug: "keten-gomlek",
  customerName: "Ahmet Demir",
  customerPhone: "05551112233",
  customerNotes: "Akşam 18 gibi alacağım",
  variantKey: "M / Mavi",
  quantity: 2,
  recaptchaToken: "valid-recaptcha-token",
};

const validServiceBody = {
  storeSlug: "kadikoy-butik",
  customerName: "Ayşe Yılmaz",
  customerPhone: "05551234567",
  customerNotes: "",
  serviceTitle: "Saç kesimi",
  servicePrice: "350 TL",
  serviceDuration: 30,
  appointmentTime: "2026-11-22T10:00:00.000Z",
  recaptchaToken: "valid-recaptcha-token",
};

describe("Ürün ayırtma (2 saat stok kilidi) SQL sözleşmesi", () => {
  it("appointments tablosunu bozmadan reservation_kind, product_id, variant_key, quantity ekler ve kısmi indeks tanımlar", () => {
    expect(tableMigrationSql).toContain("ADD COLUMN IF NOT EXISTS reservation_kind text NOT NULL DEFAULT 'service'");
    expect(tableMigrationSql).toContain("CHECK (reservation_kind IN ('service', 'product_hold'))");
    expect(tableMigrationSql).toContain("ADD COLUMN IF NOT EXISTS product_id uuid REFERENCES public.products(id) ON DELETE SET NULL");
    expect(tableMigrationSql).toContain("ADD COLUMN IF NOT EXISTS variant_key text");
    expect(tableMigrationSql).toContain("CHECK (quantity IS NULL OR quantity BETWEEN 1 AND 10)");
    expect(tableMigrationSql).toContain("CREATE INDEX IF NOT EXISTS idx_appointments_product_hold_active");
    expect(tableMigrationSql).toContain("WHERE reservation_kind = 'product_hold' AND product_id IS NOT NULL");
    expect(tableMigrationSql).not.toMatch(/DROP\s+COLUMN/i);
  });

  it("eşzamanlı stok kilidini FOR UPDATE OF p ile korur, süresi dolmamış kilitleri sayar ve STOCK_UNAVAILABLE fırlatır", () => {
    expect(securityMigrationSql).toContain("SECURITY DEFINER");
    expect(securityMigrationSql).toContain("SET search_path = pg_catalog, public, extensions");
    expect(securityMigrationSql).toContain("FOR UPDATE OF p");
    expect(securityMigrationSql).toContain("a.expires_at > now()");
    expect(securityMigrationSql).toContain("a.status IN ('pending', 'confirmed')");
    expect(securityMigrationSql).toContain("RAISE EXCEPTION 'STOCK_UNAVAILABLE'");
    expect(securityMigrationSql).toContain("RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED'");
    expect(securityMigrationSql).toContain("RAISE EXCEPTION 'INVALID_HOLD_INPUT'");
    expect(securityMigrationSql).toContain("RAISE EXCEPTION 'PRODUCT_NOT_FOUND'");
    expect(securityMigrationSql).toContain("now() + interval '2 hours'");
    expect(securityMigrationSql).toContain("gen_random_bytes(16)");
    expect(securityMigrationSql).toContain("sha256(");
  });

  it("ad ve telefon/not uzunluğunu char_length ile sınırlar, günlük limiti yalnız product_hold satırlarına uygular ve mağaza sahibini seçer", () => {
    expect(securityMigrationSql).toContain("char_length(v_customer_name) NOT BETWEEN 2 AND 120");
    expect(securityMigrationSql).toContain("char_length(v_customer_phone) NOT BETWEEN 7 AND 32");
    expect(securityMigrationSql).toContain("char_length(v_customer_notes) > 240");
    expect(securityMigrationSql).toMatch(
      /WHERE customer_phone = v_customer_phone\s+AND reservation_kind = 'product_hold'/,
    );
    expect(securityMigrationSql).toContain("s.user_id");
    expect(securityMigrationSql).toContain("s.name");
  });

  it("anon/authenticated EXECUTE yetkisini kaldırır, yalnızca service_role'e EXECUTE verir ve tablo-seviyesi sızıntı yaratmaz", () => {
    expect(securityMigrationSql).toMatch(
      /REVOKE ALL ON FUNCTION public\.create_product_hold\([^)]+\) FROM PUBLIC, anon, authenticated;/i,
    );
    expect(securityMigrationSql).toMatch(
      /GRANT EXECUTE ON FUNCTION public\.create_product_hold\([^)]+\) TO service_role;/i,
    );
    expect(securityMigrationSql).not.toMatch(
      /GRANT EXECUTE ON FUNCTION public\.create_product_hold\([^)]+\) TO[^;]*\b(anon|authenticated)\b/i,
    );
    expect(securityMigrationSql).not.toMatch(/GRANT\s+(ALL|SELECT|INSERT|UPDATE|DELETE|TRUNCATE|MAINTAIN|REFERENCES|TRIGGER)\s+ON\s+TABLE/i);
    expect(securityMigrationSql).not.toMatch(/GRANT\b[^\n;]*\b(TRUNCATE|MAINTAIN|REFERENCES|TRIGGER)\b/i);
  });

  it("appointments kaydından sonra esnaf için notification_inbox satırı ekler ve çakışmayı yutar", () => {
    expect(securityMigrationSql).toContain("INSERT INTO public.notification_inbox");
    expect(securityMigrationSql).toContain("IF v_store_user_id IS NOT NULL");
    expect(securityMigrationSql).toContain("'product_hold:' || v_appt_id::text");
    expect(securityMigrationSql).toContain("ON CONFLICT (user_id, id) DO NOTHING");
    expect(securityMigrationSql).toContain("left('Yeni urun ayirtma: ' || v_product.name, 160)");
    expect(securityMigrationSql).toContain("'product_hold'");
    expect(securityMigrationSql).toMatch(
      /INSERT INTO public\.appointments[\s\S]*INSERT INTO public\.notification_inbox/,
    );
  });
});

describe("POST /api/create-booking — product_hold ve service uyumluluğu", () => {
  let holdRpcResult: { data: unknown; error: { message: string } | null };
  let rateLimitAllowed: boolean;

  beforeEach(() => {
    vi.clearAllMocks();
    holdRpcResult = { data: null, error: null };
    rateLimitAllowed = true;

    mockGetSupabaseAdmin.mockReturnValue({ rpc: mockAdminRpc });
    mockGetClientIp.mockReturnValue("203.0.113.7");
    mockFingerprintClient.mockReturnValue("fp-test");

    mockAdminRpc.mockImplementation(async (name: string) => {
      if (name === "consume_assistant_request") {
        return {
          data: [{ allowed: rateLimitAllowed, retry_after_seconds: rateLimitAllowed ? 0 : 120 }],
          error: null,
        };
      }
      return holdRpcResult;
    });
  });

  it("geçersiz JSON gövdesinde 400 döner", async () => {
    const response = await POST(
      new Request("http://localhost/api/create-booking", {
        method: "POST",
        body: "{bozuk-json",
      }),
    );
    expect(response.status).toBe(400);
    expect(mockAnonRpc).not.toHaveBeenCalled();
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("tanımsız veya desteklenmeyen kind değerinde 400 döner", async () => {
    const response = await POST(makeRequest({ ...validHoldBody, kind: "unknown_kind" }));
    expect(response.status).toBe(400);
    expect(mockAnonRpc).not.toHaveBeenCalled();
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("productSlug, customerName veya customerPhone eksikse 400 döner ve RPC çağrılmaz", async () => {
    for (const missingField of ["storeSlug", "productSlug", "customerName", "customerPhone"] as const) {
      const payload = { ...validHoldBody } as Record<string, unknown>;
      delete payload[missingField];
      const response = await POST(makeRequest(payload));
      expect(response.status).toBe(400);
    }
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("quantity 1..10 aralığı dışında veya tam sayı değilse 400 döner", async () => {
    for (const badQty of [0, -1, 11, 1.5, "2", null]) {
      const response = await POST(makeRequest({ ...validHoldBody, quantity: badQty }));
      expect(response.status).toBe(400);
    }
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("kısa/uzun telefon, kısa/uzun ad veya 240 karakteri aşan not 400 döner ve RPC çağrılmaz", async () => {
    const gecersizler: Record<string, unknown>[] = [
      { customerPhone: "123456" },
      { customerPhone: "1".repeat(33) },
      { customerName: "A" },
      { customerName: "A".repeat(121) },
      { customerNotes: "a".repeat(241) },
    ];

    for (const gecersiz of gecersizler) {
      const response = await POST(makeRequest({ ...validHoldBody, ...gecersiz }));
      expect(response.status).toBe(400);
    }
    expect(mockVerifyRecaptchaToken).not.toHaveBeenCalled();
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("recaptchaToken eksikse 403 döner ve verifyRecaptchaToken/RPC çağrılmaz", async () => {
    const payload = { ...validHoldBody } as Record<string, unknown>;
    delete payload.recaptchaToken;
    const response = await POST(makeRequest(payload));
    expect(response.status).toBe(403);
    expect(mockVerifyRecaptchaToken).not.toHaveBeenCalled();
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("reCAPTCHA doğrulaması başarısız olursa 403 döner ve RPC çağrılmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: false, error: "Score too low" });
    const response = await POST(makeRequest(validHoldBody));
    expect(response.status).toBe(403);
    expect(mockVerifyRecaptchaToken).toHaveBeenCalledWith("valid-recaptcha-token", "booking_create");
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("IP oran sınırı allowed=false döndürdüğünde 429 verir ve create_product_hold çağrılmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    rateLimitAllowed = false;

    const response = await POST(makeRequest(validHoldBody));

    expect(response.status).toBe(429);
    expect(mockAdminRpc).toHaveBeenCalledWith("consume_assistant_request", {
      p_client_key: "product_hold:ip:fp-test",
      p_max_requests: 8,
      p_window_seconds: 3600,
    });
    expect(mockAdminRpc).not.toHaveBeenCalledWith("create_product_hold", expect.anything());
  });

  it("IP parmak izini istemci IP'sinden üretip oran sınırı anahtarında kullanır", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    holdRpcResult = { data: { appointment_id: "hold-uuid-1" }, error: null };

    const response = await POST(makeRequest(validHoldBody));

    expect(response.status).toBe(200);
    expect(mockGetClientIp).toHaveBeenCalledTimes(1);
    expect(mockFingerprintClient).toHaveBeenCalledWith("203.0.113.7");
    expect(mockAdminRpc).toHaveBeenCalledWith("consume_assistant_request", {
      p_client_key: "product_hold:ip:fp-test",
      p_max_requests: 8,
      p_window_seconds: 3600,
    });
  });

  it("getSupabaseAdmin hata verirse 503 döner ve create_product_hold çağrılmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockGetSupabaseAdmin.mockImplementation(() => {
      throw new Error("SUPABASE_SERVICE_ROLE_KEY is missing");
    });

    const response = await POST(makeRequest(validHoldBody));

    expect(response.status).toBe(503);
    expect(mockAdminRpc).not.toHaveBeenCalled();
  });

  it("STOCK_UNAVAILABLE hatasında 409 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    holdRpcResult = { data: null, error: { message: "STOCK_UNAVAILABLE" } };

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(409);
    expect(body.error.message).toContain("STOCK_UNAVAILABLE");
  });

  it("DAILY_LIMIT_EXCEEDED hatasında 429 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    holdRpcResult = { data: null, error: { message: "DAILY_LIMIT_EXCEEDED" } };

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(429);
    expect(body.error.message).toContain("DAILY_LIMIT_EXCEEDED");
  });

  it("PRODUCT_NOT_FOUND gibi diğer RPC hatalarında 400 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    holdRpcResult = { data: null, error: { message: "PRODUCT_NOT_FOUND" } };

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(400);
    expect(body.error.message).toContain("PRODUCT_NOT_FOUND");
  });

  it("geçerli product_hold isteğinde create_product_hold RPC'sini admin istemciyle çağırır ve 200 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    holdRpcResult = {
      data: {
        appointment_id: "hold-uuid-1",
        token: "test-000001",
        expires_at: "2026-11-21T22:30:00.000Z",
      },
      error: null,
    };

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mockAdminRpc).toHaveBeenCalledWith("create_product_hold", {
      p_store_slug: "kadikoy-butik",
      p_product_slug: "keten-gomlek",
      p_customer_name: "Ahmet Demir",
      p_customer_phone: "05551112233",
      p_customer_notes: "Akşam 18 gibi alacağım",
      p_variant_key: "M / Mavi",
      p_quantity: 2,
    });
    expect(mockAnonRpc).not.toHaveBeenCalled();
    expect(body.data).toEqual({
      appointment_id: "hold-uuid-1",
      token: "test-000001",
      expires_at: "2026-11-21T22:30:00.000Z",
    });
  });

  it("varsayılan service randevu akışını bozmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockAnonRpc.mockResolvedValue({
      data: { appointment_id: "appt-1", token: "tok-1" },
      error: null,
    });

    const response = await POST(makeRequest(validServiceBody));
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mockAnonRpc).toHaveBeenCalledWith("create_appointment_request", {
      p_store_slug: "kadikoy-butik",
      p_customer_name: "Ayşe Yılmaz",
      p_customer_phone: "05551234567",
      p_customer_notes: "",
      p_service_title: "Saç kesimi",
      p_service_price: "350 TL",
      p_service_duration: 30,
      p_appointment_time: "2026-11-22T10:00:00.000Z",
    });
    expect(mockAdminRpc).not.toHaveBeenCalled();
    expect(body.data).toEqual({ appointment_id: "appt-1", token: "tok-1" });
  });
});

describe("ProductCommercePanel Adıma Ayırt UI sözleşmesi", () => {
  it("useRecaptcha ile hazirla ve executeRecaptcha kullanır, takip bağlantısı üretir ve sahte WhatsApp iddiası içermez", () => {
    expect(commercePanelSource).toContain("useRecaptcha");
    expect(commercePanelSource).toContain("hazirla()");
    expect(commercePanelSource).toContain('executeRecaptcha("booking_create")');
    expect(commercePanelSource).toContain("Adıma Ayırt (2 Saat)");
    expect(commercePanelSource).toContain("/api/create-booking");
    expect(commercePanelSource).toContain('kind: "product_hold"');
    expect(commercePanelSource).toContain("/v/${storeSlug}/randevu/${holdSuccess.token}");
    expect(commercePanelSource).not.toMatch(/otomatik WhatsApp/i);
  });
});
