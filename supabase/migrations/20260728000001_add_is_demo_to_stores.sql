-- Migration: is_demo kolonu ekle
-- Kiralık Vitrin örnekleri bu flag ile işaretlenir.
-- is_demo = true olan mağazalar Keşfet'te "KİRALIK" etiketi gösterir.

ALTER TABLE public.stores
  ADD COLUMN IF NOT EXISTS is_demo BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.stores.is_demo IS
  'true ise bu mağaza Kiralık Vitrin örneğidir. Keşfet ekranında KİRALIK etiketi gösterilir.';

notify pgrst, 'reload schema';
