BEGIN;

-- Kiralık vitrinler demo değil, gerçek işletme vitrinleridir (Casper kararı,
-- 2026-09-28): randevu kapalıysa açılır. Varsayılan olarak satır olmayan
-- vitrinlerde is_enabled=false olduğundan randevu sayfası 404 dönüyordu.
-- Sadece kiralik- önekli yayındaki vitrinler etkilenir; mevcut satırlarda
-- is_enabled=true yapılır, diğer alanlara (working_hours vb.) dokunulmaz.
-- Panelinden kapatmak isteyen sahip owner-booking-settings API'siyle
-- dilediği an kapatabilir.

INSERT INTO public.booking_settings (store_slug, is_enabled)
SELECT s.slug, true
FROM public.stores s
WHERE s.slug LIKE 'kiralik-%'
  AND s.is_published = true
  AND NOT EXISTS (
    SELECT 1 FROM public.booking_settings b
    WHERE b.store_slug = s.slug
  );

UPDATE public.booking_settings b
SET is_enabled = true,
    updated_at = now()
WHERE b.store_slug LIKE 'kiralik-%'
  AND COALESCE(b.is_enabled, false) = false;

COMMIT;
