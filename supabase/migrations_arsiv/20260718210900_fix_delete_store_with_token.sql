CREATE OR REPLACE FUNCTION public.delete_store_with_token(
  p_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

REVOKE EXECUTE ON FUNCTION public.delete_store_with_token(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_store_with_token(text, text) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
