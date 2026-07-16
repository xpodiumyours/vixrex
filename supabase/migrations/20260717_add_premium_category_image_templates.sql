-- ============================================================
-- Sprint 2: Kategori Sablon Premium Genisletme Migration
-- Her kategori en az 5 adet (Butik 10 adet) gorsele tamamlanir
-- ON CONFLICT kullanarak mevcut kayitlari bozmadan ekleme yapar
-- ============================================================

/*
  ── RAPORLAMA VE VERİ DOĞRULAMA SORGULARI ────────────────────

  1. Canli/Local tabloda ayni (category_key, image_type, image_url) kombinasyonuna 
     sahip duplicate kayitlari raporlama sorgusu:

     SELECT category_key, image_type, image_url, COUNT(*) as repeat_count
     FROM public.category_image_templates
     GROUP BY category_key, image_type, image_url
     HAVING COUNT(*) > 1;

  2. Ayni gorselin ayni kategori altinda farkli tiplerde (cover, gallery, product) 
     tekrar edip etmedigini denetleme sorgusu:

     SELECT category_key, image_url, COUNT(DISTINCT image_type) as type_count, string_agg(image_type, ', ') as types
     FROM public.category_image_templates
     GROUP BY category_key, image_url
     HAVING COUNT(DISTINCT image_type) > 1;

  3. Entegrasyon sonrasi kategori ve tip bazli guncel kayit sayisi raporlama sorgusu:

     SELECT category_key, image_type, COUNT(*) as image_count
     FROM public.category_image_templates
     WHERE is_active = true
     GROUP BY category_key, image_type
     ORDER BY category_key, image_type;
*/

-- 1. Tablo uzerinde (category_key, image_type, image_url) benzersizlik kisitinin (unique constraint) eklenmesi
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'uq_category_image_template_url'
      AND conrelid = 'public.category_image_templates'::regclass
  ) THEN
    ALTER TABLE public.category_image_templates 
      ADD CONSTRAINT uq_category_image_template_url 
      UNIQUE (category_key, image_type, image_url);
  END IF;
END $$;

-- 2. Yeni premium gorsellerin eklenmesi

