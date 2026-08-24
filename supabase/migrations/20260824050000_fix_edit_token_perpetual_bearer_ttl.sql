-- ============================================================================
-- V-15 Fix: edit_token perpetual bearer — add TTL/expiration
-- ============================================================================
-- SORUN: stores.edit_token text DEFAULT '' NOT NULL — SÜRESİZ, TTL YOK.
--   - Çalınan bir edit_token SÜRELİ devrede kalır (yıl/yıllar).
--   - Kullanıcı "çıkış yap" dese bile token geçerli kalır.
--   - Demo/kiralık vitrinler için 15 dk sonrası token yine de çalışır.
--
-- ÇÖZÜM:
--   1. stores tablosuna edit_token_expires_at TIMESTAMPTZ kolonu ekle
--   2. Yeni token üretilirken expiration set et:
--      - Demo trial (rent-demo): 15 dakika
--      - Normal store oluşturma: 1 yıl (365 gün) — yenilenebilir
--      - Sahip oturumu (create_owner_session): 15 dakika (zaten var)
--   3. _check_store_authorization ve create_owner_session'a expiration kontrolü ekle
--   4. Cron job: günlük expired token'ları temizle (NULL yap)
-- ============================================================================

BEGIN;

-- ── 1) stores tablosuna expiration kolonu ekle ─────────────────────────────
ALTER TABLE "public"."stores"
  ADD COLUMN IF NOT EXISTS "edit_token_expires_at" TIMESTAMPTZ;

COMMENT ON COLUMN "public"."stores"."edit_token_expires_at" IS
  'edit_token geçerlilik bitiş zamanı. NULL = süresiz (eski token''lar için geriye dönük uyumluluk). Dolu = o zamana kadar geçerli. V-15 fix.';

-- ── 2) _check_store_authorization: expiration kontrolü ekle ────────────────
-- Mevcut fonksiyon zaten p_edit_token ile doğruluyor, expiration ekle.
CREATE OR REPLACE FUNCTION "public"."_check_store_authorization"(
  "p_store_id" "uuid",
  "p_edit_token" "text" DEFAULT NULL::"text"
)
RETURNS boolean
LANGUAGE "plpgsql" SECURITY DEFINER
SET "search_path" TO 'pg_catalog', 'public'
AS $$
DECLARE
  v_token_ok boolean;
  v_expired boolean;
BEGIN
  -- Normalize
  IF p_edit_token IS NULL THEN
    RETURN false;
  END IF;

  SELECT
    (stores.edit_token = p_edit_token)::boolean,
    (stores.edit_token_expires_at IS NOT NULL AND stores.edit_token_expires_at <= now())::boolean
  INTO v_token_ok, v_expired
  FROM public.stores
  WHERE id = p_store_id;

  IF NOT v_token_ok THEN
    RETURN false;
  END IF;

  IF v_expired THEN
    RETURN false; -- Token expired
  END IF;

  RETURN true;
END;
$$;

ALTER FUNCTION "public"."_check_store_authorization"("p_store_id" "uuid", "p_edit_token" "text")
OWNER TO "postgres";

-- ── 3) create_owner_session: token expiration kontrolü ─────────────────────
-- Mevcut fonksiyon zaten session_token_hash kontrol ediyor, store.edit_token_expires_at da kontrol et.
CREATE OR REPLACE FUNCTION "public"."create_owner_session"(
  "p_slug" "text",
  "p_edit_token" "text" DEFAULT NULL::"text"
)
RETURNS jsonb
LANGUAGE "plpgsql" SECURITY DEFINER
SET "search_path" TO 'pg_catalog', 'public'
AS $$
DECLARE
  v_store public.stores%rowtype;
  v_session_token text;
  v_session_token_hash text;
  v_code text;
  v_expires_at timestamptz := now() + interval '15 minutes';
  v_token_expired boolean;
