-- Demo/şablon ürünlerin fotoğraf standardı: 1 foto -> 3+ foto (2026-09-25)
-- Kök neden: 20260922010000 seed'i urune tek gorsel atadi
--   (jsonb_build_array(g.gorseller[...]) — havuzdan tek eleman).
-- Kaynak: yalniz kendi depomuz (storage: category-templates, public).
--   Unsplash/dis baglantili gorsel KULLANILMAZ (20260825 karari).
-- Kapsam: YALNIZ is_demo=true magazalarin urunleri. is_demo=false
--   (gercek musteri) urunlerine HIC dokunulmaz.
-- Kural: mevcut fotograflar korunur (ilk sira dahil), eksik havuzdan
--   tamamlanir; zaten 3+ fotoya sahip urun degismez (idempotent).
-- Tekrar kosum guvenli: guard blogu kalan eksik urun 0 olmadan gecmez.

CREATE TEMP TABLE _vx_foto_havuzu (sablon text primary key, havuz text[]) ON COMMIT DROP;
INSERT INTO _vx_foto_havuzu VALUES
  ('fashion', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-1-5cf119.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-3-6348d8.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-5-274039.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-7-8075d7.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-1-68eaa9.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-3-40b9e3.jpg'
  ]::text[]),
  ('food', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-1-6c3427.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-2-45457c.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-3-7b46e4.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-5-35b6e3.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-1-c718d1.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-2-4985ba.jpg'
  ]::text[]),
  ('cafe_restaurant', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-1-207ae2.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-3-b63ef6.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-6-a0fe95.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-8-e510e9.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-2-30b98b.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-4-156d1b.jpg'
  ]::text[]),
  ('service', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-1-e7acd0.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-3-8eeb7b.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-5-53b2e1.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-8-cf8491.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-2-bae2f3.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-4-c35880.jpg'
  ]::text[]),
  ('technical_service', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-1-d1dbdf.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-2-4881c1.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-3-9b1a57.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-4-4ad978.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-5-8191f9.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-1-f61804.jpg'
  ]::text[]),
  ('electronics', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-1-e028e5.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-2-024b62.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-3-73e2fb.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-4-3916e4.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-5-76d810.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-1-c50a72.jpg'
  ]::text[]),
  ('generic', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-1-f59145.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-2-e31874.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-3-b752fa.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-5-b21d99.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-1-ee52a7.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-2-c768fb.jpg'
  ]::text[]);

UPDATE public.products p
SET image_urls = p.image_urls || e.eklenen
FROM (
  SELECT p2.id,
         (
           SELECT coalesce(jsonb_agg(sec.u), '[]'::jsonb)
           FROM (
             SELECT t.u
             FROM unnest(h.havuz) AS t(u)
             WHERE t.u IS DISTINCT FROM (p2.image_urls ->> 0)
               AND NOT p2.image_urls @> to_jsonb(ARRAY[t.u]::text[])
             LIMIT 3 - jsonb_array_length(p2.image_urls)
           ) sec
         ) AS eklenen
  FROM public.products p2
  JOIN public.product_categories pc ON pc.id = p2.category_id
  JOIN public.stores s ON s.id = p2.store_id
  JOIN _vx_foto_havuzu h ON h.sablon = coalesce(pc.product_template_key, 'generic')
  WHERE s.is_demo = true
    AND p2.is_active = true
    AND jsonb_array_length(p2.image_urls) < 3
) e
WHERE p.id = e.id
  AND e.eklenen <> '[]'::jsonb;

-- Adim 2: seed'in Unsplash ilk gorselini kendi depomuzdan degistir
-- (20260825 karari: sablon gorselleri kendi depoda; dis baglanti yok).
-- Canliya 2026-09-25'te ayni kurallarla uygulandi; bu dosya taze
-- ortam/CI zincirinin ayni sonucu uretmesi icin sozlesmenin kendisidir.
UPDATE public.products p
SET image_urls = e.yeni
FROM (
  SELECT p2.id,
         to_jsonb(
           ARRAY(
             SELECT t.u
             FROM unnest(h2.havuz) AS t(u)
             WHERE NOT t.u = ANY(ARRAY(
               SELECT x.v
               FROM jsonb_array_elements_text(p2.image_urls) WITH ORDINALITY AS x(v, ord)
               WHERE x.ord BETWEEN 2 AND 3
               ORDER BY x.ord
             ))
             LIMIT 1
           )
           || ARRAY(
             SELECT x.v
             FROM jsonb_array_elements_text(p2.image_urls) WITH ORDINALITY AS x(v, ord)
             WHERE x.ord BETWEEN 2 AND 3
             ORDER BY x.ord
           )
         ) AS yeni
  FROM public.products p2
  JOIN public.product_categories pc2 ON pc2.id = p2.category_id
  JOIN public.stores s2 ON s2.id = p2.store_id
  JOIN _vx_foto_havuzu h2 ON h2.sablon = coalesce(pc2.product_template_key, 'generic')
  WHERE s2.is_demo = true
    AND p2.is_active = true
    AND p2.image_urls::text ILIKE '%unsplash%'
) e
WHERE p.id = e.id;

DO $$
DECLARE kalan int;
BEGIN
  SELECT count(*) INTO kalan
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  WHERE s.is_demo = true AND p.is_active = true
    AND jsonb_array_length(p.image_urls) < 3;
  IF kalan > 0 THEN
    RAISE EXCEPTION 'Demo urunlerde hala % urun 3 fotografin altinda — seed hatti duzeltilmeli', kalan;
  END IF;
  SELECT count(*) INTO kalan
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  WHERE s.is_demo = true AND p.is_active = true
    AND p.image_urls::text ILIKE '%unsplash%';
  IF kalan > 0 THEN
    RAISE EXCEPTION 'Demo urun gorsellerinde hala % Unsplash baglantisi var — dis baglanti yasak', kalan;
  END IF;
END $$;
