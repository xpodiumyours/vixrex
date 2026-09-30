import { describe, expect, it, vi } from "vitest";

const onbellek = vi.hoisted(() => ({ revalidateTag: vi.fn() }));
vi.mock("next/cache", () => ({ revalidateTag: onbellek.revalidateTag }));

import { tuketicideGorunenler, vitrinOnbelleginiYenile } from "@/lib/vitrinYayinDogrula";

function adminIle(satirlar: unknown[] | null, hata: { message: string } | null = null) {
  const z: Record<string, unknown> = {};
  z.select = () => z;
  z.eq = () => z;
  z.in = async () => ({ data: satirlar, error: hata });
  return { from: () => z } as never;
}

describe("tüketicinin gördüğü sorgu doğrulaması", () => {
  it("vitrin sorgusunda çıkan, fiyatlı ve görselli ürün görünür sayılır", async () => {
    const sonuc = await tuketicideGorunenler(
      adminIle([{ id: "u1", name: "Takım", price_amount: 499, image_urls: ["https://depo.example/a.jpg"] }]),
      "store-1",
      ["u1"],
    );

    expect(sonuc?.get("u1")).toEqual({ gorunur: true });
  });

  it("sorguda çıkmayan, fiyatsız ya da görselsiz ürün görünür sayılmaz", async () => {
    const sonuc = await tuketicideGorunenler(
      adminIle([
        { id: "u2", name: "Fiyatsız", price_amount: null, image_urls: ["https://depo.example/a.jpg"] },
        { id: "u3", name: "Görselsiz", price_amount: 100, image_urls: [] },
      ]),
      "store-1",
      ["u1", "u2", "u3"],
    );

    expect(sonuc?.get("u1")?.gorunur).toBe(false);
    expect(sonuc?.get("u2")?.sebep).toContain("fiyat");
    expect(sonuc?.get("u3")?.sebep).toContain("fotoğraf");
  });

  it("sorgu hata verirse null döner; sahte 'görünmüyor' denmez", async () => {
    expect(await tuketicideGorunenler(adminIle(null, { message: "hata" }), "store-1", ["u1"])).toBeNull();
  });

  it("yayından sonra vitrin önbelleği yenilenir", () => {
    vitrinOnbelleginiYenile("deneme-vitrin");

    expect(onbellek.revalidateTag).toHaveBeenCalledWith("store-deneme-vitrin", { expire: 0 });
    expect(onbellek.revalidateTag).toHaveBeenCalledWith("products-deneme-vitrin", { expire: 0 });
  });
});
