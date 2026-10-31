-- Vixrex R-01B: empty owner edit token must NEVER authorize store changes.
-- Reproduced on production + test before fix: 26/26 stores with edit_token=''
-- passed _check_store_authorization(id, '').
-- Scope: one function; no store, product, cron, RLS or grant changes.
-- This migration retains SECURITY DEFINER, signature, existing EXECUTE grants,
-- expiration behavior and support for valid nonempty owner tokens.
-- Run in test first, verify; run on production only after test succeeds.
BEGIN;

DO $r01b_preflight$
DECLARE v_source text; v_owner text; v_security_definer boolean;
BEGIN
  SELECT pg_catalog.pg_get_functiondef(p.oid),
         pg_catalog.pg_get_userbyid(p.proowner), p.prosecdef
  INTO v_source, v_owner, v_security_definer
  FROM pg_catalog.pg_proc p
  WHERE p.oid = 'public._check_store_authorization(uuid,text)'::pg_catalog.regprocedure;

  IF v_source IS NULL OR pg_catalog.md5(v_source) <> 'e488979fee100ed56ab71cf01e7e87cf'
     OR v_owner <> 'postgres' OR v_security_definer IS NOT TRUE
  THEN
    RAISE EXCEPTION 'R01B_PREFLIGHT_FAILED: authorization function changed';
  END IF;
END;
$r01b_preflight$;

CREATE OR REPLACE FUNCTION public._check_store_authorization(
  p_store_id uuid,
  p_edit_token text DEFAULT NULL::text
)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
  v_token_ok boolean;
  v_expired boolean;
BEGIN
  -- R-01B: empty / whitespace-only bearer token must never authorize.
  IF p_edit_token IS NULL OR pg_catalog.btrim(p_edit_token) = '' THEN
    RETURN false;
  END IF;

  SELECT
    (stores.edit_token = p_edit_token)::boolean,
    (stores.edit_token_expires_at IS NOT NULL AND stores.edit_token_expires_at <= now())::boolean
  INTO v_token_ok, v_expired
  FROM public.stores
  WHERE id = p_store_id;

  -- R-01B: missing store and NULL comparisons must fail closed.
  IF NOT coalesce(v_token_ok, false) THEN
    RETURN false;
  END IF;

  IF v_expired THEN
    RETURN false; -- Token expired
  END IF;

  RETURN true;
END;
$function$;

DO $r01b_postcheck$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.edit_token = ''
      AND public._check_store_authorization(s.id, '') IS DISTINCT FROM false
  ) THEN
    RAISE EXCEPTION 'R01B_POSTCHECK_FAILED: blank token authorized';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.edit_token <> ''
      AND (s.edit_token_expires_at IS NULL OR s.edit_token_expires_at > now())
      AND public._check_store_authorization(s.id, s.edit_token) IS DISTINCT FROM true
  ) THEN
    RAISE EXCEPTION 'R01B_POSTCHECK_FAILED: valid token rejected';
  END IF;

  IF public._check_store_authorization(NULL::uuid, 'not-a-real-token') IS DISTINCT FROM false
  THEN
    RAISE EXCEPTION 'R01B_POSTCHECK_FAILED: missing store authorized';
  END IF;
END;
$r01b_postcheck$;
COMMIT;
