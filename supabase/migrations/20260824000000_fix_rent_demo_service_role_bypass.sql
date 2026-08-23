-- ============================================================================
-- V-57 Fix: Rent-demo service role bypass
-- ============================================================================
-- SORUN: /api/rent-demo POST handler getSupabaseAdmin() (service role key) ile
--        start_demo_trial RPC'sini çağırıyordu. Service role RLS'yi tamamen
--        bypass eder — herhangi bir kullanıcı bu endpoint'i çağırarak admin
--        yetkisi kazanabilir veya tüm veriye erişebilir.
--
-- ÇÖZÜM (Option A — Least Privilege):
--   1. start_demo_trial artık _create_owner_session_core ÇAĞIRMAZ.
--      Yerine: yeni slug + edit_token DÖNDÜRÜR.
--   2. API route (normal client, user JWT ile) önce start_demo_trial
--      çağırır → slug + edit_token alır → sonra create_owner_session
--      (zaten anon/authenticated'a açık) çağırır.
--   3. start_demo_trial execute yetkisi authenticated (+ anon) verilir.
--      service_role özel yetkisi KALDIRILIR.
--   4. clone_demo_store_as_draft execute yetkisi authenticated'a
--      tekrar verilir (20260815180000'de revoke edilmişti).
--
-- GÜVENLİK KONTROLLERİ (start_demo_trial içinde zaten mevcut):
--   - 3 katmanlı rate limit (IP + global)
--   - Kaynak demo store doğrulama (is_demo=true, is_published=true)
--   - Slug çakışma retry (max 3 deneme)
--   - Tüm işlem tek transaction'da (başarısız olursa rollback)
--
-- create_owner_session içinde mevcut kontroller:
--   - edit_token eşleşmesi (yeni klonun token'ı)
--   - Demo store immutable koruması (zaten false çünkü draft)
--   - Oturum kodu + hash + 15 dk TTL
-- ============================================================================

BEGIN;

-- ── 1) start_demo_trial: _create_owner_session_core çağrısını KALDIR,
--      yerine slug + edit_token döndür ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.start_demo_trial(
  p_source_slug text,
  p_client_key text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
DECLARE
  v_source_slug text := pg_catalog.btrim(coalesce(p_source_slug, ''));
  v_client_key text := pg_catalog.btrim(coalesce(p_client_key, ''));
  v_new_slug text;
  v_edit_token text;
  v_attempt integer := 0;
  v_cloned boolean := false;
  v_allowed boolean;
  v_retry_after integer;
BEGIN
  IF v_source_slug = '' THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF v_client_key = '' THEN
    RAISE EXCEPTION 'INVALID_CLIENT_KEY';
  END IF;

  -- Katman 1: aynı IP, kısa pencere — hızlı bot patlamasını durdurur.
  SELECT allowed, retry_after_seconds
  INTO v_allowed, v_retry_after
  FROM public.consume_assistant_request(
    'rent_demo:ip:short:' || v_client_key, 3, 600
  );
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'RATE_LIMITED'
      USING errcode = 'P0001', detail = v_retry_after::text;
  END IF;

  -- Katman 2: aynı IP, günlük pencere — yavaş/dağıtık denemeyi durdurur.
  SELECT allowed, retry_after_seconds
  INTO v_allowed, v_retry_after
  FROM public.consume_assistant_request(
    'rent_demo:ip:day:' || v_client_key, 10, 86400
  );
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'RATE_LIMITED'
      USING errcode = 'P0001', detail = v_retry_after::text;
  END IF;

  -- Katman 3: TÜM Vixrex, saatlik — IP değiştiren bot bile bu duvara çarpar.
  SELECT allowed, retry_after_seconds
  INTO v_allowed, v_retry_after
  FROM public.consume_assistant_request(
    'rent_demo:global', 100, 3600
  );
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'RATE_LIMITED'
      USING errcode = 'P0001', detail = v_retry_after::text;
  END IF;

  -- Kaynağın gerçekten kiralanabilir bir demo olduğunu erkenden doğrula
  IF NOT EXISTS (
    SELECT 1 FROM public.stores
    WHERE slug = v_source_slug AND is_demo = true AND is_published = true
  ) THEN
    RAISE EXCEPTION 'SOURCE_NOT_FOUND';
  END IF;

  -- Slug çakışması — DB içinde retry (max 3 deneme)
  WHILE NOT v_cloned AND v_attempt < 3 LOOP
    v_attempt := v_attempt + 1;
    v_new_slug := v_source_slug || '-' || encode(gen_random_bytes(4), 'hex');
    v_edit_token := encode(gen_random_bytes(32), 'hex');

    BEGIN
      PERFORM public.clone_demo_store_as_draft(
        v_source_slug, v_new_slug, v_edit_token
      );
      v_cloned := true;
    EXCEPTION
      WHEN unique_violation THEN
        IF v_attempt >= 3 THEN
          RAISE EXCEPTION 'SLUG_GENERATION_FAILED';
        END IF;
    END;
  END LOOP;

  -- DEĞİŞİKLİK: _create_owner_session_core ÇAĞIRMAYIZ.
  -- API route create_owner_session'ı ayrı çağıracak (normal client ile).
  RETURN jsonb_build_object(
    'slug', v_new_slug,
    'edit_token', v_edit_token,
    'expires_at', (now() + interval '15 minutes')
  );
END;
$$;

COMMENT ON FUNCTION public.start_demo_trial(text, text) IS
  '"Bu vitrini kirala" — TEK güvenli giriş noktası. Oran sınırı + klonlama
   tek transaction''da. Authenticated/anon çağırabilir; service_role özel
   yetkisi KALDIRILDI (V-57 fix). Dönen edit_token ile create_owner_session
   ayrı çağrılır.';

-- ── 2) Yetkileri DÜZELT ────────────────────────────────────────────────────
-- start_demo_trial: authenticated + anon (kiralama kimliksiz de olabilir)
REVOKE EXECUTE ON FUNCTION public.start_demo_trial(text, text)
  FROM public, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.start_demo_trial(text, text)
  TO anon, authenticated;

-- clone_demo_store_as_draft: authenticated'a tekrar ver (20260815180000 revoke etti)
REVOKE EXECUTE ON FUNCTION public.clone_demo_store_as_draft(text, text, text)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.clone_demo_store_as_draft(text, text, text)
  TO anon, authenticated;

-- _create_owner_session_core: HALA sadece service_role (iç fonksiyon, dışarıya kapalı)
-- create_owner_session: zaten anon/authenticated'a açık (20260804001000)

COMMIT;