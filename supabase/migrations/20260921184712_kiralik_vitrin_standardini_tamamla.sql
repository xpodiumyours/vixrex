-- Kiralık vitrinlerde doğrulanmış kalite farklarını tek seferde kapatır.
-- İçerik bakımı yayın/demo bayrağından bağımsızdır: temiz yerel DB'de yasal belge
-- seed'i yoksa landing demoları taslak ve is_demo=false kalabilir. Güvenlik kimliği
-- sabit slug + seed adı + user_id IS NULL eşleşmesidir; yayın/sahiplik değiştirilmez.
-- Kapsam: yalnız kiralik-teknik + demo-lezzet-duragi + demo-nova-kuafor
-- + demo-aymira-giyim. Asistan, owner paneli ve kiralama motoru değişmez.
BEGIN;

DO $$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.stores s
  JOIN (VALUES
    ('kiralik-teknik','Hızlı Teknik'),
    ('demo-lezzet-duragi','Lezzet Durağı'),
    ('demo-nova-kuafor','Nova Kuaför'),
    ('demo-aymira-giyim','Aymira Giyim')
  ) AS expected(slug,name)
    ON expected.slug = s.slug
   AND expected.name = s.name
  WHERE s.user_id IS NULL;
  IF v_count <> 4 THEN
    RAISE EXCEPTION 'KIRALIK_STANDARD_PREFLIGHT_FAILED: expected 4 stores, found %', v_count;
  END IF;
END;
$$;

ALTER TABLE public.stores DISABLE TRIGGER protect_landing_demo_stores;

-- Hızlı Teknik: Hakkımızda + SSS + blog başlıkları.
UPDATE public.stores SET
  about_kicker = 'Hakkımızda',
  about_title = 'Bağcılar''da hızlı, açık ve garantili teknik servis',
  about_image_url = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=1200&q=85',
  about_image_caption = 'Atölyemizde cihaz kontrol ve onarım süreci',
  about_values = '[
    {"id":"1","title":"Açık Fiyatlandırma","description":"İşlem başlamadan önce arıza ve ücret bilgisi paylaşılır."},
    {"id":"2","title":"Parça Garantisi","description":"Değişen parça ve yapılan işlem için garanti bilgisi teslimde verilir."},
    {"id":"3","title":"Hızlı Teslim","description":"Stokta parçası bulunan yaygın işlemler mümkün olduğunda aynı gün tamamlanır."}
  ]'::jsonb,
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Servis Hakkında Merak Edilenler',
  faq_section_description = 'Onarım, fiyat, garanti ve teslim süreci hakkında sık sorulan sorular.',
  faq_items = '[
    {"id":"1","question":"Arıza tespiti ne kadar sürer?","answer":"Cihaz türüne göre değişir; yaygın kontroller çoğunlukla aynı gün sonuçlandırılır."},
    {"id":"2","question":"Onarım başlamadan fiyat öğrenebilir miyim?","answer":"Evet. İşlem ve tahmini ücret onayınızdan önce paylaşılır."},
    {"id":"3","question":"Değişen parçaya garanti veriliyor mu?","answer":"Garanti süresi parçaya ve işleme göre değişir; teslimde belirtilir."},
    {"id":"4","question":"Hangi cihazlara bakıyorsunuz?","answer":"Telefon, tablet ve bilgisayarlarda ekran, batarya, bakım ve temel donanım işlemleri yapılır."}
  ]'::jsonb,
  blog_section_kicker = 'Teknik Rehber',
  blog_section_title = 'Cihaz Bakımı ve Onarım Bilgileri'
WHERE slug = 'kiralik-teknik' AND user_id IS NULL;

-- Lezzet Durağı: çalışma saati + Hakkımızda + SSS + bölüm başlıkları.
UPDATE public.stores SET
  working_hours = '{"monday":"09:00-22:00","tuesday":"09:00-22:00","wednesday":"09:00-22:00","thursday":"09:00-22:00","friday":"09:00-23:00","saturday":"09:00-23:00","sunday":"10:00-22:00"}',
  category_section_title = 'Menü Kategorileri',
  product_section_title = 'Menümüz',
  about_kicker = 'Hakkımızda',
  about_title = 'Günlük hazırlanan sıcak yemekler ve samimi mahalle mutfağı',
  corporate_bio = 'Lezzet Durağı, günlük hazırlanan sıcak yemekleri, ev yapımı tarifleri ve pratik paket servis seçeneklerini sunan mahalle lokantasıdır.

