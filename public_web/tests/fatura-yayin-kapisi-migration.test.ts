import { readdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";

// P6 veritabanı son kapısı sözleşmesi. Eski uygulama sürümü, doğrudan toplu
// istek, is_visible=true gönderen eski RPC veya telefonun toplu görünürlük
// düğmesi bu kapıyı atlayamaz; yalnız publish_invoice_product görünür yapar.

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

const migration = migrationOku("_fatura_yayin_kapisi.sql");

describe("fatura yayin kapisi migration", () => {
  it("fatura kanit ozeti icin kolon acar", () => {
    expect(migration).toContain("fatura_kanit jsonb");
    expect(migration).toContain("alter table public.products");
  });

  it("yeni fatura satiri gorunur dogamaz", () => {
    expect(migration).toContain("create trigger fatura_yayin_kilidi");
    expect(migration).toContain("before insert or update on public.products");
    expect(migration).toMatch(/tg_op = 'INSERT'/);
    expect(migration).toMatch(/new\.is_visible := false/);
  });

  it("taslak, publish RPC'si disinda gorunur yapilamaz", () => {
    expect(migration).toContain("vixrex.fatura_yayin_serbest");
    expect(migration).toContain("FATURA_YAYIN_KAPISI");
  });

  it("publish RPC kapilari yeniden okur", () => {
    expect(migration).toContain("create or replace function public.publish_invoice_product");
    expect(migration).toContain("price_amount");
    expect(migration).toContain("jsonb_array_length");
    expect(migration).toContain("stock_quantity");
    expect(migration).toContain("kartDurumu");
    expect(migration).toContain("stokOnaylandi");
    expect(migration).toContain("kanitli");
  });

  it("publish RPC sahiplik ister ve herkese acik arayuzden cagrilabilir", () => {
    expect(migration).toContain("p_edit_token");
    expect(migration).toContain("grant execute on function public.publish_invoice_product(uuid, text)");
    expect(migration).toContain("to anon, authenticated, service_role");
  });

  it("mevcut gorunur satirlar topluca degistirilmez", () => {
    // Tetik yalniz gelecekteki INSERT/UPDATE'e bakar. Migration icindeki TEK
    // guncelleme, tek urunu (where id) gorunur yapan publish RPC'sidir;
    // kosulsuz/toptan bir UPDATE yoktur.
    const guncellemeler = migration.match(/update public\.products/g) ?? [];
    expect(guncellemeler).toHaveLength(1);
    expect(migration).toMatch(/where id = p_product_id/);
  });
});

const katman = readFileSync(
  resolve(repo, "supabase/migrations/20261006180000_fatura_kart_katmanlari.sql"),
  "utf8",
);

describe("fatura kart katmanlari migration", () => {
  it("ayri stok onayini zorunlu tutmaz, sablon ve fotoğraf netliğini tutar", () => {
    expect(katman).toContain("sablonTam");
    expect(katman).toContain("< 1200");
    expect(katman).not.toContain("stokOnaylandi' is distinct from 'true'");
    expect(katman).toContain("invoice_read_usage");
  });
});
