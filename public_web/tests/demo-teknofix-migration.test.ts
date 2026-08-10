import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260809120000_demo_teknofix_icerik_doldur.sql",
  ),
  "utf-8",
);

describe("demo-teknofix içerik migration sözleşmesi", () => {
  it("korumalı demo satırını yalnız migration işlemi boyunca güncelleyebilir", () => {
    const disableIndex = migration.indexOf(
      "alter table public.stores disable trigger protect_landing_demo_stores",
    );
    const storeUpdateIndex = migration.indexOf("update public.stores set");
    const enableIndex = migration.indexOf(
      "alter table public.stores enable trigger protect_landing_demo_stores",
    );

    expect(disableIndex).toBeGreaterThanOrEqual(0);
    expect(storeUpdateIndex).toBeGreaterThan(disableIndex);
    expect(enableIndex).toBeGreaterThan(storeUpdateIndex);
  });

  it("hedef vitrinin görsel doluluk seviyesini taşır", () => {
    expect(migration).toContain("about_image_url =");
    expect(migration).toContain("Teslim öncesi son kalite kontrolü");

    const productImageUrls = [
      "photo-1511707171634-5f897ff02aa9",
      "photo-1597872200969-2b65d56bd16b",
      "photo-1588872657578-7efd1f1555ed",
      "photo-1584438784894-089d6a62b8fa",
    ];
    for (const imageId of productImageUrls) {
      expect(migration).toContain(imageId);
    }
  });

  it("sekiz hizmetin prompttaki teslim ve garanti sözlerini korur", () => {
    expect(migration.match(/6 ay garanti/g)?.length).toBeGreaterThanOrEqual(5);
    expect(migration).toContain("2-3 iş günü, 3 ay garanti");
    expect(migration).toContain("3-5 iş günü");
    expect(migration).toContain("Stoktan aynı gün");
  });

  it("kategori ve ürün adreslerini URL güvenli biçime getirir", () => {
    expect(migration).toContain("translate(lower(kl.isim)");
    expect(migration).toContain("translate(lower(ul.ad)");
  });
});
