import { describe, expect, it } from "vitest";
import {
  blogTaslagiUret,
  blogKonulariUret,
  tazelemeGerektirenler,
  BLOG_TAZELEME_GUN,
  type VitrinOzeti,
} from "@/lib/blogAsistan";
import {
  BLOG_BASLIK_EN_AZ,
  BLOG_BASLIK_EN_FAZLA,
  BLOG_EN_AZ_KELIME,
  BLOG_OZET_EN_AZ,
  BLOG_OZET_EN_FAZLA,
  BLOG_YAYIN_ESIGI,
  blogKelimeSayisi,
  blogSeoAnalizi,
  blogYayinEngelleri,
} from "@/lib/blogSeo";

const vitrin: VitrinOzeti = {
  slug: "kiralik-butik",
  ad: "Butik Kiralık",
  kategori: "kuaför",
  il: "İstanbul",
  ilce: "Kadıköy",
  adres: "Caferağa Mah. Moda Cad. No 1",
  calismaSaatleri: "09:00 - 19:00",
  whatsapp: "05551234567",
  urunler: ["Saç kesimi", "Bakım paketi"],
};

const bosVitrin: VitrinOzeti = {
  slug: "bos-vitrin",
  ad: "",
  kategori: "",
  urunler: [],
};

function analiz(vitrinOzeti: VitrinOzeti, konu: string) {
  const taslak = blogTaslagiUret(vitrinOzeti, konu);
  const girdi = {
    title: taslak.baslik,
    summary: taslak.ozet,
    content: taslak.icerik,
    topic: taslak.hedefKonu,
    city: taslak.hedefSehir,
    hasCover: false,
  };
  return { taslak, girdi };
}

describe("vitrin blog asistanı", () => {
  it("konuları yalnız vitrin verisinden üretir", () => {
    const konular = blogKonulariUret(vitrin);
    const metinler = konular.map((konu) => `${konu.konu} ${konu.baslik}`).join(" ");

    expect(metinler).toContain("Kadıköy");
    expect(metinler).toContain("kuaför");
    expect(konular.some((konu) => konu.baslik.includes("Saç kesimi"))).toBe(true);
    expect(metinler).not.toMatch(/%|\d+\s?(TL|₺)/);
  });

  it("ürün yoksa uydurmaz, kategoriye döner", () => {
    const konular = blogKonulariUret(bosVitrin);
    expect(konular.length).toBeGreaterThan(0);
    expect(konular.every((konu) => konu.baslik.length > 0)).toBe(true);
    expect(konular.some((konu) => /saç|bakım paketi/i.test(konu.baslik))).toBe(
      false,
    );
  });

  it("taslak yayın standardını geçer ve asgari puanı aşar", () => {
    for (const konu of blogKonulariUret(vitrin)) {
      const { taslak, girdi } = analiz(vitrin, konu.konu);
      expect(blogYayinEngelleri(girdi)).toEqual([]);
      expect(blogSeoAnalizi(girdi).score).toBeGreaterThanOrEqual(
        BLOG_YAYIN_ESIGI,
      );
      expect(taslak.baslik.length).toBeGreaterThanOrEqual(BLOG_BASLIK_EN_AZ);
      expect(taslak.baslik.length).toBeLessThanOrEqual(BLOG_BASLIK_EN_FAZLA);
      expect(taslak.ozet.length).toBeGreaterThanOrEqual(BLOG_OZET_EN_AZ);
      expect(taslak.ozet.length).toBeLessThanOrEqual(BLOG_OZET_EN_FAZLA);
      expect(blogKelimeSayisi(taslak.icerik)).toBeGreaterThanOrEqual(
        BLOG_EN_AZ_KELIME,
      );
    }
  });

  it("vitrin verisi boşken de standardı tutar", () => {
    const { taslak, girdi } = analiz(bosVitrin, "");
    expect(blogYayinEngelleri(girdi)).toEqual([]);
    expect(taslak.icerik).not.toContain("undefined");
    expect(taslak.icerik).not.toContain("null");
  });

  it("uydurma sayı, fiyat ve iddia üretmez", () => {
    const { taslak } = analiz(vitrin, "Kadıköy kuaför");
    expect(taslak.baslik).not.toMatch(/\d/);
    expect(taslak.icerik).not.toMatch(/%/);
    expect(taslak.icerik).not.toMatch(/\d+\s?(TL|₺)/);
    expect(taslak.icerik).not.toMatch(/araştırma|uzman onayı|istatistik/i);
  });

  it("kendi vitrinine ve yazı listesine bağlantı verir", () => {
    const { taslak } = analiz(vitrin, "Kadıköy kuaför");
    expect(taslak.icerik).toContain('href="/v/kiralik-butik"');
    expect(taslak.icerik).toContain('href="/v/kiralik-butik/yazilar"');
    expect(taslak.icerik).toContain("Saç kesimi");
  });

  it("aynı girdi için aynı taslağı üretir", () => {
    const birinci = blogTaslagiUret(vitrin, "Kadıköy kuaför");
    const ikinci = blogTaslagiUret(vitrin, "Kadıköy kuaför");
    expect(ikinci).toEqual(birinci);
  });

  it("uzun başlık ve özeti aralığa çeker", () => {
    const uzun: VitrinOzeti = {
      ...vitrin,
      ad: "Çok Uzun Bir İşletme Adı Buraya Yazıldığında Ne Olacak",
      kategori: "güzellik ve kişisel bakım merkezi işletmesi",
    };
    const { taslak, girdi } = analiz(uzun, "güzellik bakımı randevusu");
    expect(blogYayinEngelleri(girdi)).toEqual([]);
    expect(taslak.baslik.length).toBeLessThanOrEqual(BLOG_BASLIK_EN_FAZLA);
    expect(taslak.ozet.length).toBeLessThanOrEqual(BLOG_OZET_EN_FAZLA);
  });
});

describe("içerik tazeleme sinyali", () => {
  const simdi = Date.parse("2026-09-27T00:00:00Z");
  const gunOnce = (gun: number) =>
    new Date(simdi - gun * 86_400_000).toISOString();

  it("yayındaki bayat yazıları eskiyen sırayla bildirir", () => {
    const sonuc = tazelemeGerektirenler(
      [
        { slug: "a", title: "Eski", status: "published", updated_at: gunOnce(200) },
        { slug: "b", title: "Orta", status: "published", updated_at: gunOnce(BLOG_TAZELEME_GUN) },
        { slug: "c", title: "Yeni", status: "published", updated_at: gunOnce(10) },
        { slug: "d", title: "Taslak", status: "draft", updated_at: gunOnce(400) },
      ],
      BLOG_TAZELEME_GUN,
      simdi,
    );

    expect(sonuc.map((yazi) => yazi.slug)).toEqual(["a", "b"]);
    expect(sonuc[0].gun).toBe(200);
  });

  it("bozuk tarihi tazeleme nedeni saymaz", () => {
    const sonuc = tazelemeGerektirenler(
      [{ slug: "x", title: "Bozuk", status: "published", updated_at: "yok" }],
      BLOG_TAZELEME_GUN,
      simdi,
    );
    expect(sonuc).toEqual([]);
  });
});
