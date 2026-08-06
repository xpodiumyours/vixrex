-- ============================================================================
-- VixRex TEMEL ŞEMA (baseline) — buluttan alındı 2026-08-05
--
-- NEDEN VAR
-- Migration zinciri sıfırdan çalışmıyordu: bazı nesneler hiçbir dosyada
-- yoktu, yalnız bulut veritabanında elle açılmışlardı. Bu dosya bulutun
-- o günkü tam şemasıdır; zincirin başlangıç noktası olur.
--
-- Bu dosyanın kapsadığı eski migration'lar supabase/migrations_arsiv/
-- altına taşındı. Silinmediler; geçmiş kaydı olarak duruyorlar ve git
-- içinde de tam hâlleriyle mevcutlar.
--
-- Bu noktadan SONRAKİ değişiklikler normal migration olarak eklenir.
-- ============================================================================




SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "moddatetime" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."_check_store_authorization"("p_store_id" "uuid", "p_edit_token" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE v_owner_id UUID; v_stored_token TEXT;
BEGIN
  SELECT user_id, edit_token INTO v_owner_id, v_stored_token
  FROM public.stores WHERE id = p_store_id;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF auth.uid() IS NOT NULL AND v_owner_id IS NOT NULL AND v_owner_id = auth.uid() THEN
    RETURN TRUE;
  END IF;
  IF p_edit_token IS NOT NULL
     AND pg_catalog.length(pg_catalog.btrim(p_edit_token)) >= 24
     AND v_stored_token IS NOT NULL
     AND v_stored_token = pg_catalog.btrim(p_edit_token)
     AND v_stored_token <> '' THEN
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;
$$;


ALTER FUNCTION "public"."_check_store_authorization"("p_store_id" "uuid", "p_edit_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."apply_category_template"("p_store_id" "uuid", "p_category_key" "text", "p_fill_cover" boolean DEFAULT true, "p_fill_logo" boolean DEFAULT true, "p_fill_gallery" boolean DEFAULT true, "p_fill_products" boolean DEFAULT true, "p_edit_token" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  v_result jsonb := '{}'::jsonb;
  v_image_row record;
  v_current_cover text;
  v_current_logo text;
  v_current_gallery jsonb;
  v_current_products jsonb;
  v_gallery_items jsonb := '[]'::jsonb;
  v_template_products jsonb := '[]'::jsonb;
  v_applied_count int := 0;
  v_authorized boolean := false;
  v_storage_version smallint := 1;
  v_table_product_count int := 0;
  v_tpl record;
  v_sort int := 0;
  v_slug text;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.stores s
    WHERE s.id = p_store_id
      AND (
        (auth.uid() IS NOT NULL AND s.user_id = auth.uid())
        OR (
          pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
          AND s.edit_token = pg_catalog.btrim(p_edit_token)
        )
      )
  ) INTO v_authorized;

  IF NOT v_authorized THEN
    RAISE EXCEPTION 'STORE_UPDATE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;

  SELECT
    shelf_image_url,
    logo_url,
    gallery_items,
    products,
    coalesce(product_storage_version, 1)
  INTO
    v_current_cover,
    v_current_logo,
    v_current_gallery,
    v_current_products,
    v_storage_version
  FROM public.stores
  WHERE id = p_store_id;

  IF p_fill_cover THEN
    SELECT image_url INTO v_image_row
    FROM public.category_image_templates
    WHERE category_key = p_category_key AND image_type = 'cover' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_cover IS NULL OR v_current_cover = '') THEN
      UPDATE public.stores SET shelf_image_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"cover": true}'::jsonb;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_logo THEN
    SELECT image_url INTO v_image_row
    FROM public.category_image_templates
    WHERE category_key = p_category_key AND image_type = 'logo_placeholder' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_logo IS NULL OR v_current_logo = '') THEN
      UPDATE public.stores SET logo_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"logo": true}'::jsonb;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_gallery THEN
    IF v_current_gallery IS NULL OR jsonb_array_length(v_current_gallery) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'imageUrl', image_url,
          'title', coalesce(title, 'Gorsel')
        ) ORDER BY display_order
      )
      INTO v_gallery_items
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND image_type = 'gallery' AND is_active = true;

      IF v_gallery_items IS NOT NULL AND jsonb_array_length(v_gallery_items) > 0 THEN
        UPDATE public.stores SET gallery_items = v_gallery_items WHERE id = p_store_id;
        v_result := v_result || '{"gallery": true}'::jsonb;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  IF p_fill_products THEN
    IF v_storage_version = 2 THEN
      SELECT count(*)::int INTO v_table_product_count
      FROM public.products
      WHERE store_id = p_store_id AND is_active = true;

      IF v_table_product_count = 0 THEN
        FOR v_tpl IN
          SELECT image_url, title, display_order
          FROM public.category_image_templates
          WHERE category_key = p_category_key
            AND image_type = 'product'
            AND is_active = true
          ORDER BY display_order
        LOOP
          v_slug := lower(replace(replace(coalesce(v_tpl.title, 'urun'), ' ', '-'), '.', ''));
          IF v_slug IS NULL OR v_slug = '' THEN
            v_slug := 'urun-' || v_sort::text;
          END IF;
          -- slug çakışmasını önle
          v_slug := v_slug || '-' || v_sort::text;

          INSERT INTO public.products (
            store_id,
            name,
            slug,
            description,
            price_text,
            image_urls,
            source_type,
            is_visible,
            is_active,
            sort_order
          ) VALUES (
            p_store_id,
            coalesce(v_tpl.title, 'Urun'),
            v_slug,
            '',
            '',
            jsonb_build_array(v_tpl.image_url),
            'category_template',
            true,
            true,
            v_sort
          );
          v_sort := v_sort + 1;
        END LOOP;

        IF v_sort > 0 THEN
          v_result := v_result || '{"products": true}'::jsonb;
          v_applied_count := v_applied_count + 1;
        END IF;
      END IF;
    ELSE
      IF v_current_products IS NULL OR jsonb_array_length(v_current_products) = 0 THEN
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', gen_random_uuid(),
            'name', coalesce(title, 'Urun'),
            'description', '',
            'price', '',
            'imageUrls', jsonb_build_array(image_url),
            'isVisible', true,
            'source', 'category_template'
          ) ORDER BY display_order
        )
        INTO v_template_products
        FROM public.category_image_templates
        WHERE category_key = p_category_key AND image_type = 'product' AND is_active = true;

        IF v_template_products IS NOT NULL AND jsonb_array_length(v_template_products) > 0 THEN
          UPDATE public.stores SET products = v_template_products WHERE id = p_store_id;
          v_result := v_result || '{"products": true}'::jsonb;
          v_applied_count := v_applied_count + 1;
        END IF;
      END IF;
    END IF;
  END IF;

  IF v_applied_count > 0 THEN
    INSERT INTO public.store_category_image_usage (store_id, category_key, images_used)
    VALUES (
      p_store_id,
      p_category_key,
      coalesce(
        (
          SELECT jsonb_agg(image_url)
          FROM public.category_image_templates
          WHERE category_key = p_category_key AND is_active = true
        ),
        '[]'::jsonb
      )
    )
    ON CONFLICT (store_id) DO UPDATE SET
      category_key = EXCLUDED.category_key,
      images_used = EXCLUDED.images_used,
      applied_at = pg_catalog.now();
  END IF;

  RETURN v_result || jsonb_build_object(
    'success', v_applied_count > 0,
    'image_count', (
      SELECT count(*)::int
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND is_active = true
    )
  );
END;
$$;


