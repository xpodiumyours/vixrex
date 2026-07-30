-- Dilim 3: ürün create/update RPC'lerine Atmosfer alanları.
-- Sütunlar zaten var (old_price_amount, badge_tag, fulfillment_region).
-- Bu migration yalnız RPC imzasını genişletir; satır silmez.

DROP FUNCTION IF EXISTS public.create_store_product(
  UUID, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, JSONB, UUID, TEXT, TEXT, BOOLEAN, INT
);

CREATE OR REPLACE FUNCTION public.create_store_product(
  p_store_id UUID,
  p_edit_token TEXT,
  p_name TEXT,
  p_slug TEXT,
  p_description TEXT DEFAULT '',
  p_price_text TEXT DEFAULT '',
  p_price_amount NUMERIC DEFAULT NULL,
  p_image_urls JSONB DEFAULT '[]'::jsonb,
  p_category_id UUID DEFAULT NULL,
  p_source_type TEXT DEFAULT 'manual',
  p_external_product_id TEXT DEFAULT NULL,
  p_is_visible BOOLEAN DEFAULT true,
  p_sort_order INT DEFAULT 0,
  p_old_price_amount NUMERIC DEFAULT NULL,
  p_badge_tag TEXT DEFAULT NULL,
  p_fulfillment_region TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
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

DROP FUNCTION IF EXISTS public.update_store_product(
  UUID, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, JSONB, UUID, BOOLEAN, INT, INT, TEXT,
  BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN
);

CREATE OR REPLACE FUNCTION public.update_store_product(
  p_product_id UUID,
  p_edit_token TEXT DEFAULT NULL,
  p_name TEXT DEFAULT NULL,
  p_slug TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_price_text TEXT DEFAULT NULL,
  p_price_amount NUMERIC DEFAULT NULL,
  p_image_urls JSONB DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_is_visible BOOLEAN DEFAULT NULL,
  p_sort_order INT DEFAULT NULL,
  p_stock_quantity INT DEFAULT NULL,
  p_stock_status TEXT DEFAULT NULL,
  p_clear_category BOOLEAN DEFAULT FALSE,
  p_clear_price_amount BOOLEAN DEFAULT FALSE,
  p_clear_stock_quantity BOOLEAN DEFAULT FALSE,
  p_clear_stock_status BOOLEAN DEFAULT FALSE,
  p_old_price_amount NUMERIC DEFAULT NULL,
  p_badge_tag TEXT DEFAULT NULL,
  p_fulfillment_region TEXT DEFAULT NULL,
  p_clear_old_price_amount BOOLEAN DEFAULT FALSE,
  p_clear_badge_tag BOOLEAN DEFAULT FALSE,
  p_clear_fulfillment_region BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
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

REVOKE EXECUTE ON FUNCTION public.create_store_product FROM public;
REVOKE EXECUTE ON FUNCTION public.update_store_product FROM public;
GRANT EXECUTE ON FUNCTION public.create_store_product TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_store_product TO anon, authenticated;
