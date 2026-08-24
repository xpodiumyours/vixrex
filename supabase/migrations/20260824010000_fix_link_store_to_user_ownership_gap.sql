-- ============================================================================
-- V-51 Fix: link_store_to_user store ownership gap
-- ============================================================================
-- SORUN: link_store_to_user fonksiyonu edit_token eşleştirmesi yapıyor ama
-- store'ın linklenebilir durumda olduğunu kontrol etmiyor:
--   - is_demo = true olan kaynak vitrinin sahipliği alınabilir
--
-- ÇÖZÜM: Token kontrolü ve demo engelini tek atomik UPDATE içinde uygula.
-- Yayınlanmış vitrini engelleme: giriş sonrası mevcut vitrini hesaba bağlama
-- akışı özellikle yayınlanmış vitrinlerde de çalışmalıdır.
--
-- YETKİLENDİRME DESENİ:
--   1. authenticated kullanıcı zorunlu
--   2. en az 24 karakterlik edit_token + sahipsiz + demo olmayan vitrin
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION "public"."link_store_to_user"("p_edit_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_user_id uuid;
begin
  -- Retrieve the authenticated user's ID
  v_user_id := auth.uid();
  
  if v_user_id is null then
    raise exception 'UNAUTHORIZED';
  end if;

  if pg_catalog.length(pg_catalog.btrim(pg_catalog.coalesce(p_edit_token, ''))) < 24 then
    return false;
  end if;

  -- Kontrol ve sahiplik ataması aynı statement'ta: eşzamanlı iki istekte
  -- yalnız biri user_id IS NULL koşulunu sağlayabilir.
  update public.stores
  set user_id = v_user_id
  where edit_token = pg_catalog.btrim(p_edit_token)
    and user_id is null
    and is_demo = false;

  return found;
end;
$$;

COMMENT ON FUNCTION public.link_store_to_user(text) IS
  'Sahipsiz ve demo olmayan vitrini edit_token ile authenticated kullanıcıya atomik olarak bağlar.';

COMMIT;
