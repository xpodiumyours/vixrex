-- ============================================================================
-- XML Feed Desteği Genişletmesi: brand, barcode, vat_rate, variants
--
-- Mevcut products tablosuna yeni sütunlar ekler:
-- - brand: Ürün markası
-- - barcode: Barkod (GTIN/EAN)
-- - vat_rate: KDV oranı (%)
-- - variants: Varyant bilgileri (JSON array)
-- ============================================================================

-- ============================================================================
-- 1. YENİ SÜTUNLAR EKLE
-- ============================================================================
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS brand TEXT,
ADD COLUMN IF NOT EXISTS barcode TEXT,
ADD COLUMN IF NOT EXISTS vat_rate INT CHECK (vat_rate IS NULL OR (vat_rate >= 0 AND vat_rate <= 100)),
ADD COLUMN IF NOT EXISTS variants JSONB DEFAULT '[]'::jsonb
  CHECK (jsonb_typeof(variants) = 'array');

COMMENT ON COLUMN public.products.brand IS 'Ürün markası (ör: Nike, Apple)';
COMMENT ON COLUMN public.products.barcode IS 'Barkod numarası (GTIN/EAN/UPC)';
COMMENT ON COLUMN public.products.vat_rate IS 'KDV oranı yüzdesi (0-100)';
COMMENT ON COLUMN public.products.variants IS 'Ürün varyantları JSON array [{name, sku, price, stock, attributes}]';

-- ============================================================================
-- 2. INDEX EKLE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_products_brand ON public.products(brand) WHERE brand IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode) WHERE barcode IS NOT NULL;

-- ============================================================================
-- 3. UPSERT RPC'Nİ GÜNCELLE (Yeni alanları destekle)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.upsert_products_from_xml(
  p_store_id UUID,
  p_edit_token TEXT,
  p_products JSONB
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

      v_existing_id := NULL;
      IF v_external_id IS NOT NULL AND length(v_external_id) > 0 THEN
        SELECT id INTO v_existing_id
        FROM public.products
        WHERE store_id = p_store_id
          AND source_type = 'xml'
          AND external_product_id = v_external_id
        LIMIT 1;
      END IF;

      v_slug := lower(regexp_replace(v_name, '[^a-zA-Z0-9\s-]', '', 'g'));
      v_slug := regexp_replace(v_slug, '\s+', '-', 'g');
      v_slug := trim(v_slug, '-');

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

      v_image_urls := COALESCE(v_product->'image_urls', '[]'::jsonb);
      IF jsonb_typeof(v_image_urls) != 'array' THEN
        v_image_urls := '[]'::jsonb;
      END IF;

      IF v_existing_id IS NOT NULL THEN
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
          brand = COALESCE(v_product->>'brand', brand),
          barcode = COALESCE(v_product->>'barcode', barcode),
          vat_rate = CASE
            WHEN v_product ? 'vat_rate' THEN (v_product->>'vat_rate')::INT
            ELSE vat_rate
          END,
          variants = CASE
            WHEN v_product ? 'variants' THEN v_product->'variants'
            ELSE variants
          END,
          last_synced_at = now()
        WHERE id = v_existing_id;

        v_updated := v_updated + 1;
      ELSE
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
          brand, barcode, vat_rate, variants,
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
          v_product->>'brand',
          v_product->>'barcode',
          (v_product->>'vat_rate')::INT,
          COALESCE(v_product->'variants', '[]'::jsonb),
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
