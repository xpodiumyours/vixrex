import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const HEDEFLER = ["vixrex-qwen-fatura-okuma-suzme", "urun-kart-olusturucu"];

function nesne(deger) {
  return deger !== null && typeof deger === "object" && !Array.isArray(deger) ? deger : {};
}

function metin(deger) {
  return typeof deger === "string" ? deger : null;
}

function dizi(deger) {
  return Array.isArray(deger) ? deger : [];
}

export function ayarlariOzetle(slug, yanit) {
  const veri = nesne(nesne(yanit).data);
  const surum = nesne(veri.designated_version);
  const ayarlar = nesne(surum.config);
  if (!surum.version || !surum.config || typeof surum.config !== "object") {
    return { preset: slug, ok: false, hata: "Aktif preset sürümü veya yapılandırması bulunamadı" };
  }
  const model = metin(ayarlar.model);
  const modeller = [...new Set([
    ...(model ? [model] : []),
    ...dizi(ayarlar.models).filter((m) => typeof m === "string"),
    ...dizi(ayarlar.fallbacks).map((m) => metin(nesne(m).model)).filter(Boolean)
  ])];
  const araclar = dizi(ayarlar.tools).map((girdi) => {
    const arac = nesne(girdi);
    return metin(arac.name) || metin(nesne(arac.function).name) || metin(arac.type) || "adı-belirsiz";
  });
  const eklentiler = dizi(ayarlar.plugins).map((girdi) => {
    const eklenti = nesne(girdi);
    return metin(eklenti.id) || metin(eklenti.name) || "adı-belirsiz";
  });
  const aramaAraci = [...araclar, ...eklentiler].some((ad) => /web|search|fetch|browse|internet|tavily|exa|serp/i.test(ad));
  return {
    preset: slug,
    durum: metin(veri.status) || "bilinmiyor",
    surum: typeof surum.version === "number" ? surum.version : null,
    model: model || "belirtilmemiş",
    alternatif_modeller: modeller.filter((m) => m !== model),
    model_listesi_sadece_ucretsiz: modeller.length > 0 && modeller.every((m) => m.endsWith(":free")),
    arac_adlari: araclar,
    eklenti_adlari: eklentiler,
    web_araci_tanimli: aramaAraci,
    tam_ucretsiz_oldugu_kanitlandi: false,
    not: "Bu okuma ücretli bir çıkarım isteği çalıştırmaz. Web aracı ve model maliyeti ayrıca doğrulanmalıdır."
  };
}

export async function presetleriOku({ anahtar, fetcher = fetch, timeoutMs = 15000 } = {}) {
  if (typeof anahtar !== "string" || anahtar.length < 8) {
    throw new Error("OPENROUTER_API_KEY ortam değişkeni eksik.");
  }
  const sonuc = [];
  for (const slug of HEDEFLER) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const yanit = await fetcher(`https://openrouter.ai/api/v1/presets/${encodeURIComponent(slug)}`, {
        method: "GET",
        headers: { Authorization: `Bearer ${anahtar}`, Accept: "application/json" },
        redirect: "error",
        cache: "no-store",
        signal: controller.signal
      });
      if (!yanit.ok) {
        sonuc.push({ preset: slug, hata: `OpenRouter HTTP ${yanit.status}`, ok: false });
        continue;
      }
      const veri = await yanit.json();
      const ozet = ayarlariOzetle(slug, veri);
      sonuc.push({ ...ozet, ok: ozet.ok !== false });
    } catch (hata) {
      sonuc.push({ preset: slug, hata: hata?.name === "AbortError" ? "İstek zaman aşımına uğradı" : "Ayarlar okunamadı", ok: false });
    } finally {
      clearTimeout(timer);
    }
  }
  return sonuc;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const sonuc = await presetleriOku({ anahtar: process.env.OPENROUTER_API_KEY });
    process.stdout.write(`${JSON.stringify({ degisiklik: false, ucretli_model_istegi: false, sonuclar: sonuc }, null, 2)}\n`);
    if (sonuc.some((v) => !v.ok)) process.exitCode = 1;
  } catch (hata) {
    process.stderr.write(`${hata instanceof Error ? hata.message : "Kontrol başarısız."}\n`);
    process.exitCode = 1;
  }
}
