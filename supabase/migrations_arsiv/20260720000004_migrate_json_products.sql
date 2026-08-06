-- ============================================================================
-- Aşama 2: Mevcut JSON ürünlerini ilişkisel tabloya taşıma
--
-- Bu migration stores tablosundaki products JSONB alanını
-- yeni products tablosuna aktarır. JSON verisi SİLİNMEZ.
--
-- Mevcut JSON yapısı:
--   product_categories: [{id, name, sortOrder}]  (slug YOK)
--   products: [{id, name, description, price, category, imageUrls, isVisible, source, sortOrder}]
-- ============================================================================

-- 1. ÖNCE KONTROL: Kaç mağazada ürün var?
SELECT
  s.slug as magaza,
  s.name as adi,
  jsonb_array_length(s.products) as json_urun_sayisi,
  jsonb_array_length(s.product_categories) as json_kategori_sayisi,
  s.product_storage_version
FROM public.stores s
WHERE jsonb_array_length(s.products) > 0;

-- 2. KATEGORİLERİ TAŞI
-- slug name'den üretilir (JSON'da slug alanı yok)
INSERT INTO public.product_categories (store_id, name, slug, sort_order, is_active)
SELECT
  s.id as store_id,
  trim(cat->>'name') as name,
  lower(replace(replace(replace(trim(cat->>'name'), ' ', '-'), '.', ''), ',', '')) as slug,
  COALESCE((cat->>'sortOrder')::int, 0) as sort_order,
  true as is_active
FROM public.stores s,
     jsonb_array_elements(s.product_categories) as cat
WHERE jsonb_array_length(s.product_categories) > 0
  AND s.product_storage_version = 1
  AND trim(cat->>'name') IS NOT NULL
  AND trim(cat->>'name') != ''
ON CONFLICT (store_id, slug) DO NOTHING;

-- 3. ÜRÜNLERİ TAŞI
INSERT INTO public.products (
  store_id, category_id, source_type, name, slug,
  description, price_text, image_urls, is_visible, sort_order
)
SELECT
  s.id as store_id,
  -- Kategori eşleştirmesi: ürünün category alanı ile category name'ini eşleştir
  (SELECT pc.id FROM public.product_categories pc
   WHERE pc.store_id = s.id
     AND lower(pc.name) = lower(trim(prod->>'category'))
   LIMIT 1) as category_id,
  COALESCE(prod->>'source', 'manual') as source_type,
  trim(prod->>'name') as name,
  -- Slug: ürün adından üret
  lower(replace(replace(replace(replace(replace(
    trim(prod->>'name'),
    ' ', '-'), '.', ''), ',', ''), 'İ', 'i'), 'I', 'ı')) as slug,
  COALESCE(prod->>'description', '') as description,
  COALESCE(prod->>'price', '') as price_text,
  COALESCE(prod->'imageUrls', '[]'::jsonb) as image_urls,
  COALESCE((prod->>'isVisible')::boolean, true) as is_visible,
  COALESCE((prod->>'sortOrder')::int, 0) as sort_order
FROM public.stores s,
     jsonb_array_elements(s.products) as prod
WHERE jsonb_array_length(s.products) > 0
  AND s.product_storage_version = 1
  AND trim(prod->>'name') IS NOT NULL
  AND trim(prod->>'name') != ''
ON CONFLICT (store_id, slug) DO NOTHING;

-- 4. ÜRÜN SAYILARINI KARŞILAŞTIR
SELECT
  s.slug as magaza,
  jsonb_array_length(s.products) as json_sayisi,
  (SELECT count(*) FROM public.products p WHERE p.store_id = s.id) as tablo_sayisi,
  CASE
    WHEN jsonb_array_length(s.products) = (SELECT count(*) FROM public.products p WHERE p.store_id = s.id)
    THEN 'ESLESTI'
    ELSE 'FARK VAR'
  END as durum
FROM public.stores s
WHERE jsonb_array_length(s.products) > 0
  AND s.product_storage_version = 1;

-- 5. VERSİYONU GÜNCELLE
UPDATE public.stores
SET product_storage_version = 2
WHERE product_storage_version = 1
  AND jsonb_array_length(products) > 0;

-- 6. SONUÇ RAPORU
SELECT
  'TAMAMLANDI' as durum,
  (SELECT count(*) FROM public.stores WHERE product_storage_version = 2) as tasinan_magaza,
  (SELECT count(*) FROM public.stores WHERE product_storage_version = 1) as eski_sistem,
  (SELECT count(*) FROM public.products) as toplam_urun,
  (SELECT count(*) FROM public.product_categories) as toplam_kategori;
