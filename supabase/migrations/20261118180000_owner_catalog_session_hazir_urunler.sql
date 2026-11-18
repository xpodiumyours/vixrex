BEGIN;

CREATE OR REPLACE FUNCTION public.get_owner_catalog_for_session(
  p_session_token text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
DECLARE
  v_token text := pg_catalog.btrim(coalesce(p_session_token, ''));
  v_token_hash text;
  v_store_id uuid;
  v_owner_store_id uuid;
  v_is_demo boolean;
BEGIN
  IF v_token = '' OR pg_catalog.length(v_token) <> 64 THEN
    RAISE EXCEPTION 'INVALID_SESSION_TOKEN';
  END IF;

  v_token_hash := encode(sha256(v_token::bytea), 'hex');

  SELECT s.store_id, st.is_demo
    INTO v_store_id, v_is_demo
  FROM public.owner_sessions s
  JOIN public.stores st ON st.id = s.store_id
  WHERE s.session_token_hash = v_token_hash
    AND s.consumed_at IS NOT NULL
    AND s.expires_at > now();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_SESSION_TOKEN';
  END IF;

  IF v_is_demo THEN
    RAISE EXCEPTION 'DEMO_STORE_IMMUTABLE' USING errcode = 'P0001';
  END IF;

  v_owner_store_id := v_store_id;

  RETURN jsonb_build_object(
    'categories', coalesce((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', c.id,
          'name', c.name
        )
        ORDER BY c.sort_order, c.id
      )
      FROM public.product_categories c
      WHERE c.store_id = v_store_id
        AND c.is_active = true
    ), '[]'::jsonb),
    'products', coalesce((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', p.id,
          'name', p.name,
          'slug', p.slug,
          'description', p.description,
          'price_text', p.price_text,
          'price_amount', p.price_amount,
          'old_price_amount', p.old_price_amount,
          'badge_tag', p.badge_tag,
          'fulfillment_region', p.fulfillment_region,
          'currency', p.currency,
          'stock_status', p.stock_status,
          'image_urls', p.image_urls,
          'category_id', p.category_id,
          'is_visible', p.is_visible,
          'is_active', p.is_active,
          'source_type', p.source_type,
          'sort_order', p.sort_order
        )
        ORDER BY p.sort_order, p.id
      )
      FROM public.products p
      WHERE p.store_id = v_store_id
        AND p.is_active = true
        AND (p.is_visible = true OR (v_owner_store_id IS NOT NULL AND p.store_id = v_owner_store_id AND p.is_active = true))
    ), '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_owner_catalog_for_session(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_owner_catalog_for_session(text) TO anon, authenticated, service_role;

COMMIT;

NOTIFY pgrst, 'reload schema';
