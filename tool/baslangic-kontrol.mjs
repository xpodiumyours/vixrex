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

const sicilBolumu = (() => {
  const m = doc.match(/## 3\..*?(?=\n## )/s);
  return m ? m[0] : doc;
})();

const exemptDoc = (rel) =>
  rel === "docs/AJAN-BASLANGIC.md" ||
  rel.startsWith(".github/") ||
  rel.includes("/skills/") ||
  rel.startsWith("supabase/functions/");

let trackedDocs = [];
try {
  trackedDocs = execFileSync("git", ["ls-files", "*.md"], { encoding: "utf8" }).split(/\r?\n/).filter(Boolean);
} catch (e) {
  errors.push("izlenen .md listesi okunamadı: " + String(e.message || e).slice(0, 120));
}
for (const file of trackedDocs) {
  if (exemptDoc(file)) continue;
  const kisa = file.replace(/^docs\//, "");
  if (!sicilBolumu.includes(file) && !sicilBolumu.includes(kisa)) {
    errors.push("belge sicile girmedi: " + file + " — docs/AJAN-BASLANGIC.md §3 tablosuna ekle ya da muaf listesine yaz");
  }
}

const sicilSatirlari = sicilBolumu.split(/\r?\n/).filter((l) => /^\|/.test(l) && l.includes(".md"));
for (const row of sicilSatirlari) {
  const cells = row.split("|").map((c) => c.trim()).filter((c) => c.length > 0);
  const belgeCell = cells[0] || "";
  const sinif = cells[1] || "";
  const t = belgeCell.match(/([A-Za-z0-9_./-]+\.md)/);
  if (!t) continue;
  const token = t[1].replace(/^\.\.\//, "");
  const adaylar = [token, "docs/" + token.replace(/^docs\//, "")];
  const resolved = adaylar.find((p) => fs.existsSync(p));
  if (!resolved) {
    if (/yerel kayıt/i.test(sinif)) continue;
    errors.push("sicil satırındaki belge diskte yok (hayalet): " + token + " — sınıf: " + sinif);
    continue;
  }
  if (/^(aktüel|güncel)/i.test(sinif)) {
    try {
      const d = execFileSync("git", ["log", "-1", "--format=%ad", "--date=short", "--", resolved], { encoding: "utf8" }).trim();
      if (!d) {
        errors.push("güncel belge git geçmişinde yok: " + resolved);
      } else {
        const yas = Math.floor((Date.now() - new Date(d + "T00:00:00Z").getTime()) / 86400000);
        if (yas > 30) {
          errors.push(
            "güncel belge bayatladı: " + resolved + " (" + yas + " gün önce yazılmış — 30 gün yasağı; tazele ya da sınıfını tarihsel/arşiv yap)",
          );
        }
      }
    } catch (e) {
      errors.push("belge yaşı okunamadı: " + resolved + " — " + String(e.message || e).slice(0, 80));
    }
  }
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
    if (codeChanged.length > 0) {
      const etkiSatirlari = body.split(/\r?\n/).filter((satir) => /graphify\s*etki/i.test(satir));
      if (etkiSatirlari.length === 0) {
        errors.push(
          "Kod değişikliği var ama PR gövdesinde 'Graphify etki:' satırı yok. " +
            "Etkiyi `graphify affected <Sembol>` (veya MCP graphify_impact) ile çıkar ve PR gövdesine yaz. " +
            "Değişen kod dosyası sayısı: " +
            codeChanged.length,
        );
      } else {
        const ayrac = String.fromCharCode(92);
        const metin = etkiSatirlari.join(" ").split(ayrac).join("/");
        const refs = [...metin.matchAll(/([A-Za-z0-9_./@-]+\.[A-Za-z0-9]+):[Ll]?(\d+)/g)];
        const gercek = refs.filter((eslesme) => {
          try {
            return fs.statSync(eslesme[1]).isFile();
          } catch {
            return false;
          }
        });
        if (gercek.length === 0) {
          errors.push(
            "'Graphify etki:' satırı gerçek bir dosya:satır kanıtı içermiyor" +
              (refs.length > 0
                ? " (yazılan: " + refs.map((e) => e[1] + ":" + e[2]).join(", ") + ")"
                : " (hiç dosya:satır yok)") +
              '. graphify affected <Sembol> çıktısından dosya:satır yaz; "bulunamadı" tek başına kanıt sayılmaz.',
          );
        }
      }
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
