import { readFileSync, readdirSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const migrationFiles = readdirSync(migrationsDir).filter((name) => name.endsWith(".sql"));
const readinessFiles = migrationFiles.filter((name) =>
  readFileSync(resolve(migrationsDir, name), "utf8").includes("assert_store_publish_ready"),
);
const source = readinessFiles.length === 1
  ? readFileSync(resolve(migrationsDir, readinessFiles[0]), "utf8")
  : "";
const routeSource = readFileSync(
  resolve(__dirname, "../src/app/api/owner-publish/route.ts"),
  "utf8",
);

describe("assert_store_publish_ready DB core", () => {
  it("tek migration içinde istemciye kapalı bir modüldür", () => {
    expect(readinessFiles).toHaveLength(1);
    expect(source).toContain("function public.assert_store_publish_ready(jsonb)");
    expect(source).toMatch(/revoke execute on function public\.assert_store_publish_ready\(jsonb\) from public/);
    expect(source).toMatch(/revoke execute on function public\.assert_store_publish_ready\(jsonb\) from anon, authenticated/);
  });

  it.each([
    ["name", "STORE_NAME_REQUIRED"],
    ["kategori", "STORE_CATEGORY_REQUIRED"],
    ["whatsapp", "STORE_WHATSAPP_REQUIRED"],
    ["address", "STORE_ADDRESS_REQUIRED"],
    ["province_name", "STORE_PROVINCE_REQUIRED"],
    ["district_name", "STORE_DISTRICT_REQUIRED"],
  ])("%s eksikliğini %s ile reddeder", (field, errorCode) => {
    expect(source).toContain(`->> '${field}'`);
    expect(source).toContain(`raise exception '${errorCode}'`);
  });

  it("Diğer/diger kategorisini ve geçersiz TR mobil biçimini reddeder", () => {
    expect(source).toContain("'diğer', 'diger'");
    expect(source).toContain("raise exception 'STORE_WHATSAPP_INVALID'");
    expect(source).toContain("^905[0-9]{9}$");
  });

  it("ilk yayın geçişini tetikler; mevcut yayınlı satırlara dokunmaz", () => {
    expect(source).toContain("create trigger stores_publish_readiness_guard");
    expect(source).toContain("old.is_published is true");
    expect(source).not.toMatch(/update public\.stores[\s\S]{0,80}is_published = false/i);
  });

  it("yeniden yayında hazırlık yasal tetikleyiciden ve taslak silmeden önce çalışır", () => {
    const publishStart = source.indexOf("create or replace function public.publish_working_draft");
    const publishBlock = source.slice(publishStart);
    const readiness = publishBlock.indexOf("perform public.assert_store_publish_ready");
    const legalTrigger = publishBlock.indexOf("set is_published = true");
    const deleteDraft = publishBlock.indexOf("delete from public.store_working_drafts");
    expect(readiness).toBeGreaterThan(-1);
    expect(legalTrigger).toBeGreaterThan(readiness);
    expect(deleteDraft).toBeGreaterThan(legalTrigger);
    expect(publishBlock).toContain("raise exception 'PREMIUM_REQUIRED'");
    expect(publishBlock).toContain("raise exception 'DRAFT_STALE'");
  });

  it("yeni hata kodlarını Next.js Türkçe mesaja ve 422 durumuna çevirir", () => {
    for (const code of [
      "STORE_NAME_REQUIRED",
      "STORE_CATEGORY_REQUIRED",
      "STORE_WHATSAPP_REQUIRED",
      "STORE_WHATSAPP_INVALID",
      "STORE_ADDRESS_REQUIRED",
      "STORE_PROVINCE_REQUIRED",
      "STORE_DISTRICT_REQUIRED",
    ]) {
      expect(routeSource).toContain(`${code}:`);
      expect(routeSource).toContain(`${code}: 422`);
    }
  });
});
