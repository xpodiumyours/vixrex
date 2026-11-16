import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
  adminTaslakSatiri: null as null | Record<string, unknown>,
  adminGuncelleme: null as null | Record<string, unknown>,
  adminGuncellemeSayisi: 0,
}));

vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    from: (tablo: string) => {
      if (tablo === "stores") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: async () => ({
                data: { id: "magaza-1", version: 2 },
                error: null,
              }),
            }),
          }),
        };
      }
      return {
        select: () => ({
          eq: () => ({
            maybeSingle: async () => ({
              data: mocks.adminTaslakSatiri,
              error: null,
            }),
          }),
        }),
        update: (yama: Record<string, unknown>) => ({
          eq: async () => {
            mocks.adminGuncelleme = yama;
            mocks.adminGuncellemeSayisi += 1;
            return { error: null };
          },
        }),
      };
    },
  }),
}));

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

function govde() {
  return new NextRequest("http://localhost/api/create-store", {
    method: "POST",
    headers: {
      authorization: "Bearer user-access-token",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      name: "Ege Tost Evi",
      kategori: "Gıda",
      whatsapp: "05551234567",
      address: "Mimar Sinan Mah. No: 5",
      province_name: "İstanbul",
      district_name: "Üsküdar",
      privacy_notice_acknowledged: true,
      terms_accepted: true,
      publication_consent_accepted: true,
    }),
  });
}

function kuran() {
  mocks.getUser.mockResolvedValue({
    data: { user: { id: "user-1", is_anonymous: false } },
    error: null,
  });
  mocks.createClient.mockReturnValue({
    auth: { getUser: mocks.getUser },
    from: vi.fn((tablo: string) =>
      tablo === "legal_documents"
        ? zincir({ data: AKTIF_BELGELER, error: null })
        : zincir({ data: null, error: null })
    ),
    rpc: mocks.rpc,
  });
  mocks.rpc.mockImplementation(async (ad: string) => {
    if (ad === "claim_store_for_user") return { data: { ok: true }, error: null };
    if (ad === "create_owner_session")
      return { data: { code: "owner-code" }, error: null };
    return { data: null, error: null };
  });
}

describe("sihirbaz onayı taslak kopyaya da işlenir", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test-key";
    mocks.adminTaslakSatiri = null;
    mocks.adminGuncelleme = null;
    mocks.adminGuncellemeSayisi = 0;
  });

  it("var olan taslağa üç onay bayrağını yazar ve sürümü eşitler", async () => {
    kuran();
    mocks.adminTaslakSatiri = { draft_data: { name: "Ege Tost Evi" } };

    const response = await POST(govde());

    expect(response.status).toBe(200);
    expect(mocks.adminGuncellemeSayisi).toBe(1);
    const yama = mocks.adminGuncelleme as Record<string, unknown>;
    expect(yama["base_live_version"]).toBe(2);
    const veri = yama["draft_data"] as Record<string, unknown>;
    expect(veri).toMatchObject({
      name: "Ege Tost Evi",
      privacy_notice_acknowledged: true,
      terms_accepted: true,
      publication_consent_accepted: true,
    });
  });

  it("henüz taslak yoksa dokunmaz", async () => {
    kuran();
    mocks.adminTaslakSatiri = null;

    const response = await POST(govde());

    expect(response.status).toBe(200);
    expect(mocks.adminGuncellemeSayisi).toBe(0);
  });
});
