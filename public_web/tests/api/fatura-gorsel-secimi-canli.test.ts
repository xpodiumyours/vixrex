import { afterAll, beforeAll, describe, expect, it } from "vitest";
import fs from "node:fs";
import path from "node:path";
import type { GoruSatiri } from "@/lib/faturaGoru";
import { adayGorselleriniSec } from "@/lib/faturaGorselSecimi";

const CANLI = process.env.GORSEL_SECIM_CANLI === "1";
const KOK = path.resolve(__dirname, "..", "..", "..");
const VERI = path.join(KOK, "tool", "fatura_olcum", "veri");
const EKRAN = path.join(KOK, "tool", "fatura_olcum", "ekran");

const GOFRET = "https://cdn.ornek.example/gofret-36.png";
const POPKEK = "https://cdn.ornek.example/popkek-60.png";
const VITRIN = "https://cdn.ornek.example/vitrin-ekran.png";

const DOSYALAR: Record<string, string> = {
  [GOFRET]: path.join(VERI, "gorsel-ulker.png"),
  [POPKEK]: path.join(VERI, "gorsel-popkek.png"),
  [VITRIN]: path.join(EKRAN, "2026-10-27-vitrin-13-kart.png"),
};

async function yerelFetch(adres: string): Promise<Response> {
  const yol = DOSYALAR[adres];
  if (!yol || !fs.existsSync(yol)) return new Response("yok", { status: 404 });
  return new Response(new Uint8Array(fs.readFileSync(yol)), {
    status: 200,
    headers: { "content-type": "image/png" },
  });
}

function satir(ek: Partial<GoruSatiri> & { ad: string; siteGorseller: string[] }): GoruSatiri {
  return {
    hamSatir: ek.ad,
    model: "",
    barkod: "",
    varyant: "",
    beden: "",
    marka: "",
    adet: 1,
    birim: "Adet",
    birimFiyat: null,
    tutar: null,
    okumaGuveni: 0.9,
    dogrulamaDurumu: "Doğrulandı",
    ...ek,
  };
}

function anahtarOku(): string {
  const icerik = fs.readFileSync(path.join(KOK, "public_web", ".env"), "utf8");
  const satirMetni = icerik
    .split(/\r?\n/)
    .find((l) => l.startsWith("OPENROUTER_MANAGEMENT_API_KEY="));
  if (!satirMetni) throw new Error("OPENROUTER_MANAGEMENT_API_KEY public_web/.env içinde yok");
  return satirMetni.slice("OPENROUTER_MANAGEMENT_API_KEY=".length).trim();
}

async function istek(yol: string, yontem: string, govde: unknown, anahtar: string) {
  const yanit = await fetch("https://openrouter.ai/api/v1" + yol, {
    method: yontem,
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${anahtar}` },
    body: govde === undefined ? undefined : JSON.stringify(govde),
    signal: AbortSignal.timeout(30_000),
  });
  const metin = await yanit.text();
  let cozulen: Record<string, unknown> = {};
  try {
    cozulen = JSON.parse(metin);
  } catch {
    cozulen = {};
  }
  return { kod: yanit.status, yanit: cozulen as { key?: string; data?: { hash?: string } } };
}

let hamIcerik = "";

function sseIcerikBirlestir(metin: string): string {
  if (!metin.includes("data: ")) return metin;
  const parcalar: string[] = [];
  for (const satirMetni of metin.split("\n")) {
    if (!satirMetni.startsWith("data: ") || satirMetni === "data: [DONE]") continue;
    try {
      const parca = JSON.parse(satirMetni.slice(6));
      const delta = parca.choices?.[0]?.delta?.content ?? parca.choices?.[0]?.message?.content ?? "";
      if (typeof delta === "string") parcalar.push(delta);
    } catch {}
  }
  return parcalar.join("");
}

describe.skipIf(!CANLI)("canlı görsel seçimi — gerçek fatura ile @preset/urun-gorsel-secim", () => {
  const eskiAnahtar = process.env.OPENROUTER_API_KEY;
  const gercekFetch = globalThis.fetch.bind(globalThis);
  let geciciHash = "";

  beforeAll(async () => {
    globalThis.fetch = (async (girdi: RequestInfo | URL, init?: RequestInit) => {
      const yanit = await gercekFetch(girdi as never, init);
      try {
        const adres =
          typeof girdi === "string"
            ? girdi
            : girdi instanceof URL
              ? girdi.href
              : (girdi as Request).url;
        if (adres.includes("openrouter.ai/api/v1/chat/completions")) {
          hamIcerik += sseIcerikBirlestir(await yanit.clone().text());
        }
      } catch {}
      return yanit;
    }) as typeof globalThis.fetch;
    const { kod, yanit } = await istek(
      "/keys",
      "POST",
      {
        name: "vixrex-gorsel-secim-canli-" + Date.now(),
        limit: 1,
        expires_at: new Date(Date.now() + 3600_000).toISOString(),
        include_byok_in_limit: true,
      },
      anahtarOku(),
    );
    if (kod < 200 || kod > 299 || !yanit.key) throw new Error("GECICI_ANAHTAR_YOK: " + kod);
    process.env.OPENROUTER_API_KEY = yanit.key;
    geciciHash = yanit.data?.hash ?? "";
  });

  afterAll(async () => {
    globalThis.fetch = gercekFetch;
    if (eskiAnahtar === undefined) delete process.env.OPENROUTER_API_KEY;
    else process.env.OPENROUTER_API_KEY = eskiAnahtar;
    if (geciciHash) await istek("/keys/" + geciciHash, "DELETE", undefined, anahtarOku());
  });

  it(
    "gerçek fatura satırlarında doğru ürün fotoğrafı ilk sıraya geçer, vitrin ekranı ürün fotoğrafı olarak kalmaz",
    async () => {
      const satirlar: GoruSatiri[] = [
        satir({
          ad: "ÜLKER ÇİKOLATALI GOFRET 36 GR",
          barkod: "8690504020509",
          siteGorseller: [POPKEK, VITRIN, GOFRET],
        }),
        satir({
          ad: "ETİ POPKEK KAKAOLU 60 GR",
          barkod: "8690526083711",
          siteGorseller: [VITRIN, GOFRET, POPKEK],
        }),
      ];

      const sonuc = await adayGorselleriniSec({
        satirlar,
        bagimliliklar: { fetcher: yerelFetch },
      });

      console.log(
        "CANLI_SECIM",
        JSON.stringify(
          sonuc.map((s) => ({ ad: s.ad, sira: s.siteGorseller })),
          null,
          2,
        ),
      );
      console.log("HAM_YANIT", hamIcerik);

      expect(sonuc[0].siteGorsel).toBe(GOFRET);
      expect(sonuc[1].siteGorsel).toBe(POPKEK);
    },
    240_000,
  );
});
