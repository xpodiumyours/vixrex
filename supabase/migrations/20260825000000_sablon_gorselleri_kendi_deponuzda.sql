-- Şablon görsellerini harici barındırıcıdan (Unsplash) proje storage'ına taşıma.
-- #235: hazır vitrin görselleri tek harici kaynağa bağımlıydı; kaynak
-- değişirse tüm kategorilerin hazır görselleri aynı anda kırılıyordu.
-- Gerçekleşme: canlıdaki 349 satırın 23'ünün Unsplash adresi zaten ölmüştü
-- (HTTP 404) — o satırlar pasifleştiriliyor; hiçbir vitrin/ürün etkilenmiyordu
-- (2026-08-25'te sorguyla doğrulandı).
--
-- Ön koşul: sağlam görseller 'category-templates' bucket'ına önceden yüklenmiş
--   olmalı (tool/sablon_gorsellerini_tasi.mjs --upload --anon).
-- Idempotent: UPDATE'ler WHERE image_url=eski koşuluyla çalışır; ikinci koşu no-op.
-- Mevcut vitrin/ürün satırlarına dokunulmaz — yalnız şablon havuzu güncellenir.

-- Bucket tanımı: yerel/taze ortamlar için (canlıda zaten mevcut).
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('category-templates', 'category-templates', true, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.category_image_templates ADD COLUMN IF NOT EXISTS source_url text;
COMMENT ON COLUMN public.category_image_templates.source_url IS '#235: taşınmadan önceki harici (Unsplash) adres — lisans/kaynak sorguları için';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-1-69582d.jpg', source_url = 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-2-2b2b0a.jpg', source_url = 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-3-6ce3d3.jpg', source_url = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-4-1748b5.jpg', source_url = 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-5-897bf0.jpg', source_url = 'https://images.unsplash.com/photo-1608748010899-18f300247112?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1608748010899-18f300247112?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-6-c667b5.jpg', source_url = 'https://images.unsplash.com/photo-1578932750294-f5075e85f44a?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1578932750294-f5075e85f44a?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-7-0cc974.jpg', source_url = 'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-8-6f5d2a.jpg', source_url = 'https://images.unsplash.com/photo-1506152983158-b4a74a01c721?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1506152983158-b4a74a01c721?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-9-e103f9.jpg', source_url = 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/cover-10-02cc44.jpg', source_url = 'https://images.unsplash.com/photo-1537832816519-689ad163238b?w=1200&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1537832816519-689ad163238b?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-1-258715.jpg', source_url = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-2-beff11.jpg', source_url = 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-3-cc0698.jpg', source_url = 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-4-8f135f.jpg', source_url = 'https://images.unsplash.com/photo-1618220179428-22790b461013?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1618220179428-22790b461013?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-5-1ac861.jpg', source_url = 'https://images.unsplash.com/photo-1603252109303-2751441dd157?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1603252109303-2751441dd157?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-6-5178d4.jpg', source_url = 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-7-6c3568.jpg', source_url = 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-8-c4536e.jpg', source_url = 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-9-ec5931.jpg', source_url = 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/gallery-10-9f8f7b.jpg', source_url = 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/logo_placeholder-1-ba1e34.jpg', source_url = 'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=512&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-1-e2382f.jpg', source_url = 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-2-0ec1ae.jpg', source_url = 'https://images.unsplash.com/photo-1509319117193-57bab727e09d?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1509319117193-57bab727e09d?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-3-d25af6.jpg', source_url = 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-4-d1c245.jpg', source_url = 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-5-df9c81.jpg', source_url = 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-6-e6695a.jpg', source_url = 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-7-47f047.jpg', source_url = 'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-8-c7d788.jpg', source_url = 'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-9-8c120b.jpg', source_url = 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/butik/product-10-0d43ef.jpg', source_url = 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=600&q=80', updated_at = now()
WHERE category_key = 'butik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/cover-1-6d5475.jpg', source_url = 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=1200&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/cover-2-9bc5b2.jpg', source_url = 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/cover-3-7bdece.jpg', source_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=1200&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/cover-4-19f45d.jpg', source_url = 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=1200&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/gallery-1-3c3210.jpg', source_url = 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/gallery-2-fe7faf.jpg', source_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/gallery-3-3b6923.jpg', source_url = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/gallery-4-740916.jpg', source_url = 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/gallery-5-e6bd5b.jpg', source_url = 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=800&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/logo_placeholder-1-28fb97.jpg', source_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=512&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/product-1-8f6ceb.jpg', source_url = 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/product-2-c2edd0.jpg', source_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=600&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/product-3-b041e8.jpg', source_url = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/product-4-a4c318.jpg', source_url = 'https://images.unsplash.com/photo-1567225557594-88d73e55f2cb?w=600&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1567225557594-88d73e55f2cb?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/dekorasyon/product-5-6a2a01.jpg', source_url = 'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=600&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/cover-1-c1ef66.jpg', source_url = 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=1200&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/cover-2-736af8.jpg', source_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/cover-3-cc7904.jpg', source_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/cover-4-338366.jpg', source_url = 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=1200&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/cover-5-aa8689.jpg', source_url = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-1-f59145.jpg', source_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-2-e31874.jpg', source_url = 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=800&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-3-b752fa.jpg', source_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/gallery-5-b21d99.jpg', source_url = 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/logo_placeholder-1-6568ff.jpg', source_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=512&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-1-ee52a7.jpg', source_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-2-c768fb.jpg', source_url = 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=600&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-3-f47b81.jpg', source_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=600&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-4-ed54fd.jpg', source_url = 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=600&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/diger/product-5-d58ba8.jpg', source_url = 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/cover-1-812109.jpg', source_url = 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=1200&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/cover-2-b8bf36.jpg', source_url = 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=1200&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/cover-3-d4df19.jpg', source_url = 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=1200&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/cover-5-e157e3.jpg', source_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/gallery-1-39c5e0.jpg', source_url = 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=800&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/gallery-2-6b9014.jpg', source_url = 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/gallery-3-c7a5c6.jpg', source_url = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/gallery-4-03cc4c.jpg', source_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/gallery-5-a4e588.jpg', source_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=800&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/logo_placeholder-1-81c210.jpg', source_url = 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=512&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/product-1-3257e1.jpg', source_url = 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=600&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/product-2-6af0c0.jpg', source_url = 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/product-3-89dbae.jpg', source_url = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/product-4-81146a.jpg', source_url = 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/egitim_ders/product-5-ff01a2.jpg', source_url = 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=600&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/cover-1-51a3b5.jpg', source_url = 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=1200&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/cover-2-08374c.jpg', source_url = 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=1200&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/cover-3-3837b6.jpg', source_url = 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=1200&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/cover-4-7b1024.jpg', source_url = 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=1200&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/cover-5-6ed232.jpg', source_url = 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=1200&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-1-e028e5.jpg', source_url = 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-2-024b62.jpg', source_url = 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-3-73e2fb.jpg', source_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-4-3916e4.jpg', source_url = 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=800&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/gallery-5-76d810.jpg', source_url = 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/logo_placeholder-1-383529.jpg', source_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=512&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-1-c50a72.jpg', source_url = 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=600&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-2-32129d.jpg', source_url = 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-3-5c50d9.jpg', source_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=600&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-4-51e153.jpg', source_url = 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/elektronik/product-5-2271c9.jpg', source_url = 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=600&q=80', updated_at = now()
WHERE category_key = 'elektronik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/cover-1-42536c.jpg', source_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=1200&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/cover-2-c849cd.jpg', source_url = 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=1200&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/cover-3-e3876c.jpg', source_url = 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=1200&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/cover-4-f6f985.jpg', source_url = 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=1200&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/gallery-1-b84d0c.jpg', source_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/gallery-2-64f555.jpg', source_url = 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=800&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/gallery-3-a4d668.jpg', source_url = 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=800&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/gallery-4-b7575d.jpg', source_url = 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=800&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/logo_placeholder-1-7d2fcc.jpg', source_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=512&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/product-1-81126b.jpg', source_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/product-2-418833.jpg', source_url = 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=600&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/product-3-06bcff.jpg', source_url = 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=600&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/ev_temizlik/product-5-4ed0ef.jpg', source_url = 'https://images.unsplash.com/photo-1527515545081-5db817172677?w=600&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1527515545081-5db817172677?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/cover-1-0842b5.jpg', source_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1200&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/cover-2-abf2e8.jpg', source_url = 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=1200&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/cover-3-204be8.jpg', source_url = 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=1200&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/cover-4-f8fd44.jpg', source_url = 'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=1200&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/gallery-1-b648b6.jpg', source_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/gallery-2-3e2433.jpg', source_url = 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=800&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/gallery-3-f959dc.jpg', source_url = 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=800&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/gallery-4-9b69b8.jpg', source_url = 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/gallery-5-2096b4.jpg', source_url = 'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=800&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/logo_placeholder-1-a854cd.jpg', source_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=512&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/product-1-699240.jpg', source_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/product-2-167866.jpg', source_url = 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/product-3-41c78e.jpg', source_url = 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=600&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/product-4-850dcd.jpg', source_url = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/firin/product-5-034ed7.jpg', source_url = 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/cover-1-cc7904.jpg', source_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/cover-2-736af8.jpg', source_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/cover-3-2dd678.jpg', source_url = 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1200&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/cover-4-5bc8a3.jpg', source_url = 'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=1200&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/cover-5-7510f9.jpg', source_url = 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=1200&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-1-6c3427.jpg', source_url = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-2-45457c.jpg', source_url = 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=800&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-3-7b46e4.jpg', source_url = 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=800&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/gallery-5-35b6e3.jpg', source_url = 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?w=800&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/logo_placeholder-1-bbe9fd.jpg', source_url = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=512&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-1-c718d1.jpg', source_url = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-2-4985ba.jpg', source_url = 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=600&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-3-f0e6dc.jpg', source_url = 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=600&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-4-9c1593.jpg', source_url = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/gida/product-5-e4141f.jpg', source_url = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-1-2b2b0a.jpg', source_url = 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-2-69582d.jpg', source_url = 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-3-b5fc5c.jpg', source_url = 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-4-ca6ba1.jpg', source_url = 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-5-6ab652.jpg', source_url = 'https://images.unsplash.com/photo-1505022610485-0249ba5b3675?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1505022610485-0249ba5b3675?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-6-be9319.jpg', source_url = 'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-7-8e7773.jpg', source_url = 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/cover-8-831ac9.jpg', source_url = 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1200&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-1-5cf119.jpg', source_url = 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-2-74a618.jpg', source_url = 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-3-6348d8.jpg', source_url = 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-4-8ebb75.jpg', source_url = 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-5-274039.jpg', source_url = 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-6-87f1fd.jpg', source_url = 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-7-8075d7.jpg', source_url = 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/gallery-8-1e3bd7.jpg', source_url = 'https://images.unsplash.com/photo-1554568218-0f1715e72254?w=800&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1554568218-0f1715e72254?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/logo_placeholder-1-7c1a49.jpg', source_url = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=512&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-1-68eaa9.jpg', source_url = 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-2-030a80.jpg', source_url = 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-3-40b9e3.jpg', source_url = 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-4-0f96d7.jpg', source_url = 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-5-119484.jpg', source_url = 'https://images.unsplash.com/photo-1492707892479-7bc8d5a4ee93?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1492707892479-7bc8d5a4ee93?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-7-136d04.jpg', source_url = 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/giyim/product-8-45dd1d.jpg', source_url = 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/cover-1-e157e3.jpg', source_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/cover-2-453007.jpg', source_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/cover-3-fabcfe.jpg', source_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=1200&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/cover-4-c7d106.jpg', source_url = 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=1200&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/cover-5-7a21b6.jpg', source_url = 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=1200&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/gallery-1-ab66f5.jpg', source_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/gallery-2-03cc4c.jpg', source_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/gallery-3-a4e588.jpg', source_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=800&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/gallery-4-0c67d0.jpg', source_url = 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/logo_placeholder-1-8f10d1.jpg', source_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=512&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/product-1-842831.jpg', source_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/product-2-929c41.jpg', source_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=600&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/hizmet_danismanlik/product-3-a8ea9f.jpg', source_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-1-8448f1.jpg', source_url = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-2-8812c7.jpg', source_url = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-3-a598d4.jpg', source_url = 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-4-564006.jpg', source_url = 'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-5-97c47f.jpg', source_url = 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-6-af50a5.jpg', source_url = 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-7-5bc8a3.jpg', source_url = 'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/cover-8-5e784d.jpg', source_url = 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=1200&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-1-207ae2.jpg', source_url = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-2-b20986.jpg', source_url = 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-3-b63ef6.jpg', source_url = 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-4-dfe420.jpg', source_url = 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-6-a0fe95.jpg', source_url = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-7-6026d9.jpg', source_url = 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/gallery-8-e510e9.jpg', source_url = 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/logo_placeholder-1-51c40c.jpg', source_url = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=512&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-1-ffef38.jpg', source_url = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-2-30b98b.jpg', source_url = 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-3-57cb36.jpg', source_url = 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-4-156d1b.jpg', source_url = 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-5-f45f60.jpg', source_url = 'https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-6-15eb04.jpg', source_url = 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-7-e2b5da.jpg', source_url = 'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kafe_lokanta/product-8-a7bbb8.jpg', source_url = 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/cover-1-91edf5.jpg', source_url = 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=1200&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/cover-2-8f7218.jpg', source_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=1200&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/cover-3-5f972b.jpg', source_url = 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=1200&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/gallery-1-49037e.jpg', source_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=800&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/gallery-2-5d4c5e.jpg', source_url = 'https://images.unsplash.com/photo-1516962215378-7fa2e137ae93?w=800&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1516962215378-7fa2e137ae93?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/gallery-3-2485df.jpg', source_url = 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=800&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/gallery-4-50fd84.jpg', source_url = 'https://images.unsplash.com/photo-1569003339405-ea396a5a8a90?w=800&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1569003339405-ea396a5a8a90?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/gallery-5-832a3f.jpg', source_url = 'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=800&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/logo_placeholder-1-4e9d01.jpg', source_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=512&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/product-1-ee7f78.jpg', source_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=600&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/product-2-9eec80.jpg', source_url = 'https://images.unsplash.com/photo-1516962215378-7fa2e137ae93?w=600&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1516962215378-7fa2e137ae93?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/product-3-859d28.jpg', source_url = 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=600&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kirtasiye/product-5-d0658f.jpg', source_url = 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=600&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/cover-1-b784d7.jpg', source_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/cover-2-fbb6b3.jpg', source_url = 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1200&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/cover-3-423ab1.jpg', source_url = 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=1200&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/cover-4-e80f64.jpg', source_url = 'https://images.unsplash.com/photo-1633681926035-ec1ac984418a?w=1200&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1633681926035-ec1ac984418a?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/cover-5-ea3901.jpg', source_url = 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=1200&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/gallery-1-d84453.jpg', source_url = 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=800&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/gallery-2-b25b00.jpg', source_url = 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/gallery-3-91e3a4.jpg', source_url = 'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=800&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/gallery-4-98f329.jpg', source_url = 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/gallery-5-4efac3.jpg', source_url = 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=800&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/logo_placeholder-1-6f84d1.jpg', source_url = 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=512&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/product-1-a0725d.jpg', source_url = 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=600&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/product-2-fca316.jpg', source_url = 'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=600&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kozmetik/product-3-0cdaab.jpg', source_url = 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/cover-1-e4f210.jpg', source_url = 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/cover-2-b784d7.jpg', source_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/cover-3-ce444c.jpg', source_url = 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/cover-5-95aadc.jpg', source_url = 'https://images.unsplash.com/photo-1634449571010-02389ed0f9b0?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1634449571010-02389ed0f9b0?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/cover-6-a32cc1.jpg', source_url = 'https://images.unsplash.com/photo-1612817288484-6f916006741a?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1612817288484-6f916006741a?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/cover-8-bce53a.jpg', source_url = 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-1-e7acd0.jpg', source_url = 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-2-53693d.jpg', source_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-3-8eeb7b.jpg', source_url = 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-4-0a959f.jpg', source_url = 'https://images.unsplash.com/photo-1515688594390-b649af70d282?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1515688594390-b649af70d282?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-5-53b2e1.jpg', source_url = 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-6-d08def.jpg', source_url = 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/gallery-8-cf8491.jpg', source_url = 'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/logo_placeholder-1-7073b6.jpg', source_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=512&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-1-080c62.jpg', source_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-2-bae2f3.jpg', source_url = 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-3-33cfb4.jpg', source_url = 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-4-c35880.jpg', source_url = 'https://images.unsplash.com/photo-1633681926035-ec1ac984418a?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1633681926035-ec1ac984418a?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-5-1c48dc.jpg', source_url = 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-6-3f3013.jpg', source_url = 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/kuafor/product-7-8761f2.jpg', source_url = 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/cover-1-54d954.jpg', source_url = 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=1200&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/cover-2-0860ac.jpg', source_url = 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=1200&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/cover-3-75dfec.jpg', source_url = 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=1200&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/cover-4-8f7de9.jpg', source_url = 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1200&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/cover-5-45c2a4.jpg', source_url = 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?w=1200&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/cover-6-4ebe41.jpg', source_url = 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=1200&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/gallery-1-196334.jpg', source_url = 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=800&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/gallery-2-b0b2db.jpg', source_url = 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=800&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/gallery-3-279c99.jpg', source_url = 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=800&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/gallery-4-79ab25.jpg', source_url = 'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?w=800&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/gallery-5-a78c62.jpg', source_url = 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/gallery-6-b0c38b.jpg', source_url = 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=800&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/logo_placeholder-1-e4695d.jpg', source_url = 'https://images.unsplash.com/photo-1551522435-a13afa10f103?w=512&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1551522435-a13afa10f103?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/product-1-074f2d.jpg', source_url = 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=600&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/product-2-d1944b.jpg', source_url = 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=600&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/product-3-6ba392.jpg', source_url = 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=600&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/product-4-5c5c62.jpg', source_url = 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=600&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/product-5-80de58.jpg', source_url = 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/oto_arac/product-6-a1b050.jpg', source_url = 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600&q=80', updated_at = now()
WHERE category_key = 'oto_arac' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/cover-1-e7fedd.jpg', source_url = 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=1200&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/cover-2-e1dbf7.jpg', source_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=1200&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/cover-3-a17c83.jpg', source_url = 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=1200&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/cover-4-9b4273.jpg', source_url = 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=1200&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/cover-5-06fa03.jpg', source_url = 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=1200&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/gallery-1-4e0b64.jpg', source_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/gallery-2-472ff4.jpg', source_url = 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=800&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/gallery-3-7c4c6f.jpg', source_url = 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/gallery-4-de4240.jpg', source_url = 'https://images.unsplash.com/photo-1596492784531-6e6eb5ea9993?w=800&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1596492784531-6e6eb5ea9993?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/gallery-5-115554.jpg', source_url = 'https://images.unsplash.com/photo-1415369629372-26f2fe60c467?w=800&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1415369629372-26f2fe60c467?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/logo_placeholder-1-e28231.jpg', source_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=512&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/product-1-706445.jpg', source_url = 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=600&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/product-2-82efea.jpg', source_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=600&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/product-3-dc498d.jpg', source_url = 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=600&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/pet_shop_veteriner/product-4-fe21d0.jpg', source_url = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/cover-1-0e480b.jpg', source_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=1200&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/cover-2-a9d994.jpg', source_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=1200&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/cover-3-0bf264.jpg', source_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=1200&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/cover-4-a6ec8d.jpg', source_url = 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=1200&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/cover-5-094d39.jpg', source_url = 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?w=1200&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/gallery-1-f178ec.jpg', source_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/gallery-2-99b37e.jpg', source_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/gallery-3-82e07a.jpg', source_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=800&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/gallery-4-2c502d.jpg', source_url = 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=800&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/gallery-5-7db2a0.jpg', source_url = 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=800&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/logo_placeholder-1-7e8fca.jpg', source_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=512&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/product-1-5dd5f3.jpg', source_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=600&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/product-2-6616ba.jpg', source_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/product-3-b28111.jpg', source_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=600&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/product-4-8f31ec.jpg', source_url = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=600&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/saglik_yasam/product-5-eee565.jpg', source_url = 'https://images.unsplash.com/photo-1581594693702-fbdc51b2763b?w=600&q=80', updated_at = now()
WHERE category_key = 'saglik_yasam' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1581594693702-fbdc51b2763b?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/cover-1-f0b324.jpg', source_url = 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/cover-2-3c8367.jpg', source_url = 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/cover-3-15392b.jpg', source_url = 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=1200&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/cover-4-499e72.jpg', source_url = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/cover-5-332838.jpg', source_url = 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=1200&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/gallery-1-46ecef.jpg', source_url = 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/gallery-2-53a296.jpg', source_url = 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/gallery-3-0c8cce.jpg', source_url = 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/gallery-4-9a2d32.jpg', source_url = 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=800&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/gallery-5-661b45.jpg', source_url = 'https://images.unsplash.com/photo-1594882645126-14020914d58d?w=800&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1594882645126-14020914d58d?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/logo_placeholder-1-06c92c.jpg', source_url = 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=512&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/product-1-ef4a8e.jpg', source_url = 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/product-2-b785e7.jpg', source_url = 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/product-3-5ee32b.jpg', source_url = 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=600&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/product-4-9e50d1.jpg', source_url = 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/spor_fitness/product-5-c5ef87.jpg', source_url = 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=600&q=80', updated_at = now()
WHERE category_key = 'spor_fitness' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/cover-1-0a6bd2.jpg', source_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=1200&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/cover-2-e2317c.jpg', source_url = 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=1200&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/cover-3-3f0e5c.jpg', source_url = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=1200&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/cover-4-9243df.jpg', source_url = 'https://images.unsplash.com/photo-1588508065123-287b28e013da?w=1200&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1588508065123-287b28e013da?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/cover-5-f297a8.jpg', source_url = 'https://images.unsplash.com/photo-1597733336794-12d05021d510?w=1200&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1597733336794-12d05021d510?w=1200&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-1-d1dbdf.jpg', source_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-2-4881c1.jpg', source_url = 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=800&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-3-9b1a57.jpg', source_url = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-4-4ad978.jpg', source_url = 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/gallery-5-8191f9.jpg', source_url = 'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=800&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=800&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/logo_placeholder-1-383529.jpg', source_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=512&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'logo_placeholder' AND image_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=512&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-1-f61804.jpg', source_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-2-006ee3.jpg', source_url = 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=600&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-3-869878.jpg', source_url = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-4-8a70ab.jpg', source_url = 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&q=80';

UPDATE public.category_image_templates
SET image_url = 'https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/teknik_servis/product-5-24629e.jpg', source_url = 'https://images.unsplash.com/photo-1563770660941-20978e870e26?w=600&q=80', updated_at = now()
WHERE category_key = 'teknik_servis' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1563770660941-20978e870e26?w=600&q=80';
-- Unsplash'te artık yok (404): dekorasyon/cover/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1585418694458-5f28582413b2?w=1200&q=80', updated_at = now()
WHERE category_key = 'dekorasyon' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1585418694458-5f28582413b2?w=1200&q=80';

-- Unsplash'te artık yok (404): diger/gallery/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1472851294608-062f824d296e?w=800&q=80', updated_at = now()
WHERE category_key = 'diger' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1472851294608-062f824d296e?w=800&q=80';

-- Unsplash'te artık yok (404): egitim_ders/cover/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1553871373-d15224ef1f6d?w=1200&q=80', updated_at = now()
WHERE category_key = 'egitim_ders' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1553871373-d15224ef1f6d?w=1200&q=80';

-- Unsplash'te artık yok (404): ev_temizlik/cover/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1528740561666-bd247e66ad50?w=1200&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1528740561666-bd247e66ad50?w=1200&q=80';

-- Unsplash'te artık yok (404): ev_temizlik/gallery/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1609770231080-e321deccc344?w=800&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1609770231080-e321deccc344?w=800&q=80';

-- Unsplash'te artık yok (404): ev_temizlik/product/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1585421514738-ee1a3b2e5ef0?w=600&q=80', updated_at = now()
WHERE category_key = 'ev_temizlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1585421514738-ee1a3b2e5ef0?w=600&q=80';

-- Unsplash'te artık yok (404): firin/cover/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1463797224155-85a9ee92767a?w=1200&q=80', updated_at = now()
WHERE category_key = 'firin' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1463797224155-85a9ee92767a?w=1200&q=80';

-- Unsplash'te artık yok (404): gida/gallery/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1543083507-993b77bb708e?w=800&q=80', updated_at = now()
WHERE category_key = 'gida' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1543083507-993b77bb708e?w=800&q=80';

-- Unsplash'te artık yok (404): giyim/product/6
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1495385794356-15371f548e61?w=600&q=80', updated_at = now()
WHERE category_key = 'giyim' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1495385794356-15371f548e61?w=600&q=80';

-- Unsplash'te artık yok (404): hizmet_danismanlik/gallery/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1516321307626-f440ee48af35?w=800&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1516321307626-f440ee48af35?w=800&q=80';

-- Unsplash'te artık yok (404): hizmet_danismanlik/product/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1552581234-2612b75dc89c?w=600&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1552581234-2612b75dc89c?w=600&q=80';

-- Unsplash'te artık yok (404): hizmet_danismanlik/product/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1521791136364-7221f70f6f59?w=600&q=80', updated_at = now()
WHERE category_key = 'hizmet_danismanlik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1521791136364-7221f70f6f59?w=600&q=80';

-- Unsplash'te artık yok (404): kafe_lokanta/gallery/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1620921556828-d7dc29ef0488?w=800&q=80', updated_at = now()
WHERE category_key = 'kafe_lokanta' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1620921556828-d7dc29ef0488?w=800&q=80';

-- Unsplash'te artık yok (404): kirtasiye/cover/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1586075010923-2dd45e9b2d4f?w=1200&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1586075010923-2dd45e9b2d4f?w=1200&q=80';

-- Unsplash'te artık yok (404): kirtasiye/cover/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1515041408953-5b87ac0a4245?w=1200&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1515041408953-5b87ac0a4245?w=1200&q=80';

-- Unsplash'te artık yok (404): kirtasiye/product/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1519791883288-db8bc6bb1f23?w=600&q=80', updated_at = now()
WHERE category_key = 'kirtasiye' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1519791883288-db8bc6bb1f23?w=600&q=80';

-- Unsplash'te artık yok (404): kozmetik/product/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1507081329363-9524582389e3?w=600&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1507081329363-9524582389e3?w=600&q=80';

-- Unsplash'te artık yok (404): kozmetik/product/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1608248597481-496100c8c836?w=600&q=80', updated_at = now()
WHERE category_key = 'kozmetik' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1608248597481-496100c8c836?w=600&q=80';

-- Unsplash'te artık yok (404): kuafor/cover/4
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1521590832167-7bcbfea6331f?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1521590832167-7bcbfea6331f?w=1200&q=80';

-- Unsplash'te artık yok (404): kuafor/cover/7
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1522335939835-0347101999b4?w=1200&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'cover' AND image_url = 'https://images.unsplash.com/photo-1522335939835-0347101999b4?w=1200&q=80';

-- Unsplash'te artık yok (404): kuafor/gallery/7
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1527799863830-580c3b0dc7f2?w=800&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'gallery' AND image_url = 'https://images.unsplash.com/photo-1527799863830-580c3b0dc7f2?w=800&q=80';

-- Unsplash'te artık yok (404): kuafor/product/8
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1507081329363-9524582389e3?w=600&q=80', updated_at = now()
WHERE category_key = 'kuafor' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1507081329363-9524582389e3?w=600&q=80';

-- Unsplash'te artık yok (404): pet_shop_veteriner/product/5
UPDATE public.category_image_templates
SET is_active = false, source_url = 'https://images.unsplash.com/photo-1537151608828-ea2b117b62e4?w=600&q=80', updated_at = now()
WHERE category_key = 'pet_shop_veteriner' AND image_type = 'product' AND image_url = 'https://images.unsplash.com/photo-1537151608828-ea2b117b62e4?w=600&q=80';

-- Geçici yükleme politikası her durumda kapalı başlar (gerekirse elle açılır):
DROP POLICY IF EXISTS "tmp_anon_fill_category_templates" ON storage.objects;