Menü günlük üretime göre yenilenir. Amaç müşterinin menüyü, fiyatı, konumu ve sipariş kanalını tek ekrandan görebilmesidir.',
  about_image_url = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=85',
  about_image_caption = 'Günlük servis öncesi hazırlanan salon',
  about_values = '[
    {"id":"1","title":"Günlük Hazırlık","description":"Ana ürünler günlük hazırlanır."},
    {"id":"2","title":"Açık Menü","description":"Ürün ve fiyat bilgisi karar vermeyi kolaylaştıracak biçimde sunulur."},
    {"id":"3","title":"Paket Servis","description":"Uygun ürünlerde WhatsApp üzerinden sipariş bilgisi alınabilir."}
  ]'::jsonb,
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Menü ve Sipariş Hakkında',
  faq_section_description = 'Menü, paket servis ve çalışma düzeni hakkında sık sorulan sorular.',
  faq_items = '[
    {"id":"1","question":"Günün menüsü her gün değişiyor mu?","answer":"Evet. Günün seçenekleri günlük hazırlığa göre değişebilir."},
    {"id":"2","question":"Paket servis var mı?","answer":"Uygun ürünlerde paket servis bilgisi WhatsApp üzerinden teyit edilebilir."},
    {"id":"3","question":"Alerjen bilgisi öğrenebilir miyim?","answer":"Sipariş öncesinde ürün içeriği için işletmeyle iletişime geçebilirsiniz."},
    {"id":"4","question":"Kalabalık gruplar için önceden bilgi gerekir mi?","answer":"Yoğun saatlerde önceden bilgi vermeniz önerilir."}
  ]'::jsonb,
  blog_section_kicker = 'Mutfak Rehberi',
  blog_section_title = 'Menü ve Lezzet Notları'
WHERE slug = 'demo-lezzet-duragi' AND user_id IS NULL;

-- Nova Kuaför: çalışma saati + Hakkımızda + SSS + 5 görsellik galeri.
UPDATE public.stores SET
  working_hours = '{"monday":"09:00-20:00","tuesday":"09:00-20:00","wednesday":"09:00-20:00","thursday":"09:00-20:00","friday":"09:00-20:00","saturday":"09:00-19:00","sunday":""}',
  category_section_title = 'Hizmet Kategorileri',
  product_section_title = 'Hizmet Fiyat Listesi',
  gallery_section_kicker = 'Stüdyodan',
  gallery_section_title = 'Çalışmalarımız',
  about_kicker = 'Hakkımızda',
  about_title = 'Saç tasarımı ve bakımda randevulu, kişisel hizmet',
  corporate_bio = 'Nova Kuaför; saç kesimi, renklendirme, bakım ve özel gün hazırlıklarını randevulu düzende sunar.

Hizmet öncesinde beklenti, saç yapısı ve işlem süresi konuşulur; müşterinin hizmetleri ve randevu yolunu vitrinden net görmesi amaçlanır.',
  about_image_url = 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=1200&q=85',
  about_image_caption = 'Nova Kuaför bakım ve uygulama alanı',
  about_values = '[
    {"id":"1","title":"Kişisel Planlama","description":"Kesim ve bakım saç yapısına göre planlanır."},
    {"id":"2","title":"Randevulu Hizmet","description":"İşlem süresini korumak için randevulu çalışma düzeni uygulanır."},
    {"id":"3","title":"Bakım Odaklı","description":"Renklendirmede saçın mevcut durumu dikkate alınır."}
  ]'::jsonb,
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Randevu ve Hizmet Hakkında',
  faq_section_description = 'Randevu, işlem süresi ve bakım hakkında sık sorulan sorular.',
  faq_items = '[
    {"id":"1","question":"Randevu almam gerekiyor mu?","answer":"Yoğun saatlerde beklememek için WhatsApp üzerinden randevu önerilir."},
    {"id":"2","question":"Saç boyama ne kadar sürer?","answer":"Saç uzunluğu ve işleme göre süre değişir."},
    {"id":"3","question":"İşlem öncesi fiyat bilgisi alabilir miyim?","answer":"Evet. Yaklaşık fiyat aralığı işlem öncesinde paylaşılır."},
    {"id":"4","question":"Özel gün saç ve makyaj hizmeti var mı?","answer":"Evet. Müsaitlik için önceden randevu önerilir."}
  ]'::jsonb,
  blog_section_kicker = 'Saç Rehberi',
  blog_section_title = 'Bakım ve Stil Bilgileri',
  gallery_items = '[
    {"id":"cover","imageUrl":"https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=800&q=80","title":"Stüdyo genel görünümü"},
    {"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=800&q=80","title":"Saç kesimi ve şekillendirme"},
    {"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?auto=format&fit=crop&w=800&q=80","title":"Renklendirme uygulaması"},
    {"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=800&q=80","title":"Özel gün makyajı"},
    {"id":"gallery-3","imageUrl":"https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=800&q=80","title":"Bakım sonrası görünüm"}
  ]'::jsonb
