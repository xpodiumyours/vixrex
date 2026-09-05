import { describe, expect, it } from "vitest";
import {
  createPendingEnvelope,
  parsePendingEnvelope,
} from "../src/lib/vixrexPendingContract";

describe("Vixrex pending envelope v1", () => {
  it("v1 envelope legacy uyum alanlarını da taşır", () => {
    const slot = createPendingEnvelope({
      fieldKey: "telefon",
      fieldType: "telefon",
      fieldLabel: "Telefon",
      kind: "missing_value",
      createdAt: "2026-09-05T12:00:00.000Z",
    });

    expect(slot).toMatchObject({
      schemaVersion: 1,
      domain: "storefront",
      kind: "missing_value",
      fieldKey: "telefon",
      anahtar: "telefon",
      tip: "telefon",
      deneme: 1,
    });
  });

  it("eski pending kaydını v1 envelope'a normalize eder", () => {
    const slot = parsePendingEnvelope({
      anahtar: "adres",
      etiket: "Açık Adres",
      tip: "uzunMetin",
      sorulduAt: "2026-09-05T12:00:00.000Z",
      deneme: 2,
    });

    expect(slot).toMatchObject({
      schemaVersion: 1,
      domain: "storefront",
      kind: "missing_value",
      fieldKey: "adres",
      fieldType: "uzunMetin",
      fieldLabel: "Açık Adres",
      attempt: 2,
    });
  });

  it("yanlış domain/schema state'ini reddeder", () => {
    expect(
      parsePendingEnvelope({
        schemaVersion: 99,
        domain: "storefront",
        kind: "missing_value",
        fieldKey: "telefon",
      }),
    ).toBeNull();

    expect(
      parsePendingEnvelope({
        schemaVersion: 1,
        domain: "blog",
        kind: "missing_value",
        fieldKey: "telefon",
      }),
    ).toBeNull();
  });
});
