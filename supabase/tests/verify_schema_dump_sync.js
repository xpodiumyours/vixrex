// Şema dump'u ile aktif migration'ın apply_category_template tanımının
// güvenlik kontrolleri açısından senkron olduğunu doğrular (DB gerektirmez).
// Çalıştır: node supabase/tests/verify_schema_dump_sync.js
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..", "..");
const dump = fs.readFileSync(path.join(root, "supabase_schema.sql"), "utf8");
const canonical = fs.readFileSync(
  path.join(root, "supabase", "migrations", "00000000000000_temel_sema_bulut_20260805.sql"),
  "utf8"
);

function extract(body, name) {
  const start = body.indexOf(`CREATE OR REPLACE FUNCTION ${name}(`);
  if (start < 0) throw new Error(`${name} bulunamadı`);
  const end = body.indexOf("$$;", start);
  return body.slice(start, end + 3);
}

const dumpFn = extract(dump, "apply_category_template");
const canonFn = extract(canonical, '"public"."apply_category_template"');

const checks = [
  ["dump: SET search_path sabitlenmiş", /SET search_path = ''/.test(dumpFn)],
  ["dump: sahiplik/edit_token kontrolü (STORE_UPDATE_NOT_ALLOWED)", /STORE_UPDATE_NOT_ALLOWED/.test(dumpFn)],
  ["dump: p_edit_token parametresi", /p_edit_token/.test(dumpFn)],
  ["dump: nesneler public. ile nitelenmiş", /FROM public\.stores/.test(dumpFn)],
  ["dump: now() yerine pg_catalog.now()", /pg_catalog\.now\(\)/.test(dumpFn)],
  ["canonical: SET search_path sabitlenmiş", /SET "search_path" TO ''/.test(canonFn)],
  ["canonical: sahiplik/edit_token kontrolü", /STORE_UPDATE_NOT_ALLOWED/.test(canonFn)],
  ["dump, canonical ile aynı güvenlik marker'larına sahip",
    /SET search_path = ''/.test(dumpFn) === /SET "search_path" TO ''/.test(canonFn) &&
    /STORE_UPDATE_NOT_ALLOWED/.test(dumpFn) === /STORE_UPDATE_NOT_ALLOWED/.test(canonFn)],
];

let ok = true;
for (const [label, pass] of checks) {
  console.log(`${pass ? "PASS" : "FAIL"}  ${label}`);
  if (!pass) ok = false;
}
process.exit(ok ? 0 : 1);
