-- ============================================================================
-- Products tablosuna brand ve sku kolonları ekler
-- ============================================================================

-- brand kolonu
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS brand TEXT;

-- sku kolonu
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS sku TEXT;

-- brand ve sku için index
CREATE INDEX IF NOT EXISTS idx_products_brand ON public.products (brand) WHERE brand IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_sku ON public.products (sku) WHERE sku IS NOT NULL;
