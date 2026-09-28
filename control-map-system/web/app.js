const BRANCH="control-map-system";
const ROOT="https://raw.githubusercontent.com/xpodiumyours/vixrex/"+BRANCH+"/control-map-system/";
const ISSUE_BASE="https://github.com/xpodiumyours/vixrex/issues/new";
const STATUS_KEYS=["code","preview","live","data","e2e"];
const STATUS_LABELS={code:"KOD",preview:"PREVIEW",live:"CANLI",data:"VERİ",e2e:"E2E"};
let MAP=null,STATE=null,TASKS=null,selected=null,currentFilter="all",focusSet=null;

const esc=s=>String(s??"").replace(/[&<>"']/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;"}[m]));
const statusClass=s=>["healthy","broken","partial","unknown","disabled"].includes(s)?s:"unknown";
const age=t=>{if(!t)return"—";const d=Math.max(0,Date.now()-new Date(t).getTime());const m=Math.floor(d/60000);if(m<1)return"şimdi";if(m<60)return m+" dk";const h=Math.floor(m/60);return h<24?h+" sa":Math.floor(h/24)+" gün"};

async function loadJSON(name){
 const u=ROOT+name+"?t="+Date.now();
 const r=await fetch(u,{cache:"no-store"});
 if(!r.ok) throw new Error(name+" HTTP "+r.status);
 return r.json();
}
async function loadAll(){
 document.getElementById("refreshBtn").textContent="Ölçülüyor…";
 try{
   [MAP,STATE,TASKS]=await Promise.all([loadJSON("map.json"),loadJSON("state.json"),loadJSON("tasks.json")]);
   document.getElementById("sourceWarning").classList.add("hidden");
   render();
 }catch(e){
   const w=document.getElementById("sourceWarning");w.textContent="Kanonik GitHub omurgası okunamadı: "+e.message;w.classList.remove("hidden");
 }finally{document.getElementById("refreshBtn").textContent="Yenile"}
}
function aggregate(k){
 const vals=Object.values(STATE?.nodes||{}).map(x=>x[k]||"unknown");
 const c={healthy:0,broken:0,partial:0,unknown:0,disabled:0};vals.forEach(x=>c[statusClass(x)]++);
 return c;
}
function metricText(k){
 const c=aggregate(k);return c.broken?c.broken+" kırmızı":c.partial?c.partial+" sarı":c.unknown?c.unknown+" bilinmiyor":"sağlıklı";
}
function renderMetrics(){
 ["live","preview","data","e2e"].forEach(k=>document.getElementById(k+"Metric").textContent=metricText(k));
 document.getElementById("shaMetric").textContent=STATE?.source_commit?.short||"—";
 document.getElementById("ageMetric").textContent=age(STATE?.observed_at);
}
function groupFor(n){
 if(n.key==="vixrex")return"Sistem";
 if(["experience","business"].includes(n.layer))return"Önyüz / Akışlar";
 if(["code"].includes(n.layer)||["api","rpc"].includes(n.kind))return"Arka uç";
 if(n.layer==="data")return"Veri";
 if(["infra","test"].includes(n.layer))return"Altyapı / Kanıt";
 return"Diğer";
}
function problem(n){const s=STATE?.nodes?.[n.key]||{};return STATUS_KEYS.some(k=>s[k]==="broken"||s[k]==="partial")}
function hasAgent(n){return (TASKS?.queue||[]).some(t=>t.node_key===n.key&&!["done","cancelled"].includes(t.status))}
function shouldShow(n){if(currentFilter==="problem")return problem(n);if(currentFilter==="agent")return hasAgent(n);return true}
function relations(key){
 const e=MAP.edges||[];return e.filter(x=>x.from===key||x.to===key)
}
function connectedKeys(key){
 const set=new Set([key]);relations(key).forEach(e=>{set.add(e.from);set.add(e.to)});return set
}
function render(){
 renderMetrics();
 const groups={};(MAP.nodes||[]).forEach(n=>{const g=groupFor(n);(groups[g]??=[]).push(n)});
 const graph=document.getElementById("graph");graph.innerHTML="";
 Object.entries(groups).forEach(([name,nodes])=>{
   const visible=nodes.filter(shouldShow);if(!visible.length)return;
   const sec=document.createElement("section");sec.className="group";
   sec.innerHTML='<div class="group-title"><h2>'+esc(name)+'</h2><span>'+visible.length+' node</span></div><div class="node-grid"></div>';
   const grid=sec.querySelector(".node-grid");
   visible.sort((a,b)=>(a.sort_order||0)-(b.sort_order||0)).forEach(n=>grid.appendChild(nodeCard(n)));
   graph.appendChild(sec);
 });
}
function nodeCard(n){
 const st=STATE?.nodes?.[n.key]||{};
 const b=document.createElement("button");b.className="node";b.dataset.key=n.key;
 if(focusSet){if(focusSet.has(n.key))b.classList.add("focus");else b.classList.add("dim")}
 const sig=STATUS_KEYS.map(k=>'<div class="signal '+statusClass(st[k])+'">'+STATUS_LABELS[k]+'</div>').join("");
 b.innerHTML='<div class="node-head"><div><h3>'+esc(n.label)+'</h3><div class="kind">'+esc(n.kind)+'</div></div><span>'+ (problem(n)?"●":"") +'</span></div><div class="sub">'+esc(n.route||n.notes||((n.source_paths||[])[0]||""))+'</div><div class="signal-row">'+sig+'</div>';
 b.onclick=()=>openNode(n.key);return b;
}
function openNode(key){
 selected=MAP.nodes.find(x=>x.key===key);if(!selected)return;
 const st=STATE?.nodes?.[key]||{};
 document.getElementById("sheetKind").textContent=(selected.layer||"")+" · "+(selected.kind||"");
 document.getElementById("sheetTitle").textContent=selected.label;
 document.getElementById("sheetStatuses").innerHTML=STATUS_KEYS.map(k=>'<div class="status-card '+statusClass(st[k])+'">'+STATUS_LABELS[k]+'<b>'+esc(st[k]||"unknown")+'</b></div>').join("");
 const deps=relations(key).map(e=>e.from===key?e.relation+" → "+e.to:e.from+" → "+e.relation).join("\n")||"—";
 const tasks=(TASKS?.queue||[]).filter(t=>t.node_key===key).map(t=>(t.executor||"unassigned")+" · "+t.status).join("\n")||"Yok";
 const blocks=[
  ["Route",selected.route||"—"],["Kaynak dosyalar",(selected.source_paths||[]).join("\n")||"—"],["API",(selected.api_refs||[]).join("\n")||"—"],
  ["RPC",(selected.rpc_refs||[]).join("\n")||"—"],["Tablolar",(selected.table_refs||[]).join("\n")||"—"],["Testler",(selected.test_refs||[]).join("\n")||"—"],
  ["Bağımlılıklar",deps],["Aktif ajan/görev",tasks]
 ];
 document.getElementById("sheetDetail").innerHTML=blocks.map(([a,b])=>'<div class="detail-block"><small>'+esc(a)+'</small><div>'+esc(b).replace(/\n/g,"<br>")+'</div></div>').join("");
 const open=document.getElementById("openReal");const u=selected.live_url||(selected.route?"https://www.vixrex.com"+selected.route:"https://github.com/xpodiumyours/vixrex");
 open.href=u;
 document.getElementById("sheet").classList.add("open");document.getElementById("sheet").setAttribute("aria-hidden","false");document.getElementById("sheetBackdrop").classList.remove("hidden");
}
function closeSheet(){document.getElementById("sheet").classList.remove("open");document.getElementById("sheet").setAttribute("aria-hidden","true");document.getElementById("sheetBackdrop").classList.add("hidden")}
function taskPackage(n){
 const rel=relations(n.key);const direct=[...new Set(rel.map(e=>e.from===n.key?e.to:e.from))];
 const st=STATE?.nodes?.[n.key]||{};
 return [
  "GÖREV",n.label+" ("+n.key+")","",
  "KAPSAM","Seçilen node + doğrudan bağımlılıklar: "+direct.join(", "),"",
  "MEVCUT SİNYAL",STATUS_KEYS.map(k=>STATUS_LABELS[k]+": "+(st[k]||"unknown")).join(" | "),"",
  "YASAK","İlgisiz özellikler; main merge; production deploy/publish; DB schema/RLS; auth/ödeme/güvenlik değişikliği kullanıcı onayı olmadan.","",
  "ÇIKIŞ ŞARTI","Ayrı doğrulama kanıtı + gerçek ekran/veri kanıtı. Ajan kendi işini kanıtsız green ilan edemez.","",
  "KAYNAK", "control-map-system/map.json + state.json + protocol.md"
 ].join("\n");
}
function assign(){
 if(!selected)return;const p=taskPackage(selected);document.getElementById("taskTitle").textContent=selected.label;document.getElementById("taskPackage").value=p;
 const title="[CONTROL:"+selected.key+"] "+selected.label;
 document.getElementById("openIssue").href=ISSUE_BASE+"?title="+encodeURIComponent(title)+"&body="+encodeURIComponent(p);
 document.getElementById("taskDialog").showModal();
}
document.getElementById("refreshBtn").onclick=loadAll;
document.getElementById("closeSheet").onclick=closeSheet;document.getElementById("sheetBackdrop").onclick=closeSheet;
document.getElementById("focusDeps").onclick=()=>{if(!selected)return;focusSet=connectedKeys(selected.key);closeSheet();render()};
document.getElementById("assignAgent").onclick=assign;
document.getElementById("copyTask").onclick=async()=>{await navigator.clipboard.writeText(document.getElementById("taskPackage").value);document.getElementById("copyTask").textContent="Kopyalandı"};
document.querySelectorAll(".filter").forEach(b=>b.onclick=()=>{document.querySelectorAll(".filter").forEach(x=>x.classList.remove("active"));b.classList.add("active");currentFilter=b.dataset.filter;focusSet=null;render()});
loadAll();
setInterval(loadAll,60000);
