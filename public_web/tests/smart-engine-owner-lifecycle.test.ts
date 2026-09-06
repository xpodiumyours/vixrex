import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  OWNER_ACTION_LIFECYCLE_EVENT,
  ownerLifecycleFromCommand,
  ownerLifecycleRequiresAttention,
  ownerLifecycleStatusText,
  type OwnerActionLifecycleResult,
} from "../src/lib/ownerActionLifecycle";
import type { SmartEngineCommandResult } from "../src/lib/smartEngineCommandClient";

const ROOT = resolve(__dirname, "..");
const read = (path: string) => readFileSync(resolve(ROOT, path), "utf8");

function command(status: SmartEngineCommandResult["status"]): SmartEngineCommandResult {
  return {
    status,
    commandId: "11111111-1111-4111-8111-111111111111",
    draftVersion: 7,
    succeeded: status === "succeeded" || status === "partial_result"
      ? [{
          anahtar: "isletmeAdi",
          deger: "Vixrex Test",
          actionId: "22222222-2222-4222-8222-222222222222",
          draftVersion: 7,
          replayed: false,
        }]
      : [],
    failed: status === "failed" || status === "partial_result"
      ? [{
          anahtar: "website",
          deger: "hatalı",
          actionId: "33333333-3333-4333-8333-333333333333",
          code: "INVALID_VALUE",
          message: "Geçersiz değer.",
        }]
      : [],
    stopped: [],
  };
}

describe("5.7 owner lifecycle sözleşmesi", () => {
  it("authoritative command sonucu lifecycle'a birebir taşınır", () => {
    expect(ownerLifecycleFromCommand(command("succeeded"))).toEqual({
      status: "succeeded",
      commandId: "11111111-1111-4111-8111-111111111111",
      code: undefined,
    });

    expect(ownerLifecycleFromCommand(command("partial_result"))).toEqual({
      status: "partial_result",
      commandId: "11111111-1111-4111-8111-111111111111",
      code: "INVALID_VALUE",
    });
  });

  it("yalnız kullanıcı müdahalesi gereken sonuçlar attention ister", () => {
    const cases: Array<[OwnerActionLifecycleResult["status"], boolean]> = [
      ["no_op", false],
      ["succeeded", false],
      ["needs_input", true],
      ["failed", true],
      ["partial_result", true],
      ["queued_offline", true],
    ];

    for (const [status, expected] of cases) {
      expect(ownerLifecycleRequiresAttention({ status })).toBe(expected);
    }
  });

  it("screen-reader için attention ve success durumlarının okunabilir metni vardır", () => {
    for (const status of [
      "needs_input",
      "succeeded",
      "failed",
      "partial_result",
      "queued_offline",
    ] as const) {
      expect(ownerLifecycleStatusText({ status }).trim().length).toBeGreaterThan(0);
    }
    expect(ownerLifecycleStatusText({ status: "no_op" })).toBe("");
  });

  it("lifecycle event adı tek canonical sabittir", () => {
    expect(OWNER_ACTION_LIFECYCLE_EVENT).toBe("vixrex:owner-action-lifecycle");
  });
});

describe("5.7 FieldInputArea execution/accessibility wiring", () => {
  const input = read("src/app/v/[slug]/components/FieldInputArea.tsx");
  const selection = read("src/app/v/[slug]/hooks/useFieldSelection.ts");
  const css = read("src/app/v/[slug]/ownerStorefrontPolish.css");

  // 5.7 busy state'i yalnız `kaydediliyor` üzerinden tanımlamıştı. 5.9 LOCK 4
  // GPS location bundle'ı coupled transaction (gerçek persistence) yaptı;
  // busy yüzeyi bu yüzden `persistenceSuruyor = kaydediliyor || gpsIsleniyor`
  // üzerinden türüyor. Kural aynı: tek kaynak, keyboard-safe disabled.
  it("duplicate submit ref + gerçek disabled guard kullanır", () => {
    expect(input).toContain("if (gonderRef.current) return;");
    expect(input).toContain(
      "const persistenceSuruyor = kaydediliyor || gpsIsleniyor;",
    );
    expect(input).toContain(
      "const gonderEngelli = persistenceSuruyor || gonderKilitli;",
    );
    expect(input).toContain("if (!gonderEngelli) void gonderVeVitriniGoster();");
    expect(input).toContain("disabled={gonderEngelli}");
  });

  it("executing body class yalnız gerçek persistence state'inden türetilir", () => {
    expect(input).toContain(
      'document.body.classList.toggle("vixrex-asistan-isliyor", persistenceSuruyor)',
    );
    expect(input).not.toContain('classList.add("vixrex-asistan-isliyor")');
  });

  it("lifecycle sonucu explicit event + live-region üzerinden taşınır", () => {
    expect(input).toContain("const sonuc = await gonder();");
    expect(input).toContain("dispatchOwnerActionLifecycle(sonuc);");
    expect(input).toContain("onGonderSonucu?.(sonuc);");
    expect(input).toContain('role="status"');
    expect(input).toContain('aria-live="polite"');
    expect(input).toContain("ownerLifecycleStatusText(sonGonderSonucu)");
  });

  it("attention lifecycle React panel-aç callback'ine bağlanır, success bağlanmaz", () => {
    expect(selection).toContain("OWNER_ACTION_LIFECYCLE_EVENT");
    expect(selection).toContain("ownerLifecycleRequiresAttention(result)");
    expect(selection).toContain("onAlanSecildi?.();");
    expect(selection).not.toContain("querySelector<HTMLButtonElement>");
  });

  it("canonical düğme executing sırasında keyboard-safe disabled + aria-busy olur", () => {
    expect(input).toContain("canonicalButton.disabled = persistenceSuruyor;");
    expect(input).toContain(
      'canonicalButton.setAttribute("aria-busy", persistenceSuruyor ? "true" : "false")',
    );
    expect(input).toContain("aria-busy={persistenceSuruyor}");
  });

  it("reduced-motion spinner'ı durdurur", () => {
    expect(css).toContain("@media (prefers-reduced-motion: reduce)");
    expect(css).toContain("animation: none;");
  });
});
