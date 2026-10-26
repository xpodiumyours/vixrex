import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

describe("taslak çakışması içerik kontrolü sözleşmesi", () => {
  const goc = readFileSync(
    resolve(
      __dirname,
      "../../supabase/migrations/20261027090000_taslak_cakismasinda_icerik_kontrolu.sql",
    ),
    "utf-8",
  );
  const profil = readFileSync(
    resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
    "utf-8",
  );
  const mesajlar = readFileSync(
    resolve(__dirname, "../../shared/vixrex_mesajlar.json"),
    "utf-8",
  );

  it("içerik aynıysa çakışma sayılmaz ve taban sessizce canlıya bağlanır", () => {
    expect(goc).toContain("is distinct from");
    expect(goc).toContain("set base_live_version = v_live_version");
    expect(goc).toContain("v_conflict := false");
    expect(goc).toContain("v_fark = 0");
  });

  it("içerik gerçekten farklıysa çakışma korunur", () => {
    expect(goc).toContain(
      "v_conflict := (v_draft_base_live_version <> v_live_version)",
    );
    expect(goc).toContain("v_fark := v_fark + 1");
  });

  it("taslak bandı yayın durumuna göre doğru cümleyi kurar", () => {
    expect(profil).toContain("isPublished");
    expect(profil).toContain(
      "bu vitrin henüz yayında değil, müşteriler göremez",
    );
    expect(profil).toContain("müşteriler yayındaki hâli görüyor");
  });

  it("çakışma mesajı kaybı açıkça söyler", () => {
    expect(mesajlar).toContain("yayınlanmamış değişiklikler kaybolur");
  });
});
