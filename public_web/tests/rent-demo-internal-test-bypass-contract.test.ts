import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const source = readFileSync(
  resolve(migrationsDir, "20260910140000_rent_demo_internal_test_bypass.sql"),
  "utf-8"
);
const routeSource = readFileSync(
  resolve(__dirname, "../src/app/api/rent-demo/route.ts"),
  "utf-8"
);

describe("start_demo_trial — iç test muafiyeti Katman 3'ü atlamaz", () => {
  it("eski 2 parametreli imzayı düşürüp 3 parametreliyi tanımlar", () => {
    expect(source).toContain(
      "drop function if exists public.start_demo_trial(text, text);"
    );
    expect(source).toContain(
      "create or replace function public.start_demo_trial(\n  p_source_slug text,\n  p_client_key text,\n  p_bypass_secret text default null\n)"
    );
  });

  it("bypass yalnız sha256 hash eşleşirse true olur", () => {
    expect(source).toContain(
      "encode(sha256(p_bypass_secret::bytea), 'hex')"
    );
    expect(source).toMatch(/= '[0-9a-f]{64}'/);
  });

  it("Katman 1 ve 2 bypass'a bağlı (if not v_bypass bloğunun içinde)", () => {
    const bypassBlock = source.slice(
      source.indexOf("if not v_bypass then"),
      source.indexOf("-- Katman 3"),
    );
    expect(bypassBlock).toContain("rent_demo:ip:short:");
    expect(bypassBlock).toContain("rent_demo:ip:day:");
  });

  it("Katman 3 (global) if not v_bypass bloğunun DIŞINDA — bypass'tan muaf değil", () => {
    const katman3Index = source.indexOf("-- Katman 3");
    const bypassBlockEnd = source.indexOf("end if;\n  end if;");
    expect(katman3Index).toBeGreaterThan(-1);
    expect(bypassBlockEnd).toBeGreaterThan(-1);
    expect(katman3Index).toBeGreaterThan(bypassBlockEnd);
    const katman3Block = source.slice(katman3Index, source.indexOf("-- Kaynağın gerçekten"));
    expect(katman3Block).toContain("'rent_demo:global', 100, 3600");
  });

  it("yalnız service_role'e açık, anon/authenticated/PUBLIC'e kapalı", () => {
    expect(source).toContain(
      "revoke execute on function public.start_demo_trial(text, text, text)\n  from public, anon, authenticated;"
    );
    expect(source).toContain(
      "grant execute on function public.start_demo_trial(text, text, text)\n  to service_role;"
    );
  });

  it("route yalnız sunucu-yalnız env değişkeniyle eşleşen başlığı iletir, istemci değerini doğrudan geçirmez", () => {
    expect(routeSource).toContain("RENT_DEMO_BYPASS_SECRET");
    expect(routeSource).toContain("x-vixrex-internal-test-secret");
    expect(routeSource).toContain(
      "internalTestSecret === process.env.RENT_DEMO_BYPASS_SECRET"
    );
  });
});