ALTER FUNCTION "public"."apply_category_template"("p_store_id" "uuid", "p_category_key" "text", "p_fill_cover" boolean, "p_fill_logo" boolean, "p_fill_gallery" boolean, "p_fill_products" boolean, "p_edit_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."batch_create_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE
  v_product JSONB;
  v_new_id UUID;
  v_success_count INT := 0;
  v_error_count INT := 0;
  v_errors JSONB := '[]'::JSONB;
  v_index INT := 0;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;
  FOR v_product IN SELECT * FROM jsonb_array_elements(p_products)
  LOOP
    v_index := v_index + 1;
    
    BEGIN
      DECLARE
        v_name TEXT := COALESCE(v_product->>'name', '');
        v_slug TEXT := COALESCE(v_product->>'slug', '');
        v_description TEXT := COALESCE(v_product->>'description', '');
        v_price_text TEXT := COALESCE(v_product->>'price_text', '');
        v_price_amount NUMERIC := NULL;
        v_image_urls JSONB := COALESCE(v_product->'image_urls', '[]'::jsonb);
        v_category_id UUID := NULL;
        v_source_type TEXT := COALESCE(v_product->>'source_type', 'xml_import');
        v_external_product_id TEXT := v_product->>'external_product_id';
        v_is_visible BOOLEAN := COALESCE((v_product->>'isVisible')::boolean, true);
        v_sort_order INT := COALESCE((v_product->>'sort_order')::int, 0);
      BEGIN
        IF length(trim(v_name)) = 0 THEN
          v_error_count := v_error_count + 1;
          v_errors := v_errors || jsonb_build_object('index', v_index, 'error', 'EMPTY_NAME');
          CONTINUE;
        END IF;
        IF length(trim(v_slug)) = 0 THEN
          v_slug := lower(regexp_replace(regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'), '\s+', '-', 'g'));
          IF EXISTS (SELECT 1 FROM public.products WHERE store_id = p_store_id AND slug = v_slug) THEN
            v_slug := v_slug || '-' || substr(md5(random()::text), 1, 6);
          END IF;
        END IF;
        IF v_price_amount IS NULL AND length(v_price_text) > 0 THEN
          v_price_amount := NULLIF(regexp_replace(regexp_replace(v_price_text, '[^0-9.,]', '', 'g'), ',', '.', 'g'), '')::numeric;
        END IF;
        IF v_product->>'category_id' IS NOT NULL THEN
          IF EXISTS (SELECT 1 FROM public.product_categories pc WHERE pc.id = (v_product->>'category_id')::uuid AND pc.store_id = p_store_id) THEN
            v_category_id := (v_product->>'category_id')::uuid;
          END IF;
        END IF;
        INSERT INTO public.products (store_id, category_id, source_type, external_product_id, name, slug, description, price_text, price_amount, image_urls, is_visible, sort_order)
        VALUES (p_store_id, v_category_id, v_source_type, v_external_product_id, v_name, v_slug, v_description, v_price_text, v_price_amount, v_image_urls, v_is_visible, v_sort_order);
        v_success_count := v_success_count + 1;
      EXCEPTION WHEN OTHERS THEN
        v_error_count := v_error_count + 1;
        v_errors := v_errors || jsonb_build_object('index', v_index, 'error', SQLERRM);
      END;
    END;
  END LOOP;
  RETURN jsonb_build_object('success', true, 'total', v_index, 'inserted', v_success_count, 'errors', v_error_count, 'error_details', v_errors);
END;
$$;


ALTER FUNCTION "public"."batch_create_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."bulk_insert_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE
  v_inserted INT := 0;
  v_skipped INT := 0;
  v_errors JSONB := '[]'::jsonb;
  v_product JSONB;
  v_name TEXT;
  v_slug TEXT;
  v_external_id TEXT;
  v_category_name TEXT;
  v_category_id UUID;
  v_image_urls JSONB;
  v_new_product_id UUID;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;
  FOR v_product IN SELECT * FROM jsonb_array_elements(p_products)
  LOOP
    BEGIN
      v_name := trim(v_product->>'name');
      IF v_name IS NULL OR length(v_name) = 0 THEN
        v_skipped := v_skipped + 1;
        CONTINUE;
      END IF;
      v_slug := lower(regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'));
      v_slug := regexp_replace(v_slug, '\s+', '-', 'g');
      v_slug := trim(v_slug, '-');
      IF EXISTS (
        SELECT 1 FROM public.products
        WHERE store_id = p_store_id AND slug = v_slug
      ) THEN
        v_slug := v_slug || '-' || substr(md5(random()::text), 1, 6);
      END IF;
      v_external_id := v_product->>'external_product_id';
      IF v_external_id IS NOT NULL AND length(v_external_id) > 0 THEN
        IF EXISTS (
          SELECT 1 FROM public.products
          WHERE store_id = p_store_id
            AND source_type = 'xml'
            AND external_product_id = v_external_id
        ) THEN
          v_skipped := v_skipped + 1;
          CONTINUE;
        END IF;
      END IF;
      v_category_name := v_product->>'category_name';
      v_category_id := NULL;
      IF v_category_name IS NOT NULL AND length(v_category_name) > 0 THEN
        SELECT id INTO v_category_id
        FROM public.product_categories
        WHERE store_id = p_store_id
          AND lower(name) = lower(v_category_name)
        LIMIT 1;
        IF v_category_id IS NULL THEN
          INSERT INTO public.product_categories (store_id, name, slug)
          VALUES (p_store_id, v_category_name, lower(regexp_replace(v_category_name, '[^a-zA-Z0-9\s-]', '', 'g')))
          RETURNING id INTO v_category_id;
        END IF;
      END IF;
      v_image_urls := COALESCE(v_product->'image_urls', '[]'::jsonb);
      IF jsonb_typeof(v_image_urls) != 'array' THEN
        v_image_urls := '[]'::jsonb;
      END IF;
      INSERT INTO public.products (
        store_id, name, slug, description,
        price_text, price_amount, image_urls,
        category_id, source_type, external_product_id,
        stock_quantity, stock_status,
        is_visible, is_active, sort_order
      ) VALUES (
        p_store_id,
        v_name,
        v_slug,
        COALESCE(v_product->>'description', ''),
        COALESCE(v_product->>'price_text', ''),
        (v_product->>'price_amount')::NUMERIC,
        v_image_urls,
        v_category_id,
        'xml',
        v_external_id,
        (v_product->>'stock_quantity')::INT,
        COALESCE(v_product->>'stock_status', 'Mevcut'),
        true,
        true,
        0
      ) RETURNING id INTO v_new_product_id;
      v_inserted := v_inserted + 1;
    EXCEPTION WHEN OTHERS THEN
      v_errors := v_errors || jsonb_build_object(
        'name', v_product->>'name',
        'error', SQLERRM
      );
      v_skipped := v_skipped + 1;
    END;
  END LOOP;
  UPDATE public.products
  SET sort_order = sub.row_num
  FROM (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) - 1 AS row_num
    FROM public.products
    WHERE store_id = p_store_id AND source_type = 'xml'
  ) sub
  WHERE products.id = sub.id;
  RETURN jsonb_build_object(
    'inserted', v_inserted,
    'skipped', v_skipped,
    'errors', v_errors
  );
END;
$$;


ALTER FUNCTION "public"."bulk_insert_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."consume_assistant_request"("p_client_key" "text", "p_max_requests" integer DEFAULT 6) RETURNS TABLE("allowed" boolean, "retry_after_seconds" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_window_started_at timestamptz;
  v_request_count integer;
begin
  insert into public.assistant_rate_limits as limits (
    client_key,
    window_started_at,
    request_count,
    updated_at
  )
  values (p_client_key, now(), 1, now())
  on conflict (client_key) do update
  set
    window_started_at = case
      when limits.window_started_at <= now() - interval '1 minute' then now()
      else limits.window_started_at
    end,
    request_count = case
      when limits.window_started_at <= now() - interval '1 minute' then 1
      else limits.request_count + 1
    end,
    updated_at = now()
  returning window_started_at, request_count
  into v_window_started_at, v_request_count;

  return query select
    v_request_count <= p_max_requests,
    greatest(
      0,
      ceil(extract(epoch from (v_window_started_at + interval '1 minute' - now())))::integer
    );
end;
$$;


ALTER FUNCTION "public"."consume_assistant_request"("p_client_key" "text", "p_max_requests" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_store_product"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text" DEFAULT ''::"text", "p_price_text" "text" DEFAULT ''::"text", "p_price_amount" numeric DEFAULT NULL::numeric, "p_image_urls" "jsonb" DEFAULT '[]'::"jsonb", "p_category_id" "uuid" DEFAULT NULL::"uuid", "p_source_type" "text" DEFAULT 'manual'::"text", "p_external_product_id" "text" DEFAULT NULL::"text", "p_is_visible" boolean DEFAULT true, "p_sort_order" integer DEFAULT 0, "p_old_price_amount" numeric DEFAULT NULL::numeric, "p_badge_tag" "text" DEFAULT NULL::"text", "p_fulfillment_region" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE
  v_new_product UUID;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  IF p_category_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.product_categories pc
      WHERE pc.id = p_category_id AND pc.store_id = p_store_id
    ) THEN
      RAISE EXCEPTION 'CATEGORY_NOT_IN_SAME_STORE';
    END IF;
  END IF;

  INSERT INTO public.products (
    store_id, name, slug, description,
    price_text, price_amount, image_urls,
    category_id, source_type, external_product_id,
    is_visible, sort_order,
    old_price_amount, badge_tag, fulfillment_region
  ) VALUES (
    p_store_id, trim(p_name), trim(p_slug), p_description,
    p_price_text, p_price_amount, p_image_urls,
    p_category_id, p_source_type, p_external_product_id,
    p_is_visible, p_sort_order,
    p_old_price_amount,
    NULLIF(trim(COALESCE(p_badge_tag, '')), ''),
    NULLIF(trim(COALESCE(p_fulfillment_region, '')), '')
  )
  RETURNING id INTO v_new_product;

  RETURN jsonb_build_object('id', v_new_product, 'success', true);
END;
$$;


ALTER FUNCTION "public"."create_store_product"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_source_type" "text", "p_external_product_id" "text", "p_is_visible" boolean, "p_sort_order" integer, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  INSERT INTO public.stores (
    slug, edit_token, user_id, name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address, theme, status,
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, is_published, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_consent_at, location_source,
    province_code, province_name, district_code, district_name, google_business_link,
    privacy_notice_acknowledged, privacy_notice_version, privacy_notice_hash,
    terms_accepted, terms_version, terms_hash,
    publication_consent_accepted, publication_consent_version, publication_consent_hash,
    updated_at
  ) VALUES (
    pg_catalog.btrim(p_slug),
    pg_catalog.btrim(p_edit_token),
    v_user_id,
    coalesce(p_store->>'name', ''),
    coalesce(p_store->>'business_type', ''),
    coalesce(p_store->>'description', ''),
    coalesce(p_store->>'corporate_bio', ''),
    coalesce(p_store->>'whatsapp', ''),
    coalesce(p_store->>'phone', ''),
    coalesce(p_store->>'email', ''),
    coalesce(p_store->>'hero_badge', ''),
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
    CASE WHEN p_store ? 'latitude' AND nullif(p_store->>'latitude', '') IS NOT NULL
      THEN (p_store->>'latitude')::float8 ELSE NULL END,
    CASE WHEN p_store ? 'longitude' AND nullif(p_store->>'longitude', '') IS NOT NULL
      THEN (p_store->>'longitude')::float8 ELSE NULL END,
    CASE WHEN p_store ? 'location_accuracy_meters'
      AND nullif(p_store->>'location_accuracy_meters', '') IS NOT NULL
      THEN (p_store->>'location_accuracy_meters')::float8 ELSE NULL END,
    CASE WHEN p_store ? 'location_consent_at'
      AND nullif(p_store->>'location_consent_at', '') IS NOT NULL
      THEN (p_store->>'location_consent_at')::timestamptz ELSE NULL END,
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
    coalesce((p_store->>'publication_consent_accepted')::boolean, false),
    coalesce(p_store->>'publication_consent_version', ''),
    coalesce(p_store->>'publication_consent_hash', ''),
    pg_catalog.now()
  );
END;
$$;


ALTER FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_store_product"("p_product_id" "uuid", "p_edit_token" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE v_store_id UUID;
BEGIN
  SELECT store_id INTO v_store_id FROM public.products WHERE id = p_product_id;
  IF v_store_id IS NULL THEN RAISE EXCEPTION 'PRODUCT_NOT_FOUND'; END IF;
  IF NOT public._check_store_authorization(v_store_id, p_edit_token) THEN RAISE EXCEPTION 'UNAUTHORIZED'; END IF;
  DELETE FROM public.products WHERE id = p_product_id;
  RETURN jsonb_build_object('id', p_product_id, 'success', true);
END;
$$;


ALTER FUNCTION "public"."delete_store_product"("p_product_id" "uuid", "p_edit_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_store_with_token"("p_slug" "text", "p_edit_token" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  v_slug text := pg_catalog.btrim(p_slug);
  v_store_id uuid;
BEGIN
  IF v_slug IS NULL OR v_slug = '' THEN
    RAISE EXCEPTION 'STORE_DELETE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;

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
    RAISE EXCEPTION 'STORE_DELETE_NOT_ALLOWED' USING errcode = 'P0001';
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


ALTER FUNCTION "public"."delete_store_with_token"("p_slug" "text", "p_edit_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_user_account"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_store_slug TEXT;
BEGIN
  SELECT slug INTO v_store_slug
  FROM public.stores
  WHERE user_id = v_user_id
  LIMIT 1;
  IF v_store_slug IS NOT NULL THEN
    DELETE FROM public.appointment_reschedule_requests
    WHERE appointment_id IN (
      SELECT id FROM public.appointments WHERE store_slug = v_store_slug
    );
    DELETE FROM public.appointments WHERE store_slug = v_store_slug;
    DELETE FROM public.booking_blocks WHERE store_slug = v_store_slug;
    DELETE FROM public.booking_settings WHERE store_slug = v_store_slug;
    DELETE FROM public.article_reports
    WHERE article_id IN (
      SELECT id FROM public.store_articles WHERE store_slug = v_store_slug
    );
    DELETE FROM public.store_articles WHERE store_slug = v_store_slug;
    DELETE FROM public.store_instagram_tokens
    WHERE connection_id IN (
      SELECT id FROM public.store_instagram_connections WHERE store_slug = v_store_slug
    );
    DELETE FROM public.store_instagram_imports WHERE store_slug = v_store_slug;
    DELETE FROM public.store_instagram_connections WHERE store_slug = v_store_slug;
    DELETE FROM public.legal_acceptance_events WHERE store_slug = v_store_slug;
    DELETE FROM public.vitrin_views WHERE store_slug = v_store_slug;
    DELETE FROM public.store_category_image_usage
    WHERE store_id IN (
      SELECT id FROM public.stores WHERE user_id = v_user_id
    );
    DELETE FROM public.stores WHERE user_id = v_user_id;
  END IF;
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;


ALTER FUNCTION "public"."delete_user_account"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_audit_logs"("p_limit" integer DEFAULT 50, "p_action" "text" DEFAULT NULL::"text", "p_target_type" "text" DEFAULT NULL::"text") RETURNS TABLE("id" "uuid", "user_id" "uuid", "session_id" "text", "action" "text", "target_type" "text", "target_id" "text", "old_value" "jsonb", "new_value" "jsonb", "metadata" "jsonb", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.id, al.user_id, al.session_id, al.action, al.target_type,
    al.target_id, al.old_value, al.new_value, al.metadata, al.created_at
  FROM audit_logs al
  WHERE
    al.user_id = auth.uid()
    AND (p_action IS NULL OR al.action = p_action)
    AND (p_target_type IS NULL OR al.target_type = p_target_type)
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_action" "text", "p_target_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_audit_logs"("p_limit" integer DEFAULT 50, "p_user_id" "uuid" DEFAULT NULL::"uuid", "p_action" "text" DEFAULT NULL::"text", "p_target_type" "text" DEFAULT NULL::"text") RETURNS TABLE("id" "uuid", "user_id" "uuid", "session_id" "text", "action" "text", "target_type" "text", "target_id" "text", "old_value" "jsonb", "new_value" "jsonb", "metadata" "jsonb", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.id, al.user_id, al.session_id, al.action, al.target_type,
    al.target_id, al.old_value, al.new_value, al.metadata, al.created_at
  FROM audit_logs al
  WHERE
    al.user_id = auth.uid()
    AND (p_action IS NULL OR al.action = p_action)
    AND (p_target_type IS NULL OR al.target_type = p_target_type)
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_user_id" "uuid", "p_action" "text", "p_target_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_feature_flags"() RETURNS TABLE("flag_key" "text", "is_enabled" boolean, "target_users" "text")
    LANGUAGE "sql" STABLE
    SET "search_path" TO ''
    AS $$
  SELECT ff.flag_key, ff.is_enabled, ff.target_users
  FROM public.feature_flags AS ff;
$$;


ALTER FUNCTION "public"."get_feature_flags"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_store_preview"("p_slug" "text", "p_edit_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  SELECT jsonb_build_object(
    'id', s.id,
    'slug', s.slug,
    'name', s.name,
    'business_type', s.business_type,
    'description', s.description,
    'corporate_bio', s.corporate_bio,
    'whatsapp', s.whatsapp,
    'phone', s.phone,
    'email', s.email,
    'hero_badge', s.hero_badge,
    'instagram', s.instagram,
    'website', s.website,
    'address', s.address,
    'status', s.status,
    'marketplace_links', s.marketplace_links,
    'gallery_items', s.gallery_items,
    'products', s.products,
    'faq_items', s.faq_items,
    'about_kicker', s.about_kicker,
    'about_title', s.about_title,
    'about_image_url', s.about_image_url,
    'about_image_caption', s.about_image_caption,
    'about_values', s.about_values,
    'gallery_section_kicker', s.gallery_section_kicker,
    'gallery_section_title', s.gallery_section_title,
    'show_storefront_rating', s.show_storefront_rating,
    'show_directions_link', s.show_directions_link,
    'references_link', s.references_link,
    'shelf_image_url', s.shelf_image_url,
    'logo_url', s.logo_url,
    'working_hours', s.working_hours,
    'is_published', s.is_published,
    'kategori', s.kategori,
    'latitude', s.latitude,
    'longitude', s.longitude,
    'google_business_link', s.google_business_link,
    'product_storage_version', s.product_storage_version,
    'featured_banner_label', s.featured_banner_label,
    'featured_banner_title', s.featured_banner_title,
    'featured_banner_description', s.featured_banner_description,
    'featured_banner_image_url', s.featured_banner_image_url,
    'featured_banner_price_text', s.featured_banner_price_text,
    'rating_score', s.rating_score,
    'review_count', s.review_count
  ) INTO v_result
  FROM public.stores s
  WHERE s.slug = pg_catalog.btrim(p_slug)
    AND s.edit_token = pg_catalog.btrim(p_edit_token)
    AND s.edit_token <> '';

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH' USING errcode = 'P0001';
  END IF;

  RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."get_store_preview"("p_slug" "text", "p_edit_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_today_vitrin_view_count"("p_slug" "text", "p_edit_token" "text") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_store_id uuid;
  v_viewed_date date;
  v_count integer;
begin
  select s.id
    into v_store_id
  from public.stores s
  where s.slug = pg_catalog.btrim(coalesce(p_slug, ''))
    and s.edit_token = p_edit_token
    and s.edit_token <> ''
  limit 1;

  if v_store_id is null then
    return 0;
  end if;

  v_viewed_date := (now() at time zone 'Europe/Istanbul')::date;

  select count(*)::integer
    into v_count
  from public.vitrin_views vv
  where vv.store_id = v_store_id
    and vv.viewed_date = v_viewed_date;

  return coalesce(v_count, 0);
end;
$$;


ALTER FUNCTION "public"."get_today_vitrin_view_count"("p_slug" "text", "p_edit_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
  insert into public.profiles (id, email, created_at, last_sign_in_at)
  values (new.id, new.email, new.created_at, new.last_sign_in_at)
  on conflict (id) do update
    set email = excluded.email,
        created_at = excluded.created_at,
        last_sign_in_at = excluded.last_sign_in_at;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_updated_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
begin
  update public.profiles
  set email = new.email,
      last_sign_in_at = new.last_sign_in_at
  where id = new.id;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_updated_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."link_store_to_user"("p_edit_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_user_id uuid;
begin
  -- Retrieve the authenticated user's ID
  v_user_id := auth.uid();
  
  if v_user_id is null then
    raise exception 'UNAUTHORIZED';
  end if;

  -- Link store that matches p_edit_token and doesn't have an owner yet
  update public.stores
  set user_id = v_user_id
  where edit_token = p_edit_token
    and user_id is null;

  return found;
end;
$$;


ALTER FUNCTION "public"."link_store_to_user"("p_edit_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_audit_event"("p_user_id" "uuid", "p_session_id" "text", "p_action" "text", "p_target_type" "text", "p_target_id" "text" DEFAULT NULL::"text", "p_old_value" "jsonb" DEFAULT NULL::"jsonb", "p_new_value" "jsonb" DEFAULT NULL::"jsonb", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO audit_logs (
    user_id, session_id, action, target_type, target_id,
    old_value, new_value, metadata
  ) VALUES (
    p_user_id, p_session_id, p_action, p_target_type, p_target_id,
    p_old_value, p_new_value, p_metadata
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;


ALTER FUNCTION "public"."log_audit_event"("p_user_id" "uuid", "p_session_id" "text", "p_action" "text", "p_target_type" "text", "p_target_id" "text", "p_old_value" "jsonb", "p_new_value" "jsonb", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_demo_store_mutation"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF OLD.is_demo THEN
    RAISE EXCEPTION 'DEMO_STORE_IMMUTABLE' USING ERRCODE = 'P0001';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."prevent_demo_store_mutation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."record_vitrin_view"("p_store_slug" "text", "p_session_key" "text", "p_source" "text" DEFAULT 'unknown'::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_store_id uuid;
  v_store_slug text;
  v_session_key text;
  v_source text;
  v_viewed_date date;
begin
  v_session_key := pg_catalog.btrim(coalesce(p_session_key, ''));

  if length(v_session_key) < 16 then
    return;
  end if;

  select s.id, s.slug
    into v_store_id, v_store_slug
  from public.stores s
  where s.slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and s.is_published = true
  limit 1;

  if v_store_id is null then
    return;
  end if;

  v_source := lower(pg_catalog.btrim(coalesce(p_source, 'unknown')));

  if v_source not in ('direct', 'qr', 'share', 'unknown') then
    v_source := 'unknown';
  end if;

  v_viewed_date := (now() at time zone 'Europe/Istanbul')::date;

  insert into public.vitrin_views (
    store_id,
    store_slug,
    session_key,
    source,
    viewed_date
  ) values (
    v_store_id,
    v_store_slug,
    v_session_key,
    v_source,
    v_viewed_date
  )
  on conflict (store_id, session_key, viewed_date) do nothing;
end;
$$;


ALTER FUNCTION "public"."record_vitrin_view"("p_store_slug" "text", "p_session_key" "text", "p_source" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reorder_store_products"("p_store_id" "uuid", "p_edit_token" "text", "p_product_ids" "uuid"[]) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE v_index INT; v_product_id UUID; v_found_count INT;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;
  IF p_product_ids IS NULL OR array_length(p_product_ids, 1) IS NULL OR array_length(p_product_ids, 1) = 0 THEN
    RETURN jsonb_build_object('success', true, 'reordered', 0);
  END IF;
  IF array_length(p_product_ids, 1) != (SELECT count(DISTINCT unnest) FROM unnest(p_product_ids)) THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_ORDER: Ürün listesinde tekrarlanan ID var';
  END IF;
  SELECT count(*) INTO v_found_count FROM public.products
  WHERE id = ANY(p_product_ids) AND store_id = p_store_id AND is_active = true;
  IF v_found_count != array_length(p_product_ids, 1) THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_ORDER: Liste içinde bulunmayan veya başka mağazaya ait ürün var';
  END IF;
  FOR v_index IN 1..array_length(p_product_ids, 1) LOOP
    v_product_id := p_product_ids[v_index];
    UPDATE public.products SET sort_order = v_index - 1 WHERE id = v_product_id AND store_id = p_store_id AND is_active = true;
  END LOOP;
  RETURN jsonb_build_object('success', true, 'reordered', array_length(p_product_ids, 1));
END;
$$;


ALTER FUNCTION "public"."reorder_store_products"("p_store_id" "uuid", "p_edit_token" "text", "p_product_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."save_store_draft_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_existing_id uuid;
  v_existing_published boolean;
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  SELECT id, is_published INTO v_existing_id, v_existing_published
  FROM public.stores
  WHERE slug = pg_catalog.btrim(p_slug);

  IF v_existing_id IS NOT NULL THEN
    IF v_existing_published THEN
      RAISE EXCEPTION 'STORE_ALREADY_PUBLISHED';
    END IF;

    UPDATE public.stores
    SET
      edit_token = pg_catalog.btrim(p_edit_token),
      name = coalesce(p_store->>'name', name),
      business_type = coalesce(p_store->>'business_type', business_type),
      description = coalesce(p_store->>'description', description),
      corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
      whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
      instagram = coalesce(p_store->>'instagram', instagram),
      website = coalesce(p_store->>'website', website),
      address = coalesce(p_store->>'address', address),
      theme = coalesce(p_store->>'theme', theme),
      marketplace_links = coalesce(p_store->'marketplace_links', marketplace_links),
      gallery_items = coalesce(p_store->'gallery_items', gallery_items),
      offerings = coalesce(p_store->'offerings', offerings),
      shelf_image_url = coalesce(nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
      logo_url = coalesce(nullif(p_store->>'logo_url', ''), logo_url),
      working_hours = coalesce(p_store->>'working_hours', working_hours),
      kategori = coalesce(p_store->>'kategori', kategori),
      google_business_link = coalesce(p_store->>'google_business_link', google_business_link),
      is_published = false,
      status = 'draft',
      updated_at = pg_catalog.now()
    WHERE id = v_existing_id
      AND edit_token = pg_catalog.btrim(p_edit_token)
      AND edit_token <> ''
      AND is_published = false;

    IF NOT FOUND THEN
      -- Token uyuşmadı ya da SELECT'ten sonra eşzamanlı olarak yayınlandı.
      RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH_OR_PUBLISHED' USING errcode = 'P0001';
    END IF;
  ELSE
    INSERT INTO public.stores (
      slug, edit_token, user_id, name, business_type, description, corporate_bio,
      whatsapp, instagram, website, address, theme, status,
      marketplace_links, gallery_items, offerings,
      shelf_image_url, logo_url, working_hours, is_published, kategori,
      google_business_link, updated_at
    ) VALUES (
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
      'draft',
      coalesce(p_store->'marketplace_links', '[]'::jsonb),
      coalesce(p_store->'gallery_items', '[]'::jsonb),
      coalesce(p_store->'offerings', '[]'::jsonb),
      coalesce(p_store->>'shelf_image_url', ''),
      coalesce(p_store->>'logo_url', ''),
      coalesce(p_store->>'working_hours', ''),
      false,
      coalesce(p_store->>'kategori', ''),
      coalesce(p_store->>'google_business_link', ''),
      pg_catalog.now()
    );
  END IF;
END;
$$;


ALTER FUNCTION "public"."save_store_draft_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_published_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$ BEGIN IF NEW.status = 'published' AND (OLD.status IS DISTINCT FROM 'published') THEN NEW.published_at = COALESCE(NEW.published_at, now()); END IF; RETURN NEW; END; $$;


ALTER FUNCTION "public"."set_published_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_published_at_on_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$ BEGIN IF NEW.status = 'published' AND NEW.published_at IS NULL THEN NEW.published_at = now(); END IF; RETURN NEW; END; $$;


ALTER FUNCTION "public"."set_published_at_on_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_store_instagram_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_store_instagram_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_store_product"("p_product_id" "uuid", "p_edit_token" "text" DEFAULT NULL::"text", "p_name" "text" DEFAULT NULL::"text", "p_slug" "text" DEFAULT NULL::"text", "p_description" "text" DEFAULT NULL::"text", "p_price_text" "text" DEFAULT NULL::"text", "p_price_amount" numeric DEFAULT NULL::numeric, "p_image_urls" "jsonb" DEFAULT NULL::"jsonb", "p_category_id" "uuid" DEFAULT NULL::"uuid", "p_is_visible" boolean DEFAULT NULL::boolean, "p_sort_order" integer DEFAULT NULL::integer, "p_stock_quantity" integer DEFAULT NULL::integer, "p_stock_status" "text" DEFAULT NULL::"text", "p_clear_category" boolean DEFAULT false, "p_clear_price_amount" boolean DEFAULT false, "p_clear_stock_quantity" boolean DEFAULT false, "p_clear_stock_status" boolean DEFAULT false, "p_old_price_amount" numeric DEFAULT NULL::numeric, "p_badge_tag" "text" DEFAULT NULL::"text", "p_fulfillment_region" "text" DEFAULT NULL::"text", "p_clear_old_price_amount" boolean DEFAULT false, "p_clear_badge_tag" boolean DEFAULT false, "p_clear_fulfillment_region" boolean DEFAULT false) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE
  v_store_id UUID;
BEGIN
  SELECT store_id INTO v_store_id
  FROM public.products WHERE id = p_product_id;

  IF v_store_id IS NULL THEN
    RAISE EXCEPTION 'PRODUCT_NOT_FOUND';
  END IF;

  IF NOT public._check_store_authorization(v_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  IF p_slug IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.products
      WHERE store_id = v_store_id AND slug = trim(p_slug) AND id != p_product_id
    ) THEN
      RAISE EXCEPTION 'SLUG_ALREADY_EXISTS';
    END IF;
  END IF;

  IF p_category_id IS NOT NULL AND NOT p_clear_category THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.product_categories pc
      WHERE pc.id = p_category_id AND pc.store_id = v_store_id
    ) THEN
      RAISE EXCEPTION 'CATEGORY_NOT_IN_SAME_STORE';
    END IF;
  END IF;

  UPDATE public.products SET
    name = COALESCE(p_name, name),
    slug = COALESCE(trim(p_slug), slug),
    description = COALESCE(p_description, description),
    price_text = COALESCE(p_price_text, price_text),
    price_amount = CASE
      WHEN p_clear_price_amount THEN NULL
      WHEN p_price_amount IS NOT NULL THEN p_price_amount
      ELSE price_amount
    END,
    image_urls = COALESCE(p_image_urls, image_urls),
    category_id = CASE
      WHEN p_clear_category THEN NULL
      WHEN p_category_id IS NOT NULL THEN p_category_id
      ELSE category_id
    END,
    is_visible = COALESCE(p_is_visible, is_visible),
    sort_order = COALESCE(p_sort_order, sort_order),
    stock_quantity = CASE
      WHEN p_clear_stock_quantity THEN NULL
      WHEN p_stock_quantity IS NOT NULL THEN p_stock_quantity
      ELSE stock_quantity
    END,
    stock_status = CASE
      WHEN p_clear_stock_status THEN NULL
      WHEN p_stock_status IS NOT NULL THEN p_stock_status
      ELSE stock_status
    END,
    old_price_amount = CASE
      WHEN p_clear_old_price_amount THEN NULL
      WHEN p_old_price_amount IS NOT NULL THEN p_old_price_amount
      ELSE old_price_amount
    END,
    badge_tag = CASE
      WHEN p_clear_badge_tag THEN NULL
      WHEN p_badge_tag IS NOT NULL THEN NULLIF(trim(p_badge_tag), '')
      ELSE badge_tag
    END,
    fulfillment_region = CASE
      WHEN p_clear_fulfillment_region THEN NULL
      WHEN p_fulfillment_region IS NOT NULL THEN NULLIF(trim(p_fulfillment_region), '')
      ELSE fulfillment_region
    END
  WHERE id = p_product_id;

  RETURN jsonb_build_object('id', p_product_id, 'success', true);
END;
$$;


ALTER FUNCTION "public"."update_store_product"("p_product_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_is_visible" boolean, "p_sort_order" integer, "p_stock_quantity" integer, "p_stock_status" "text", "p_clear_category" boolean, "p_clear_price_amount" boolean, "p_clear_stock_quantity" boolean, "p_clear_stock_status" boolean, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text", "p_clear_old_price_amount" boolean, "p_clear_badge_tag" boolean, "p_clear_fulfillment_region" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."update_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_products_from_xml"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE
  v_inserted INT := 0;
  v_updated INT := 0;
  v_skipped INT := 0;
  v_errors JSONB := '[]'::jsonb;
  v_product JSONB;
  v_name TEXT;
  v_slug TEXT;
  v_external_id TEXT;
  v_category_name TEXT;
  v_category_id UUID;
  v_image_urls JSONB;
  v_existing_id UUID;
  v_new_product_id UUID;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;
  FOR v_product IN SELECT * FROM jsonb_array_elements(p_products)
  LOOP
    BEGIN
      v_name := trim(v_product->>'name');
      IF v_name IS NULL OR length(v_name) = 0 THEN
        v_skipped := v_skipped + 1;
        CONTINUE;
      END IF;
      v_external_id := v_product->>'external_product_id';
      v_existing_id := NULL;
      IF v_external_id IS NOT NULL AND length(v_external_id) > 0 THEN
        SELECT id INTO v_existing_id
        FROM public.products
        WHERE store_id = p_store_id
          AND source_type = 'xml'
          AND external_product_id = v_external_id
        LIMIT 1;
      END IF;
      v_slug := lower(regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'));
      v_slug := regexp_replace(v_slug, '\s+', '-', 'g');
      v_slug := trim(v_slug, '-');
      v_category_name := v_product->>'category_name';
      v_category_id := NULL;
      IF v_category_name IS NOT NULL AND length(v_category_name) > 0 THEN
        SELECT id INTO v_category_id
        FROM public.product_categories
        WHERE store_id = p_store_id
          AND lower(name) = lower(v_category_name)
        LIMIT 1;
        IF v_category_id IS NULL THEN
          INSERT INTO public.product_categories (store_id, name, slug)
          VALUES (p_store_id, v_category_name, lower(regexp_replace(v_category_name, '[^a-zA-Z0-9\s-]', '', 'g')))
          RETURNING id INTO v_category_id;
        END IF;
      END IF;
      v_image_urls := COALESCE(v_product->'image_urls', '[]'::jsonb);
      IF jsonb_typeof(v_image_urls) != 'array' THEN
        v_image_urls := '[]'::jsonb;
      END IF;
      IF v_existing_id IS NOT NULL THEN
        UPDATE public.products SET
          name = v_name,
          description = COALESCE(v_product->>'description', description),
          price_text = COALESCE(v_product->>'price_text', price_text),
          price_amount = COALESCE((v_product->>'price_amount')::NUMERIC, price_amount),
          image_urls = CASE
            WHEN jsonb_array_length(v_image_urls) > 0 THEN v_image_urls
            ELSE image_urls
          END,
          category_id = COALESCE(v_category_id, category_id),
          stock_quantity = CASE
            WHEN v_product ? 'stock_quantity' THEN (v_product->>'stock_quantity')::INT
            ELSE stock_quantity
          END,
          stock_status = COALESCE(v_product->>'stock_status', stock_status),
          last_synced_at = now()
        WHERE id = v_existing_id;
        v_updated := v_updated + 1;
      ELSE
        IF EXISTS (
          SELECT 1 FROM public.products
          WHERE store_id = p_store_id AND slug = v_slug
        ) THEN
          v_slug := v_slug || '-' || substr(md5(random()::text), 1, 6);
        END IF;
        INSERT INTO public.products (
          store_id, name, slug, description,
          price_text, price_amount, image_urls,
          category_id, source_type, external_product_id,
          stock_quantity, stock_status,
          is_visible, is_active, sort_order, last_synced_at
        ) VALUES (
          p_store_id,
          v_name,
          v_slug,
          COALESCE(v_product->>'description', ''),
          COALESCE(v_product->>'price_text', ''),
          (v_product->>'price_amount')::NUMERIC,
          v_image_urls,
          v_category_id,
          'xml',
          v_external_id,
          (v_product->>'stock_quantity')::INT,
          COALESCE(v_product->>'stock_status', 'Mevcut'),
          true,
          true,
          0,
          now()
        ) RETURNING id INTO v_new_product_id;
        v_inserted := v_inserted + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_errors := v_errors || jsonb_build_object(
        'name', v_product->>'name',
        'external_id', v_external_id,
        'error', SQLERRM
      );
      v_skipped := v_skipped + 1;
    END;
  END LOOP;
  UPDATE public.products
  SET sort_order = sub.row_num
  FROM (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) - 1 AS row_num
    FROM public.products
    WHERE store_id = p_store_id AND source_type = 'xml'
  ) sub
  WHERE products.id = sub.id;
  RETURN jsonb_build_object(
    'inserted', v_inserted,
    'updated', v_updated,
    'skipped', v_skipped,
    'errors', v_errors
  );
END;
$$;


ALTER FUNCTION "public"."upsert_products_from_xml"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_store_category"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text" DEFAULT NULL::"text", "p_sort_order" integer DEFAULT 0) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'auth'
    AS $$
DECLARE
  v_slug TEXT;
  v_id UUID;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  IF p_name IS NULL OR pg_catalog.length(pg_catalog.btrim(p_name)) = 0 THEN
    RAISE EXCEPTION 'CATEGORY_NAME_REQUIRED';
  END IF;

  v_slug := NULLIF(pg_catalog.btrim(COALESCE(p_slug, '')), '');
  IF v_slug IS NULL THEN
    v_slug := lower(replace(replace(replace(pg_catalog.btrim(p_name), ' ', '-'), '.', ''), ',', ''));
  END IF;
  IF v_slug IS NULL OR v_slug = '' THEN
    v_slug := 'kategori';
  END IF;

  INSERT INTO public.product_categories (store_id, name, slug, sort_order, is_active)
  VALUES (
    p_store_id,
    pg_catalog.btrim(p_name),
    v_slug,
    COALESCE(p_sort_order, 0),
    true
  )
  ON CONFLICT (store_id, slug) DO UPDATE
    SET name = EXCLUDED.name,
        sort_order = EXCLUDED.sort_order,
        is_active = true,
        updated_at = now()
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('id', v_id, 'slug', v_slug, 'success', true);
END;
$$;


ALTER FUNCTION "public"."upsert_store_category"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_sort_order" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_product_category"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF NEW.category_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.product_categories pc
      WHERE pc.id = NEW.category_id AND pc.store_id = NEW.store_id
    ) THEN
      RAISE EXCEPTION 'CATEGORY_NOT_IN_SAME_STORE';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_product_category"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."withdraw_store_publication_consent"("p_slug" "text", "p_edit_token" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."withdraw_store_publication_consent"("p_slug" "text", "p_edit_token" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."admins" (
    "user_id" "uuid" NOT NULL
);


ALTER TABLE "public"."admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_slug" "text" NOT NULL,
    "customer_name" "text" NOT NULL,
    "customer_phone" "text" NOT NULL,
    "customer_notes" "text",
    "service_title" "text",
    "service_price" "text",
    "service_duration" integer DEFAULT 30,
    "appointment_time" timestamp with time zone NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "token" "text" DEFAULT ("gen_random_uuid"())::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "appointments_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text", 'cancelled'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."appointments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."assistant_rate_limits" (
    "client_key" "text" NOT NULL,
    "window_started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "request_count" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "assistant_rate_limits_request_count_check" CHECK (("request_count" >= 0))
);


ALTER TABLE "public"."assistant_rate_limits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "session_id" "text",
    "action" "text" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text",
    "old_value" "jsonb",
    "new_value" "jsonb",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."booking_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_slug" "text" NOT NULL,
    "is_enabled" boolean DEFAULT false,
    "capacity" integer DEFAULT 1,
    "working_hours" "jsonb" DEFAULT '{}'::"jsonb",
    "lunch_break" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."booking_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."category_image_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category_key" "text" NOT NULL,
    "category_label" "text" NOT NULL,
    "image_type" "text" NOT NULL,
    "image_url" "text" NOT NULL,
    "thumbnail_url" "text",
    "title" "text",
    "description" "text",
    "display_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "category_image_templates_image_type_check" CHECK (("image_type" = ANY (ARRAY['cover'::"text", 'logo_placeholder'::"text", 'gallery'::"text", 'product'::"text"])))
);


ALTER TABLE "public"."category_image_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_flags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "flag_key" "text" NOT NULL,
    "is_enabled" boolean DEFAULT false NOT NULL,
    "target_users" "text" DEFAULT 'all'::"text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "feature_flags_target_users_check" CHECK (("target_users" = ANY (ARRAY['all'::"text", 'premium'::"text", 'free'::"text"])))
);


ALTER TABLE "public"."feature_flags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."legal_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "document_type" "text" NOT NULL,
    "version" "text" NOT NULL,
    "title" "text" NOT NULL,
    "subtitle" "text" DEFAULT ''::"text" NOT NULL,
    "sections" "jsonb" NOT NULL,
    "content_hash" "text" DEFAULT ''::"text" NOT NULL,
    "is_active" boolean DEFAULT false NOT NULL,
    "effective_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "legal_documents_document_type_check" CHECK (("document_type" = ANY (ARRAY['privacy'::"text", 'terms'::"text", 'consent'::"text", 'dataDeletion'::"text"]))),
    CONSTRAINT "legal_documents_sections_check" CHECK (("jsonb_typeof"("sections") = 'array'::"text"))
);


ALTER TABLE "public"."legal_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."platform_settings" (
    "key" "text" NOT NULL,
    "value" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."platform_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "product_categories_name_check" CHECK (("length"("btrim"("name")) > 0))
);


ALTER TABLE "public"."product_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "category_id" "uuid",
    "source_type" "text" DEFAULT 'manual'::"text" NOT NULL,
    "external_product_id" "text",
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "description" "text",
    "price_amount" numeric,
    "price_text" "text",
    "currency" "text" DEFAULT 'TRY'::"text" NOT NULL,
    "stock_quantity" integer,
    "stock_status" "text",
    "image_urls" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "seo_title" "text",
    "seo_description" "text",
    "is_visible" boolean DEFAULT true NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_synced_at" timestamp with time zone,
    "brand" "text",
    "barcode" "text",
    "vat_rate" integer,
    "variants" "jsonb" DEFAULT '[]'::"jsonb",
    "old_price_amount" numeric,
    "badge_tag" "text",
    "fulfillment_region" "text",
    CONSTRAINT "products_image_urls_check" CHECK (("jsonb_typeof"("image_urls") = 'array'::"text")),
    CONSTRAINT "products_metadata_check" CHECK (("jsonb_typeof"("metadata") = 'object'::"text")),
    CONSTRAINT "products_name_check" CHECK (("length"("btrim"("name")) > 0)),
    CONSTRAINT "products_price_amount_check" CHECK ((("price_amount" IS NULL) OR ("price_amount" >= (0)::numeric))),
    CONSTRAINT "products_slug_check" CHECK (("length"("btrim"("slug")) > 0)),
    CONSTRAINT "products_stock_quantity_check" CHECK ((("stock_quantity" IS NULL) OR ("stock_quantity" >= 0))),
    CONSTRAINT "products_vat_rate_check" CHECK ((("vat_rate" IS NULL) OR (("vat_rate" >= 0) AND ("vat_rate" <= 100))))
);


ALTER TABLE "public"."products" OWNER TO "postgres";


COMMENT ON COLUMN "public"."products"."old_price_amount" IS 'Ürünün çizili eski fiyatı';



COMMENT ON COLUMN "public"."products"."badge_tag" IS 'Ürün rozeti (-31%, Yeni, Özel Tasarım vb.)';



COMMENT ON COLUMN "public"."products"."fulfillment_region" IS 'Ürünün teslim / hizmet bölgesi kısa metni (isteğe bağlı).';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "last_sign_in_at" timestamp with time zone
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."store_articles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_slug" "text" NOT NULL,
    "title" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "summary" "text",
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "cover_image_url" "text",
    "article_type" "text" DEFAULT 'standard'::"text",
    "target_topic" "text",
    "target_city" "text",
    "seo_score" integer DEFAULT 0,
    "seo_errors" "text"[] DEFAULT ARRAY[]::"text"[],
    "status" "text" DEFAULT 'draft'::"text",
    "is_blog_trusted" boolean DEFAULT false,
    "published_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "store_articles_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'review'::"text", 'published'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."store_articles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."store_category_image_usage" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid",
    "category_key" "text" NOT NULL,
    "images_used" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "applied_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."store_category_image_usage" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."store_instagram_connections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_slug" "text" NOT NULL,
    "user_id" "uuid",
    "instagram_user_id" "text",
    "username" "text",
    "account_type" "text",
    "scopes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "state_nonce" "text",
    "edit_token_hash" "text",
    "connected_at" timestamp with time zone,
    "last_sync_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_instagram_connections_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'connected'::"text", 'disconnected'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."store_instagram_connections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."store_instagram_imports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_slug" "text" NOT NULL,
    "connection_id" "uuid",
    "source_media_id" "text" NOT NULL,
    "source_permalink" "text",
    "product_slug" "text" NOT NULL,
    "status" "text" DEFAULT 'imported'::"text" NOT NULL,
    "error_message" "text",
    "imported_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_instagram_imports_status_check" CHECK (("status" = ANY (ARRAY['imported'::"text", 'updated'::"text", 'failed'::"text", 'retained'::"text"])))
);


ALTER TABLE "public"."store_instagram_imports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."store_instagram_tokens" (
    "connection_id" "uuid" NOT NULL,
    "access_token_ciphertext" "text" NOT NULL,
    "token_type" "text" DEFAULT 'bearer'::"text" NOT NULL,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."store_instagram_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "business_type" "text" DEFAULT ''::"text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "whatsapp" "text" DEFAULT ''::"text" NOT NULL,
    "instagram" "text" DEFAULT ''::"text" NOT NULL,
    "website" "text" DEFAULT ''::"text" NOT NULL,
    "address" "text" DEFAULT ''::"text" NOT NULL,
    "theme" "text" DEFAULT 'Sade'::"text" NOT NULL,
    "status" "text" DEFAULT 'Açık'::"text" NOT NULL,
    "marketplace_links" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "catalog_link" "text" DEFAULT ''::"text" NOT NULL,
    "references_link" "text" DEFAULT ''::"text" NOT NULL,
    "vcard_link" "text" DEFAULT ''::"text" NOT NULL,
    "is_published" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "shelf_image_url" "text" DEFAULT ''::"text" NOT NULL,
    "edit_token" "text" DEFAULT ''::"text" NOT NULL,
    "corporate_bio" "text" DEFAULT ''::"text" NOT NULL,
    "gallery_items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "is_store" boolean DEFAULT false,
    "kategori" "text" DEFAULT ''::"text",
    "latitude" double precision,
    "longitude" double precision,
    "location_accuracy_meters" double precision,
    "location_consent_at" timestamp with time zone,
    "location_source" "text",
    "user_id" "uuid",
    "working_hours" "text",
    "products" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "logo_url" "text",
    "offerings" "jsonb" DEFAULT '[]'::"jsonb",
    "google_business_link" "text",
    "province_code" "text",
    "province_name" "text",
    "district_code" "text",
    "district_name" "text",
    "booking_is_enabled" boolean DEFAULT false,
    "privacy_notice_acknowledged" boolean DEFAULT false,
    "terms_accepted" boolean DEFAULT false,
    "explicit_consent_given" boolean DEFAULT false,
    "consent_accepted_at" timestamp with time zone,
    "publish_version" integer DEFAULT 1,
    "publish_hash" "text" DEFAULT ''::"text",
    "privacy_notice_hash" "text" DEFAULT ''::"text",
    "privacy_notice_version" "text" DEFAULT ''::"text",
    "privacy_notice_acknowledged_at" timestamp with time zone,
    "terms_hash" "text" DEFAULT ''::"text",
    "terms_version" "text" DEFAULT ''::"text",
    "terms_accepted_at" timestamp with time zone,
    "publication_consent_hash" "text" DEFAULT ''::"text",
    "publication_consent_version" "text" DEFAULT ''::"text",
    "publication_consent_accepted_at" timestamp with time zone,
    "product_categories" "jsonb" DEFAULT '[]'::"jsonb",
    "publication_consent_accepted" boolean DEFAULT false NOT NULL,
    "publication_consent_withdrawn_at" timestamp with time zone,
    "product_storage_version" smallint DEFAULT 2 NOT NULL,
    "theme_preset" "text" DEFAULT 'default'::"text",
    "email" "text",
    "rating_score" numeric DEFAULT 4.9,
    "review_count" integer DEFAULT 128,
    "featured_banner_title" "text",
    "featured_banner_description" "text",
    "featured_banner_image_url" "text",
    "featured_banner_price_text" "text",
    "is_demo" boolean DEFAULT false NOT NULL,
    "phone" "text",
    "hero_badge" "text",
    "featured_banner_label" "text",
    "faq_items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "about_kicker" "text",
    "about_title" "text",
    "about_image_url" "text",
    "about_image_caption" "text",
    "about_values" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "gallery_section_kicker" "text",
    "gallery_section_title" "text",
    "show_storefront_rating" boolean DEFAULT false NOT NULL,
    "show_directions_link" boolean DEFAULT true NOT NULL,
    CONSTRAINT "stores_gallery_items_array_max_12" CHECK (
CASE
    WHEN ("jsonb_typeof"("gallery_items") = 'array'::"text") THEN ("jsonb_array_length"("gallery_items") <= 12)
    ELSE false
END),
    CONSTRAINT "stores_slug_format_check" CHECK (("slug" ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::"text"))
);


ALTER TABLE "public"."stores" OWNER TO "postgres";


COMMENT ON COLUMN "public"."stores"."latitude" IS 'Store location latitude coordinate.';



COMMENT ON COLUMN "public"."stores"."longitude" IS 'Store location longitude coordinate.';



COMMENT ON COLUMN "public"."stores"."location_accuracy_meters" IS 'Accuracy radius of the retrieved location in meters.';



COMMENT ON COLUMN "public"."stores"."location_consent_at" IS 'Timestamp when the user provided KVKK consent to share their location.';



COMMENT ON COLUMN "public"."stores"."location_source" IS 'Source platform/device from which location was retrieved (e.g., ''geolocator'').';



COMMENT ON COLUMN "public"."stores"."working_hours" IS 'Working hours text for stores.';



COMMENT ON COLUMN "public"."stores"."products" IS 'Product catalog list for stores.';



COMMENT ON COLUMN "public"."stores"."privacy_notice_acknowledged" IS 'Kullanıcı Aydınlatma Metni okudu onayı';



COMMENT ON COLUMN "public"."stores"."terms_accepted" IS 'Kullanıcı Kullanım Şartları kabul onayı';



COMMENT ON COLUMN "public"."stores"."explicit_consent_given" IS 'Kullanıcı açık rıza beyanı verdi onayı';



COMMENT ON COLUMN "public"."stores"."consent_accepted_at" IS 'Yasal onayların tamamının kabul edildiği zaman';



COMMENT ON COLUMN "public"."stores"."privacy_notice_hash" IS 'Aydinlatma Metni hash';



COMMENT ON COLUMN "public"."stores"."privacy_notice_version" IS 'Aydinlatma Metni versiyonu';



COMMENT ON COLUMN "public"."stores"."privacy_notice_acknowledged_at" IS 'Aydinlatma Metni onay zamani';



COMMENT ON COLUMN "public"."stores"."terms_hash" IS 'Kullanim Sartlari hash';



COMMENT ON COLUMN "public"."stores"."terms_version" IS 'Kullanim Sartlari versiyonu';



COMMENT ON COLUMN "public"."stores"."terms_accepted_at" IS 'Kullanim Sartlari onay zamani';



COMMENT ON COLUMN "public"."stores"."publication_consent_hash" IS 'Acik Riza hash';



COMMENT ON COLUMN "public"."stores"."publication_consent_version" IS 'Acik Riza versiyonu';



COMMENT ON COLUMN "public"."stores"."publication_consent_accepted_at" IS 'Acik Riza onay zamani';



COMMENT ON COLUMN "public"."stores"."theme_preset" IS 'Vitrin tema stili (default, atmosfer vb.)';



COMMENT ON COLUMN "public"."stores"."email" IS 'İşletme iletişim e-postası.';



COMMENT ON COLUMN "public"."stores"."is_demo" IS 'true ise bu mağaza Kiralık Vitrin örneğidir. Keşfet ekranında KİRALIK etiketi gösterilir.';



COMMENT ON COLUMN "public"."stores"."phone" IS 'İşletme telefonu (WhatsApp’tan ayrı, isteğe bağlı).';



COMMENT ON COLUMN "public"."stores"."hero_badge" IS 'Kapak üstü kısa etiket (örn. Atölye / Mağaza).';



COMMENT ON COLUMN "public"."stores"."featured_banner_label" IS 'Öne çıkan kampanya bandı etiketi (örn. Yeni Sezon).';



COMMENT ON COLUMN "public"."stores"."faq_items" IS 'Vitrin SSS listesi: [{id, question, answer}, ...]';



COMMENT ON COLUMN "public"."stores"."about_kicker" IS 'Hakkımızda üst etiketi (örn. Atmosfer’in hikâyesi).';



COMMENT ON COLUMN "public"."stores"."about_title" IS 'Hakkımızda ana başlık.';



COMMENT ON COLUMN "public"."stores"."about_image_url" IS 'Hakkımızda bölüm görseli.';



COMMENT ON COLUMN "public"."stores"."about_image_caption" IS 'Hakkımızda görsel alt yazısı.';



COMMENT ON COLUMN "public"."stores"."about_values" IS 'Hakkımızda değer kartları: [{id, title, description}, ...] en fazla 3.';



COMMENT ON COLUMN "public"."stores"."gallery_section_kicker" IS 'Galeri bölüm üst etiketi.';



COMMENT ON COLUMN "public"."stores"."gallery_section_title" IS 'Galeri bölüm başlığı.';



COMMENT ON COLUMN "public"."stores"."show_storefront_rating" IS 'Vitrinde puan bandı gösterilsin mi (varsayılan kapalı).';



COMMENT ON COLUMN "public"."stores"."show_directions_link" IS 'Vitrinde yol tarifi butonu gösterilsin mi (varsayılan açık).';



CREATE TABLE IF NOT EXISTS "public"."vitrin_views" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "store_slug" "text" NOT NULL,
    "session_key" "text" NOT NULL,
    "source" "text" DEFAULT 'unknown'::"text" NOT NULL,
    "viewed_date" "date" DEFAULT (("now"() AT TIME ZONE 'Europe/Istanbul'::"text"))::"date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "vitrin_views_session_key_check" CHECK (("length"("btrim"("session_key")) >= 16)),
    CONSTRAINT "vitrin_views_source_check" CHECK (("source" = ANY (ARRAY['direct'::"text", 'qr'::"text", 'share'::"text", 'unknown'::"text"])))
);


ALTER TABLE "public"."vitrin_views" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."xml_feeds" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "feed_name" "text" NOT NULL,
    "feed_url" "text" NOT NULL,
    "feed_format" "text" DEFAULT 'generic'::"text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "last_synced_at" timestamp with time zone,
    "last_sync_status" "text" DEFAULT 'pending'::"text",
    "last_sync_message" "text",
    "total_products_synced" integer DEFAULT 0,
    "product_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "xml_feeds_feed_format_check" CHECK (("feed_format" = ANY (ARRAY['generic'::"text", 'trendyol'::"text", 'hepsiburada'::"text", 'n11'::"text", 'google_merchant'::"text"]))),
    CONSTRAINT "xml_feeds_feed_name_check" CHECK (("length"("btrim"("feed_name")) > 0)),
    CONSTRAINT "xml_feeds_feed_url_check" CHECK (("length"("btrim"("feed_url")) > 0)),
    CONSTRAINT "xml_feeds_last_sync_status_check" CHECK (("last_sync_status" = ANY (ARRAY['pending'::"text", 'success'::"text", 'error'::"text"])))
);


ALTER TABLE "public"."xml_feeds" OWNER TO "postgres";


COMMENT ON TABLE "public"."xml_feeds" IS 'Tedarikçi XML feed adresleri ve senkronizasyon durumları.';



ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."assistant_rate_limits"
    ADD CONSTRAINT "assistant_rate_limits_pkey" PRIMARY KEY ("client_key");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."booking_settings"
    ADD CONSTRAINT "booking_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."booking_settings"
    ADD CONSTRAINT "booking_settings_store_slug_key" UNIQUE ("store_slug");



ALTER TABLE ONLY "public"."category_image_templates"
    ADD CONSTRAINT "category_image_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feature_flags"
    ADD CONSTRAINT "feature_flags_flag_key_key" UNIQUE ("flag_key");



ALTER TABLE ONLY "public"."feature_flags"
    ADD CONSTRAINT "feature_flags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."legal_documents"
    ADD CONSTRAINT "legal_documents_document_type_version_key" UNIQUE ("document_type", "version");



ALTER TABLE ONLY "public"."legal_documents"
    ADD CONSTRAINT "legal_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."platform_settings"
    ADD CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."product_categories"
    ADD CONSTRAINT "product_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_categories"
    ADD CONSTRAINT "product_categories_store_id_slug_key" UNIQUE ("store_id", "slug");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_store_id_slug_key" UNIQUE ("store_id", "slug");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_articles"
    ADD CONSTRAINT "store_articles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_articles"
    ADD CONSTRAINT "store_articles_store_slug_slug_key" UNIQUE ("store_slug", "slug");



ALTER TABLE ONLY "public"."store_category_image_usage"
    ADD CONSTRAINT "store_category_image_usage_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_instagram_connections"
    ADD CONSTRAINT "store_instagram_connections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_instagram_imports"
    ADD CONSTRAINT "store_instagram_imports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_instagram_tokens"
    ADD CONSTRAINT "store_instagram_tokens_pkey" PRIMARY KEY ("connection_id");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."store_instagram_connections"
    ADD CONSTRAINT "unique_store_instagram_connection" UNIQUE ("store_slug");



ALTER TABLE ONLY "public"."store_instagram_imports"
    ADD CONSTRAINT "unique_store_instagram_import" UNIQUE ("store_slug", "source_media_id");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "unique_user_store" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."category_image_templates"
    ADD CONSTRAINT "uq_category_image_template_url" UNIQUE ("category_key", "image_type", "image_url");



ALTER TABLE ONLY "public"."vitrin_views"
    ADD CONSTRAINT "vitrin_views_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."xml_feeds"
    ADD CONSTRAINT "xml_feeds_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_audit_logs_action" ON "public"."audit_logs" USING "btree" ("action");



CREATE INDEX "idx_audit_logs_created_at" ON "public"."audit_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_audit_logs_target" ON "public"."audit_logs" USING "btree" ("target_type", "target_id");



CREATE INDEX "idx_audit_logs_user_id" ON "public"."audit_logs" USING "btree" ("user_id");



CREATE INDEX "idx_cat_templates_active" ON "public"."category_image_templates" USING "btree" ("is_active");



CREATE INDEX "idx_cat_templates_key" ON "public"."category_image_templates" USING "btree" ("category_key");



CREATE INDEX "idx_cat_templates_type" ON "public"."category_image_templates" USING "btree" ("image_type");



CREATE INDEX "idx_product_categories_sort" ON "public"."product_categories" USING "btree" ("store_id", "sort_order");



CREATE INDEX "idx_product_categories_store_id" ON "public"."product_categories" USING "btree" ("store_id");



CREATE INDEX "idx_products_barcode" ON "public"."products" USING "btree" ("barcode") WHERE ("barcode" IS NOT NULL);



CREATE INDEX "idx_products_brand" ON "public"."products" USING "btree" ("brand") WHERE ("brand" IS NOT NULL);



CREATE INDEX "idx_products_category_id" ON "public"."products" USING "btree" ("category_id");



CREATE UNIQUE INDEX "idx_products_external_unique" ON "public"."products" USING "btree" ("store_id", "source_type", "external_product_id") WHERE (("external_product_id" IS NOT NULL) AND ("external_product_id" <> ''::"text"));



CREATE INDEX "idx_products_sort" ON "public"."products" USING "btree" ("store_id", "sort_order");



CREATE INDEX "idx_products_source_type" ON "public"."products" USING "btree" ("source_type");



CREATE INDEX "idx_products_store_active" ON "public"."products" USING "btree" ("store_id", "is_active");



CREATE INDEX "idx_products_store_id" ON "public"."products" USING "btree" ("store_id");



CREATE INDEX "idx_products_store_visible" ON "public"."products" USING "btree" ("store_id", "is_visible");



CREATE INDEX "idx_profiles_email" ON "public"."profiles" USING "btree" ("email");



CREATE INDEX "idx_store_articles_published" ON "public"."store_articles" USING "btree" ("store_slug", "status", "published_at" DESC NULLS LAST);



CREATE INDEX "idx_store_cat_usage_store" ON "public"."store_category_image_usage" USING "btree" ("store_id");



CREATE UNIQUE INDEX "idx_store_cat_usage_store_unique" ON "public"."store_category_image_usage" USING "btree" ("store_id");



CREATE INDEX "idx_store_instagram_connections_state_nonce" ON "public"."store_instagram_connections" USING "btree" ("state_nonce") WHERE ("state_nonce" IS NOT NULL);



CREATE INDEX "idx_store_instagram_connections_store" ON "public"."store_instagram_connections" USING "btree" ("store_slug");



CREATE INDEX "idx_store_instagram_connections_user" ON "public"."store_instagram_connections" USING "btree" ("user_id");



CREATE INDEX "idx_store_instagram_imports_store" ON "public"."store_instagram_imports" USING "btree" ("store_slug", "imported_at" DESC);



CREATE INDEX "idx_stores_published_slug" ON "public"."stores" USING "btree" ("is_published", "slug") WHERE ("is_published" = true);



CREATE INDEX "idx_xml_feeds_store_id" ON "public"."xml_feeds" USING "btree" ("store_id");



CREATE UNIQUE INDEX "idx_xml_feeds_store_url" ON "public"."xml_feeds" USING "btree" ("store_id", "feed_url");



CREATE UNIQUE INDEX "legal_documents_one_active_per_type" ON "public"."legal_documents" USING "btree" ("document_type") WHERE "is_active";



CREATE INDEX "stores_is_published_idx" ON "public"."stores" USING "btree" ("is_published");



CREATE INDEX "stores_slug_idx" ON "public"."stores" USING "btree" ("slug");



CREATE INDEX "vitrin_views_store_day_idx" ON "public"."vitrin_views" USING "btree" ("store_id", "viewed_date" DESC);



CREATE UNIQUE INDEX "vitrin_views_store_session_day_key" ON "public"."vitrin_views" USING "btree" ("store_id", "session_key", "viewed_date");



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "extensions"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "protect_landing_demo_stores" BEFORE DELETE OR UPDATE ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_demo_store_mutation"();



CREATE OR REPLACE TRIGGER "stores_set_updated_at" BEFORE UPDATE ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_product_categories_updated_at" BEFORE UPDATE ON "public"."product_categories" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_products_updated_at" BEFORE UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_store_articles_published_at" BEFORE UPDATE ON "public"."store_articles" FOR EACH ROW EXECUTE FUNCTION "public"."set_published_at"();



CREATE OR REPLACE TRIGGER "trg_store_articles_published_at_insert" BEFORE INSERT ON "public"."store_articles" FOR EACH ROW EXECUTE FUNCTION "public"."set_published_at_on_insert"();



CREATE OR REPLACE TRIGGER "trg_store_articles_updated_at" BEFORE UPDATE ON "public"."store_articles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_store_instagram_connections_updated_at" BEFORE UPDATE ON "public"."store_instagram_connections" FOR EACH ROW EXECUTE FUNCTION "public"."set_store_instagram_updated_at"();



CREATE OR REPLACE TRIGGER "trg_store_instagram_imports_updated_at" BEFORE UPDATE ON "public"."store_instagram_imports" FOR EACH ROW EXECUTE FUNCTION "public"."set_store_instagram_updated_at"();



CREATE OR REPLACE TRIGGER "trg_store_instagram_tokens_updated_at" BEFORE UPDATE ON "public"."store_instagram_tokens" FOR EACH ROW EXECUTE FUNCTION "public"."set_store_instagram_updated_at"();



CREATE OR REPLACE TRIGGER "trg_validate_product_category" BEFORE INSERT OR UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."validate_product_category"();



CREATE OR REPLACE TRIGGER "trg_xml_feeds_updated_at" BEFORE UPDATE ON "public"."xml_feeds" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_store_slug_fkey" FOREIGN KEY ("store_slug") REFERENCES "public"."stores"("slug") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."booking_settings"
    ADD CONSTRAINT "booking_settings_store_slug_fkey" FOREIGN KEY ("store_slug") REFERENCES "public"."stores"("slug") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_categories"
    ADD CONSTRAINT "product_categories_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."product_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."store_articles"
    ADD CONSTRAINT "store_articles_store_slug_fkey" FOREIGN KEY ("store_slug") REFERENCES "public"."stores"("slug") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."store_category_image_usage"
    ADD CONSTRAINT "store_category_image_usage_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."store_instagram_connections"
    ADD CONSTRAINT "store_instagram_connections_store_slug_fkey" FOREIGN KEY ("store_slug") REFERENCES "public"."stores"("slug") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."store_instagram_connections"
    ADD CONSTRAINT "store_instagram_connections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."store_instagram_imports"
    ADD CONSTRAINT "store_instagram_imports_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "public"."store_instagram_connections"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."store_instagram_imports"
    ADD CONSTRAINT "store_instagram_imports_store_slug_fkey" FOREIGN KEY ("store_slug") REFERENCES "public"."stores"("slug") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."store_instagram_tokens"
    ADD CONSTRAINT "store_instagram_tokens_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "public"."store_instagram_connections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vitrin_views"
    ADD CONSTRAINT "vitrin_views_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."xml_feeds"
    ADD CONSTRAINT "xml_feeds_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;



CREATE POLICY "Active legal documents are publicly readable" ON "public"."legal_documents" FOR SELECT TO "authenticated", "anon" USING (("is_active" = true));



CREATE POLICY "Admins can modify feature flags" ON "public"."feature_flags" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"())))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can modify platform_settings" ON "public"."platform_settings" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"())))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can read" ON "public"."admins" FOR SELECT USING (true);



CREATE POLICY "Admins can read all appointments" ON "public"."appointments" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can read all audit logs" ON "public"."audit_logs" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can read all store_articles" ON "public"."store_articles" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can read all stores" ON "public"."stores" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can read platform_settings" ON "public"."platform_settings" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can read profiles" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can update appointments" ON "public"."appointments" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"())))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can update store_articles" ON "public"."store_articles" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"())))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can view own admin row" ON "public"."admins" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Allow insert admins" ON "public"."admins" FOR INSERT WITH CHECK (true);



CREATE POLICY "Allow public read stores" ON "public"."stores" FOR SELECT TO "authenticated", "anon" USING (("is_published" = true));



CREATE POLICY "Anyone can read published articles" ON "public"."store_articles" FOR SELECT TO "authenticated", "anon" USING (("status" = 'published'::"text"));



CREATE POLICY "Owners can delete their own articles" ON "public"."store_articles" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "store_articles"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can delete their stores" ON "public"."stores" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Owners can insert booking settings" ON "public"."booking_settings" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "booking_settings"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can insert their own articles" ON "public"."store_articles" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "store_articles"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can read all their own articles" ON "public"."store_articles" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "store_articles"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can read own Instagram connection" ON "public"."store_instagram_connections" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores"
  WHERE (("stores"."slug" = "store_instagram_connections"."store_slug") AND ("stores"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can read own Instagram imports" ON "public"."store_instagram_imports" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores"
  WHERE (("stores"."slug" = "store_instagram_imports"."store_slug") AND ("stores"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can update booking settings" ON "public"."booking_settings" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "booking_settings"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "booking_settings"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can update their own articles" ON "public"."store_articles" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "store_articles"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "store_articles"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Owners can update their store appointments" ON "public"."appointments" FOR UPDATE TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "appointments"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))) WITH CHECK (((( SELECT "auth"."uid"() AS "uid") IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "appointments"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "Owners can update their stores" ON "public"."stores" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Owners can view their store appointments" ON "public"."appointments" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."slug" = "appointments"."store_slug") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "Public can read booking_settings" ON "public"."booking_settings" FOR SELECT USING (true);



CREATE POLICY "Public can read feature flags" ON "public"."feature_flags" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Service role can manage audit logs" ON "public"."audit_logs" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Service role can manage profiles" ON "public"."profiles" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Store owners can read their stores" ON "public"."stores" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can read own audit logs" ON "public"."audit_logs" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."admins" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "anon_read_categories" ON "public"."product_categories" FOR SELECT TO "anon" USING ((("is_active" = true) AND (EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "product_categories"."store_id") AND ("s"."is_published" = true))))));



CREATE POLICY "anon_read_products" ON "public"."products" FOR SELECT TO "anon" USING ((("is_active" = true) AND ("is_visible" = true) AND (EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "products"."store_id") AND ("s"."is_published" = true))))));



ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."assistant_rate_limits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "auth_read_categories" ON "public"."product_categories" FOR SELECT TO "authenticated" USING ((("is_active" = true) AND (EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "product_categories"."store_id") AND ("s"."is_published" = true))))));



