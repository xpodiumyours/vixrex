import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
}

const kart = yorumsuz(
  readFileSync(
    resolve(__dirname, "../src/components/kesfet/VitrinKarti.tsx"),
    "utf-8"
  )
);
const seritKaynak = yorumsuz(
  readFileSync(
    resolve(__dirname, "../src/components/kesfet/KategoriSeridi.tsx"),
    "utf-8"
  )
);

/**
 * Keşfet kartındaki "Kirala" düğmesi — vitrin sayfasındaki CTA ile aynı
 * kuralı taşır (bkz. demo-kirala-cta-contract.test.ts).
 *
 * 2026-08-15'te kapatılan açık: `/api/rent-demo` GET'te hiçbir kimlik ya da
 * oran sınırlaması olmadan veritabanına yazıyordu.
 *
 * Faz C3 (Tek Asistan planı, 2026-09-02): "Kirala" artık `/rent-demo`
 * köprü SAYFASINA yönlendirmiyor — Keşfet'ten ayrılmadan aynı akışı
 * (useKesfetKirala.ts) yerinde çalıştırıyor. Bu, `/api/rent-demo`'ya
 * doğrudan referans vermeyi ZORUNLU kılıyor — eski "hiç geçmesin"
 * kuralı artık uygulanamaz. Güvenlik doğrulandı (api/rent-demo/route.ts
 * okunarak): asıl zorunlu kapı reCAPTCHA DEĞİL — client IP'nin HMAC
 * parmak izi + `start_demo_trial` RPC'sindeki üç katmanlı oran sınırı
 * (3/10dk, 10/gün, 100/saat). reCAPTCHA yalnız ek/yumuşak sinyal,
 * başarısız olsa bile akış devam eder. Yani gerçek koruma HANGİ
 * bileşenin `/api/rent-demo`'yu andığına değil, isteğin native
 * `<form method="POST">` ile (fetch/GET değil) gitmesine bağlı — test
 * artık BUNU zorunlu kılıyor.
 */
describe("Keşfet kartı 'Kirala' CTA'sı", () => {
  it("native form POST ile gider — fetch/GET ile değil (2026-08-15 açığı tekrarlanmaz)", () => {
    expect(kart).toContain('<form ref={kiralaFormRef} method="POST" action="/api/rent-demo"');
    // GET'e düşecek çıplak bir <a href="/api/rent-demo"> veya fetch(GET) yok.
    expect(kart).not.toMatch(/href=["'`]\/api\/rent-demo/);
    expect(kart).not.toContain('fetch("/api/rent-demo"');
  });

  it("reCAPTCHA token'ı forma taşıyor (yumuşak sinyal, ama taşınmalı)", () => {
    expect(kart).toContain('name="recaptchaToken"');
  });

  it("fiyat vaadi vitrin CTA'sıyla aynı", () => {
    expect(kart).toContain("Aylık 299 TL");
    expect(kart).toContain("14 gün ücretsiz dene");
  });

  it("kiralık ayrımı is_demo'dan gelen alana bakar", () => {
    expect(kart).toContain("vitrin.kiralikMi");
  });
});

/**
 * Kategori süzgeci SEO ve erişilebilirlik sözleşmesi.
 *
 * Kategori süzgeci, arama motorlarının tüm kategori sayfalarını
 * keşfedebilmesi için düz <Link> kullanır. JavaScript filtresi
 * kategorileri robotlardan gizler — bu yüzden "use client" yasaktır.
 *
 * Ayrıca erişilebilirlik için <nav> + aria-label zorunludur.
 */
describe("Kategori süzgeci SEO + erişilebilirlik", () => {
  it("istemci bileşeni değil — arama motorundan gizlenmez", () => {
    expect(seritKaynak).not.toContain('"use client"');
  });

  it("<nav> ve aria-label ile sarılmış — ekran okuyucu tanır", () => {
    expect(seritKaynak).toContain("<nav");
    expect(seritKaynak).toContain('aria-label="Kategoriler"');
  });

  it("Tumu linki yok — varsayılan olarak tüm kategoriler gösterilir", () => {
    // KategoriSeridi artık "Tümü" linki içermez; tüm vitrinler varsayılan
    // olarak gösterilir, aktif kategori yoksa hepsi görünür.
    expect(seritKaynak).not.toContain('">Tümü</');
  });

  it("her kategori kendi düz linkine sahip — taranabilir sayfa üretir", () => {
    // KategoriSync kullanici tarafinda kategoriUrlParcasi() cagrisi yapiyor
    // ve BUSINESS_CATEGORIES uzerinde donup her biri icin Link uretiyor.
    expect(seritKaynak).toContain("kategoriUrlParcasi(kategori.id)");
    expect(seritKaynak).toContain("BUSINESS_CATEGORIES.map");
  });

  it("tireli URL üretir — alt çizgi kullanmaz", () => {
    // Google alt çizgiyi kelime birleştirici sayar, tireyi ayırıcı.
    expect(seritKaynak).toContain("kategoriUrlParcasi");
    expect(seritKaynak).not.toContain("/kesfet/kafe_lokanta");
  });

  it("aktif kategori aria-current ile işaretlenir", () => {
    expect(seritKaynak).toContain("aria-current");
    expect(seritKaynak).toContain("aktifKimlik");
  });
});
