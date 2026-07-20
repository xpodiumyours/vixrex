-- ============================================================================
-- Aşama 1: İlişkisel ürün altyapısı (Düzeltilmiş v2)
--
-- Bu migration mevcut stores tablosuna ve verilerine DOKUNMAZ.
-- Sadece 2 yeni tablo + 1 yeni sütun ekler.
--
-- NOT: Mevcut ProductCategory JSON yapısında slug alanı yoktur.
--      Sadece id, name, sortOrder alanları bulunur.
--      slug, name alanından otomatik üretilecektir.
--
-- NOT: edit-token ürün yazma RPC'leri bu aşamada oluşturulmaz.
--      Aşama 4'te ProductRepository/ProductService oluşturulurken
--      mevcut edit-token mimarisine uygun RPC'ler yazılacaktır.
-- ============================================================================

-- ============================================================================
-- 1. ÜRÜN KATEGORİLERİ TABLOSU
-- ============================================================================
-- slug nullable: Mevcut JSON'da slug alanı olmadığı için name'den üretilecek
CREATE TABLE IF NOT EXISTS public.product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (length(btrim(name)) > 0),
  slug TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (store_id, slug)
);

COMMENT ON TABLE public.product_categories IS 'Mağazaya ait ürün kategorileri. slug name alanından otomatik üretilir.';

-- ============================================================================
-- 2. ÜRÜNLER TABLOSU
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,

  -- Kaynak bilgisi (XML, OCR, manuel, vb.)
  source_type TEXT NOT NULL DEFAULT 'manual',
  external_product_id TEXT,

  -- Ürün bilgileri
  name TEXT NOT NULL CHECK (length(btrim(name)) > 0),
  slug TEXT NOT NULL CHECK (length(btrim(slug)) > 0),
  description TEXT,

  -- Fiyat
  price_amount NUMERIC CHECK (price_amount IS NULL OR price_amount >= 0),
  price_text TEXT,
  currency TEXT NOT NULL DEFAULT 'TRY',

  -- Stok
  stock_quantity INT CHECK (stock_quantity IS NULL OR stock_quantity >= 0),
  stock_status TEXT,

  -- Görseller (JSON array olmalı)
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb
    CHECK (jsonb_typeof(image_urls) = 'array'),

  -- Ek veri (JSON object olmalı)
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
    CHECK (jsonb_typeof(metadata) = 'object'),

  -- SEO
  seo_title TEXT,
  seo_description TEXT,

  -- Durum
  is_visible BOOLEAN NOT NULL DEFAULT true,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,

  -- Zaman damgaları
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_synced_at TIMESTAMPTZ,

  -- Unique constraint
  UNIQUE (store_id, slug)
);

COMMENT ON TABLE public.products IS 'İlişkisel ürün tablosu. XML, OCR veya manuel eklenebilir.';

-- external_product_id doluysa benzersiz olmalı (partial index)
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_external_unique
  ON public.products (store_id, source_type, external_product_id)
  WHERE external_product_id IS NOT NULL AND external_product_id != '';

-- ============================================================================
-- 3. İNDEX'LER
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_products_store_id ON public.products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_store_active ON public.products(store_id, is_active);
CREATE INDEX IF NOT EXISTS idx_products_store_visible ON public.products(store_id, is_visible);
CREATE INDEX IF NOT EXISTS idx_products_source_type ON public.products(source_type);
CREATE INDEX IF NOT EXISTS idx_products_sort ON public.products(store_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_product_categories_store_id ON public.product_categories(store_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_sort ON public.product_categories(store_id, sort_order);

-- ============================================================================
-- 4. STORES TABLOSUNA YENİ SÜTUN
-- ============================================================================
ALTER TABLE public.stores
ADD COLUMN IF NOT EXISTS product_storage_version SMALLINT NOT NULL DEFAULT 1;

COMMENT ON COLUMN public.stores.product_storage_version IS
  'Ürün verisi saklama versiyonu. 1=eski JSON, 2=yeni products tablosu.';

-- ============================================================================
-- 5. TRIGGER FONKSİYONLARI
-- ============================================================================

-- category_id doğrulama: Aynı mağazaya ait kategori olmalı
CREATE OR REPLACE FUNCTION public.validate_product_category()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.category_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.product_categories pc
      WHERE pc.id = NEW.category_id
        AND pc.store_id = NEW.store_id
    ) THEN
      RAISE EXCEPTION 'CATEGORY_NOT_IN_SAME_STORE: category_id aynı mağazaya ait olmalıdır';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 6. TRIGGER KAYITLARI
-- ============================================================================

-- products updated_at: Mevcut set_updated_at() kullanılır
DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- product_categories updated_at
DROP TRIGGER IF EXISTS trg_product_categories_updated_at ON public.product_categories;
CREATE TRIGGER trg_product_categories_updated_at
  BEFORE UPDATE ON public.product_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- category_id doğrulama
DROP TRIGGER IF EXISTS trg_validate_product_category ON public.products;
CREATE TRIGGER trg_validate_product_category
  BEFORE INSERT OR UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.validate_product_category();

-- ============================================================================
-- 7. RLS POLİTİKALARI
-- ============================================================================

-- ---------------------------------------------------------------------------
-- PRODUCTS
-- ---------------------------------------------------------------------------
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_read_products" ON public.products;
DROP POLICY IF EXISTS "auth_read_products" ON public.products;
DROP POLICY IF EXISTS "owner_select_products" ON public.products;
DROP POLICY IF EXISTS "owner_insert_products" ON public.products;
DROP POLICY IF EXISTS "owner_update_products" ON public.products;
DROP POLICY IF EXISTS "owner_delete_products" ON public.products;

-- Anon: Yayınlanmış mağazaların aktif VE görünür ürünlerini okuyabilir
CREATE POLICY "anon_read_products"
  ON public.products FOR SELECT TO anon
  USING (
    is_active = true
    AND is_visible = true
    AND EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.is_published = true
    )
  );

