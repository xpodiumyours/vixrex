-- Migration: Add Atmosfer store theme and product badge/discount fields
-- Created: 2026-07-27

ALTER TABLE public.stores
  ADD COLUMN IF NOT EXISTS theme_preset TEXT DEFAULT 'default',
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS rating_score NUMERIC DEFAULT 4.9,
  ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 128,
  ADD COLUMN IF NOT EXISTS featured_banner_title TEXT,
  ADD COLUMN IF NOT EXISTS featured_banner_description TEXT,
  ADD COLUMN IF NOT EXISTS featured_banner_image_url TEXT,
  ADD COLUMN IF NOT EXISTS featured_banner_price_text TEXT;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS old_price_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS badge_tag TEXT;

COMMENT ON COLUMN public.stores.theme_preset IS 'Vitrin tema stili (default, atmosfer vb.)';
COMMENT ON COLUMN public.products.old_price_amount IS 'Ürünün çizili eski fiyatı';
COMMENT ON COLUMN public.products.badge_tag IS 'Ürün rozeti (-31%, Yeni, Özel Tasarım vb.)';
