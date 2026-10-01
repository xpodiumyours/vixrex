#!/usr/bin/env node
// sharp izleme (outputFileTracingIncludes) kapsam denetimi — 2026-10-01.
//
// NEDEN VAR: sharp 0.35.x, linux'ta libvips `.so` dosyalarını ayrı pakette
// (`@img/sharp-libvips-linux-x64`) tutar ve `.node` addon'u oraya RPATH ile
// bağlanır. Next.js'in nft (node file trace) yalnız `require()` zincirini
// statik izler; RPATH/dlop ile açılan `.so` dosyaları izlemeye GİRMEZ.
// Sonuç: derleme yeşil, kurulum tam, ama lambda paketinde `.so` yok → rota
// runtime'da 500 verir (ERR_DLOPEN_FAILED: libvips-cpp.so.8.18.6).
// Çözüm: paketleri `outputFileTracingIncludes` ile AÇIKÇA eklemek.
//
// BU DENETİM O KURALI ZORUNLU KILAR: sharp'e runtime'da transitif ulaşan
// her route `next.config.ts` içindeki SHARP_ROUTES listesinde olmalıdır.
// `import type` derlemede silindiği için runtime'a katkısı yoktur ve
// transitif çözümde dikkate alınmaz.
// E2E bu uçları test etmiyordu; bu yüzden kırılma canlıya kadar görünmedi.

import fs from "node:fs";
import path from "node:path";

const ROOT = process.argv[2] ?? path.resolve(process.cwd());
const SRC = path.join(ROOT, "src");
const CONFIG = path.join(ROOT, "next.config.ts");
const EXT = [".ts", ".tsx", ".js", ".mjs", ".jsx"];

function resolve(spec, fromFile) {
  let base;
  if (spec.startsWith("@/")) base = path.join(SRC, spec.slice(2));
  else if (spec.startsWith(".")) base = path.resolve(path.dirname(fromFile), spec);
  else return null;
  for (const e of EXT) {
    if (fs.existsSync(base + e) && fs.statSync(base + e).isFile()) return base + e;
  }
  for (const e of EXT) {
    const idx = path.join(base, "index" + e);
    if (fs.existsSync(idx)) return idx;
  }
  return null;
}

function runtimeImports(file) {
  const src = fs.readFileSync(file, "utf8");
  const out = [];
  const re = /(?:^|\n)\s*(?:import|export)\s+(type\s+)?([\s\S]*?)from\s*["']([^"']+)["']/g;
  let m;
  while ((m = re.exec(src))) out.push({ spec: m[3], isType: Boolean(m[1]) });
  const dre = /import\(\s*["']([^"']+)["']\s*\)/g;
  while ((m = dre.exec(src))) out.push({ spec: m[1], isType: false });
  return out;
}

const memo = new Map();
const visiting = new Set();
function reachesSharp(file) {
  if (memo.has(file)) return memo.get(file);
  if (visiting.has(file)) return false; // döngü: bu yolda sharp yok
  visiting.add(file);
  let hit = false;
  for (const imp of runtimeImports(file)) {
    if (imp.isType) continue; // tip import runtime'a girmez
    if (imp.spec === "sharp") { hit = true; break; }
    const r = resolve(imp.spec, file);
    if (r && reachesSharp(r)) { hit = true; break; }
  }
  visiting.delete(file);
  memo.set(file, hit);
  return hit;
}

const routes = [];
(function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.isFile() && /^route\.(ts|tsx|js|mjs)$/.test(e.name)) {
      const route = "/" + path.relative(path.join(SRC, "app"), p).split(path.sep).slice(0, -1).join("/");
      routes.push({ route, file: p });
    }
  }
})(SRC);

const sharpRoutes = new Set(routes.filter((r) => reachesSharp(r.file)).map((r) => r.route));

// next.config.ts içindeki SHARP_ROUTES listesini oku.
const config = fs.readFileSync(CONFIG, "utf8");
const block = config.match(/const SHARP_ROUTES = \[([\s\S]*?)\];/);
if (!block) {
  console.error("HATA: next.config.ts içinde SHARP_ROUTES listesi bulunamadı.");
  process.exit(1);
}
const declared = new Set(
  [...block[1].matchAll(/"(\/[^"]*)"/g)].map((m) => m[1]),
);

const missing = [...sharpRoutes].filter((r) => !declared.has(r)).sort();
const stale = [...declared].filter((r) => !sharpRoutes.has(r)).sort();

if (missing.length) {
  console.error("HATA: sharp'e ulaşan uç next.config.ts SHARP_ROUTES listesinde EKSİK:");
  for (const r of missing) console.error("  " + r);
  console.error("Bu uçlar üretimde 500 verir (libvips .so paketlenmez). Listeye ekle.");
  process.exit(1);
}
if (stale.length) {
  console.error("HATA: SHARP_ROUTES listesinde sharp'e ULAŞMAYAN uç var (liste bayatladı):");
  for (const r of stale) console.error("  " + r);
  process.exit(1);
}

console.log(`OK: ${sharpRoutes.size} uç sharp'e ulaşıyor, hepsi izleme listesinde.`);