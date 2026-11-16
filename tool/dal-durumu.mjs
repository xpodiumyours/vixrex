import { execFileSync } from "node:child_process";

function git(args) {
  try {
    return execFileSync("git", args, { encoding: "utf8" }).trim();
  } catch {
    return "";
  }
}

const mainSha = git(["rev-parse", "--short", "origin/main"]) || git(["rev-parse", "--short", "main"]);
const mainDate = git(["log", "-1", "--format=%cs", "origin/main"]) || git(["log", "-1", "--format=%cs", "main"]);
const nowSec = Math.floor(Date.now() / 1000);

console.log(`Ana dal (main): ${mainSha} (${mainDate})\n`);

const rawHeads = git([
  "for-each-ref",
  "refs/heads",
  "--sort=refname",
  "--format=%(refname:short)\t%(objectname:short)\t%(committerdate:unix)\t%(committerdate:short)",
]);

const lines = rawHeads.split(/\r?\n/).filter(Boolean);
console.log(
  "DAL".padEnd(45) +
  "SON_COMMIT".padEnd(12) +
  "GÜN".padStart(5) +
  "GERİDE".padStart(8) +
  "NOVEL".padStart(8) +
  "  DURUM"
);
console.log("-".repeat(90));

let sessiz = 0;
let eski = 0;
let silinebilir = 0;

for (const line of lines) {
  const [ref, sha, tsStr, dateStr] = line.split("\t");
  if (!ref || ref === "main") continue;

  const ts = parseInt(tsStr, 10) || 0;
  const days = Math.floor((nowSec - ts) / 86400);

  const countStr = git(["rev-list", "--left-right", "--count", `origin/main...${ref}`]);
  const [gerideStr, ileriStr] = countStr.split(/\s+/);
  const geride = parseInt(gerideStr, 10) || 0;
  const ileri = parseInt(ileriStr, 10) || 0;

  const cherryOut = git(["cherry", "origin/main", ref]);
  const novel = (cherryOut.match(/^\+/gm) || []).length;

  const durumlar = [];
  if (novel === 0 && ileri > 0) {
    durumlar.push("SILINEBILIR(patch main'de)");
    silinebilir++;
  } else if (novel === 0 && ileri === 0) {
    durumlar.push("SILINEBILIR");
    silinebilir++;
  }

  if (days >= 15) {
    durumlar.push("ESKI(15+ gün)");
    eski++;
  } else if (days >= 3) {
    durumlar.push("SESSIZ(3+ gün)");
    sessiz++;
  }

  if (geride >= 100) {
    durumlar.push("GERIDE(100+ commit)");
  }

  const durumText = durumlar.length ? durumlar.join(" ") : "aktif";

  console.log(
    ref.padEnd(45) +
    dateStr.padEnd(12) +
    String(days).padStart(5) +
    String(geride).padStart(8) +
    String(novel).padStart(8) +
    "  " + durumText
  );
}

console.log("\n--- Worktree Durumu ---");
const rawWt = git(["worktree", "list", "--porcelain"]);
const wtBlocks = rawWt.split(/\r?\n\r?\n/).filter(Boolean);
console.log(`Toplam worktree: ${wtBlocks.length}`);
for (const b of wtBlocks) {
  const pathLine = (b.match(/^worktree\s+(.+)$/m) || [])[1] || "";
  const branchLine = (b.match(/^branch\s+(.+)$/m) || [])[1] || "(detached)";
  console.log(`- ${pathLine} [${branchLine.replace("refs/heads/", "")}]`);
}

console.log(`\nÖzet: ${lines.length - 1} dal incelendi (${silinebilir} silinebilir, ${sessiz} sessiz, ${eski} eski).`);
