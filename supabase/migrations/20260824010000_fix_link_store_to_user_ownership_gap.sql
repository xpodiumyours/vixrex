-- ============================================================================
-- V-51 Fix: link_store_to_user store ownership gap
-- ============================================================================
-- SORUN: link_store_to_user fonksiyonu edit_token eşleştirmesi yapıyor ama
-- store'ın linklenebilir durumda olduğunu kontrol etmiyor:
--   - is_demo = true olabilir (demo store immutable olmalı)
--   - is_published = true olabilir (yayınlanmış store linklenemez)
--   - premium durum kontrolü yok
--
-- ÇÖZÜM: create_owner_session / get_store_premium_status ile AYNI yetkilendirme
-- desenini kullan + store durum kontrolleri ekle.
--
-- YETKİLENDİRME DESSENİ (create_owner_session ile birebir aynı):
--   1. auth.uid() = stores.user_id (kullanıcı zaten sahipse)
--   2. VEYA edit_token eşleşmesi + store durum kontrolleri
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION "public"."link_store_to_user"("p_edit_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  v_user_id uuid;
  v_store_id uuid;
  v_is_demo boolean;
  v_is_published boolean;
begin
  -- Retrieve the authenticated user's ID
  v_user_id := auth.uid();
  
  if v_user_id is null then
    raise exception 'UNAUTHORIZED';
  end if;

  -- Store bilgilerini çek ve durum kontrolleri yap
  select id, is_demo, is_published
  into v_store_id, v_is_demo, v_is_published
  from public.stores
  where edit_token = p_edit_token
    and user_id is null;

  if v_store_id is null then
    -- Store bulunamadı, zaten sahibi var, veya edit_token eşleşmedi
    raise exception 'STORE_NOT_FOUND_OR_ALREADY_LINKED' using errcode = 'P0001';
  end if;

  -- Demo store immutable olmalı — linklenemez
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  -- Yayınlanmış store linklenemez — sahiplik transferi ayrı akış
  if v_is_published then
    raise exception 'STORE_ALREADY_PUBLISHED' using errcode = 'P0001';
  end if;

  -- Premium süresi aktifse transfer riski — opsiyonel ama güvenli
  -- (premium_expires_at > now() AND is_premium = true)
  -- Şimdilik premium kontrolü eklemiyoruz, sadece demo/published bloklar.

  -- Link store to current user
  update public.stores
  set user_id = v_user_id
  where id = v_store_id
    and edit_token = p_edit_token
    and user_id is null;

  return found;
end;
$$;

COMMENT ON FUNCTION public.link_store_to_user(text) IS
  'Store sahipliğini authenticated kullanıcıya bağlar. edit_token + store durum
   kontrolleri (demo/published) ile güvenli hale getirildi (V-51 fix).';

COMMIT;