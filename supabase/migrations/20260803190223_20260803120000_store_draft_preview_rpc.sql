-- Taslak (yayın öncesi) önizleme için iki yeni RPC.
-- Amaç: PreviewScreen (Flutter native render) yerine esnafın taslağını
-- Next.js'in gerçek /v/:slug şablonunda göstermek.
--
-- Güvenlik: public "Allow public read stores" politikası (is_published = true)
-- DEĞİŞMİYOR. Taslak okuma/yazma tamamen bu iki SECURITY DEFINER fonksiyonu
-- üzerinden, edit_token (veya auth.uid()) doğrulamasıyla yapılıyor —
-- create_store_with_token / update_store_with_token ile aynı yetkilendirme deseni.

-- 1) Taslak kaydet: yalnızca YAYINDA OLMAYAN bir satırı oluşturur/günceller.
--    Zaten yayınlanmış (is_published = true) bir mağaza üzerinde asla
--    çalışmaz — canlı public içeriği yanlışlıkla taslak veriyle
--    ezme riskini kökten kapatır.
CREATE OR REPLACE FUNCTION public.save_store_draft_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_existing_id uuid;
  v_existing_published boolean;
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  SELECT id, is_published INTO v_existing_id, v_existing_published
  FROM public.stores
  WHERE slug = pg_catalog.btrim(p_slug);

  IF v_existing_id IS NOT NULL THEN
    IF v_existing_published THEN
      RAISE EXCEPTION 'STORE_ALREADY_PUBLISHED';
    END IF;

    UPDATE public.stores
    SET
      edit_token = pg_catalog.btrim(p_edit_token),
      name = coalesce(p_store->>'name', name),
      business_type = coalesce(p_store->>'business_type', business_type),
      description = coalesce(p_store->>'description', description),
      corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
      whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
      instagram = coalesce(p_store->>'instagram', instagram),
      website = coalesce(p_store->>'website', website),
      address = coalesce(p_store->>'address', address),
      theme = coalesce(p_store->>'theme', theme),
      marketplace_links = coalesce(p_store->'marketplace_links', marketplace_links),
      gallery_items = coalesce(p_store->'gallery_items', gallery_items),
      offerings = coalesce(p_store->'offerings', offerings),
      shelf_image_url = coalesce(nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
      logo_url = coalesce(nullif(p_store->>'logo_url', ''), logo_url),
      working_hours = coalesce(p_store->>'working_hours', working_hours),
      kategori = coalesce(p_store->>'kategori', kategori),
      google_business_link = coalesce(p_store->>'google_business_link', google_business_link),
      is_published = false,
      status = 'draft',
      updated_at = pg_catalog.now()
    WHERE id = v_existing_id
      AND edit_token = pg_catalog.btrim(p_edit_token)
      AND edit_token <> '';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH' USING errcode = 'P0001';
    END IF;
  ELSE
    INSERT INTO public.stores (
      slug, edit_token, user_id, name, business_type, description, corporate_bio,
      whatsapp, instagram, website, address, theme, status,
      marketplace_links, gallery_items, offerings,
      shelf_image_url, logo_url, working_hours, is_published, kategori,
      google_business_link, updated_at
    ) VALUES (
      pg_catalog.btrim(p_slug),
      pg_catalog.btrim(p_edit_token),
      v_user_id,
      coalesce(p_store->>'name', ''),
      coalesce(p_store->>'business_type', ''),
      coalesce(p_store->>'description', ''),
      coalesce(p_store->>'corporate_bio', ''),
      coalesce(p_store->>'whatsapp', ''),
      coalesce(p_store->>'instagram', ''),
      coalesce(p_store->>'website', ''),
      coalesce(p_store->>'address', ''),
      coalesce(p_store->>'theme', ''),
      'draft',
      coalesce(p_store->'marketplace_links', '[]'::jsonb),
      coalesce(p_store->'gallery_items', '[]'::jsonb),
      coalesce(p_store->'offerings', '[]'::jsonb),
      coalesce(p_store->>'shelf_image_url', ''),
      coalesce(p_store->>'logo_url', ''),
      coalesce(p_store->>'working_hours', ''),
      false,
      coalesce(p_store->>'kategori', ''),
      coalesce(p_store->>'google_business_link', ''),
      pg_catalog.now()
    );
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.save_store_draft_with_token(text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.save_store_draft_with_token(text, text, jsonb) TO anon, authenticated;

-- 2) Taslak oku: yalnızca edit_token (veya sahibi auth.uid()) eşleşirse satırı döndürür.
--    Public "is_published = true" politikasına hiç dokunmuyor; bu okuma
--    tamamen bu fonksiyonun içindeki yetki kontrolüne dayanıyor.
CREATE OR REPLACE FUNCTION public.get_store_preview(
  p_slug text,
  p_edit_token text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN
    RAISE EXCEPTION 'INVALID_SLUG';
  END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN
    RAISE EXCEPTION 'INVALID_EDIT_TOKEN';
  END IF;

  SELECT to_jsonb(s) INTO v_result
  FROM public.stores s
  WHERE s.slug = pg_catalog.btrim(p_slug)
    AND s.edit_token = pg_catalog.btrim(p_edit_token)
    AND s.edit_token <> '';

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH' USING errcode = 'P0001';
  END IF;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_store_preview(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_store_preview(text, text) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
