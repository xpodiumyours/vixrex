import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  rpc: vi.fn(),
  adminTaslakSatiri: null as null | Record<string, unknown>,
  adminGuncelleme: null as null | Record<string, unknown>,
  sonStoreKaydi: null as null | Record<string, unknown>,
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

function istekKur(govde: Record<string, unknown>): NextRequest {
  return new NextRequest("http://localhost/api/create-store", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: "Bearer test-token-123",
    },
    body: JSON.stringify(govde),
  });
}

describe("create-store sektörel hazır paket entegrasyonu (Faz 1)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.adminTaslakSatiri = { draft_data: {} };
    mocks.adminGuncelleme = null;
    mocks.sonStoreKaydi = null;

    mocks.getUser.mockResolvedValue({
      data: {
        user: {
          id: "usr-1",
          email: "esnaf@example.com",
          app_metadata: {},
          user_metadata: {},
        },
      },
      error: null,
    });

    mocks.rpc.mockImplementation(async (ad: string, params: Record<string, unknown>) => {
      if (ad === "create_store_with_token") {
        mocks.sonStoreKaydi = params.p_store as Record<string, unknown>;
        return { data: null, error: null };
      }
      if (ad === "claim_store_for_user") {
        return { data: { ok: true }, error: null };
      }
      if (ad === "get_or_create_working_draft") {
        return { data: { id: "taslak-1" }, error: null };
      }
      if (ad === "create_owner_session") {
        return { data: { code: "ocode-123" }, error: null };
      }
      if (ad === "update_store_with_token") {
        mocks.sonStoreKaydi = params.p_store as Record<string, unknown>;
        return { data: null, error: null };
      }
      return { data: null, error: null };
    });

    mocks.createClient.mockReturnValue({
      auth: { getUser: mocks.getUser },
      rpc: mocks.rpc,
      from: (tablo: string) => {
        if (tablo === "stores") return zincir({ data: null, error: null });
        if (tablo === "legal_documents") return zincir({ data: AKTIF_BELGELER, error: null });
        return zincir({ data: null, error: null });
      },
    });
  });

  it("Butik kategorisinde açılan vitrin %85 dolu sektörel paketle doğar", async () => {
    const res = await POST(
      istekKur({
        name: "Kuzey Butik",
        kategori: "Butik",
        whatsapp: "0555 123 45 67",
        address: "Çekmeköy, İstanbul",
        province_name: "İstanbul",
        district_name: "Çekmeköy",
        privacy_notice_acknowledged: true,
        terms_accepted: true,
        publication_consent_accepted: true,
      })
    );

    expect(res.status).toBe(200);

    // 1. Canlı store kaydına yazılan zengin alanlar
    expect(mocks.sonStoreKaydi).not.toBeNull();
    const store = mocks.sonStoreKaydi!;
    expect(store.hero_badge).toBe("Özenle Seçilmiş Parçalar");
    expect(store.featured_banner_label).toBe("Yeni Sezon");
    expect(store.featured_banner_title).toBe("Sonbahar & Kış Koleksiyonu Vitrinde");
    expect(store.about_title).toBe("Butik Modasında Samimi Dokunuş");
    expect(store.category_section_title).toBe("Koleksiyonlar");
    expect(store.product_section_title).toBe("Öne Çıkan Ürünlerimiz");
    expect(Array.isArray(store.faq_items)).toBe(true);
    expect((store.faq_items as unknown[]).length).toBe(4);
    expect(Array.isArray(store.about_values)).toBe(true);
    expect((store.about_values as unknown[]).length).toBe(3);

    // 2. store_working_drafts.draft_data içine eşitlenen alanlar
    expect(mocks.adminGuncelleme).not.toBeNull();
    const draftData = (mocks.adminGuncelleme as { draft_data: Record<string, unknown> }).draft_data;
    expect(draftData.hero_badge).toBe("Özenle Seçilmiş Parçalar");
    expect(draftData.featured_banner_title).toBe("Sonbahar & Kış Koleksiyonu Vitrinde");
    expect(draftData.about_title).toBe("Butik Modasında Samimi Dokunuş");
    expect(draftData.privacy_notice_acknowledged).toBe(true);
  });

  it("Esnaf onboarding'de kendi açıklamasını yazdıysa sektörel açıklama onu ezmez", async () => {
    const ozelAciklama = "Biz 30 yıllık aile butiğiyiz, sadece pamuklu kumaş satarız.";
    const res = await POST(
      istekKur({
        name: "Özel Butik",
        kategori: "Butik",
        description: ozelAciklama,
        whatsapp: "0555 123 45 67",
        address: "Kadıköy, İstanbul",
        province_name: "İstanbul",
        district_name: "Kadıköy",
        privacy_notice_acknowledged: true,
        terms_accepted: true,
        publication_consent_accepted: true,
      })
    );

    expect(res.status).toBe(200);
    const store = mocks.sonStoreKaydi!;
    expect(store.description).toBe(ozelAciklama);
    // Diğer zengin alanlar yine sektörel paketle doludur
    expect(store.hero_badge).toBe("Özenle Seçilmiş Parçalar");
    expect(store.featured_banner_title).toBe("Sonbahar & Kış Koleksiyonu Vitrinde");
  });

  it("Kafe & Restoran kategorisi kendi lezzet ve menü paketini alır", async () => {
    const res = await POST(
      istekKur({
        name: "Moda Kahvecisi",
        kategori: "Kafe & Restoran",
        whatsapp: "0555 123 45 67",
        address: "Moda, İstanbul",
        province_name: "İstanbul",
        district_name: "Kadıköy",
        privacy_notice_acknowledged: true,
        terms_accepted: true,
        publication_consent_accepted: true,
      })
    );

    expect(res.status).toBe(200);
    const store = mocks.sonStoreKaydi!;
    expect(store.hero_badge).toBe("Keyifli Bir Mola");
    expect(store.category_section_title).toBe("Menümüz");
    expect(store.featured_banner_title).toBe("Günün Özel Lezzetini Keşfedin");
  });
});
