import { expect, it } from "vitest";
import { gomuluIslemOzeti, islemAsamasi } from "@/lib/faturaIslemOku";

it("satırı olan iş devam edilebilir sayılır", () => {
  expect(islemAsamasi(13, "processed")).toBe("hazir");
  expect(islemAsamasi(1, null)).toBe("hazir");
});

it("sağlayıcı hâlâ çalışıyorsa iş okunuyor sayılır, devam düğmesi verilmez", () => {
  expect(islemAsamasi(0, "queued")).toBe("okunuyor");
  expect(islemAsamasi(0, "received")).toBe("okunuyor");
});

it("tek yanıttaki satır sayısı ve sağlayıcı durumu listeye taşınır", () => {
  const hazir = gomuluIslemOzeti({
    id: "a",
    status: "inceleme",
    supplier_name: "Glisa",
    created_at: "2026-10-29T10:00:00Z",
    invoice_job_lines: [{ count: 13 }],
    invoice_provider_runs: [{ state: "processed", error_code: null }],
  });
  expect(hazir).toMatchObject({ satirSayisi: 13, asama: "hazir", tedarikci: "Glisa", hata: null });

  const yarida = gomuluIslemOzeti({
    id: "b",
    status: "eslestirme",
    supplier_name: null,
    created_at: "2026-10-29T10:00:00Z",
    invoice_job_lines: [{ count: 0 }],
    invoice_provider_runs: [{ state: "failed", error_code: "KART_YANITI_COZULEMEDI" }],
  });
  expect(yarida).toMatchObject({ satirSayisi: 0, asama: "yarida", hata: "KART_YANITI_COZULEMEDI" });
});

it("tek satır sayısı nesne olarak da gelebilir", () => {
  const ozet = gomuluIslemOzeti({
    id: "c",
    invoice_job_lines: { count: 4 },
    invoice_provider_runs: { state: "queued", error_code: null },
  });
  expect(ozet).toMatchObject({ satirSayisi: 4, asama: "hazir" });
});

it("satırı olmayan ve sağlayıcısı bitmiş iş yarıda kalmış sayılır", () => {
  expect(islemAsamasi(0, "failed")).toBe("yarida");
  expect(islemAsamasi(0, null)).toBe("yarida");
  expect(islemAsamasi(0, "")).toBe("yarida");
});
