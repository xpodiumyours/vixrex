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
const ownedMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql"
  ),
  "utf8"
);
const commandMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260909233000_add_assistant_storefront_command_core.sql"
  ),
  "utf8"
);

describe("Flutter Vixrex Assistant kanonik command sözleşmesi", () => {
  it("kalıcı hesapta Next.js ile aynı command core wrapper'ını kullanır", () => {
    expect(writer).toContain("apply_owned_working_draft_command");
    expect(writer).toContain("'p_command_id': commandId");
    expect(writer).toContain("'p_changes': changes");
    expect(writer).toContain("const _uuid = Uuid()");
    expect(writer).toContain("returnedCommandId != commandId");
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

  it("authenticated Assistant yazım sınırı canonical 46 alan allowlistiyle fail-closed kalır", () => {
    expect(ownedMigration).toContain("vixrex_assistant_editable_draft_columns");
    expect(ownedMigration).toContain(
      "v_key = any (public.vixrex_assistant_editable_draft_columns())"
    );
    expect(ownedMigration).toContain("where st.user_id = v_user_id");
    expect(ownedMigration).toContain("public.owner_forbidden_draft_keys()");
  });

  it("Flutter ve Next yetki sarmalayıcıları aynı kapalı command core'a gider", () => {
    expect(commandMigration).toContain("public.vixrex_apply_storefront_command_core(");
    expect(commandMigration).toContain("public.apply_working_draft_command(");
    expect(commandMigration).toContain("public.apply_owned_working_draft_command(");
    expect(commandMigration).toContain(
      "grant execute on function public.apply_owned_working_draft_command(uuid, jsonb)"
    );
    expect(commandMigration).toContain("to authenticated");
    expect(commandMigration).toContain(
      "revoke all on function public.vixrex_apply_storefront_command_core("
    );
  });
});
