import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Faz 0 (Tek Asistan planı, 2026-09-02) — regresyon kilidi.
 *
 * ÖNCEKİ HATA (canlı veriyle doğrulandı): OwnerWorkspaceShell'deki
 * "hesabına bağla" bandı `isDemo` (stores.is_demo) koşuluna bakıyordu.
 * is_demo yalnız 9 kanonik ŞABLONUN kendisinde true — hiçbir müşteri
 * klonunda değil (clone_demo_store_as_draft klonu is_demo=false doğurur).
 * Üstelik get_working_draft_for_session zaten is_demo=true iken
 * DEMO_STORE_IMMUTABLE fırlatıyor, yani isOwnerMode is_demo=true iken
 * hiçbir zaman true olamaz — bant ulaşılamaz koddu. Ölçüm: demo olmayan
 * 29 gerçek mağazadan yalnız 2'sinin user_id'si dolu, kalan 27'si bu
 * bandı hiç göremiyordu.
 */
describe("hesap bağlama CTA'sı gerçek edit_token sahiplerine ulaşır", () => {
  const kaynak = oku("app/v/[slug]/OwnerWorkspaceShell.tsx");

  it("bant artık isDemo yerine draft.has_account'a bakar", () => {
    expect(kaynak).toContain("draft?.has_account === false");
    // Eski, ulaşılamaz koşul tek başına kalmamalı.
    expect(kaynak).not.toMatch(/\{isDemo \? \(/);
  });

  it("has_account tipini WorkingDraftData'ya taşır", () => {
    expect(kaynak).toContain("has_account?: boolean");
  });

  it("linkIdentity'den önce oturum yoksa anonim oturum açılır (blog-yonetim ile aynı desen)", () => {
    expect(kaynak).toContain("supabase.auth.getSession()");
    expect(kaynak).toContain("supabase.auth.signInAnonymously()");
    expect(kaynak).toContain("supabase.auth.linkIdentity({");
  });

  it("bağlanma denemesi hata/yükleniyor durumunu kullanıcıya gösterir", () => {
    expect(kaynak).toContain("hesapBaglaniyor");
    expect(kaynak).toContain("hesapBaglaHata");
  });
});

describe("get_working_draft_for_session RPC'si has_account döner (Faz 0)", () => {
  const migrasyon = readFileSync(
    resolve(
      __dirname,
      "../../supabase/migrations/20260902120000_working_draft_has_account_flag.sql",
    ),
    "utf8",
  );

  it("ham user_id yerine yalnız türetilmiş boolean seçer", () => {
    expect(migrasyon).toContain("st.user_id is not null");
    expect(migrasyon).toContain("'has_account', coalesce(v_has_account, false)");
  });

  it("is_demo=true satırlar hâlâ DEMO_STORE_IMMUTABLE ile reddedilir", () => {
    expect(migrasyon).toContain("DEMO_STORE_IMMUTABLE");
  });
});
