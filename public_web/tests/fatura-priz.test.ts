import { afterEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  VARSAYILAN_PRIZ_ADRESI,
  faturaPrizAdresi,
  faturaPrizAnahtari,
  faturaOkumaPresetReferansi,
  faturaPrizZamanSiniri,
  faturaPrizBasliklari,
} from "@/lib/faturaPriz";

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("fatura priz - tak-cikar", () => {
  it("varsayilan OpenRouter fişi calisir", () => {
    vi.stubEnv("OPENROUTER_API_KEY", "sk-or-vixrex-123");
    expect(VARSAYILAN_PRIZ_ADRESI).toBe("https://openrouter.ai/api/v1/chat/completions");
    expect(faturaPrizAdresi()).toBe("https://openrouter.ai/api/v1/chat/completions");
    expect(faturaPrizAnahtari()).toBe("sk-or-vixrex-123");
    expect(faturaOkumaPresetReferansi()).toBe("@preset/vixrex-qwen-fatura-okuma-suzme");
    expect(faturaPrizZamanSiniri()).toBe(240_000);
    expect(faturaPrizBasliklari("sk-or-vixrex-123")).toEqual({
      "Content-Type": "application/json",
      Authorization: "Bearer sk-or-vixrex-123",
      "HTTP-Referer": "https://vixrex.com",
      "X-Title": "Vixrex Fatura",
    });
  });

  it("FATURA_PRIZ_URL ve FATURA_PRIZ_API_KEY ile tak-cikar calisir", () => {
    vi.stubEnv("FATURA_PRIZ_URL", "https://ornek-saglayici.com/v1/chat/completions");
    vi.stubEnv("FATURA_PRIZ_API_KEY", "fk-abc-456");
    expect(faturaPrizAdresi()).toBe("https://ornek-saglayici.com/v1/chat/completions");
    expect(faturaPrizAnahtari()).toBe("fk-abc-456");
  });

  it("FATURA_PRIZ_API_KEY yoksa OPENROUTER_API_KEY fallback calisir", () => {
    vi.stubEnv("FATURA_PRIZ_URL", "https://baska.com/api");
    vi.stubEnv("OPENROUTER_API_KEY", "sk-fallback-789");
    expect(faturaPrizAdresi()).toBe("https://baska.com/api");
    expect(faturaPrizAnahtari()).toBe("sk-fallback-789");
  });

  it("OPENROUTER_BASE_URL verilirse priz adresi buradan uretilir", () => {
    vi.stubEnv("OPENROUTER_BASE_URL", "https://ozel-openrouter.example/api/v1/");
    expect(faturaPrizAdresi()).toBe("https://ozel-openrouter.example/api/v1/chat/completions");
    vi.stubEnv("OPENROUTER_BASE_URL", "https://ozel-openrouter.example/api/v1/chat/completions");
    expect(faturaPrizAdresi()).toBe("https://ozel-openrouter.example/api/v1/chat/completions");
  });

  it("zaman siniri 240 saniye varsayilanidir ve sinirlar dahilinde korunur", () => {
    vi.stubEnv("OPENROUTER_FATURA_TIMEOUT_MS", "600000");
    expect(faturaPrizZamanSiniri()).toBe(600_000);
    vi.stubEnv("OPENROUTER_FATURA_TIMEOUT_MS", "1000");
    expect(faturaPrizZamanSiniri()).toBe(240_000);
    vi.stubEnv("OPENROUTER_FATURA_TIMEOUT_MS", "999999999");
    expect(faturaPrizZamanSiniri()).toBe(240_000);
  });

  it("preset referansi on ek teklami degistirmez", () => {
    vi.stubEnv("OPENROUTER_PRESET", "@preset/ozel");
    expect(faturaOkumaPresetReferansi()).toBe("@preset/ozel");
    vi.stubEnv("OPENROUTER_PRESET", "");
    vi.stubEnv("OPENROUTER_FATURA_PRESET", "eski");
    expect(faturaOkumaPresetReferansi()).toBe("@preset/eski");
  });

  it("faturaGoru.ts kaynak kodunda sabit openrouter.ai URL'i kalmaz", () => {
    const source = readFileSync(
      fileURLToPath(new URL("../src/lib/faturaGoru.ts", import.meta.url)),
      "utf8",
    );
    expect(source).not.toContain("openrouter.ai/api/v1/chat/completions");
  });
});