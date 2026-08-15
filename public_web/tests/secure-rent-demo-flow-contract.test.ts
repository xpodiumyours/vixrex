import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * "Bu vitrini kirala" güvenlik açığının kapatılması (2026-08-15).
 *
 * Asıl risk: clone_demo_store_as_draft + create_owner_session anon rolüne
 * açıktı — saldırgan Next.js'i atlayıp Supabase anon anahtarıyla RPC'yi
 * doğrudan çağırıp sınırsız veri üretebiliyordu. Bu testler, tek güvenli
 * giriş noktası olan start_demo_trial'ın gerçekten (a) yalnız service_role'e
 * açık olduğunu, (b) katmanlı oran sınırı uyguladığını, (c) klonlama +
 * oturum açmayı TEK transaction'da yaptığını doğrular.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const source = readFileSync(
  resolve(migrationsDir, "20260815180000_secure_rent_demo_flow.sql"),
  "utf-8"
);

describe("start_demo_trial — tek güvenli giriş noktası", () => {
  it("yalnız service_role'e açık, anon/authenticated/PUBLIC'e kapalı", () => {
    expect(source).toContain(
      "revoke execute on function public.start_demo_trial(text, text)\n  from public, anon, authenticated;"
    );
    expect(source).toContain(
      "grant execute on function public.start_demo_trial(text, text)\n  to service_role;"
    );
  });

  it("3 katmanlı oran sınırı uygular: IP kısa pencere, IP günlük, global saatlik", () => {
    expect(source).toContain("'rent_demo:ip:short:' || v_client_key");
    expect(source).toContain("3, 600");
  });
});

describe("start_demo_trial — katmanlı oran sınırı anahtarları ve limitleri", () => {
  it("IP kısa pencere: 3 istek / 10 dakika", () => {
    const block = source.slice(
      source.indexOf("-- Katman 1"),
      source.indexOf("-- Katman 2")
    );
    expect(block).toContain("'rent_demo:ip:short:' || v_client_key, 3, 600");
  });

  it("IP günlük pencere: 10 istek / 24 saat", () => {
    const block = source.slice(
      source.indexOf("-- Katman 2"),
      source.indexOf("-- Katman 3")
    );
    expect(block).toContain("'rent_demo:ip:day:' || v_client_key, 10, 86400");
  });

  it("global saatlik pencere: 100 istek / saat — IP değiştiren bot da duvara çarpar", () => {
    const block = source.slice(
      source.indexOf("-- Katman 3"),
      source.indexOf("-- Kaynağın gerçekten")
    );
    expect(block).toContain("'rent_demo:global', 100, 3600");
  });

  it("herhangi bir katman geçilemezse RATE_LIMITED fırlatır", () => {
    const occurrences = source.match(/raise exception 'RATE_LIMITED'/g) ?? [];
    expect(occurrences.length).toBe(3);
  });
});

describe("start_demo_trial — klonlama + oturum açma TEK transaction", () => {
  it("clone_demo_store_as_draft'ı çağırır", () => {
    expect(source).toContain("perform public.clone_demo_store_as_draft(");
  });

  it("_create_owner_session_core'u AYNI fonksiyon içinde çağırır (ayrı bir RPC çağrısı değil)", () => {
    expect(source).toContain(
      "public._create_owner_session_core(v_new_slug, v_edit_token, null::jsonb)"
    );
  });

  it("slug çakışmasında (unique_violation) içeride retry yapar, dışarı hata sızdırmaz", () => {
    expect(source).toContain("when unique_violation then");
    expect(source).toContain("v_attempt < 3");
  });

  it("edit_token 256-bit (32 byte) rastgele üretir — Node.js artık edit_token üretmez", () => {
    expect(source).toContain("encode(gen_random_bytes(32), 'hex')");
  });

  it("kaynağın is_demo=true VE is_published=true olduğunu doğrular", () => {
    expect(source).toContain("is_demo = true and is_published = true");
  });
});

describe("clone_demo_store_as_draft / cleanup_expired_trial_clones — dışarıdan tetiklenemez", () => {
  it("clone_demo_store_as_draft: PUBLIC/anon/authenticated'ten revoke edilir", () => {
    expect(source).toContain(
      "revoke execute on function public.clone_demo_store_as_draft(text, text, text)\n  from public, anon, authenticated;"
    );
  });

  it("cleanup_expired_trial_clones: PUBLIC/anon/authenticated'ten AÇIKÇA revoke edilir", () => {
    expect(source).toContain(
      "revoke execute on function public.cleanup_expired_trial_clones()\n  from public, anon, authenticated;"
    );
  });
});

describe("consume_assistant_request — geriye uyumlu genelleştirme", () => {
  it("p_window_seconds parametresi eklenir, varsayılan 60 (eski çağıran etkilenmez)", () => {
    expect(source).toContain(
      "p_window_seconds integer default 60"
    );
  });

  it("vixrex-assistant-nlu Edge Function'ının 2 parametreli çağrısı hâlâ geçerli imzaya uyar", () => {
    // p_client_key, p_max_requests default 6, p_window_seconds default 60 —
    // eski çağıran (p_client_key, p_max_requests) hâlâ çalışır.
    expect(source).toContain("p_max_requests integer default 6");
  });
});
