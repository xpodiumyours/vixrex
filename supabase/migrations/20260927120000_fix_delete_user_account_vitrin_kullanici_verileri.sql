-- delete_user_account: Vitrin Ölçer v2 kullanici verileri silme zincirine bagliydi.
--
-- SORUN (2026-09-27 Checkup turu): #563'te eklenen uc tablo silme fonksiyonunda
-- yoktu. "Hesabi Kalici Sil" calisiyordu ama kullanicinin baska vitrinlerde
-- biraktigi veriler kaliyordu (KVKK acisindan acik):
--   public.vitrin_product_comments.user_id   -> dogrudan kullanici verisi
--   public.vitrin_product_likes.user_id      -> dogrudan kullanici verisi
--   public.vitrin_engagement_events.session_key -> kalici kullanici icin
--     'u:' || sha256(user_id) aktor anahtari; kullanici kaydi silinse de
--     kimlik biliniyorsa yeniden eslestirilebilen turetilmis kimliktir.
--
-- Kendi vitrinindeki satirlar stores silinince cascade ile zaten gidiyor
-- (vitrin_product_likes/comments store_id -> stores ON DELETE CASCADE,
-- vitrin_engagement_events store_id -> stores ON DELETE CASCADE). Eksik
-- kalan, kullanicinin BASKASININ vitrinlerinde biraktigi veriydi.
--
-- OLCEK (2026-09-27): yorum/beğeni/etkileşim silinince diger vitrinlerin
-- Olcer sayimlari ve yorum sayilari bu kullanici kadar azalir — beklenen
-- davranis budur, regresyon degildir.
--
-- Bu dosya canliya henuz uygulanmamistir; uygulama yolu:
--   git push origin migration-uygula-toplu/20260927120000_fix_delete_user_account_vitrin_kullanici_verileri.sql

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

  DELETE FROM public.vitrin_product_comments WHERE user_id = v_user_id;
  DELETE FROM public.vitrin_product_likes
  WHERE user_id = v_user_id
     OR actor_key = 'u:' || encode(sha256(v_user_id::text::bytea), 'hex');
  DELETE FROM public.vitrin_engagement_events
  WHERE session_key = 'u:' || encode(sha256(v_user_id::text::bytea), 'hex');

  DELETE FROM public.owner_sessions WHERE user_id = v_user_id;
  DELETE FROM public.profiles WHERE id = v_user_id;
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

ALTER FUNCTION public.delete_user_account() OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated, service_role;

-- Govebe gercekten yeni tablolari siliyor mu — CREATE etmek yetmez.
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
  IF position('vitrin_product_comments' in v_src) = 0
     OR position('vitrin_product_likes' in v_src) = 0
     OR position('vitrin_engagement_events' in v_src) = 0 THEN
    RAISE EXCEPTION 'delete_user_account vitrin olcer kullanici verilerini silmiyor';
  END IF;
END;
$$;
