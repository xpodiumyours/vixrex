import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));

import { POST } from "@/app/api/create-store/route";

/**
 * Vitrin oluşturma parite testi.
 *
 * Kural (2026-10-02, esnaf akışı): vitrin taslakta BIRAKILMAZ. "Yayınla"
 * deniyorsa ya yayınlanır ya da NEYİN eksik olduğu söylenir. Bu yüzden
 * başarılı çağrılar, Flutter'ın gerçekten yolladığı tam yükle gelir
 * (`StorePublishPayloadBuilder`: ad, kategori, WhatsApp, adres, il, ilçe,
 * is_published ve yasal onay).
 *
 * Eksik yükle gelen istek 422 ile geri döner, `eksik` listesi taşır ve
 * vitrin HİÇ OLUŞMAZ — sessizce taslak üretilmez.
 */

const TAM_YUK = {
  name: "Test Market",
  kategori: "MARKET",
  whatsapp: "905551234567",
  address: "Test Sokak No:1",
  province_name: "İstanbul",
  district_name: "Kadıköy",
  legal_consent: true,
};

const AKTIF_BELGELER = [
  { document_type: "privacy", version: "2026-01", content_hash: "h-privacy" },
  { document_type: "terms", version: "2026-02", content_hash: "h-terms" },
  { document_type: "consent", version: "2026-03", content_hash: "h-consent" },
];

/** Zincir hem `.maybeSingle()` hem `await` ile kullanılabilir. */
function zincir(sonuc: { data?: unknown; error?: unknown }) {
  const z: Record<string, unknown> = {};
  z.select = vi.fn(() => z);
  z.eq = vi.fn(() => z);
  z.in = vi.fn(() => z);
  z.limit = vi.fn(() => z);
  z.maybeSingle = vi.fn(async () => sonuc);
  z.then = (coz: (s: unknown) => unknown) =>
    Promise.resolve(sonuc).then(coz);
  return z;
}

function istek(govde: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/create-store", {
    method: "POST",
    headers: {
      authorization: "Bearer user-access-token",
      "content-type": "application/json",
    },
    body: JSON.stringify(govde),
  });
}

describe("vitrin olusturma parite (Flutter referansiyla)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";
    mocks.getUser.mockResolvedValue({
      data: { user: { id: "user-1", is_anonymous: false } },
      error: null,
    });
    mocks.rpc.mockResolvedValue({
      data: { ok: true, code: "OWNER_SESSION_CODE" },
      error: null,
    });

    mocks.createClient.mockReturnValue({
      auth: { getUser: mocks.getUser },
      from: vi.fn((tablo: string) =>
        tablo === "legal_documents"
          ? zincir({ data: AKTIF_BELGELER, error: null })
          : zincir({ data: null, error: null }),
      ),
      rpc: mocks.rpc,
    });
  });

  it("tam bilgiyle vitrin olusturur", async () => {
    const response = await POST(istek(TAM_YUK));

    expect(response.status).toBe(200);
    const sonuc = await response.json();
    expect(sonuc.tamam).toBe(true);
    expect(sonuc.slug).toContain("test-market");
  });

  it("Flutter gibi sahiplik karari uygular (claim_store_for_user)", async () => {
    const response = await POST(istek(TAM_YUK));

    expect(response.status).toBe(200);
    const rpcCalls = mocks.rpc.mock.calls.map((c) => c[0]);
    expect(rpcCalls).toContain("claim_store_for_user");
  });

  it("Flutter gibi calisma taslagi olusturur", async () => {
    const response = await POST(istek(TAM_YUK));

    expect(response.status).toBe(200);
    const rpcCalls = mocks.rpc.mock.calls.map((c) => c[0]);
    expect(rpcCalls).toContain("get_or_create_working_draft");
  });

  it("Flutter gibi sahip oturumu acar ve kod doner", async () => {
    const response = await POST(istek(TAM_YUK));

    expect(response.status).toBe(200);
    const sonuc = await response.json();
    expect(sonuc.yonlendir).toContain("ocode=OWNER_SESSION_CODE");
  });

  it("Flutter gibi isim zorunludur (422)", async () => {
    const response = await POST(istek({ ...TAM_YUK, name: "" }));

    expect(response.status).toBe(422);
  });

  it("Flutter gibi oturum zorunludur (401)", async () => {
    const response = await POST(
      new NextRequest("http://localhost/api/create-store", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ name: "Test" }),
      }),
    );

    expect(response.status).toBe(401);
  });

  it("eksik il/ilce icin neyin eksik oldugunu soyler ve vitrin hic olusturmaz", async () => {
    const response = await POST(
      istek({ ...TAM_YUK, province_name: "", district_name: "" }),
    );

    expect(response.status).toBe(422);
    const sonuc = await response.json();
    expect(sonuc.eksik).toEqual(
      expect.arrayContaining(["il", "ilçe"]),
    );
    expect(sonuc.hata).toContain("anında yayına alınır");
    // Taslak üretilmemiş: vitrin kaydı RPC'si hiç çalışmamış olmalı.
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("yayina yeterli olmayan kategori ve numara da ayrica soyenilir", async () => {
    const response = await POST(
      istek({ ...TAM_YUK, kategori: "Diğer", whatsapp: "0555ABC1234" }),
    );

    expect(response.status).toBe(422);
    const sonuc = await response.json();
    expect(sonuc.eksik).toEqual(
      expect.arrayContaining(["kategori", "WhatsApp numarası (05XX XXX XX XX)"]),
    );
    expect(mocks.rpc).not.toHaveBeenCalled();
  });

  it("yasal onay yoksa vitrin olusturmaz, neyin eksik oldugunu soyer", async () => {
    const response = await POST(istek({ ...TAM_YUK, legal_consent: false }));

    expect(response.status).toBe(422);
    const sonuc = await response.json();
    expect(sonuc.hata).toContain("üç yasal onayın tamamı gerekli");
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
});
