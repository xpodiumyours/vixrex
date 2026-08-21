import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) => readFileSync(resolve(__dirname, yol), "utf-8");

const migration = oku(
  "../../supabase/migrations/20260821143000_restore_working_draft_field.sql"
);
const route = oku("../src/app/api/owner-draft-restore/route.ts");
const hook = oku("../src/app/v/[slug]/hooks/useFieldRestore.ts");
const input = oku("../src/app/v/[slug]/components/FieldInputArea.tsx");
const panel = oku("../src/app/v/[slug]/OwnerAssistantPanel.tsx");
const draftRoute = oku("../src/app/api/owner-draft/route.ts");
const broadcast = oku("../src/lib/workingDraftBroadcast.ts");

const functionStart = migration.indexOf(
  "create or replace function public.restore_working_draft_field"
);
const functionSource = migration.slice(
  functionStart,
  migration.indexOf("$$;", functionStart) + 3
);

describe("#261 — tek alanı canlı hâline döndürme RPC'si", () => {
  it("oturumu bağımsız doğrular ve yalnız izinli stores kolonlarını kabul eder", () => {
    expect(functionSource).toContain("security definer");
    expect(functionSource).toContain("set search_path = pg_catalog, public, extensions");
    expect(functionSource).toContain("public.owner_sessions");
    expect(functionSource).toContain("public.owner_forbidden_draft_keys()");
    expect(functionSource).toContain("information_schema.columns");
  });

  it("canlı değeri stores'tan okur, yalnız taslağın seçilen alanını günceller", () => {
    expect(functionSource).toContain("to_jsonb(st) -> v_key");
    expect(functionSource).toContain("update public.store_working_drafts");
    expect(functionSource).not.toContain("update public.stores");
    expect(functionSource).toMatch(/jsonb_set\(\s*draft_data,\s*array\[v_key\]/);
  });

  it("aynı değerde idempotenttir ve sürümü yalnız değişiklikte artırır", () => {
    expect(functionSource).toContain("is distinct from");
    expect(functionSource).toMatch(/if v_changed then[\s\S]*?draft_version = draft_version \+ 1/);
    expect(functionSource).toContain("'changed', v_changed");
  });

  it("RPC erişimini açıkça sınırlar", () => {
    expect(migration).toContain(
      "revoke all on function public.restore_working_draft_field(text, text) from public"
    );
    expect(migration).toContain(
      "grant execute on function public.restore_working_draft_field(text, text) to anon, authenticated"
    );
  });
});

describe("#261 — sunucu ve istemci sözleşmesi", () => {
  it("API oturumu yalnız çerezden okur ve şemadaki kanonik kolonu RPC'ye verir", () => {
    expect(route).toContain("OWNER_SESSION_COOKIE");
    expect(route).toContain("verifyOwnerSession");
    expect(route).not.toMatch(/govde\.(token|sessionToken)/);
    expect(route).toContain("FIELD_BY_KEY.get(anahtar)");
    expect(route).toContain('.rpc("restore_working_draft_field"');
    expect(route).toContain("p_key: alan.kolon");
    expect(route).not.toContain("SERVICE_ROLE");
  });

  it("broadcast yalnız gerçek değişiklikte gönderilir ve ortak yardımcı kullanılır", () => {
    expect(route).toMatch(/if \(degisti\)[\s\S]*?broadcastTaslakGuncellendi/);
    expect(draftRoute).toContain('@/lib/workingDraftBroadcast');
    expect(draftRoute).not.toContain("function broadcastTaslakGuncellendi");
    expect(broadcast).toContain('event: "alan_guncellendi"');
    expect(broadcast).not.toMatch(/payload:\s*{[^}]*deger/);
  });

  it("hook yerel alanı ve girişi günceller, vitrini tazeler ve sonucu dürüstçe söyler", () => {
    expect(hook).toContain('/api/owner-draft-restore');
    expect(hook).toContain("taslakClientId()");
    expect(hook).toContain("setAlan(alan.kolon, govde.deger)");
    expect(hook).toContain("setGiris(");
    expect(hook).toContain("router.refresh()");
    expect(hook).toContain("canlı hâline döndürüldü. Diğer değişikliklerin korundu.");
    expect(hook).toContain("zaten canlıdakiyle aynı.");
  });

  it("seçili her alanda tek tıklamalı ve bekleme durumlu eylem görünür", () => {
    expect(input).toContain("Canlı hâline döndür");
    expect(input).toContain("Döndürülüyor…");
    expect(input).not.toContain("confirm(");
    expect(panel).toContain("useFieldRestore");
    expect(panel).toContain("geriAliniyor={fieldRestore.geriAliniyor}");
  });
});
