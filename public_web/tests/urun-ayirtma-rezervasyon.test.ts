import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";

const { mockRpc, mockVerifyRecaptchaToken } = vi.hoisted(() => ({
  mockRpc: vi.fn(),
  mockVerifyRecaptchaToken: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: { rpc: mockRpc },
}));

vi.mock("@/lib/recaptchaServer", () => ({
  verifyRecaptchaToken: (...args: unknown[]) => mockVerifyRecaptchaToken(...args),
}));

import { POST } from "@/app/api/create-booking/route";

const migrationSql = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20261121224000_urun_ayirtma_rezervasyon.sql"),
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
    expect(migrationSql).toContain("ADD COLUMN IF NOT EXISTS reservation_kind text NOT NULL DEFAULT 'service'");
    expect(migrationSql).toContain("CHECK (reservation_kind IN ('service', 'product_hold'))");
    expect(migrationSql).toContain("ADD COLUMN IF NOT EXISTS product_id uuid REFERENCES public.products(id) ON DELETE SET NULL");
    expect(migrationSql).toContain("ADD COLUMN IF NOT EXISTS variant_key text");
    expect(migrationSql).toContain("CHECK (quantity IS NULL OR quantity BETWEEN 1 AND 10)");
    expect(migrationSql).toContain("CREATE INDEX IF NOT EXISTS idx_appointments_product_hold_active");
    expect(migrationSql).toContain("WHERE reservation_kind = 'product_hold' AND product_id IS NOT NULL");
    expect(migrationSql).not.toMatch(/DROP\s+COLUMN/i);
  });

  it("eşzamanlı stok kilidini FOR UPDATE OF p ile korur, süresi dolmamış kilitleri sayar ve STOCK_UNAVAILABLE fırlatır", () => {
    expect(migrationSql).toContain("SECURITY DEFINER");
    expect(migrationSql).toContain("SET search_path = pg_catalog, public, extensions");
    expect(migrationSql).toContain("FOR UPDATE OF p");
    expect(migrationSql).toContain("a.expires_at > now()");
    expect(migrationSql).toContain("a.status IN ('pending', 'confirmed')");
    expect(migrationSql).toContain("RAISE EXCEPTION 'STOCK_UNAVAILABLE'");
    expect(migrationSql).toContain("RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED'");
    expect(migrationSql).toContain("RAISE EXCEPTION 'INVALID_HOLD_INPUT'");
    expect(migrationSql).toContain("RAISE EXCEPTION 'PRODUCT_NOT_FOUND'");
    expect(migrationSql).toContain("now() + interval '2 hours'");
    expect(migrationSql).toContain("gen_random_bytes(16)");
    expect(migrationSql).toContain("sha256(");
  });

  it("PUBLIC execute yetkisini kaldırır, yalnızca anon ve authenticated'e EXECUTE verir ve tablo-seviyesi sızıntı yaratmaz", () => {
    expect(migrationSql).toMatch(
      /REVOKE ALL ON FUNCTION public\.create_product_hold\([^)]+\) FROM PUBLIC;/i,
    );
    expect(migrationSql).toMatch(
      /GRANT EXECUTE ON FUNCTION public\.create_product_hold\([^)]+\) TO anon, authenticated;/i,
    );
    expect(migrationSql).not.toMatch(/GRANT\s+(ALL|SELECT|INSERT|UPDATE|DELETE|TRUNCATE|MAINTAIN|REFERENCES|TRIGGER)\s+ON\s+TABLE/i);
    expect(migrationSql).not.toMatch(/GRANT\b[^\n;]*\b(TRUNCATE|MAINTAIN|REFERENCES|TRIGGER)\b/i);
  });
});

