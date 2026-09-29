const BRANCH = "control-map-system";
const ROOT = "https://raw.githubusercontent.com/xpodiumyours/vixrex/" + BRANCH + "/control-map-system/";
const ISSUE_BASE = "https://github.com/xpodiumyours/vixrex/issues/new";
const STATUS_KEYS = ["code", "preview", "live", "data", "e2e"];
const STATUS_LABELS = { code: "KOD", preview: "ÖNİZLEME", live: "CANLI", data: "VERİ", e2e: "E2E" };
const STATUS_TEXT = { healthy: "ÇALIŞIYOR", partial: "KISMİ", broken: "HATA", unknown: "BİLİN MİYOR", disabled: "KAPALI" };
const STATUS_SHORT = { healthy: "OK", partial: "~", broken: "X", unknown: "-", disabled: "off" };

let MAP = null, STATE = null;
let selected = null, currentFilter = "all", focusSet = null;

const esc = s => String(s ?? "").replace(/[&<>"']/g, m => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m]));
const statusClass = s => ["healthy", "broken", "partial", "unknown", "disabled"].includes(s) ? s : "unknown";
const age = t => {
  if (!t) return "-";
  const d = Math.max(0, Date.now() - new Date(t).getTime());
  const m = Math.floor(d / 60000);
  if (m < 1) return "şimdi";
  if (m < 60) return m + " dk önce";
  const h = Math.floor(m / 60);
  return h < 24 ? h + " sa önce" : Math.floor(h / 24) + " gün önce";
};

async function loadJSON(name) {
  const u = ROOT + name + "?t=" + Date.now();
  const r = await fetch(u, { cache: "no-store" });
  if (!r.ok) throw new Error(name + " HTTP " + r.status);
  return r.json();
}

async function loadAll() {
  const btn = document.getElementById("refreshBtn");
  btn.textContent = "Ölçülüyor…";
  try {
    [MAP, STATE] = await Promise.all([loadJSON("map.json"), loadJSON("state.json")]);
    document.getElementById("sourceWarning").classList.add("hidden");
    // Ekrandaki renkler canlı ölçüm değil, dosyadaki son fotoğrafın sonucu.
    // Kullanıcı bunu baştan bilsin diye tarih üstte yazılır. (2026-09-29)
    const snap = document.getElementById("snapshotNote");
    if (snap) {
      const t = STATE && STATE.observed_at
        ? new Date(STATE.observed_at).toLocaleString("tr-TR", { dateStyle: "long", timeStyle: "short" })
        : "tarihi bilinmiyor";
      snap.textContent = "CANLI DEĞİL · Renkler " + t + " tarihli son görüntüden geliyor; şimdiki durumu göstermez.";
      snap.classList.remove("hidden");
    }
    render();
  } catch (e) {
    const w = document.getElementById("sourceWarning");
    w.textContent = "Kanonik GitHub omurgası okunamadı: " + e.message;
    w.classList.remove("hidden");
  } finally {
    btn.textContent = "Yenile";
  }
}

function stateOf(key) {
  const s = STATE && STATE.nodes ? STATE.nodes[key] : null;
  if (s) return s;
  const o = {};
  STATUS_KEYS.forEach(k => o[k] = "unknown");
  return o;
}
function signalsOf(key) { const s = stateOf(key); return STATUS_KEYS.map(k => statusClass(s[k])); }
function isBroken(key) { return signalsOf(key).some(x => x === "broken" || x === "partial"); }
function isMeasured(key) { return signalsOf(key).some(x => x === "healthy" || x === "partial" || x === "broken"); }
function badCount(key) { return signalsOf(key).filter(x => x === "broken").length; }

function openIssuesFor(key) {
  const list = (window.controlIssues || []).filter(i => i.state === "open" && issueNodeKey(i.title) === key);
  return list;
}
function hasAgent(key) {
  return openIssuesFor(key).length > 0;
}

function shouldShow(key) {
  if (currentFilter === "problem") return isBroken(key);
  if (currentFilter === "measured") return isMeasured(key);
  if (currentFilter === "agent") return hasAgent(key);
  return true;
}

function countBy(fn) { const c = { bad: 0, warn: 0, ok: 0, unknown: 0 }; (MAP.nodes || []).forEach(n => { const s = signalsOf(n.key); if (s.some(x => x === "broken")) c.bad++; else if (s.some(x => x === "partial")) c.warn++; else if (s.some(x => x === "healthy")) c.ok++; else c.unknown++; }); return c; }

function renderMetrics() {
  const c = countBy();
  document.getElementById("nodeMetric").textContent = (MAP.nodes || []).length + " satır";
  document.getElementById("badMetric").textContent = c.bad + " kırmızı";
  document.getElementById("warnMetric").textContent = c.warn + " sarı";
  const open = (window.controlIssues || []).filter(i => i.state === "open");
  document.getElementById("taskMetric").textContent = open.length + " açık";
  document.getElementById("ageMetric").textContent = age(STATE && STATE.observed_at);
  document.getElementById("shaMetric").textContent = (STATE && STATE.source_commit && STATE.source_commit.short) || "-";
}

function issueCellHTML(key) {
  const issues = openIssuesFor(key);
  const parts = [];
  issues.forEach(i => {
    const who = (i.assignees || []).map(a => a.login).join(", ") || "atanmadı";
    parts.push('<a class="task-link" href="' + esc(i.html_url) + '" target="_blank" rel="noreferrer">#' + i.number + " " + esc(who) + "</a>");
  });
  if (!parts.length) return '<span class="no-task">—</span>';
  return parts.join("<br>");
}

function renderTable() {
  const body = document.getElementById("nodeRows");
  body.innerHTML = "";
  const nodes = (MAP.nodes || []).slice();
  nodes.sort((a, b) => badCount(b.key) - badCount(a.key) || (a.sort_order || 0) - (b.sort_order || 0) || String(a.label).localeCompare(String(b.label), "tr"));
  const visible = nodes.filter(n => shouldShow(n.key));
  document.getElementById("tableNote").textContent = visible.length + " / " + nodes.length + " satır · GitHub: " + BRANCH;

  visible.forEach(n => {
    const tr = document.createElement("tr");
    tr.className = "node-row";
    tr.dataset.key = n.key;
    if (focusSet) tr.classList.add(focusSet.has(n.key) ? "focus" : "dim");

    const sigCells = STATUS_KEYS.map(k => {
      const s = statusClass(stateOf(n.key)[k]);
      return '<td class="sig"><span class="pill ' + s + '">' + STATUS_SHORT[s] + "</span></td>";
    }).join("");

    const problemMark = isBroken(n.key) ? '<span class="row-flag" title="Sorun var">●</span>' : "";
    tr.innerHTML =
      '<td class="col-name"><div class="name-cell">' + problemMark + "<div><b>" + esc(n.label) + '</b><small>' + esc(n.key) + "</small></div></div></td>" +
      "<td>" + esc(n.layer || "-") + "</td>" +
      sigCells +
      "<td>" + esc(n.criticality || "-") + "</td>" +
      '<td class="col-task">' + issueCellHTML(n.key) + "</td>";
    tr.onclick = e => { if (e.target.closest("a")) return; openNode(n.key); };
    body.appendChild(tr);
  });

  if (!visible.length) {
    body.innerHTML = '<tr><td class="empty" colspan="9">Bu filtrede düğüm yok.</td></tr>';
  }
}

function render() {
  renderMetrics();
  renderTable();
  if (typeof renderControlIssues === "function") renderControlIssues();
}

function openNode(key) {
  selected = (MAP.nodes || []).find(x => x.key === key);
  if (!selected) return;
  const st = stateOf(key);
  document.getElementById("sheetKind").textContent = (selected.layer || "") + " · " + (selected.kind || "");
  document.getElementById("sheetTitle").textContent = selected.label;
  document.getElementById("sheetStatuses").innerHTML = STATUS_KEYS.map(k =>
    '<div class="status-card ' + statusClass(st[k]) + '">' + STATUS_LABELS[k] + "<b>" + esc(STATUS_TEXT[statusClass(st[k])] || st[k]) + "</b></div>"
  ).join("");

  const deps = (MAP.edges || []).filter(e => e.from === key || e.to === key)
    .map(e => e.from === key ? e.relation + " → " + e.to : e.from + " ← " + e.relation).join("\n") || "-";
  const issues = openIssuesFor(key).map(i => "#" + i.number + " " + i.title.replace(/^\[CONTROL:[^\]]+\]\s*/, "") + " (" + i.state + ")").join("\n") || "Yok";
  const blocks = [
    ["Route", selected.route || "-"],
    ["Kaynak dosyalar", (selected.source_paths || []).join("\n") || "-"],
    ["API", (selected.api_refs || []).join("\n") || "-"],
    ["RPC", (selected.rpc_refs || []).join("\n") || "-"],
    ["Tablolar", (selected.table_refs || []).join("\n") || "-"],
    ["Testler", (selected.test_refs || []).join("\n") || "-"],
    ["Bağımlılıklar", deps],
    ["Açık GitHub görevleri", issues],
    ["Son ölçüm", (STATE && STATE.observed_at) ? STATE.observed_at : "-"]
  ];
  document.getElementById("sheetDetail").innerHTML = blocks.map(([a, b]) =>
    '<div class="detail-block"><small>' + esc(a) + "</small><div>" + esc(b).replace(/\n/g, "<br>") + "</div></div>"
  ).join("");

  const open = document.getElementById("openReal");
  open.href = selected.live_url || (selected.route ? "https://vixrex.com" + selected.route : "https://github.com/xpodiumyours/vixrex");
  document.getElementById("sheet").classList.add("open");
  document.getElementById("sheet").setAttribute("aria-hidden", "false");
  document.getElementById("sheetBackdrop").classList.remove("hidden");
}

function closeSheet() {
  document.getElementById("sheet").classList.remove("open");
  document.getElementById("sheet").setAttribute("aria-hidden", "true");
  document.getElementById("sheetBackdrop").classList.add("hidden");
}

function taskPackage(n) {
  const rel = (MAP.edges || []).filter(e => e.from === n.key || e.to === n.key);
  const direct = [...new Set(rel.map(e => e.from === n.key ? e.to : e.from))];
  const st = stateOf(n.key);
  return [
    "GÖREV", n.label + " (" + n.key + ")", "",
    "KAPSAM", "Seçilen düğüm + doğrudan bağımlılıklar: " + direct.join(", "), "",
    "MEVCUT SİNYAL", STATUS_KEYS.map(k => STATUS_LABELS[k] + ": " + (STATUS_TEXT[statusClass(st[k])] || "bilinmiyor")).join(" | "), "",
    "YASAK", "İlgisiz özellikler; main merge; production deploy/publish; DB schema/RLS; auth/ödeme/güvenlik değişikliği kullanıcı onayı olmadan.", "",
    "ÇIKIŞ ŞARTI", "Ayrı doğrulama kanıtı + gerçek ekran/veri kanıtı. Ajan kendi işini kanıtsız green ilan edemez.", "",
    "KAYNAK", "control-map-system/map.json + state.json + protocol.md"
  ].join("\n");
}

function assign() {
  if (!selected) return;
  const p = taskPackage(selected);
  document.getElementById("taskTitle").textContent = selected.label;
  document.getElementById("taskPackage").value = p;
  const title = "[CONTROL:" + selected.key + "] " + selected.label;
  document.getElementById("openIssue").href = ISSUE_BASE + "?title=" + encodeURIComponent(title) + "&body=" + encodeURIComponent(p);
  document.getElementById("taskDialog").showModal();
}

document.getElementById("refreshBtn").onclick = loadAll;
document.getElementById("closeSheet").onclick = closeSheet;
document.getElementById("sheetBackdrop").onclick = closeSheet;
document.getElementById("focusDeps").onclick = () => {
  if (!selected) return;
  focusSet = new Set([selected.key]);
  (MAP.edges || []).filter(e => e.from === selected.key || e.to === selected.key).forEach(e => { focusSet.add(e.from); focusSet.add(e.to); });
  closeSheet();
  render();
};
document.getElementById("assignAgent").onclick = assign;
document.getElementById("copyTask").onclick = async () => {
  await navigator.clipboard.writeText(document.getElementById("taskPackage").value);
  document.getElementById("copyTask").textContent = "Kopyalandı";
};
document.querySelectorAll(".filter").forEach(b => b.onclick = () => {
  document.querySelectorAll(".filter").forEach(x => x.classList.remove("active"));
  b.classList.add("active");
  currentFilter = b.dataset.filter;
  focusSet = null;
  render();
});

loadAll();
setInterval(loadAll, 60000);
