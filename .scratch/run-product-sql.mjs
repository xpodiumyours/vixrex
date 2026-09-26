import { readFileSync } from 'node:fs';
import { PGlite } from './sql-runtime/node_modules/@electric-sql/pglite/dist/index.js';
const db = new PGlite();
const read = (name) => readFileSync(`supabase/migrations/${name}`, 'utf8');
try {
  await db.exec("create role anon; create role authenticated; create role service_role; create schema auth; create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;");
  const base = read('00000000000000_temel_sema_bulut_20260805.sql');
  for (const table of ['stores', 'product_categories', 'products']) {
    const statement = base.match(new RegExp(`CREATE TABLE IF NOT EXISTS "public"\\."${table}" \\([\\s\\S]*?\\n\\);`));
    if (!statement) throw new Error(`Missing table ${table}`);
    await db.exec(statement[0]);
  }
  for (const statement of base.matchAll(/ALTER TABLE ONLY "public"\."(?:stores|products|product_categories)"[\s\S]*?;/g)) {
    if (!statement[0].includes('FOREIGN KEY')) await db.exec(statement[0]);
  }
  for (const statement of base.matchAll(/CREATE (?:UNIQUE )?INDEX[^;]+ ON "public"\."(?:products|product_categories)"[^;]*;/g)) await db.exec(statement[0]);
  const auth = base.match(/CREATE OR REPLACE FUNCTION "public"\."_check_store_authorization"[\s\S]*?\$\$;/);
  await db.exec(auth[0]);
  await db.exec(read('20260811053804_product_core_slug_authority.sql'));
  await db.exec(read('20260915010000_product_rich_core_minimal.sql'));
  await db.exec(read('20260915020000_product_batch_rich_fields.sql'));
  await db.exec("insert into stores(id,slug,name,edit_token,is_published) values ('00000000-0000-0000-0000-000000000001','sql-test','SQL test','test-token-long-enough-123456',true); insert into products(store_id,name,slug,image_urls) values ('00000000-0000-0000-0000-000000000001','Legacy','legacy','[\"https://cdn.example/old.jpg\"]');");
  await db.exec(read('20260915030000_product_image_publication.sql'));
  await db.exec(base.match(/CREATE POLICY "anon_read_products"[\s\S]*?;/)[0]);
  await db.exec('alter table public.products enable row level security; grant usage on schema public to anon; grant select on public.products, public.stores to anon;');
  await db.exec(readFileSync('supabase/tests/product_import_publication_smoke.sql','utf8'));
  console.log('PASS: scoped PostgreSQL product import and image publication smoke');
} catch (error) { console.error(error.message); process.exitCode = 1; }
finally { await db.close(); }
