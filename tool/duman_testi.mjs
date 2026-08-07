#!/usr/bin/env node
//
// Duman testi — canlı ortam gerçekten çalışıyor mu?
//
// NEDEN VAR
// 2026-08-06/07'de kod doğruydu, canlı yanlıştı. Derleme betiği boş bir
// ayar geçiriyordu; uygulama vitrin linklerini KENDİ adresiyle kuruyordu.
// Testler yeşildi, Casper bir saat boyunca çalışmayan bir akışı deneyip
// "her şeyi bozmuşsun" dedi. Haklıydı: kimse canlıya bakıp ölçmemişti.
//
// Bu betik o boşluğu kapatır. Her dağıtımdan SONRA çalışır; Casper'a
// "test edebilirsin" denmeden önce yeşil olmalıdır.
//
// KULLANIM
//   node tool/duman_testi.mjs                  (canlı ortam)
//   node tool/duman_testi.mjs --slug=koton     (belirli bir vitrinle)
//
// Çıkış kodu: hepsi geçerse 0, bir tanesi bile kırmızıysa 1.

import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const KOK = resolve(dirname(fileURLToPath(import.meta.url)), "..");

const UYGULAMA = "https://vixrex-app.vercel.app";
const VITRIN = "https://vixrex-public.vercel.app";

const sonuclar = [];

function kaydet(ad, gecti, ayrinti = "") {
  sonuclar.push({ ad, gecti, ayrinti });
  const isaret = gecti ? "\x1b[32m✓\x1b[0m" : "\x1b[31m✗\x1b[0m";
  console.log(`${isaret} ${ad}${ayrinti ? `\n    ${ayrinti}` : ""}`);
}

async function iste(url, secenekler = {}) {
  const denetleyici = new AbortController();
  const zaman = setTimeout(() => denetleyici.abort(), 45_000);
  try {
    return await fetch(url, {
      redirect: "manual",
      signal: denetleyici.signal,
      ...secenekler,
    });
  } finally {
    clearTimeout(zaman);
  }
}

/** public_web/.env.local'dan Supabase bilgilerini okur. */
function supabaseBilgisi() {
  const yol = resolve(KOK, "public_web/.env.local");
  const cevre = { ...process.env };
  if (existsSync(yol)) {
    for (const satir of readFileSync(yol, "utf-8").split("\n")) {
      const t = satir.trim();
      if (!t || t.startsWith("#") || !t.includes("=")) continue;
      const [a, ...kalan] = t.split("=");
      cevre[a] = kalan.join("=").trim().replace(/^"|"$/g, "");
    }
  }
  return {
    url: cevre.NEXT_PUBLIC_SUPABASE_URL || cevre.SUPABASE_URL,
    anahtar: cevre.NEXT_PUBLIC_SUPABASE_ANON_KEY || cevre.SUPABASE_PUBLISHABLE_KEY,
  };
}

/** Test için yayınlanmış bir vitrin bulur. */
async function vitrinBul(sb) {
  const arg = process.argv.find((a) => a.startsWith("--slug="));
  if (arg) return arg.slice(7);
  if (!sb.url || !sb.anahtar) return null;

  const y = await iste(
    `${sb.url}/rest/v1/stores?select=slug&is_published=eq.true&limit=1`,
    { headers: { apikey: sb.anahtar, Authorization: `Bearer ${sb.anahtar}` } }
  );
  if (!y.ok) return null;
  const veri = await y.json();
  return veri[0]?.slug ?? null;
}

// ---------------------------------------------------------------- testler

async function uygulamaAcilir() {
  const y = await iste(`${UYGULAMA}/`);
  kaydet("Uygulama açılıyor", y.status === 200, `durum ${y.status}`);
}

// Bugünün hatası buydu: uygulama linkleri kendi adresiyle kuruyordu.
async function linkAdresiDogru() {
  const y = await iste(`${UYGULAMA}/main.dart.js`);
  if (y.status !== 200) {
    kaydet("Uygulama kodu okunuyor", false, `durum ${y.status}`);
    return;
  }
  const kod = await y.text();
  const dogru = (kod.match(/vixrex-public\.vercel\.app/g) || []).length;
  kaydet(
    "Uygulama vitrin adresini biliyor",
    dogru >= 2,
    dogru >= 2
      ? `${dogru} yerde geçiyor`
      : `YALNIZ ${dogru} yerde geçiyor — PUBLIC_SITE_URL boş olabilir, ` +
        `linkler uygulamanın kendi adresiyle kurulur`
  );
}

