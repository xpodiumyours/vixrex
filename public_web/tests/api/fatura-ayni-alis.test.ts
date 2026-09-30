import { describe, expect, it, vi } from "vitest";
import { ayniAlisIsiniBul } from "@/lib/faturaIslemKaydi";

// Aynı alışverişin farklı fotoğrafı aynı işe bağlanır:
// bilgi fişi + e-Arşiv faturası 8 adedi 16 yapmaz.

const isler = vi.hoisted(() => ({ liste: [] as Array<Record<string, unknown>> }));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    from: () => ({
      select: () => ({
        eq: () => ({
          order: () => ({
            limit: async () => ({ data: isler.liste, error: null }),
          }),
        }),
      }),
    }),
  }),
}));

describe("ayni alis isi", () => {
  it("belge no yoksa aramaz, null doner", async () => {
    isler.liste = [{ id: "is-1", document_fingerprint: "a", supplier_trace: { belgeNo: "1" } }];
    expect(
      await ayniAlisIsiniBul({ storeId: "magaza", tedarikci: "Glisa", belgeNo: null, belgeTarihi: null }),
    ).toBeNull();
    expect(
      await ayniAlisIsiniBul({ storeId: "magaza", tedarikci: "Glisa", belgeNo: "  ", belgeTarihi: "" }),
    ).toBeNull();
  });

  it("ayni belge no + tarih ayni isi bulur", async () => {
    isler.liste = [
      {
        id: "is-9",
        document_fingerprint: "parmak-9",
        supplier_trace: { belgeNo: "2026/123", belgeTarihi: "2026-09-30" },
      },
    ];
    const sonuc = await ayniAlisIsiniBul({
      storeId: "magaza",
      tedarikci: "Glisa",
      belgeNo: "2026/123",
      belgeTarihi: "2026-09-30",
    });
    expect(sonuc).toEqual({ id: "is-9", parmakIzi: "parmak-9" });
  });

  it("tarih ikisinde de yaziyor ve tutmuyorsa baska istir", async () => {
    isler.liste = [
      {
        id: "is-9",
        document_fingerprint: "parmak-9",
        supplier_trace: { belgeNo: "2026/123", belgeTarihi: "2026-09-29" },
      },
    ];
    expect(
      await ayniAlisIsiniBul({
        storeId: "magaza",
        tedarikci: "Glisa",
        belgeNo: "2026/123",
        belgeTarihi: "2026-09-30",
      }),
    ).toBeNull();
  });

  it("farkli belge no baska istir", async () => {
    isler.liste = [
      {
        id: "is-9",
        document_fingerprint: "parmak-9",
        supplier_trace: { belgeNo: "2026/123", belgeTarihi: "2026-09-30" },
      },
    ];
    expect(
      await ayniAlisIsiniBul({
        storeId: "magaza",
        tedarikci: "Glisa",
        belgeNo: "2026/124",
        belgeTarihi: "2026-09-30",
      }),
    ).toBeNull();
  });
});
