import fs from "node:fs";

const envPath = process.argv[2] ?? "public_web/.env.local";
const strip = (s: string) => s.replace(/^["']/, "").replace(/["']$/, "");
const env = Object.fromEntries(
  fs
    .readFileSync(envPath, "utf8")
    .split(/\r?\n/)
    .filter((l) => l.includes("=") && !l.trim().startsWith("#"))
    .map((l) => {
      const i = l.indexOf("=");
      return [l.slice(0, i).trim(), strip(l.slice(i + 1).trim())];
    }),
);

const sb = env.SUPABASE_URL || env.NEXT_PUBLIC_SUPABASE_URL || "";
const key =
  env.SUPABASE_PUBLISHABLE_KEY || env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "";
const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || "";
const site = "https://www.vixrex.com";

type Row = Record<string, unknown>;

async function rest(
  path: string,
  k: string,
): Promise<{ status: number; rows: Row[]; total: number | null }> {
  const r = await fetch(sb + "/rest/v1/" + path, {
    headers: {
      apikey: k,
      Authorization: "Bearer " + k,
      Accept: "application/json",
      Prefer: "count=exact",
    },
  });
  const cr = r.headers.get("content-range");
  const total = cr ? Number(cr.split("/")[1]) : null;
  const t = await r.text();
  let rows: Row[] = [];
  try {
    const parsed = JSON.parse(t);
    if (Array.isArray(parsed)) rows = parsed;
  } catch {
    rows = [];
  }
  return { status: r.status, rows, total };
}

function photoBucket(n: number): string {
  if (n === 0) return "0 foto";
  if (n === 1) return "1 foto";
  if (n === 2) return "2 foto";
  return "3+ foto";
}

async function main() {
  const valid = (v: string) => v && !v.startsWith("[SENSITIVE");
  if (!sb || !valid(key)) {
    console.error("Env dosyasinda gecerli SUPABASE_URL + publishable anahtar yok: " + envPath);
    process.exit(2);
  }

  console.log("== CANLI DURUM PANOSU ==");
  console.log("Olcum zamani:", new Date().toLocaleString("tr-TR"));
  console.log("Kaynak env:", envPath);
  console.log("");

  console.log("-- Vitrinler --");
  if (valid(serviceKey)) {
    const stores = await rest(
      "stores?select=id,slug,is_demo,is_published&limit=1000",
      serviceKey,
    );
    if (stores.status === 200) {
      const rows = stores.rows;
      const demo = rows.filter((s) => s.is_demo === true);
      const demoDisi = rows.filter((s) => s.is_demo !== true);
      const yayinda = rows.filter((s) => s.is_published === true);
      console.log("Toplam vitrin:", stores.total ?? rows.length);
      console.log("Kiralik vitrin:", demo.length, "(kiralik vitrin — kiralanabilir hazir sablonlar)");
      console.log("Gercek musteri vitrini:", demoDisi.length, "(is_demo=false)");
      console.log("Yayinda:", yayinda.length);
    } else {
      console.log("stores okunamadi (servis anahtari): HTTP " + stores.status);
    }
  } else {
    console.log("Servis anahtari yok — vitrin sayimi atlandi (yalniz urun olculur).");
  }
  console.log("");

  console.log("-- Urunler (anon/RLS) --");
  const products = await rest(
    "products?select=id,store_id,name,image_urls,price_text,price_amount,metadata,is_visible&limit=5000",
    key,
  );
  if (products.status !== 200) {
    console.error("products okunamadi: HTTP " + products.status);
    process.exit(1);
  }

  const rows = products.rows;
  const perStore = new Map<string, number>();
  const buckets = new Map<string, number>();
  let attrFilled = 0;
  let serviceKind = 0;
  let invisible = 0;
  let priceAmount = 0;

  for (const p of rows) {
    const sid = String(p.store_id ?? "");
    perStore.set(sid, (perStore.get(sid) ?? 0) + 1);
    const imgs = Array.isArray(p.image_urls)
      ? (p.image_urls as unknown[]).filter((u) => String(u ?? "").trim())
      : [];
    const b = photoBucket(imgs.length);
    buckets.set(b, (buckets.get(b) ?? 0) + 1);
    const m = (p.metadata ?? {}) as Row;
    const attrs = Array.isArray(m.attributes) ? (m.attributes as unknown[]) : [];
    const service = m.service && typeof m.service === "object" ? (m.service as Row) : null;
    if (service && Object.keys(service).length > 0) serviceKind++;
    if (attrs.length > 0 || (service && Object.keys(service).length > 0)) attrFilled++;
    if (p.is_visible === false) invisible++;
    if (p.price_amount != null) priceAmount++;
  }

  console.log("Toplam urun:", products.total ?? rows.length);
  console.log("Fotograf dagilimi:", [...buckets.entries()].sort().map(([k, v]) => k + ": " + v).join(" | "));
  console.log("Oznitelik/hizmet bilgisi dolu:", attrFilled + "/" + rows.length);
  console.log("Hizmet turu kayit:", serviceKind);
  console.log("Taslak (gorunmez):", invisible);
  console.log("price_amount dolu:", priceAmount + "/" + rows.length);
  console.log("Vitrin basina urun (ilk 10):");
  for (const [sid, c] of [...perStore.entries()].sort((a, b) => b[1] - a[1]).slice(0, 10)) {
    console.log("  " + sid.slice(0, 8) + " -> " + c);
  }

  const cats = await rest("product_categories?select=id&limit=1000", key);
  console.log("Urun kategorisi:", cats.status === 200 ? (cats.total ?? cats.rows.length) : "HTTP " + cats.status);

  console.log("");
  console.log("-- Vitrinler (sitemap.xml) --");
  try {
    const sm = await fetch(site + "/sitemap.xml");
    const xml = await sm.text();
    const urls = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
    const vitrin = urls.filter((u) => /\/v\/[^/]+\/?$/.test(u));
    const urun = urls.filter((u) => /\/v\/[^/]+\/urun\//.test(u));
    console.log("Sitemap URL sayisi:", urls.length);
    console.log("/v/ vitrin:", vitrin.length, "| /v/ urun:", urun.length);
    console.log("Not: #345 karariyla yalniz demo olmayan vitrinler haritada; ilk gercek musteri yayinlandiginda /v/ URL'leri kendiliginden cikar.");
  } catch (e) {
    console.log("Sitemap okunamadi:", (e as Error).message);
  }
}

main().catch((e) => {
  console.error("Hata:", (e as Error).message);
  process.exit(1);
});
