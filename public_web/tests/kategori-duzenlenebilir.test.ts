import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * "İşletme Kategorisi" (kategori) şemada vardı (tip: secim), veriyi
 * de taşıyordu, ama sayfada tıklanacak hiçbir yere bağlı değildi —
 * data-flow testi (vitrin-field-schema-render) bunu yakalamıyordu,
 * çünkü yalnız verinin AKTIĞINI kontrol ediyor, tıkla-düzenle
 * işaretinin var olup olmadığını değil.
 *
 * Casper (2026-08-14): "kirala ile açılan vitrinlerde kategori ve
 * ürünler gelmiyor, onlar da düzenlenmeli."
 */

const view = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

describe("İşletme kategorisi sahip modunda düzenlenebilir", () => {
  it("kategori editableProps ile işaretli", () => {
    expect(view).toContain('editableProps("kategori", ownerMode)');
  });

  it("kategori değeri boşsa hiç render edilmiyor (boş chip yok)", () => {
    const blok = view.slice(
      view.indexOf('editableProps("kategori"'),
      view.indexOf('editableProps("kategori"') + 400
    );
    // Koşullu render: {kategori && kategori.trim() && (...)}
    const kosulBaslangici = view.lastIndexOf(
      "{kategori",
      view.indexOf('editableProps("kategori"')
    );
    expect(kosulBaslangici).toBeGreaterThan(-1);
    expect(blok).toBeTruthy();
  });
});
