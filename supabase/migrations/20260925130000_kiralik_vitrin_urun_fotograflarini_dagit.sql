BEGIN;

CREATE TEMP TABLE _vx_foto_havuzu (sablon text primary key, havuz text[]) ON COMMIT DROP;

INSERT INTO _vx_foto_havuzu VALUES
  ('fashion', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-1-68eaa9.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-2-030a80.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-3-40b9e3.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-4-0f96d7.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-5-119484.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-7-136d04.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-8-45dd1d.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-1-5cf119.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-2-74a618.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-3-6348d8.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-4-8ebb75.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-5-274039.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-6-87f1fd.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-7-8075d7.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-8-1e3bd7.jpg'
  ]::text[]),
  ('food', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-1-c718d1.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-2-4985ba.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-3-f0e6dc.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-4-9c1593.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-5-e4141f.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-1-6c3427.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-2-45457c.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-3-7b46e4.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-5-35b6e3.jpg'
  ]::text[]),
  ('cafe_restaurant', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-1-ffef38.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-2-30b98b.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-3-57cb36.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-4-156d1b.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-5-f45f60.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-6-15eb04.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-7-e2b5da.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-8-a7bbb8.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-1-207ae2.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-2-b20986.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-3-b63ef6.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-4-dfe420.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-6-a0fe95.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-7-6026d9.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-8-e510e9.jpg'
  ]::text[]),
  ('service', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-1-080c62.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-2-bae2f3.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-3-33cfb4.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-4-c35880.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-5-1c48dc.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-6-3f3013.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-7-8761f2.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-1-e7acd0.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-2-53693d.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-3-8eeb7b.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-4-0a959f.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-5-53b2e1.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-6-d08def.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-8-cf8491.jpg'
  ]::text[]),
  ('technical_service', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-1-f61804.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-2-006ee3.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-3-869878.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-4-8a70ab.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-5-24629e.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-1-d1dbdf.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-2-4881c1.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-3-9b1a57.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-4-4ad978.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-5-8191f9.jpg'
  ]::text[]),
  ('electronics', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-1-c50a72.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-2-32129d.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-3-5c50d9.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-4-51e153.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-5-2271c9.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-1-e028e5.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-2-024b62.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-3-73e2fb.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-4-3916e4.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-5-76d810.jpg'
  ]::text[]),
  ('generic', ARRAY[
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-1-ee52a7.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-2-c768fb.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-3-f47b81.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-4-ed54fd.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-5-d58ba8.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-1-f59145.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-2-e31874.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-3-b752fa.jpg',
    'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-5-b21d99.jpg'
  ]::text[]);

WITH hedef AS (
  SELECT p.id,
         (
           (dense_rank() OVER (ORDER BY s.slug) - 1)
           + (
               row_number() OVER (
                 PARTITION BY s.id, coalesce(pc.product_template_key, 'generic')
                 ORDER BY coalesce(p.sort_order, 9999), p.created_at, p.slug
               ) - 1
             )
         ) AS sira,
         h.havuz AS havuz,
         array_length(h.havuz, 1) AS havuz_boyu
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  JOIN public.product_categories pc ON pc.id = p.category_id
  JOIN _vx_foto_havuzu h ON h.sablon = coalesce(pc.product_template_key, 'generic')
  WHERE s.is_demo = true
    AND s.user_id IS NULL
    AND p.is_active = true
)
UPDATE public.products p
SET image_urls = to_jsonb(ARRAY[
      hedef.havuz[(hedef.sira % hedef.havuz_boyu) + 1],
      hedef.havuz[((hedef.sira + 1) % hedef.havuz_boyu) + 1],
      hedef.havuz[((hedef.sira + 2) % hedef.havuz_boyu) + 1]
    ])
FROM hedef
WHERE p.id = hedef.id;

DO $$
DECLARE
  vitrin int;
  tek_ilk int;
  yanlis_adet int;
  dis_baglanti int;
BEGIN
  SELECT count(*) INTO vitrin
  FROM public.stores s
  WHERE s.is_demo = true
    AND s.user_id IS NULL
    AND EXISTS (SELECT 1 FROM public.products p WHERE p.store_id = s.id AND p.is_active = true);

  IF vitrin <> 30 THEN
    RAISE EXCEPTION 'FOTOGRAF_DAGITIMI_DUSTU: % vitrin kapsandi, 30 bekleniyordu', vitrin;
  END IF;

  SELECT count(*) INTO tek_ilk
  FROM (
    SELECT s.id
    FROM public.stores s
    JOIN public.products p ON p.store_id = s.id AND p.is_active = true
    WHERE s.is_demo = true AND s.user_id IS NULL
    GROUP BY s.id
    HAVING count(DISTINCT p.image_urls ->> 0) <> count(*)
  ) x;

  IF tek_ilk > 0 THEN
    RAISE EXCEPTION 'FOTOGRAF_DAGITIMI_DUSTU: % vitrinde urunler ayni ilk fotografi paylasiyor', tek_ilk;
  END IF;

  SELECT count(*) INTO yanlis_adet
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  WHERE s.is_demo = true AND s.user_id IS NULL AND p.is_active = true
    AND jsonb_array_length(p.image_urls) <> 3;

  IF yanlis_adet > 0 THEN
    RAISE EXCEPTION 'FOTOGRAF_DAGITIMI_DUSTU: % urunde fotograf sayisi 3 degil', yanlis_adet;
  END IF;

  SELECT count(*) INTO dis_baglanti
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  WHERE s.is_demo = true AND s.user_id IS NULL AND p.is_active = true
    AND p.image_urls::text ILIKE '%unsplash%';

  IF dis_baglanti > 0 THEN
    RAISE EXCEPTION 'FOTOGRAF_DAGITIMI_DUSTU: % urunde dis baglanti var', dis_baglanti;
  END IF;
END $$;

COMMIT;
