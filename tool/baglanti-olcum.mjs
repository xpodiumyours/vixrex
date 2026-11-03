import fs from "node:fs";

const envPath = "public_web/.env.local";

function readEnv(path) {
  try {
    const text = fs.readFileSync(path, "utf8");
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

const probes = [];
probes.push(await probe("graphify_mcp", "https://api.graphify.com/mcp", { method: "POST", headers: mcpHeaders, body: initBody }));
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
