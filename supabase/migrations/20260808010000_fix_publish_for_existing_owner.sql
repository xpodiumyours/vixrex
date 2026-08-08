-- Bir kullanici bir vitrin: ikinci yayin mevcut vitrini gunceller.
--
-- SORUN (2026-08-08, tur bulgusu 17)
-- Yayinlama tamamen kilitlendi:
--   duplicate key value violates unique constraint "unique_user_store"
--
-- stores.user_id uzerinde UNIQUE kisit var. create_store_with_token duz
-- INSERT yapiyordu. 7 Agustos'ta anonim oturum eklendi; artik her
-- kullanicinin user_id'si dolu, kisit devreye girdi. Eskiden user_id bos
-- oldugu icin hic tetiklenmiyordu.
--
-- Casper: "hic vitrin yayinlanmiyor".
--
-- YAKLASIM
-- Fonksiyon BASTAN YAZILMADI. Orijinal INSERT blogu birebir korundu —
-- eksik birakilacak bir sutun ya da bilinmeyen bir tetikleyici
-- yayinlamayi baska turlu kirabilirdi. Yalniz basina bir kontrol kondu.

CREATE OR REPLACE FUNCTION "public"."create_store_with_token"("p_slug" "text", "p_edit_token" "text", "p_store" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_mevcut_id uuid;
  v_mevcut_slug text;
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  -- KULLANICININ VITRINI VARSA YENISI KURULMAZ, MEVCUDU GUNCELLENIR.
  --
  -- 2026-08-08: yayinlama tamamen kilitlendi —
  --   duplicate key value violates unique constraint "unique_user_store"
  -- stores.user_id uzerinde UNIQUE kisit var: bir kullanici bir vitrin.
  -- Bu fonksiyon duz INSERT yapiyordu. 7 Agustos'ta anonim oturum
  -- eklendi; artik her kullanicinin user_id'si dolu. Eskiden bos oldugu
  -- icin kisit hic tetiklenmiyordu (birden fazla NULL cakisma saymaz).
  -- Sonuc: bir kez vitrin kuran esnaf bir daha hic yayinlayamiyordu.
  --
  -- Asagidaki INSERT bloguna DOKUNULMADI; yalniz onune bu kontrol kondu.
  IF v_user_id IS NOT NULL THEN
    SELECT id, slug INTO v_mevcut_id, v_mevcut_slug
    FROM public.stores WHERE user_id = v_user_id LIMIT 1;
  END IF;

  IF v_mevcut_id IS NOT NULL THEN
    -- Slug degistiyse ve BASKASI kullanmiyorsa guncellenir; boylece
    -- uygulamanin verdigi link dogru kalir. Kullaniliyorsa eski adres
    -- korunur — baskasinin vitrinini ele gecirmek soz konusu olamaz.
    IF pg_catalog.btrim(p_slug) <> v_mevcut_slug
       AND NOT EXISTS (
         SELECT 1 FROM public.stores
         WHERE slug = pg_catalog.btrim(p_slug) AND id <> v_mevcut_id
       )
    THEN
      UPDATE public.stores SET slug = pg_catalog.btrim(p_slug)
      WHERE id = v_mevcut_id;
    END IF;

    UPDATE public.stores SET
      name = coalesce(p_store->>'name', name),
      business_type = coalesce(p_store->>'business_type', business_type),
      description = coalesce(p_store->>'description', description),
      whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
      phone = coalesce(p_store->>'phone', phone),
      email = coalesce(p_store->>'email', email),
      instagram = coalesce(p_store->>'instagram', instagram),
      website = coalesce(p_store->>'website', website),
      address = coalesce(p_store->>'address', address),
      status = coalesce(p_store->>'status', status),
      shelf_image_url = coalesce(p_store->>'shelf_image_url', shelf_image_url),
      logo_url = coalesce(p_store->>'logo_url', logo_url),
      kategori = coalesce(p_store->>'kategori', kategori),
      province_code = coalesce(p_store->>'province_code', province_code),
      province_name = coalesce(p_store->>'province_name', province_name),
      district_code = coalesce(p_store->>'district_code', district_code),
      district_name = coalesce(p_store->>'district_name', district_name),
      latitude = coalesce((p_store->>'latitude')::double precision, latitude),
      longitude = coalesce((p_store->>'longitude')::double precision, longitude),
      is_published = coalesce((p_store->>'is_published')::boolean, is_published),
      is_store = coalesce((p_store->>'is_store')::boolean, is_store),
      privacy_notice_acknowledged = coalesce(
        (p_store->>'privacy_notice_acknowledged')::boolean,
        privacy_notice_acknowledged),
      privacy_notice_version = coalesce(
        p_store->>'privacy_notice_version', privacy_notice_version),
      privacy_notice_hash = coalesce(
        p_store->>'privacy_notice_hash', privacy_notice_hash),
      terms_accepted = coalesce(
        (p_store->>'terms_accepted')::boolean, terms_accepted),
      terms_version = coalesce(p_store->>'terms_version', terms_version),
      terms_hash = coalesce(p_store->>'terms_hash', terms_hash),
      publication_consent_accepted = coalesce(
        (p_store->>'publication_consent_accepted')::boolean,
        publication_consent_accepted),
      publication_consent_version = coalesce(
        p_store->>'publication_consent_version', publication_consent_version),
      publication_consent_hash = coalesce(
        p_store->>'publication_consent_hash', publication_consent_hash),
      updated_at = pg_catalog.now()
    WHERE id = v_mevcut_id;

    RETURN;
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

