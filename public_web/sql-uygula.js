// Tek SQL dosyasini canli Supabase'e exec_sql RPC ile uygular.
// Kullanim: node sql-uygula.js <sql-dosyasi-yolu>
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const envLocal = fs.readFileSync('C:\\Projects\\vixrex\\public_web\\.env.local', 'utf8');
const urlMatch = envLocal.match(/SUPABASE_URL=(.+)/);
const url = urlMatch ? urlMatch[1].trim().replace(/^['"]|['"]$/g, '') : null;

const envProd = fs.readFileSync('C:\\Projects\\vixrex\\public_web\\.env.production.local', 'utf8');
const keyMatch = envProd.match(/SUPABASE_SERVICE_ROLE_KEY=(.+)/);
const key = keyMatch ? keyMatch[1].trim().replace(/^['"]|['"]$/g, '') : null;

if (!url || !key) { console.log('HATA: anahtar bulamadi'); process.exit(1); }

const dosya = process.argv[2];
if (!dosya || !fs.existsSync(dosya)) { console.log('HATA: SQL dosyasi yok: ' + dosya); process.exit(1); }
const sql = fs.readFileSync(dosya, 'utf8');

const supabase = createClient(url, key);

async function run() {
  const { data, error } = await supabase.rpc('exec_sql', { query: sql });
  if (error) { console.log('RPC_HATA: ' + error.message); process.exit(2); }
  console.log('OK: uygulandi (' + dosya + ')');
  process.exit(0);
}
run();