import { expect, it, vi } from "vitest";
import { kaynakGorselleriniHazirla, sayfaGorselAlanAdlari } from "@/lib/faturaGorsel";

const depo = {
  storage: {
    from: () => ({
      upload: async () => ({ error: null }),
      getPublicUrl: (yol: string) => ({ data: { publicUrl: `https://depo.example/${yol}` } }),
    }),
  },
};

it("üretici alan adı dışındaki görsel kaynak-uyumsuz diye reddedilir", async () => {
  const fetcher = vi.fn();
  const sonuc = await kaynakGorselleriniHazirla({
    admin: depo as never,
    slug: "deneme",
    kaynakSayfa: "https://uretici.example/urun",
    adaylar: ["https://pazaryeri.example/urun.jpg"],
    izinliAlanAdlari: ["uretici.example"],
    bagimliliklar: { fetcher: fetcher as never },
  });
  expect(sonuc.reddedilenler).toEqual([
    { kaynakGorsel: "https://pazaryeri.example/urun.jpg", sebep: "kaynak-uyumsuz" },
  ]);
  expect(fetcher).not.toHaveBeenCalled();
});

it("resmî sayfanın og:image alan adı izin listesine katılır", async () => {
  const fetcher = vi.fn(async () => new Response(
    '<html><head><meta property="og:image" content="https://cdn.myikas.com/urun.webp"/></head></html>',
    { status: 200, headers: { "content-type": "text/html" } },
  ));
  const alanlar = await sayfaGorselAlanAdlari("https://sehermensucat.com/urun", fetcher as never);
  expect([...alanlar].sort()).toEqual(["cdn.myikas.com", "sehermensucat.com"]);
});

it("alt alan adı üretici alanına aitse reddedilmez, indirilmeye çalışılır", async () => {
  const fetcher = vi.fn(async () => new Response("yok", { status: 500 }));
  const sonuc = await kaynakGorselleriniHazirla({
    admin: depo as never,
    slug: "deneme",
    kaynakSayfa: "https://uretici.example/urun",
    adaylar: ["https://cdn.uretici.example/urun.jpg"],
    izinliAlanAdlari: ["uretici.example"],
    bagimliliklar: { fetcher: fetcher as never },
  });
  expect(fetcher).toHaveBeenCalled();
  expect(sonuc.reddedilenler[0]?.sebep).toBe("erisilemedi");
});
