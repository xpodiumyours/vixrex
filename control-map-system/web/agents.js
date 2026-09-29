const CONTROL_REPO = "xpodiumyours/vixrex";
const CONTROL_API = "https://api.github.com/repos/" + CONTROL_REPO + "/issues?state=all&per_page=100";

window.controlIssues = [];

function issueNodeKey(title) {
  const m = String(title || "").match(/^\[CONTROL:([^\]]+)\]/);
  return m ? m[1] : "-";
}
function issueShortTitle(title) {
  return String(title || "").replace(/^\[CONTROL:[^\]]+\]\s*/, "");
}

async function loadControlIssues() {
  const note = document.getElementById("issueNote");
  try {
    const r = await fetch(CONTROL_API, { headers: { Accept: "application/vnd.github+json" }, cache: "no-store" });
    if (!r.ok) throw new Error("GitHub HTTP " + r.status);
    const all = await r.json();
    window.controlIssues = all.filter(x => !x.pull_request && /^\[CONTROL:[^\]]+\]/.test(x.title || ""));
    if (note) note.textContent = "GitHub Issues · " + window.controlIssues.length + " kayıtlı görev";
  } catch (e) {
    window.controlIssues = [];
    if (note) note.textContent = "GitHub görevleri okunamadı: " + String(e.message || e);
  }
  renderIssueTable();
  if (typeof renderTable === "function" && MAP) renderTable();
  renderMetrics();
}

function renderIssueTable() {
  const body = document.getElementById("issueRows");
  if (!body) return;
  const list = window.controlIssues.slice().sort((a, b) => (a.state === b.state ? b.number - a.number : a.state === "open" ? -1 : 1));
  body.innerHTML = "";

  if (!list.length) {
    body.innerHTML = '<tr><td class="empty" colspan="5">Kayıtlı görev yok. Bir düğüme tıklayıp “Ajana ver” ile ilk görevi aç.</td></tr>';
    return;
  }

  list.forEach(i => {
    const who = (i.assignees || []).map(a => a.login).join(", ") || "atanmadı";
    const tr = document.createElement("tr");
    tr.className = "issue-row";
    tr.innerHTML =
      '<td class="col-no"><a href="' + esc(i.html_url) + '" target="_blank" rel="noreferrer">#' + i.number + "</a></td>" +
      "<td>" + esc(issueShortTitle(i.title)) + "</td>" +
      "<td>" + esc(issueNodeKey(i.title)) + "</td>" +
      "<td>" + esc(who) + "</td>" +
      '<td><span class="pill ' + (i.state === "open" ? "broken" : "healthy") + '">' + (i.state === "open" ? "AÇIK" : "KAPALI") + "</span></td>";
    body.appendChild(tr);
  });
}

window.addEventListener("load", loadControlIssues);
setInterval(loadControlIssues, 300000);