async function vitrinYonlendirmesi(slug) {
  const y = await iste(`${UYGULAMA}/v/${slug}`);
  const hedef = y.headers.get("location") ?? "";
  kaydet(
    "Uygulamadaki vitrin yolu vitrin sitesine yönlendiriyor",
    y.status >= 300 && y.status < 400 && hedef.includes("vixrex-public"),
    `durum ${y.status} → ${hedef || "yönlendirme yok"}`
  );
}

async function vitrinAcilir(slug) {
  const y = await iste(`${VITRIN}/v/${slug}`);
  kaydet("Vitrin açılıyor", y.status === 200, `/v/${slug} → durum ${y.status}`);
  return y.status === 200 ? await y.text() : "";
}

// Koruma sınırı 3: sahip araçları müşteri yanıtına sızmaz.
function sahipPaneliSizmiyor(html) {
  const izler = [
    "Sahip Çalışma Alanı",
    "data-vixrex-editable",
    "Taslak önizleme",
    "vixrex-secili-alan",
  ].filter((iz) => html.includes(iz));

  kaydet(
    "Çerezsiz ziyaretçiye sahip paneli sızmıyor",
    izler.length === 0,
    izler.length === 0 ? "temiz" : `SIZAN: ${izler.join(", ")}`
  );
}

async function sahipOturumuYoluVar() {
  // Parametresiz çağrı 400 + Türkçe hata sayfası dönmeli. Bu, yolun DOĞRU
  // alan adında var olduğunu kanıtlar; bugün karşılama sayfasına düşüyordu.
  const y = await iste(`${VITRIN}/api/owner-session`);
  const govde = y.status === 400 ? await y.text() : "";
  kaydet(
    "Sahip oturumu yolu vitrin sitesinde",
    y.status === 400 && govde.includes("Vitrin bulunamadı"),
    `durum ${y.status}`
  );
}

async function kokYonlendirmesi() {
  const y = await iste(`${VITRIN}/`);
  kaydet(
    "Vitrin sitesinin kökü uygulamaya yönlendiriyor",
    y.status >= 300 && y.status < 400,
    `durum ${y.status} → ${y.headers.get("location") ?? "-"}`
  );
}

async function veritabaniYollari(sb) {
  if (!sb.url || !sb.anahtar) {
    kaydet("Veritabanı yolları", false, "Supabase bilgisi bulunamadı");
    return;
  }
  const cagrilar = {
    consume_owner_session: { p_slug: "yok", p_code: "000000" },
    get_working_draft_for_session: { p_session_token: "0".repeat(64) },
    publish_working_draft: { p_session_token: "0".repeat(64) },
    discard_working_draft: { p_session_token: "0".repeat(64) },
  };

  const eksik = [];
  for (const [ad, gonderi] of Object.entries(cagrilar)) {
    const y = await iste(`${sb.url}/rest/v1/rpc/${ad}`, {
      method: "POST",
      headers: {
        apikey: sb.anahtar,
        Authorization: `Bearer ${sb.anahtar}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(gonderi),
    });
    // PGRST202 = böyle bir fonksiyon yok. Başka hata "var ama reddetti" demek.
    const govde = await y.text();
    if (govde.includes("PGRST202")) eksik.push(ad);
  }

  kaydet(
    "Sahip oturumu veritabanı yolları yerinde",
    eksik.length === 0,
    eksik.length === 0 ? "4/4" : `EKSİK: ${eksik.join(", ")}`
  );
}

// ------------------------------------------------------------------- akış

console.log("\nVixRex duman testi — canlı ortam\n");

const sb = supabaseBilgisi();
const slug = await vitrinBul(sb);

if (!slug) {
  console.error(
    "Test edilecek yayınlanmış vitrin bulunamadı.\n" +
      "--slug=<vitrin-adi> ile elle verebilirsin.\n"
  );
  process.exit(1);
}

console.log(`Test vitrini: ${slug}\n`);

await uygulamaAcilir();
await linkAdresiDogru();
await vitrinYonlendirmesi(slug);
const html = await vitrinAcilir(slug);
if (html) sahipPaneliSizmiyor(html);
await sahipOturumuYoluVar();
await kokYonlendirmesi();
await veritabaniYollari(sb);

const kirmizi = sonuclar.filter((s) => !s.gecti);
console.log(
  `\n${sonuclar.length - kirmizi.length}/${sonuclar.length} geçti` +
    (kirmizi.length ? ` — ${kirmizi.length} KIRMIZI\n` : "\n")
);

process.exit(kirmizi.length ? 1 : 0);
