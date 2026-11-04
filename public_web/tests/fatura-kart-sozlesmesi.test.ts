import { readFileSync } from "node:fs";
import path from "node:path";
import { expect, it } from "vitest";
import { kartPresetYanitiniOku } from "@/lib/faturaKartPreset";
import { KartSozlesmeHatasi, kartSozlesmesineCevir } from "@/lib/faturaKartSozlesmesi";
import type { GoruSonucu } from "@/lib/faturaGoru";

const kok = path.resolve(__dirname, "fixtures", "fatura-kart");
const dosya = (ad: string) => readFileSync(path.join(kok, ad), "utf8");
const okuma = JSON.parse(dosya("gercek-okuma.json")) as { satirlar: Array<Record<string, unknown>> };
const ilkOkuma = { tedarikci: "Seher Mensucat", satirlar: okuma.satirlar } as unknown as GoruSonucu;

const metinYanit = (icerik: string) => new Response(JSON.stringify({
  choices: [{ message: { content: icerik }, finish_reason: "stop" }],
}), { status: 200, headers: { "content-type": "application/json" } });

const akisYaniti = (govde: string) => new Response(govde, {
  status: 200, headers: { "content-type": "text/event-stream" },
});

const say = (satirlar: Array<Record<string, unknown>>) => ({
  satir: satirlar.length,
  kart: satirlar.filter((satir) => typeof satir.dogrulamaDurumu === "string").length,
  gorselli: satirlar.filter((satir) => Array.isArray(satir.siteGorseller) && satir.siteGorseller.length > 0).length,
});

it("gerçek çitli yanıt: geçmiş preset yanıtı: 5 satır, 4 kanonik kart, 3 kart görseli", async () => {
  const sonuc = await kartPresetYanitiniOku(metinYanit(dosya("gercek-citli.txt")), ilkOkuma);
  expect(say(sonuc.sonuc.satirlar)).toEqual({ satir: 5, kart: 4, gorselli: 3 });
  expect(sonuc.sonuc.satirlar[2].siteGorseller).toEqual([]);
  expect(sonuc.sonuc.satirlar[2].siteSayfa).toBe("https://sehermensucat.com/kadin-atlet");
  expect(sonuc.sonuc.satirlar[2].dogrulamaDurumu).toBe("Belirsiz");
});

it("gerçek akış yanıtı (text/event-stream): aynı satırları üretir", async () => {
  const akan = await kartPresetYanitiniOku(akisYaniti(dosya("gercek-akis.txt")), ilkOkuma);
  const citli = await kartPresetYanitiniOku(metinYanit(dosya("gercek-citli.txt")), ilkOkuma);
  expect(akan.sonuc.satirlar).toEqual(citli.sonuc.satirlar);
});

it("düz şemalı gerçek yanıt: doğrulama, sayfa ve görsel alanlarını okur", async () => {
  const sonuc = await kartPresetYanitiniOku(metinYanit(dosya("duz-sema.json")), ilkOkuma);
  expect(say(sonuc.sonuc.satirlar)).toEqual({ satir: 5, kart: 4, gorselli: 3 });
  expect(sonuc.sonuc.satirlar[2].siteGorseller).toEqual([]);
  expect(sonuc.sonuc.satirlar[2].siteSayfa).toBe("https://sehermensucat.com/kadin-atlet");
  expect(sonuc.sonuc.satirlar[0].siteSayfa).toBe("https://sehermensucat.com/elt1301-elit-erkek-elastan-sifiryaka-fanila");
  expect(sonuc.sonuc.satirlar[0].dogrulamaDurumu).toBe("Doğrulandı");
  expect(sonuc.sonuc.satirlar[2].dogrulamaDurumu).toBe("Belirsiz");
  const kanit = sonuc.sonuc.satirlar[0].kaynaklar?.[0] as { media?: { image_url?: string } };
  expect(kanit.media?.image_url).toBe(sonuc.sonuc.satirlar[0].siteGorsel);
});

it("aynı girdi aynı çıktı: üç biçim birebir aynı kartları verir", async () => {
  const citli = await kartPresetYanitiniOku(metinYanit(dosya("gercek-citli.txt")), ilkOkuma);
  const duz = await kartPresetYanitiniOku(metinYanit(dosya("duz-sema.json")), ilkOkuma);
  const akan = await kartPresetYanitiniOku(akisYaniti(dosya("gercek-akis.txt")), ilkOkuma);
  expect(duz.sonuc.satirlar).toEqual(citli.sonuc.satirlar);
  expect(akan.sonuc.satirlar).toEqual(citli.sonuc.satirlar);
});

it("geçmiş preset iki farklı bedeni aynı grupta bildirdiyse Vixrex kanonik kararını değiştirmez", async () => {
  const sonuc = await kartPresetYanitiniOku(metinYanit(dosya("gercek-citli.txt")), ilkOkuma);
  expect(sonuc.sonuc.satirlar[3].ad).toBe("TER0105 Tutku Erkek Penye Sıfır Yaka Fanila");
  // Kanonik olmayan satırın özgün fatura adı ve barkodu kaybolmaz.
  expect(sonuc.sonuc.satirlar[4].ad).toBe("TUT ERK SIFIRYAKA");
  expect(sonuc.sonuc.satirlar[4].eksikler).toContain("Aynı ürün belgede 4. satırda da geçiyor; tek kart açılır.");
  expect(sonuc.sonuc.satirlar[3].barkod).not.toBe(sonuc.sonuc.satirlar[4].barkod);
});

it("OpenRouter farklı bedenlere ayrı grup kararı verdiğinde ikisi de kendi kartını alır", async () => {
  const { items } = JSON.parse(dosya("duz-sema.json")) as { items: Array<Record<string, unknown>> };
  const ayriSatirlar = items.map((item) => (item.row_id === "4" || item.row_id === "5")
    ? { ...item, duplicate_group: null, canonical_row_id: null } : item);
  const sonuc = await kartPresetYanitiniOku(metinYanit(JSON.stringify({ items: ayriSatirlar })), ilkOkuma);
  expect(say(sonuc.sonuc.satirlar)).toEqual({ satir: 5, kart: 5, gorselli: 4 });
  expect(sonuc.sonuc.satirlar[3].ad).toBe("TER0105 Tutku Erkek Penye Sıfır Yaka Fanila");
  expect(sonuc.sonuc.satirlar[4].ad).toBe("TER0105 Tutku Erkek Penye Sıfır Yaka Fanila");
  expect(sonuc.sonuc.satirlar[3].barkod).not.toBe(sonuc.sonuc.satirlar[4].barkod);
});

it("okunamayan yanıtta ham cevap hatada saklanır ve kullanıcı mesajı ayrıdır", async () => {
  await expect(kartSozlesmesineCevir("Ürün bulunamadı.")).rejects.toBeInstanceOf(KartSozlesmeHatasi);
  try {
    await kartSozlesmesineCevir("Ürün bulunamadı.");
  } catch (hata) {
    const ozel = hata as KartSozlesmeHatasi;
    expect(ozel.message).toBe("KART_YANITI_COZULEMEDI");
    expect(ozel.hamCevap).toContain("Ürün bulunamadı.");
    expect(String(ozel.cause)).toContain("teknik kayıt");
  }
});
