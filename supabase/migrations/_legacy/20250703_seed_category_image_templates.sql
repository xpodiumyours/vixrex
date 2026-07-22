-- ============================================================
-- Sprint 1: Kategori Sablon Seed Verileri (19 Kategori Hizalamasi)
-- Unsplash telifsiz gorseller
-- ============================================================

TRUNCATE TABLE category_image_templates;

-- 1. GIYIM
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80', 'Giyim Mağazası', 1),
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=1200&q=80', 'Giyim Rafı', 2),
('giyim', 'Giyim', 'cover', 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=1200&q=80', 'Mağaza İçi', 3),
('giyim', 'Giyim', 'logo_placeholder', 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=512&q=80', 'Giyim Logo', 1),
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=800&q=80', 'Yeni Sezon Günlük Giyim', 1),
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800&q=80', 'Basic & Rahat Kombinler', 2),
('giyim', 'Giyim', 'gallery', 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=800&q=80', 'Dış Giyim & Kabanlar', 3),
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80', 'Basic Tişört', 1),
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&q=80', 'Mavi Kot Pantolon', 2),
('giyim', 'Giyim', 'product', 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&q=80', 'Yazlık Elbise', 3);

-- 2. BUTIK
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=1200&q=80', 'Butik Vitrini', 1),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80', 'Giyim Rafı', 2),
('butik', 'Butik', 'cover', 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&q=80', 'Mağaza İçi', 3),
('butik', 'Butik', 'logo_placeholder', 'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=512&q=80', 'Butik Logo', 1),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80', 'Özel Tasarım Elbiseler', 1),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80', 'Butik Takı & Aksesuar', 2),
('butik', 'Butik', 'gallery', 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80', 'Sınırlı Özel Koleksiyon', 3),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=600&q=80', 'Tasarım Saat', 1),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1509319117193-57bab727e09d?w=600&q=80', 'Butik Elbise', 2),
('butik', 'Butik', 'product', 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&q=80', 'El Yapımı Çanta', 3);

-- 3. GIDA
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('gida', 'Gıda', 'cover', 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200&q=80', 'Taze Gıda Reyonu', 1),
('gida', 'Gıda', 'cover', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&q=80', 'Manav Reyonu', 2),
('gida', 'Gıda', 'cover', 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1200&q=80', 'Market İçi', 3),
('gida', 'Gıda', 'logo_placeholder', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=512&q=80', 'Gıda Logo', 1),
('gida', 'Gıda', 'gallery', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800&q=80', 'Taze Sebze & Meyve', 1),
('gida', 'Gıda', 'gallery', 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=800&q=80', 'Şarküteri Ürünleri', 2),
('gida', 'Gıda', 'gallery', 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=800&q=80', 'Sağlıklı Atıştırmalıklar', 3),
('gida', 'Gıda', 'product', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600&q=80', 'Organik Portakal', 1),
('gida', 'Gıda', 'product', 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=600&q=80', 'Taze Portakal Suyu', 2),
('gida', 'Gıda', 'product', 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=600&q=80', 'Karışık Kuruyemiş', 3);

-- 4. FIRIN
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('firin', 'Fırın', 'cover', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1200&q=80', 'Taş Fırın', 1),
('firin', 'Fırın', 'cover', 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=1200&q=80', 'Taze Ekmek Tezgâhı', 2),
('firin', 'Fırın', 'cover', 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=1200&q=80', 'Unlu Mamuller', 3),
('firin', 'Fırın', 'logo_placeholder', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=512&q=80', 'Fırın Logo', 1),
('firin', 'Fırın', 'gallery', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&q=80', 'Ekşi Mayalı Ekmekler', 1),
('firin', 'Fırın', 'gallery', 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=800&q=80', 'Taze Çıkan Kruvasanlar', 2),
('firin', 'Fırın', 'gallery', 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=800&q=80', 'Kurabiye & Makaron', 3),
('firin', 'Fırın', 'product', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80', 'Köy Ekmeği', 1),
('firin', 'Fırın', 'product', 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600&q=80', 'Sade Kruvasan', 2),
('firin', 'Fırın', 'product', 'https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=600&q=80', 'Tuzlu Kurabiye', 3);

-- 5. KOZMETIK
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kozmetik', 'Kozmetik', 'cover', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&q=80', 'Kozmetik Dünyası', 1),
('kozmetik', 'Kozmetik', 'cover', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1200&q=80', 'Kişisel Bakım Reyonu', 2),
('kozmetik', 'Kozmetik', 'cover', 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=1200&q=80', 'Kozmetik Ürünleri', 3),
('kozmetik', 'Kozmetik', 'logo_placeholder', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=512&q=80', 'Kozmetik Logo', 1),
('kozmetik', 'Kozmetik', 'gallery', 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=800&q=80', 'Doğal & Organik Makyaj', 1),
('kozmetik', 'Kozmetik', 'gallery', 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800&q=80', 'Saç Serum & Bakım', 2),
('kozmetik', 'Kozmetik', 'gallery', 'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=800&q=80', 'Özel Parfümler', 3),
('kozmetik', 'Kozmetik', 'product', 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=600&q=80', 'Kırmızı Ruj', 1),
('kozmetik', 'Kozmetik', 'product', 'https://images.unsplash.com/photo-1547887537-6158d64c35b3?w=600&q=80', 'Nemlendirici Krem', 2),
('kozmetik', 'Kozmetik', 'product', 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80', 'Göz Farı Paleti', 3);

-- 6. DEKORASYON
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('dekorasyon', 'Dekorasyon', 'cover', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=1200&q=80', 'Ev Dekorasyon', 1),
('dekorasyon', 'Dekorasyon', 'cover', 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200&q=80', 'Modern İç Mekan', 2),
('dekorasyon', 'Dekorasyon', 'cover', 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=1200&q=80', 'Dekorasyon Vitrini', 3),
('dekorasyon', 'Dekorasyon', 'logo_placeholder', 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=512&q=80', 'Dekorasyon Logo', 1),
('dekorasyon', 'Dekorasyon', 'gallery', 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800&q=80', 'Salon Çiçekleri', 1),
('dekorasyon', 'Dekorasyon', 'gallery', 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=80', 'El Yapımı Saksı', 2),
('dekorasyon', 'Dekorasyon', 'gallery', 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&q=80', 'Yapay Çiçek / Teraryum', 3),
('dekorasyon', 'Dekorasyon', 'product', 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600&q=80', 'Seramik Saksı', 1),
('dekorasyon', 'Dekorasyon', 'product', 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=600&q=80', 'Modern Abajur', 2),
('dekorasyon', 'Dekorasyon', 'product', 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&q=80', 'Dekoratif Kırlent', 3);

-- 7. ELEKTRONIK
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('elektronik', 'Elektronik', 'cover', 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=1200&q=80', 'Elektronik Aksesuar', 1),
('elektronik', 'Elektronik', 'cover', 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=1200&q=80', 'Akıllı Cihazlar', 2),
('elektronik', 'Elektronik', 'cover', 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=1200&q=80', 'Elektronik Vitrini', 3),
('elektronik', 'Elektronik', 'logo_placeholder', 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=512&q=80', 'Elektronik Logo', 1),
('elektronik', 'Elektronik', 'gallery', 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=800&q=80', 'Telefon Kılıf & Cam', 1),
('elektronik', 'Elektronik', 'gallery', 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800&q=80', 'Bluetooth Kulaklık', 2),
('elektronik', 'Elektronik', 'gallery', 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80', 'Akıllı Saat & Bileklik', 3),
('elektronik', 'Elektronik', 'product', 'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=600&q=80', 'Silikon Kılıf', 1),
('elektronik', 'Elektronik', 'product', 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600&q=80', 'TWS Kulaklık', 2),
('elektronik', 'Elektronik', 'product', 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=600&q=80', 'Akıllı Saat', 3);

-- 8. KIRTASIYE
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kirtasiye', 'Kırtasiye', 'cover', 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=1200&q=80', 'Kırtasiye Masası', 1),
('kirtasiye', 'Kırtasiye', 'cover', 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=1200&q=80', 'Kalem ve Defterler', 2),
('kirtasiye', 'Kırtasiye', 'cover', 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=1200&q=80', 'Kırtasiye Kitaplığı', 3),
('kirtasiye', 'Kırtasiye', 'logo_placeholder', 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=512&q=80', 'Kırtasiye Logo', 1),
('kirtasiye', 'Kırtasiye', 'gallery', 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=800&q=80', 'Defter & Kalem Setleri', 1),
('kirtasiye', 'Kırtasiye', 'gallery', 'https://images.unsplash.com/photo-1516962215378-7fa2e137ae93?w=800&q=80', 'Sanatsal Hobi Seti', 2),
('kirtasiye', 'Kırtasiye', 'gallery', 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=800&q=80', 'Haftalık Planlayıcılar', 3),
('kirtasiye', 'Kırtasiye', 'product', 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=600&q=80', 'Çizgili Defter', 1),
('kirtasiye', 'Kırtasiye', 'product', 'https://images.unsplash.com/photo-1516962215378-7fa2e137ae93?w=600&q=80', 'Renkli Resim Kalemi', 2),
('kirtasiye', 'Kırtasiye', 'product', 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=600&q=80', 'Akademik Ajanda', 3);

-- 9. KAFE_LOKANTA
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1200&q=80', 'Kafe & Lokanta', 1),
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&q=80', 'Restoran Masa Düzeni', 2),
('kafe_lokanta', 'Kafe / Lokanta', 'cover', 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=1200&q=80', 'Kafe Sıcaklığı', 3),
('kafe_lokanta', 'Kafe / Lokanta', 'logo_placeholder', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=512&q=80', 'Kafe Logo', 1),
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80', 'Sıcak Kahve Çeşitleri', 1),
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80', 'Ev Yapımı Pizza', 2),
('kafe_lokanta', 'Kafe / Lokanta', 'gallery', 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80', 'Şık Sunumlu Tatlılar', 3),
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600&q=80', 'Filtre Kahve', 1),
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80', 'Karışık Pizza', 2),
('kafe_lokanta', 'Kafe / Lokanta', 'product', 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=600&q=80', 'Mozaik Pasta', 3);

-- 10. KUAFOR
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=1200&q=80', 'Kuaför Salonu', 1),
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&q=80', 'Güzellik Merkezi', 2),
('kuafor', 'Kuaför', 'cover', 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=1200&q=80', 'Saç Tasarım Köşesi', 3),
('kuafor', 'Kuaför', 'logo_placeholder', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=512&q=80', 'Kuaför Logo', 1),
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800&q=80', 'Saç Tasarım & Boya', 1),
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800&q=80', 'Modern Saç Kesimi', 2),
('kuafor', 'Kuaför', 'gallery', 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=800&q=80', 'El & Ayak Bakımı', 3),
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80', 'Saç Tasarımı', 1),
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600&q=80', 'Saç Boyama', 2),
('kuafor', 'Kuaför', 'product', 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=600&q=80', 'Manikür', 3);

-- 11. TEKNIK_SERVIS
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('teknik_servis', 'Teknik Servis', 'cover', 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=1200&q=80', 'Teknik Destek', 1),
('teknik_servis', 'Teknik Servis', 'cover', 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=1200&q=80', 'Tamir Masası', 2),
('teknik_servis', 'Teknik Servis', 'cover', 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=1200&q=80', 'Donanım Atölyesi', 3),
('teknik_servis', 'Teknik Servis', 'logo_placeholder', 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=512&q=80', 'Servis Logo', 1),
('teknik_servis', 'Teknik Servis', 'gallery', 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&q=80', 'Ekran & Donanım Onarım', 1),
('teknik_servis', 'Teknik Servis', 'gallery', 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=800&q=80', 'Hızlı Batarya Yenileme', 2),
('teknik_servis', 'Teknik Servis', 'gallery', 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800&q=80', 'Teknik Ekipman & Alet', 3),
('teknik_servis', 'Teknik Servis', 'product', 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600&q=80', 'Ekran Değişimi', 1),
('teknik_servis', 'Teknik Servis', 'product', 'https://images.unsplash.com/photo-1616440347437-b1c73416efc2?w=600&q=80', 'Yeni Batarya', 2),
('teknik_servis', 'Teknik Servis', 'product', 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&q=80', 'Format & Yazılım', 3);

-- 12. HIZMET_DANISMANLIK
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'cover', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=1200&q=80', 'Danışmanlık Hizmetleri', 1),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'cover', 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200&q=80', 'Kurumsal Ofis', 2),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'cover', 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=1200&q=80', 'Finansal Analiz', 3),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'logo_placeholder', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=512&q=80', 'Danışmanlık Logo', 1),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'gallery', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&q=80', 'Mali Müşavirlik', 1),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'gallery', 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80', 'Hukuki Danışmanlık', 2),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'gallery', 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=800&q=80', 'Marka & Kariyer Koçluğu', 3),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'product', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80', 'Kariyer Danışmanlığı', 1),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'product', 'https://images.unsplash.com/photo-1434626881859-194d67b2b86f?w=600&q=80', 'Finansal Raporlama', 2),
('hizmet_danismanlik', 'Hizmet & Danışmanlık', 'product', 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&q=80', 'Hukuki Danışmanlık', 3);

-- 13. EGITIM_DERS
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('egitim_ders', 'Eğitim & Ders', 'cover', 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=1200&q=80', 'Eğitim / Okul', 1),
('egitim_ders', 'Eğitim & Ders', 'cover', 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=1200&q=80', 'Çalışma Kütüphanesi', 2),
('egitim_ders', 'Eğitim & Ders', 'cover', 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=1200&q=80', 'Birebir Ders', 3),
('egitim_ders', 'Eğitim & Ders', 'logo_placeholder', 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=512&q=80', 'Eğitim Logo', 1),
('egitim_ders', 'Eğitim & Ders', 'gallery', 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=800&q=80', 'Özel Matematik Dersi', 1),
('egitim_ders', 'Eğitim & Ders', 'gallery', 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80', 'İngilizce Konuşma', 2),
('egitim_ders', 'Eğitim & Ders', 'gallery', 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80', 'Yazılım & Kodlama', 3),
('egitim_ders', 'Eğitim & Ders', 'product', 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=600&q=80', 'Matematik Özel Ders', 1),
('egitim_ders', 'Eğitim & Ders', 'product', 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&q=80', 'İngilizce Kursu', 2),
('egitim_ders', 'Eğitim & Ders', 'product', 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600&q=80', 'Yazılım Eğitimi', 3);

-- 14. EV_TEMIZLIK
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('ev_temizlik', 'Ev & Temizlik', 'cover', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=1200&q=80', 'Temizlik Hizmetleri', 1),
('ev_temizlik', 'Ev & Temizlik', 'cover', 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=1200&q=80', 'Temizlik Ekipmanları', 2),
('ev_temizlik', 'Ev & Temizlik', 'cover', 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=1200&q=80', 'Düzenli Ev Ortamı', 3),
('ev_temizlik', 'Ev & Temizlik', 'logo_placeholder', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=512&q=80', 'Temizlik Logo', 1),
('ev_temizlik', 'Ev & Temizlik', 'gallery', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80', 'Detaylı Ev Temizliği', 1),
('ev_temizlik', 'Ev & Temizlik', 'gallery', 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=800&q=80', 'Koltuk & Halı Yıkama', 2),
('ev_temizlik', 'Ev & Temizlik', 'gallery', 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=800&q=80', 'Ütü & Çamaşır Hizmeti', 3),
('ev_temizlik', 'Ev & Temizlik', 'product', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&q=80', 'Standart Ev Temizliği', 1),
('ev_temizlik', 'Ev & Temizlik', 'product', 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=600&q=80', 'Koltuk Yıkama', 2),
('ev_temizlik', 'Ev & Temizlik', 'product', 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=600&q=80', 'Ütü Hizmeti', 3);

-- 15. SPOR_FITNESS
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('spor_fitness', 'Spor & Fitness', 'cover', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80', 'Fitness Salonu', 1),
('spor_fitness', 'Spor & Fitness', 'cover', 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200&q=80', 'Ağırlık Antrenmanı', 2),
('spor_fitness', 'Spor & Fitness', 'cover', 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=1200&q=80', 'Egzersiz Alanı', 3),
('spor_fitness', 'Spor & Fitness', 'logo_placeholder', 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=512&q=80', 'Fitness Logo', 1),
('spor_fitness', 'Spor & Fitness', 'gallery', 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800&q=80', 'Ağırlık & Kardiyo', 1),
('spor_fitness', 'Spor & Fitness', 'gallery', 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&q=80', 'Birebir Antrenör (PT)', 2),
('spor_fitness', 'Spor & Fitness', 'gallery', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80', 'Online Pilates & Ders', 3),
('spor_fitness', 'Spor & Fitness', 'product', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80', 'Spor Salonu Üyeliği', 1),
('spor_fitness', 'Spor & Fitness', 'product', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80', 'PT Paket Dersi', 2),
('spor_fitness', 'Spor & Fitness', 'product', 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=600&q=80', 'Pilates Dersi', 3);

-- 16. PET_SHOP_VETERINER
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'cover', 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=1200&q=80', 'Pet Shop & Klinik', 1),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'cover', 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=1200&q=80', 'Pet Bakım Salonu', 2),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'cover', 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=1200&q=80', 'Klinik Muayene', 3),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'logo_placeholder', 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=512&q=80', 'Pet Logo', 1),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'gallery', 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800&q=80', 'Pet Kuaför & Bakım', 1),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'gallery', 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=800&q=80', 'Premium Pet Mama', 2),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'gallery', 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80', 'Veteriner Muayene', 3),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'product', 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=600&q=80', 'Kedi Maması 10kg', 1),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'product', 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=600&q=80', 'Pet Tüy Kesimi', 2),
('pet_shop_veteriner', 'Pet Shop & Veteriner', 'product', 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=600&q=80', 'Genel Muayene', 3);

-- 17. SAGLIK_YASAM
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('saglik_yasam', 'Sağlık & Yaşam', 'cover', 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=1200&q=80', 'Sağlık & Danışmanlık', 1),
('saglik_yasam', 'Sağlık & Yaşam', 'cover', 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=1200&q=80', 'Klinik Hizmetleri', 2),
('saglik_yasam', 'Sağlık & Yaşam', 'cover', 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=1200&q=80', 'Fizyoterapi Salonu', 3),
('saglik_yasam', 'Sağlık & Yaşam', 'logo_placeholder', 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=512&q=80', 'Sağlık Logo', 1),
('saglik_yasam', 'Sağlık & Yaşam', 'gallery', 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&q=80', 'Diyetisyen Danışmanlığı', 1),
('saglik_yasam', 'Sağlık & Yaşam', 'gallery', 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800&q=80', 'Klinik Kontrol', 2),
('saglik_yasam', 'Sağlık & Yaşam', 'gallery', 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=800&q=80', 'Fizyoterapi & Yaşam', 3),
('saglik_yasam', 'Sağlık & Yaşam', 'product', 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=600&q=80', 'Diyetisyen Analizi', 1),
('saglik_yasam', 'Sağlık & Yaşam', 'product', 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600&q=80', 'Fizyoterapi Seansı', 2),
('saglik_yasam', 'Sağlık & Yaşam', 'product', 'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=600&q=80', 'Psikolog Görüşmesi', 3);

-- 18. OTO_ARAC
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('oto_arac', 'Oto & Araç Hizmetleri', 'cover', 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=1200&q=80', 'Araç Bakım & Yıkama', 1),
('oto_arac', 'Oto & Araç Hizmetleri', 'cover', 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=1200&q=80', 'Detaylı Oto Temizlik', 2),
('oto_arac', 'Oto & Araç Hizmetleri', 'cover', 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=1200&q=80', 'Seramik Kaplama Atölyesi', 3),
('oto_arac', 'Oto & Araç Hizmetleri', 'logo_placeholder', 'https://images.unsplash.com/photo-1551522435-a13afa10f103?w=512&q=80', 'Araç Logo', 1),
('oto_arac', 'Oto & Araç Hizmetleri', 'gallery', 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=800&q=80', 'Detaylı Oto Yıkama', 1),
('oto_arac', 'Oto & Araç Hizmetleri', 'gallery', 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=800&q=80', 'Periyodik Araç Bakımı', 2),
('oto_arac', 'Oto & Araç Hizmetleri', 'gallery', 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=800&q=80', 'Pasta Cila & Seramik', 3),
('oto_arac', 'Oto & Araç Hizmetleri', 'product', 'https://images.unsplash.com/photo-1552930294-6b595f4c2974?w=600&q=80', 'Detaylı İç Dış Yıkama', 1),
('oto_arac', 'Oto & Araç Hizmetleri', 'product', 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=600&q=80', 'Seramik Kaplama', 2),
('oto_arac', 'Oto & Araç Hizmetleri', 'product', 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=600&q=80', 'İç Detaylı Temizlik', 3);

-- 19. DIGER
INSERT INTO category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES
('diger', 'Diğer', 'cover', 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=1200&q=80', 'VixRex İşletmesi', 1),
('diger', 'Diğer', 'cover', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&q=80', 'Genel Hizmet Alanı', 2),
('diger', 'Diğer', 'cover', 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200&q=80', 'Ürün / Raf Teşhiri', 3),
('diger', 'Diğer', 'logo_placeholder', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=512&q=80', 'İşletme Logo', 1),
('diger', 'Diğer', 'gallery', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80', 'Genel Danışmanlık', 1),
('diger', 'Diğer', 'gallery', 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=800&q=80', 'Özel Hizmet & Destek', 2),
('diger', 'Diğer', 'gallery', 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80', 'Ürün & Raf Düzeni', 3),
('diger', 'Diğer', 'product', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80', 'Özel Hizmet Paketleri', 1),
('diger', 'Diğer', 'product', 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=600&q=80', 'Standart Paket', 2),
('diger', 'Diğer', 'product', 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=600&q=80', 'Danışma Saati', 3);
