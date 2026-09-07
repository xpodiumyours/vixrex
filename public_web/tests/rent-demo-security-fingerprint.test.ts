import { afterEach, describe, expect, it, vi } from "vitest";
import { fingerprintClient } from "../src/lib/rentDemoSecurity";

// V-16 (attack-vectors.md, 2026-08-18): RATE_LIMIT_SECRET tanımsızken
// fingerprintClient ham IP'yi OLDUĞU GİBİ döndürüyordu — "ham IP
// veritabanına yazılmaz" sözünü bozuyordu (dönen değer start_demo_trial /
// consume_assistant_request'e p_client_key olarak gidiyor).

describe("fingerprintClient", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("RATE_LIMIT_SECRET varsa HMAC ile hash'ler — ham IP asla dönmez", () => {
    vi.stubEnv("RATE_LIMIT_SECRET", "test-secret-0123456789"); // gitleaks:allow
    const sonuc = fingerprintClient("1.2.3.4");
    expect(sonuc).not.toBe("1.2.3.4");
    expect(sonuc).toMatch(/^[0-9a-f]{64}$/);
  });

  it("secret yokken üretimde fail-closed olur (ham IP asla dönmez)", () => {
    vi.stubEnv("RATE_LIMIT_SECRET", "");
    vi.stubEnv("NODE_ENV", "production");
    expect(() => fingerprintClient("1.2.3.4")).toThrow(
      "RATE_LIMIT_SECRET is not configured in production"
    );
  });

  it("secret yokken yerelde/testte yine de ham IP dönmez (sabit tuzla hash'lenir)", () => {
    vi.stubEnv("RATE_LIMIT_SECRET", "");
    vi.stubEnv("NODE_ENV", "test");
    const sonuc = fingerprintClient("1.2.3.4");
    expect(sonuc).not.toBe("1.2.3.4");
    expect(sonuc).toMatch(/^[0-9a-f]{64}$/);
  });

  it("aynı IP her zaman aynı torbaya düşer (rate-limit tutarlılığı)", () => {
    vi.stubEnv("RATE_LIMIT_SECRET", "");
    vi.stubEnv("NODE_ENV", "test");
    expect(fingerprintClient("9.9.9.9")).toBe(fingerprintClient("9.9.9.9"));
  });
});