BEGIN
  IF p_slug IS NULL OR pg_catalog.btrim(p_slug) = '' THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  SELECT * INTO v_store
  FROM public.stores
  WHERE slug = pg_catalog.btrim(p_slug);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'STORE_NOT_FOUND';
  END IF;

  -- Demo store immutable
  IF v_store.is_demo THEN
    RAISE EXCEPTION 'DEMO_STORE_IMMUTABLE';
  END IF;

  -- V-15: edit_token expiration kontrolü
  IF v_store.edit_token_expires_at IS NOT NULL AND v_store.edit_token_expires_at <= now() THEN
    RAISE EXCEPTION 'EDIT_TOKEN_EXPIRED';
  END IF;

  IF v_store.edit_token <> pg_catalog.btrim(p_edit_token) THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  -- Session token oluştur
  v_session_token := encode(gen_random_bytes(32), 'hex');
  v_session_token_hash := encode(sha256(v_session_token::bytea), 'hex');
  v_code := upper(substring(encode(gen_random_bytes(4), 'hex') from 1 for 6));

  INSERT INTO public.owner_sessions (
    store_id, session_token_hash, code, expires_at, consumed_at
  ) VALUES (
    v_store.id, v_session_token_hash, v_code, v_expires_at, now()
  )
  ON CONFLICT (store_id) DO UPDATE SET
    session_token_hash = EXCLUDED.session_token_hash,
    code = EXCLUDED.code,
    expires_at = EXCLUDED.expires_at,
    consumed_at = EXCLUDED.consumed_at;

  RETURN jsonb_build_object(
    'code', v_code,
    'expires_at', v_expires_at
  );
END;
$$;

ALTER FUNCTION "public"."create_owner_session"("p_slug" "text", "p_edit_token" "text")
OWNER TO "postgres";

-- ── 4) clone_demo_store_as_draft: edit_token_expires_at = 15 dk ────────────
-- Rent-demo akışı için üretilen token 15 dakika sonra expire olmalı.
CREATE OR REPLACE FUNCTION public.clone_demo_store_as_draft(
  p_source_slug text,
  p_new_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
BEGIN
  IF p_new_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  INSERT INTO public.stores (
    slug, edit_token, user_id,
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, status,
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, is_published, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    edit_token_expires_at  -- V-15: 15 dakika sonra expire
  )
  SELECT
    pg_catalog.btrim(p_new_slug), pg_catalog.btrim(p_edit_token), null,
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, 'draft',
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, false, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    now() + interval '15 minutes'
  FROM public.stores
  WHERE slug = pg_catalog.btrim(p_source_slug)
    AND is_demo = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SOURCE_NOT_FOUND';
  END IF;
END;
$$;

-- ── 5) create_store_with_token: edit_token_expires_at = 1 yıl ──────────────
-- Normal store oluşturma için 1 yıl geçerli token.
CREATE OR REPLACE FUNCTION "public"."create_store_with_token"(
  "p_slug" "text",
  "p_edit_token" "text",
  "p_store" "jsonb"
)
RETURNS "void"
LANGUAGE "plpgsql" SECURITY DEFINER
SET "search_path" TO 'pg_catalog', 'public'
AS $$
DECLARE
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_store_json jsonb := p_store;
BEGIN
  IF v_slug = '' THEN RAISE EXCEPTION 'INVALID_SLUG'; END IF;
  IF v_token = '' OR pg_catalog.length(v_token) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  INSERT INTO public.stores (
    slug, edit_token, user_id,
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, status,
    marketplace_links, gallery_items, products, product_categories, offerings,
    catalog_link, references_link, vcard_link, shelf_image_url, logo_url,
    working_hours, is_published, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name,
    google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text,
    faq_items, about_kicker, about_title, about_image_url, about_image_caption,
    about_values, gallery_section_kicker, gallery_section_title,
    show_storefront_rating, show_directions_link,
    edit_token_expires_at  -- V-15: 1 yıl sonra expire
  ) VALUES (
    v_slug, v_token, null,
    coalesce(v_store_json->>'name', ''),
    coalesce(v_store_json->>'business_type', ''),
    coalesce(v_store_json->>'description', ''),
    coalesce(v_store_json->>'corporate_bio', ''),
    coalesce(v_store_json->>'whatsapp', ''),
    coalesce(v_store_json->>'phone', ''),
    coalesce(v_store_json->>'email', ''),
    coalesce(v_store_json->>'hero_badge', ''),
    coalesce(v_store_json->>'instagram', ''),
    coalesce(v_store_json->>'website', ''),
    coalesce(v_store_json->>'address', ''),
    coalesce(v_store_json->>'theme', 'default'),
    coalesce(v_store_json->>'theme_preset', ''),
    'draft',
    coalesce(v_store_json->'marketplace_links', '[]'::jsonb),
    coalesce(v_store_json->'gallery_items', '[]'::jsonb),
    coalesce(v_store_json->'products', '[]'::jsonb),
    coalesce(v_store_json->'product_categories', '[]'::jsonb),
    coalesce(v_store_json->'offerings', '[]'::jsonb),
    coalesce(v_store_json->>'catalog_link', ''),
    coalesce(v_store_json->>'references_link', ''),
    coalesce(v_store_json->>'vcard_link', ''),
    coalesce(v_store_json->>'shelf_image_url', ''),
    coalesce(v_store_json->>'logo_url', ''),
    coalesce(v_store_json->>'working_hours', ''),
    false, false,
    coalesce(v_store_json->>'kategori', ''),
    coalesce((v_store_json->>'latitude')::double precision, null),
    coalesce((v_store_json->>'longitude')::double precision, null),
    coalesce((v_store_json->>'location_accuracy_meters')::double precision, null),
    coalesce(v_store_json->>'location_source', ''),
    coalesce(v_store_json->>'province_code', ''),
    coalesce(v_store_json->>'province_name', ''),
    coalesce(v_store_json->>'district_code', ''),
    coalesce(v_store_json->>'district_name', ''),
    coalesce(v_store_json->>'google_business_link', ''),
    coalesce(v_store_json->>'featured_banner_label', ''),
    coalesce(v_store_json->>'featured_banner_title', ''),
    coalesce(v_store_json->>'featured_banner_description', ''),
    coalesce(v_store_json->>'featured_banner_image_url', ''),
    coalesce(v_store_json->>'featured_banner_price_text', ''),
    coalesce(v_store_json->'faq_items', '[]'::jsonb),
    coalesce(v_store_json->>'about_kicker', ''),
    coalesce(v_store_json->>'about_title', ''),
    coalesce(v_store_json->>'about_image_url', ''),
    coalesce(v_store_json->>'about_image_caption', ''),
    coalesce(v_store_json->'about_values', '[]'::jsonb),
    coalesce(v_store_json->>'gallery_section_kicker', ''),
    coalesce(v_store_json->>'gallery_section_title', ''),
    coalesce(v_store_json->>'show_storefront_rating', 'true')::boolean,
    coalesce(v_store_json->>'show_directions_link', 'true')::boolean,
    now() + interval '1 year'
  );