-- Giyim Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=1200&q=80', 'Giyim Örnek Cover 4', 4),
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1505022610485-0249ba5b3675?w=1200&q=80', 'Giyim Örnek Cover 5', 5),
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=1200&q=80', 'Giyim Örnek Cover 6', 6),
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200&q=80', 'Giyim Örnek Cover 7', 7),
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1200&q=80', 'Giyim Örnek Cover 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Giyim Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800&q=80', 'Giyim Örnek Gallery 4', 4),
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&q=80', 'Giyim Örnek Gallery 5', 5),
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&q=80', 'Giyim Örnek Gallery 6', 6),
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800&q=80', 'Giyim Örnek Gallery 7', 7),
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1554568218-0f1715e72254?w=800&q=80', 'Giyim Örnek Gallery 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Giyim Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&q=80', 'Giyim Örnek Product 4', 4),
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1492707892479-7bc8d5a4ee93?w=600&q=80', 'Giyim Örnek Product 5', 5),
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1495385794356-15371f548e61?w=600&q=80', 'Giyim Örnek Product 6', 6),
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80', 'Giyim Örnek Product 7', 7),
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=600&q=80', 'Giyim Örnek Product 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Butik Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=1200&q=80', 'Butik Örnek Cover 4', 4),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1608748010899-18f300247112?w=1200&q=80', 'Butik Örnek Cover 5', 5),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1578932750294-f5075e85f44a?w=1200&q=80', 'Butik Örnek Cover 6', 6),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=1200&q=80', 'Butik Örnek Cover 7', 7),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1560243563-062bff001d68?w=1200&q=80', 'Butik Örnek Cover 8', 8),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=1200&q=80', 'Butik Örnek Cover 9', 9),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1537832816519-689ad163238b?w=1200&q=80', 'Butik Örnek Cover 10', 10)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Butik Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1618220179428-22790b461013?w=800&q=80', 'Butik Örnek Gallery 4', 4),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1603252109303-2751441dd157?w=800&q=80', 'Butik Örnek Gallery 5', 5),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800&q=80', 'Butik Örnek Gallery 6', 6),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&q=80', 'Butik Örnek Gallery 7', 7),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&q=80', 'Butik Örnek Gallery 8', 8),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&q=80', 'Butik Örnek Gallery 9', 9),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80', 'Butik Örnek Gallery 10', 10)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Butik Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=600&q=80', 'Butik Örnek Product 4', 4),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&q=80', 'Butik Örnek Product 5', 5),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80', 'Butik Örnek Product 6', 6),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=600&q=80', 'Butik Örnek Product 7', 7),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=600&q=80', 'Butik Örnek Product 8', 8),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=600&q=80', 'Butik Örnek Product 9', 9),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=600&q=80', 'Butik Örnek Product 10', 10)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Gıda Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('gida', 'Gıda', 'cover', 'https://images.unsplash.com/photo-1517433456452-f9633a875f6f?w=1200&q=80', 'Gıda Örnek Cover 4', 4),
('gida', 'Gıda', 'cover', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=1200&q=80', 'Gıda Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Gıda Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('gida', 'Gıda', 'gallery', 'https://images.unsplash.com/photo-1543083507-993b77bb708e?w=800&q=80', 'Gıda Örnek Gallery 4', 4),
('gida', 'Gıda', 'gallery', 'https://images.unsplash.com/photo-1608686207856-001b95cf60ca?w=800&q=80', 'Gıda Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Gıda Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('gida', 'Gıda', 'product', 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80', 'Gıda Örnek Product 4', 4),
('gida', 'Gıda', 'product', 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80', 'Gıda Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Fırın Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('firin', 'Fırın', 'cover', 'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=1200&q=80', 'Fırın Örnek Cover 4', 4),
('firin', 'Fırın', 'cover', 'https://images.unsplash.com/photo-1463797224155-85a9ee92767a?w=1200&q=80', 'Fırın Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Fırın Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('firin', 'Fırın', 'gallery', 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=800&q=80', 'Fırın Örnek Gallery 4', 4),
('firin', 'Fırın', 'gallery', 'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=800&q=80', 'Fırın Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Fırın Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('firin', 'Fırın', 'product', 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80', 'Fırın Örnek Product 4', 4),
('firin', 'Fırın', 'product', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80', 'Fırın Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kozmetik Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kozmetik', 'Kozmetik', 'cover', 'https://images.unsplash.com/photo-1633681926035-ec1ac984418a?w=1200&q=80', 'Kozmetik Örnek Cover 4', 4),
('kozmetik', 'Kozmetik', 'cover', 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=1200&q=80', 'Kozmetik Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kozmetik Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kozmetik', 'Kozmetik', 'gallery', 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800&q=80', 'Kozmetik Örnek Gallery 4', 4),
('kozmetik', 'Kozmetik', 'gallery', 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=800&q=80', 'Kozmetik Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kozmetik Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kozmetik', 'Kozmetik', 'product', 'https://images.unsplash.com/photo-1507081329363-9524582389e3?w=600&q=80', 'Kozmetik Örnek Product 4', 4),
('kozmetik', 'Kozmetik', 'product', 'https://images.unsplash.com/photo-1608248597481-496100c8c836?w=600&q=80', 'Kozmetik Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Dekorasyon Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('dekorasyon', 'Dekorasyon', 'cover', 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=1200&q=80', 'Dekorasyon Örnek Cover 4', 4),
('dekorasyon', 'Dekorasyon', 'cover', 'https://images.unsplash.com/photo-1585418694458-5f28582413b2?w=1200&q=80', 'Dekorasyon Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Dekorasyon Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('dekorasyon', 'Dekorasyon', 'gallery', 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80', 'Dekorasyon Örnek Gallery 4', 4),
('dekorasyon', 'Dekorasyon', 'gallery', 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=800&q=80', 'Dekorasyon Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Dekorasyon Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('dekorasyon', 'Dekorasyon', 'product', 'https://images.unsplash.com/photo-1567225557594-88d73e55f2cb?w=600&q=80', 'Dekorasyon Örnek Product 4', 4),
('dekorasyon', 'Dekorasyon', 'product', 'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=600&q=80', 'Dekorasyon Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Elektronik Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('elektronik', 'Elektronik', 'cover', 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=1200&q=80', 'Elektronik Örnek Cover 4', 4),
('elektronik', 'Elektronik', 'cover', 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=1200&q=80', 'Elektronik Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Elektronik Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('elektronik', 'Elektronik', 'gallery', 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=800&q=80', 'Elektronik Örnek Gallery 4', 4),
('elektronik', 'Elektronik', 'gallery', 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800&q=80', 'Elektronik Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Elektronik Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('elektronik', 'Elektronik', 'product', 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&q=80', 'Elektronik Örnek Product 4', 4),
('elektronik', 'Elektronik', 'product', 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=600&q=80', 'Elektronik Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kırtasiye Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kirtasiye', 'Kırtasiye', 'cover', 'https://images.unsplash.com/photo-1586075010923-2dd45e9b2d4f?w=1200&q=80', 'Kırtasiye Örnek Cover 4', 4),
('kirtasiye', 'Kırtasiye', 'cover', 'https://images.unsplash.com/photo-1515041408953-5b87ac0a4245?w=1200&q=80', 'Kırtasiye Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kırtasiye Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kirtasiye', 'Kırtasiye', 'gallery', 'https://images.unsplash.com/photo-1569003339405-ea396a5a8a90?w=800&q=80', 'Kırtasiye Örnek Gallery 4', 4),
('kirtasiye', 'Kırtasiye', 'gallery', 'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=800&q=80', 'Kırtasiye Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kırtasiye Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kirtasiye', 'Kırtasiye', 'product', 'https://images.unsplash.com/photo-1519791883288-db8bc6bb1f23?w=600&q=80', 'Kırtasiye Örnek Product 4', 4),
('kirtasiye', 'Kırtasiye', 'product', 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=600&q=80', 'Kırtasiye Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kafe / Lokanta Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=1200&q=80', 'Kafe / Lokanta Örnek Cover 4', 4),
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=1200&q=80', 'Kafe / Lokanta Örnek Cover 5', 5),
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1200&q=80', 'Kafe / Lokanta Örnek Cover 6', 6),
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=1200&q=80', 'Kafe / Lokanta Örnek Cover 7', 7),
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=1200&q=80', 'Kafe / Lokanta Örnek Cover 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kafe / Lokanta Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=800&q=80', 'Kafe / Lokanta Örnek Gallery 4', 4),
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1620921556828-d7dc29ef0488?w=800&q=80', 'Kafe / Lokanta Örnek Gallery 5', 5),
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80', 'Kafe / Lokanta Örnek Gallery 6', 6),
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80', 'Kafe / Lokanta Örnek Gallery 7', 7),
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80', 'Kafe / Lokanta Örnek Gallery 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kafe / Lokanta Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=600&q=80', 'Kafe / Lokanta Örnek Product 4', 4),
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=600&q=80', 'Kafe / Lokanta Örnek Product 5', 5),
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=600&q=80', 'Kafe / Lokanta Örnek Product 6', 6),
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?w=600&q=80', 'Kafe / Lokanta Örnek Product 7', 7),
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&q=80', 'Kafe / Lokanta Örnek Product 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kuaför Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1521590832167-7bcbfea6331f?w=1200&q=80', 'Kuaför Örnek Cover 4', 4),
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1634449571010-02389ed0f9b0?w=1200&q=80', 'Kuaför Örnek Cover 5', 5),
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1612817288484-6f916006741a?w=1200&q=80', 'Kuaför Örnek Cover 6', 6),
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1522335939835-0347101999b4?w=1200&q=80', 'Kuaför Örnek Cover 7', 7),
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?w=1200&q=80', 'Kuaför Örnek Cover 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kuaför Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1515688594390-b649af70d282?w=800&q=80', 'Kuaför Örnek Gallery 4', 4),
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80', 'Kuaför Örnek Gallery 5', 5),
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=800&q=80', 'Kuaför Örnek Gallery 6', 6),
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1527799863830-580c3b0dc7f2?w=800&q=80', 'Kuaför Örnek Gallery 7', 7),
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?w=800&q=80', 'Kuaför Örnek Gallery 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Kuaför Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1633681926035-ec1ac984418a?w=600&q=80', 'Kuaför Örnek Product 4', 4),
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=600&q=80', 'Kuaför Örnek Product 5', 5),
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=600&q=80', 'Kuaför Örnek Product 6', 6),
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&q=80', 'Kuaför Örnek Product 7', 7),
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1507081329363-9524582389e3?w=600&q=80', 'Kuaför Örnek Product 8', 8)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Teknik Servis Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('teknik_servis', 'Teknik Servis', 'cover', 'https://images.unsplash.com/photo-1588508065123-287b28e013da?w=1200&q=80', 'Teknik Servis Örnek Cover 4', 4),
('teknik_servis', 'Teknik Servis', 'cover', 'https://images.unsplash.com/photo-1597733336794-12d05021d510?w=1200&q=80', 'Teknik Servis Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Teknik Servis Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('teknik_servis', 'Teknik Servis', 'gallery', 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80', 'Teknik Servis Örnek Gallery 4', 4),
('teknik_servis', 'Teknik Servis', 'gallery', 'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=800&q=80', 'Teknik Servis Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Teknik Servis Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('teknik_servis', 'Teknik Servis', 'product', 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&q=80', 'Teknik Servis Örnek Product 4', 4),
('teknik_servis', 'Teknik Servis', 'product', 'https://images.unsplash.com/photo-1563770660941-20978e870e26?w=600&q=80', 'Teknik Servis Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Hizmet & Danışmanlık Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'cover', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=1200&q=80', 'Hizmet & Danışmanlık Örnek Cover 4', 4),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'cover', 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=1200&q=80', 'Hizmet & Danışmanlık Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Hizmet & Danışmanlık Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'gallery', 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&q=80', 'Hizmet & Danışmanlık Örnek Gallery 4', 4),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'gallery', 'https://images.unsplash.com/photo-1516321307626-f440ee48af35?w=800&q=80', 'Hizmet & Danışmanlık Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Hizmet & Danışmanlık Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'product', 'https://images.unsplash.com/photo-1552581234-2612b75dc89c?w=600&q=80', 'Hizmet & Danışmanlık Örnek Product 4', 4),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'product', 'https://images.unsplash.com/photo-1521791136364-7221f70f6f59?w=600&q=80', 'Hizmet & Danışmanlık Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Eğitim & Ders Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('egitim_ders', 'Eğitim & Ders', 'cover', 'https://images.unsplash.com/photo-1553871373-d15224ef1f6d?w=1200&q=80', 'Eğitim & Ders Örnek Cover 4', 4),
('egitim_ders', 'Eğitim & Ders', 'cover', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80', 'Eğitim & Ders Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Eğitim & Ders Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('egitim_ders', 'Eğitim & Ders', 'gallery', 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80', 'Eğitim & Ders Örnek Gallery 4', 4),
('egitim_ders', 'Eğitim & Ders', 'gallery', 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=800&q=80', 'Eğitim & Ders Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Eğitim & Ders Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('egitim_ders', 'Eğitim & Ders', 'product', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600&q=80', 'Eğitim & Ders Örnek Product 4', 4),
('egitim_ders', 'Eğitim & Ders', 'product', 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=600&q=80', 'Eğitim & Ders Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Ev & Temizlik Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('ev_temizlik', 'Ev & Temizlik', 'cover', 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=1200&q=80', 'Ev & Temizlik Örnek Cover 4', 4),
('ev_temizlik', 'Ev & Temizlik', 'cover', 'https://images.unsplash.com/photo-1528740561666-bd247e66ad50?w=1200&q=80', 'Ev & Temizlik Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Ev & Temizlik Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('ev_temizlik', 'Ev & Temizlik', 'gallery', 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=800&q=80', 'Ev & Temizlik Örnek Gallery 4', 4),
('ev_temizlik', 'Ev & Temizlik', 'gallery', 'https://images.unsplash.com/photo-1609770231080-e321deccc344?w=800&q=80', 'Ev & Temizlik Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Ev & Temizlik Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('ev_temizlik', 'Ev & Temizlik', 'product', 'https://images.unsplash.com/photo-1585421514738-ee1a3b2e5ef0?w=600&q=80', 'Ev & Temizlik Örnek Product 4', 4),
('ev_temizlik', 'Ev & Temizlik', 'product', 'https://images.unsplash.com/photo-1527515545081-5db817172677?w=600&q=80', 'Ev & Temizlik Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Spor & Fitness Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('spor_fitness', 'Spor & Fitness', 'cover', 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1200&q=80', 'Spor & Fitness Örnek Cover 4', 4),
('spor_fitness', 'Spor & Fitness', 'cover', 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=1200&q=80', 'Spor & Fitness Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Spor & Fitness Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('spor_fitness', 'Spor & Fitness', 'gallery', 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=800&q=80', 'Spor & Fitness Örnek Gallery 4', 4),
('spor_fitness', 'Spor & Fitness', 'gallery', 'https://images.unsplash.com/photo-1594882645126-14020914d58d?w=800&q=80', 'Spor & Fitness Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Spor & Fitness Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('spor_fitness', 'Spor & Fitness', 'product', 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&q=80', 'Spor & Fitness Örnek Product 4', 4),
('spor_fitness', 'Spor & Fitness', 'product', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=600&q=80', 'Spor & Fitness Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Pet Shop & Veteriner Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'cover', 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=1200&q=80', 'Pet Shop & Veteriner Örnek Cover 4', 4),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'cover', 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=1200&q=80', 'Pet Shop & Veteriner Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Pet Shop & Veteriner Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'gallery', 'https://images.unsplash.com/photo-1596492784531-6e6eb5ea9993?w=800&q=80', 'Pet Shop & Veteriner Örnek Gallery 4', 4),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'gallery', 'https://images.unsplash.com/photo-1415369629372-26f2fe60c467?w=800&q=80', 'Pet Shop & Veteriner Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Pet Shop & Veteriner Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'product', 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600&q=80', 'Pet Shop & Veteriner Örnek Product 4', 4),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'product', 'https://images.unsplash.com/photo-1537151608828-ea2b117b62e4?w=600&q=80', 'Pet Shop & Veteriner Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Sağlık & Yaşam Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('saglik_yasam', 'Sağlık & Yaşam', 'cover', 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=1200&q=80', 'Sağlık & Yaşam Örnek Cover 4', 4),
('saglik_yasam', 'Sağlık & Yaşam', 'cover', 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?w=1200&q=80', 'Sağlık & Yaşam Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Sağlık & Yaşam Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('saglik_yasam', 'Sağlık & Yaşam', 'gallery', 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=800&q=80', 'Sağlık & Yaşam Örnek Gallery 4', 4),
('saglik_yasam', 'Sağlık & Yaşam', 'gallery', 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=800&q=80', 'Sağlık & Yaşam Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Sağlık & Yaşam Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('saglik_yasam', 'Sağlık & Yaşam', 'product', 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=600&q=80', 'Sağlık & Yaşam Örnek Product 4', 4),
('saglik_yasam', 'Sağlık & Yaşam', 'product', 'https://images.unsplash.com/photo-1581594693702-fbdc51b2763b?w=600&q=80', 'Sağlık & Yaşam Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Oto & Araç Hizmetleri Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('oto_arac', 'Oto & Araç Hizmetleri', 'cover', 'https://images.unsplash.com/photo-1617886322168-72b886573c3c?w=1200&q=80', 'Oto & Araç Hizmetleri Örnek Cover 4', 4),
('oto_arac', 'Oto & Araç Hizmetleri', 'cover', 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?w=1200&q=80', 'Oto & Araç Hizmetleri Örnek Cover 5', 5),
('oto_arac', 'Oto & Araç Hizmetleri', 'cover', 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=1200&q=80', 'Oto & Araç Hizmetleri Örnek Cover 6', 6)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Oto & Araç Hizmetleri Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('oto_arac', 'Oto & Araç Hizmetleri', 'gallery', 'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?w=800&q=80', 'Oto & Araç Hizmetleri Örnek Gallery 4', 4),
('oto_arac', 'Oto & Araç Hizmetleri', 'gallery', 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800&q=80', 'Oto & Araç Hizmetleri Örnek Gallery 5', 5),
('oto_arac', 'Oto & Araç Hizmetleri', 'gallery', 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=800&q=80', 'Oto & Araç Hizmetleri Örnek Gallery 6', 6)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Oto & Araç Hizmetleri Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('oto_arac', 'Oto & Araç Hizmetleri', 'product', 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=600&q=80', 'Oto & Araç Hizmetleri Örnek Product 4', 4),
('oto_arac', 'Oto & Araç Hizmetleri', 'product', 'https://images.unsplash.com/photo-1562620658-c30089e02315?w=600&q=80', 'Oto & Araç Hizmetleri Örnek Product 5', 5),
('oto_arac', 'Oto & Araç Hizmetleri', 'product', 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600&q=80', 'Oto & Araç Hizmetleri Örnek Product 6', 6)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Diğer Sektoru COVER Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('diger', 'Diğer', 'cover', 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=1200&q=80', 'Diğer Örnek Cover 4', 4),
('diger', 'Diğer', 'cover', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=80', 'Diğer Örnek Cover 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Diğer Sektoru GALLERY Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('diger', 'Diğer', 'gallery', 'https://images.unsplash.com/photo-1472851294608-062f824d296e?w=800&q=80', 'Diğer Örnek Gallery 4', 4),
('diger', 'Diğer', 'gallery', 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80', 'Diğer Örnek Gallery 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;

-- Diğer Sektoru PRODUCT Eklemleri
INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('diger', 'Diğer', 'product', 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=600&q=80', 'Diğer Örnek Product 4', 4),
('diger', 'Diğer', 'product', 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&q=80', 'Diğer Örnek Product 5', 5)
ON CONFLICT (category_key, image_type, image_url) DO NOTHING;
