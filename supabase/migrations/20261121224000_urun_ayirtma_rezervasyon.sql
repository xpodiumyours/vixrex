ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS reservation_kind text NOT NULL DEFAULT 'service',
  ADD COLUMN IF NOT EXISTS product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS variant_key text,
  ADD COLUMN IF NOT EXISTS quantity integer;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'appointments_reservation_kind_check'
  ) THEN
    ALTER TABLE public.appointments
      ADD CONSTRAINT appointments_reservation_kind_check
      CHECK (reservation_kind IN ('service', 'product_hold'));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'appointments_quantity_check'
  ) THEN
    ALTER TABLE public.appointments
      ADD CONSTRAINT appointments_quantity_check
      CHECK (quantity IS NULL OR quantity BETWEEN 1 AND 10);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_appointments_product_hold_active
  ON public.appointments (product_id, status, expires_at)
  WHERE reservation_kind = 'product_hold' AND product_id IS NOT NULL;

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
    OR v_customer_name = ''
    OR v_customer_phone = ''
  THEN
    RAISE EXCEPTION 'INVALID_HOLD_INPUT';
  END IF;

  SELECT count(*)::integer INTO v_daily_count
  FROM public.appointments
  WHERE customer_phone = v_customer_phone
    AND created_at > now() - interval '24 hours';

  IF v_daily_count >= 5 THEN
    RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED';
  END IF;

  SELECT p.id, p.name, p.price_text, p.stock_quantity
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
    v_plaintext_token,
    v_token_hash,
    v_expires_at,
    'product_hold',
    v_product.id,
    v_variant_key,
    p_quantity
  );

  RETURN jsonb_build_object(
    'appointment_id', v_appt_id,
    'token', v_plaintext_token,
    'expires_at', v_expires_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.create_product_hold(text, text, text, text, text, text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_product_hold(text, text, text, text, text, text, integer) TO anon, authenticated;
