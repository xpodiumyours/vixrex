const CONTROL_REPO="xpodiumyours/vixrex";
const CONTROL_API="https://api.github.com/repos/"+CONTROL_REPO+"/issues?state=all&per_page=100";
let controlIssues=[];

async function loadControlIssues(){
  try{
    const r=await fetch(CONTROL_API,{headers:{Accept:"application/vnd.github+json"},cache:"no-store"});
    if(!r.ok) throw new Error("GitHub Issues HTTP "+r.status);
    const all=await r.json();
    controlIssues=all.filter(x=>!x.pull_request && /^\[CONTROL:[^\]]+\]/.test(x.title||""));
    renderControlIssues();
  }catch(e){
    renderControlIssues(e);
  }
}
function issueNodeKey(title){
  const m=String(title||"").match(/^\[CONTROL:([^\]]+)\]/);return m?m[1]:"unknown";
}
function renderControlIssues(error){
  const graph=document.getElementById("graph");if(!graph)return;
  const old=document.getElementById("control-management-group");if(old)old.remove();
  const sec=document.createElement("section");sec.id="control-management-group";sec.className="group";
  const active=controlIssues.filter(x=>x.state==="open");
  sec.innerHTML='<div class="group-title"><h2>Ortak Yönetim / Ajanlar</h2><span>'+(error?"bağlantı hatası":active.length+" aktif görev")+'</span></div><div class="node-grid" id="controlIssueGrid"></div>';
  const grid=sec.querySelector("#controlIssueGrid");
  if(error){
    const d=document.createElement("div");d.className="node";d.innerHTML='<h3>GitHub görevleri okunamadı</h3><div class="sub">'+String(error.message||error)+'</div>';grid.appendChild(d);
  }else if(!active.length){
    const d=document.createElement("div");d.className="node";d.innerHTML='<div class="node-head"><div><h3>Aktif görev yok</h3><div class="kind">GitHub Issues</div></div></div><div class="sub">Yeni görev bir Vixrex node\'undan “Ajana ver” ile açılır.</div>';grid.appendChild(d);
  }else{
    active.forEach(i=>{
      const d=document.createElement("a");d.className="node";d.href=i.html_url;d.target="_blank";d.rel="noreferrer";
      const assignees=(i.assignees||[]).map(a=>a.login).join(", ")||"atanmamış";
      d.innerHTML='<div class="node-head"><div><h3>'+esc(i.title.replace(/^\[CONTROL:[^\]]+\]\s*/,""))+'</h3><div class="kind">'+esc(issueNodeKey(i.title))+'</div></div><span>●</span></div><div class="sub">Ajan: '+esc(assignees)+'<br>Durum: '+esc(i.state)+' · #'+i.number+'</div>';
      grid.appendChild(d);
    });
  }
  graph.appendChild(sec);
}
window.addEventListener("load",loadControlIssues);
setInterval(loadControlIssues,300000);

const _render=window.render;
if(typeof _render==="function"){
  window.render=function(){_render();setTimeout(()=>renderControlIssues(),0)}
}
