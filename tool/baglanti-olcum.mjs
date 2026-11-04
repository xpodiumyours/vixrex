import crypto from "node:crypto";
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

function tokenForUrl(serverUrl) {
  const hash = crypto.createHash("md5").update(serverUrl).digest("hex");
  const file = path.join(os.homedir(), ".mcp-auth", "mcp-remote-v1", hash + "_tokens.json");
  try {
    const t = JSON.parse(fs.readFileSync(file, "utf8"));
    if (!t.access_token) return { token: "", expired: false };
    const rawExp = Number(t.expires_at || 0);
    const exp = rawExp > 1e12 ? Math.floor(rawExp / 1000) : rawExp;
    const now = Math.floor(Date.now() / 1000);
    if (exp && exp - now <= 120) return { token: "", expired: true };
    return { token: t.access_token, expired: false };
  } catch {
    return { token: "", expired: false };
  }
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
  const auth = tokenForUrl("https://api.graphify.com/mcp");
  if (auth.expired) {
    return { ad: "graphify_mcp", durum: "OTURUM_ESKI", http: 401, sure_ms: 0 };
  }
  if (!auth.token) {
    return await probe("graphify_mcp", "https://api.graphify.com/mcp", { method: "POST", headers: mcpHeaders, body: initBody });
  }
  const token = auth.token;
  try {
    const s = await mcpSession("https://api.graphify.com/mcp", token);
    const init = await s.rpc("initialize", {
      protocolVersion: "2025-03-26",
      capabilities: {},
      clientInfo: { name: "vixrex-baglanti-olcum", version: "1" },
    });
    if (init.status !== 200) {
      return { ad: "graphify_mcp", durum: init.status === 401 ? "YETKISIZ" : "HATA", http: init.status, sure_ms: Date.now() - started };
    }
    const list = await s.rpc("tools/list", {});
    const tools = list.msg?.result?.tools || [];
    const repos = await s.rpc("tools/call", { name: "list_repositories", arguments: {} });
    const errCode = repos.msg?.error?.code || "";
    const text = (repos.msg?.result?.content || []).filter((c) => c.type === "text").map((c) => c.text).join(" ");
    const durum = errCode === "no_authorized_repositories" ? "KISITLI" : repos.status === 200 && text ? "BAGLI" : "HATA";
    let bulutCommit = "";
    let bulutYas = "";
    let dugum = 0;
    try {
      const st = await s.rpc("tools/call", { name: "graph_stats", arguments: { repository_id: "xpodiumyours/vixrex" } });
      const stText = (st.msg?.result?.content || []).filter((c) => c.type === "text").map((c) => c.text).join(" ");
      const parsed = JSON.parse(stText);
      bulutCommit = String(parsed.commitSha || parsed.result?.freshness?.commit || "");
      bulutYas = String(parsed.result?.freshness?.age || "");
      dugum = Number(parsed.result?.n_nodes || 0);
    } catch {}
    return {
      ad: "graphify_mcp",
      durum,
      http: repos.status,
      arac: tools.length,
      dugum,
      bulut_commit: bulutCommit.slice(0, 7),
      bulut_yas: bulutYas,
      depo_metni: String(text || errCode).slice(0, 160),
      sure_ms: Date.now() - started,
    };
  } catch (e) {
    return { ad: "graphify_mcp", durum: "ERISILEMEDI", http: 0, sure_ms: Date.now() - started, not: String(e.message || e).slice(0, 120) };
  }
}

async function authProbe(ad, url) {
  const started = Date.now();
  const auth = tokenForUrl(url);
  if (auth.expired) return { ad, durum: "OTURUM_ESKI", http: 401, sure_ms: 0 };
  if (auth.token) {
    try {
      const r = await fetch(url, {
        method: "POST",
        headers: { ...mcpHeaders, authorization: "Bearer " + auth.token },
        body: initBody,
        signal: AbortSignal.timeout(timeoutMs),
      });
      if (r.status === 200) return { ad, durum: "BAGLI", http: 200, oturum: true, sure_ms: Date.now() - started };
    } catch {}
  }
  return await probe(ad, url, { method: "POST", headers: mcpHeaders, body: initBody });
}

const probes = [];
probes.push(await graphifyProbe());
probes.push(await authProbe("supabase_mcp", "https://mcp.supabase.com/mcp?project_ref=chfulefxczbgurtgavtp"));
probes.push(await authProbe("vercel_mcp", "https://mcp.vercel.com"));

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
