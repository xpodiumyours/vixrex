import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { NextRequest } from "next/server";
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

import { GET } from "@/app/api/kesfet/yakin/route";
import { yakinVitrinleriGetir } from "@/lib/explore";

const migrationSource = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20261121223000_postgis_konum_indeksi.sql"),
  "utf8"
);

const kesfetIcerikSource = readFileSync(
  resolve(__dirname, "../src/components/kesfet/KesfetIcerik.tsx"),
  "utf8"
);

const vitrinKartiSource = readFileSync(
  resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
  "utf8"
);

function mockProductsQuery(rows: { store_id: string; name: string | null }[]) {
  const eqVisible = vi.fn().mockResolvedValue({ data: rows, error: null });
  const eqActive = vi.fn().mockReturnValue({ eq: eqVisible });
  const inFn = vi.fn().mockReturnValue({ eq: eqActive });
  const select = vi.fn().mockReturnValue({ in: inFn });
  mockFrom.mockReturnValue({ select });
}

describe("PostGIS konum indeksi migration sözleşmesi", () => {
  it("postgis eklentisini extensions şemasında açar ve geography kolonunu ekler", () => {
    expect(migrationSource).toContain(
      "CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;"
    );
    expect(migrationSource).toContain("extensions.geography(Point, 4326)");
  });

  it("tetikleyici ve GIST/il-ilçe indekslerini yayındaki mağazalar için tanımlar", () => {
    expect(migrationSource).toContain("stores_sync_location_geography()");
    expect(migrationSource).toContain(
      "BEFORE INSERT OR UPDATE OF latitude, longitude ON public.stores"
    );
    expect(migrationSource).toContain("USING GIST (location)");
    expect(migrationSource).toContain("idx_stores_location_gist");
    expect(migrationSource).toContain("idx_stores_province_district_published");
    expect(migrationSource).toContain("WHERE is_published = true");
  });

  it("search_nearby_stores güvenli ve yalnız anon/authenticated'e açık", () => {
    expect(migrationSource).toContain("public.search_nearby_stores");
    expect(migrationSource).toContain("SECURITY DEFINER");
    expect(migrationSource).toContain("SET search_path = public, extensions");
    expect(migrationSource).toContain("s.is_published = true");
    expect(migrationSource).toContain("extensions.st_dwithin");
    expect(migrationSource).toContain("s.location <-> origin");
    expect(migrationSource).toMatch(
      /REVOKE ALL ON FUNCTION public\.search_nearby_stores\([^)]+\) FROM PUBLIC;/
    );
    expect(migrationSource).toMatch(
      /GRANT EXECUTE ON FUNCTION public\.search_nearby_stores\([^)]+\) TO anon, authenticated;/
    );
  });

  it("hassas kolonları sızdırmaz ve public.stores üzerinde tablo-seviyesi GRANT açmaz", () => {
    expect(migrationSource).not.toContain("user_id");
    expect(migrationSource).not.toContain("edit_token");
    expect(migrationSource).not.toMatch(/\b(truncate|maintain|references)\b/i);
    expect(migrationSource).not.toMatch(/\bgrant\b[\s\S]*?\btrigger\b/i);
    expect(migrationSource).not.toMatch(
      /\bgrant\b[\s\S]*?\bon\s+(?:table\s+)?public\.stores\b/i
    );

    const returnsMatch = migrationSource.match(
      /RETURNS TABLE\s*\(([\s\S]*?)\)\s*LANGUAGE plpgsql/
    );
    expect(returnsMatch).not.toBeNull();
    expect(returnsMatch?.[1]).not.toMatch(/\blocation\b/i);

    const selectMatch = migrationSource.match(
      /RETURN QUERY\s*SELECT([\s\S]*?)FROM public\.stores s/
    );
    expect(selectMatch).not.toBeNull();
    expect(selectMatch?.[1]).not.toMatch(/(?:^|,)\s*s\.location\s*(?:,|$)/im);
    expect(selectMatch?.[1]).toContain("AS distance_meters");
  });
});

