alter table public.stores
  add column if not exists google_store_code text,
  add column if not exists google_place_id text;

alter table public.products
  add column if not exists google_product_category text;
