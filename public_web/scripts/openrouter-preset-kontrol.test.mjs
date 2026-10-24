import test from "node:test";
import assert from "node:assert/strict";
import { ayarlariOzetle, presetleriOku } from "./openrouter-preset-kontrol.mjs";

test("iki preset GET ile okunur, model çağrısı yapılmaz", async () => {
  const istekler = [];
  const fetcher = async (url, init) => {
    istekler.push({ url, method: init.method });
    return { ok: true, json: async () => ({ data: { status: "active", designated_version: { version: 2, system_prompt: "GIZLI_PROMPT", config: { model: "vendor/vision:free", tools: [{ type: "function", function: { name: "web_search" } }] } } } }) };
  };
  const sonuc = await presetleriOku({ anahtar: "sahteanahtar", fetcher });
  assert.equal(sonuc.length, 2);
  assert.equal(sonuc[0].model, "vendor/vision:free");
  assert.equal(sonuc[0].web_araci_tanimli, true);
  assert.equal(sonuc[0].tam_ucretsiz_oldugu_kanitlandi, false);
  assert.deepEqual(istekler.map((x) => x.method), ["GET", "GET"]);
  assert.ok(istekler.every((x) => x.url.startsWith("https://openrouter.ai/api/v1/presets/")));
  assert.equal(JSON.stringify(sonuc).includes("GIZLI_PROMPT"), false);
  assert.equal(JSON.stringify(sonuc).includes("sahteanahtar"), false);
});

test("anahtar yoksa ağ isteği yapılmaz", async () => {
  let sayac = 0;
  await assert.rejects(presetleriOku({ anahtar: "", fetcher: () => { sayac += 1; } }), /eksik/);
  assert.equal(sayac, 0);
});

test("HTTP hatası gövde ve sır olmadan raporlanır", async () => {
  const sonuc = await presetleriOku({ anahtar: "sahteanahtar", fetcher: async () => ({ ok: false, status: 401, json: async () => { throw new Error("Okunmamalı"); } }) });
  assert.equal(sonuc.length, 2);
  assert.equal(sonuc[0].hata, "OpenRouter HTTP 401");
  assert.equal(sonuc[0].ok, false);
});

test("alternatif ücretli modeller varsa ücretsiz diye işaretlenmez", () => {
  const sonuc = ayarlariOzetle("test", { data: { designated_version: { version: 1, config: { model: "vendor/vision:free", models: ["vendor/vision:free", "vendor/paid"], plugins: [{ id: "web" }] } } } });
  assert.equal(sonuc.model_listesi_sadece_ucretsiz, false);
  assert.deepEqual(sonuc.alternatif_modeller, ["vendor/paid"]);
  assert.equal(sonuc.web_araci_tanimli, true);
});

test("geri dönüş modellerinde ücretli seçenek gizlenmez", () => {
  const sonuc = ayarlariOzetle("test", { data: { designated_version: { version: 1, config: { model: "model/a:free", fallbacks: [{ model: "model/b" }] } } } });
  assert.equal(sonuc.model_listesi_sadece_ucretsiz, false);
  assert.deepEqual(sonuc.alternatif_modeller, ["model/b"]);
});

test("aktif sürüm yoksa ayarlar doğrulandı sayılmaz", async () => {
  const sonuc = await presetleriOku({ anahtar: "sahteanahtar", fetcher: async () => ({ ok: true, json: async () => ({ data: { status: "active" } }) }) });
  assert.ok(sonuc.every((item) => item.ok === false));
});
