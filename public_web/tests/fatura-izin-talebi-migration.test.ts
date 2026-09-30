import { readdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";

// F7 izin takibi sözleşmesi: talep ile firma onayı ayrı tutulur,
// aynı firmaya her faturada yeniden talep yağmaz.

const repo = resolve(__dirname, "../..");

function migrationOku(sonEk: string): string {
  const dizin = resolve(repo, "supabase/migrations");
  const dosya = readdirSync(dizin)
    .filter((ad) => ad.endsWith(sonEk))
    .sort()
    .at(-1);
  if (!dosya) throw new Error(`Migration bulunamadı: *${sonEk}`);
  return readFileSync(join(dizin, dosya), "utf8");
}

const migration = migrationOku("_fatura_izin_talebi.sql");

describe("fatura izin talebi migration", () => {
  it("talep tablosunu acar", () => {
    expect(migration).toContain("invoice_permission_requests");
    expect(migration).toContain("store_id");
    expect(migration).toContain("job_id");
  });

  it("sorumlu ve durum ayrimini kilitler", () => {
    expect(migration).toContain("sorumlu");
    expect(migration).toContain("'esnaf'");
    expect(migration).toContain("'vixrex'");
    expect(migration).toContain("gonderildi");
    expect(migration).toContain("cevap_bekliyor");
    expect(migration).toContain("izin_var");
    expect(migration).toContain("reddedildi");
  });

  it("talep herkese kapali tutulur", () => {
    expect(migration).toContain("enable row level security");
    expect(migration).toContain("revoke all on public.invoice_permission_requests from anon");
    expect(migration).toContain("revoke all on public.invoice_permission_requests from authenticated");
  });
});
