import { expect, it } from "vitest";
import { faturaOzetSatiri, gecenSaniye } from "@/lib/faturaOzeti";

const kimlik = "1d265b38-6962-4451-b43a-6f1076a20d9a";

it("tek satır rapor biçimi sabittir", () => {
  expect(faturaOzetSatiri({
    islemKimligi: kimlik, satirSayisi: 7, kartSayisi: 7, gorselliSayisi: 7,
    sureSaniye: 246.4, hataKodu: null,
  })).toBe(`Fatura ${kimlik} → 7 satır → 7 kart → 7 görselli → 246 sn → hata: yok`);
});

it("hata kodu satırda görünür", () => {
  expect(faturaOzetSatiri({
    islemKimligi: kimlik, satirSayisi: 7, kartSayisi: 0, gorselliSayisi: 0,
    sureSaniye: 12, hataKodu: "KART_YANITI_COZULEMEDI",
  })).toContain("hata: KART_YANITI_COZULEMEDI");
});

it("ölçülemeyen süre ve görsel sayısı soru işaretiyle yazılır", () => {
  expect(faturaOzetSatiri({
    islemKimligi: kimlik, satirSayisi: 1, kartSayisi: 1, gorselliSayisi: null,
    sureSaniye: null, hataKodu: null,
  })).toBe(`Fatura ${kimlik} → 1 satır → 1 kart → ? görselli → ? sn → hata: yok`);
});

it("geçen süre başlangıç yoksa ölçülmez", () => {
  expect(gecenSaniye(null)).toBeNull();
  expect(gecenSaniye(new Date(Date.now() - 5000).toISOString())).toBeGreaterThanOrEqual(4);
});
