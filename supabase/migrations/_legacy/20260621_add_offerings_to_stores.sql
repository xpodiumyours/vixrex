-- Add offerings jsonb column to stores table
alter table public.stores
add column if not exists offerings jsonb default '[]'::jsonb;

-- Ensure it allows NULL if it was previously created as NOT NULL
alter table public.stores
alter column offerings drop not null;

-- Add offerings constraint
alter table public.stores drop constraint if exists check_offerings_limit;
alter table public.stores add constraint check_offerings_limit check (
  offerings is null or (
    jsonb_typeof(offerings) = 'array' and jsonb_array_length(offerings) <= 6
  )
);

-- Update update_store_with_token RPC function to handle offerings
create or replace function public.update_store_with_token(p_slug text, p_edit_token text, p_store jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_slug is null or pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;

  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  update public.stores
  set
    name = pg_catalog.coalesce(p_store->>'name', name),
    business_type = pg_catalog.coalesce(p_store->>'business_type', business_type),
    description = pg_catalog.coalesce(p_store->>'description', description),
    corporate_bio = pg_catalog.coalesce(p_store->>'corporate_bio', corporate_bio),
    whatsapp = pg_catalog.coalesce(p_store->>'whatsapp', whatsapp),
    instagram = pg_catalog.coalesce(p_store->>'instagram', instagram),
    website = pg_catalog.coalesce(p_store->>'website', website),
    address = pg_catalog.coalesce(p_store->>'address', address),
    theme = pg_catalog.coalesce(p_store->>'theme', theme),
    status = pg_catalog.coalesce(p_store->>'status', status),
    marketplace_links = pg_catalog.coalesce(p_store->'marketplace_links', marketplace_links),
    gallery_items = pg_catalog.coalesce(p_store->'gallery_items', gallery_items),
    products = pg_catalog.coalesce(p_store->'products', products),
    offerings = pg_catalog.coalesce(p_store->'offerings', offerings),
    catalog_link = pg_catalog.coalesce(p_store->>'catalog_link', catalog_link),
    references_link = pg_catalog.coalesce(p_store->>'references_link', references_link),
    vcard_link = pg_catalog.coalesce(p_store->>'vcard_link', vcard_link),
    shelf_image_url = pg_catalog.coalesce(pg_catalog.nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
    logo_url = pg_catalog.coalesce(pg_catalog.nullif(p_store->>'logo_url', ''), logo_url),
    working_hours = pg_catalog.coalesce(p_store->>'working_hours', working_hours),
    is_published = true,
    is_store = pg_catalog.coalesce((p_store->>'is_store')::boolean, is_store),
    kategori = pg_catalog.coalesce(p_store->>'kategori', kategori),
    latitude = case when p_store ? 'latitude' then (p_store->>'latitude')::float8 else latitude end,
    longitude = case when p_store ? 'longitude' then (p_store->>'longitude')::float8 else longitude end,
    location_accuracy_meters = case when p_store ? 'location_accuracy_meters' then (p_store->>'location_accuracy_meters')::float8 else location_accuracy_meters end,
    location_consent_at = case when p_store ? 'location_consent_at' then (p_store->>'location_consent_at')::timestamptz else location_consent_at end,
    location_source = case when p_store ? 'location_source' then p_store->>'location_source' else location_source end,
    updated_at = pg_catalog.now()
  where slug = p_slug
    and edit_token = p_edit_token
    and edit_token <> '';

  if not pg_catalog.found then
    raise exception 'EDIT_TOKEN_MISMATCH' using errcode = 'P0001';
  end if;
end;
$$;