WHERE slug = 'demo-nova-kuafor' AND user_id IS NULL;

-- Aymira Giyim: çalışma saati + Hakkımızda + SSS + bölüm başlıkları.
UPDATE public.stores SET
  working_hours = '{"monday":"10:00-20:00","tuesday":"10:00-20:00","wednesday":"10:00-20:00","thursday":"10:00-20:00","friday":"10:00-21:00","saturday":"10:00-21:00","sunday":"11:00-19:00"}',
  category_section_title = 'Ürün Kategorileri',
  product_section_title = 'Yeni Sezon Ürünleri',
  about_kicker = 'Hakkımızda',
  about_title = 'Günlük kullanıma uygun yeni sezon kadın giyim seçkisi',
  corporate_bio = 'Aymira Giyim, günlük kombinlerden özel gün parçalarına kadar farklı kullanım alanlarına yönelik kadın giyim ürünlerini bir araya getirir.

Vitrin müşterinin ürün tipini, fiyatı, görselleri ve mağazaya ulaşma yollarını tek ekrandan görebilmesi için düzenlenmiştir.',
  about_image_url = 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=1200&q=85',
  about_image_caption = 'Yeni sezon reyonlarından görünüm',
  about_values = '[
    {"id":"1","title":"Sezon Seçkisi","description":"Günlük giyim ve tamamlayıcı parçalardan oluşan seçki."},
    {"id":"2","title":"Beden Bilgisi","description":"Uygun olduğunda beden ve temel ürün bilgileri kartlarda gösterilir."},
    {"id":"3","title":"Mağaza + İletişim","description":"Stok soruları için WhatsApp, mağaza ziyareti için konum bilgisi sunulur."}
  ]'::jsonb,
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Ürün ve Alışveriş Hakkında',
  faq_section_description = 'Beden, stok ve mağaza alışverişi hakkında sık sorulan sorular.',
  faq_items = '[
    {"id":"1","question":"Beden seçeneklerini nereden öğrenebilirim?","answer":"Ürün kartı yeterli değilse WhatsApp üzerinden beden ve stok teyidi alabilirsiniz."},
    {"id":"2","question":"Mağazada deneyebilir miyim?","answer":"Evet. Stokta bulunan ürünler mağazada incelenebilir."},
    {"id":"3","question":"Stoklar güncel mi?","answer":"Bu vitrin örnek içeriktir; gerçek kiracı kendi ürün ve stoklarını yönetir."},
    {"id":"4","question":"Değişim koşulları nedir?","answer":"Gerçek işletme vitrini yayına alındığında kendi değişim politikasını belirtmelidir."}
  ]'::jsonb,
  blog_section_kicker = 'Stil Rehberi',
  blog_section_title = 'Kombin ve Ürün Rehberi'
WHERE slug = 'demo-aymira-giyim' AND user_id IS NULL;

ALTER TABLE public.stores ENABLE TRIGGER protect_landing_demo_stores;

-- Üç boş demo için 3'er gerçek kategori.
WITH kategori_listesi (store_slug, isim, slug, sira) AS (
  VALUES
    ('demo-lezzet-duragi','Ana Yemekler','ana-yemekler',0),
    ('demo-lezzet-duragi','Kahve & İçecek','kahve-icecek',1),
    ('demo-lezzet-duragi','Tatlılar','tatlilar',2),
    ('demo-nova-kuafor','Saç Kesimi & Bakım','sac-kesimi-bakim',0),
    ('demo-nova-kuafor','Renklendirme','renklendirme',1),
    ('demo-nova-kuafor','Makyaj & Özel Gün','makyaj-ozel-gun',2),
    ('demo-aymira-giyim','Elbise & Alt Giyim','elbise-alt-giyim',0),
    ('demo-aymira-giyim','Üst Giyim','ust-giyim',1),
    ('demo-aymira-giyim','Aksesuar','aksesuar',2)
)
INSERT INTO public.product_categories (store_id, name, slug, is_active, sort_order)
SELECT s.id, k.isim, k.slug, true, k.sira
FROM kategori_listesi k
JOIN public.stores s ON s.slug = k.store_slug
WHERE NOT EXISTS (
  SELECT 1 FROM public.product_categories pc
  WHERE pc.store_id = s.id AND lower(pc.name) = lower(k.isim)
);

