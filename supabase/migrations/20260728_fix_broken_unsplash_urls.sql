-- ============================================================================
-- Kiralık Vitrin Kırık Unsplash Görsellerini Güncelleme Migration'ı
-- ============================================================================

-- 1. Kuaför Mağazası Logosu
UPDATE public.stores
SET logo_url = 'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=200&q=80'
WHERE slug = 'kiralik-kuafor';

-- 2. Keratin Bakımı (Kuaför)
UPDATE public.products
SET image_urls = '["https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=600&q=80"]'::jsonb
WHERE slug = 'keratin-bakimi';

-- 3. Avokado Toast (Kafe)
UPDATE public.products
SET image_urls = '["https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&q=80"]'::jsonb
WHERE slug = 'avokado-toast';

-- 4. Batarya Yenileme (Teknik Servis)
UPDATE public.products
SET image_urls = '["https://images.unsplash.com/photo-1580910051074-3eb694886505?w=600&q=80"]'::jsonb
WHERE slug = 'batarya-yenileme';

-- 5. Yöresel Zeytin Karma (Gıda)
UPDATE public.products
SET image_urls = '["https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=600&q=80"]'::jsonb
WHERE slug = 'yoresel-zeytin-karma';

-- 6. Çilek Reçeli (Gıda)
UPDATE public.products
SET image_urls = '["https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=600&q=80"]'::jsonb
WHERE slug = 'cilek-receli';

-- 7. Kuru Domates & Zeytinyağı (Gıda)
UPDATE public.products
SET image_urls = '["https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&q=80"]'::jsonb
WHERE slug = 'kuru-domates-zeytinyagi';
