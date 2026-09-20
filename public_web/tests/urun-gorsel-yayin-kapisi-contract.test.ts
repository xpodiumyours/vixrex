import { readFileSync, readdirSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationFiles = readdirSync(migrationsDir).filter((name) => name.endsWith(".sql"));

const gateFiles = migrationFiles.filter((name) =>
  /create\s+(or\s+replace\s+)?function\s+public\.assert_store_products_ready\s*\(/i.test(
    readFileSync(resolve(migrationsDir, name), "utf8"),
  ),
);
const source = gateFiles.length === 1
  ? readFileSync(resolve(migrationsDir, gateFiles[0]), "utf8")
  : "";
const routeSource = readFileSync(
  resolve(__dirname, "../src/app/api/owner-publish/route.ts"),
  "utf8",
);

describe("assert_store_products_ready DB kapısı", () => {
  it("tek migration içinde istemciye kapalı bir modüldür", () => {
    expect(gateFiles).toHaveLength(1);
    expect(source).toContain("function public.assert_store_products_ready(uuid)");
    expect(source).toMatch(
      /revoke execute on function public\.assert_store_products_ready\(uuid\) from public/,
    );
    expect(source).toMatch(
      /revoke execute on function public\.assert_store_products_ready\(uuid\) from anon, authenticated/,
    );
  });

  it("yalnız görünür ürünlerde sıfır fotoğrafı reddeder", () => {
    expect(source).toContain("p.is_visible is true");
    expect(source).toContain("jsonb_array_length(coalesce(p.image_urls, '[]'::jsonb)) = 0");
    expect(source).toContain("raise exception 'PRODUCT_IMAGE_REQUIRED'");
  });

  it("hem ilk yayın tetikleyicisinden hem yeniden yayın RPC'sinden çağrılır", () => {
    expect(source).toMatch(
      /enforce_store_publish_readiness[\s\S]*?perform public\.assert_store_products_ready\(new\.id\)/,
    );
    const publishStart = source.indexOf("create or replace function public.publish_working_draft");
    const publishBlock = source.slice(publishStart);
    const products = publishBlock.indexOf("perform public.assert_store_products_ready(v_store_id)");
    const setPublished = publishBlock.indexOf("set is_published = true");
    const deleteDraft = publishBlock.indexOf("delete from public.store_working_drafts");
    expect(products).toBeGreaterThan(-1);
    expect(setPublished).toBeGreaterThan(products);
    expect(deleteDraft).toBeGreaterThan(setPublished);
  });

  it("PRODUCT_IMAGE_REQUIRED Next.js'te Türkçe mesaja ve 422 durumuna çevrilir", () => {
    expect(routeSource).toContain("PRODUCT_IMAGE_REQUIRED:");
    expect(routeSource).toContain("PRODUCT_IMAGE_REQUIRED: 422");
  });
});
