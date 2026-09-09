import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const writer = readFileSync(
  resolve(__dirname, "../../lib/services/vixrex_nlu/vixrex_canonical_draft_writer.dart"),
  "utf8"
);
const pipeline = readFileSync(
  resolve(__dirname, "../../lib/services/vixrex_nlu/vixrex_nlu_pipeline.dart"),
  "utf8"
);
const migration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909225500_add_owned_atomic_working_draft_batch.sql"
  ),
  "utf8"
);

describe("Flutter Vixrex Assistant kanonik working draft sözleşmesi", () => {
  it("kalıcı hesapta tek Supabase batch RPC kullanır, alan alan RPC döngüsü kurmaz", () => {
    expect(writer).toContain("update_owned_working_draft_fields");
    expect(writer).toContain("'p_changes': changes");
    expect(writer).toContain("user.isAnonymous");
    expect(writer).not.toContain("update_working_draft_field'");
  });

  it("pipeline controller yokken handled sonucundan önce kanonik yazarı çağırır", () => {
    expect(pipeline).toContain("_writeCanonicalWhenDelegated");
    expect(pipeline).toContain("VixrexCanonicalWriteState.failed");
    expect(pipeline).toContain("if (canonicalFailure != null) return canonicalFailure");
  });

  it("çoklu niyette bir hata varsa kısmi başarıyı reddeder", () => {
    expect(pipeline).toContain("basarili.isEmpty || hatalar.isNotEmpty");
    const hataKontrol = pipeline.indexOf("basarili.isEmpty || hatalar.isNotEmpty");
    const canonicalWrite = pipeline.indexOf("_writeCanonicalWhenDelegated", hataKontrol);
    expect(hataKontrol).toBeGreaterThan(-1);
    expect(canonicalWrite).toBeGreaterThan(hataKontrol);
  });

  it("Supabase RPC yalnız kalıcı hesabın kendi vitrininin working draft satırına yazar", () => {
    expect(migration).toContain("v_user_id uuid := auth.uid()");
    expect(migration).toContain("not public.is_permanent_user()");
    expect(migration).toContain("where st.user_id = v_user_id");
    expect(migration).toContain("public.owner_forbidden_draft_keys()");
    expect(migration).toContain("for update;");
    expect(migration).toContain("draft_version = draft_version + 1");
    expect(migration).toContain(
      "revoke all on function public.update_owned_working_draft_fields(jsonb)"
    );
    expect(migration).toContain("grant execute on function public.update_owned_working_draft_fields(jsonb)");
    expect(migration).toContain("to authenticated");
  });
});
