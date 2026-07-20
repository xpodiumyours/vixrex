-- ============================================================================
-- Aşama 4A-DÜZELTİLMİŞ v3: Ürün CRUD RPC'leri
--
-- Düzeltmeler:
-- 1. _check_store_authorization: user_id NULL olsa bile edit_token ile yetki ver
-- 2. update_store_product: p_clear_* flag'leri ile NULL değer desteği
-- 3. _check_store_authorization'a anon/authenticated doğrudan EXECUTE kaldırıldı
-- ============================================================================

-- Eski fonksiyonları temizle
DROP FUNCTION IF EXISTS public._check_store_authorization(UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_store_product(UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, JSONB, UUID, TEXT, TEXT, BOOLEAN, INT);
DROP FUNCTION IF EXISTS public.update_store_product(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, JSONB, UUID, BOOLEAN, INT, INT, TEXT);
DROP FUNCTION IF EXISTS public.delete_store_product(UUID, TEXT);
DROP FUNCTION IF EXISTS public.reorder_store_products(UUID, TEXT, UUID[]);

-- ============================================================================
-- 1. YARDIMCI: Yetkilendirme kontrolü
-- ============================================================================
-- SECURITY DEFINER: Fonksiyonu çağıranın değil, oluşturanın yetkisiyle çalışır
-- user_id NULL olsa bile edit_token ile yetki verilir
-- Doğrudan anon/authenticated EXECUTE yetkisi YOKTUR
-- Yalnızca 4 ana SECURITY DEFINER RPC içinden kullanılır
-- ============================================================================
CREATE OR REPLACE FUNCTION public._check_store_authorization(
  p_store_id UUID,
  p_edit_token TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_owner_id UUID;
  v_stored_token TEXT;
BEGIN
  -- Mağazanın var olduğunu kontrol et
  SELECT user_id, edit_token INTO v_owner_id, v_stored_token
  FROM public.stores WHERE id = p_store_id;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  -- Yol 1: Giriş yapmış mağaza sahibi (user_id NULL olabilir — guest mağaza)
  IF auth.uid() IS NOT NULL AND v_owner_id IS NOT NULL AND v_owner_id = auth.uid() THEN
    RETURN TRUE;
  END IF;

  -- Yol 2: Edit-token ile misafir sahiplik (user_id NULL olsa bile çalışır)
  IF p_edit_token IS NOT NULL
     AND pg_catalog.length(pg_catalog.btrim(p_edit_token)) >= 24
     AND v_stored_token IS NOT NULL
     AND v_stored_token = p_edit_token
     AND v_stored_token <> '' THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$;

-- ============================================================================
-- 2. ÜRÜN EKLE
-- ============================================================================
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
  p_sort_order INT DEFAULT 0
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
    is_visible, sort_order
  ) VALUES (
    p_store_id, trim(p_name), trim(p_slug), p_description,
    p_price_text, p_price_amount, p_image_urls,
    p_category_id, p_source_type, p_external_product_id,
    p_is_visible, p_sort_order
  )
  RETURNING id INTO v_new_product;

  RETURN jsonb_build_object('id', v_new_product, 'success', true);
END;
$$;

-- ============================================================================
-- 3. ÜRÜN GÜNCELLE (clear flag destekli)
-- ============================================================================
-- p_clear_* = TRUE ise ilgili alan NULL yapılır
-- p_clear_* = FALSE VE p_*_value NULL ise alan değişmez
-- ============================================================================
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
  p_clear_stock_status BOOLEAN DEFAULT FALSE
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
    END
  WHERE id = p_product_id;

  RETURN jsonb_build_object('id', p_product_id, 'success', true);
END;
$$;

-- ============================================================================
-- 4. ÜRÜN SİL
-- ============================================================================
CREATE OR REPLACE FUNCTION public.delete_store_product(
  p_product_id UUID,
  p_edit_token TEXT DEFAULT NULL
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

  DELETE FROM public.products WHERE id = p_product_id;

  RETURN jsonb_build_object('id', p_product_id, 'success', true);
END;
$$;

-- ============================================================================
-- 5. ÜRÜN SIRALAMASINI DEĞİŞTİR
-- ============================================================================
CREATE OR REPLACE FUNCTION public.reorder_store_products(
  p_store_id UUID,
  p_edit_token TEXT,
  p_product_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_index INT;
  v_product_id UUID;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  FOR v_index IN 1..array_length(p_product_ids, 1) LOOP
    v_product_id := p_product_ids[v_index];
    UPDATE public.products
    SET sort_order = v_index - 1
    WHERE id = v_product_id AND store_id = p_store_id;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'reordered', array_length(p_product_ids, 1));
END;
$$;

-- ============================================================================
-- 6. GRANT — _check_store_authorization'a DOĞRUDAN YETKİ VERİLMEZ
-- ============================================================================
REVOKE EXECUTE ON FUNCTION public._check_store_authorization FROM public;
REVOKE EXECUTE ON FUNCTION public._check_store_authorization FROM anon;
REVOKE EXECUTE ON FUNCTION public._check_store_authorization FROM authenticated;

REVOKE EXECUTE ON FUNCTION public.create_store_product FROM public;
REVOKE EXECUTE ON FUNCTION public.update_store_product FROM public;
REVOKE EXECUTE ON FUNCTION public.delete_store_product FROM public;
REVOKE EXECUTE ON FUNCTION public.reorder_store_products FROM public;

GRANT EXECUTE ON FUNCTION public.create_store_product TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_store_product TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_store_product TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reorder_store_products TO anon, authenticated;
