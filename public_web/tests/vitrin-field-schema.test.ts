import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import {
  VITRIN_FIELDS,
  FIELD_BY_KEY,
  EDITABLE_COLUMNS,
  fieldsOfSection,
} from "../src/lib/vitrinFieldSchema";
import { validateField } from "../src/lib/vitrinFieldValidation";

// implementation_plan.md Commit 8.
// Şema tek kaynaktır; bu testler onun bozulmasını engeller.

describe("alan şeması — bütünlük", () => {
  it("anahtarlar benzersizdir", () => {
    const anahtarlar = VITRIN_FIELDS.map((f) => f.anahtar);
    expect(new Set(anahtarlar).size).toBe(anahtarlar.length);
  });

  it("kolonlar benzersizdir", () => {
    const kolonlar = VITRIN_FIELDS.map((f) => f.kolon);
    expect(new Set(kolonlar).size).toBe(kolonlar.length);
  });

  it("her alanın Türkçe etiketi vardır", () => {
    for (const f of VITRIN_FIELDS) {
      expect(f.etiket.trim().length, f.anahtar).toBeGreaterThan(0);
    }
  });

  it("hiçbir alan yasaklı kolona yazmaz", () => {
    // Veritabanı tarafındaki owner_forbidden_draft_keys() ile aynı liste.
    // İkisi ayrışırsa sunucu izin verir ama veritabanı reddeder; kullanıcı
    // sebebini anlamayan bir hata görür. Bu test o ayrışmayı yakalar.
    const yasakli = [
      "id", "slug", "edit_token", "user_id",
      "is_published", "status", "published_at",
      "is_demo", "is_premium", "premium_plan", "premium_expires_at",
      "version", "created_at", "updated_at",
      "rating_score", "review_count", "is_blog_trusted",
      "location_source", "location_accuracy_meters", "location_consent_at",
      "product_storage_version",
    ];
    for (const kolon of EDITABLE_COLUMNS) {
      expect(yasakli, `${kolon} yasaklı listede olmamalı`).not.toContain(kolon);
    }
  });

  it("yasal onay ve gizli alanlar şemada hiç geçmez", () => {
    const tehlikeli = /edit_token|privacy_notice|terms_|publication_consent/;
    for (const f of VITRIN_FIELDS) {
      expect(tehlikeli.test(f.kolon), `${f.anahtar} → ${f.kolon}`).toBe(false);
    }
  });

  it("FIELD_BY_KEY tüm alanları kapsar", () => {
    expect(FIELD_BY_KEY.size).toBe(VITRIN_FIELDS.length);
  });

  it("her alan bir bölüme aittir ve bölüm sorgusu çalışır", () => {
    const bolumler = new Set(VITRIN_FIELDS.map((f) => f.bolum));
    let toplam = 0;
    for (const b of bolumler) toplam += fieldsOfSection(b).length;
    expect(toplam).toBe(VITRIN_FIELDS.length);
  });
});

describe("alan doğrulama — tek fonksiyon, alan başına dallanma yok", () => {
  it("bilinmeyen alanı reddeder", () => {
    const r = validateField("boyleBirAlanYok", "x");
    expect(r.ok).toBe(false);
  });

  it("zorunlu alan boş bırakılamaz", () => {
    const r = validateField("isletmeAdi", "");
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.hata).toContain("boş bırakılamaz");
  });

  it("en az uzunluk uygulanır", () => {
    const r = validateField("isletmeAdi", "X");
    expect(r.ok).toBe(false);
  });

  it("en fazla uzunluk uygulanır", () => {
    const r = validateField("heroRozet", "a".repeat(61));
    expect(r.ok).toBe(false);
  });

  it("geçerli metni kabul eder ve kırpar", () => {
    const r = validateField("heroRozet", "  Kadıköy Servis  ");
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.deger).toBe("Kadıköy Servis");
  });

  it("zorunlu olmayan boş alan null döner (alanı temizler)", () => {
    const r = validateField("heroRozet", "");
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.deger).toBeNull();
  });

  it("telefon yalnız rakama indirgenir, kısa numara reddedilir", () => {
    const gecerli = validateField("whatsapp", "0555 123 45 67");
    expect(gecerli.ok).toBe(true);
    if (gecerli.ok) expect(gecerli.deger).toBe("05551234567");

    expect(validateField("whatsapp", "12345").ok).toBe(false);
  });

  it("e-posta biçimi denetlenir", () => {
    expect(validateField("eposta", "bozukadres").ok).toBe(false);
    expect(validateField("eposta", "servis@fixtech.com").ok).toBe(true);
  });

  it("url yalnız http/https veya sayfa içi çapa kabul eder", () => {
    expect(validateField("website", "https://vixrex.com").ok).toBe(true);
    expect(validateField("galeriAksiyonLinki", "#iletisim").ok).toBe(true);
    expect(validateField("website", "javascript:alert(1)").ok).toBe(false);
    expect(validateField("website", "ftp://sunucu/dosya").ok).toBe(false);
  });

  it("sayı alanı sınırları uygulanır", () => {
    expect(validateField("enlem", 41.015).ok).toBe(true);
    expect(validateField("enlem", 120).ok).toBe(false);
    expect(validateField("boylam", "28,974").ok).toBe(true); // virgüllü ondalık
    expect(validateField("enlem", "sayi degil").ok).toBe(false);
  });

  it("açık/kapalı yalnız boolean kabul eder", () => {
    expect(validateField("puanGoster", true).ok).toBe(true);
    expect(validateField("puanGoster", "evet").ok).toBe(false);
  });
});

