import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const envPath = "public_web/.env.local";

function readEnv(p) {
  try {
    const text = fs.readFileSync(p, "utf8");
    const out = {};
    for (const line of text.split(/\r?\n/)) {
      const t = line.trim();
      if (!t || t.startsWith("#") || !t.includes("=")) continue;
      const i = t.indexOf("=");
      const k = t.slice(0, i).trim();
      const v = t.slice(i + 1).trim().replace(/^["']|["']$/g, "");
      if (!(k in out)) out[k] = v;
    }
    return out;
  } catch {
    return {};
  }
}

const env = readEnv(envPath);
const timeoutMs = 15000;
const mcpHeaders = { "content-type": "application/json", accept: "application/json, text/event-stream" };
const initBody = JSON.stringify({
  jsonrpc: "2.0",
  id: 1,
  method: "initialize",
  params: {
    protocolVersion: "2025-03-26",
    capabilities: {},
    clientInfo: { name: "vixrex-baglanti-olcum", version: "1" },
  },
});

async function probe(ad, url, options) {
  const started = Date.now();
  try {
    const r = await fetch(url, { ...options, signal: AbortSignal.timeout(timeoutMs) });
    let durum = "HATA";
    if (r.status >= 200 && r.status < 300) durum = "BAGLI";
    else if (r.status === 401 || r.status === 403) durum = "YETKISIZ";
    return { ad, durum, http: r.status, sure_ms: Date.now() - started };
  } catch (e) {
    return { ad, durum: "ERISILEMEDI", http: 0, sure_ms: Date.now() - started, not: String(e.message || e).slice(0, 120) };
  }
}

function readTokenStore(serverUrl) {
  const dir = path.join(os.homedir(), ".mcp-auth", "mcp-remote-v1");
  try {
    const files = fs.readdirSync(dir).filter((f) => f.endsWith("_tokens.json"));
    for (const f of files) {
      try {
        const t = JSON.parse(fs.readFileSync(path.join(dir, f), "utf8"));
        if (t.access_token) return t.access_token;
      } catch {}
    }
  } catch {}
  return "";
}

function parseMcpBody(text) {
  const trimmed = text.trim();
  if (trimmed.startsWith("{")) {
    try {
      return JSON.parse(trimmed);
    } catch {}
  }
  const lines = trimmed
    .split(/\r?\n/)
    .filter((l) => l.startsWith("data: "))
    .map((l) => l.slice(6));
  for (const line of reversed(lines)) {
    try {
      const j = JSON.parse(line);
      if (j && (j.result || j.error)) return j;
    } catch {}
  }
  return null;
}

function reversed(a) {
  const b = a.slice();
  b.reverse();
  return b;
}

async function mcpSession(url, token) {
  let sessionId = "";
  async function rpc(method, params) {
    const headers = { ...mcpHeaders, authorization: "Bearer " + token };
    if (sessionId) headers["mcp-session-id"] = sessionId;
    const r = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify({ jsonrpc: "2.0", id: Math.floor(Math.random() * 1e9), method, params: params || {} }),
      signal: AbortSignal.timeout(timeoutMs),
    });
    const sid = r.headers.get("mcp-session-id");
    if (sid) sessionId = sid;
    const text = await r.text();
    return { status: r.status, msg: parseMcpBody(text), text };
  }
  return { rpc };
}

async function graphifyProbe() {
  const started = Date.now();
  const token = readTokenStore();
  if (!token) {
    return await probe("graphify_mcp", "https://api.graphify.com/mcp", { method: "POST", headers: mcpHeaders, body: initBody });
  }
  try {
    const s = await mcpSession("https://api.graphify.com/mcp", token);
    const init = await s.rpc("initialize", {
      protocolVersion: "2025-03-26",
      capabilities: {},
      clientInfo: { name: "vixrex-baglanti-olcum", version: "1" },
    });
    if (init.status === 401) return { ad: "graphify_mcp", durum: "YETKISIZ", http: 401, sure_ms: Date.now() - started };
    if (init.status !== 200) return { ad: "graphify_mcp", durum: "HATA", http: init.status, sure_ms: Date.now() - started };
    const list = await s.rpc("tools/list", {});
    const tools = list.msg?.result?.tools || [];
    const repos = await s.rpc("tools/call", { name: "list_repositories", arguments: {} });
    const errCode = repos.msg?.error?.code || "";
    const text = (repos.msg?.result?.content || []).filter((c) => c.type === "text").map((c) => c.text).join(" ");
    const durum = errCode === "no_authorized_repositories" ? "KISITLI" : repos.status === 200 && text ? "BAGLI" : "HATA";
    return { ad: "graphify_mcp", durum, http: repos.status, arac: tools.length, depo_metni: String(text || errCode).slice(0, 160), sure_ms: Date.now() - started };
  } catch (e) {
    return { ad: "graphify_mcp", durum: "ERISILEMEDI", http: 0, sure_ms: Date.now() - started, not: String(e.message || e).slice(0, 120) };
  }
}

const probes = [];
probes.push(await graphifyProbe());
probes.push(await probe("supabase_mcp", "https://mcp.supabase.com/mcp?project_ref=chfulefxczbgurtgavtp", { method: "POST", headers: mcpHeaders, body: initBody }));
probes.push(await probe("vercel_mcp", "https://mcp.vercel.com", { method: "POST", headers: mcpHeaders, body: initBody }));

const orKey = env.OPENROUTER_API_KEY || "";
if (orKey) {
  probes.push(await probe("openrouter_models", "https://openrouter.ai/api/v1/models", { headers: { authorization: "Bearer " + orKey } }));
  probes.push(await probe("openrouter_presets", "https://openrouter.ai/api/v1/presets", { headers: { authorization: "Bearer " + orKey } }));
} else {
  probes.push({ ad: "openrouter_models", durum: "ANAHTAR_YOK", http: 0 });
  probes.push({ ad: "openrouter_presets", durum: "ANAHTAR_YOK", http: 0 });
}

const sbUrl = env.SUPABASE_URL || env.NEXT_PUBLIC_SUPABASE_URL || "";
const sbKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_PUBLISHABLE_KEY || "";
if (sbUrl && sbKey) {
  probes.push(
    await probe("supabase_rest", sbUrl.replace(/\/$/, "") + "/rest/v1/stores?select=id&limit=1", {
      headers: { apikey: sbKey, authorization: "Bearer " + sbKey, accept: "application/json" },
    }),
  );
} else {
  probes.push({ ad: "supabase_rest", durum: "ANAHTAR_YOK", http: 0 });
}

console.log(JSON.stringify({ zaman: new Date().toISOString(), probes }, null, 2));
