-- Fix: delete_user_account artık tüm ilişkili verileri siliyor.
-- Önceki versiyon sadece stores ve auth.users'i siliyordu.

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_store_slug TEXT;
BEGIN
  -- Kullanıcının store'unu bul
  SELECT slug INTO v_store_slug
  FROM public.stores
  WHERE user_id = v_user_id
  LIMIT 1;

  -- 1. Appointment ilişkili veriler (önce alt tablolar)
  IF v_store_slug IS NOT NULL THEN
    -- Reschedule request'leri sil (önce bu)
    DELETE FROM public.appointment_reschedule_requests
    WHERE appointment_id IN (
      SELECT id FROM public.appointments WHERE store_slug = v_store_slug
    );

    -- Appointment'ları sil
    DELETE FROM public.appointments WHERE store_slug = v_store_slug;

    -- Booking ayarları ve blokları
    DELETE FROM public.booking_blocks WHERE store_slug = v_store_slug;
    DELETE FROM public.booking_settings WHERE store_slug = v_store_slug;

    -- Blog yazıları ve bildirimleri
    DELETE FROM public.article_reports
    WHERE article_id IN (
      SELECT id FROM public.store_articles WHERE store_slug = v_store_slug
    );
    DELETE FROM public.store_articles WHERE store_slug = v_store_slug;

    -- Instagram bağlantıları ve token'ları
    DELETE FROM public.store_instagram_tokens
    WHERE connection_id IN (
      SELECT id FROM public.store_instagram_connections WHERE store_slug = v_store_slug
    );
    DELETE FROM public.store_instagram_imports WHERE store_slug = v_store_slug;
    DELETE FROM public.store_instagram_connections WHERE store_slug = v_store_slug;

    -- Yasal kabul olayları
    DELETE FROM public.legal_acceptance_events WHERE store_slug = v_store_slug;

    -- Görüntülenme kayıtları
    DELETE FROM public.vitrin_views WHERE store_slug = v_store_slug;

    -- Kategori görsel kullanımı
    DELETE FROM public.store_category_image_usage
    WHERE store_id IN (
      SELECT id FROM public.stores WHERE user_id = v_user_id
    );

    -- Store'u sil (FK CASCADE çoğu şeyi silecek ama garanti olsun)
    DELETE FROM public.stores WHERE user_id = v_user_id;
  END IF;

  -- 2. Kullanıcının auth hesabını sil
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

-- Yetkiyi koru
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM public;
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

NOTIFY pgrst, 'reload schema';
