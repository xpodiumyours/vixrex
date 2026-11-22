CREATE OR REPLACE FUNCTION public.stores_sync_location_geography()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
BEGIN
  IF NEW.latitude IS NOT NULL
     AND NEW.longitude IS NOT NULL
     AND NEW.latitude BETWEEN -90 AND 90
     AND NEW.longitude BETWEEN -180 AND 180 THEN
    NEW.location := extensions.st_setsrid(
      extensions.st_makepoint(NEW.longitude, NEW.latitude),
      4326
    )::extensions.geography;
  ELSE
    NEW.location := NULL;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.stores_sync_location_geography() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.search_nearby_stores(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer DEFAULT 5000,
  p_limit integer DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  slug text,
  name text,
  description text,
  address text,
  kategori text,
  business_type text,
  shelf_image_url text,
  logo_url text,
  province_name text,
  district_name text,
  status text,
  is_demo boolean,
  whatsapp text,
  rating_score numeric,
  review_count integer,
  show_storefront_rating boolean,
  updated_at timestamp with time zone,
  distance_meters double precision
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
DECLARE
  origin extensions.geography;
  clamped_radius integer;
  clamped_limit integer;
BEGIN
  IF p_lat IS NULL
     OR p_lng IS NULL
     OR NOT (p_lat BETWEEN -90 AND 90)
     OR NOT (p_lng BETWEEN -180 AND 180) THEN
    RETURN;
  END IF;

  clamped_radius := LEAST(GREATEST(COALESCE(p_radius_m, 5000), 100), 100000);
  clamped_limit := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
  origin := extensions.st_setsrid(
    extensions.st_makepoint(p_lng, p_lat),
    4326
  )::extensions.geography;

  RETURN QUERY
  SELECT
    s.id,
    s.slug,
    s.name,
    s.description,
    s.address,
    s.kategori,
    s.business_type,
    s.shelf_image_url,
    s.logo_url,
    s.province_name,
    s.district_name,
    s.status,
    s.is_demo,
    s.whatsapp,
    s.rating_score,
    s.review_count,
    s.show_storefront_rating,
    s.updated_at,
    extensions.st_distance(s.location, origin) AS distance_meters
  FROM public.stores s
  WHERE s.is_published = true
    AND s.location IS NOT NULL
    AND extensions.st_dwithin(s.location, origin, clamped_radius)
  ORDER BY s.location <-> origin, s.updated_at DESC
  LIMIT clamped_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.search_nearby_stores(double precision, double precision, integer, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_nearby_stores(double precision, double precision, integer, integer) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.create_product_hold(
  p_store_slug text,
  p_product_slug text,
  p_customer_name text,
  p_customer_phone text,
  p_customer_notes text DEFAULT '',
  p_variant_key text DEFAULT NULL,
  p_quantity integer DEFAULT 1
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
DECLARE
  v_store_slug text := pg_catalog.btrim(coalesce(p_store_slug, ''));
  v_product_slug text := pg_catalog.btrim(coalesce(p_product_slug, ''));
  v_customer_name text := pg_catalog.btrim(coalesce(p_customer_name, ''));
  v_customer_phone text := pg_catalog.btrim(coalesce(p_customer_phone, ''));
  v_customer_notes text := pg_catalog.btrim(coalesce(p_customer_notes, ''));
  v_variant_key text := nullif(pg_catalog.btrim(coalesce(p_variant_key, '')), '');
  v_daily_count integer;
  v_product record;
  v_store_user_id uuid;
  v_active_holds integer := 0;
  v_plaintext_token text;
  v_token_hash text;
  v_appt_id uuid;
  v_expires_at timestamptz;
  v_service_title text;
BEGIN
  IF p_quantity IS NULL
    OR p_quantity < 1
    OR p_quantity > 10
    OR v_store_slug = ''
    OR v_product_slug = ''
    OR char_length(v_customer_name) NOT BETWEEN 2 AND 120
    OR char_length(v_customer_phone) NOT BETWEEN 7 AND 32
    OR char_length(v_customer_notes) > 240
  THEN
    RAISE EXCEPTION 'INVALID_HOLD_INPUT';
  END IF;

  SELECT count(*)::integer INTO v_daily_count
  FROM public.appointments
  WHERE customer_phone = v_customer_phone
    AND reservation_kind = 'product_hold'
    AND created_at > now() - interval '24 hours';

  IF v_daily_count >= 5 THEN
    RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED';
  END IF;

  SELECT p.id, p.name, p.price_text, p.stock_quantity, s.user_id AS store_user_id, s.name AS store_name
  INTO v_product
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  WHERE s.slug = v_store_slug
    AND s.is_published = true
    AND p.slug = v_product_slug
    AND p.is_active = true
    AND p.is_visible = true
  FOR UPDATE OF p;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PRODUCT_NOT_FOUND';
  END IF;

  v_store_user_id := v_product.store_user_id;

  UPDATE public.appointments
  SET status = 'expired'
  WHERE product_id = v_product.id
    AND reservation_kind = 'product_hold'
    AND status = 'pending'
    AND expires_at <= now();

  IF v_product.stock_quantity IS NOT NULL THEN
    SELECT coalesce(sum(coalesce(a.quantity, 1)), 0)::integer
    INTO v_active_holds
    FROM public.appointments a
    WHERE a.product_id = v_product.id
      AND a.reservation_kind = 'product_hold'
      AND a.status IN ('pending', 'confirmed')
      AND a.expires_at > now();

    IF (v_product.stock_quantity - v_active_holds) < p_quantity THEN
      RAISE EXCEPTION 'STOCK_UNAVAILABLE';
    END IF;
  END IF;

  v_plaintext_token := encode(gen_random_bytes(16), 'hex');
  v_token_hash := encode(sha256(v_plaintext_token::bytea), 'hex');
  v_appt_id := gen_random_uuid();
  v_expires_at := now() + interval '2 hours';
  v_service_title := CASE
    WHEN v_variant_key IS NOT NULL THEN v_product.name || ' (' || v_variant_key || ') · ' || p_quantity || ' adet'
    ELSE v_product.name || ' · ' || p_quantity || ' adet'
  END;

  INSERT INTO public.appointments (
    id,
    store_slug,
    customer_name,
    customer_phone,
    customer_notes,
    service_title,
    service_price,
    service_duration,
    appointment_time,
    status,
    token,
    token_hash,
    expires_at,
    reservation_kind,
    product_id,
    variant_key,
    quantity
  ) VALUES (
    v_appt_id,
    v_store_slug,
    v_customer_name,
    v_customer_phone,
    v_customer_notes,
    v_service_title,
    coalesce(v_product.price_text, ''),
    120,
    now(),
    'pending',
    v_token_hash,
    v_token_hash,
    v_expires_at,
    'product_hold',
    v_product.id,
    v_variant_key,
    p_quantity
  );

  IF v_store_user_id IS NOT NULL THEN
    INSERT INTO public.notification_inbox (user_id, id, title, body, store_slug, type)
    VALUES (
      v_store_user_id,
      'product_hold:' || v_appt_id::text,
      left('Yeni urun ayirtma: ' || v_product.name, 160),
      left(v_customer_name || ' (' || v_customer_phone || ') - ' || v_service_title, 1000),
      v_store_slug,
      'product_hold'
    )
    ON CONFLICT (user_id, id) DO NOTHING;
  END IF;

  RETURN jsonb_build_object(
    'appointment_id', v_appt_id,
    'token', v_plaintext_token,
    'expires_at', v_expires_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.create_product_hold(text, text, text, text, text, text, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_product_hold(text, text, text, text, text, text, integer) TO service_role;
