import fs from "node:fs";
import path from "node:path";

const ROOT = path.resolve(process.argv[2] ?? process.cwd());
const SRC = path.join(ROOT, "src");
const CONFIG = path.join(ROOT, "next.config.ts");
const CODE_FILE_RE = /\.(ts|tsx|js|mjs|jsx)$/;
const SELECT_STAR_RE = /\.select\(\s*["'`]\s*\*(?:\s*,|\s*["'`])/;
const DIRECT_STORAGE_UPLOAD_RE = /\.storage\s*\.from\([\s\S]{0,120}?\)\s*\.upload\s*\(/;
const CACHE_SECONDS_RE = /\bONBELLEK_SANIYE\s*=\s*["']31536000["']/;

function toPosix(filePath) {
  return filePath.split(path.sep).join("/");
}

function walkCodeFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walkCodeFiles(fullPath));
    } else if (entry.isFile() && CODE_FILE_RE.test(entry.name)) {
      files.push(fullPath);
    }
  }
  return files;
}

function readRequired(filePath, relLabel, errors) {
  if (!fs.existsSync(filePath)) {
    errors.push(`Eksik dosya: ${relLabel}`);
    return null;
  }
  return fs.readFileSync(filePath, "utf8");
}

function extractCallBlocks(content, fnName) {
  const blocks = [];
  const pattern = new RegExp(`\\b${fnName}\\s*\\(`, "g");
  let match;
  while ((match = pattern.exec(content))) {
    const start = match.index + match[0].length - 1;
    let depth = 0;
    let quote = null;
    let escaped = false;
    for (let i = start; i < content.length; i += 1) {
      const ch = content[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (quote) {
        if (ch === "\\") {
          escaped = true;
        } else if (ch === quote) {
          quote = null;
        }
        continue;
      }
      if (ch === '"' || ch === "'" || ch === "`") {
        quote = ch;
        continue;
      }
      if (ch === "(") {
        depth += 1;
      } else if (ch === ")") {
        depth -= 1;
        if (depth === 0) {
          blocks.push(content.slice(match.index, i + 1));
          break;
        }
      }
    }
  }
  return blocks;
}

function checkSelectStar(errors) {
  const targetDirs = [
    path.join(SRC, "app", "v"),
    path.join(SRC, "app", "sitemap.xml"),
    path.join(SRC, "app", "(site)", "kesfet"),
  ];
  for (const dir of targetDirs) {
    for (const file of walkCodeFiles(dir)) {
      const content = fs.readFileSync(file, "utf8");
      if (SELECT_STAR_RE.test(content)) {
        errors.push(`Yasak select("*") kullanimi: ${toPosix(path.relative(ROOT, file))}`);
      }
    }
  }
}

function checkUnstableCacheRevalidate(content, relLabel, minSeconds, errors) {
  const blocks = extractCallBlocks(content, "unstable_cache");
  if (blocks.length === 0) {
    errors.push(`${relLabel} icinde unstable_cache bulunamadi.`);
    return;
  }
  for (const block of blocks) {
    const match = /\brevalidate\s*:\s*(\d+)/.exec(block);
    if (!match) {
      errors.push(`${relLabel} unstable_cache icinde revalidate degeri eksik.`);
      continue;
    }
    const seconds = Number(match[1]);
    if (!Number.isFinite(seconds) || seconds < minSeconds) {
      errors.push(`${relLabel} unstable_cache revalidate=${seconds} < ${minSeconds}.`);
    }
  }
}

function checkExportRevalidate(content, relLabel, minSeconds, errors) {
  const match = /\bexport\s+const\s+revalidate\s*=\s*(\d+)/.exec(content);
  if (!match) {
    errors.push(`${relLabel} icinde export const revalidate eksik.`);
    return;
  }
  const seconds = Number(match[1]);
  if (!Number.isFinite(seconds) || seconds < minSeconds) {
    errors.push(`${relLabel} revalidate=${seconds} < ${minSeconds}.`);
  }
}

function checkSitemapThresholds(errors) {
  const relLabel = "src/app/sitemap.xml/route.ts";
  const content = readRequired(path.join(SRC, "app", "sitemap.xml", "route.ts"), relLabel, errors);
  if (!content) return;

  checkExportRevalidate(content, relLabel, 3600, errors);
  if (extractCallBlocks(content, "unstable_cache").length > 0) {
    checkUnstableCacheRevalidate(content, relLabel, 3600, errors);
  }

  const maxAgeMatches = [...content.matchAll(/\bs-maxage\s*=\s*(\d+)/g)];
  if (maxAgeMatches.length === 0) {
    errors.push(`${relLabel} icinde s-maxage basligi eksik.`);
    return;
  }
  for (const match of maxAgeMatches) {
    const seconds = Number(match[1]);
    if (!Number.isFinite(seconds) || seconds < 3600) {
      errors.push(`${relLabel} s-maxage=${seconds} < 3600.`);
    }
  }
}

function checkPageThresholds(relSegments, minSeconds, checkExport, errors) {
  const relLabel = toPosix(path.join("src", ...relSegments));
  const content = readRequired(path.join(SRC, ...relSegments), relLabel, errors);
  if (!content) return;

  if (checkExport) {
    checkExportRevalidate(content, relLabel, minSeconds, errors);
  }
  checkUnstableCacheRevalidate(content, relLabel, minSeconds, errors);
}

function checkStorageAdapterLock(errors) {
  const allowedRel = "src/lib/gorselDepo.ts";
  const targetDirs = [path.join(SRC, "app", "api"), path.join(SRC, "lib")];
  for (const dir of targetDirs) {
    for (const file of walkCodeFiles(dir)) {
      const relPath = toPosix(path.relative(ROOT, file));
      if (relPath === allowedRel) continue;
      const content = fs.readFileSync(file, "utf8");
      if (DIRECT_STORAGE_UPLOAD_RE.test(content)) {
        errors.push(`Dogrudan storage.from(...).upload() yasak (${allowedRel} kullan): ${relPath}`);
      }
    }
  }
}

function checkCacheSecondsConstant(errors) {
  const relLabel = "src/lib/gorselSikistir.ts";
  const content = readRequired(path.join(SRC, "lib", "gorselSikistir.ts"), relLabel, errors);
  if (!content) return;
  if (!CACHE_SECONDS_RE.test(content)) {
    errors.push(`${relLabel} icinde ONBELLEK_SANIYE = "31536000" eksik.`);
  }
}

function main() {
  const errors = [];

  if (!fs.existsSync(SRC) || !fs.statSync(SRC).isDirectory()) {
    errors.push(`Eksik dizin: ${toPosix(path.relative(ROOT, SRC) || "src")}`);
  }
  if (!fs.existsSync(CONFIG) || !fs.statSync(CONFIG).isFile()) {
    errors.push("Eksik dosya: next.config.ts");
  }

  if (errors.length === 0) {
    checkSelectStar(errors);
    checkSitemapThresholds(errors);
    checkPageThresholds(["app", "v", "[slug]", "page.tsx"], 300, false, errors);
    checkPageThresholds(["app", "v", "[slug]", "urun", "[productSlug]", "page.tsx"], 900, true, errors);
    checkPageThresholds(["app", "v", "[slug]", "yazilar", "page.tsx"], 900, true, errors);
    checkPageThresholds(["app", "v", "[slug]", "yazilar", "[articleSlug]", "page.tsx"], 900, true, errors);
    checkStorageAdapterLock(errors);
    checkCacheSecondsConstant(errors);
  }

  if (errors.length > 0) {
    for (const err of errors) {
      console.error(`HATA: ${err}`);
    }
    process.exit(1);
  }

  console.log("OK: Maliyet ve egress bekcisi tum denetimlerden gecti.");
}

main();
