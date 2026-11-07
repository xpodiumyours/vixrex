import { describe, expect, it, beforeAll } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";
import { arkaPlanFaturaSonucunuAl } from "@/lib/faturaArkaPlanIslemi";

beforeAll(() => {
  process.env.OPENROUTER_API_KEY = "test-anahtar";
});

type Cagri = { ad: string; args: Record<string, unknown> };

const sorgu = {
  select: () => sorgu,
  eq: () => sorgu,
  order: () => sorgu,
  limit: () => sorgu,
  insert: () => sorgu,
  update: () => sorgu,
  upsert: () => sorgu,
  delete: () => sorgu,
  maybeSingle: async () => ({
    data: { created_at: new Date().toISOString(), discovery_state: {} },
    error: null,
  }),
  single: async () => ({ data: null, error: null }),
  then: (coz: (deger: unknown) => unknown) => coz({ data: null, error: null }),
};

const sahteAdmin = (cagrilar: Cagri[], sonuc: Record<string, unknown>, sinif: string) =>
  ({
    rpc: async (ad: string, args: Record<string, unknown>) => {
      cagrilar.push({ ad, args });
      if (ad === "get_invoice_provider_response") return { data: sonuc, error: null };
      if (ad === "invoice_error_class") return { data: sinif, error: null };
      if (ad === "invoice_backoff_ms") return { data: 1, error: null };
      return { data: { success: true }, error: null };
    },
    from: () => sorgu,
  }) as unknown as SupabaseClient;

const temel = {
  state: "received",
  stage: "cards",
  contentType: "application/json",
  body: JSON.stringify({ error: { code: 401 } }),
  error: null,
  fingerprint: "a".repeat(64),
  attempts: 0,
  readResult: { satirlar: [{ ad: "Ürün", satirNo: 1, adet: 1 }] },
};

const olaylar = (cagrilar: Cagri[]) =>
  cagrilar.filter((c) => c.ad === "record_invoice_job_event").map((c) => c.args);

describe("deneme yolu", () => {
  it("anahtar hatasında tekrar denemez ve işi bitirir", async () => {
    const cagrilar: Cagri[] = [];
    const admin = sahteAdmin(cagrilar, { ...temel, httpStatus: 401 }, "permanent");
    await expect(arkaPlanFaturaSonucunuAl(admin, "s", "x", "j")).rejects.toThrow("ANAHTAR_GECERSIZ");
    const adlar = cagrilar.map((c) => c.ad);
    expect(adlar).not.toContain("retry_invoice_provider_job");
    expect(adlar).toContain("fail_invoice_provider_job");
    const [olay] = olaylar(cagrilar);
    expect(olay.p_to_state).toBe("failed");
    expect(olay.p_error_class).toBe("permanent");
    expect(olay.p_reason_code).toBe("ANAHTAR_GECERSIZ");
  });

  it("geçici hatada bir kez yeniden dener ve kuyruğa döner", async () => {
    const cagrilar: Cagri[] = [];
    const admin = sahteAdmin(cagrilar, { ...temel, httpStatus: 503 }, "transient");
    const sonuc = await arkaPlanFaturaSonucunuAl(admin, "s", "x", "j");
    expect(sonuc.hazirlaniyor).toBe(true);
    const tekrar = cagrilar.filter((c) => c.ad === "retry_invoice_provider_job");
    expect(tekrar).toHaveLength(1);
    expect(tekrar[0].args.p_body).toBeTruthy();
    expect(cagrilar.some((c) => c.ad === "fail_invoice_provider_job")).toBe(false);
    const [olay] = olaylar(cagrilar);
    expect(olay.p_to_state).toBe("queued");
    expect(olay.p_reason_code).toBe("GECICI_TEKRAR");
  });

  it("üçüncü denemede tekrar denemeyi keser", async () => {
    const cagrilar: Cagri[] = [];
    const admin = sahteAdmin(cagrilar, { ...temel, httpStatus: 503, attempts: 2 }, "transient");
    await expect(arkaPlanFaturaSonucunuAl(admin, "s", "x", "j")).rejects.toThrow("OKUYUCU_GECICI_HATA");
    expect(cagrilar.map((c) => c.ad)).not.toContain("retry_invoice_provider_job");
    const [olay] = olaylar(cagrilar);
    expect(olay.p_attempt).toBe(3);
    expect(olay.p_to_state).toBe("failed");
  });

  it("okuma aşamasında geçici hatada yeniden ateşlemez", async () => {
    const cagrilar: Cagri[] = [];
    const admin = sahteAdmin(cagrilar, { ...temel, stage: "reading", httpStatus: 503 }, "transient");
    await expect(arkaPlanFaturaSonucunuAl(admin, "s", "x", "j")).rejects.toThrow("OKUYUCU_GECICI_HATA");
    expect(cagrilar.map((c) => c.ad)).not.toContain("retry_invoice_provider_job");
  });
});
