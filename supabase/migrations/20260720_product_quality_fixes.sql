-- ============================================================================
-- Aşama 4-KALİTE: Son kalite düzeltmeleri
--
-- Düzeltmeler:
-- 1. set_products_updated_at() kaldır (kullanılmıyor)
-- 2. validate_product_category() → search_path + EXECUTE kısıtlaması
-- 3. reorder_store_products → boş liste, tekrar, yanlış mağaza kontrolü
-- 4. Owner RLS → (select auth.uid()) optimizasyonu
-- 5. _check_store_authorization → btrim ile token karşılaştırması
--
-- NOT: RPC anon/authenticated EXECUTE yetkileri KORUNUR (edit-token sistemi için)
-- NOT: Veri taşıma, Flutter, public_web, stores.products DEĞİŞTİRİLMEZ
-- ============================================================================

-- ============================================================================
-- 1. set_products_updated_at() KALDIR
-- ============================================================================
-- Bu fonksiyon hiçbir trigger tarafından kullanılmıyor
-- Trigger'lar mevcut set_updated_at() kullanıyor
-- ============================================================================
DROP FUNCTION IF EXISTS public.set_products_updated_at();

-- ============================================================================
-- 2. validate_product_category() GÜVENLİ YENİDEN OLUŞTUR
-- ============================================================================
-- search_path ekleniyor, EXECUTE anon/authenticated'den kaldırılıyor
-- ============================================================================
CREATE OR REPLACE FUNCTION public.validate_product_category()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.category_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.product_categories pc
      WHERE pc.id = NEW.category_id
        AND pc.store_id = NEW.store_id
    ) THEN
      RAISE EXCEPTION 'CATEGORY_NOT_IN_SAME_STORE';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- validate_product_category'a doğrudan EXECUTE yetkisini kaldır
REVOKE EXECUTE ON FUNCTION public.validate_product_category() FROM public;
REVOKE EXECUTE ON FUNCTION public.validate_product_category() FROM anon;
REVOKE EXECUTE ON FUNCTION public.validate_product_category() FROM authenticated;

-- ============================================================================
-- 3. reorder_store_products GÜNCELLE
-- ============================================================================
-- Boş liste → reordered=0 dön
-- Tekrarlanan ID → INVALID_PRODUCT_ORDER
-- Başka mağazaya ait veya bulunmayan ürün → INVALID_PRODUCT_ORDER
-- ============================================================================
DROP FUNCTION IF EXISTS public.reorder_store_products(UUID, TEXT, UUID[]);

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
  v_found_count INT;
BEGIN
  IF NOT public._check_store_authorization(p_store_id, p_edit_token) THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  -- Boş veya null liste
  IF p_product_ids IS NULL OR array_length(p_product_ids, 1) IS NULL OR array_length(p_product_ids, 1) = 0 THEN
    RETURN jsonb_build_object('success', true, 'reordered', 0);
  END IF;

  -- Tekrarlanan ID kontrolü
  IF array_length(p_product_ids, 1) != (
    SELECT count(DISTINCT unnest) FROM unnest(p_product_ids)
  ) THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_ORDER: Ürün listesinde tekrarlanan ID var';
  END IF;

  -- Tüm ürünlerin aynı mağazaya ait olduğunu ve mevcut olduğunu doğrula
  SELECT count(*) INTO v_found_count
  FROM public.products
  WHERE id = ANY(p_product_ids) AND store_id = p_store_id AND is_active = true;

  IF v_found_count != array_length(p_product_ids, 1) THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_ORDER: Liste içinde bulunmayan veya başka mağazaya ait ürün var';
  END IF;

  -- Sadece doğrulanmış ürünleri sırala
  FOR v_index IN 1..array_length(p_product_ids, 1) LOOP
    v_product_id := p_product_ids[v_index];
    UPDATE public.products
    SET sort_order = v_index - 1
    WHERE id = v_product_id AND store_id = p_store_id AND is_active = true;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'reordered', array_length(p_product_ids, 1));
END;
$$;

-- ============================================================================
-- 4. OWNER RLS POLİTİKALARI → (select auth.uid())
-- ============================================================================
-- auth.uid() her satır için tekrar hesaplanıyordu
-- (select auth.uid()) ile tek seferde hesaplanır
-- ============================================================================

-- PRODUCTS owner politikaları
DROP POLICY IF EXISTS "owner_select_products" ON public.products;
DROP POLICY IF EXISTS "owner_insert_products" ON public.products;
DROP POLICY IF EXISTS "owner_update_products" ON public.products;
DROP POLICY IF EXISTS "owner_delete_products" ON public.products;

CREATE POLICY "owner_select_products"
  ON public.products FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = (select auth.uid())
    )
  );

CREATE POLICY "owner_insert_products"
  ON public.products FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = (select auth.uid())
    )
  );

CREATE POLICY "owner_update_products"
  ON public.products FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = (select auth.uid())
    )
  );

CREATE POLICY "owner_delete_products"
  ON public.products FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = (select auth.uid())
    )
  );

-- PRODUCT CATEGORIES owner politikaları
DROP POLICY IF EXISTS "owner_select_categories" ON public.product_categories;
DROP POLICY IF EXISTS "owner_insert_categories" ON public.product_categories;
DROP POLICY IF EXISTS "owner_update_categories" ON public.product_categories;
DROP POLICY IF EXISTS "owner_delete_categories" ON public.product_categories;

CREATE POLICY "owner_select_categories"
  ON public.product_categories FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = (select auth.uid())
    )
  );

CREATE POLICY "owner_insert_categories"
  ON public.product_categories FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = (select auth.uid())
    )
  );

CREATE POLICY "owner_update_categories"
  ON public.product_categories FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = (select auth.uid())
    )
  );

CREATE POLICY "owner_delete_categories"
  ON public.product_categories FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = (select auth.uid())
    )
  );

-- ============================================================================
-- 5. _check_store_authorization → btrim ile token karşılaştırması
-- ============================================================================
DROP FUNCTION IF EXISTS public._check_store_authorization(UUID, TEXT);

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
  SELECT user_id, edit_token INTO v_owner_id, v_stored_token
  FROM public.stores WHERE id = p_store_id;

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  -- Yol 1: Giriş yapmış mağaza sahibi
  IF auth.uid() IS NOT NULL AND v_owner_id IS NOT NULL AND v_owner_id = auth.uid() THEN
    RETURN TRUE;
  END IF;

  -- Yol 2: Edit-token ile misafir sahiplik (btrim ile temizleme)
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

-- _check_store_authorization'a doğrudan EXECUTE yetkisi YOK (zaten yok)
-- 4 ana RPC SECURITY DEFINER olduğu için fonksiyonu çağırabilir

-- ============================================================================
-- SONUÇ: RPC EXECUTE yetkileri KORUNDU (anon/authenticated açık kaldı)
-- ============================================================================
-- reorder_store_products yeniden oluşturuldu → GRANT tekrarlanmalı
REVOKE EXECUTE ON FUNCTION public.reorder_store_products FROM public;
GRANT EXECUTE ON FUNCTION public.reorder_store_products TO anon, authenticated;