-- Her boş demo için 6 ürün/hizmet.
WITH urun_listesi (store_slug,kategori_adi,ad,slug,aciklama,fiyat_metin,fiyat_sayi,gorsel,teslim,sira) AS (
  VALUES
    ('demo-lezzet-duragi','Ana Yemekler','Ev Yapımı Mantı','ev-yapimi-manti','Yoğurt ve tereyağlı sosla servis edilir.','195 TL',195::numeric,'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80','Siparişe hazırlanır',0),
    ('demo-lezzet-duragi','Ana Yemekler','Günün Ev Yemeği Menüsü','gunun-ev-yemegi-menusu','Ana yemek, yardımcı yemek ve içecek menüsü.','240 TL',240::numeric,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600&q=80','Günlük menü',1),
    ('demo-lezzet-duragi','Kahve & İçecek','Filtre Kahve','filtre-kahve','Taze çekilmiş kahve ile hazırlanır.','85 TL',85::numeric,'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80','5-10 dk',0),
    ('demo-lezzet-duragi','Kahve & İçecek','Ev Yapımı Limonata','ev-yapimi-limonata','Taze limonla günlük hazırlanır.','75 TL',75::numeric,'https://images.unsplash.com/photo-1523677011781-c91d1bbe2f9d?w=600&q=80','Stoktan',1),
    ('demo-lezzet-duragi','Tatlılar','Fırın Sütlaç','firin-sutlac','Günlük hazırlanan klasik fırın sütlaç.','110 TL',110::numeric,'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600&q=80','Stoktan',0),
    ('demo-lezzet-duragi','Tatlılar','San Sebastian Cheesecake','san-sebastian-cheesecake','Yoğun kıvamlı cheesecake, dilim servis.','145 TL',145::numeric,'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=600&q=80','Stoktan',1),

    ('demo-nova-kuafor','Saç Kesimi & Bakım','Saç Kesimi & Fön','sac-kesimi-fon','Yıkama, kesim ve fön dahil.','650 TL',650::numeric,'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600&q=80','Yaklaşık 60 dk',0),
    ('demo-nova-kuafor','Saç Kesimi & Bakım','Keratin Bakımı','keratin-bakimi','Saç yapısına göre yoğun bakım.','1.600 TL',1600::numeric,'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80','90-120 dk',1),
    ('demo-nova-kuafor','Renklendirme','Tek Renk Saç Boyama','tek-renk-sac-boyama','Saç uzunluğuna göre tek renk uygulama.','1.250 TL''den',1250::numeric,'https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?w=600&q=80','90-120 dk',0),
    ('demo-nova-kuafor','Renklendirme','Balyaj & Ombre','balyaj-ombre','Kişiselleştirilmiş renklendirme.','2.400 TL''den',2400::numeric,'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=600&q=80','2-4 saat',1),
    ('demo-nova-kuafor','Makyaj & Özel Gün','Özel Gün Saç Tasarımı','ozel-gun-sac-tasarimi','Davet ve özel gün saç tasarımı.','1.100 TL''den',1100::numeric,'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=600&q=80','Randevulu',0),
    ('demo-nova-kuafor','Makyaj & Özel Gün','Profesyonel Makyaj','profesyonel-makyaj','Etkinlik türüne uygun profesyonel makyaj.','1.350 TL',1350::numeric,'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80','Randevulu',1),

    ('demo-aymira-giyim','Elbise & Alt Giyim','Keten Midi Elbise','keten-midi-elbise','Rahat kesim keten karışımlı midi elbise.','1.290 TL',1290::numeric,'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&q=80','Mağaza stoğu',0),
    ('demo-aymira-giyim','Elbise & Alt Giyim','Yüksek Bel Kumaş Pantolon','yuksek-bel-kumas-pantolon','Ofis ve günlük kombinlere uygun pantolon.','990 TL',990::numeric,'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=600&q=80','Mağaza stoğu',1),
    ('demo-aymira-giyim','Üst Giyim','Oversize Keten Gömlek','oversize-keten-gomlek','Rahat kesimli keten karışımlı gömlek.','790 TL',790::numeric,'https://images.unsplash.com/photo-1605763240000-7e93b172d754?w=600&q=80','Mağaza stoğu',0),
    ('demo-aymira-giyim','Üst Giyim','İnce Triko Hırka','ince-triko-hirka','Mevsim geçişlerine uygun ince triko.','690 TL',690::numeric,'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=600&q=80','Mağaza stoğu',1),
    ('demo-aymira-giyim','Aksesuar','Omuz Çantası','omuz-cantasi','Günlük kullanım için orta boy omuz çantası.','850 TL',850::numeric,'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&q=80','Mağaza stoğu',0),
    ('demo-aymira-giyim','Aksesuar','Desenli Fular','desenli-fular','Kombinleri tamamlayan desenli fular.','390 TL',390::numeric,'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=600&q=80','Mağaza stoğu',1)
)
INSERT INTO public.products (
  store_id,name,slug,description,price_text,price_amount,image_urls,category_id,
  source_type,is_visible,is_active,sort_order,fulfillment_region,stock_status
)
SELECT
  s.id,u.ad,u.slug,u.aciklama,u.fiyat_metin,u.fiyat_sayi,jsonb_build_array(u.gorsel),
  pc.id,'manual',true,true,u.sira,u.teslim,'Mevcut'
FROM urun_listesi u
JOIN public.stores s ON s.slug = u.store_slug
JOIN public.product_categories pc ON pc.store_id = s.id AND lower(pc.name) = lower(u.kategori_adi)
WHERE NOT EXISTS (
  SELECT 1 FROM public.products p
  WHERE p.store_id = s.id AND lower(p.name) = lower(u.ad)
);

-- Dört hedefe üçer blog.
INSERT INTO public.store_articles (store_slug,title,slug,summary,content,cover_image_url,status,published_at)
SELECT * FROM (VALUES
  ('kiralik-teknik','Telefon Bataryasının Değişim İşaretleri','telefon-bataryasi-degisim-isaretleri','Batarya ne zaman kontrol edilmeli?','Hızlı tükenme, ani kapanma veya şişme batarya kontrolü gerektirebilir. Şişme varsa cihaz kullanılmadan profesyonel destek alınmalıdır.','https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('kiralik-teknik','Laptop Fan ve Termal Bakım Rehberi','laptop-fan-termal-bakim','Isınma ve bakımın temel noktaları.','Toz birikimi hava akışını azaltabilir. Fan, hava kanalları ve termal malzeme kontrolü aşırı ısınmanın yaygın nedenlerini azaltmaya yardımcı olur.','https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('kiralik-teknik','Ekran Değişimi Öncesi Sorulacak 4 Soru','ekran-degisimi-oncesi-sorular','Parça, fiyat, garanti ve teslim süresi.','Ekran değişiminden önce parça türü, toplam ücret, garanti süresi ve teslim zamanı netleştirilmelidir.','https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=1200&q=80','published',now()),

  ('demo-lezzet-duragi','Günün Menüsü Nasıl Planlanır?','gunun-menusu-nasil-planlanir','Dengeli günlük menünün temel noktaları.','Ana yemek, yardımcı ürün ve içecek dengesini açık fiyatla sunmak müşterinin hızlı karar vermesini kolaylaştırır.','https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('demo-lezzet-duragi','Paket Serviste Kaliteyi Korumak','paket-serviste-kalite','Ambalaj ve teslim süresi neden önemli?','Ürüne uygun ambalaj, sıcak-soğuk ayrımı ve gerçekçi teslim süresi paket serviste kaliteyi korumaya yardımcı olur.','https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('demo-lezzet-duragi','Kahvede Kavrum ve Demleme Farkı','kahve-kavrum-demleme-farki','Kahvenin tadını neler değiştirir?','Çekirdeğin yanında kavrum, öğütme, su sıcaklığı ve demleme süresi de fincan sonucunu etkiler.','https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80','published',now()),

  ('demo-nova-kuafor','Saç Kesimi Öncesi Ne Anlatmalısınız?','sac-kesimi-oncesi-ne-anlatmali','Beklentiyi doğru aktarmanın kısa rehberi.','İstenen model kadar günlük şekillendirme alışkanlığı, korunacak uzunluk ve bakım süresi de işlem öncesinde konuşulmalıdır.','https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('demo-nova-kuafor','Renklendirme Sonrası İlk 48 Saat','renklendirme-sonrasi-ilk-48-saat','Rengi korumaya yardımcı temel adımlar.','İlk bakım zamanı kullanılan işleme göre değişebilir. Aşırı sıcak su ve yoğun ısıdan kaçınmak rengin korunmasına yardımcı olabilir.','https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('demo-nova-kuafor','Özel Gün Randevusu Ne Zaman Alınmalı?','ozel-gun-randevusu-ne-zaman','Prova ve randevu planlaması.','Özel günlerde uygun saat bulmak için erken iletişim kurulması ve karmaşık modellerde prova planlanması yararlı olabilir.','https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=1200&q=80','published',now()),

  ('demo-aymira-giyim','Kapsül Gardırop İçin Temel Parçalar','kapsul-gardirop-temel-parcalar','Az parçayla daha fazla kombin.','Birbiriyle uyumlu pantolon, gömlek, hırka ve sade elbise gibi temel parçalar kapsül gardırop kurmayı kolaylaştırır.','https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('demo-aymira-giyim','Online Beden Seçiminde Ölçü','online-beden-seciminde-olcu','Beden tablosunu doğru kullanma rehberi.','Göğüs, bel ve kalça ölçüsünü doğru alıp ürün tablosuyla karşılaştırmak yalnız beden numarasına güvenmekten daha sağlıklıdır.','https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=1200&q=80','published',now()),
  ('demo-aymira-giyim','Kumaş Seçimi Günlük Kullanımı Nasıl Etkiler?','kumas-secimi-gunluk-kullanim','Kumaş ve bakım farkları.','Keten, pamuk ve triko gibi kumaşlar kullanım hissini ve bakım şeklini değiştirir; ürün etiketindeki bakım talimatı dikkate alınmalıdır.','https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1200&q=80','published',now())
) AS v(store_slug,title,slug,summary,content,cover_image_url,status,published_at)
WHERE NOT EXISTS (
  SELECT 1 FROM public.store_articles sa
  WHERE sa.store_slug = v.store_slug AND sa.slug = v.slug
);

-- POSTCHECK: standardın tamamı oluşmadan migration başarılı sayılmaz.
DO $$
DECLARE
  r record;
  v_products integer;
  v_categories integer;
  v_articles integer;
  v_faq integer;
  v_gallery integer;
  v_about text;
  v_hours text;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('kiralik-teknik',6,3,0),
      ('demo-lezzet-duragi',6,3,0),
      ('demo-nova-kuafor',6,3,5),
      ('demo-aymira-giyim',6,3,0)
    ) AS x(slug,min_products,min_categories,min_gallery)
  LOOP
    SELECT count(*) INTO v_products FROM public.products p
      JOIN public.stores s ON s.id=p.store_id
      WHERE s.slug=r.slug AND p.is_active=true;
    SELECT count(*) INTO v_categories FROM public.product_categories pc
      JOIN public.stores s ON s.id=pc.store_id
      WHERE s.slug=r.slug AND pc.is_active=true;
    SELECT count(*) INTO v_articles FROM public.store_articles
      WHERE store_slug=r.slug AND status='published';
    SELECT
      COALESCE(jsonb_array_length(COALESCE(faq_items,'[]'::jsonb)),0),
      COALESCE(jsonb_array_length(COALESCE(gallery_items,'[]'::jsonb)),0),
      COALESCE(about_title,''),
      COALESCE(working_hours::text,'')
    INTO v_faq,v_gallery,v_about,v_hours
    FROM public.stores WHERE slug=r.slug;

    IF v_products < r.min_products THEN RAISE EXCEPTION '% products % < %',r.slug,v_products,r.min_products; END IF;
    IF v_categories < r.min_categories THEN RAISE EXCEPTION '% categories % < %',r.slug,v_categories,r.min_categories; END IF;
    IF v_articles < 3 THEN RAISE EXCEPTION '% articles % < 3',r.slug,v_articles; END IF;
    IF v_faq < 4 THEN RAISE EXCEPTION '% faq % < 4',r.slug,v_faq; END IF;
    IF btrim(v_about)='' THEN RAISE EXCEPTION '% about missing',r.slug; END IF;
    IF r.slug<>'kiralik-teknik' AND (btrim(v_hours)='' OR v_hours='null') THEN
      RAISE EXCEPTION '% working hours missing',r.slug;
    END IF;
    IF r.min_gallery>0 AND v_gallery<r.min_gallery THEN
      RAISE EXCEPTION '% gallery % < %',r.slug,v_gallery,r.min_gallery;
    END IF;
  END LOOP;
END;
$$;

NOTIFY pgrst, 'reload schema';
COMMIT;
