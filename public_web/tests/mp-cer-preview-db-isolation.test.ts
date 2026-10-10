import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

// C0: gerçek kaynak güvenlik kuralı; mock DB ile değil config koduyla doğrulanır.
describe("MP-CER C0 — Preview veritabanı izolasyonu", () => {
  it("Next.js Preview için production Supabase URL/anahtarı gömülü değildir", () => {
    const source = readFileSync(join(process.cwd(), "next.config.ts"), "utf8");
    expect(source).not.toContain("chfulefxczbgurtgavtp");
    expect(source).not.toContain("sb_publishable_GcCRXDh6vXFGR1UvBFG-3w_x85hvXbN");
    expect(source).toContain("MP_CER_PREVIEW_DB_MUST_BE_ISOLATED");
    expect(source).toContain("nfivinvdlxhyxsoxzarh");
  });

  it("sunucu yönetim bağlantısı PR #672'nin Preview ortamında yanlış DB'yi reddeder", () => {
    const source = readFileSync(join(process.cwd(), "src/lib/supabaseAdmin.ts"), "utf8");
    expect(source).toContain('process.env.VERCEL_ENV === "preview"');
    expect(source).toContain('process.env.VERCEL_GIT_COMMIT_REF === "fix/fatura-cerrahi-birlesik-20261010"');
    expect(source).toContain("MP_CER_PREVIEW_DB_MUST_BE_ISOLATED");
    expect(source).toContain("nfivinvdlxhyxsoxzarh");
  });
});