-- Authenticated: Yayınlanmış mağazaların aktif VE görünür ürünlerini okuyabilir
CREATE POLICY "auth_read_products"
  ON public.products FOR SELECT TO authenticated
  USING (
    is_active = true
    AND is_visible = true
    AND EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.is_published = true
    )
  );

-- Mağaza sahibi: Yayın durumundan bağımsız TÜM ürünlerini okuyabilir
CREATE POLICY "owner_select_products"
  ON public.products FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = auth.uid()
    )
  );

-- Mağaza sahibi: Kendi ürünlerini ekleyebilir
CREATE POLICY "owner_insert_products"
  ON public.products FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = auth.uid()
    )
  );

-- Mağaza sahibi: Kendi ürünlerini güncelleyebilir
CREATE POLICY "owner_update_products"
  ON public.products FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = auth.uid()
    )
  );

-- Mağaza sahibi: Kendi ürünlerini silebilir
CREATE POLICY "owner_delete_products"
  ON public.products FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = products.store_id
        AND s.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- PRODUCT CATEGORIES
-- ---------------------------------------------------------------------------
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_read_categories" ON public.product_categories;
DROP POLICY IF EXISTS "auth_read_categories" ON public.product_categories;
DROP POLICY IF EXISTS "owner_select_categories" ON public.product_categories;
DROP POLICY IF EXISTS "owner_insert_categories" ON public.product_categories;
DROP POLICY IF EXISTS "owner_update_categories" ON public.product_categories;
DROP POLICY IF EXISTS "owner_delete_categories" ON public.product_categories;

-- Anon: Yayınlanmış mağazaların aktif kategorilerini okuyabilir
CREATE POLICY "anon_read_categories"
  ON public.product_categories FOR SELECT TO anon
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.is_published = true
    )
  );

-- Authenticated: Yayınlanmış mağazaların aktif kategorilerini okuyabilir
CREATE POLICY "auth_read_categories"
  ON public.product_categories FOR SELECT TO authenticated
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.is_published = true
    )
  );

-- Mağaza sahibi: Yayın durumundan bağımsız TÜM kategorilerini okuyabilir
CREATE POLICY "owner_select_categories"
  ON public.product_categories FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = auth.uid()
    )
  );

-- Mağaza sahibi: Kendi kategorilerini ekleyebilir
CREATE POLICY "owner_insert_categories"
  ON public.product_categories FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = auth.uid()
    )
  );

-- Mağaza sahibi: Kendi kategorilerini güncelleyebilir
CREATE POLICY "owner_update_categories"
  ON public.product_categories FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = auth.uid()
    )
  );

-- Mağaza sahibi: Kendi kategorilerini silebilir
CREATE POLICY "owner_delete_categories"
  ON public.product_categories FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores s
      WHERE s.id = product_categories.store_id
        AND s.user_id = auth.uid()
    )
  );

-- ============================================================================
-- 8. GRANT KOMUTLARI
-- ============================================================================
GRANT SELECT ON public.products TO anon;
GRANT SELECT ON public.product_categories TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_categories TO authenticated;