describe("Commit 8 kabul ölçütü — yeni alan kod değişikliği istemez", () => {
  const validationSource = readFileSync(
    resolve(__dirname, "../src/lib/vitrinFieldValidation.ts"),
    "utf-8"
  );
  const routeSource = readFileSync(
    resolve(__dirname, "../src/app/api/owner-draft/route.ts"),
    "utf-8"
  );

  it("doğrulayıcı alan ADINA göre dallanmaz, yalnız TİPE göre dallanır", () => {
    // Alan başına dallanma yazılmışsa burada yakalanır. Referans
    // sablonlar/hedef-vitrin.html'de sekiz elle yazılmış dal var ve bu yüzden
    // orada yalnız dokuz alan düzenlenebiliyor; Hakkımızda ve SSS tıklanamıyor.
    //
    // Not: bazı alan adları tip adlarıyla çakışır (örn. "telefon" hem alan
    // hem tip). O yüzden metinde geçip geçmediğine değil, ANAHTARA GÖRE
    // KARŞILAŞTIRMA yapılıp yapılmadığına bakılır.
    // Gerçek alan adlarıyla karşılaştırma aranır; `=== "string"` gibi tip
    // kontrolleri yanlış alarm vermesin diye anahtarlar listeden gelir.
    const anahtarlar = VITRIN_FIELDS.map((f) => f.anahtar).join("|");
    const alanDallanmasi = new RegExp(
      `anahtar\\s*===\\s*["'](${anahtarlar})["']`
    );

    expect(validationSource).not.toMatch(alanDallanmasi);
    expect(validationSource).not.toMatch(/switch\s*\(\s*(alan\.)?anahtar\s*\)/);
    // Tipe göre dallanma ise beklenen davranıştır.
    expect(validationSource).toMatch(/switch\s*\(\s*alan\.tip\s*\)/);
  });

  it("API ucu alan adına göre dallanmaz", () => {
    const anahtarlar = VITRIN_FIELDS.map((f) => f.anahtar).join("|");
    const alanDallanmasi = new RegExp(
      `anahtar\\s*===\\s*["'](${anahtarlar})["']`
    );

    expect(routeSource).not.toMatch(alanDallanmasi);
    expect(routeSource).not.toMatch(/switch\s*\(\s*anahtar\s*\)/);
    // Anahtar yalnız şemaya sorulur, koşula sokulmaz.
    expect(routeSource).toContain("validateField(anahtar,");
  });

  it("şemaya eklenen alan başka dosya değişmeden doğrulanabilir", () => {
    // Şemadaki HER alan, doğrulayıcıdan geçebilmeli. Yeni bir alan
    // eklendiğinde bu test onu kendiliğinden kapsar.
    for (const f of VITRIN_FIELDS) {
      const ornek =
        f.tip === "acikKapali"
          ? true
          : f.tip === "sayi"
          ? 0
          : f.tip === "eposta"
          ? "ornek@vixrex.com"
          : f.tip === "url" || f.tip === "gorsel"
          ? "https://vixrex.com/x.png"
          : f.tip === "telefon"
          ? "05551234567"
          : f.tip === "secim"
          ? (f.secenekler?.[0] ?? "Örnek")
          : "Örnek";
      const r = validateField(f.anahtar, ornek);
      expect(r.ok, `${f.anahtar} (${f.tip}) doğrulanamadı`).toBe(true);
    }
  });
});

describe("owner-draft ucu — güvenlik sözleşmesi", () => {
  const routeSource = readFileSync(
    resolve(__dirname, "../src/app/api/owner-draft/route.ts"),
    "utf-8"
  );

  it("oturum yalnız çerezden okunur, istek gövdesinden token kabul edilmez", () => {
    expect(routeSource).toContain("cookieStore.get(OWNER_SESSION_COOKIE)");
    expect(routeSource).toContain("verifyOwnerSession(ownerSessionCookie, slug)");
    expect(routeSource).not.toContain("govde.sessionToken");
    expect(routeSource).not.toContain("govde.token");
  });

  it("service-role anahtarı kullanılmaz", () => {
    expect(routeSource).not.toContain("SERVICE_ROLE");
    expect(routeSource).not.toContain("supabaseAdmin");
  });

  it("RPC'ye şemadan gelen kolon adı gider, kullanıcının yazdığı anahtar değil", () => {
    expect(routeSource).toContain("p_key: sonuc.alan.kolon");
  });

  it("oturum tokenı ve alan değeri loglanmaz", () => {
    expect(routeSource).not.toContain("console.log");
    expect(routeSource).not.toContain("console.error(sonuc");
    expect(routeSource).toContain("console.error(\"[owner-draft] update failed:\", error.message)");
  });
});
