#!/usr/bin/env node
//
// Şablon görsellerini Unsplash'ten projeye ait Supabase Storage'a taşır.
// (#235 — hazır vitrin görselleri tek harici kaynağa bağımlıydı.)
//
// KULLANIM
//   node tool/sablon_gorsellerini_tasi.mjs --dry-run   # yalnız indir + doğrula, canlıya dokunmaz
//   node tool/sablon_gorsellerini_tasi.mjs --upload    # bucket'a yükler (service anahtarı ister)
//   node tool/sablon_gorsellerini_tasi.mjs --sql       # mapping'den migration SQL'i üretir
//
// Kaynak veri: supabase/migrations/20250703000002_seed_category_image_templates.sql
// Betik idempotenttir: yükleme upsert, SQL UPDATE'leri tekrar çalıştırılabilir.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const SEED = path.join(ROOT, "supabase", "migrations", "20250703000002_seed_category_image_templates.sql");
const WORK_DIR = process.env.SABLON_CALISMA_DIR || path.join(ROOT, ".tmp-sablon-gorselleri");
const MAPPING_FILE = path.join(WORK_DIR, "mapping.json");
const BUCKET = "category-templates";
const PUBLIC_URL_BASE = process.env.SUPABASE_PUBLIC_URL_BASE || null; // örn. https://<ref>.supabase.co

const mode = process.argv.includes("--dry-run")
  ? "dry"
  : process.argv.includes("--upload")
    ? "upload"
    : process.argv.includes("--sql")
      ? "sql"
      : null;

// --rows <dosya>: satırları seed regex'i yerine canlı DB dökümünden al (349 satır gerçekliği)
const rowsArgIdx = process.argv.indexOf("--rows");
const ROWS_FILE = rowsArgIdx > -1 ? process.argv[rowsArgIdx + 1] : null;
// --dead <dosya>: Unsplash'ten silinmiş (indirilemeyen) satırlar — migration'da pasifleştirilir
const deadArgIdx = process.argv.indexOf("--dead");
const DEAD_FILE = deadArgIdx > -1 ? process.argv[deadArgIdx + 1] : null;
// --anon: service anahtarı yoksa, geçici RLS politikası açıkken anon anahtarla yükle
const USE_ANON = process.argv.includes("--anon");

if (!mode) {
  console.error("Mod gerekli: --dry-run | --upload | --sql");
  process.exit(2);
}

