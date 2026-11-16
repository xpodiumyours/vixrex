import fs from "node:fs";
import { describe, expect, it } from "vitest";
import { kartPresetYanitiniOku } from "@/lib/faturaKartPreset";
import { arkaPlanFaturaHatasi } from "@/lib/faturaArkaPlanIslemi";
import type { GoruSonucu } from "@/lib/faturaGoru";

const dizin = "tests/fixtures/fatura-kart";

const akis = (icerik: string): Response => {
  const parcalar = [
    { id: "t", model: "m", choices: [{ index: 0, delta: { content: icerik }, finish_reason: null }] },
    { id: "t", model: "m", choices: [{ index: 0, delta: { content: "" }, finish_reason: "stop" }] },
  ];
  const govde = parcalar.map((parca) => `data: ${JSON.stringify(parca)}\n\n`).join("") + "data: [DONE]\n\n";
  return new Response(govde, { status: 200, headers: { "content-type": "text/event-stream" } });
};

const okuma = (adet: number, ad = (sira: number): string => `Ürün ${sira + 1}`): GoruSonucu =>
  ({
    satirlar: Array.from({ length: adet }, (_, sira) => ({ satirNo: sira + 1, ad: ad(sira), adet: 1 })),
  }) as unknown as GoruSonucu;

const icerik = fs.readFileSync(`${dizin}/12d7718a-parse.icerik.txt`, "utf8");
const json = JSON.parse(icerik) as { items: Array<Record<string, unknown>> };

describe("kart kapsamı", () => {
  it("tam gövde 20 satırın tamamını kartlar", async () => {
    const { sonuc } = await kartPresetYanitiniOku(akis(icerik), okuma(20), "mevcut");
    expect(sonuc.satirlar).toHaveLength(20);
  });

  it("bir satır eksikse fatura işlenmiş sayılmaz", async () => {
    const eksik = JSON.stringify({ ...json, items: json.items.slice(0, 19) });
    await expect(kartPresetYanitiniOku(akis(eksik), okuma(20), "mevcut")).rejects.toThrow("KART_KAPSAMI_EKSIK");
  });

  it("içi boş kart satırı kapatmaz", async () => {
    const bos = JSON.stringify({ items: [{ row_id: "1", validation: { status: "verified" } }] });
    await expect(kartPresetYanitiniOku(akis(bos), okuma(1, () => ""), "mevcut")).rejects.toThrow("KART_KAPSAMI_EKSIK");
  });

  it("yeni yolda bir satır eksikse kalan 19 satır karantinayla döner", async () => {
    const eksik = JSON.stringify({ ...json, items: json.items.slice(0, 19) });
    const { sonuc, karantinadakiSatirlar } = await kartPresetYanitiniOku(akis(eksik), okuma(20), "yeni");
    expect(sonuc.satirlar).toHaveLength(20);
    expect(karantinadakiSatirlar).toEqual([20]);
    expect(sonuc.satirlar[19].dogrulamaDurumu).toBe("Araştırılamadı");
  });

  it("kullanıcıya hiçbir şeyin kaydedilmediği söylenir", () => {
    expect(arkaPlanFaturaHatasi("KART_KAPSAMI_EKSIK")).toContain("kaydedilmedi");
  });
});
