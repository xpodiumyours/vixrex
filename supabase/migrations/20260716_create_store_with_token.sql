-- Guest/authenticated store create via security-definer RPC.
-- Avoids broad anon INSERT RLS; user_id = auth.uid() when logged in, else null.

create or replace function public.create_store_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if p_slug is null or pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  insert into public.stores (
    slug,
    edit_token,
    user_id,
    name,
    business_type,
    description,
    corporate_bio,
    whatsapp,
    instagram,
    website,
    address,
    theme,
    status,
    marketplace_links,
    gallery_items,
    products,
    product_categories,
    offerings,
    catalog_link,
    references_link,
    vcard_link,
    shelf_image_url,
    logo_url,
    working_hours,
    is_published,
    is_store,
    kategori,
    latitude,
    longitude,
    location_accuracy_meters,
    location_consent_at,
    location_source,
    province_code,
    province_name,
    district_code,
    district_name,
    google_business_link,
    privacy_notice_acknowledged,
    privacy_notice_version,
    privacy_notice_hash,
    terms_accepted,
    terms_version,
    terms_hash,
    publication_consent_accepted,
    publication_consent_version,
    publication_consent_hash,
    updated_at
  ) values (
    pg_catalog.btrim(p_slug),
    pg_catalog.btrim(p_edit_token),
    v_user_id,
    coalesce(p_store->>'name', ''),
    coalesce(p_store->>'business_type', ''),
    coalesce(p_store->>'description', ''),
    coalesce(p_store->>'corporate_bio', ''),
    coalesce(p_store->>'whatsapp', ''),
    coalesce(p_store->>'instagram', ''),
    coalesce(p_store->>'website', ''),
    coalesce(p_store->>'address', ''),
    coalesce(p_store->>'theme', ''),
    coalesce(p_store->>'status', ''),
    coalesce(p_store->'marketplace_links', '[]'::jsonb),
    coalesce(p_store->'gallery_items', '[]'::jsonb),
    coalesce(p_store->'products', '[]'::jsonb),
    coalesce(p_store->'product_categories', '[]'::jsonb),
    coalesce(p_store->'offerings', '[]'::jsonb),
    coalesce(p_store->>'catalog_link', ''),
    coalesce(p_store->>'references_link', ''),
    coalesce(p_store->>'vcard_link', ''),
    coalesce(p_store->>'shelf_image_url', ''),
    coalesce(p_store->>'logo_url', ''),
    coalesce(p_store->>'working_hours', ''),
    true,
    coalesce((p_store->>'is_store')::boolean, false),
    coalesce(p_store->>'kategori', ''),
    case when p_store ? 'latitude' and nullif(p_store->>'latitude', '') is not null
      then (p_store->>'latitude')::float8 else null end,
    case when p_store ? 'longitude' and nullif(p_store->>'longitude', '') is not null
      then (p_store->>'longitude')::float8 else null end,
    case when p_store ? 'location_accuracy_meters'
      and nullif(p_store->>'location_accuracy_meters', '') is not null
      then (p_store->>'location_accuracy_meters')::float8 else null end,
    case when p_store ? 'location_consent_at'
      and nullif(p_store->>'location_consent_at', '') is not null
      then (p_store->>'location_consent_at')::timestamptz else null end,
    p_store->>'location_source',
    coalesce(p_store->>'province_code', ''),
    coalesce(p_store->>'province_name', ''),
    coalesce(p_store->>'district_code', ''),
    coalesce(p_store->>'district_name', ''),
    coalesce(p_store->>'google_business_link', ''),
    coalesce((p_store->>'privacy_notice_acknowledged')::boolean, false),
    coalesce(p_store->>'privacy_notice_version', ''),
    coalesce(p_store->>'privacy_notice_hash', ''),
    coalesce((p_store->>'terms_accepted')::boolean, false),
    coalesce(p_store->>'terms_version', ''),
    coalesce(p_store->>'terms_hash', ''),
    coalesce(
      (p_store->>'publication_consent_accepted')::boolean,
      (p_store->>'explicit_consent_given')::boolean,
      false
    ),
    coalesce(p_store->>'publication_consent_version', ''),
    coalesce(p_store->>'publication_consent_hash', ''),
    pg_catalog.now()
  );
end;
$$;

revoke execute on function public.create_store_with_token(text, text, jsonb)
from public;
grant execute on function public.create_store_with_token(text, text, jsonb)
to anon, authenticated;