CREATE POLICY "auth_read_products" ON "public"."products" FOR SELECT TO "authenticated" USING ((("is_active" = true) AND ("is_visible" = true) AND (EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "products"."store_id") AND ("s"."is_published" = true))))));



ALTER TABLE "public"."booking_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."category_image_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "category_templates_admin_all" ON "public"."category_image_templates" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "category_templates_select_public" ON "public"."category_image_templates" FOR SELECT TO "authenticated", "anon" USING (("is_active" = true));



ALTER TABLE "public"."feature_flags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."legal_documents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owner_delete_categories" ON "public"."product_categories" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "product_categories"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_delete_products" ON "public"."products" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "products"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_insert_categories" ON "public"."product_categories" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "product_categories"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_insert_products" ON "public"."products" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "products"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_select_categories" ON "public"."product_categories" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "product_categories"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_select_products" ON "public"."products" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "products"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_update_categories" ON "public"."product_categories" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "product_categories"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "product_categories"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_update_products" ON "public"."products" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "products"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "products"."store_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "owner_xml_feeds" ON "public"."xml_feeds" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "xml_feeds"."store_id") AND (("s"."user_id" = "auth"."uid"()) OR ("s"."edit_token" IS NOT NULL)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores" "s"
  WHERE (("s"."id" = "xml_feeds"."store_id") AND (("s"."user_id" = "auth"."uid"()) OR ("s"."edit_token" IS NOT NULL))))));



