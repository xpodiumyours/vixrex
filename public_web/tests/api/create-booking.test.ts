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

// V-21 (attack-vectors.md, 2026-08-18): BookingWizardClient reCAPTCHA
// fişini alıp yalnız log'luyordu, hiç doğrulanmıyordu. Bu rota web
// istemcisinin artık gerçekten geçtiği, sunucu tarafında doğrulama yapan
// ara katman.

function request(body: Record<string, unknown>) {
  return new Request("http://localhost/api/create-booking", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

const validBody = {
  storeSlug: "kadikoy-butik",
  customerName: "Ayşe Yılmaz",
  customerPhone: "05551234567",
  customerNotes: "",
  serviceTitle: "Saç kesimi",
  servicePrice: "",
  serviceDuration: 30,
  appointmentTime: "2026-08-20T10:00:00.000Z",
  recaptchaToken: "test-token",
};

describe("POST /api/create-booking", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("recaptchaToken eksikse RPC hiç çağrılmaz", async () => {
    const bodyWithoutToken = { ...validBody } as Record<string, unknown>;
    delete bodyWithoutToken.recaptchaToken;
    const response = await POST(request(bodyWithoutToken));

    expect(response.status).toBe(403);
    expect(mockVerifyRecaptchaToken).not.toHaveBeenCalled();
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("reCAPTCHA reddederse RPC çağrılmaz", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: false, error: "Score too low" });

    const response = await POST(request(validBody));

    expect(response.status).toBe(403);
    expect(mockVerifyRecaptchaToken).toHaveBeenCalledWith("test-token", "booking_create");
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("eksik randevu bilgisiyle RPC çağrılmaz", async () => {
    const bodyWithoutSlug = { ...validBody } as Record<string, unknown>;
    delete bodyWithoutSlug.storeSlug;
    const response = await POST(request(bodyWithoutSlug));

    expect(response.status).toBe(400);
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("reCAPTCHA geçerse create_appointment_request'i doğru parametrelerle çağırır", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockRpc.mockResolvedValue({
      data: { appointment_id: "appt-1", token: "tok-1" },
      error: null,
    });

    const response = await POST(request(validBody));
    const body = await response.json();

    expect(mockRpc).toHaveBeenCalledWith("create_appointment_request", {
      p_store_slug: "kadikoy-butik",
      p_customer_name: "Ayşe Yılmaz",
      p_customer_phone: "05551234567",
      p_customer_notes: "",
      p_service_title: "Saç kesimi",
      p_service_price: "",
      p_service_duration: 30,
      p_appointment_time: "2026-08-20T10:00:00.000Z",
    });
    expect(response.status).toBe(200);
    expect(body.data).toEqual({ appointment_id: "appt-1", token: "tok-1" });
  });

  it("RPC hata dönerse mesajı client'a taşır", async () => {
    mockVerifyRecaptchaToken.mockResolvedValue({ success: true, score: 0.9 });
    mockRpc.mockResolvedValue({ data: null, error: { message: "CAPACITY_FULL" } });

    const response = await POST(request(validBody));
    const body = await response.json();

    expect(response.status).toBe(400);
    expect(body.error.message).toBe("CAPACITY_FULL");
  });
});
