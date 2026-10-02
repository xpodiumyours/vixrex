import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// Landing asistanı "yayınlandı" dediği anda vitrinin GERÇEKTEN
// `is_published = true` olmasını doğrular. `create_store_with_token`
// taslak bıraktığı için zincirde `update_store_with_token` adımı şart;
// bu dosya o adımın gerçekten çağrıldığını ve yasal onay damgasını
// götürdüğünü yakalar.

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));

import { POST } from "@/app/api/create-store/route";

type Zincir = Record<string, unknown>;

function zincir(sonuc: { data?: unknown; error?: unknown }): Zincir {
  const z: Record<string, unknown> = {};
  z.select = vi.fn(() => z);
  z.eq = vi.fn(() => z);
  z.in = vi.fn(() => z);
  z.limit = vi.fn(() => z);
  z.maybeSingle = vi.fn(async () => sonuc);
  z.then = (coz: (s: unknown) => unknown) => Promise.resolve(sonuc).then(coz);
  return z;
}

const AKTIF_BELGELER = [
  { document_type: "privacy", version: "2026-01", content_hash: "h-privacy" },
  { document_type: "terms", version: "2026-02", content_hash: "h-terms" },
  { document_type: "consent", version: "2026-03", content_hash: "h-consent" },
];

function govde(ekstra: Record<string, unknown> = {}) {
  return new NextRequest("http://localhost/api/create-store", {
    method: "POST",
    headers: {
      authorization: "Bearer user-access-token",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      name: "Levent Kahve",
      kategori: "Kafe & Lokanta",
      whatsapp: "05551234567",
      address: "Bağdat Caddesi 1",
      province_name: "İstanbul",
      district_name: "Kadıköy",
      legal_consent: true,
      ...ekstra,
    }),
  });
}

function kuran(belgeler: unknown[] | null) {
  mocks.getUser.mockResolvedValue({
    data: { user: { id: "user-1", is_anonymous: false } },
    error: null,
  });

  mocks.createClient.mockReturnValue({
    auth: { getUser: mocks.getUser },
    from: vi.fn((tablo: string) =>
      tablo === "legal_documents"
        ? zincir({ data: belgeler, error: null })
        : zincir({ data: null, error: null }),
    ),
    rpc: mocks.rpc,
  });
}

function rpcCagrisi(ad: string) {
  return mocks.rpc.mock.calls.find((c) => c[0] === ad);
}

describe("landing asistanı vitrini gerçekten yayınlar", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";

    mocks.rpc.mockImplementation(async (ad: string) => {
      if (ad === "claim_store_for_user") {
        return { data: { ok: true }, error: null };
      }
      if (ad === "create_owner_session") {
        return { data: { code: "owner-code" }, error: null };
      }
      return { data: null, error: null };
    });
  });

  it("oluşturma sonrası yayın adımını çağırır ve yayın bayrağını yazar", async () => {
    kuran(AKTIF_BELGELER);

    const response = await POST(govde());

    expect(response.status).toBe(200);
    const cagri = rpcCagrisi("update_store_with_token");
    expect(cagri).toBeDefined();
    expect(cagri?.[1].p_store.is_published).toBe(true);
    expect(cagri?.[1].p_edit_token).toBeTruthy();
    await expect(response.json()).resolves.toMatchObject({ tamam: true });
  });

  it("asistanın onayladığı yasal belgeleri aktif sürüm/hash ile damgalar", async () => {
    kuran(AKTIF_BELGELER);

    await POST(govde());

    expect(rpcCagrisi("update_store_with_token")?.[1].p_store).toMatchObject({
      privacy_notice_acknowledged: true,
      privacy_notice_version: "2026-01",
      privacy_notice_hash: "h-privacy",
      terms_accepted: true,
      terms_version: "2026-02",
      terms_hash: "h-terms",
      publication_consent_accepted: true,
      publication_consent_version: "2026-03",
      publication_consent_hash: "h-consent",
    });
  });

  it("yasal onay yoksa vitrin hiç oluşturmaz, neyin eksik olduğunu söyler", async () => {
    kuran(AKTIF_BELGELER);

    const response = await POST(govde({ legal_consent: false }));

    // Eski davranış: vitrin yine oluşur sonra yayın kapısında düşerdi →
    // ortada yayına alınamayan bir kayıt kalırdı. Artık baştan duruyoruz.
    expect(response.status).toBe(422);
    const govdeSonucu = await response.json();
    expect(govdeSonucu.hata).toContain("üç yasal onayın tamamı gerekli");
    expect(rpcCagrisi("create_store_with_token")).toBeUndefined();
    expect(rpcCagrisi("update_store_with_token")).toBeUndefined();
  });

  it("yayın kapısı reddederse sahte başarı döndürmez, slug'ı korur", async () => {
    kuran(AKTIF_BELGELER);
    mocks.rpc.mockImplementation(async (ad: string) => {
      if (ad === "update_store_with_token") {
        return { data: null, error: { message: "STORE_WHATSAPP_INVALID" } };
      }
      if (ad === "claim_store_for_user") {
        return { data: { ok: true }, error: null };
      }
      if (ad === "create_owner_session") {
        return { data: { code: "owner-code" }, error: null };
      }
      return { data: null, error: null };
    });

    const response = await POST(govde());

    expect(response.status).toBe(500);
    const govdeSonucu = await response.json();
    // Sahte başarı yok; ham kod da gösterilmiyor — neyin yanlış olduğu
    // esnafın anlayacağı cümleyle söyleniyor.
    expect(govdeSonucu.tamam).toBeUndefined();
    expect(govdeSonucu.hata).toContain("WhatsApp numarası geçerli görünmüyor");
    expect(govdeSonucu.sebep).toBe("STORE_WHATSAPP_INVALID");
    expect(govdeSonucu.slug).toBeTruthy();
    expect(govdeSonucu.yonlendir).toContain("/api/owner-session");
    // Sahiplik ve oturum YİNE de kuruldu: öksüz vitrin kalmaz.
    expect(rpcCagrisi("claim_store_for_user")).toBeDefined();
    expect(rpcCagrisi("create_owner_session")).toBeDefined();
  });
});