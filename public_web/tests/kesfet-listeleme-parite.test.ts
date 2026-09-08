import { beforeEach, describe, expect, it, vi } from "vitest";
import { EXPLORE_STORE_SELECT } from "@/lib/publicStoreSelect";

const mocks = vi.hoisted(() => ({
  from: vi.fn(),
  storeSelect: vi.fn(),
  storeEq: vi.fn(),
  storeOrder: vi.fn(),
  storeLimit: vi.fn(),
  productSelect: vi.fn(),
  productIn: vi.fn(),
  productEqActive: vi.fn(),
  productEqVisible: vi.fn(),
}));

vi.mock("next/cache", () => ({
  unstable_cache: (loader: () => unknown) => loader,
}));

vi.mock("@/lib/supabase", () => ({
  supabase: { from: mocks.from },
}));

import {
  KESFET_LIMIT,
  kategoriVitrinleriniGetir,
  kesfetVitrinleriniGetir,
} from "@/lib/explore";

const storeRows = [
  {
    id: "s1",
    slug: "teknofix",
    name: "Teknofix",
    description: "Aynı gün cihaz onarımı",
    address: "Kadıköy",
    kategori: "teknik_servis",
    business_type: null,
    shelf_image_url: "https://example.com/cover.jpg",
    logo_url: null,
    province_name: "İstanbul",
    district_name: "Kadıköy",
    status: "Açık",
    is_demo: false,
    whatsapp: "905551112233",
    updated_at: "2026-09-08T10:00:00Z",
  },
  {
    id: "s2",
    slug: "aymira",
    name: "Aymira",
    description: "Yeni sezon",
    address: "",
    kategori: "giyim",
    business_type: null,
    shelf_image_url: null,
    logo_url: "https://example.com/logo.jpg",
    province_name: "Ankara",
    district_name: "Çankaya",
    status: "Kapalı",
    is_demo: true,
    whatsapp: null,
    updated_at: "2026-09-07T10:00:00Z",
  },
  {
    id: "bos",
    slug: "   ",
    name: "Slug yok",
    description: "",
    address: "",
    kategori: null,
    business_type: null,
    shelf_image_url: null,
    logo_url: null,
    province_name: null,
    district_name: null,
    status: null,
    is_demo: false,
    whatsapp: null,
    updated_at: null,
  },
];

beforeEach(() => {
  vi.clearAllMocks();

  mocks.storeSelect.mockReturnValue({ eq: mocks.storeEq });
  mocks.storeEq.mockReturnValue({ order: mocks.storeOrder });
  mocks.storeOrder.mockReturnValue({ limit: mocks.storeLimit });
  mocks.storeLimit.mockResolvedValue({ data: storeRows, error: null });

  mocks.productSelect.mockReturnValue({ in: mocks.productIn });
  mocks.productIn.mockReturnValue({ eq: mocks.productEqActive });
  mocks.productEqActive.mockReturnValue({ eq: mocks.productEqVisible });
  mocks.productEqVisible.mockResolvedValue({
    data: [
      { store_id: "s1", name: "OLED ekran değişimi" },
      { store_id: "s1", name: "Batarya" },
      { store_id: "s2", name: "Keten gömlek" },
    ],
    error: null,
  });

  mocks.from.mockImplementation((table: string) => {
    if (table === "stores") return { select: mocks.storeSelect };
    if (table === "products") return { select: mocks.productSelect };
    throw new Error(`Beklenmeyen tablo: ${table}`);
  });
});

describe("kesfet listeleme — gerçek veri katmanı davranışı", () => {
  it("yayın filtresi, sıralama, limit ve ürün filtrelerini gerçekten kurar", async () => {
    await kesfetVitrinleriniGetir();

    expect(mocks.from).toHaveBeenNthCalledWith(1, "stores");
    expect(mocks.storeSelect).toHaveBeenCalledWith(EXPLORE_STORE_SELECT);
    expect(mocks.storeEq).toHaveBeenCalledWith("is_published", true);
    expect(mocks.storeOrder).toHaveBeenCalledWith("updated_at", {
      ascending: false,
    });
    expect(KESFET_LIMIT).toBe(50);
    expect(mocks.storeLimit).toHaveBeenCalledWith(50);

    expect(mocks.from).toHaveBeenNthCalledWith(2, "products");
    expect(mocks.productSelect).toHaveBeenCalledWith("store_id,name");
    expect(mocks.productIn).toHaveBeenCalledWith("store_id", ["s1", "s2"]);
    expect(mocks.productEqActive).toHaveBeenCalledWith("is_active", true);
    expect(mocks.productEqVisible).toHaveBeenCalledWith("is_visible", true);
  });

  it("sorgu sonucunu Keşfet kart modeline gerçekten dönüştürür", async () => {
    const sonuc = await kesfetVitrinleriniGetir();

    expect(sonuc).toHaveLength(2);
    expect(sonuc[0]).toMatchObject({
      slug: "teknofix",
      ad: "Teknofix",
      kategoriEtiketi: "Teknik Servis",
      kategoriKimligi: "teknik_servis",
      kapakUrl: "https://example.com/cover.jpg",
      konum: "Kadıköy, İstanbul",
      kiralikMi: false,
      acikMi: true,
      urunSayisi: 2,
      urunAdlari: ["OLED ekran değişimi", "Batarya"],
      whatsapp: "905551112233",
    });
    expect(sonuc[1]).toMatchObject({
      slug: "aymira",
      kategoriKimligi: "giyim",
      kapakUrl: "https://example.com/logo.jpg",
      kiralikMi: true,
      acikMi: false,
      urunSayisi: 1,
    });
    expect(sonuc.some((vitrin) => vitrin.ad === "Slug yok")).toBe(false);
  });

  it("kategori yardımcı fonksiyonu gerçek listeyi süzer ve veri hatasında boş döner", async () => {
    const liste = [
      { kategoriKimligi: "giyim", slug: "a" },
      { kategoriKimligi: "teknik_servis", slug: "b" },
    ] as never[];

    await expect(
      kategoriVitrinleriniGetir("giyim", async () => liste),
    ).resolves.toEqual([liste[0]]);

    await expect(
      kategoriVitrinleriniGetir("giyim", async () => {
        throw new Error("veri yok");
      }),
    ).resolves.toEqual([]);
  });
});