END;
$$;

ALTER FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb")
OWNER TO "postgres";

-- ── 6) Cron job: günlük expired token temizliği ───────────────────────────
-- pg_cron extension varsa kullan, yoksa manual cleanup fonksiyonu sağla.
DO $do$
BEGIN
  -- pg_cron extension kontrolü
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Mevcut job varsa sil (yoksa unschedule hata fırlatır)
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-expired-edit-tokens') THEN
      PERFORM cron.unschedule('cleanup-expired-edit-tokens');
    END IF;
    -- Yeni job oluştur (her gün 03:00 UTC)
    PERFORM cron.schedule(
      'cleanup-expired-edit-tokens',
      '0 3 * * *',
      $$
      UPDATE public.stores
      SET edit_token = '',
          edit_token_expires_at = NULL
      WHERE edit_token_expires_at IS NOT NULL
        AND edit_token_expires_at <= now();
      $$
    );
  END IF;
EXCEPTION
  WHEN undefined_table THEN
    -- pg_cron yoksa sessizce geç
    NULL;
END;
$do$;

-- Manual cleanup fonksiyonu (pg_cron yoksa kullanılabilir)
CREATE OR REPLACE FUNCTION public.cleanup_expired_edit_tokens()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.stores
  SET edit_token = '',
      edit_token_expires_at = NULL
  WHERE edit_token_expires_at IS NOT NULL
    AND edit_token_expires_at <= now();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.cleanup_expired_edit_tokens() IS
  'Expired edit_token''ları temizler (edit_token = '''', edit_token_expires_at = NULL). 
   pg_cron yoksa manuel veya external scheduler ile çağrılabilir.';

-- ── 7) Eski token'lar için geriye dönük uyumluluk: NULL expiration = süresiz --
-- Mevcut token'ların expiration'ı NULL (süresiz) kabul edilir.
-- Yeni token'lar yukarıdaki fonksiyonlarla expiration alacak.
-- İsterseniz mevcut token'lara default expiration verebilirsiniz:
-- UPDATE public.stores
-- SET edit_token_expires_at = now() + interval '1 year'
-- WHERE edit_token <> '' AND edit_token_expires_at IS NULL;

COMMIT;