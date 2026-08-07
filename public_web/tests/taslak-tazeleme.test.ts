import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// Taslak tazeleme nöbetçisi (bulgu 10).
//
// Taslak BİR KEZ oluşturuluyordu — o anki vitrinin kopyası olarak. Esnaf
// manuel panelden yayınladığı her şey stores'a yazılıyor ama taslak eski
// hâlde kalıyordu. Turuncu kutu farkı bildiriyor, "Yeniden Yükle" aynı
// eski taslağı tekrar getiriyordu. Uyarının çaresi yoktu.
//
// Casper 2026-08-07: "yeniden yükleme ile ... next.js ekrana gelmiyor."
//
// Tek çıkış "Değişiklikleri bırak"tı; esnaf için "işimi kaybedeceğim"
// demek, kimse basmaz.

const oku = (yol: string) => readFileSync(resolve(__dirname, yol), "utf-8");

describe("Sürüm uyarısının çaresi var", () => {
  it("tazeleme ucu var ve oturumu çerezden okuyor", () => {
    const rota = oku("../src/app/api/owner-refresh/route.ts");
    expect(rota).toContain("refresh_working_draft");
    // Gövdeden token kabul edilmez — koruma sınırı.
    expect(rota).toContain("OWNER_SESSION_COOKIE");
    expect(rota).toContain("verifyOwnerSession");
  });

  it("uyarı kutusu tazeleme düğmesi gösteriyor", () => {
    const shell = oku("../src/app/v/[slug]/OwnerWorkspaceShell.tsx");
    expect(shell).toContain("Canlı sürümü al");
    expect(shell).toContain("/api/owner-refresh");
    // Eski çaresiz düğme geri gelmemeli.
    expect(
      shell.includes(">\n            Yeniden Yükle\n          </button>"),
      "Çaresiz 'Yeniden Yükle' düğmesi geri gelmiş."
    ).toBe(false);
  });

  it("veritabanı fonksiyonu gizli alanları taslağa sokmuyor", () => {
    const sql = oku(
      "../../supabase/migrations/20260807200000_add_refresh_working_draft.sql"
    );
    // edit_token taslağa girerse sahip paneline prop olarak gider ve
    // doğrudan tarayıcıya sızar (koruma sınırı 7).
    expect(sql).toContain("edit_token,user_id");
    expect(sql).toContain("degisen_alan");
  });
});
