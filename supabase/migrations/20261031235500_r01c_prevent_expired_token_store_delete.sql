-- R-01C: prevent expired edit_token from authorizing destructive store deletion.
-- Exactly one function changes. Original owner/session path and NULL-TTL compatibility remain.
DO $r01c_guard$
BEGIN
  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.delete_store_with_token(text,text)'::pg_catalog.regprocedure)) <> 'f9e3678c9af18504fc1751b2cc4decf3'
  THEN RAISE EXCEPTION 'R01C_PREFLIGHT_FAILED: function source changed'; END IF;
END;
$r01c_guard$;

CREATE OR REPLACE FUNCTION public.delete_store_with_token(p_slug text, p_edit_token text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_slug text := pg_catalog.btrim(p_slug);
  v_store_id uuid;
BEGIN
  IF v_slug IS NULL OR v_slug = '' THEN
    RAISE EXCEPTION 'STORE_DELETE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;

  SELECT id
  INTO v_store_id
  FROM public.stores
  WHERE slug = v_slug
    AND (
      (
        pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
        AND edit_token = pg_catalog.btrim(p_edit_token)
        AND (edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())
      )
      OR (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
      )
    );

  IF v_store_id IS NULL THEN
    RAISE EXCEPTION 'STORE_DELETE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;

  DELETE FROM public.store_instagram_imports
  WHERE store_slug = v_slug
     OR connection_id IN (
       SELECT id FROM public.store_instagram_connections WHERE store_slug = v_slug
     );
  DELETE FROM public.store_instagram_tokens
  WHERE connection_id IN (
    SELECT id FROM public.store_instagram_connections WHERE store_slug = v_slug
  );
  DELETE FROM public.store_instagram_connections WHERE store_slug = v_slug;
  DELETE FROM public.vitrin_views WHERE store_id = v_store_id;
  DELETE FROM public.store_category_image_usage WHERE store_id = v_store_id;
  DELETE FROM public.booking_settings WHERE store_slug = v_slug;
  DELETE FROM public.store_articles WHERE store_slug = v_slug;
  DELETE FROM public.appointments WHERE store_slug = v_slug;
  DELETE FROM public.stores WHERE id = v_store_id;
END;
$function$;

DO $r01c_assert$
DECLARE v_definition text;
BEGIN
  v_definition := pg_catalog.pg_get_functiondef('public.delete_store_with_token(text,text)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_definition, 'AND (edit_token_expires_at IS NULL OR edit_token_expires_at > pg_catalog.now())') = 0
  THEN RAISE EXCEPTION 'R01C_POSTCHECK_FAILED: expiration guard missing'; END IF;
  IF NOT pg_catalog.has_function_privilege('anon','public.delete_store_with_token(text,text)','EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated','public.delete_store_with_token(text,text)','EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role','public.delete_store_with_token(text,text)','EXECUTE')
  THEN RAISE EXCEPTION 'R01C_POSTCHECK_FAILED: access grants changed'; END IF;
END;
$r01c_assert$;
