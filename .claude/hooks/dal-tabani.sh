#!/bin/bash
# Dal tabani freni — VixRex
#
# Neden: 2026-09-17'de yerel ana dal origin/main'in 5 kayit gerisindeydi ve
# olcum yanlis yapildi ("canlida degil" dendi, halbuki degisiklik canliya
# giden yoldaydi). AGENTS.md madde 8: dal acarken tabani UZAKTAN al.
#
# Kural: yeni dal acilmadan once yerel main origin/main ile ayni olmali.

INPUT=$(cat)

if ! command -v node >/dev/null 2>&1; then
  echo "BLOCKED: node bulunamadi, dal tabani kancasi calismadi. Kontrol calismiyorsa is ilerlemez (anayasa VII)." >&2
  exit 2
fi

HOOK_INPUT="$INPUT" node -e '
let d = {};
try { d = JSON.parse(process.env.HOOK_INPUT || "{}"); } catch (e) {}
const komut = String(((d && d.tool_input) || {}).command || "");
if (!komut) process.exit(0);
const dalAciyor = /git\s+(checkout\s+-b|switch\s+-c|branch\s+(--)?[A-Za-z0-9._\/-]+)/.test(komut);
if (!dalAciyor) process.exit(0);
const { execSync } = require("child_process");
const kos = function (c) { try { return execSync(c, { stdio: ["ignore", "pipe", "ignore"] }).toString().trim(); } catch (e) { return ""; } };
if (!kos("git rev-parse --verify --quiet origin/main")) {
  console.error("BLOCKED: origin/main bulunamadi. Once `git fetch origin` calistir, sonra dali origin/main uzerinden ac (AGENTS.md 8).");
  process.exit(2);
}
if (!kos("git rev-parse --verify --quiet main")) {
  console.error("BLOCKED: yerel main yok. Once origin/main i cek: git fetch origin && git branch main origin/main");
  process.exit(2);
}
const sayim = kos("git rev-list --left-right --count origin/main...main");
const geride = parseInt(String(sayim).split(/\s+/)[0] || "0", 10);
if (geride > 0) {
  console.error(
    "BLOCKED: yerel main origin/main in " + geride + " kayit GERISINDE. " +
    "Bayat tabandan dal acmak yanlis olcume yol acar (2026-09-17 de oldu). " +
    "Once: git fetch origin && git checkout main && git merge --ff-only origin/main. " +
    "Sonra dali origin/main uzerinden ac."
  );
  process.exit(2);
}
process.exit(0);
'
