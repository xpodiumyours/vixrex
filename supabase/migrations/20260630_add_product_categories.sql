alter table public.stores
add column if not exists product_categories jsonb not null default '[]'::jsonb;

comment on column public.stores.product_categories is
'Ordered custom product categories for the store catalog.';

create or replace function public.update_store_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
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
    name = coalesce(p_store->>'name', name),
    business_type = coalesce(p_store->>'business_type', business_type),
    description = coalesce(p_store->>'description', description),
    corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
    whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
    instagram = coalesce(p_store->>'instagram', instagram),
    website = coalesce(p_store->>'website', website),
    address = coalesce(p_store->>'address', address),
    theme = coalesce(p_store->>'theme', theme),
    status = coalesce(p_store->>'status', status),
    marketplace_links = coalesce(p_store->'marketplace_links', marketplace_links),
    gallery_items = coalesce(p_store->'gallery_items', gallery_items),
    products = coalesce(p_store->'products', products),
    product_categories = coalesce(p_store->'product_categories', product_categories),
    offerings = coalesce(p_store->'offerings', offerings),
    catalog_link = coalesce(p_store->>'catalog_link', catalog_link),
    references_link = coalesce(p_store->>'references_link', references_link),
    vcard_link = coalesce(p_store->>'vcard_link', vcard_link),
    shelf_image_url = coalesce(nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
    logo_url = coalesce(nullif(p_store->>'logo_url', ''), logo_url),
    working_hours = coalesce(p_store->>'working_hours', working_hours),
    is_published = true,
    is_store = coalesce((p_store->>'is_store')::boolean, is_store),
    kategori = coalesce(p_store->>'kategori', kategori),
    latitude = case when p_store ? 'latitude' then (p_store->>'latitude')::float8 else latitude end,
    longitude = case when p_store ? 'longitude' then (p_store->>'longitude')::float8 else longitude end,
    location_accuracy_meters = case when p_store ? 'location_accuracy_meters' then (p_store->>'location_accuracy_meters')::float8 else location_accuracy_meters end,
    location_consent_at = case when p_store ? 'location_consent_at' then (p_store->>'location_consent_at')::timestamptz else location_consent_at end,
    location_source = case when p_store ? 'location_source' then p_store->>'location_source' else location_source end,
    province_code = coalesce(p_store->>'province_code', province_code),
    province_name = coalesce(p_store->>'province_name', province_name),
    district_code = coalesce(p_store->>'district_code', district_code),
    district_name = coalesce(p_store->>'district_name', district_name),
    google_business_link = coalesce(p_store->>'google_business_link', google_business_link),
    privacy_notice_acknowledged = coalesce((p_store->>'privacy_notice_acknowledged')::boolean, privacy_notice_acknowledged),
    privacy_notice_version = coalesce(p_store->>'privacy_notice_version', privacy_notice_version),
    privacy_notice_hash = coalesce(p_store->>'privacy_notice_hash', privacy_notice_hash),
    terms_accepted = coalesce((p_store->>'terms_accepted')::boolean, terms_accepted),
    terms_version = coalesce(p_store->>'terms_version', terms_version),
    terms_hash = coalesce(p_store->>'terms_hash', terms_hash),
    publication_consent_accepted = coalesce((p_store->>'publication_consent_accepted')::boolean, publication_consent_accepted),
    publication_consent_version = coalesce(p_store->>'publication_consent_version', publication_consent_version),
    publication_consent_hash = coalesce(p_store->>'publication_consent_hash', publication_consent_hash),
    updated_at = pg_catalog.now()
  where slug = p_slug
    and edit_token = p_edit_token
    and edit_token <> '';

  if not found then
    raise exception 'EDIT_TOKEN_MISMATCH' using errcode = 'P0001';
  end if;
end;
$$;

revoke execute on function public.update_store_with_token(text, text, jsonb)
from public;
grant execute on function public.update_store_with_token(text, text, jsonb)
to anon, authenticated;

notify pgrst, 'reload schema';
