import { describe, expect, it } from "vitest";
import { faturaYanitiniOku } from "@/lib/faturaGoru";
import { kartSozlesmesineCevir } from "@/lib/faturaKartSozlesmesi";

const frame = (data: unknown) => `data: ${JSON.stringify(data)}\n\n`;
const cevap = (govde: string) => new Response(govde, { headers: { "content-type": "text/event-stream" } });
const bitis = "data: [DONE]\n\n";

describe("Kesik cevap sözleşmesi", () => {
  it("length ile biten okuma cevabındaki tamamlanmış satırlar korunur", async () => {
    const icerik = '{"tedarikci":"X GIDA","satirlar":[{"ham_satir":"1","ad":"Kalem A","adet":2},'
      + '{"ham_satir":"2","ad":"Kalem B"},{"ham_satir":"3","ad":"Yarım';
    const govde = frame({ choices: [{ index: 0, delta: { content: icerik }, finish_reason: null }] })
      + frame({ choices: [{ index: 0, delta: {}, finish_reason: "length" }], usage: { cost: 0.02 } })
      + bitis;
    const sonuc = await faturaYanitiniOku(cevap(govde));
    expect(sonuc.kesik).toBe(true);
    expect(sonuc.satirlar.map((satir) => satir.ad)).toEqual(["Kalem A", "Kalem B"]);
    expect(sonuc.satirlar[0].adet).toBe(2);
    expect(sonuc.uyarilar).toContain("OKUYUCU_KESIK_CEVAP");
    expect(sonuc.maliyet).toBe(0.02);
  });

  it("length yoksa bozuk JSON eskisi gibi reddedilir", async () => {
    const govde = frame({ choices: [{ index: 0, delta: { content: '{"satirlar":[{"ad":"A"}]' }, finish_reason: "stop" }] }) + bitis;
    await expect(faturaYanitiniOku(cevap(govde))).rejects.toThrow("OKUMA_COZULEMEDI");
  });

  it("araç çağrısı parçaları birleşir ve cevap gövdesi olarak çözülür", async () => {
    const ilk = frame({ choices: [{ index: 0, delta: { tool_calls: [{
      index: 0, id: "c1", type: "function", function: { name: "fatura", arguments: '{"satirlar":[{"ad":"Kalem A","adet":1' },
    }] }, finish_reason: null }] });
    const son = frame({ choices: [{ index: 0, delta: { tool_calls: [{ index: 0, function: { arguments: "}]}" } }] }, finish_reason: "tool_calls" }] });
    const sonuc = await faturaYanitiniOku(cevap(ilk + son + bitis));
    expect(sonuc.satirlar.map((satir) => satir.ad)).toEqual(["Kalem A"]);
  });

  it("kart aşamasında kesik cevaptan tamamlanmış kartlar korunur", async () => {
    const icerik = '{"items":[{"row_id":"r1","ad":"Kalem A"},{"row_id":"r2","ad":"Kalem';
    const govde = frame({ choices: [{ index: 0, delta: { content: icerik }, finish_reason: null }] })
      + frame({ choices: [{ index: 0, delta: {}, finish_reason: "length" }] }) + bitis;
    const kartlar = await kartSozlesmesineCevir(cevap(govde));
    expect(kartlar.map((kart) => kart.rowId)).toEqual(["r1"]);
  });

  it("200 içinde gelen sağlayıcı hatası gerçek koda çevrilir", async () => {
    await expect(faturaYanitiniOku(cevap(frame({ error: { code: 402, message: "Insufficient credits" } }) + bitis)))
      .rejects.toThrow("OKUYUCU_BAKIYE_BITTI");
    await expect(faturaYanitiniOku(cevap(frame({ error: { code: 401, message: "No auth credentials" } }) + bitis)))
      .rejects.toThrow("OKUYUCU_ANAHTAR_GECERSIZ");
  });
  it("length olsa da kurtarılacak satır yoksa reddedilir", async () => {
    const govde = frame({ choices: [{ index: 0, delta: { content: "{\"tedarikci\":\"X\",\"satirlar\":[" }, finish_reason: null }] })
      + frame({ choices: [{ index: 0, delta: {}, finish_reason: "length" }] }) + bitis;
    await expect(faturaYanitiniOku(cevap(govde))).rejects.toThrow("OKUMA_COZULEMEDI");
  });

});
