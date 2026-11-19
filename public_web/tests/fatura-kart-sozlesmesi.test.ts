import { readFileSync } from "node:fs";
import path from "node:path";
import { afterEach, beforeEach, expect, it, vi } from "vitest";

beforeEach(() => vi.stubEnv("PRESET_AKIS", "mevcut"));
afterEach(() => vi.unstubAllEnvs());
import { kartPresetYanitiniOku } from "@/lib/faturaKartPreset";
import {
  KartSozlesmeHatasi,
  kartSozlesmesineCevir,
  kartYanitiniCoz,
  tekKartSozlesmesi,
} from "@/lib/faturaKartSozlesmesi";
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

it("eski akış: geçmiş preset yanıtında farklı barkodlu 5 satır ayrı kart kalır", async () => {
  const sonuc = await kartPresetYanitiniOku(metinYanit(dosya("gercek-citli.txt")), ilkOkuma);
  expect(say(sonuc.sonuc.satirlar)).toEqual({ satir: 5, kart: 5, gorselli: 4 });
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
  expect(say(sonuc.sonuc.satirlar)).toEqual({ satir: 5, kart: 5, gorselli: 4 });
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

it("eski akışta farklı barkodlu satırlar gruplandırılmış olsa bile ayrı kalır", async () => {
  const sonuc = await kartPresetYanitiniOku(metinYanit(dosya("gercek-citli.txt")), ilkOkuma);
  expect(sonuc.sonuc.satirlar[3].ad).toBe("TER0105 Tutku Erkek Penye Sıfır Yaka Fanila");
  expect(sonuc.sonuc.satirlar[4].ad).toBe("TER0105 Tutku Erkek Penye Sıfır Yaka Fanila");
  expect(sonuc.sonuc.satirlar[4].eksikler).not.toContain("Aynı ürün belgede 4. satırda da geçiyor; tek kart açılır.");
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

it("string sources ve null şema alanları güvenli işlenir; geçersiz tip ve boş dizi listesi reddedilir", async () => {
  const kart = tekKartSozlesmesi({
    row_id: "1",
    title: "Test Ürün",
    validation: { status: "verified", official_domain: "baska.com", matched_attributes: null, unmatched_attributes: null },
    media: { selected_image_url: "https://cdn.example/ana.jpg", image_urls: null },
    vixrex_product_json: { title: "Test Ürün", selected_image_url: "https://cdn.example/kart.jpg" },
    sources: ["https://uretici.example/urun-1", "javascript:alert(1)", { url: "https://uretici.example/ek" }],
  });
  expect(kart.resmiSayfa).toBe("https://uretici.example/urun-1");
  expect(kart.dogrulanmis).toBe(true);
  expect(kart.kanitEksigi).toBeNull();
  expect(kart.kaynaklar).toEqual(["https://uretici.example/urun-1", { url: "https://uretici.example/ek" }]);
  expect(kart.gorselAdaylari).toEqual(["https://cdn.example/ana.jpg", "https://cdn.example/kart.jpg"]);

  const belirsiz = tekKartSozlesmesi({
    row_id: "2",
    title: "Belirsiz Ürün",
    validation: { status: "ambiguous" },
    sources: ["https://uretici.example/urun-2"],
  });
  expect(belirsiz.resmiSayfa).toBe("");
  expect(belirsiz.dogrulanmis).toBe(false);

  const cozulen = await kartYanitiniCoz(
    JSON.stringify({
      items: [
        {
          row_id: "1",
          vixrex_product_json: { title: "Null Alanlı Ürün" },
          validation: { status: "verified", matched_attributes: null, unmatched_attributes: null },
          media: { image_urls: null },
          card_status: null,
        },
      ],
    }),
  );
  expect(cozulen.kartlar).toHaveLength(1);

  for (const bozuk of [
    { row_id: "1", vixrex_product_json: { title: "Bozuk" }, validation: { matched_attributes: "metin" } },
    { row_id: "1", vixrex_product_json: { title: "Bozuk" }, media: { image_urls: [123] } },
    { row_id: "1", vixrex_product_json: { title: "Bozuk" }, card_status: 42 },
  ]) {
    await expect(kartYanitiniCoz(JSON.stringify({ items: [bozuk] }))).rejects.toThrow("KART_YANITI_COZULEMEDI");
  }
});

it("kartPresetYanitiniOku çoklu yanıtları, öğeleri ve kullanım metriklerini birleştirir; boş veya hatalı yanıtı reddeder", async () => {
  const yanitUret = (items: unknown[], usage: Record<string, unknown>) =>
    new Response(
      JSON.stringify({
        id: "gen-1",
        model: "test-model",
        choices: [{ message: { content: JSON.stringify({ items }) }, finish_reason: "stop" }],
        usage,
      }),
      { status: 200, headers: { "content-type": "application/json" } },
    );
  const { items } = JSON.parse(dosya("duz-sema.json")) as { items: Array<Record<string, unknown>> };
  const ilk = yanitUret(items.slice(0, 2), { prompt_tokens: 100, completion_tokens: 50, cost: 0.01 });
  const ikinci = yanitUret(items.slice(2, 5), { prompt_tokens: 150, completion_tokens: 75, cost: 0.02 });

  const birlesik = await kartPresetYanitiniOku([ilk, ikinci], ilkOkuma, "mevcut");
  expect(birlesik.sonuc.satirlar).toHaveLength(5);
  expect((birlesik.kartCevabi as { items: unknown[] }).items).toHaveLength(5);
  expect(birlesik.kullanim.girdiToken).toBe(250);
  expect(birlesik.kullanim.ciktiToken).toBe(125);
  expect(birlesik.kullanim.maliyet).toBeCloseTo(0.03, 6);

  await expect(kartPresetYanitiniOku([], ilkOkuma, "yeni")).rejects.toThrow("OKUYUCU_EKSIK_CEVAP");

  const hatali = new Response(JSON.stringify({ error: { code: 404 } }), {
    status: 404,
    headers: { "content-type": "application/json" },
  });
  await expect(
    kartPresetYanitiniOku([yanitUret(items.slice(0, 2), { prompt_tokens: 10, completion_tokens: 5 }), hatali], ilkOkuma, "yeni"),
  ).rejects.toThrow("OKUYUCU_MODEL_BULUNAMADI");
});
