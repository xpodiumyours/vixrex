import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import { createHmac } from "node:crypto";
import {
  OWNER_SESSION_COOKIE,
  signOwnerSession,
  verifyOwnerSession,
} from "../src/lib/ownerSession";
import proxy from "../src/proxy";
import { NextRequest } from "next/server";

/**
 * implementation_plan.md Commit 4 & 7: sahip kodu değişimi ve güvenli çerez.
 *
 * Davranış testleri imzalı çerezin slug'a ve süreye bağlı olduğunu, kurcalanmış
 * veya süresi dolmuş değerin reddedildiğini kilitler. Kaynak sözleşme testleri
 * giriş rotasının tek kullanımlık kodu tükettiğini, güvenli çerezi kurduğunu,
 * temiz URL'ye yönlendirdiğini ve hatalı kodu açık hata durumuyla reddettiğini
 * doğrular.
 */

const SECRET = "test-owner-session-secret-0123456789abcdef";
const STORE_ID = "11111111-1111-1111-1111-111111111111";
const SLUG = "deneme-vitrin";

// Geçerli 64 hex char (32 byte) session token for tests
const TEST_SESSION_TOKEN = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

function b64url(value: string): string {
  return Buffer.from(value, "utf8").toString("base64url");
}

describe("sahip oturumu çerezi — imzalı değer davranışı", () => {
  beforeEach(() => {
    vi.stubEnv("OWNER_SESSION_SECRET", SECRET);
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("çerez adı sabittir: vixrex_owner_session", () => {
    expect(OWNER_SESSION_COOKIE).toBe("vixrex_owner_session");
  });

  it("geçerli çerez doğrulanır ve vitrin/store kimliğini + sessionToken döner", () => {
    const token = signOwnerSession(STORE_ID, SLUG, TEST_SESSION_TOKEN);
    expect(verifyOwnerSession(token, SLUG)).toEqual({
      storeId: STORE_ID,
      slug: SLUG,
      sessionToken: TEST_SESSION_TOKEN,
    });
  });

  it("geçersiz sessionToken (kısa) ile imzalama başarısız olur", () => {
    expect(() => signOwnerSession(STORE_ID, SLUG, "kisa")).toThrow(
      "sessionToken must be 64 hex characters"
    );
  });

  it("geçersiz sessionToken (non-hex) ile imzalama başarısız olur", () => {
    expect(() => signOwnerSession(STORE_ID, SLUG, "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg")).toThrow(
      "sessionToken must be 64 hex characters"
    );
  });

  it("bir vitrin için üretilen çerez başka slug'ta kullanılamaz", () => {
    const token = signOwnerSession(STORE_ID, SLUG, TEST_SESSION_TOKEN);
    expect(verifyOwnerSession(token, "baska-vitrin")).toBeNull();
  });

  it("imzası bozulmuş çerez reddedilir", () => {
    const token = signOwnerSession(STORE_ID, SLUG, TEST_SESSION_TOKEN);
    const tampered = token.slice(0, -4) + "aaaa";
    expect(verifyOwnerSession(tampered, SLUG)).toBeNull();
  });

  it("süresi dolmuş çerez reddedilir", () => {
    const payload = b64url(
      JSON.stringify({ storeId: STORE_ID, slug: SLUG, sessionToken: TEST_SESSION_TOKEN, exp: Date.now() - 1000 })
    );
    const signature = createHmac("sha256", SECRET)
      .update(payload)
      .digest("base64url");
    expect(verifyOwnerSession(`${payload}.${signature}`, SLUG)).toBeNull();
  });

  it("eksik veya bozuk çerez reddedilir", () => {
    expect(verifyOwnerSession(undefined, SLUG)).toBeNull();
    expect(verifyOwnerSession("", SLUG)).toBeNull();
    expect(verifyOwnerSession("noluyor", SLUG)).toBeNull();
    expect(verifyOwnerSession("a.b.c", SLUG)).toBeNull();
  });

  it("gizli anahtar yokken imzalama başarısız, doğrulama güvenli kapalıdır", () => {
    vi.stubEnv("OWNER_SESSION_SECRET", "");
    expect(() => signOwnerSession(STORE_ID, SLUG, TEST_SESSION_TOKEN)).toThrow(
      "OWNER_SESSION_SECRET"
    );
    expect(verifyOwnerSession("gecerli.gorunen", SLUG)).toBeNull();
  });

  it("32 karakterden kısa gizli anahtarı reddeder", () => {
    vi.stubEnv("OWNER_SESSION_SECRET", "cok-kisa-secret");
    expect(() => signOwnerSession(STORE_ID, SLUG, TEST_SESSION_TOKEN)).toThrow(
      "at least 32 characters"
    );
    expect(verifyOwnerSession("gecerli.gorunen", SLUG)).toBeNull();
  });

  it("sessionToken olmadan imzalama başarısız olur", () => {
    // @ts-expect-error testing missing arg
    expect(() => signOwnerSession(STORE_ID, SLUG)).toThrow(
      "sessionToken must be 64 hex characters"
    );
  });
});

describe("sahip oturumu giriş rotası — tek kullanımlık kod değişimi", () => {
  const routeSource = readFileSync(
    resolve(__dirname, "../src/app/api/owner-session/route.ts"),
    "utf-8"
  );

  it("kodu consume_owner_session ile sunucu tarafında doğrular", () => {
    expect(routeSource).toContain('supabase.rpc("consume_owner_session"');
    expect(routeSource).toContain("p_slug: slug");
    expect(routeSource).toContain("p_code: code");
  });

  it("gizli anahtarı tek kullanımlık kodu tüketmeden önce doğrular", () => {
    const configurationCheck = routeSource.indexOf(
      "assertOwnerSessionConfigured()"
    );
    const codeConsumption = routeSource.indexOf(
      'supabase.rpc("consume_owner_session"'
    );

    expect(configurationCheck).toBeGreaterThan(-1);
    expect(codeConsumption).toBeGreaterThan(configurationCheck);
  });

  it("başarıda HttpOnly, Secure, SameSite=Lax sahip çerezi kurar", () => {
    expect(routeSource).toContain("response.cookies.set(OWNER_SESSION_COOKIE");
    expect(routeSource).toContain("httpOnly: true");
    expect(routeSource).toContain("secure: true");
    expect(routeSource).toContain('sameSite: "lax"');
    expect(routeSource).toContain('path: "/"');
    expect(routeSource).toContain("maxAge: OWNER_SESSION_MAX_AGE_SECONDS");
  });

  it("gizli sorgu değerini adres çubuğundan kaldırarak temiz /v/:slug'a yönlendirir", () => {
    expect(routeSource).toContain("NextResponse.redirect(destination, 303)");
    expect(routeSource).toContain("new URL(`/v/${slug}`, url)");
  });

  it("hatalı, kullanılmış veya süresi dolmuş kodu açık hata durumuyla reddeder", () => {
    expect(routeSource).toContain("INVALID_OR_EXPIRED_OWNER_CODE");
    expect(routeSource).toContain("status: 400");
    expect(routeSource).toContain('"cache-control": "no-store"');
  });

  it("giriş rotası önbelleğe alınmaz (force-dynamic)", () => {
    expect(routeSource).toContain('export const dynamic = "force-dynamic"');
    expect(routeSource).toContain('response.headers.set("cache-control", "no-store")');
  });
});

describe("sahip oturumu proxy katmanı — yanıt önbelleği", () => {
  const proxySource = readFileSync(
    resolve(__dirname, "../src/proxy.ts"),
    "utf-8"
  );

  beforeEach(() => {
    vi.stubEnv("OWNER_SESSION_SECRET", SECRET);
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  function requestWith(
    token?: string,
    slug = SLUG,
    incomingOwnerHeader?: string
  ): NextRequest {
    const headers = new Headers();
    if (token) headers.set("cookie", `${OWNER_SESSION_COOKIE}=${token}`);
    if (incomingOwnerHeader) {
      headers.set("x-owner-mode", incomingOwnerHeader);
    }
    return new NextRequest(`https://vixrex.app/v/${slug}`, { headers });
  }

  it("yalnız geçerli ve aynı slug'a bağlı çerez için sahip modunu açar", () => {
    const response = proxy(requestWith(signOwnerSession(STORE_ID, SLUG, TEST_SESSION_TOKEN)));

    expect(response.headers.get("cache-control")).toBe("private, no-store");
    expect(response.headers.get("x-middleware-request-x-owner-mode")).toBe("1");
  });

  it("çerez yoksa istemcinin gönderdiği sahte sahip başlığını siler", () => {
    const response = proxy(requestWith(undefined, SLUG, "1"));

    expect(response.headers.get("cache-control")).toBeNull();
    expect(response.headers.get("x-middleware-request-x-owner-mode")).toBeNull();
    expect(response.headers.get("x-middleware-request-x-owner-mode")).not.toBe("1");
  });

it("başka slug'a ait çerezle sahip modunu açmaz", () => {
    const token = signOwnerSession(STORE_ID, SLUG, TEST_SESSION_TOKEN);
    const response = proxy(requestWith(token, "baska-vitrin", "1"));

    expect(response.headers.get("cache-control")).toBeNull();
    expect(response.headers.get("x-middleware-request-x-owner-mode")).toBeNull();
    expect(response.headers.get("x-middleware-request-x-owner-mode")).not.toBe("1");
  });

  it("yalnız vitrin yollarında (/v/:path*) çalışır", () => {
    expect(proxySource).toContain('matcher: ["/v/:path*"]');
  });

  it("sahip isteğine x-owner-mode işaretini ekler", () => {
    expect(proxySource).toContain("verifyOwnerSession(ownerToken, slug)");
    expect(proxySource).toContain('requestHeaders.delete("x-owner-mode")');
    expect(proxySource).toContain('requestHeaders.set("x-owner-mode", "1")');
  });
});

describe("sahip oturumu sayfa meta — müşteri SEO davranışı korunur", () => {
  const pageSource = readFileSync(
    resolve(__dirname, "../src/app/v/[slug]/page.tsx"),
    "utf-8"
  );

  it("sahip çerezi doğrulanan sayfa arama motorlarına kapatılır", () => {
    expect(pageSource).toContain(
      "verifyOwnerSession(ownerToken, params.slug)"
    );
    expect(pageSource).toContain(
      "return { robots: { index: false, follow: false } };"
    );
  });

  it("sahip görünümü Google'a kapalı, müşteri görünümü açık kalır", () => {
    // Commit 12'de değişti: eskiden noindex kararı preview_token'a bakıyordu.
    // O yol kaldırıldı; karar artık doğrulanmış sahip oturumuna bakıyor.
    //
    // Koruma aynı: sahip kendi taslağını görürken sayfa Google'a
    // kapatılmalı, yoksa yayınlanmamış içerik aramada çıkar. Müşteri
    // görünümü ise indekslenmeye devam etmeli — vitrinin bulunması
    // ürünün tüm amacı.
    const metadataBlock = pageSource.slice(
      pageSource.indexOf("export async function generateMetadata"),
      pageSource.indexOf("export default async function StorePage")
    );

    expect(metadataBlock).toContain("verifyOwnerSession(ownerToken, params.slug)");
    expect(metadataBlock).toContain("if (ownerSession) {");
    expect(metadataBlock).toContain("robots: { index: false, follow: false }");
    expect(metadataBlock).not.toContain("preview_token");
  });
});
