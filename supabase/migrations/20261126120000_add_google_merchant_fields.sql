-- Aktif Görev #6 (2026-11-26): Google Merchant Center / Perplexity Merchant Program
-- için geriye dönük tam uyumlu (nullable) alanlar. Mevcut şema ve RLS
-- politikalarına dokunulmaz; yalnızca yeni nullable sütunlar eklenir.

alter table public.stores
  add column if not exists google_store_code text,
  add column if not exists google_place_id text;

alter table public.products
  add column if not exists google_product_category text;
