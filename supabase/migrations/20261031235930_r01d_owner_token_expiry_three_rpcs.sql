-- R-01D: three existing owner RPCs must reject expired bearer edit tokens.
-- Scope: only their WHERE/EXISTS conditions. Owner auth route and NULL legacy token TTL unaffected.
-- No change to tables, rows, triggers, EXECUTE privileges, or other functions.
DO $r01d_preflight$
BEGIN
IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.get_store_premium_status(text,text)'::pg_catalog.regprocedure)) <> '6f7d94c554a8bdc1a8aea99e9ca4f88d' THEN RAISE EXCEPTION 'R01D_PREFLIGHT: get_store_premium_status changed'; END IF;
IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.update_store_with_token(text,text,jsonb)'::pg_catalog.regprocedure)) <> 'e1d040dd5ee701435ecddf6856737052' THEN RAISE EXCEPTION 'R01D_PREFLIGHT: update_store_with_token changed'; END IF;
IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.withdraw_store_publication_consent(text,text)'::pg_catalog.regprocedure)) <> '4e513f2afd116d8a874c7df4b88b6cdb' THEN RAISE EXCEPTION 'R01D_PREFLIGHT: withdraw_store_publication_consent changed'; END IF;
END;
$r01d_preflight$;

CREATE OR REPLACE FUNCTION public.get_store_premium_status(p_slug text, p_edit_token text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'extensions'
AS $function$
declare
  v_user_id uuid := auth.uid();
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_store_id uuid;
  v_premium_expires_at timestamptz;
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;

  select id, premium_expires_at
  into v_store_id, v_premium_expires_at
  from public.stores
  where slug = v_slug;

  if v_store_id is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  -- Sahiplik kanıtı: oturum açmış kullanıcı vitrinin sahibi VEYA
  -- edit_token eşleşiyor (create_owner_session ile aynı iki yol).
  if not (
    (
      v_user_id is not null
      and exists (
        select 1 from public.stores
        where id = v_store_id and user_id = v_user_id
      )
    )
    or (
      v_token <> ''
      and exists (
        select 1 from public.stores
        where id = v_store_id and edit_token = v_token
          and (edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())
      )
    )
  ) then
    raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'store_id', v_store_id,
    'is_premium',
      v_premium_expires_at is not null and v_premium_expires_at > now(),
    'premium_expires_at', v_premium_expires_at
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.update_store_with_token(p_slug text, p_edit_token text, p_store jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;

  UPDATE public.stores
  SET
    name = coalesce(p_store->>'name', name),
    business_type = coalesce(p_store->>'business_type', business_type),
    description = coalesce(p_store->>'description', description),
    corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
    about_kicker = coalesce(p_store->>'about_kicker', about_kicker),
    about_title = coalesce(p_store->>'about_title', about_title),
    about_image_url = coalesce(p_store->>'about_image_url', about_image_url),
    about_image_caption = coalesce(p_store->>'about_image_caption', about_image_caption),
    about_values = coalesce(p_store->'about_values', about_values),
    gallery_section_kicker = coalesce(p_store->>'gallery_section_kicker', gallery_section_kicker),
    gallery_section_title = coalesce(p_store->>'gallery_section_title', gallery_section_title),
    show_storefront_rating = coalesce((p_store->>'show_storefront_rating')::boolean, show_storefront_rating),
    show_directions_link = coalesce((p_store->>'show_directions_link')::boolean, show_directions_link),
    whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
    phone = coalesce(p_store->>'phone', phone),
    email = coalesce(p_store->>'email', email),
    hero_badge = coalesce(p_store->>'hero_badge', hero_badge),
    featured_banner_label = coalesce(p_store->>'featured_banner_label', featured_banner_label),
    featured_banner_title = coalesce(p_store->>'featured_banner_title', featured_banner_title),
    featured_banner_description = coalesce(p_store->>'featured_banner_description', featured_banner_description),
    featured_banner_image_url = coalesce(p_store->>'featured_banner_image_url', featured_banner_image_url),
    featured_banner_price_text = coalesce(p_store->>'featured_banner_price_text', featured_banner_price_text),
    faq_items = coalesce(p_store->'faq_items', faq_items),
    instagram = coalesce(p_store->>'instagram', instagram),
    website = coalesce(p_store->>'website', website),
    address = coalesce(p_store->>'address', address),
    theme = coalesce(p_store->>'theme', theme),
    status = coalesce(p_store->>'status', status),
    marketplace_links = CASE WHEN p_store ? 'marketplace_links'
      THEN public._sanitize_marketplace_links(p_store->'marketplace_links')
      ELSE marketplace_links END,
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
    latitude = CASE WHEN p_store ? 'latitude' THEN (p_store->>'latitude')::float8 ELSE latitude END,
    longitude = CASE WHEN p_store ? 'longitude' THEN (p_store->>'longitude')::float8 ELSE longitude END,
    location_accuracy_meters = CASE WHEN p_store ? 'location_accuracy_meters' THEN (p_store->>'location_accuracy_meters')::float8 ELSE location_accuracy_meters END,
    location_consent_at = CASE WHEN p_store ? 'location_consent_at' THEN (p_store->>'location_consent_at')::timestamptz ELSE location_consent_at END,
    location_source = CASE WHEN p_store ? 'location_source' THEN p_store->>'location_source' ELSE location_source END,
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
  WHERE slug = pg_catalog.btrim(p_slug)
    AND (
      (
        pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
        AND edit_token = pg_catalog.btrim(p_edit_token)
        AND (edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())
      )
      OR (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
      )
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'STORE_UPDATE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.withdraw_store_publication_consent(p_slug text, p_edit_token text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  UPDATE public.stores
  SET
    is_published = false,
    publication_consent_accepted = false,
    publication_consent_withdrawn_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  WHERE slug = pg_catalog.btrim(p_slug)
    AND (
      (
        pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
        AND edit_token = pg_catalog.btrim(p_edit_token)
        AND (edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())
      )
      OR (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
      )
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'STORE_UPDATE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;
END;
$function$;

DO $r01d_postcheck$
BEGIN
IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.get_store_premium_status(text,text)'::pg_catalog.regprocedure),'(edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())') = 0 THEN RAISE EXCEPTION 'R01D_POSTCHECK: get_store_premium_status missing expiry'; END IF;
IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.update_store_with_token(text,text,jsonb)'::pg_catalog.regprocedure),'(edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())') = 0 THEN RAISE EXCEPTION 'R01D_POSTCHECK: update_store_with_token missing expiry'; END IF;
IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.withdraw_store_publication_consent(text,text)'::pg_catalog.regprocedure),'(edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())') = 0 THEN RAISE EXCEPTION 'R01D_POSTCHECK: withdraw_store_publication_consent missing expiry'; END IF;
END;
$r01d_postcheck$;
