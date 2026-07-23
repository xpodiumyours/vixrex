const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// .env.local'dan URL oku
const envLocal = fs.readFileSync('C:\\Projects\\vixrex\\public_web\\.env.local', 'utf8');
const urlMatch = envLocal.match(/SUPABASE_URL=(.+)/);
const url = urlMatch ? urlMatch[1].trim().replace(/^['"]|['"]$/g, '') : null;

// .env.production.local'dan service role key oku
const envProd = fs.readFileSync('C:\\Projects\\vixrex\\public_web\\.env.production.local', 'utf8');
const keyMatch = envProd.match(/SUPABASE_SERVICE_ROLE_KEY=(.+)/);
const key = keyMatch ? keyMatch[1].trim().replace(/^['"]|['"]$/g, '') : null;

if (!url || !key) {
  console.log('ERROR: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(url, key);

const sql = `CREATE INDEX IF NOT EXISTS idx_stores_published_slug ON public.stores (is_published, slug) WHERE is_published = true;`;

async function run() {
  // exec_sql RPC'si varsa kullan
  const { data, error } = await supabase.rpc('exec_sql', { query: sql });
  if (error) {
    console.log('RPC_ERROR: ' + error.message);
    // exec_sql yoksa PostgREST üzerinden dene
    console.log('Trying direct query...');
    const { data: d2, error: e2 } = await supabase.from('stores').select('id').limit(1);
    if (e2) {
      console.log('CONNECTION_ERROR: ' + e2.message);
    } else {
      console.log('CONNECTION_OK: Can connect to Supabase');
      console.log('SQL needs to run in Supabase SQL Editor manually');
    }
  } else {
    console.log('SUCCESS: Index created');
    console.log(JSON.stringify(data));
  }
}

run().catch(e => console.log('FATAL: ' + e.message));
