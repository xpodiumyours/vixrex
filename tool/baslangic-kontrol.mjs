import fs from "node:fs";
import { execFileSync } from "node:child_process";

const root = process.cwd();
const errors = [];
const warnings = [];

function read(rel) {
  try {
    return fs.readFileSync(rel, "utf8");
  } catch {
    return "";
  }
}

function must(ok, message) {
  if (!ok) errors.push(message);
}

const requiredFiles = [
  "tool/ajan-baslangic.ps1",
  "tool/baglanti-olcum.mjs",
  "tool/baslangic-kontrol.mjs",
  "docs/AJAN-BASLANGIC.md",
  "AGENTS.md",
  "README.md",
  "CLAUDE.md",
  ".cursorrules",
  ".mcp.json",
];
for (const file of requiredFiles) must(fs.existsSync(file), "eksik dosya: " + file);

const agents = read("AGENTS.md");
must(/tool\/ajan-baslangic\.ps1/.test(agents), "AGENTS.md açılış kapısı satırını içermiyor");
must(/Graphify etki/i.test(agents), "AGENTS.md 'Graphify etki' kanıt kuralını içermiyor");

const readme = read("README.md");
must(/docs\/AJAN-BASLANGIC\.md/.test(readme), "README.md başlangıç haritasına bağlantı vermiyor");
must(/tarihsel/i.test(readme), "README.md tarihsel plan etiketini içermiyor");

const doc = read("docs/AJAN-BASLANGIC.md");
const docDate = doc.match(/Son doğrulama:\s*(\d{4}-\d{2}-\d{2})/);
if (!docDate) {
  errors.push("docs/AJAN-BASLANGIC.md 'Son doğrulama: YYYY-MM-DD' satırını içermiyor");
} else {
  const ageDays = Math.floor((Date.now() - new Date(docDate[1] + "T00:00:00Z").getTime()) / 86400000);
  if (ageDays > 60) errors.push("docs/AJAN-BASLANGIC.md " + ageDays + " gündür doğrulanmamış (60 gün sınırı)");
  else if (ageDays > 30) warnings.push("docs/AJAN-BASLANGIC.md " + ageDays + " gündür doğrulanmamış (30 gün uyarısı)");
}

try {
  const mcp = JSON.parse(read(".mcp.json"));
  const servers = mcp.mcpServers || {};
  must(Boolean(servers.graphify), ".mcp.json graphify sunucusunu içermiyor");
  must(Boolean(servers.vercel), ".mcp.json vercel sunucusunu içermiyor");
} catch {
  errors.push(".mcp.json geçerli JSON değil");
}

const presets = ["openrouter/preset-okuma.json", "openrouter/preset-kart.json", "openrouter/preset-gorsel-secim.json"];
for (const file of presets) must(fs.existsSync(file), "eksik preset dosyası: " + file);

const gitignore = read(".gitignore");
must(/graphify-out\//.test(gitignore), ".gitignore graphify-out/ dizinini dışlamıyor");

const isPrMode = process.argv.includes("--pr");
if (isPrMode) {
  const body = process.env.PR_BODY || "";
  const base = process.env.BASE_SHA || "";
  const head = process.env.HEAD_SHA || "HEAD";
  if (!base) {
    warnings.push("PR modu: BASE_SHA yok, değişiklik listesi okunamadı");
  } else {
    let changed = [];
    try {
      changed = execFileSync("git", ["diff", "--name-only", base + "..." + head], { encoding: "utf8" })
        .split(/\r?\n/)
        .filter(Boolean);
    } catch (e) {
      errors.push("değişiklik listesi okunamadı: " + String(e.message || e).slice(0, 120));
    }
    const codePrefixes = ["lib/", "public_web/", "supabase/", "shared/", "android/", "ios/", "web/", "test/", "integration_test/", "tool/"];
    const codeChanged = changed.filter((f) => codePrefixes.some((p) => f.startsWith(p)));
    if (codeChanged.length > 0 && !/graphify\s*etki/i.test(body)) {
      errors.push(
        "Kod değişikliği var ama PR gövdesinde 'Graphify etki:' satırı yok. " +
          "Etkiyi `graphify affected \"<Sembol>\"` (veya MCP graphify_impact) ile çıkar ve PR gövdesine yaz. " +
          "Değişen kod dosyası sayısı: " +
          codeChanged.length,
      );
    }
  }
}

for (const w of warnings) console.log("UYARI: " + w);
for (const e of errors) console.log("HATA: " + e);
if (errors.length > 0) {
  console.log("SONUÇ: " + errors.length + " hata — başlangıç haritası eksik.");
  process.exit(1);
}
console.log("SONUÇ: başlangıç haritası bütünlüğü tamam (" + warnings.length + " uyarı).");
