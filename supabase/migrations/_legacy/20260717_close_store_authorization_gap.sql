-- Pilot security gate: edit tokens are write-only guest credentials.
-- They must never be readable through PostgREST, even for an authenticated owner.

-- A table-level SELECT grant also grants every column, so remove it first and
-- restore only the non-secret columns. This dynamically follows future
-- non-secret columns while permanently excluding edit_token.
REVOKE SELECT ON TABLE public.stores FROM anon, authenticated;
REVOKE SELECT (edit_token) ON TABLE public.stores FROM anon, authenticated;

DO $$
DECLARE
  safe_columns text;
BEGIN
  SELECT string_agg(quote_ident(attname), ', ' ORDER BY attnum)
  INTO safe_columns
  FROM pg_attribute
  WHERE attrelid = 'public.stores'::regclass
    AND attnum > 0
    AND NOT attisdropped
    AND attname <> 'edit_token';

  EXECUTE format(
    'GRANT SELECT (%s) ON TABLE public.stores TO anon, authenticated',
    safe_columns
  );
END;
$$;

-- Published stores remain public, while authenticated owners can also read
-- their unpublished store without exposing its edit token.
DROP POLICY IF EXISTS "Store owners can read their stores" ON public.stores;
CREATE POLICY "Store owners can read their stores"
ON public.stores FOR SELECT TO authenticated
USING ((select auth.uid()) = user_id);

-- Guest token remains valid for its originating device. Logged-in owners do
-- not need the token, which prevents a server-side token recovery path.
CREATE OR REPLACE FUNCTION public.update_store_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

CREATE OR REPLACE FUNCTION public.withdraw_store_publication_consent(
  p_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

CREATE OR REPLACE FUNCTION public.delete_store_with_token(
  p_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slug text := pg_catalog.btrim(p_slug);
  v_store_id uuid;
BEGIN
  SELECT id
  INTO v_store_id
  FROM public.stores
  WHERE slug = v_slug
    AND (
      (
        pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
        AND edit_token = pg_catalog.btrim(p_edit_token)
      )
      OR (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
      )
    );

  IF v_store_id IS NULL THEN
    RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH';
  END IF;

  DELETE FROM public.store_instagram_imports
  WHERE store_slug = v_slug
     OR connection_id IN (
       SELECT id FROM public.store_instagram_connections WHERE store_slug = v_slug
     );
  DELETE FROM public.store_instagram_tokens
  WHERE connection_id IN (
    SELECT id FROM public.store_instagram_connections WHERE store_slug = v_slug
  );
  DELETE FROM public.store_instagram_connections WHERE store_slug = v_slug;
  DELETE FROM public.vitrin_views WHERE store_id = v_store_id;
  DELETE FROM public.store_category_image_usage WHERE store_id = v_store_id;
  DELETE FROM public.booking_settings WHERE store_slug = v_slug;
  DELETE FROM public.store_articles WHERE store_slug = v_slug;
  DELETE FROM public.appointments WHERE store_slug = v_slug;
  DELETE FROM public.stores WHERE id = v_store_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.link_store_to_user(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.link_store_to_user(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) TO anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text) TO anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_store_with_token(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_store_with_token(text, text) TO anon, authenticated;

-- Remove the live broad policies by their observed names, then restore only
-- owner access. Public booking and appointment-token RPCs remain unchanged.
DROP POLICY IF EXISTS "Anyone can read appointments by token" ON public.appointments;
DROP POLICY IF EXISTS "Public can insert appointments" ON public.appointments;
DROP POLICY IF EXISTS "Store owner can update appointments" ON public.appointments;
DROP POLICY IF EXISTS "Owners can view their store appointments" ON public.appointments;
DROP POLICY IF EXISTS "Owners can update their store appointments" ON public.appointments;

CREATE POLICY "Owners can view their store appointments"
ON public.appointments FOR SELECT TO authenticated
USING (
  (select auth.uid()) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = appointments.store_slug
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can update their store appointments"
ON public.appointments FOR UPDATE TO authenticated
USING (
  (select auth.uid()) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = appointments.store_slug
      AND s.user_id = (select auth.uid())
  )
)
WITH CHECK (
  (select auth.uid()) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = appointments.store_slug
      AND s.user_id = (select auth.uid())
  )
);

DROP POLICY IF EXISTS "Anyone can upsert booking_settings" ON public.booking_settings;
DROP POLICY IF EXISTS "Allow owners to insert booking settings" ON public.booking_settings;
DROP POLICY IF EXISTS "Allow owners to update booking settings" ON public.booking_settings;
DROP POLICY IF EXISTS "Owners can insert booking settings" ON public.booking_settings;
DROP POLICY IF EXISTS "Owners can update booking settings" ON public.booking_settings;

CREATE POLICY "Owners can insert booking settings"
ON public.booking_settings FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = booking_settings.store_slug
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can update booking settings"
ON public.booking_settings FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = booking_settings.store_slug
      AND s.user_id = (select auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = booking_settings.store_slug
      AND s.user_id = (select auth.uid())
  )
);

NOTIFY pgrst, 'reload schema';
