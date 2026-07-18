-- ============================================================================
-- VixRex M3 — Hesap Silme ve Storage Policy
-- ============================================================================

-- 1. HESAP SİLME FONKSİYONU
-- JWT doğrular, idempotent silme yapar
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_store_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  -- Mağaza bilgisini al
  SELECT id INTO v_store_id FROM public.stores WHERE user_id = v_user_id;

  -- Storage nesnelerini sil (eğer store varsa)
  IF v_store_id IS NOT NULL THEN
    -- Shelf images
    DELETE FROM storage.objects
    WHERE bucket_id = 'shelf-images'
      AND name LIKE v_store_id || '%';
  END IF;

  -- İlişkili verileri sil (idempotent — zaten silinmişse sorun yok)
  DELETE FROM public.appointments WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.booking_settings WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.booking_blocks WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.store_articles WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.store_instagram_imports WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.store_instagram_tokens WHERE connection_id IN (SELECT id FROM public.store_instagram_connections WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id));
  DELETE FROM public.store_instagram_connections WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.vitrin_views WHERE store_slug IN (SELECT slug FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.store_category_image_usage WHERE store_id IN (SELECT id FROM public.stores WHERE user_id = v_user_id);
  DELETE FROM public.stores WHERE user_id = v_user_id;

  -- Auth kullanıcısını sil
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- 2. STORAGE POLICY — Upload ticket ile yükleme
-- Bu policy yükleme iznini düzenler
-- Gerçek upload ticket sistemi M3'ün sonraki aşamasında eklenecek
