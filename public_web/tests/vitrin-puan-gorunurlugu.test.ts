import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import { vitrinPuani } from "@/lib/explore";
import { EXPLORE_STORE_SELECT } from "@/lib/publicStoreSelect";

describe("vitrin puanı", () => {
  it("sahibi puanı göstermeyi açmadıysa puan taşınmaz", () => {
    expect(vitrinPuani({ rating_score: 4.9, show_storefront_rating: false })).toBeNull();
    expect(vitrinPuani({ rating_score: 4.9, show_storefront_rating: null })).toBeNull();
  });

  it("sahibi açtıysa puan taşınır", () => {
    expect(vitrinPuani({ rating_score: 4.2, show_storefront_rating: true })).toBe(4.2);
  });

  it("puan yoksa null kalır", () => {
    expect(vitrinPuani({ rating_score: null, show_storefront_rating: true })).toBeNull();
  });

  it("keşfet puanın kaynağını okuyabilir", () => {
    expect(EXPLORE_STORE_SELECT.split(",")).toContain("show_storefront_rating");
    expect(EXPLORE_STORE_SELECT.split(",")).not.toContain("user_id");
  });
});

describe("sahte puan varsayılanı", () => {
  const migration = readFileSync(
    resolve(__dirname, "../../supabase/migrations/20261110120000_vitrin_puan_varsayilani.sql"),
    "utf-8",
  );

  it("veritabanı varsayılanı 4.9 ve 128 bırakmaz", () => {
    expect(migration).toContain("alter column rating_score drop default");
    expect(migration).toContain("alter column review_count drop default");
  });

  it("uydurma değerleri taşıyan satırları temizler", () => {
    expect(migration).toMatch(/rating_score = 4\.9/);
    expect(migration).toMatch(/review_count = 128/);
    expect(migration).toContain("show_storefront_rating = false");
  });
});
