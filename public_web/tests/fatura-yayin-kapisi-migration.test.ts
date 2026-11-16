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

const gorselIzinKapisi = migrationOku("_fatura_gorsel_izni_yayin_kapisi.sql");

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

describe("fatura gorsel izni yayin kapisi", () => {
  it("publish RPC'sini yeniden tanimlar ve izin alanini okur", () => {
    expect(gorselIzinKapisi).toContain("create or replace function public.publish_invoice_product");
    expect(gorselIzinKapisi).toContain("gorselKaynaklari");
    expect(gorselIzinKapisi).toContain("hakKayitDurumu");
  });

  it("yalniz dogrulanmis izin durumlarini gecerli sayar", () => {
    for (const durum of [
      "verified_supplier_permission",
      "verified_feed_terms",
      "merchant_owned_media",
    ]) {
      expect(gorselIzinKapisi).toContain(`'${durum}'`);
    }
  });

  it("eksik veya bilinmeyen izin durumu üretici görselini yayına açmaz", () => {
    expect(gorselIzinKapisi).toContain("jsonb_array_elements_text(v_product.image_urls) image(url)");
    expect(gorselIzinKapisi).toContain("kaynak->>'depoUrl'=image.url");
    expect(gorselIzinKapisi).toContain("coalesce(kaynak->>'hakKayitDurumu','') not in");
    expect(gorselIzinKapisi).not.toContain("kaynak ? 'hakKayitDurumu'");
    expect(gorselIzinKapisi).not.toContain("'merchant_attestation'");
  });

  it("izin dogrulanmamissa karti gorunmez birakir ve hazir doner", () => {
    expect(gorselIzinKapisi).toContain("set is_visible=false");
    expect(gorselIzinKapisi).toContain("'gorunur',false");
    expect(gorselIzinKapisi).toContain("'izin_bekliyor',true");
  });

  it("zaten gorunur urunleri izin kapisi kapatmaz", () => {
    expect(gorselIzinKapisi.indexOf("'zaten_yayinda'"))
      .toBeLessThan(gorselIzinKapisi.indexOf("hakKayitDurumu"));
  });

  it("gorsel kaynaklari bos ise esnaf gorseline izin verir", () => {
    expect(gorselIzinKapisi).toContain("else '[]'::jsonb end");
  });

  it("mevcut gorunur satirlari topluca degistirmez", () => {
    const guncellemeler = gorselIzinKapisi
      .split("\n")
      .filter((satir) => satir.includes("update public.products"));
    expect(guncellemeler).toHaveLength(2);
    for (const satir of guncellemeler) {
      expect(satir).toContain("where id=p_product_id and store_id=v_store");
    }
  });
});

const katman = readFileSync(
  resolve(repo, "supabase/migrations/20261006180000_fatura_kart_katmanlari.sql"),
  "utf8",
);

const kanitSarti = readFileSync(
  resolve(repo, "supabase/migrations/20261010220000_fatura_kanit_sarti_kalkar.sql"),
  "utf8",
);

describe("fatura kanit sarti kalkar", () => {
  it("yayin fonksiyonu satir durumunun kanitli olmasini istemez", () => {
    expect(kanitSarti).toContain("create or replace function public.publish_invoice_product");
    expect(kanitSarti).not.toContain("outcome is distinct from 'kanitli'");
    expect(kanitSarti).not.toContain("sablonTam");
    expect(kanitSarti).not.toContain("< 1200");
  });
});

describe("fatura kart katmanlari migration", () => {
  it("ayri stok onayini zorunlu tutmaz, sablon ve fotoğraf netliğini tutar", () => {
    expect(katman).toContain("sablonTam");
    expect(katman).toContain("< 1200");
    expect(katman).not.toContain("stokOnaylandi' is distinct from 'true'");
    expect(katman).toContain("invoice_read_usage");
  });
});
