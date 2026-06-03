-- Step 1: list recent store candidates.
-- Review the result carefully before deleting anything.
select slug, name, created_at, is_store, is_published, kategori, address
from public.stores
where is_store = true
order by created_at desc
limit 50;

-- Step 2: after choosing fake slugs, replace the placeholders below.
-- Keep this delete narrow. Do not run it with placeholder values.
/*
delete from public.stores
where slug in (
  'fake-slug-1',
  'fake-slug-2'
);
*/
