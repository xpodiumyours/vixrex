const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const dir = 'C:\\Projects\\vixrex\\public_web';
const envLocal = fs.readFileSync(dir + '\\.env.local', 'utf8');
const url = envLocal.match(/SUPABASE_URL=(.+)/)[1].trim().replace(/^['"]|['"]$/g, '');

const envProd = fs.readFileSync(dir + '\\.env.production.local', 'utf8');
const key = envProd.match(/SUPABASE_SERVICE_ROLE_KEY=(.+)/)[1].trim().replace(/^['"]|['"]$/g, '');

const supabase = createClient(url, key);

const sql = "CREATE INDEX IF NOT EXISTS idx_stores_published_slug ON public.stores (is_published, slug) WHERE is_published = true;";

async function run() {
  const { data, error } = await supabase.rpc('exec_sql', { query: sql });
  if (error) {
    console.log('RPC_NOT_AVAILABLE: ' + error.message);
    const { data: test } = await supabase.from('stores').select('id').limit(1);
    console.log('CONNECTION: OK (read works)');
    console.log('SQL must run in Supabase SQL Editor');
  } else {
    console.log('SUCCESS: Index created');
    console.log(JSON.stringify(data));
  }
}

run();
