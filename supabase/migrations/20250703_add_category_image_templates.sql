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
