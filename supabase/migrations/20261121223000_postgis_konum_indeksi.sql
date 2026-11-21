CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

ALTER TABLE public.stores
  ADD COLUMN IF NOT EXISTS location extensions.geography(Point, 4326);

CREATE OR REPLACE FUNCTION public.stores_sync_location_geography()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
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

DROP TRIGGER IF EXISTS trg_stores_sync_location_geography ON public.stores;

CREATE TRIGGER trg_stores_sync_location_geography
  BEFORE INSERT OR UPDATE OF latitude, longitude ON public.stores
  FOR EACH ROW
  EXECUTE FUNCTION public.stores_sync_location_geography();

DO $$
DECLARE
  v_demo_trigger_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'protect_landing_demo_stores'
      AND tgrelid = 'public.stores'::regclass
      AND NOT tgisinternal
  ) INTO v_demo_trigger_exists;

  IF v_demo_trigger_exists THEN
    EXECUTE 'ALTER TABLE public.stores DISABLE TRIGGER protect_landing_demo_stores';
  END IF;

  BEGIN
    UPDATE public.stores
    SET location = extensions.st_setsrid(
      extensions.st_makepoint(longitude, latitude),
      4326
    )::extensions.geography
    WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND latitude BETWEEN -90 AND 90
      AND longitude BETWEEN -180 AND 180
      AND location IS NULL;
  EXCEPTION WHEN OTHERS THEN
    IF v_demo_trigger_exists THEN
      EXECUTE 'ALTER TABLE public.stores ENABLE TRIGGER protect_landing_demo_stores';
    END IF;
    RAISE;
  END;

  IF v_demo_trigger_exists THEN
    EXECUTE 'ALTER TABLE public.stores ENABLE TRIGGER protect_landing_demo_stores';
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_stores_location_gist
  ON public.stores USING GIST (location)
  WHERE is_published = true;

CREATE INDEX IF NOT EXISTS idx_stores_province_district_published
  ON public.stores (province_name, district_name)
  WHERE is_published = true;

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
SET search_path = public, extensions
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
GRANT EXECUTE ON FUNCTION public.search_nearby_stores(double precision, double precision, integer, integer) TO anon, authenticated;
