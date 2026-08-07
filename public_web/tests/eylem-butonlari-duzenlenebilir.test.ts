import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

// Eylem butonları nöbetçisi (bulgu 6).
//
// Sahip modunda WhatsApp, Yol Tarifi ve web sitesi butonları düz link
// olarak çiziliyordu. Esnaf kendi kendine WhatsApp mesajı açıyor ya da
// kendi haritasına gidiyordu; düzenleme kutusu hiç açılmıyordu.
//
// Casper 2026-08-07: "whatsaptan kendi kendimize mesaj atmak veya
// instagramda kendi sayfamızı açmak için değil. mantık olarak dimi?"
//
// Panelin tıklama dinleyicisi yalnız data-vixrex-editable taşıyan
// öğelerde preventDefault çağırıyor; işaret yoksa tarayıcı normal link
// davranışını sürdürüyordu.

const view = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

describe("Sahip modunda eylem butonları düzenleme açıyor", () => {
  it("hero butonları şema alanına bağlı", () => {
    expect(view).toContain("EYLEM_ALANI");
    expect(view).toContain("editableProps(EYLEM_ALANI[buton.anahtar]");
  });

  it("eşleşen alanların hepsi şemada var", () => {
    const blok = view.slice(
      view.indexOf("const EYLEM_ALANI"),
      view.indexOf("};", view.indexOf("const EYLEM_ALANI"))
    );
    const alanlar = [...blok.matchAll(/:\s*"([a-zA-Z]+)"/g)].map((m) => m[1]);
    expect(alanlar.length).toBeGreaterThan(0);
    for (const anahtar of alanlar) {
      expect(
        FIELD_BY_KEY.has(anahtar),
        `"${anahtar}" şemada yok; buton hiçbir alana bağlanmaz.`
      ).toBe(true);
    }
  });

  it("iletişim kartındaki WhatsApp bağlantısı da işaretli", () => {
    expect(view).toContain('editableProps("whatsapp", ownerMode)');
  });

  it("ziyaretçi görünümü etkilenmiyor", () => {
    // editableProps ownerMode kapalıyken boş nesne döner; müşteriye
    // tek öznitelik bile sızmaz (koruma sınırı 3).
    const props = readFileSync(
      resolve(__dirname, "../src/lib/vitrinEditableProps.ts"),
      "utf-8"
    );
    expect(props).toContain("if (!ownerMode) return {};");
  });
});