describe("POST /api/create-booking — product_hold ve service uyumluluğu", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("geçersiz JSON gövdesinde 400 döner", async () => {
    const response = await POST(
      new Request("http://localhost/api/create-booking", {
        method: "POST",
        body: "{bozuk-json",
      }),
    );
    expect(response.status).toBe(400);
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("tanımsız veya desteklenmeyen kind değerinde 400 döner", async () => {
    const response = await POST(makeRequest({ ...validHoldBody, kind: "unknown_kind" }));
    expect(response.status).toBe(400);
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("productSlug, customerName veya customerPhone eksikse 400 döner ve RPC çağrılmaz", async () => {
    for (const missingField of ["storeSlug", "productSlug", "customerName", "customerPhone"] as const) {
      const payload = { ...validHoldBody } as Record<string, unknown>;
      delete payload[missingField];
      const response = await POST(makeRequest(payload));
      expect(response.status).toBe(400);
    }
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("quantity 1..10 aralığı dışında veya tam sayı değilse 400 döner", async () => {
    for (const badQty of [0, -1, 11, 1.5, "2", null]) {
      const response = await POST(makeRequest({ ...validHoldBody, quantity: badQty }));
      expect(response.status).toBe(400);
    }
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("recaptchaToken eksikse 403 döner ve verifyRecaptchaToken/RPC çağrılmaz", async () => {
    const payload = { ...validHoldBody } as Record<string, unknown>;
    delete payload.recaptchaToken;
    const response = await POST(makeRequest(payload));
    expect(response.status).toBe(403);
    expect(mockVerifyRecaptchaToken).not.toHaveBeenCalled();
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("reCAPTCHA doğrulaması başarısız olursa 403 döner ve RPC çağrılmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: false, error: "Score too low" });
    const response = await POST(makeRequest(validHoldBody));
    expect(response.status).toBe(403);
    expect(mockVerifyRecaptchaToken).toHaveBeenCalledWith("valid-recaptcha-token", "booking_create");
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("STOCK_UNAVAILABLE hatasında 409 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockRpc.mockResolvedValue({ data: null, error: { message: "STOCK_UNAVAILABLE" } });

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(409);
    expect(body.error.message).toContain("STOCK_UNAVAILABLE");
  });

  it("DAILY_LIMIT_EXCEEDED hatasında 429 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockRpc.mockResolvedValue({ data: null, error: { message: "DAILY_LIMIT_EXCEEDED" } });

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(429);
    expect(body.error.message).toContain("DAILY_LIMIT_EXCEEDED");
  });

  it("PRODUCT_NOT_FOUND gibi diğer RPC hatalarında 400 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockRpc.mockResolvedValue({ data: null, error: { message: "PRODUCT_NOT_FOUND" } });

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(400);
    expect(body.error.message).toContain("PRODUCT_NOT_FOUND");
  });

  it("geçerli product_hold isteğinde create_product_hold RPC'sini çağırır ve 200 döner", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockRpc.mockResolvedValue({
      data: {
        appointment_id: "hold-uuid-1",
        token: "test-000001",
        expires_at: "2026-11-21T22:30:00.000Z",
      },
      error: null,
    });

    const response = await POST(makeRequest(validHoldBody));
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mockRpc).toHaveBeenCalledWith("create_product_hold", {
      p_store_slug: "kadikoy-butik",
      p_product_slug: "keten-gomlek",
      p_customer_name: "Ahmet Demir",
      p_customer_phone: "05551112233",
      p_customer_notes: "Akşam 18 gibi alacağım",
      p_variant_key: "M / Mavi",
      p_quantity: 2,
    });
    expect(body.data).toEqual({
      appointment_id: "hold-uuid-1",
      token: "test-000001",
      expires_at: "2026-11-21T22:30:00.000Z",
    });
  });

  it("varsayılan service randevu akışını bozmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockRpc.mockResolvedValue({
      data: { appointment_id: "appt-1", token: "tok-1" },
      error: null,
    });

    const response = await POST(makeRequest(validServiceBody));
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mockRpc).toHaveBeenCalledWith("create_appointment_request", {
      p_store_slug: "kadikoy-butik",
      p_customer_name: "Ayşe Yılmaz",
      p_customer_phone: "05551234567",
      p_customer_notes: "",
      p_service_title: "Saç kesimi",
      p_service_price: "350 TL",
      p_service_duration: 30,
      p_appointment_time: "2026-11-22T10:00:00.000Z",
    });
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
