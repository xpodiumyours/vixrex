-- create_owner_session: düşen `extensions` şeması geri kondu.
--
-- SORUN (2026-08-27 canlıda ölçüldü):
-- 24 Ağustos'taki `20260824050000_fix_edit_token_perpetual_bearer_ttl.sql`
-- bu fonksiyonu yeniden yazarken search_path'i
--   'pg_catalog', 'public', 'extensions'  →  'pg_catalog', 'public'
-- yaptı. Fonksiyon gövdesi `gen_random_bytes()` çağırıyor; pgcrypto bu
-- projede `extensions` şemasında kurulu. Sonuç: HER çağrı
--   42883: function gen_random_bytes(integer) does not exist
-- ile düşüyordu — 3 gün boyunca sahip oturumu hiç üretilemedi.
--
-- Migration temiz göründü çünkü plpgsql gövdesi CREATE anında derlenmiyor;
-- hata ancak çağrı anında ortaya çıkıyor. (Aynı tuzak 26 Ağustos'ta
-- link_store_to_user'da da yaşandı.)
--
-- ETKİSİ:
--   - web: /api/owner-session/self → pano, ürün yönetimi, blog, randevu
--   - uygulama: vitrin_sahiplik_repository, owner_preview_service
--
-- Yalnız ayar değişiyor; fonksiyon gövdesine dokunulmuyor.

ALTER FUNCTION public.create_owner_session(text, text)
  SET search_path = pg_catalog, public, extensions;

DO $$
DECLARE
  v_ayar text;
BEGIN
  SELECT array_to_string(p.proconfig, ', ') INTO v_ayar
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'create_owner_session';

  IF v_ayar IS NULL OR v_ayar NOT LIKE '%extensions%' THEN
    RAISE EXCEPTION 'create_owner_session search_path düzelmedi: %', v_ayar;
  END IF;
END;
$$;