function readEnvValue(file, key) {
  if (!fs.existsSync(file)) return null;
  const m = fs.readFileSync(file, "utf8").match(new RegExp(`^${key}=(.+)$`, "m"));
  return m ? m[1].trim().replace(/^['"]|['"]$/g, "") : null;
}

function getClient() {
  const require = createRequire(path.join(ROOT, "public_web", "package.json"));
  const { createClient } = require("@supabase/supabase-js");
  // Sıra 1: süreç ortam değişkenleri (secrets repoya yazılmaz)
  // Sıra 2: yerel env dosyaları (.env.production.local'daki SERVICE anahtarı boş yer tutucudur)
  const url =
    process.env.VIXREX_SUPABASE_URL ||
    readEnvValue(path.join(ROOT, "public_web", ".env.local"), "SUPABASE_URL") ||
    readEnvValue(path.join(ROOT, "public_web", ".env.production.local"), "SUPABASE_URL");
  let key;
  if (USE_ANON) {
    key =
      readEnvValue(path.join(ROOT, "public_web", ".env.local"), "NEXT_PUBLIC_SUPABASE_ANON_KEY") ||
      readEnvValue(path.join(ROOT, "public_web", ".env.local"), "SUPABASE_ANON_KEY");
  } else {
    key =
      process.env.VIXREX_SERVICE_ROLE_KEY ||
      readEnvValue(path.join(ROOT, "public_web", ".env.local"), "SUPABASE_SERVICE_ROLE_KEY") ||
      readEnvValue(path.join(ROOT, "public_web", ".env.production.local"), "SUPABASE_SERVICE_ROLE_KEY");
  }
  if (!url || !key) {
    console.error("HATA: SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY bulunamadı (değerler yazdırılmaz).");
    process.exit(1);
  }
  return createClient(url, key, { auth: { persistSession: false } });
}

function parseSeed() {
  const text = fs.readFileSync(SEED, "utf8");
  const re = /\('([a-z_]+)',\s*'([^']+)',\s*'(cover|logo_placeholder|gallery|product)',\s*'(https:\/\/images\.unsplash\.com\/[^']+)',\s*'([^']*)',\s*(\d+)\)/g;
  const rows = [];
  let m;
  while ((m = re.exec(text)) !== null) {
    rows.push({
      category_key: m[1],
      category_label: m[2],
      image_type: m[3],
      old_url: m[4],
      title: m[5],
      display_order: Number(m[6]),
    });
  }
  if (rows.length === 0) {
    console.error("HATA: Seed dosyasından satır okunamadı — regex mi değişti?");
    process.exit(1);
  }
  return rows;
}

async function downloadAll(rows) {
  fs.mkdirSync(WORK_DIR, { recursive: true });
  const failed = [];
  const ok = [];
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const h = crypto.createHash("md5").update(r.old_url).digest("hex").slice(0, 6);
    const fileName = `${r.category_key}_${r.image_type}_${r.display_order}_${h}.jpg`;
    const dest = path.join(WORK_DIR, fileName);
    r.file = fileName;

    if (fs.existsSync(dest) && fs.statSync(dest).size > 10000) {
      ok.push(r);
      continue;
    }
    let attempt = 0;
    let success = false;
    while (attempt < 3) {
      attempt++;
      try {
        const res = await fetch(r.old_url, { redirect: "follow" });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const buf = Buffer.from(await res.arrayBuffer());
        if (buf.length < 10000) throw new Error(`dosya çok küçük (${buf.length} bayt)`);
        fs.writeFileSync(dest, buf);
        ok.push(r);
        success = true;
        break;
      } catch (e) {
        if (attempt === 3) failed.push({ row: r, reason: e.message });
        else await new Promise((s) => setTimeout(s, 500 * attempt));
      }
    }
    if ((i + 1) % 50 === 0) console.log(`  ${i + 1}/${rows.length} işlendi...`);
    await new Promise((s) => setTimeout(s, 150));
  }
  console.log(`İndirme: ${ok.length}/${rows.length} başarılı`);

  // Ölü/indirilemeyen kaynakları işle: yükleme bunlara dokunmaz,
  // migration üretiminde pasifleştirilmek üzere kayda geçer.
  if (failed.length) {
    const deadOut = path.join(WORK_DIR, "olu-adresler.json");
    const existing = fs.existsSync(deadOut)
      ? JSON.parse(fs.readFileSync(deadOut, "utf8"))
      : [];
    const byKey = new Map(existing.map((d) => [`${d.category_key}|${d.image_type}|${d.image_url}`, d]));
    for (const f of failed) {
      byKey.set(`${f.row.category_key}|${f.row.image_type}|${f.row.image_url}`, {
        category_key: f.row.category_key,
        image_type: f.row.image_type,
        display_order: f.row.display_order,
        image_url: f.row.old_url,
        title: f.row.title,
        reason: f.reason,
      });
      f.row.dead = true;
    }
    fs.writeFileSync(deadOut, JSON.stringify([...byKey.values()], null, 2));
    console.log(
      `İndirilemeyen: ${failed.length} satır -> ${deadOut} olarak işlendi (migration'da pasifleştirilir)`
    );
  }
  rows = ok.length ? ok : rows.filter((r) => !r.dead);
  return rows.filter((r) => !r.dead);
}

function publicUrlFor(client, objectPath) {
  const { data } = client.storage.from(BUCKET).getPublicUrl(objectPath);
  return data.publicUrl;
}

async function uploadAll(client, rows) {
  if (!USE_ANON) {
    // Bucket yoksa oluştur (public; kurallar shelf-images ile aynı)
    const { data: buckets, error: lbErr } = await client.storage.listBuckets();
    if (lbErr) throw new Error(`bucket listesi alınamadı: ${lbErr.message}`);
    if (!buckets.some((b) => b.name === BUCKET)) {
      const { error } = await client.storage.createBucket(BUCKET, {
        public: true,
        fileSizeLimit: "5mb",
        allowedMimeTypes: ["image/jpeg", "image/png", "image/webp"],
      });
      if (error) throw new Error(`bucket oluşturulamadı: ${error.message}`);
      console.log(`Bucket oluşturuldu: ${BUCKET}`);
    }
  } else {
    console.log("Anon modda bucket oluşturulmaz — canlıda zaten var olmalı.");
  }

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const h = crypto.createHash("md5").update(r.old_url).digest("hex").slice(0, 6);
    const objectPath = `${r.category_key}/${r.image_type}-${r.display_order}-${h}.jpg`;
    r.object_path = objectPath;
    r.new_url = publicUrlFor(client, objectPath);
    const body = fs.readFileSync(path.join(WORK_DIR, r.file));
    const { error } = await client.storage.from(BUCKET).upload(objectPath, body, {
      contentType: "image/jpeg",
      upsert: true,
    });
    if (error && !`${error.message}`.includes("exists")) {
      console.error(`YÜKLEME HATASI ${objectPath}: ${error.message}`);
      process.exit(1);
    }
    if ((i + 1) % 50 === 0) console.log(`  ${i + 1}/${rows.length} yüklendi...`);
  }

  // Her yüklenen nesne için public erişim doğrulaması
  let vOk = 0;
  for (const r of rows) {
    const res = await fetch(r.new_url, { method: "HEAD" });
    if (!res.ok) {
      console.error(`DOĞRULAMA HATASI ${r.new_url}: HTTP ${res.status}`);
      process.exit(1);
    }
    vOk++;
    if (vOk % 100 === 0) console.log(`  doğrulama ${vOk}/${rows.length}...`);
  }
  console.log(`Doğrulama: ${vOk}/${rows.length} public URL erişimi OK`);

  fs.writeFileSync(MAPPING_FILE, JSON.stringify(rows, null, 2), "utf8");
  console.log(`Mapping yazıldı: ${MAPPING_FILE}`);
}