ALTER TABLE "public"."platform_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."store_articles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "store_cat_usage_owner_insert" ON "public"."store_category_image_usage" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."stores"
  WHERE (("stores"."id" = "store_category_image_usage"."store_id") AND ("stores"."user_id" = "auth"."uid"())))));



CREATE POLICY "store_cat_usage_owner_select" ON "public"."store_category_image_usage" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."stores"
  WHERE (("stores"."id" = "store_category_image_usage"."store_id") AND ("stores"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."store_category_image_usage" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."store_instagram_connections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."store_instagram_imports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."store_instagram_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vitrin_views" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."xml_feeds" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."_check_store_authorization"("p_store_id" "uuid", "p_edit_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_check_store_authorization"("p_store_id" "uuid", "p_edit_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_check_store_authorization"("p_store_id" "uuid", "p_edit_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."apply_category_template"("p_store_id" "uuid", "p_category_key" "text", "p_fill_cover" boolean, "p_fill_logo" boolean, "p_fill_gallery" boolean, "p_fill_products" boolean, "p_edit_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."apply_category_template"("p_store_id" "uuid", "p_category_key" "text", "p_fill_cover" boolean, "p_fill_logo" boolean, "p_fill_gallery" boolean, "p_fill_products" boolean, "p_edit_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."apply_category_template"("p_store_id" "uuid", "p_category_key" "text", "p_fill_cover" boolean, "p_fill_logo" boolean, "p_fill_gallery" boolean, "p_fill_products" boolean, "p_edit_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_category_template"("p_store_id" "uuid", "p_category_key" "text", "p_fill_cover" boolean, "p_fill_logo" boolean, "p_fill_gallery" boolean, "p_fill_products" boolean, "p_edit_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."batch_create_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."batch_create_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."batch_create_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."bulk_insert_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."bulk_insert_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."bulk_insert_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."bulk_insert_products"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."consume_assistant_request"("p_client_key" "text", "p_max_requests" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."consume_assistant_request"("p_client_key" "text", "p_max_requests" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_store_product"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_source_type" "text", "p_external_product_id" "text", "p_is_visible" boolean, "p_sort_order" integer, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_store_product"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_source_type" "text", "p_external_product_id" "text", "p_is_visible" boolean, "p_sort_order" integer, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_store_product"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_source_type" "text", "p_external_product_id" "text", "p_is_visible" boolean, "p_sort_order" integer, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_store_product"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_source_type" "text", "p_external_product_id" "text", "p_is_visible" boolean, "p_sort_order" integer, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."delete_store_product"("p_product_id" "uuid", "p_edit_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_store_product"("p_product_id" "uuid", "p_edit_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_store_product"("p_product_id" "uuid", "p_edit_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_store_product"("p_product_id" "uuid", "p_edit_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."delete_store_with_token"("p_slug" "text", "p_edit_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_store_with_token"("p_slug" "text", "p_edit_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_store_with_token"("p_slug" "text", "p_edit_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_store_with_token"("p_slug" "text", "p_edit_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."delete_user_account"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_user_account"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_user_account"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_action" "text", "p_target_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_action" "text", "p_target_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_action" "text", "p_target_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_user_id" "uuid", "p_action" "text", "p_target_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_user_id" "uuid", "p_action" "text", "p_target_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_audit_logs"("p_limit" integer, "p_user_id" "uuid", "p_action" "text", "p_target_type" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_feature_flags"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_feature_flags"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_feature_flags"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_feature_flags"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_store_preview"("p_slug" "text", "p_edit_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_store_preview"("p_slug" "text", "p_edit_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_store_preview"("p_slug" "text", "p_edit_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_store_preview"("p_slug" "text", "p_edit_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_today_vitrin_view_count"("p_slug" "text", "p_edit_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_today_vitrin_view_count"("p_slug" "text", "p_edit_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_today_vitrin_view_count"("p_slug" "text", "p_edit_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_updated_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_updated_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_updated_user"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."link_store_to_user"("p_edit_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."link_store_to_user"("p_edit_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."link_store_to_user"("p_edit_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_audit_event"("p_user_id" "uuid", "p_session_id" "text", "p_action" "text", "p_target_type" "text", "p_target_id" "text", "p_old_value" "jsonb", "p_new_value" "jsonb", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_audit_event"("p_user_id" "uuid", "p_session_id" "text", "p_action" "text", "p_target_type" "text", "p_target_id" "text", "p_old_value" "jsonb", "p_new_value" "jsonb", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_audit_event"("p_user_id" "uuid", "p_session_id" "text", "p_action" "text", "p_target_type" "text", "p_target_id" "text", "p_old_value" "jsonb", "p_new_value" "jsonb", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_demo_store_mutation"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_demo_store_mutation"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_demo_store_mutation"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."record_vitrin_view"("p_store_slug" "text", "p_session_key" "text", "p_source" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."record_vitrin_view"("p_store_slug" "text", "p_session_key" "text", "p_source" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."record_vitrin_view"("p_store_slug" "text", "p_session_key" "text", "p_source" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."reorder_store_products"("p_store_id" "uuid", "p_edit_token" "text", "p_product_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reorder_store_products"("p_store_id" "uuid", "p_edit_token" "text", "p_product_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."reorder_store_products"("p_store_id" "uuid", "p_edit_token" "text", "p_product_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."reorder_store_products"("p_store_id" "uuid", "p_edit_token" "text", "p_product_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."save_store_draft_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."save_store_draft_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."save_store_draft_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."save_store_draft_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_published_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_published_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_published_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_published_at_on_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_published_at_on_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_published_at_on_insert"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_store_instagram_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_store_instagram_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_store_product"("p_product_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_is_visible" boolean, "p_sort_order" integer, "p_stock_quantity" integer, "p_stock_status" "text", "p_clear_category" boolean, "p_clear_price_amount" boolean, "p_clear_stock_quantity" boolean, "p_clear_stock_status" boolean, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text", "p_clear_old_price_amount" boolean, "p_clear_badge_tag" boolean, "p_clear_fulfillment_region" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_store_product"("p_product_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_is_visible" boolean, "p_sort_order" integer, "p_stock_quantity" integer, "p_stock_status" "text", "p_clear_category" boolean, "p_clear_price_amount" boolean, "p_clear_stock_quantity" boolean, "p_clear_stock_status" boolean, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text", "p_clear_old_price_amount" boolean, "p_clear_badge_tag" boolean, "p_clear_fulfillment_region" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."update_store_product"("p_product_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_is_visible" boolean, "p_sort_order" integer, "p_stock_quantity" integer, "p_stock_status" "text", "p_clear_category" boolean, "p_clear_price_amount" boolean, "p_clear_stock_quantity" boolean, "p_clear_stock_status" boolean, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text", "p_clear_old_price_amount" boolean, "p_clear_badge_tag" boolean, "p_clear_fulfillment_region" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_store_product"("p_product_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_description" "text", "p_price_text" "text", "p_price_amount" numeric, "p_image_urls" "jsonb", "p_category_id" "uuid", "p_is_visible" boolean, "p_sort_order" integer, "p_stock_quantity" integer, "p_stock_status" "text", "p_clear_category" boolean, "p_clear_price_amount" boolean, "p_clear_stock_quantity" boolean, "p_clear_stock_status" boolean, "p_old_price_amount" numeric, "p_badge_tag" "text", "p_fulfillment_region" "text", "p_clear_old_price_amount" boolean, "p_clear_badge_tag" boolean, "p_clear_fulfillment_region" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."update_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."update_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."upsert_products_from_xml"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."upsert_products_from_xml"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_products_from_xml"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_products_from_xml"("p_store_id" "uuid", "p_edit_token" "text", "p_products" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."upsert_store_category"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_sort_order" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."upsert_store_category"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_sort_order" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_store_category"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_sort_order" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_store_category"("p_store_id" "uuid", "p_edit_token" "text", "p_name" "text", "p_slug" "text", "p_sort_order" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."validate_product_category"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validate_product_category"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."withdraw_store_publication_consent"("p_slug" "text", "p_edit_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."withdraw_store_publication_consent"("p_slug" "text", "p_edit_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."withdraw_store_publication_consent"("p_slug" "text", "p_edit_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."withdraw_store_publication_consent"("p_slug" "text", "p_edit_token" "text") TO "service_role";


















GRANT ALL ON TABLE "public"."admins" TO "anon";
GRANT ALL ON TABLE "public"."admins" TO "authenticated";
GRANT ALL ON TABLE "public"."admins" TO "service_role";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."appointments" TO "anon";
GRANT ALL ON TABLE "public"."appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."appointments" TO "service_role";



GRANT ALL ON TABLE "public"."assistant_rate_limits" TO "service_role";



GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."booking_settings" TO "anon";
GRANT ALL ON TABLE "public"."booking_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."booking_settings" TO "service_role";



GRANT ALL ON TABLE "public"."category_image_templates" TO "anon";
GRANT ALL ON TABLE "public"."category_image_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."category_image_templates" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."feature_flags" TO "anon";
GRANT ALL ON TABLE "public"."feature_flags" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_flags" TO "service_role";



GRANT ALL ON TABLE "public"."legal_documents" TO "anon";
GRANT ALL ON TABLE "public"."legal_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."legal_documents" TO "service_role";



GRANT ALL ON TABLE "public"."platform_settings" TO "anon";
GRANT ALL ON TABLE "public"."platform_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."platform_settings" TO "service_role";



GRANT ALL ON TABLE "public"."product_categories" TO "anon";
GRANT ALL ON TABLE "public"."product_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."product_categories" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."store_articles" TO "anon";
GRANT ALL ON TABLE "public"."store_articles" TO "authenticated";
GRANT ALL ON TABLE "public"."store_articles" TO "service_role";



GRANT ALL ON TABLE "public"."store_category_image_usage" TO "anon";
GRANT ALL ON TABLE "public"."store_category_image_usage" TO "authenticated";
GRANT ALL ON TABLE "public"."store_category_image_usage" TO "service_role";



GRANT ALL ON TABLE "public"."store_instagram_connections" TO "anon";
GRANT ALL ON TABLE "public"."store_instagram_connections" TO "authenticated";
GRANT ALL ON TABLE "public"."store_instagram_connections" TO "service_role";



GRANT ALL ON TABLE "public"."store_instagram_imports" TO "anon";
GRANT ALL ON TABLE "public"."store_instagram_imports" TO "authenticated";
GRANT ALL ON TABLE "public"."store_instagram_imports" TO "service_role";



GRANT ALL ON TABLE "public"."store_instagram_tokens" TO "service_role";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."stores" TO "anon";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."stores" TO "authenticated";
GRANT ALL ON TABLE "public"."stores" TO "service_role";



GRANT SELECT("id") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("id") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("slug") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("slug") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("name") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("name") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("business_type") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("business_type") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("description") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("description") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("whatsapp") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("whatsapp") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("instagram") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("instagram") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("website") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("website") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("address") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("address") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("theme") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("theme") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("status") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("status") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("marketplace_links") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("marketplace_links") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("catalog_link") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("catalog_link") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("references_link") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("references_link") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("vcard_link") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("vcard_link") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("is_published") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("is_published") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("created_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("created_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("updated_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("updated_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("shelf_image_url") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("shelf_image_url") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("corporate_bio") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("corporate_bio") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("gallery_items") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("gallery_items") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("is_store") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("is_store") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("kategori") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("kategori") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("latitude") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("latitude") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("longitude") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("longitude") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("location_accuracy_meters") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("location_accuracy_meters") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("location_consent_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("location_consent_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("location_source") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("location_source") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("user_id") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("user_id") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("working_hours") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("working_hours") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("products") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("products") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("logo_url") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("logo_url") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("offerings") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("offerings") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("google_business_link") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("google_business_link") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("province_code") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("province_code") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("province_name") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("province_name") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("district_code") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("district_code") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("district_name") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("district_name") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("booking_is_enabled") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("booking_is_enabled") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("privacy_notice_acknowledged") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("privacy_notice_acknowledged") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("terms_accepted") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("terms_accepted") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("explicit_consent_given") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("explicit_consent_given") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("consent_accepted_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("consent_accepted_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("publish_version") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("publish_version") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("publish_hash") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("publish_hash") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("privacy_notice_hash") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("privacy_notice_hash") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("privacy_notice_version") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("privacy_notice_version") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("privacy_notice_acknowledged_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("privacy_notice_acknowledged_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("terms_hash") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("terms_hash") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("terms_version") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("terms_version") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("terms_accepted_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("terms_accepted_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("publication_consent_hash") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("publication_consent_hash") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("publication_consent_version") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("publication_consent_version") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("publication_consent_accepted_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("publication_consent_accepted_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("product_categories") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("product_categories") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("publication_consent_accepted") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("publication_consent_accepted") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("publication_consent_withdrawn_at") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("publication_consent_withdrawn_at") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("product_storage_version") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("product_storage_version") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("theme_preset") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("theme_preset") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("email") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("email") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("rating_score") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("rating_score") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("review_count") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("review_count") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("featured_banner_title") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("featured_banner_title") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("featured_banner_description") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("featured_banner_description") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("featured_banner_image_url") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("featured_banner_image_url") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("featured_banner_price_text") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("featured_banner_price_text") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("is_demo") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("is_demo") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("phone") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("phone") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("hero_badge") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("hero_badge") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("featured_banner_label") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("featured_banner_label") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("faq_items") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("faq_items") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("about_kicker") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("about_kicker") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("about_title") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("about_title") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("about_image_url") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("about_image_url") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("about_image_caption") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("about_image_caption") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("about_values") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("about_values") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("gallery_section_kicker") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("gallery_section_kicker") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("gallery_section_title") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("gallery_section_title") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("show_storefront_rating") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("show_storefront_rating") ON TABLE "public"."stores" TO "authenticated";



GRANT SELECT("show_directions_link") ON TABLE "public"."stores" TO "anon";
GRANT SELECT("show_directions_link") ON TABLE "public"."stores" TO "authenticated";



GRANT ALL ON TABLE "public"."vitrin_views" TO "service_role";



GRANT ALL ON TABLE "public"."xml_feeds" TO "anon";
GRANT ALL ON TABLE "public"."xml_feeds" TO "authenticated";
GRANT ALL ON TABLE "public"."xml_feeds" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































