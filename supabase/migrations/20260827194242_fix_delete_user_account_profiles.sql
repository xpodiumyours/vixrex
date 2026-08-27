-- delete_user_account: hesap silme HİÇ çalışmıyordu, profil kaydı engelliyordu.
--
-- SORUN (2026-08-27 canlıda gerçek hesapla ölçüldü):
-- `/app/hesap` ekranından "Hesabı Kalıcı Sil" 500 dönüyordu. Sebep:
-- `public.profiles.id` → `auth.users.id` yabancı anahtarı NO ACTION;
-- profil satırı silinmeden kullanıcı silinemiyor. Fonksiyon `profiles`
-- tablosuna hiç dokunmuyordu.
--
-- Ölçüm: 182 kullanıcının 182'sinin de profili vardı — yani bu düğme
-- hiç kimsede çalışmıyordu. Aynı RPC'yi uygulama da çağırıyor; oradaki
-- "hesabımı sil" de aynı şekilde ölüydü.
--
-- KVKK açısından kritik: kullanıcıya "hesabını sil" deniyor, silinmiyordu.
--
-- DEĞİŞENLER:
--   1. `public.profiles` satırı siliniyor (asıl düzeltme).
--   2. `public.owner_sessions` temizleniyor — yabancı anahtarı SET NULL
--      olduğu için silmeyi engellemiyordu, ama silinen hesabın oturum
--      kayıtları sahipsiz satır olarak birikiyordu.
--   3. `auth.uid()` boşsa açık hata veriliyor; öncesinde sessizce
--      hiçbir şey silmeden başarıyla dönüyordu.
--
-- Doğrulandı: test hesabı web'den silindi, `auth.users` ve
-- `public.profiles` 182 → 181; eski şifreyle giriş "e-posta veya şifre
-- hatalı" veriyor.

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
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED' USING errcode = 'P0001';
  END IF;

  SELECT slug INTO v_store_slug FROM public.stores WHERE user_id = v_user_id LIMIT 1;

  IF v_store_slug IS NOT NULL THEN
    DELETE FROM public.appointment_reschedule_requests
    WHERE appointment_id IN (SELECT id FROM public.appointments WHERE store_slug = v_store_slug);
    DELETE FROM public.appointments WHERE store_slug = v_store_slug;
    DELETE FROM public.booking_blocks WHERE store_slug = v_store_slug;
    DELETE FROM public.booking_settings WHERE store_slug = v_store_slug;
    DELETE FROM public.article_reports
    WHERE article_id IN (SELECT id FROM public.store_articles WHERE store_slug = v_store_slug);
    DELETE FROM public.store_articles WHERE store_slug = v_store_slug;
    DELETE FROM public.store_instagram_tokens
    WHERE connection_id IN (SELECT id FROM public.store_instagram_connections WHERE store_slug = v_store_slug);
    DELETE FROM public.store_instagram_imports WHERE store_slug = v_store_slug;
    DELETE FROM public.store_instagram_connections WHERE store_slug = v_store_slug;
    DELETE FROM public.legal_acceptance_events WHERE store_slug = v_store_slug;
    DELETE FROM public.vitrin_views WHERE store_slug = v_store_slug;
    DELETE FROM public.store_category_image_usage
    WHERE store_id IN (SELECT id FROM public.stores WHERE user_id = v_user_id);
    DELETE FROM public.stores WHERE user_id = v_user_id;
  END IF;

  DELETE FROM public.owner_sessions WHERE user_id = v_user_id;
  DELETE FROM public.profiles WHERE id = v_user_id;
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

ALTER FUNCTION public.delete_user_account() OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated, service_role;

-- Gövde gerçekten profili siliyor mu — CREATE etmek yetmez.
DO $$
DECLARE
  v_src text;
BEGIN
  SELECT p.prosrc INTO v_src
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'delete_user_account';

  IF position('public.profiles' in v_src) = 0 THEN
    RAISE EXCEPTION 'delete_user_account profiles satirini silmiyor';
  END IF;
END;
$$;
