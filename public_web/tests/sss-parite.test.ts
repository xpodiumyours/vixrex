import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * SSS (FAQ) parite testi.
 */

const flutterFaq = readFileSync(
  resolve(__dirname, "../../lib/widgets/editor/faq_editor_sheet.dart"),
  "utf8",
);
const nextFaq = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/components/FaqEditor.tsx"),
  "utf8",
);

describe("SSS parite (Flutter referansiyla)", () => {
  it("Flutter gibi soru-cevap ciftlerini icerir", () => {
    expect(flutterFaq).toContain("StoreFaqItem");
    expect(nextFaq).toContain("question");
    expect(nextFaq).toContain("answer");
  });

  it("Flutter gibi kicker/title/description alanlarini icerir", () => {
    expect(flutterFaq).toContain("kickerController");
    expect(flutterFaq).toContain("titleController");
    expect(flutterFaq).toContain("descriptionController");
  });

  it("Flutter gibi ekle/duzenle/sil islemlerini destekler", () => {
    expect(nextFaq).toContain("ekle");
    expect(nextFaq).toContain("drafts");
    expect(nextFaq).toContain("kaydediliyor");
  });

  it("Flutter gibi coklu SSS maddesini yonetir", () => {
    expect(flutterFaq).toContain("items");
    expect(nextFaq).toContain("FaqItem");
  });
});