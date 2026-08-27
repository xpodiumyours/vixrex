-- create_owner_session: 24 Ağustos'ta kaybedilen doğru gövde geri getirildi.
--
-- SORUN (2026-08-27 canlıda ölçüldü, iki katmanlı):
--
-- `20260824050000_fix_edit_token_perpetual_bearer_ttl.sql` bu fonksiyonu
-- V-15 (edit_token TTL) için yeniden yazarken, 11 Ağustos'ta kurulan
-- `_create_owner_session_core` delegasyonunu ezip ESKİ bir gövdeyi geri
-- getirdi. O gövde bugünkü şemayla uyumsuz:
--
--   1. search_path'ten `extensions` düşmüştü → gen_random_bytes bulunamıyordu
--      (20260827155458 ile düzeltildi).
--   2. `owner_sessions` tablosuna `code` sütununa yazıyor — o sütun YOK,
--      tabloda `code_hash` var. Ayrıca `ON CONFLICT (store_id)` kullanıyor
--      (öyle bir kısıt yok) ve satırı daha üretirken `consumed_at = now()`
--      ile tüketilmiş işaretliyordu.
--   3. `user_id` hiç yazılmıyordu — kalıcı hesap sahipliği (26 Ağustos)
--      bu sütuna dayanıyor.
--
-- Sonuç: 24 Ağustos'tan beri sahip oturumu HİÇ üretilemedi. Etkilenenler:
--   - web: /api/owner-session/self → pano, ürün yönetimi, blog, randevu
--   - uygulama: vitrin_sahiplik_repository, owner_preview_service
--
-- Migration temiz göründü çünkü plpgsql gövdesi CREATE anında derlenmiyor.
--
-- ÇÖZÜM: fonksiyon yeniden çekirdeğe delege ediyor (11 Ağustos'taki hâli).
-- 24 Ağustos'un ASIL amacı olan V-15 kontrolü kaybolmasın diye, edit_token
-- son kullanma kontrolü çekirdeğin token dalına ekleniyor. Hesabıyla
-- sahiplenmiş kullanıcı bu kontrole takılmaz — kalıcı sahiplik süresizdir.

-- ── 1) Çekirdek: token dalına son kullanma kontrolü ──────────────────────
CREATE OR REPLACE FUNCTION public._create_owner_session_core(
  p_slug text,
  p_edit_token text,
  p_assistant_handoff jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
declare
  v_user_id uuid := auth.uid();
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_store_id uuid;
  v_is_demo boolean;
  v_code text;
  v_code_hash text;
  v_expires_at timestamptz;
  v_handoff jsonb;
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;

  select id, is_demo
  into v_store_id, v_is_demo
  from public.stores
  where slug = v_slug;

  if v_store_id is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

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
        -- V-15 (20260824050000'in korunan amacı): süresi dolmuş edit_token
        -- ile oturum açılamaz. Hesap sahipliği dalı bundan etkilenmez.
        select 1 from public.stores
        where id = v_store_id
          and edit_token = v_token
          and (edit_token_expires_at is null or edit_token_expires_at > now())
      )
    )
  ) then
    raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode = 'P0001';
  end if;

  v_handoff := public.sanitize_assistant_handoff(p_assistant_handoff);
  v_code := encode(gen_random_bytes(16), 'hex');
  v_code_hash := encode(sha256(v_code::bytea), 'hex');
  v_expires_at := now() + interval '15 minutes';

  insert into public.owner_sessions (
    store_id,
    user_id,
    code_hash,
    expires_at,
    assistant_handoff
  )
  values (
    v_store_id,
    v_user_id,
    v_code_hash,
    v_expires_at,
    v_handoff
  );

  return jsonb_build_object(
    'code', v_code,
    'expires_at', v_expires_at
  );
end;
$$;

ALTER FUNCTION public._create_owner_session_core(text, text, jsonb) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public._create_owner_session_core(text, text, jsonb)
  FROM public, anon, authenticated;

-- ── 2) create_owner_session yeniden çekirdeğe delege ediyor ──────────────
CREATE OR REPLACE FUNCTION public.create_owner_session(
  p_slug text,
  p_edit_token text default null
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
  select public._create_owner_session_core(p_slug, p_edit_token, null::jsonb);
$$;

ALTER FUNCTION public.create_owner_session(text, text) OWNER TO postgres;
REVOKE EXECUTE ON FUNCTION public.create_owner_session(text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.create_owner_session(text, text) TO anon, authenticated;

-- ── 3) Gerçekten çalıştığını kanıtla ─────────────────────────────────────
-- Yalnız CREATE etmek yetmiyor: plpgsql gövdesi çağrı anında derleniyor,
-- 24 Ağustos'taki hata tam bu yüzden fark edilmedi. Burada gerçek bir
-- vitrinle çağırıp sonucu geri alıyoruz.
DO $$
DECLARE
  v_slug text;
  v_token text;
  v_sonuc jsonb;
BEGIN
  SELECT slug, edit_token INTO v_slug, v_token
  FROM public.stores
  WHERE is_demo IS NOT TRUE
    AND edit_token IS NOT NULL
    AND (edit_token_expires_at IS NULL OR edit_token_expires_at > now())
  LIMIT 1;

  IF v_slug IS NULL THEN
    RAISE NOTICE 'Duman testi atlandı: uygun vitrin yok.';
    RETURN;
  END IF;

  v_sonuc := public.create_owner_session(v_slug, v_token);

  IF v_sonuc->>'code' IS NULL THEN
    RAISE EXCEPTION 'create_owner_session kod üretmedi: %', v_sonuc;
  END IF;

  -- Duman testinin bıraktığı oturumu sil.
  DELETE FROM public.owner_sessions
  WHERE code_hash = encode(sha256((v_sonuc->>'code')::bytea), 'hex');
END;
$$;
