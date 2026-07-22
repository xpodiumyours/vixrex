-- ============================================
-- Sprint 1: Kategori Gorsel Sablon Sistemi
-- 2025-07-03
-- ============================================

-- 1. Kategori gorsel sablonlari tablosu
CREATE TABLE IF NOT EXISTS category_image_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_key TEXT NOT NULL,
  category_label TEXT NOT NULL,
  image_type TEXT NOT NULL CHECK (image_type IN ('cover','logo_placeholder','gallery','product')),
  image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  title TEXT,
  description TEXT,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cat_templates_key ON category_image_templates(category_key);
CREATE INDEX IF NOT EXISTS idx_cat_templates_type ON category_image_templates(image_type);
CREATE INDEX IF NOT EXISTS idx_cat_templates_active ON category_image_templates(is_active);

CREATE TABLE IF NOT EXISTS store_category_image_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  category_key TEXT NOT NULL,
  images_used JSONB NOT NULL DEFAULT '[]',
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_store_cat_usage_store ON store_category_image_usage(store_id);

ALTER TABLE category_image_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_category_image_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "category_templates_select_public" ON category_image_templates;
CREATE POLICY "category_templates_select_public" 
  ON category_image_templates FOR SELECT TO anon, authenticated 
  USING (is_active = true);

DROP POLICY IF EXISTS "category_templates_admin_all" ON category_image_templates;
CREATE POLICY "category_templates_admin_all"
  ON category_image_templates FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "store_cat_usage_owner_select" ON store_category_image_usage;
CREATE POLICY "store_cat_usage_owner_select"
  ON store_category_image_usage FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM stores WHERE stores.id = store_id AND stores.user_id = auth.uid()));

DROP POLICY IF EXISTS "store_cat_usage_owner_insert" ON store_category_image_usage;
CREATE POLICY "store_cat_usage_owner_insert"
  ON store_category_image_usage FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM stores WHERE stores.id = store_id AND stores.user_id = auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'category-templates') THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('category-templates', 'category-templates', true);
  END IF;
END $$;

DROP POLICY IF EXISTS "category_templates_storage_public" ON storage.objects;
CREATE POLICY "category_templates_storage_public" 
  ON storage.objects FOR SELECT TO anon, authenticated 
  USING (bucket_id = 'category-templates');

-- ============================================
-- RPC: apply_category_template
-- Kategori sablonunu vitrine uygular
-- ============================================

CREATE OR REPLACE FUNCTION apply_category_template(
  p_store_id UUID,
  p_category_key TEXT,
  p_fill_cover BOOLEAN DEFAULT true,
  p_fill_logo BOOLEAN DEFAULT true,
  p_fill_gallery BOOLEAN DEFAULT true,
  p_fill_products BOOLEAN DEFAULT true
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '{}';
  v_image_row RECORD;
  v_current_cover TEXT;
  v_current_logo TEXT;
  v_current_gallery JSONB;
  v_current_products JSONB;
  v_gallery_items JSONB := '[]'::JSONB;
  v_template_products JSONB := '[]'::JSONB;
  v_applied_count INT := 0;
BEGIN
  -- Mevcut store verisini cek
  SELECT shelf_image_url, logo_url, gallery_items, products
  INTO v_current_cover, v_current_logo, v_current_gallery, v_current_products
  FROM stores WHERE id = p_store_id;

  -- Kapak gorseli
  IF p_fill_cover THEN
    SELECT image_url INTO v_image_row
    FROM category_image_templates
    WHERE category_key = p_category_key AND image_type = 'cover' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_cover IS NULL OR v_current_cover = '') THEN
      UPDATE stores SET shelf_image_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"cover": true}'::JSONB;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  -- Logo
  IF p_fill_logo THEN
    SELECT image_url INTO v_image_row
    FROM category_image_templates
    WHERE category_key = p_category_key AND image_type = 'logo_placeholder' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_logo IS NULL OR v_current_logo = '') THEN
      UPDATE stores SET logo_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"logo": true}'::JSONB;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  -- Galeri
  IF p_fill_gallery THEN
    IF v_current_gallery IS NULL OR jsonb_array_length(v_current_gallery) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'imageUrl', image_url,
          'title', COALESCE(title, 'Gorsel')
        ) ORDER BY display_order
      )
      INTO v_gallery_items
      FROM category_image_templates
      WHERE category_key = p_category_key AND image_type = 'gallery' AND is_active = true;

      IF v_gallery_items IS NOT NULL AND jsonb_array_length(v_gallery_items) > 0 THEN
        UPDATE stores SET gallery_items = v_gallery_items WHERE id = p_store_id;
        v_result := v_result || '{"gallery": true}'::JSONB;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  -- Urun sablonlari
  IF p_fill_products THEN
    IF v_current_products IS NULL OR jsonb_array_length(v_current_products) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', gen_random_uuid(),
          'name', COALESCE(title, 'Urun'),
          'description', '',
          'price', '',
          'imageUrls', jsonb_build_array(image_url),
          'isVisible', true,
          'source', 'category_template'
        ) ORDER BY display_order
      )
      INTO v_template_products
      FROM category_image_templates
      WHERE category_key = p_category_key AND image_type = 'product' AND is_active = true;

      IF v_template_products IS NOT NULL AND jsonb_array_length(v_template_products) > 0 THEN
        UPDATE stores SET products = v_template_products WHERE id = p_store_id;
        v_result := v_result || '{"products": true}'::JSONB;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  -- Kullanim kaydi
  IF v_applied_count > 0 THEN
    INSERT INTO store_category_image_usage (store_id, category_key, images_used)
    VALUES (
      p_store_id,      p_category_key,
      COALESCE(
        (SELECT jsonb_agg(image_url)
         FROM category_image_templates
         WHERE category_key = p_category_key AND is_active = true),
        '[]'::JSONB
      )
    )
    ON CONFLICT (store_id) DO UPDATE SET
      category_key = EXCLUDED.category_key,
      images_used = EXCLUDED.images_used,
      applied_at = now();
  END IF;

  RETURN v_result || jsonb_build_object(
    'success', v_applied_count > 0,
    'image_count', (SELECT COUNT(*) FROM category_image_templates WHERE category_key = p_category_key AND is_active = true)
  );
END;
$$;


-- ============================================
-- Unique constraint for ON CONFLICT in RPC
-- ============================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_store_cat_usage_store_unique
  ON store_category_image_usage(store_id);
