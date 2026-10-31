-- Vixrex R-01 / 2026-10-31
-- Kapsam: yalnizca UÇ bakım RPC fonksiyonunun EXECUTE yetkisi.
-- Fonksiyon gövdesi, cron görevi, veri ve RLS politikasi DEGISTIRILMEZ.
-- GitHub ana dalina / uretime uygulanmadan once ayri onay ve test gerekir.
BEGIN;

DO $preflight$
DECLARE
  v_function text;
BEGIN
  FOREACH v_function IN ARRAY ARRAY[
    'cleanup_expired_edit_tokens',
    'cleanup_expired_owner_sessions',
    'cleanup_stale_assistant_rate_limits'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = v_function
        AND p.pronargs = 0
        AND p.prosecdef = true
        AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
    ) THEN
      RAISE EXCEPTION 'R01_PREFLIGHT_FAILED: function missing or unexpected owner: %', v_function;
    END IF;
  END LOOP;

  IF (
    SELECT count(*)
    FROM cron.job
    WHERE jobname IN (
      'cleanup-expired-edit-tokens',
      'cleanup-expired-owner-sessions',
      'cleanup-stale-assistant-rate-limits'
    )
  ) <> 3 THEN
    RAISE EXCEPTION 'R01_PREFLIGHT_FAILED: expected three existing cron jobs';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM cron.job
    WHERE jobname IN (
      'cleanup-expired-edit-tokens',
      'cleanup-expired-owner-sessions',
      'cleanup-stale-assistant-rate-limits'
    )
      AND (username <> 'postgres' OR active IS NOT TRUE)
  ) THEN
    RAISE EXCEPTION 'R01_PREFLIGHT_FAILED: cron owner/state changed';
  END IF;
END;
$preflight$;

-- PUBLIC grant'i kaldirilmadan yalnizca anon/ authenticated REVOKE yeterli degildir.
REVOKE EXECUTE ON FUNCTION public.cleanup_expired_edit_tokens()
  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.cleanup_expired_owner_sessions()
  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.cleanup_stale_assistant_rate_limits()
  FROM PUBLIC, anon, authenticated;

DO $assert$
DECLARE
  v_function text;
  v_oid oid;
BEGIN
  FOREACH v_function IN ARRAY ARRAY[
    'cleanup_expired_edit_tokens',
    'cleanup_expired_owner_sessions',
    'cleanup_stale_assistant_rate_limits'
  ] LOOP
    v_oid := pg_catalog.to_regprocedure('public.' || v_function || '()');
    IF v_oid IS NULL
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('postgres', v_oid, 'EXECUTE')
    THEN
      RAISE EXCEPTION 'R01_POSTCHECK_FAILED: unexpected EXECUTE privilege: %', v_function;
    END IF;
  END LOOP;
END;
$assert$;
COMMIT;
