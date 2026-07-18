-- P0: apply_category_template ownership + search_path.
-- Ayrıca anon stores INSERT RLS (create_store_with_token tek create yolu).
-- withdraw_store_publication_consent COALESCE/FOUND düzeltmesi.
-- consume_assistant_request yalnız service_role.
-- Ölü 13-arg update_store_with_token overload kaldırılır.

DROP POLICY IF EXISTS "Allow anon insert stores with edit token" ON public.stores;

DROP FUNCTION IF EXISTS public.apply_category_template(uuid, text, boolean, boolean, boolean, boolean);

CREATE OR REPLACE FUNCTION public.apply_category_template(
  p_store_id uuid,
  p_category_key text,
  p_fill_cover boolean DEFAULT true,
  p_fill_logo boolean DEFAULT true,
  p_fill_gallery boolean DEFAULT true,
  p_fill_products boolean DEFAULT true,
  p_edit_token text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb := '{}'::jsonb;
  v_image_row record;
  v_current_cover text;
  v_current_logo text;
  v_current_gallery jsonb;
  v_current_products jsonb;
  v_gallery_items jsonb := '[]'::jsonb;
  v_template_products jsonb := '[]'::jsonb;
  v_applied_count int := 0;
  v_authorized boolean := false;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.stores s
    WHERE s.id = p_store_id
      AND (
        (auth.uid() IS NOT NULL AND s.user_id = auth.uid())
        OR (
          pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
          AND s.edit_token = pg_catalog.btrim(p_edit_token)
        )
      )
  ) INTO v_authorized;

  IF NOT v_authorized THEN
    RAISE EXCEPTION 'STORE_UPDATE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;

  SELECT shelf_image_url, logo_url, gallery_items, products
  INTO v_current_cover, v_current_logo, v_current_gallery, v_current_products
  FROM public.stores
  WHERE id = p_store_id;

  IF p_fill_cover THEN
    SELECT image_url INTO v_image_row
    FROM public.category_image_templates
    WHERE category_key = p_category_key AND image_type = 'cover' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_cover IS NULL OR v_current_cover = '') THEN
      UPDATE public.stores SET shelf_image_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"cover": true}'::jsonb;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_logo THEN
    SELECT image_url INTO v_image_row
    FROM public.category_image_templates
    WHERE category_key = p_category_key AND image_type = 'logo_placeholder' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_logo IS NULL OR v_current_logo = '') THEN
      UPDATE public.stores SET logo_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"logo": true}'::jsonb;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_gallery THEN
    IF v_current_gallery IS NULL OR jsonb_array_length(v_current_gallery) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'imageUrl', image_url,
          'title', coalesce(title, 'Gorsel')
        ) ORDER BY display_order
      )
      INTO v_gallery_items
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND image_type = 'gallery' AND is_active = true;

      IF v_gallery_items IS NOT NULL AND jsonb_array_length(v_gallery_items) > 0 THEN
        UPDATE public.stores SET gallery_items = v_gallery_items WHERE id = p_store_id;
        v_result := v_result || '{"gallery": true}'::jsonb;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  IF p_fill_products THEN
    IF v_current_products IS NULL OR jsonb_array_length(v_current_products) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', gen_random_uuid(),
          'name', coalesce(title, 'Urun'),
          'description', '',
          'price', '',
          'imageUrls', jsonb_build_array(image_url),
          'isVisible', true,
          'source', 'category_template'
        ) ORDER BY display_order
      )
      INTO v_template_products
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND image_type = 'product' AND is_active = true;

      IF v_template_products IS NOT NULL AND jsonb_array_length(v_template_products) > 0 THEN
        UPDATE public.stores SET products = v_template_products WHERE id = p_store_id;
        v_result := v_result || '{"products": true}'::jsonb;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  IF v_applied_count > 0 THEN
    INSERT INTO public.store_category_image_usage (store_id, category_key, images_used)
    VALUES (
      p_store_id,
      p_category_key,
      coalesce(
        (
          SELECT jsonb_agg(image_url)
          FROM public.category_image_templates
          WHERE category_key = p_category_key AND is_active = true
        ),
        '[]'::jsonb
      )
    )
    ON CONFLICT (store_id) DO UPDATE SET
      category_key = EXCLUDED.category_key,
      images_used = EXCLUDED.images_used,
      applied_at = pg_catalog.now();
  END IF;

  RETURN v_result || jsonb_build_object(
    'success', v_applied_count > 0,
    'image_count', (
      SELECT count(*)::int
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND is_active = true
    )
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.apply_category_template(uuid, text, boolean, boolean, boolean, boolean, text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_category_template(uuid, text, boolean, boolean, boolean, boolean, text)
TO anon, authenticated;

-- Eski 6-arg imza varsa kaldır (yeni default'lu imza kullanılır)
DO $$
BEGIN
  IF pg_catalog.to_regprocedure(
    'public.apply_category_template(uuid,text,boolean,boolean,boolean,boolean)'
  ) IS NOT NULL
  AND pg_catalog.to_regprocedure(
    'public.apply_category_template(uuid,text,boolean,boolean,boolean,boolean,text)'
  ) IS NOT NULL THEN
    -- Yeni imza create or replace ile oluşturuldu; eski overload yoksa sorun yok.
    NULL;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.withdraw_store_publication_consent(
  p_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.stores
  SET
    is_published = false,
    publication_consent_accepted = false,
    publication_consent_withdrawn_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  WHERE slug = pg_catalog.btrim(p_slug)
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

  IF NOT FOUND THEN
    RAISE EXCEPTION 'STORE_UPDATE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text)
TO anon, authenticated;

REVOKE ALL ON FUNCTION public.consume_assistant_request(text, integer)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.consume_assistant_request(text, integer)
TO service_role;

DO $$
BEGIN
  IF pg_catalog.to_regprocedure(
    'public.update_store_with_token(text,text,text,text,text,text,text,text,text,text,text,jsonb,text)'
  ) IS NOT NULL THEN
    DROP FUNCTION public.update_store_with_token(
      text, text, text, text, text, text, text, text, text, text, text, jsonb, text
    );
  END IF;
END;
$$;

NOTIFY pgrst, 'reload schema';
