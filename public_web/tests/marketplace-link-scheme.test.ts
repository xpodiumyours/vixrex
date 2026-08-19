import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import { normalizeExternalUrl } from "@/lib/products";

// GÖREV 2 — pazaryeri linki XSS (javascript:/data:/vbscript: şema).
//
// VitrinProfileView.tsx link.url'i normalizeExternalUrl'dan geçirir ve
// tehlikeli şemayı reddeder; böylece javascript:alert(1) gibi bir değer
// tıklanabilir <a> olarak render edilmez.

// Bileşendeki kararın birebir kopyası (üretim koduna yeni fonksiyon eklenmedi).
function marketplaceHref(url: unknown): string | null {
  const href = normalizeExternalUrl(url);
  const rawLower = String(url ?? "").trim().toLowerCase();
  const hasDangerousScheme = /^(javascript|data|vbscript):/i.test(rawLower);
  return !href || hasDangerousScheme ? null : href;
}

describe("normalizeExternalUrl + pazaryeri şema guard'ı", () => {
  it("javascript: şemasını reddeder — link render edilmez", () => {
    expect(marketplaceHref("javascript:alert(1)")).toBeNull();
  });

  it("data: şemasını reddeder", () => {
    expect(marketplaceHref("data:text/html,<script>alert(1)</script>")).toBeNull();
  });

  it("vbscript: şemasını reddeder", () => {
    expect(marketplaceHref("vbscript:msgbox(1)")).toBeNull();
  });

  it("normal https linkini olduğu gibi korur", () => {
    expect(marketplaceHref("https://trendyol.com/magaza/123")).toBe(
      "https://trendyol.com/magaza/123",
    );
  });

  it("şemasız alan adına https:// ekler (geçerli pazaryeri linki)", () => {
    expect(marketplaceHref("trendyol.com/magaza/123")).toBe(
      "https://trendyol.com/magaza/123",
    );
  });
});

describe("VitrinProfileView ham link.url yerine normalizeExternalUrl kullanıyor", () => {
  const icerik = readFileSync(
    resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
    "utf-8",
  );

  it("normalizeExternalUrl import edilmiş", () => {
    expect(icerik).toMatch(/import\s*\{\s*normalizeExternalUrl\s*\}\s*from\s*"@\/lib\/products"/);
  });

  it("ham href={link.url} artık yok", () => {
    expect(icerik).not.toMatch(/href=\{\s*link\.url\s*\}/);
  });

  it("tehlikeli şema guard'ı (javascript/data/vbscript) mevcut", () => {
    expect(icerik).toMatch(/javascript\|data\|vbscript/i);
  });
});
