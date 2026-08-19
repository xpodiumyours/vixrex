-- V-04 (attack-vectors.md, 2026-08-18): marketplace_links javascript: URI.
--
-- BULGU: VitrinProfileView.tsx:962 marketplace_links dizisindeki her
-- öğenin `url` alanını doğrudan `<a href={link.url}>` olarak basıyor.
-- Tek koruma istemci tarafındaydı (lib/services/store_publish_links_
-- validator.dart) — RPC'ye (create_store_with_token / save_store_draft_
-- with_token / update_store_with_token) doğrudan çağrıyla bypass edilir.
-- Karşılaştırma: google_business_link DB CHECK ile korunuyor, website/
-- instagram normalizeExternalUrl ile https'e zorlanıyor — marketplace_
-- links'in hiç sunucu tarafı koruması yoktu.
--
-- ÇÖZÜM: Ortak bir sunucu tarafı süzgeç — _sanitize_marketplace_links.
-- Flutter validator'ının kural setiyle aynı: yalnız http(s) şemalı (veya
-- boş) url'li öğeler kalır; javascript:/data:/file:/tel:/mailto: gibi
-- şemalı öğeler SESSİZCE DÜŞER (öğenin diğer alanları — platform, label —
-- bir hata sebebiyle kaybolmasın diye "url'i temizle" değil "öğeyi at"
-- seçildi; zaten geçersiz şemalı bir marketplace linki anlamsız).
--
-- Üç yazma noktası da (create/save-draft update+insert/update) bu
-- fonksiyonu kullanacak şekilde CREATE OR REPLACE ile yeniden tanımlandı;
-- fonksiyon gövdelerinin geri kalanı DEĞİŞMEDİ (yalnız marketplace_links
-- ifadesi değişti).

CREATE OR REPLACE FUNCTION "public"."_sanitize_marketplace_links"("p_links" "jsonb")
RETURNS "jsonb"
LANGUAGE "plpgsql"
IMMUTABLE
SET "search_path" TO 'pg_catalog', 'public'
AS $$
DECLARE
  v_result jsonb := '[]'::jsonb;
  v_item jsonb;
  v_url text;
BEGIN
  IF p_links IS NULL OR jsonb_typeof(p_links) <> 'array' THEN
    RETURN '[]'::jsonb;
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_links)
  LOOP
    v_url := btrim(coalesce(v_item->>'url', ''));
    IF v_url = '' OR v_url ~* '^https?://' THEN
      v_result := v_result || jsonb_build_array(v_item);
    END IF;
    -- şema izin listesi dışındaki (javascript:, data:, file:, tel:,
    -- mailto: vb.) öğe sessizce düşer.
  END LOOP;

  RETURN v_result;
END;
$$;

ALTER FUNCTION "public"."_sanitize_marketplace_links"("p_links" "jsonb") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."_sanitize_marketplace_links"("p_links" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_sanitize_marketplace_links"("p_links" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."_sanitize_marketplace_links"("p_links" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_sanitize_marketplace_links"("p_links" "jsonb") TO "service_role";

-- ── create_store_with_token ────────────────────────────────────────────
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
    public._sanitize_marketplace_links(p_store->'marketplace_links'),
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

-- ── save_store_draft_with_token ────────────────────────────────────────
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
      marketplace_links = CASE WHEN p_store ? 'marketplace_links'
        THEN public._sanitize_marketplace_links(p_store->'marketplace_links')
        ELSE marketplace_links END,
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
      public._sanitize_marketplace_links(p_store->'marketplace_links'),
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

-- ── update_store_with_token ─────────────────────────────────────────────
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
