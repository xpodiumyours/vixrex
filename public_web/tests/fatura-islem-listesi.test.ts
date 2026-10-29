import { expect, it } from "vitest";
import { islemAsamasi } from "@/lib/faturaIslemOku";

it("satırı olan iş devam edilebilir sayılır", () => {
  expect(islemAsamasi(13, "processed")).toBe("hazir");
  expect(islemAsamasi(1, null)).toBe("hazir");
});

it("sağlayıcı hâlâ çalışıyorsa iş okunuyor sayılır, devam düğmesi verilmez", () => {
  expect(islemAsamasi(0, "queued")).toBe("okunuyor");
  expect(islemAsamasi(0, "received")).toBe("okunuyor");
});

it("satırı olmayan ve sağlayıcısı bitmiş iş yarıda kalmış sayılır", () => {
  expect(islemAsamasi(0, "failed")).toBe("yarida");
  expect(islemAsamasi(0, null)).toBe("yarida");
  expect(islemAsamasi(0, "")).toBe("yarida");
});
