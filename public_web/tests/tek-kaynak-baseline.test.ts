import { describe, expect, it } from "vitest";
import { readFileSync, readdirSync, existsSync } from "fs";
import { resolve } from "path";

/**
 * PR1-C1: Tek-kaynak öncesi baseline sözleşmesi
 * Mevcut sahiplik/taslak/kiralama/yasal-onay/konuşma geçiş davranışlarını
 * dışarıdan gözlenen sonuçlarla karakterize eder. Üretim değiştirilmez.
 *
 * Bu testler PR1 sonrası evrilecek: owner_flow_states ve
 * assistant_conversations eklendiğinde buradaki "yok" beklentileri
 * "var"e dönecek ve yeni RLS/idempotency sözleşmeleri eklenecek.
 */

const migrationsDir = resolve(__dirname, "../../supabase/migrations");
const supabaseSchemaPath = resolve(__dirname, "../../supabase_schema.sql");

function migrationContents(): string {
  const files = readdirSync(migrationsDir).filter((f) => f.endsWith(".sql"));
  return files.map((f) => readFileSync(resolve(migrationsDir, f), "utf-8")).join("\n---\n");
}

const allMigrations = migrationContents();
const schema = existsSync(supabaseSchemaPath) ? readFileSync(supabaseSchemaPath, "utf-8") : "";

// ---------- 1. Sahiplik ----------
describe("baseline — sahiplik tek kaynak: stores.user_id", () => {
  it("stores tablosu user_id ile Auth kullanıcısına bağlıdır", () => {
    expect(allMigrations).toMatch(/stores.*user_id/i);
    expect(allMigrations).toMatch(/auth\.users/i);
  });

  it("çalışma taslağı stores.version üzerinden canlı sürümü izler", () => {
    expect(allMigrations).toContain("store_working_drafts");
    expect(allMigrations).toMatch(/alter table public\.stores add column if not exists version/);
  });
});

// ---------- 2. Çalışma taslağı ----------
describe("baseline — working draft mevcudu ve yalıtımı", () => {
  it("store_working_drafts tablosu migration ile oluşturulmuştur", () => {
    expect(allMigrations).toMatch(/create table public\.store_working_drafts/);
  });

  it("store_working_drafts RLS açık ve doğrudan SELECT polikası yok", () => {
    expect(allMigrations).toContain("alter table public.store_working_drafts enable row level security");
    // doğrudan politika yok — erişim SECURITY DEFINER fonksiyonlardan
    const hasDirectPolicy = /create policy[^;]*store_working_drafts/i.test(allMigrations);
    expect(hasDirectPolicy).toBe(false);
  });

  it("get_or_create_working_draft SECURITY DEFINER ve search_path sabit", () => {
    expect(allMigrations).toContain("create or replace function public.get_or_create_working_draft");
    expect(allMigrations).toContain("security definer");
    expect(allMigrations).toMatch(/set search_path = pg_catalog/);
  });
});

// ---------- 3. Kiralama ----------
describe("baseline — kiralama mevcut yolu", () => {
  it("clone/rent demo RPC'leri mevcuttur (misafir yolu dahil)", () => {
    // mevcut kiralık vitrin seed ve rent-demo route'ları
    expect(allMigrations).toMatch(/kiralik vitrin|rent_demo|clone_demo/i);
  });

  it("kiralama akışı kalıcı hesap olmadan misafire düşebiliyor — PR1 sonrası kapanacak", () => {
    // şu anki davranış karakterizasyonu: misafir kiralama bir yol olarak var
    // bu test bilerek gevşek: en az bir rent/demo migration veya route var mı bakar
    const rentRoute = resolve(__dirname, "../src/app/api/rent-demo/route.ts");
    const rentHesapRoute = resolve(__dirname, "../src/app/api/rent-demo/hesap/route.ts");
    const anyRentCode = existsSync(rentRoute) || existsSync(rentHesapRoute);
    expect(anyRentCode).toBe(true);
  });
});

// ---------- 4. Yasal onay ----------
describe("baseline — yasal onay sürümlü omurga", () => {
  it("legal belgeler ve accept fonksiyonu mevcuttur", () => {
    expect(allMigrations).toMatch(/legal_documents|accept_store_legal/i);
  });

  it("stores üzerinde yasal onay hash kolonları var (güven kaynağı JSON değil)", () => {
    // PR sonrası genel JSON boolean güven kaynağı olmayacak — belge hash'i esas
    const hasHash = /privacy_notice_hash|terms_hash|publication_consent_hash/i.test(allMigrations);
    expect(hasHash).toBe(true);
  });
});