describe("yakinVitrinleriGetir", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("geçerli koordinatla RPC ve ürün sorgularını çalıştırıp mesafeMetre ile döner", async () => {
    mockRpc.mockResolvedValue({
      data: [
        {
          id: "store-1",
          slug: "moda-kahve",
          name: "Moda Kahve",
          description: "Taze kavrum",
          address: "Moda Cad. 12",
          kategori: "kafe_lokanta",
          business_type: "kafe_lokanta",
          shelf_image_url: null,
          logo_url: "https://cdn.example.com/logo.png",
          province_name: "İstanbul",
          district_name: "Kadıköy",
          status: "Açık",
          is_demo: false,
          whatsapp: "05551112233",
          updated_at: "2026-11-21T10:00:00Z",
          rating_score: 4.8,
          show_storefront_rating: true,
          distance_meters: 352.4,
        },
      ],
      error: null,
    });
    mockProductsQuery([
      { store_id: "store-1", name: "Filtre Kahve" },
      { store_id: "store-1", name: "Latte" },
    ]);

    const vitrinler = await yakinVitrinleriGetir({
      lat: 40.986,
      lng: 29.028,
      radiusMeters: 2500,
    });

    expect(mockRpc).toHaveBeenCalledWith("search_nearby_stores", {
      p_lat: 40.986,
      p_lng: 29.028,
      p_radius_m: 2500,
      p_limit: 50,
    });
    expect(mockFrom).toHaveBeenCalledWith("products");
    expect(vitrinler).toHaveLength(1);
    expect(vitrinler[0]).toMatchObject({
      slug: "moda-kahve",
      ad: "Moda Kahve",
      konum: "Kadıköy, İstanbul",
      urunSayisi: 2,
      urunAdlari: ["Filtre Kahve", "Latte"],
      puan: 4.8,
      mesafeMetre: 352.4,
    });
  });

  it("boş sonuçta products tablosunu sorgulamadan boş dizi döner", async () => {
    mockRpc.mockResolvedValue({ data: [], error: null });

    const vitrinler = await yakinVitrinleriGetir({ lat: 41.0, lng: 29.0 });

    expect(vitrinler).toEqual([]);
    expect(mockFrom).not.toHaveBeenCalled();
  });

  it("geçersiz koordinatta RPC çağırmadan hata fırlatır", async () => {
    await expect(
      yakinVitrinleriGetir({ lat: 999, lng: 29 })
    ).rejects.toThrow("Geçersiz konum koordinatı");
    await expect(
      yakinVitrinleriGetir({ lat: 41, lng: -200 })
    ).rejects.toThrow("Geçersiz konum koordinatı");
    await expect(
      yakinVitrinleriGetir({ lat: Number.NaN, lng: 29 })
    ).rejects.toThrow("Geçersiz konum koordinatı");
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("RPC hatasında hata fırlatır", async () => {
    mockRpc.mockResolvedValue({ data: null, error: { message: "db error" } });

    await expect(
      yakinVitrinleriGetir({ lat: 41.0, lng: 29.0 })
    ).rejects.toThrow("Yakındaki vitrinler okunamadı");
  });
});

describe("GET /api/kesfet/yakin", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("geçersiz veya eksik koordinatlarda 400 döner ve RPC çağırmaz", async () => {
    const gecersizIstekler = [
      "http://localhost/api/kesfet/yakin",
      "http://localhost/api/kesfet/yakin?lat=&lng=29",
      "http://localhost/api/kesfet/yakin?lat=999&lng=29",
      "http://localhost/api/kesfet/yakin?lat=41&lng=181",
      "http://localhost/api/kesfet/yakin?lat=abc&lng=29",
      "http://localhost/api/kesfet/yakin?lat=41&lng=29&radius=-50",
      "http://localhost/api/kesfet/yakin?lat=41&lng=29&radius=abc",
    ];

    for (const url of gecersizIstekler) {
      const response = await GET(new NextRequest(url));
      expect(response.status).toBe(400);
    }
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it("geçerli koordinatta 200 ve vitrinler listesi döner", async () => {
    mockRpc.mockResolvedValue({
      data: [
        {
          id: "store-2",
          slug: "kadikoy-butik",
          name: "Kadıköy Butik",
          description: "Giyim",
          address: null,
          kategori: "butik",
          business_type: "butik",
          shelf_image_url: null,
          logo_url: null,
          province_name: "İstanbul",
          district_name: "Kadıköy",
          status: "Açık",
          is_demo: false,
          whatsapp: null,
          updated_at: "2026-11-21T10:00:00Z",
          rating_score: null,
          show_storefront_rating: false,
          distance_meters: 1420,
        },
      ],
      error: null,
    });
    mockProductsQuery([]);

    const response = await GET(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784&radius=3000")
    );
    const body = (await response.json()) as { vitrinler: { slug: string; mesafeMetre?: number }[] };

    expect(response.status).toBe(200);
    expect(mockRpc).toHaveBeenCalledWith("search_nearby_stores", {
      p_lat: 41.0082,
      p_lng: 28.9784,
      p_radius_m: 3000,
      p_limit: 50,
    });
    expect(body.vitrinler).toHaveLength(1);
    expect(body.vitrinler[0].slug).toBe("kadikoy-butik");
    expect(body.vitrinler[0].mesafeMetre).toBe(1420);
  });

  it("boş sonuçta 200 ve boş vitrinler dizisi döner", async () => {
    mockRpc.mockResolvedValue({ data: [], error: null });

    const response = await GET(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784")
    );
    const body = (await response.json()) as { vitrinler: unknown[] };

    expect(response.status).toBe(200);
    expect(body.vitrinler).toEqual([]);
  });

  it("RPC hatasında 500 döner", async () => {
    mockRpc.mockResolvedValue({ data: null, error: { message: "rpc failed" } });

    const response = await GET(
      new NextRequest("http://localhost/api/kesfet/yakin?lat=41.0082&lng=28.9784")
    );
    const body = (await response.json()) as { hata: string };

    expect(response.status).toBe(500);
    expect(body.hata).toBe("Yakındaki vitrinler yüklenemedi.");
  });
});

describe("Keşfet arayüz konum entegrasyonu sözleşmesi", () => {
  it("KesfetIcerik Yakınımdakiler düğmesini ve tarayıcı konum hatası uyarısını içerir", () => {
    expect(kesfetIcerikSource).toContain("Yakınımdakiler");
    expect(kesfetIcerikSource).toContain("navigator.geolocation.getCurrentPosition");
    expect(kesfetIcerikSource).toContain("/api/kesfet/yakin");
    expect(kesfetIcerikSource).toContain("PERMISSION_DENIED");
  });

  it("VitrinKarti opsiyonel mesafeMetre rozetini m ve km biçiminde gösterir", () => {
    expect(vitrinKartiSource).toContain("vitrin.mesafeMetre");
    expect(vitrinKartiSource).toContain("yuvarlanmis < 1000");
    expect(vitrinKartiSource).toContain("toFixed(1)} km");
  });
});
