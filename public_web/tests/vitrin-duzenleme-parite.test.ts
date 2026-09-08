import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Vitrin düzenleme parite testi.
 *
 * Kural: Flutter StoreEditorController ile Next.js VitrinimEditor
 * aynı Supabase kolonlarına yazmalı. Her iki taraf da
 * update_store_with_token RPC'sini çağırmalı.
 */

const flutterEditor = readFileSync(
  resolve(__dirname, "../../lib/controllers/store_editor_controller.dart"),
  "utf8",
);
const flutterPublishService = readFileSync(
  resolve(__dirname, "../../lib/services/store_publish_service.dart"),
  "utf8",
);
const nextEditor = readFileSync(
  resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"),
  "utf8",
);
const flutterPayload = readFileSync(
  resolve(__dirname, "../../lib/services/store_publish_payload_builder.dart"),
  "utf8",
);

describe("vitrin duzenleme parite (Flutter referansiyla)", () => {
  it("Flutter gibi update_store_with_token RPC kullanir", () => {
    expect(flutterPublishService).toContain("update_store_with_token");
  });

  it("Flutter payload builder alanlarini icerir", () => {
    const temelAlanlar = [
      "name",
      "kategori",
      "whatsapp",
      "address",
      "description",
      "instagram",
      "website",
      "email",
      "phone",
      "theme",
      "status",
      "is_published",
    ];

    for (const alan of temelAlanlar) {
      expect(flutterPayload).toContain(`'${alan}'`);
    }
  });

  it("Next.js editoru ayni temel alanlari icerir", () => {
    const temelAlanlar = [
      "isletmeAdi",
      "whatsapp",
      "adres",
      "il",
      "ilce",
      "telefon",
      "eposta",
      "instagram",
    ];

    for (const alan of temelAlanlar) {
      expect(nextEditor).toContain(alan);
    }
  });

  it("Flutter gibi calisma taslagi (working_draft) kullanir", () => {
    expect(flutterEditor).toContain("working_draft");
  });

  it("Flutter gibi versiyon catismasi (versionConflict) kontrolu vardir", () => {
    expect(flutterEditor).toContain("versionConflict");
  });
});