import { afterEach, describe, expect, it, vi } from "vitest";
import {
  BLOG_YAZILARI,
  blogOnizlemeMi,
  yayindakiYazilar,
  type BlogListeYazisi,
} from "@/data/blogYazilari";
import { blogYazilariniFiltrele } from "@/lib/blogKesif";

const liste: BlogListeYazisi[] = BLOG_YAZILARI.map((yazi) => ({
  ...yazi,
  yayinTarihi: "2026-09-11",
  okumaDakika: 3,
}));
afterEach(() => vi.unstubAllEnvs());

describe("blog keşfi ve önizleme sınırı", () => {
  it("Türkçe karakter kullanılmayan aramayı bulur", () => {
    expect(
      blogYazilariniFiltrele(liste, "KUAFOR", "Tümü").some(
        (yazi) => yazi.slug === "kuafor-icin-internet-sitesi",
      ),
    ).toBe(true);
    expect(
      blogYazilariniFiltrele(liste, "musteri ILETISIMI", "Tümü").length,
    ).toBeGreaterThan(0);
  });
  it("kategori ile arama birlikte uygulanır ve boş sonuç gizlenmez", () => {
    expect(
      blogYazilariniFiltrele(liste, "kuafor", "Google ve Keşfedilme"),
    ).toEqual([]);
    expect(blogYazilariniFiltrele(liste, "", "Tümü")).toHaveLength(
      liste.length,
    );
    expect(blogYazilariniFiltrele(liste, "bulunmayan-sozcuk", "Tümü")).toEqual(
      [],
    );
  });
  it("içerik türüne göre haber veya hikâye saklamaz", () => {
    const haber = { ...liste[0], slug: "haber", icerikTuru: "haber" as const };
    const hikaye = {
      ...liste[0],
      slug: "hikaye",
      icerikTuru: "isletme_hikayesi" as const,
    };
    expect(blogYazilariniFiltrele([haber, hikaye], "", "Tümü")).toHaveLength(2);
  });
  it("üretimde önizleme değişkeni taslakları açamaz", () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("BLOG_ONIZLEME", "1");
    expect(blogOnizlemeMi()).toBe(false);
    for (const yazi of yayindakiYazilar())
      expect(yazi.yayinda && yazi.durum !== "taslak").toBe(true);
    expect(yayindakiYazilar()).toHaveLength(0);
  });
  it("yerel önizleme taslak kaynağını değiştirmez", () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("BLOG_ONIZLEME", "1");
    expect(yayindakiYazilar()).toHaveLength(BLOG_YAZILARI.length);
    expect(
      BLOG_YAZILARI.every((yazi) => !yazi.yayinda && yazi.durum === "taslak"),
    ).toBe(true);
  });
});
