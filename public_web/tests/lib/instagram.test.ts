import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  sha256,
  encodeInstagramState,
  decodeInstagramState,
  encryptSecret,
  decryptSecret,
  getInstagramScopes,
  sanitizeInstagramMedia,
  fromBase64Url,
  type InstagramStatePayload,
} from "@/lib/instagram";

const TEST_STATE_SECRET = "test_state_secret_1234567890123456";
const TEST_ENCRYPTION_KEY = Buffer.from("12345678901234567890123456789012").toString("base64");

beforeEach(() => {
  vi.stubEnv("INSTAGRAM_STATE_SECRET", TEST_STATE_SECRET);
  vi.stubEnv("INSTAGRAM_TOKEN_ENCRYPTION_KEY", TEST_ENCRYPTION_KEY);
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("sha256", () => {
  it("returns a consistent hex hash", () => {
    expect(sha256("hello")).toBe("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824");
  });

  it("produces different hashes for different inputs", () => {
    expect(sha256("a")).not.toBe(sha256("b"));
  });
});

describe("fromBase64Url", () => {
  it("decodes a base64url-encoded string to a Buffer", () => {
    const original = "hello world";
    const encoded = Buffer.from(original).toString("base64url");
    expect(fromBase64Url(encoded).toString("utf8")).toBe(original);
  });

  it("handles strings without padding", () => {
    const encoded = "SGVsbG8";
    expect(fromBase64Url(encoded).toString("utf8")).toBe("Hello");
  });
});

describe("getInstagramScopes", () => {
  it("returns default scope when env is not set", () => {
    vi.stubEnv("INSTAGRAM_SCOPES", "");
    expect(getInstagramScopes()).toEqual(["instagram_business_basic"]);
  });

  it("parses custom scopes from env", () => {
    vi.stubEnv("INSTAGRAM_SCOPES", "instagram_business_basic,instagram_business_manage_messages");
    expect(getInstagramScopes()).toEqual([
      "instagram_business_basic",
      "instagram_business_manage_messages",
    ]);
  });

  it("deduplicates scopes", () => {
    vi.stubEnv("INSTAGRAM_SCOPES", "instagram_business_basic,instagram_business_basic");
    expect(getInstagramScopes()).toEqual(["instagram_business_basic"]);
  });

  it("throws for legacy unsupported scopes", () => {
    vi.stubEnv("INSTAGRAM_SCOPES", "user_profile");
    expect(() => getInstagramScopes()).toThrow("INSTAGRAM_SCOPES_UNSUPPORTED");
  });
});

describe("encodeInstagramState / decodeInstagramState", () => {
  const makePayload = (overrides?: Partial<InstagramStatePayload>): InstagramStatePayload => ({
    storeSlug: "test-store",
    nonce: "abc123",
    returnTo: "/v/test-store",
    createdAt: Date.now(),
    ...overrides,
  });

  it("round-trips a valid payload", () => {
    const payload = makePayload();
    const encoded = encodeInstagramState(payload);
    const decoded = decodeInstagramState(encoded);
    expect(decoded.storeSlug).toBe(payload.storeSlug);
    expect(decoded.nonce).toBe(payload.nonce);
    expect(decoded.returnTo).toBe(payload.returnTo);
  });

  it("throws on tampered signature", () => {
    const payload = makePayload();
    const encoded = encodeInstagramState(payload);
    const tampered = encoded.slice(0, -4) + "xxxx";
    expect(() => decodeInstagramState(tampered)).toThrow();
  });

  it("throws when state is expired (> 15 min)", () => {
    const payload = makePayload({ createdAt: Date.now() - 16 * 60 * 1000 });
    const encoded = encodeInstagramState(payload);
    expect(() => decodeInstagramState(encoded)).toThrow("Instagram state expired");
  });

  it("throws on malformed state (missing dot separator)", () => {
    expect(() => decodeInstagramState("invalid_state_no_dot")).toThrow("Invalid Instagram state");
  });
});

describe("encryptSecret / decryptSecret", () => {
  it("round-trips an access token", () => {
    const token = "EAAMy7rZATest1234567890";
    const ciphertext = encryptSecret(token);
    expect(decryptSecret(ciphertext)).toBe(token);
  });

  it("produces different ciphertexts for the same input (random IV)", () => {
    const token = "EAAMy7rZATest";
    const a = encryptSecret(token);
    const b = encryptSecret(token);
    expect(a).not.toBe(b);
  });

  it("throws on invalid format", () => {
    expect(() => decryptSecret("bad:format")).toThrow("Invalid encrypted token format");
  });

  it("throws when wrong key is used to decrypt", () => {
    const token = "my-secret-token";
    const ciphertext = encryptSecret(token);
    vi.stubEnv("INSTAGRAM_TOKEN_ENCRYPTION_KEY", Buffer.from("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA").toString("base64"));
    expect(() => decryptSecret(ciphertext)).toThrow();
  });
});

describe("sanitizeInstagramMedia", () => {
  it("maps all fields from a full record", () => {
    const raw = {
      id: "123",
      caption: "Test caption",
      media_type: "IMAGE",
      media_url: "https://example.com/img.jpg",
      thumbnail_url: "https://example.com/thumb.jpg",
      permalink: "https://instagram.com/p/abc",
      timestamp: "2024-01-01T00:00:00Z",
    };
    expect(sanitizeInstagramMedia(raw)).toEqual({
      id: "123",
      caption: "Test caption",
      media_type: "IMAGE",
      media_url: "https://example.com/img.jpg",
      thumbnail_url: "https://example.com/thumb.jpg",
      permalink: "https://instagram.com/p/abc",
      timestamp: "2024-01-01T00:00:00Z",
    });
  });

  it("coerces missing fields to empty strings", () => {
    const result = sanitizeInstagramMedia({ id: 42 });
    expect(result.id).toBe("42");
    expect(result.caption).toBe("");
    expect(result.media_type).toBe("");
    expect(result.media_url).toBe("");
    expect(result.thumbnail_url).toBe("");
    expect(result.permalink).toBe("");
    expect(result.timestamp).toBe("");
  });

  it("strips non-string caption values", () => {
    const result = sanitizeInstagramMedia({ id: "1", caption: 123 });
    expect(result.caption).toBe("");
  });
});
