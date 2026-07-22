alter table public.stores
add column if not exists gallery_items jsonb not null default '[]'::jsonb;

comment on column public.stores.gallery_items is
  'VixRex gallery items. Each item keeps imageUrl, title and description.';

-- Not: update_store_with_token RPC fonksiyonu, p_store içindeki
-- gallery_items değerini public.stores.gallery_items alanına yazmalıdır.
