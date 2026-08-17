-- ============================================================================
-- Vitrin bazlı premium durumu — sahip için güvenli okuma (PR #6)
-- ============================================================================
-- NEDEN VAR
-- Premium VİTRİNE bağlıdır (PR #1: stores.premium_expires_at) ve
-- premium_expires_at istemciye SELECT ile açılmaz (anon/authenticated
-- doğrudan göremez — müşteri vitrini esnafın ödeme durumunu görmez).
-- Esnafın KENDİ vitrininin premium durumunu görmesi gereken tek yer
-- (Flutter uygulaması) bu RPC'dir: edit_token'ı kanıt olarak ister,
-- create_owner_session ile AYNI yetkilendirme desenini kullanır
-- (20260804001000_add_owner_sessions.sql).
--
-- GÜVENLİK
-- - Security definer + search_path sabitli.
-- - Yanlış edit_token'la premium bilgisi ASLA dönmez: yetki yoksa
--   OWNER_AUTHORIZATION_REQUIRED (fail-closed), vitrin yoksa
--   STORE_NOT_FOUND — yanıt, vitrinin var olup olmadığını sızdırmaz
--   (create_owner_session ile aynı davranış).
-- - anon/authenticated'e AÇIK ama BİLEREK: edit_token gizli anahtar
--   (possession proof) — create_owner_session ile aynı güven modeli.
--   public'e kapalı.
-- - İstemci premium YAZAMAZ (purchasePremium kaldırıldı, PR #6); bu
--   fonksiyon yalnız OKUR.
-- ============================================================================

create or replace function public.get_store_premium_status(
  p_slug text,
  p_edit_token text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_store_id uuid;
  v_premium_expires_at timestamptz;
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;

  select id, premium_expires_at
  into v_store_id, v_premium_expires_at
  from public.stores
  where slug = v_slug;

  if v_store_id is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  -- Sahiplik kanıtı: oturum açmış kullanıcı vitrinin sahibi VEYA
  -- edit_token eşleşiyor (create_owner_session ile aynı iki yol).
  if not (
    (
      v_user_id is not null
      and exists (
        select 1 from public.stores
        where id = v_store_id and user_id = v_user_id
      )
    )
    or (
      v_token <> ''
      and exists (
        select 1 from public.stores
        where id = v_store_id and edit_token = v_token
      )
    )
  ) then
    raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'store_id', v_store_id,
    'is_premium',
      v_premium_expires_at is not null and v_premium_expires_at > now(),
    'premium_expires_at', v_premium_expires_at
  );
end;
$$;

comment on function public.get_store_premium_status(text, text) is
  'Vitrin sahibinin kendi premium durumunu okuması. edit_token veya sahip
   oturumu (auth.uid) kanıtı ister; yetkisiz istekte premium bilgisi
   dönmez (OWNER_AUTHORIZATION_REQUIRED). Yalnız okur — premium yazma
   yalnız doğrulanmış PayTR callback''indedir.';

revoke execute on function public.get_store_premium_status(text, text)
  from public;
grant execute on function public.get_store_premium_status(text, text)
  to anon, authenticated;
