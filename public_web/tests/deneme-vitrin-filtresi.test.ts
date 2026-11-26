import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";

const { mockRpc, mockFrom } = vi.hoisted(() => ({
  mockRpc: vi.fn(),
  mockFrom: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    rpc: mockRpc,
    from: mockFrom,
  },
}));

import { isTestOrDenemeStore } from "@/lib/denemeVitrinFiltresi";
import { yakinVitrinleriGetir } from "@/lib/explore";

const migrationSource = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20261124103000_eski_deneme_vitrinlerini_yayindan_kaldir.sql"
  ),
  "utf8"
);

function satir(overrides: Record<string, unknown>) {
  return {
    id: "store-x",
    slug: "vitrin",
    name: "Vitrin",
    description: null,
    address: null,
    kategori: null,
    business_type: null,
    shelf_image_url: null,
    logo_url: null,
    province_name: "İstanbul",
    district_name: "Kadıköy",
    status: "Açık",
    is_demo: false,
    whatsapp: null,
    updated_at: "2026-11-24T09:00:00Z",
    rating_score: null,
    show_storefront_rating: false,
    distance_meters: 500,
    ...overrides,
  };
}

function mockProductsQuery(rows: { store_id: string; name: string | null }[]) {
  const eqVisible = vi.fn().mockResolvedValue({ data: rows, error: null });
  const eqActive = vi.fn().mockReturnValue({ eq: eqVisible });
  const inFn = vi.fn().mockReturnValue({ eq: eqActive });
  const select = vi.fn().mockReturnValue({ in: inFn });
  mockFrom.mockReturnValue({ select });
}

describe("ortak deneme vitrini filtresi", () => {
  it("eski deneme kayıtlarını adından veya slug'ından tanır", () => {
    expect(isTestOrDenemeStore({ slug: "deneme2222-mw1a2b3c", name: "Deneme2222" })).toBe(true);
    expect(isTestOrDenemeStore({ slug: "deneme", name: "DENEME" })).toBe(true);
    expect(isTestOrDenemeStore({ slug: "deneme2222s", name: "Deneme2222s" })).toBe(true);
    expect(isTestOrDenemeStore({ slug: "asdf-mw1a2b3c", name: "Vitrin" })).toBe(true);
    expect(isTestOrDenemeStore({ slug: "aasd-mwj3ln80", name: "Vitrin" })).toBe(true);
  });

  it("gerçek esnaf vitrinlerini geçirir", () => {
    expect(isTestOrDenemeStore({ slug: "meram-kebap-mvmugivx", name: "meram-kebap" })).toBe(false);
    expect(isTestOrDenemeStore({ slug: "karanfil-cicekcilik", name: "Karanfil Çiçekçilik" })).toBe(false);
    expect(isTestOrDenemeStore({ slug: "moda-kahve", name: "Moda Kahve" })).toBe(false);
  });

  it("is_demo = true kiralık şablon vitrinini adı ne olursa olsun geçirir", () => {
    expect(isTestOrDenemeStore({ slug: "demo-butik", name: "Demo Butik", is_demo: true })).toBe(false);
    expect(isTestOrDenemeStore({ slug: "deneme-vitrin", name: "Deneme Vitrin", is_demo: true })).toBe(false);
  });
});

describe("Keşfet yakın vitrin listesi deneme filtresi", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("deneme/test vitrinlerini listeden düşürür, gerçek ve kiralık vitrinleri korur", async () => {
    mockRpc.mockResolvedValue({
      data: [
        satir({ id: "s1", slug: "deneme2222-mw1a2b3c", name: "Deneme2222" }),
        satir({ id: "s2", slug: "deneme", name: "DENEME" }),
        satir({ id: "s3", slug: "deneme2222s", name: "Deneme2222s" }),
        satir({ id: "s4", slug: "meram-kebap-mvmugivx", name: "meram-kebap" }),
        satir({
          id: "s5",
          slug: "demo-butik",
          name: "Demo Butik",
          is_demo: true,
        }),
      ],
      error: null,
    });
    mockProductsQuery([
      { store_id: "s4", name: "Kebap" },
      { store_id: "s5", name: "Vitrin Paketi" },
    ]);

    const vitrinler = await yakinVitrinleriGetir({ lat: 41.0, lng: 29.0 });

    expect(vitrinler.map((vitrin) => vitrin.slug)).toEqual([
      "meram-kebap-mvmugivx",
      "demo-butik",
    ]);
    expect(vitrinler[1].kiralikMi).toBe(true);
    expect(mockFrom).toHaveBeenCalledTimes(1);
  });
});

describe("eski deneme vitrinleri migration güvenliği", () => {
  it("hiçbir satırı silmez, yalnız yayın durumunu kapatır", () => {
    expect(migrationSource).not.toMatch(/\bdelete\s+from\b/i);
    expect(migrationSource).not.toMatch(/\btruncate\b/i);
    expect(migrationSource).not.toMatch(/\bdrop\s+table\b/i);
    expect(migrationSource).toContain("set is_published = false");
    expect(migrationSource).toContain("s.is_demo = false");
    expect(migrationSource).toContain("s.is_published = true");
    expect(migrationSource).toContain("v_korunan_demo_sonra");
  });
});