function generateSql(rows) {
  if (!fs.existsSync(MAPPING_FILE)) {
    console.error(`HATA: ${MAPPING_FILE} yok — önce --upload çalıştır.`);
    process.exit(1);
  }
  const map = JSON.parse(fs.readFileSync(MAPPING_FILE, "utf8"));
  const updates = map
    .map(
      (r) =>
        `UPDATE public.category_image_templates\nSET image_url = '${r.new_url}', source_url = '${r.old_url.replace(/'/g, "''")}', updated_at = now()\nWHERE category_key = '${r.category_key}' AND image_type = '${r.image_type}' AND image_url = '${r.old_url.replace(/'/g, "''")}';`
    )
    .join("\n\n");

  let deadRows = [];
  if (DEAD_FILE) {
    deadRows = JSON.parse(fs.readFileSync(DEAD_FILE, "utf8").replace(/^\uFEFF/, ""));
  }
  const deactivate = deadRows
    .map(
      (d) =>
        `-- Unsplash'te artık yok (404): ${d.category_key}/${d.image_type}/${d.display_order}\nUPDATE public.category_image_templates\nSET is_active = false, source_url = '${d.image_url.replace(/'/g, "''")}', updated_at = now()\nWHERE category_key = '${d.category_key}' AND image_type = '${d.image_type}' AND image_url = '${d.image_url.replace(/'/g, "''")}';`
    )
    .join("\n\n");

  const sql = `-- Şablon görsellerini harici barındırıcıdan (Unsplash) proje storage'ına taşıma.
-- #235: hazır vitrin görselleri tek harici kaynağa bağımlıydı; kaynak
-- değişirse tüm kategorilerin hazır görselleri aynı anda kırılıyordu.
-- Gerçekleşme: canlıdaki 349 satırın 23'ünün Unsplash adresi zaten ölmüştü
-- (HTTP 404) — o satırlar pasifleştiriliyor; hiçbir vitrin/ürün etkilenmiyordu
-- (2026-08-25'te sorguyla doğrulandı).
--
-- Ön koşul: sağlam görseller 'category-templates' bucket'ına önceden yüklenmiş
--   olmalı (tool/sablon_gorsellerini_tasi.mjs --upload --anon).
-- Idempotent: UPDATE'ler WHERE image_url=eski koşuluyla çalışır; ikinci koşu no-op.
-- Mevcut vitrin/ürün satırlarına dokunulmaz — yalnız şablon havuzu güncellenir.

-- Bucket tanımı: yerel/taze ortamlar için (canlıda zaten mevcut).
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('${BUCKET}', '${BUCKET}', true, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.category_image_templates ADD COLUMN IF NOT EXISTS source_url text;
COMMENT ON COLUMN public.category_image_templates.source_url IS '#235: taşınmadan önceki harici (Unsplash) adres — lisans/kaynak sorguları için';

${updates}
${deactivate}

-- Geçici yükleme politikası her durumda kapalı başlar (gerekirse elle açılır):
DROP POLICY IF EXISTS "tmp_anon_fill_category_templates" ON storage.objects;
`;
  const out = path.join(ROOT, "supabase", "migrations", "20260825000000_sablon_gorselleri_kendi_deponuzda.sql");
  fs.writeFileSync(out, sql, "utf8");
  console.log(`Migration yazıldı: ${out} (${map.length} güncelleme + ${deadRows.length} pasifleştirme)`);
}

function loadRows() {
  if (ROWS_FILE) {
    const raw = JSON.parse(fs.readFileSync(ROWS_FILE, "utf8").replace(/^\uFEFF/, ""));
    const rows = raw.map((r) => ({
      category_key: r.category_key,
      category_label: r.category_label || "",
      image_type: r.image_type,
      title: r.title || "",
      display_order: Number(r.display_order),
      old_url: r.image_url,
    }));
    return rows;
  }
  return parseSeed();
}

const rows = loadRows();
console.log(`Satırlar okundu: ${rows.length} satır, ${new Set(rows.map((r) => r.category_key)).size} kategori (${ROWS_FILE ? "canlı döküm" : "seed"})`);

if (mode === "dry") {
  await downloadAll(rows);
  console.log("Kuru koşu tamam — canlıya hiç dokunulmadı.");
} else if (mode === "upload") {
  const alive = await downloadAll(rows);
  const client = getClient();
  await uploadAll(client, alive);
} else if (mode === "sql") {
  generateSql(rows);
}