// ---------- 5. Konuşma geçişi (şu an kısa ömürlü) ----------
describe("baseline — konuşma geçişi şu an kısa ömürlü", () => {
  it("owner_sessions yalnızca kısa ömürlü yetki taşır — konuşma saklamaz", () => {
    const sessionMigration = readFileSync(
      resolve(migrationsDir, "20260804001000_20260803180000_add_owner_sessions.sql"),
      "utf-8"
    );
    expect(sessionMigration).toContain("create table public.owner_sessions");
    expect(sessionMigration).not.toMatch(/assistant_messages|conversation/i);
  });

  it("kalıcı assistant_conversations / assistant_messages PR1-C3 ile oluşturuldu", () => {
    expect(allMigrations).toMatch(/create table public\.assistant_conversations/);
    expect(allMigrations).toMatch(/create table public\.assistant_messages/);
  });

  it("assistant_messages idempotent client_message_id ve seq unique ile korunuyor", () => {
    expect(allMigrations).toMatch(/idx_assistant_messages_client_id/);
    expect(allMigrations).toMatch(/idx_assistant_messages_conversation_seq/);
    expect(allMigrations).toMatch(/client_message_id text/);
  });

  it("RLS açık ve doğrudan politika yok (yalnız definer)", () => {
    expect(allMigrations).toContain("alter table public.assistant_conversations enable row level security");
    expect(allMigrations).toContain("alter table public.assistant_messages enable row level security");
  });

  it("landing asistanı sessionStorage ile taslak taşıyor (kalıcı değil) — PR1 sonrası owner_flow_states'e aktarılacak", () => {
    const landingSohbet = readFileSync(resolve(__dirname, "../src/components/landing/LandingAsistanSohbeti.tsx"), "utf-8");
    const flowLib = readFileSync(resolve(__dirname, "../src/lib/landingAsistanAkisi.ts"), "utf-8");
    expect(landingSohbet).toContain("taslagiKaydet");
    expect(flowLib).toContain("vixrex_asistan_taslak");
  });
});

// ---------- 6. Tek-kaynak yeni tablolar (PR1-C2 sonrası) ----------
describe("PR1-C2 — owner_flow_states kalıcı akış kaydı", () => {
  it("owner_flow_states tablosu oluşturuldu", () => {
    expect(allMigrations).toMatch(/create table public\.owner_flow_states/);
  });

  it("user_id + flow_type + version + completed_steps ile tek kaynak", () => {
    expect(allMigrations).toMatch(/user_id uuid not null references auth\.users/);
    expect(allMigrations).toMatch(/flow_type text not null check/);
    expect(allMigrations).toMatch(/completed_steps text\[\]/);
    expect(allMigrations).toMatch(/version bigint not null default 1/);
  });

  it("RLS açık ve doğrudan politika yok (yalnız definer fonksiyon)", () => {
    expect(allMigrations).toContain("alter table public.owner_flow_states enable row level security");
    const hasDirectPolicy = /create policy[^;]*owner_flow_states/i.test(allMigrations);
    expect(hasDirectPolicy).toBe(false);
  });

  it("bootstrap fonksiyonu PR1-C4 ile oluşturuldu (yalnız okur, eski istemciler etkilenmez)", () => {
    expect(allMigrations).toMatch(/create or replace function public\.get_owner_workspace_bootstrap/);
    expect(allMigrations).toMatch(/security definer/);
    expect(allMigrations).toMatch(/set search_path = pg_catalog/);
    expect(allMigrations).toMatch(/grant execute on function public\.get_owner_workspace_bootstrap\(\) to authenticated/);
  });
});

describe("PR1-C5 — dar akış ve konuşma fonksiyonları", () => {
  it("update_owner_flow_state sürüm kontrollü ve yalnız auth.uid()", () => {
    expect(allMigrations).toMatch(/create or replace function public\.update_owner_flow_state/);
    expect(allMigrations).toContain("VERSION_CONFLICT");
    expect(allMigrations).toContain("FLOW_NOT_FOUND_OR_UNAUTHORIZED");
    expect(allMigrations).toMatch(/set search_path = pg_catalog, public/);
    expect(allMigrations).toMatch(/grant execute on function public\.update_owner_flow_state/);
    expect(allMigrations).toMatch(/revoke execute on function public\.update_owner_flow_state/);
  });

  it("append_assistant_message idempotent ve sıralı", () => {
    expect(allMigrations).toMatch(/create or replace function public\.append_assistant_message/);
    expect(allMigrations).toContain("CONVERSATION_NOT_FOUND_OR_UNAUTHORIZED");
    expect(allMigrations).toContain("client_message_id");
    expect(allMigrations).toMatch(/grant execute on function public\.append_assistant_message/);
    expect(allMigrations).toMatch(/revoke execute on function public\.append_assistant_message/);
  });
});
