#!/usr/bin/env node
/**
 * tool/harita_dogrula.mjs
 *
 * Vixrex Haritası notlarındaki dosya sayılarını, gerçek kodu sayarak karşılaştırır.
 * Amaç: harita eskidiğinde bunu sessizce değil, gürültüyle fark ettirmek.
 *
 * Kullanım:
 *   node tool/harita_dogrula.mjs
 *
 * Çıkış kodu: 0 = harita güncel · 1 = harita eskimiş (sayı tutmuyor)
 *
 * Not: "26 tablo" ve "43 RPC" sayıları migration çözümlemesinden gelir;
 * dosya sayımıyla üretilemez, bu script onları denetlemez (elle doğrulanır).
 */

import { readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const KOK = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

/** Dizini özyinelemeli tarar; göreli yolları döndürür. Gizliler ve node_modules atlanır. */
function tara(dir, kosul = () => true) {
  const sonuc = [];
  let girdiler;
  try {
    girdiler = readdirSync(path.join(KOK, dir), { withFileTypes: true });
  } catch {
    return sonuc;
  }
  for (const g of girdiler) {
    if (g.name === "node_modules" || g.name.startsWith(".")) continue;
    const goreli = path.join(dir, g.name).replaceAll("\\", "/");
    if (g.isDirectory()) {
      sonuc.push(...tara(goreli, kosul));
    } else if (g.isFile() && kosul(goreli)) {
      sonuc.push(goreli);
    }
  }
  return sonuc;
}

function say(dir, kosul) {
  return tara(dir, kosul).length;
}

function dizinSayisi(dir) {
  try {
    return readdirSync(path.join(KOK, dir), { withFileTypes: true }).filter(
      (g) => g.isDirectory() && !g.name.startsWith("."),
    ).length;
  } catch {
    return 0;
  }
}

/**
 * Her ölçü: koddaki gerçek sayı (kural) + haritada sayıyı arayan desenler.
 * Desenler 1. yakalama grubunda sayıyı taşır; her eşleşme gerçek sayıyla
 * karşılaştırılır (haritanın neresinde eski sayı varsa rapora düşer).
 */
const OLCUMLER = [
  {
    ad: "ekran",
    kural: "lib/**/*_screen.dart",
    say: () => say("lib", (p) => p.endsWith("_screen.dart")),
    desenler: [
      String.raw`(\d+)\s*ekran\b`,
      String.raw`\|\s*Ekran\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "servis",
    kural: "lib/services/**/*.dart",
    say: () => say("lib/services", (p) => p.endsWith(".dart")),
    desenler: [
      String.raw`(\d+)\s*servis\b`,
      String.raw`\|\s*Servis\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "controller",
    kural: "lib/controllers/**/*.dart",
    say: () => say("lib/controllers", (p) => p.endsWith(".dart")),
    desenler: [
      String.raw`(\d+)\s*controller\b`,
      String.raw`\|\s*Controller\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "repository",
    kural: "lib/**/*_repository.dart",
    say: () => say("lib", (p) => p.endsWith("_repository.dart")),
    desenler: [
      String.raw`(\d+)\s*repository\b`,
      String.raw`\|\s*Repository\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "widget",
    kural: "lib/widgets/**/*.dart",
    say: () => say("lib/widgets", (p) => p.endsWith(".dart")),
    desenler: [
      String.raw`(\d+)\s*widget\b`,
      String.raw`\|\s*Widget\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "model",
    kural: "lib/** (yolu 'model' geçen) *.dart",
    say: () => say("lib", (p) => p.includes("model") && p.endsWith(".dart")),
    desenler: [
      String.raw`(\d+)\s*model\b`,
      String.raw`\|\s*Model\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "web lib",
    kural: "public_web/src/lib/**/*.{ts,tsx}",
    say: () =>
      say("public_web/src/lib", (p) => p.endsWith(".ts") || p.endsWith(".tsx")),
    desenler: [
      String.raw`(\d+)\s*lib\b`,
      String.raw`\|\s*Lib dosyası\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "component",
    kural: "public_web/src/components/**/*.tsx",
    say: () => say("public_web/src/components", (p) => p.endsWith(".tsx")),
    desenler: [
      String.raw`(\d+)\s*component\b`,
      String.raw`\|\s*Component\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "API route",
    kural: "public_web/src/app/api/**/route.ts",
    say: () => say("public_web/src/app/api", (p) => p.endsWith("route.ts")),
    desenler: [
      String.raw`(\d+)\s*API\b`,
      String.raw`(\d+)\s*route\b`,
      String.raw`\|\s*API route\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "migration",
    kural: "supabase/migrations/*",
    say: () => say("supabase/migrations"),
    desenler: [
      String.raw`(\d+)\s*migration\b`,
      String.raw`\|\s*Migration\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "edge function",
    kural: "supabase/functions/ (klasör)",
    say: () => dizinSayisi("supabase/functions"),
    desenler: [
      String.raw`(\d+)\s*Edge Function\b`,
      String.raw`\|\s*Edge Function\b[^|\n]*\|\s*\**(\d+)`,
    ],
  },
  {
    ad: "shared JSON",
    kural: "shared/*.json",
    say: () => say("shared", (p) => p.endsWith(".json")),
    desenler: [String.raw`(\d+)\s*JSON\b`],
  },
  {
    ad: "tool dosya",
    kural: "tool/* (bu script dahil)",
    say: () => say("tool"),
    // 'dosya' sözcüğü başka notlarda da geçtiği için tool/ ile sınırlı aranır
    desenler: [String.raw`tool\/[^\n]*?(\d+)\s*dosya\b`],
  },
];

const HARITA_DESENI = /^Vixrex Haritası.*\.md$/;

function haritaNotlari() {
  return readdirSync(KOK).filter((f) => HARITA_DESENI.test(f));
}

function nottakiEslesmeler(dosya, desen) {
  const metin = readFileSync(path.join(KOK, dosya), "utf8");
  const re = new RegExp(desen, "gi");
  const sonuc = [];
  let m;
  while ((m = re.exec(metin)) !== null) {
    const satir = metin.slice(0, m.index).split("\n").length;
    sonuc.push({ sayi: Number(m[1]), satir, ornek: m[0].trim().slice(0, 60) });
  }
  return sonuc;
}

// ---------------------------------------------------------------------------
const notlar = haritaNotlari();
console.log(`Vixrex Haritası doğrulama — ${notlar.length} not, kod: ${KOK}\n`);

let hata = 0;
const cikti = [];

for (const olcu of OLCUMLER) {
  const gercek = olcu.say();
  const bulunanlar = [];
  for (const not of notlar) {
    for (const desen of olcu.desenler) {
      for (const e of nottakiEslesmeler(not, desen)) {
        bulunanlar.push({ not, ...e });
      }
    }
  }

  const yanlislar = bulunanlar.filter((b) => b.sayi !== gercek);
  const simge = bulunanlar.length === 0 ? "?" : yanlislar.length === 0 ? "✓" : "✗";
  if (yanlislar.length > 0 || bulunanlar.length === 0) hata++;

  const bulunanMetin =
    bulunanlar.length === 0
      ? "haritada sayı yok"
      : [...new Set(bulunanlar.map((b) => b.sayi))].join(", ");
  cikti.push(
    `${simge} ${olcu.ad.padEnd(13)} koddaki: ${String(gercek).padStart(4)}   haritadaki: ${bulunanMetin.padEnd(12)} [${olcu.kural}]`,
  );
  for (const y of yanlislar) {
    cikti.push(`     ↳ ${y.not}:${y.satir} → "${y.ornek}"`);
  }
}

console.log(cikti.join("\n"));

// Wikilink bütünlüğü: kırık [[hedef]] var mı?
console.log("\nWikilink kontrolü:");
const hedefler = new Set();
for (const not of notlar) {
  const metin = readFileSync(path.join(KOK, not), "utf8");
  for (const m of metin.matchAll(/\[\[([^\]|]+)(?:\|[^\]]*)?\]\]/g)) {
    hedefler.add(m[1].trim());
  }
}
const mevcutAdlar = new Set(
  tara(".", (p) => p.endsWith(".md")).map((p) => path.basename(p, ".md")),
);
for (const f of readdirSync(KOK)) {
  if (f.endsWith(".md")) mevcutAdlar.add(f.slice(0, -3));
}
try {
  for (const f of readdirSync(path.join(KOK, "docs"))) {
    if (f.endsWith(".md")) mevcutAdlar.add(f.slice(0, -3));
  }
} catch {
  /* docs yoksa boşver */
}
let kirik = 0;
for (const h of [...hedefler].sort()) {
  if (!mevcutAdlar.has(h)) {
    console.log(`  ✗ kırık: [[${h}]]`);
    kirik++;
    hata++;
  }
}
if (kirik === 0) {
  console.log(`  ✓ ${hedefler.size} benzersiz hedefin hepsi çözülüyor`);
}

console.log(
  "\nElle doğrulanır (bu script denetlemez): 26 tablo, 43 RPC — migration çözümlemesinden.",
);

if (hata > 0) {
  console.log(`\nSONUÇ: harita eskimiş (${hata} sorun). Yukarıdaki sayıları güncelleyin.`);
  process.exit(1);
}
console.log("\nSONUÇ: harita güncel ✓");
