import { readdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";

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

const migration = migrationOku("_fatura_islem_kaniti.sql");

const TABLOLAR = [
  "invoice_jobs",
  "invoice_job_lines",
  "invoice_line_evidence",
  "invoice_line_candidates",
  "invoice_image_rights",
];

describe("fatura islem ve kanit kaydi migration", () => {
  it("bes tablo da acilir ve hepsi RLS ile kilitlenir", () => {
    for (const tablo of TABLOLAR) {
      expect(migration).toContain(`create table if not exists public.${tablo}`);
      expect(migration).toContain(`alter table public.${tablo} enable row level security`);
    }
  });

  it("anon ve authenticated bu tablolara hic erisemez, politika acilmaz", () => {
    for (const tablo of TABLOLAR) {
      expect(migration).toContain(`revoke all on public.${tablo} from anon`);
      expect(migration).toContain(`revoke all on public.${tablo} from authenticated`);
    }
    expect(migration).not.toContain("create policy");
    expect(migration).not.toContain("to anon");
    expect(migration).not.toContain("to authenticated");
  });

  it("dort satir sonucu ve gorsel izin durumlari check ile kilitlidir", () => {
    expect(migration).toContain("'kanitli', 'eksik', 'celiski', 'iz-yok'");
    expect(migration).toContain("'verified_supplier_permission'");
    expect(migration).toContain("'verified_feed_terms'");
    expect(migration).toContain("'merchant_owned_media'");
    expect(migration).toContain("'merchant_attestation'");
    expect(migration).toContain("'unknown'");
    expect(migration).toContain("'denied'");
    expect(migration).toContain("'strong', 'partial', 'weak'");
  });

  it("ayni fatura fotografi ikinci bir is kaydi yaratamaz", () => {
    expect(migration).toContain("create unique index if not exists invoice_jobs_store_dokuman_uq");
    expect(migration).toContain("(store_id, document_fingerprint)");
    expect(migration).toContain("unique (job_id, line_index)");
  });

  it("okunamayan satir silinemez: satir kaydi isim zorunlu ve sonuc zorunlu", () => {
    expect(migration).toContain("raw_line text not null default ''");
    expect(migration).toContain("outcome text not null");
    expect(migration).toMatch(/references public\.invoice_jobs\(id\) on delete cascade/);
  });

  it("fatura bilgisi products tablosuna yazilmaz", () => {
    expect(migration).not.toContain("public.products");
    expect(migration).toContain("unit_price numeric");
    expect(migration).toContain("unit_price is");
  });
});
