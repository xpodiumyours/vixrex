-- CodeRabbit incelemesinde bulunan 3 gerçek sorunu düzeltir. Önceki
-- migration'lar (20260803120000, 20260803140000) DEĞİŞTİRİLMEDİ — yeni
-- düzeltme burada.

-- 1) KRİTİK: save_store_draft_with_token'da yarış durumu.
--    Eski hâlde: is_published kontrolü (SELECT) ile taslak UPDATE'i arasında
--    başka bir işlem mağazayı yayınlarsa, UPDATE yine de çalışıp yayınlı
--    satırı sessizce taslağa çevirip eski veriyle ezebiliyordu. Düzeltme:
--    UPDATE'in WHERE koşuluna is_published = false eklenir — satır o anda
--    yayınlıysa güncelleme hiç eşleşmez, hata fırlatılır.
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
      AND edit_token <> ''
      AND is_published = false;

    IF NOT FOUND THEN
      -- Token uyuşmadı ya da SELECT'ten sonra eşzamanlı olarak yayınlandı.
      RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH_OR_PUBLISHED' USING errcode = 'P0001';
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

-- 2) get_store_preview tüm satırı (edit_token, user_id dahil) döndürüyordu.
--    Next.js'in public sayfada kullandığı sütun listesiyle (PUBLIC_STORE_SELECT)
--    birebir aynı, dar bir sütun listesine daraltıldı.
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

  SELECT jsonb_build_object(
    'id', s.id,
    'slug', s.slug,
    'name', s.name,
    'business_type', s.business_type,
    'description', s.description,
    'corporate_bio', s.corporate_bio,
    'whatsapp', s.whatsapp,
    'phone', s.phone,
    'email', s.email,
    'hero_badge', s.hero_badge,
    'instagram', s.instagram,
    'website', s.website,
    'address', s.address,
    'status', s.status,
    'marketplace_links', s.marketplace_links,
    'gallery_items', s.gallery_items,
    'products', s.products,
    'faq_items', s.faq_items,
    'about_kicker', s.about_kicker,
    'about_title', s.about_title,
    'about_image_url', s.about_image_url,
    'about_image_caption', s.about_image_caption,
    'about_values', s.about_values,
    'gallery_section_kicker', s.gallery_section_kicker,
    'gallery_section_title', s.gallery_section_title,
    'show_storefront_rating', s.show_storefront_rating,
    'show_directions_link', s.show_directions_link,
    'references_link', s.references_link,
    'shelf_image_url', s.shelf_image_url,
    'logo_url', s.logo_url,
    'working_hours', s.working_hours,
    'is_published', s.is_published,
    'kategori', s.kategori,
    'latitude', s.latitude,
    'longitude', s.longitude,
    'google_business_link', s.google_business_link,
    'product_storage_version', s.product_storage_version,
    'featured_banner_label', s.featured_banner_label,
    'featured_banner_title', s.featured_banner_title,
    'featured_banner_description', s.featured_banner_description,
    'featured_banner_image_url', s.featured_banner_image_url,
    'featured_banner_price_text', s.featured_banner_price_text,
    'rating_score', s.rating_score,
    'review_count', s.review_count
  ) INTO v_result
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

-- 3) Zaten seed edilmiş demo satırlarındaki şemasız "google.com" linkini
--    düzeltir (href="google.com" göreli link gibi davranır).
UPDATE public.stores
SET marketplace_links = (
  SELECT jsonb_agg(
    CASE WHEN elem->>'url' = 'google.com'
      THEN elem || jsonb_build_object('url', 'https://google.com')
      ELSE elem
    END
  )
  FROM jsonb_array_elements(marketplace_links) elem
)
WHERE slug LIKE 'demo-%'
  AND marketplace_links @> '[{"url": "google.com"}]'::jsonb;

NOTIFY pgrst, 'reload schema';
