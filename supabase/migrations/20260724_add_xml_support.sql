-- ============================================================================
-- XML Feed Desteği: Bulk Insert ve Upsert RPC'leri
--
-- Bu migration XML feed'lerinden gelen toplu ürün verilerini yönetmek için
-- iki yeni RPC fonksiyonu ekler:
-- 1. bulk_insert_products: Yeni ürünleri toplu olarak ekler (chunk halinde)
-- 2. upsert_products_from_xml: Mevcut ürünleri günceller, yenilerini ekler
-- ============================================================================

-- ============================================================================
-- 1. TOPLU ÜRÜN EKLE (BULK INSERT)
-- ============================================================================
-- 1000'erli chunk'lar halinde çalıştırılmalı
-- source_type = 'xml' olarak işaretlenir
-- external_product_id varsa benzersizlik kontrolü yapılır
-- ============================================================================
CREATE OR REPLACE FUNCTION public.bulk_insert_products(
  p_store_id UUID,
  p_edit_token TEXT,
  p_products JSONB -- [{name, slug, description, price_text, price_amount, image_urls, category_name, external_product_id, stock_quantity, stock_status}]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
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

      -- Slug üret (name'den)
      v_slug := lower(regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'));
      v_slug := regexp_replace(v_slug, '\s+', '-', 'g');
      v_slug := trim(v_slug, '-');

      -- Benzersiz slug garantile
      IF EXISTS (
        SELECT 1 FROM public.products
        WHERE store_id = p_store_id AND slug = v_slug
      ) THEN
        v_slug := v_slug || '-' || substr(md5(random()::text), 1, 6);
      END IF;

      -- external_product_id kontrolü
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

      -- Kategori adını category_id'ye çevir
      v_category_name := v_product->>'category_name';
      v_category_id := NULL;
      IF v_category_name IS NOT NULL AND length(v_category_name) > 0 THEN
        SELECT id INTO v_category_id
        FROM public.product_categories
        WHERE store_id = p_store_id
          AND lower(name) = lower(v_category_name)
        LIMIT 1;

        -- Kategori yoksa oluştur
        IF v_category_id IS NULL THEN
          INSERT INTO public.product_categories (store_id, name, slug)
          VALUES (p_store_id, v_category_name, lower(regexp_replace(v_category_name, '[^a-zA-Z0-9\s-]', '', 'g')))
          RETURNING id INTO v_category_id;
        END IF;
      END IF;

      -- Görselleri hazırla
      v_image_urls := COALESCE(v_product->'image_urls', '[]'::jsonb);
      IF jsonb_typeof(v_image_urls) != 'array' THEN
        v_image_urls := '[]'::jsonb;
      END IF;

      -- Ürünü ekle
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

  -- Sıralama numaralarını güncelle
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

-- ============================================================================
-- 2. UPSERT XML ÜRÜNLERİ (Güncelleme + Yeni Ekleme)
-- ============================================================================
-- external_product_id bazlı eşleşme yapar
-- Mevcut ürün varsa günceller, yoksa ekler
-- Fiyat ve stok değişimlerini takip eder
-- ============================================================================
CREATE OR REPLACE FUNCTION public.upsert_products_from_xml(
  p_store_id UUID,
  p_edit_token TEXT,
  p_products JSONB -- [{name, slug, description, price_text, price_amount, image_urls, category_name, external_product_id, stock_quantity, stock_status}]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
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

      -- external_product_id ile mevcut ürünü bul
      v_existing_id := NULL;
      IF v_external_id IS NOT NULL AND length(v_external_id) > 0 THEN
        SELECT id INTO v_existing_id
        FROM public.products
        WHERE store_id = p_store_id
          AND source_type = 'xml'
          AND external_product_id = v_external_id
        LIMIT 1;
      END IF;

      -- Slug üret
      v_slug := lower(regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'));
      v_slug := regexp_replace(v_slug, '\s+', '-', 'g');
      v_slug := trim(v_slug, '-');

      -- Kategori adını category_id'ye çevir
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

      -- Görselleri hazırla
      v_image_urls := COALESCE(v_product->'image_urls', '[]'::jsonb);
      IF jsonb_typeof(v_image_urls) != 'array' THEN
        v_image_urls := '[]'::jsonb;
      END IF;

      IF v_existing_id IS NOT NULL THEN
        -- MEVCUT ÜRÜNÜ GÜNCELLE
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
        -- YENİ ÜRÜN EKLE
        -- Benzersiz slug garantile
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

  -- Sıralama numaralarını güncelle
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

-- ============================================================================
-- 3. XML FEED URL TABLOSU
-- ============================================================================
-- Her tedarikçinin XML adresi ve son senkronize zamanı
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.xml_feeds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  feed_name TEXT NOT NULL CHECK (length(btrim(feed_name)) > 0),
  feed_url TEXT NOT NULL CHECK (length(btrim(feed_url)) > 0),
  feed_format TEXT NOT NULL DEFAULT 'generic' CHECK (feed_format IN ('generic', 'trendyol', 'hepsiburada', 'n11', 'google_merchant')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  last_sync_status TEXT DEFAULT 'pending' CHECK (last_sync_status IN ('pending', 'success', 'error')),
  last_sync_message TEXT,
  total_products_synced INT DEFAULT 0,
  product_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.xml_feeds IS 'Tedarikçi XML feed adresleri ve senkronizasyon durumları.';

CREATE INDEX IF NOT EXISTS idx_xml_feeds_store_id ON public.xml_feeds(store_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_xml_feeds_store_url ON public.xml_feeds(store_id, feed_url);

-- updated_at trigger
CREATE TRIGGER trg_xml_feeds_updated_at
  BEFORE UPDATE ON public.xml_feeds
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS politikaları
ALTER TABLE public.xml_feeds ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_xml_feeds" ON public.xml_feeds;
CREATE POLICY "owner_xml_feeds"
  ON public.xml_feeds FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = xml_feeds.store_id
        AND (s.user_id = auth.uid() OR s.edit_token IS NOT NULL)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = xml_feeds.store_id
        AND (s.user_id = auth.uid() OR s.edit_token IS NOT NULL)
    )
  );

-- ============================================================================
-- 4. YETKİLENDİRME
-- ============================================================================
REVOKE EXECUTE ON FUNCTION public.bulk_insert_products FROM public;
REVOKE EXECUTE ON FUNCTION public.upsert_products_from_xml FROM public;

GRANT EXECUTE ON FUNCTION public.bulk_insert_products TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_products_from_xml TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.xml_feeds TO authenticated;
