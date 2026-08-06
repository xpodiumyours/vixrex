-- ============================================================================
-- Kiralık Vitrin Seed Data
-- 5 kategori: Butik, Kafe/Lokanta, Kuaför, Teknik Servis, Gıda
-- ÖNKoşul: 20260727_add_atmosfer_store_product_fields.sql uygulanmış olmalı
-- ÖNKoşul: 20260728_add_is_demo_to_stores.sql uygulanmış olmalı
-- ============================================================================

-- ============================================================================
-- 1. KİRALIK VİTRİN MAĞAZALARI
-- ============================================================================
INSERT INTO public.stores (
  slug, name, business_type, description, corporate_bio,
  whatsapp, instagram, address,
  kategori, status,
  shelf_image_url, logo_url,
  working_hours, is_published, is_demo,
  latitude, longitude,
  province_name, district_name,
  theme_preset, email, rating_score, review_count,
  featured_banner_title, featured_banner_description,
  featured_banner_image_url, featured_banner_price_text
)
VALUES
-- ── 1. BUTIK ──────────────────────────────────────────────────────────────────
(
  'kiralik-butik',
  'Atmosfer Butik',
  'Butik',
  'Çekmeköy''nun kalbinde, özel dikim ve sınırlı sayıda koleksiyonlar sunan butik mağaza. Her parça bir hikaye anlatır.',
  'Atmosfer Butik, 2019''dan bu yana Çekmeköy''da premium giyim deneyimi sunmaktadır. Özel tasarım elbiseler, el yapımı aksesuarlar ve sezonluk kapsül koleksiyonlarıyla tanınır.',
  '905321234567',
  '@atmosfer.butik',
  'Çekmeköy Mah. Ömerli Cad. No:12, Çekmeköy, İstanbul',
  'Butik',
  'açık',
  'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=1600&q=80',
  'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=200&q=80',
  '{"monday":"09:00-20:00","tuesday":"09:00-20:00","wednesday":"09:00-20:00","thursday":"09:00-20:00","friday":"09:00-21:00","saturday":"10:00-21:00","sunday":"11:00-18:00"}',
  true, true,
  41.035, 29.252,
  'İstanbul', 'Çekmeköy',
  'atmosfer', 'merhaba@atmosfer-butik.com', 4.9, 128,
  'Sonbahar / Kış 2026 Koleksiyonu',
  'Doğal kumaşlar, sürdürülebilir üretim ve zamansız tasarımlar. Sınırlı sayıda, ön siparişle.',
  'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80',
  '349 TL''den başlayan fiyatlarla'
),
-- ── 2. KAFE / LOKANTA ─────────────────────────────────────────────────────────
(
  'kiralik-kafe',
  'Kahve Köşesi',
  'Kafe / Lokanta',
  'Taze çekilmiş kahveler, ev yapımı tatlılar ve sıcak bir atmosfer. Her gün taze pişirilen lezzetler sizi bekliyor.',
  'Kahve Köşesi, 2021''den beri Kadıköy''de butik kahve deneyimi sunmaktadır. Özel çekirdeklerden hazırlanan yeni nesil kahveler ve el yapımı pastalarıyla meşhurdur.',
  '905391234568',
  '@kahvekosei',
  'Moda Cad. No:45, Kadıköy, İstanbul',
  'Kafe / Lokanta',
  'açık',
  'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1600&q=80',
  'https://images.unsplash.com/photo-1453614512568-c4024d13c247?w=200&q=80',
  '{"monday":"07:30-22:00","tuesday":"07:30-22:00","wednesday":"07:30-22:00","thursday":"07:30-22:00","friday":"07:30-23:00","saturday":"08:00-23:00","sunday":"09:00-21:00"}',
  true, true,
  40.990, 29.028,
  'İstanbul', 'Kadıköy',
  'atmosfer', 'merhaba@kahvekosei.com', 4.8, 214,
  'Haziran Özel Menüsü',
  'Mevsim meyveleriyle hazırlanan soğuk içecekler ve ev yapımı limonata. Yaz boyunca geçerli özel fiyatlar.',
  'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80',
  '45 TL''den başlayan içecekler'
),
-- ── 3. KUAFÖR ────────────────────────────────────────────────────────────────
(
  'kiralik-kuafor',
  'Stil Studio',
  'Kuaför',
  'Profesyonel saç tasarımı, renklendirme ve kişisel bakım hizmetleri. Deneyimli ekibimizle stilinizi yenileyin.',
  'Stil Studio, Beşiktaş''ta modern kuaförlük anlayışıyla hizmet vermektedir. Saç kesimi, boyama ve özel gün makyajı alanında uzman kadrosuyla öne çıkar.',
  '905351234569',
  '@stilstudio.bsk',
  'Beşiktaş Cad. No:78, Beşiktaş, İstanbul',
  'Kuaför',
  'açık',
  'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1600&q=80',
  'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=200&q=80',
  '{"monday":"09:00-20:00","tuesday":"09:00-20:00","wednesday":"09:00-20:00","thursday":"09:00-20:00","friday":"09:00-20:00","saturday":"09:00-19:00","sunday":""}',
  true, true,
  41.043, 29.005,
  'İstanbul', 'Beşiktaş',
  'atmosfer', 'merhaba@stilstudio.com', 4.9, 187,
  'Yaz Sezonu Fırsatları',
  'Haziran-Ağustos boyunca tüm saç boyama işlemlerinde %20 indirim. Randevu için WhatsApp''tan ulaşın.',
  'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800&q=80',
  '150 TL''den başlayan hizmetler'
),
-- ── 4. TEKNİK SERVİS ─────────────────────────────────────────────────────────
(
  'kiralik-teknik',
  'Hızlı Teknik',
  'Teknik Servis',
  'Telefon, tablet ve bilgisayar onarımları. Orjinal yedek parça, 1 yıl garanti ve aynı gün teslimat.',
  'Hızlı Teknik, Bağcılar''da 2018''den beri güvenilir cihaz onarım hizmeti sunmaktadır. Tüm marka ve modeller için orjinal parça garantisi.',
  '905361234570',
  '@hizliteknik',
  'Bağcılar Merkez Mah. Atatürk Cad. No:120, Bağcılar, İstanbul',
  'Teknik Servis',
  'açık',
  'https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=1600&q=80',
  'https://images.unsplash.com/photo-1556761175-4b46a572b786?w=200&q=80',
  '{"monday":"09:00-19:00","tuesday":"09:00-19:00","wednesday":"09:00-19:00","thursday":"09:00-19:00","friday":"09:00-19:00","saturday":"10:00-18:00","sunday":""}',
  true, true,
  41.039, 28.856,
  'İstanbul', 'Bağcılar',
  'atmosfer', 'merhaba@hizliteknik.com', 4.7, 93,
  'Ekran Değişiminde Özel Fiyat',
  'iPhone ve Samsung ekran değişiminde bu ay %15 indirim. Aynı gün teslimat garantisi.',
  'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800&q=80',
  '299 TL''den başlayan onarım'
),
-- ── 5. GIDA ──────────────────────────────────────────────────────────────────
(
  'kiralik-gida',
  'Doğal Market',
  'Gıda',
  'Çiftçiden sofranıza organik ve doğal ürünler. Yerel üreticilerden temin edilen taze gıdalar, her hafta kapınıza.',
  'Doğal Market, 2020''den beri İstanbul''da organik gıda pazarlamaktadır. Sertifikalı çiftçilerden doğrudan temin edilen ürünler, koruyucu ve katkı maddesi içermez.',
  '905371234571',
  '@dogalmarket',
  'Üsküdar Cad. No:33, Üsküdar, İstanbul',
  'Gıda',
  'açık',
  'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1600&q=80',
  'https://images.unsplash.com/photo-1518977956812-cd3dbadaaf31?w=200&q=80',
  '{"monday":"08:00-20:00","tuesday":"08:00-20:00","wednesday":"08:00-20:00","thursday":"08:00-20:00","friday":"08:00-20:00","saturday":"08:00-18:00","sunday":"09:00-16:00"}',
  true, true,
  41.023, 29.015,
  'İstanbul', 'Üsküdar',
  'atmosfer', 'merhaba@dogalmarket.com', 4.8, 156,
  'Haftalık Sepet Kampanyası',
  'Bu haftanın organik sepeti: mevsim sebzeleri, köy yumurtası ve ev yapımı reçel. Ücretsiz teslimat.',
  'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=800&q=80',
  '250 TL sepet fiyatı'
)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- 2. STORE ID'LERİ (dinamik referans için CTE)
-- ============================================================================
DO $$
DECLARE
  v_butik_id    UUID;
  v_kafe_id     UUID;
  v_kuafor_id   UUID;
  v_teknik_id   UUID;
  v_gida_id     UUID;
BEGIN
  SELECT id INTO v_butik_id    FROM public.stores WHERE slug = 'kiralik-butik';
  SELECT id INTO v_kafe_id     FROM public.stores WHERE slug = 'kiralik-kafe';
  SELECT id INTO v_kuafor_id   FROM public.stores WHERE slug = 'kiralik-kuafor';
  SELECT id INTO v_teknik_id   FROM public.stores WHERE slug = 'kiralik-teknik';
  SELECT id INTO v_gida_id     FROM public.stores WHERE slug = 'kiralik-gida';

-- ============================================================================
-- 3. ÜRÜN KATEGORİLERİ
-- ============================================================================
  INSERT INTO public.product_categories (store_id, name, slug, sort_order) VALUES
    -- Butik
    (v_butik_id, 'Giyim', 'giyim', 1),
    (v_butik_id, 'İç Giyim', 'ic-giyim', 2),
    (v_butik_id, 'Aksesuar', 'aksesuar', 3),
    (v_butik_id, 'Özel Koleksiyon', 'ozel-koleksiyon', 4),
    -- Kafe
    (v_kafe_id, 'Kahveler', 'kahveler', 1),
    (v_kafe_id, 'Tatlılar', 'tatlilar', 2),
    (v_kafe_id, 'Hafif Yemekler', 'hafif-yemekler', 3),
    -- Kuaför
    (v_kuafor_id, 'Saç Bakımı', 'sac-bakimi', 1),
    (v_kuafor_id, 'Boyama', 'boyama', 2),
    (v_kuafor_id, 'Makyaj', 'makyaj', 3),
    -- Teknik Servis
    (v_teknik_id, 'Telefon Onarımı', 'telefon-onarimi', 1),
    (v_teknik_id, 'Laptop Servisi', 'laptop-servisi', 2),
    (v_teknik_id, 'Aksesuar', 'aksesuar', 3),
    -- Gıda
    (v_gida_id, 'Organik Sebze & Meyve', 'organik-sebze-meyve', 1),
    (v_gida_id, 'Şarküteri', 'sarküteri', 2),
    (v_gida_id, 'Ev Yapımı', 'ev-yapimi', 3)
  ON CONFLICT (store_id, slug) DO NOTHING;

-- ============================================================================
-- 4. ÜRÜNLER
-- ============================================================================
  INSERT INTO public.products (
    store_id, category_id, name, slug, description,
    price_amount, old_price_amount, price_text, currency,
    badge_tag, image_urls, is_visible, is_active, sort_order, source_type
  )
  SELECT
    s.id AS store_id,
    pc.id AS category_id,
    p.name, p.slug, p.description,
    p.price_amount, p.old_price_amount, p.price_text, p.currency,
    p.badge_tag, p.image_urls::jsonb,
    true, true, p.sort_order, 'manual'
  FROM (VALUES
    -- ── BUTIK ürünleri ──────────────────────────────────────────────────────
    ('kiralik-butik', 'Giyim',         'Sonbahar Trençkot',      'sonbahar-trenckat',     'Klasik kesim, %100 yün karışımlı premium kumaş.',                   899, 1199, '899 TL',  'TRY', '-25%', '["https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=600&q=80"]'::jsonb, 1),
    ('kiralik-butik', 'Giyim',         'Günlük Keten Gömlek',    'gunluk-keten-gomlek',   'Nefes alan keten kumaş, rahat kesim, 4 renk seçenek.',              349, NULL, '349 TL',  'TRY', 'Yeni',  '["https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600&q=80"]'::jsonb, 2),
    ('kiralik-butik', 'İç Giyim',      'Bambu Pijama Takımı',    'bambu-pijama',          'Ultra yumuşak bambu karışımlı pijama. S-XL beden aralığı.',         449, 599, '449 TL',   'TRY', '-25%', '["https://images.unsplash.com/photo-1631125915902-d8abe9225ff2?w=600&q=80"]'::jsonb, 3),
    ('kiralik-butik', 'Aksesuar',      'El Yapımı Deri Çanta',   'el-yapimi-deri-canta',  'Özel tablo dikim, tam grain İtalyan derisi.',                      1250, NULL,'1.250 TL', 'TRY', 'Özel', '["https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&q=80"]'::jsonb, 4),
    ('kiralik-butik', 'Aksesuar',      'İpek Fular',             'ipek-fular',            '%100 doğal ipek, el baskısı desen. 90x90 cm.',                      299, NULL, '299 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1601924638867-3a6de6b7a500?w=600&q=80"]'::jsonb, 5),
    ('kiralik-butik', 'Özel Koleksiyon','Kapsül Sezon Elbise',   'kapsul-sezon-elbise',   'Sınırlı üretim, özel dikim, yalnızca 30 adet.',                    1450, 1800,'1.450 TL', 'TRY', 'Son 5', '["https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=600&q=80"]'::jsonb, 6),
    -- ── KAFE ürünleri ────────────────────────────────────────────────────────
    ('kiralik-kafe', 'Kahveler',      'Filtre Kahve (V60)',       'filtre-kahve-v60',      'Tek orjinli Etiyopya çekirdeği, 250ml demleme.',                    65, NULL, '65 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&q=80"]'::jsonb, 1),
    ('kiralik-kafe', 'Kahveler',      'Cold Brew',               'cold-brew',             '18 saat soğuk demleme, hafif asitli yumuşak içim.',                 75, NULL, '75 TL',   'TRY', 'Özel', '["https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600&q=80"]'::jsonb, 2),
    ('kiralik-kafe', 'Tatlılar',      'Tiramisu (Ev Yapımı)',    'tiramisu',              'Orijinal İtalyan tarifi, günlük taze hazırlama.',                   95, NULL, '95 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=600&q=80"]'::jsonb, 3),
    ('kiralik-kafe', 'Tatlılar',      'Çikolatalı Kek',          'cikolatali-kek',        'Bitter çikolata ganajlı, orman meyveli.',                           75, NULL, '75 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&q=80"]'::jsonb, 4),
    ('kiralik-kafe', 'Hafif Yemekler','Avokado Toast',           'avokado-toast',         'Ekşi mayalı ekmek, taze avokado, poşe yumurta.',                   125, NULL, '125 TL',  'TRY', 'Popüler','["https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&q=80"]'::jsonb, 5),
    ('kiralik-kafe', 'Hafif Yemekler','Kaşarlı Tost',            'kasarli-tost',          'Özel ekmekte kaşar, domates, roka.',                                85, NULL, '85 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1528736235302-52922df5c122?w=600&q=80"]'::jsonb, 6),
    -- ── KUAFÖR ürünleri ──────────────────────────────────────────────────────
    ('kiralik-kuafor', 'Saç Bakımı',  'Saç Kesimi & Yıkama',    'sac-kesimi-yikama',     'Yüz hattına özel kesim, profesyonel yıkama ve fön.',               150, NULL, '150 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600&q=80"]'::jsonb, 1),
    ('kiralik-kuafor', 'Saç Bakımı',  'Keratin Bakımı',         'keratin-bakimi',         'Yıpranmış saçlar için besleyici keratin yüklemesi ve fön.',         450, 550, '450 TL',  'TRY', '-18%', '["https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=600&q=80"]'::jsonb, 2),
    ('kiralik-kuafor', 'Boyama',      'Komple Saç Boyama',       'komple-sac-boyama',     'Kaliteli profesyonel saç boyası, her renk.',                        350, NULL, '350 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80"]'::jsonb, 3),
    ('kiralik-kuafor', 'Boyama',      'Balyaj & Ombre',          'balyaj-ombre',          'Doğal geçişli renklendirme, hasar yapmayan teknik.',                550, NULL, '550 TL',  'TRY', 'Trend', '["https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?w=600&q=80"]'::jsonb, 4),
    ('kiralik-kuafor', 'Makyaj',      'Gece Makyajı',            'gece-makyaji',          'Nişan, davet ve özel gece makyajı.',                                400, NULL, '400 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80"]'::jsonb, 5),
    ('kiralik-kuafor', 'Makyaj',      'Manikür & Pedikür',       'manikur-pedikur',       'Profesyonel el ve ayak tırnak bakımı.',                             200, NULL, '200 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1604654894610-df63bc536371?w=600&q=80"]'::jsonb, 6),
    -- ── TEKNİK SERVİS ürünleri ───────────────────────────────────────────────
    ('kiralik-teknik', 'Telefon Onarımı','iPhone Ekran Değişimi','iphone-ekran-degisimi', 'Tüm iPhone modelleri, orjinal ekran, 1 yıl garanti.',              399, 499, '399 TL',   'TRY', '-20%', '["https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=600&q=80"]'::jsonb, 1),
    ('kiralik-teknik', 'Telefon Onarımı','Samsung Ekran Değişimi','samsung-ekran-degisimi','Samsung Galaxy serisi, orjinal AMOLED ekran.',                    449, NULL, '449 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=600&q=80"]'::jsonb, 2),
    ('kiralik-teknik', 'Telefon Onarımı','Batarya Yenileme',     'batarya-yenileme',      'Tüm markalar, yüksek kapasiteli orjinal batarya.',                 249, NULL, '249 TL',   'TRY', 'Hızlı', '["https://images.unsplash.com/photo-1580910051074-3eb694886505?w=600&q=80"]'::jsonb, 3),
    ('kiralik-teknik', 'Laptop Servisi','Laptop Format & Kurulum','laptop-format-kurulum', 'İşletim sistemi kurulumu, veri yedekleme, sürücü yüklemeleri.',   350, NULL, '350 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&q=80"]'::jsonb, 4),
    ('kiralik-teknik', 'Laptop Servisi','Fan & Termal Bakımı',   'fan-termal-bakim',      'Laptop aşırı ısınma sorunu, fan temizlik ve macun değişimi.',      299, NULL, '299 TL',  'TRY', NULL,    '["https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80"]'::jsonb, 5),
    ('kiralik-teknik', 'Aksesuar',    'Temperli Cam Ekran Koruyucu','ekran-koruyucu',     '9H sertlik, tam kaplama, montaj dahil.',                            49, NULL, '49 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=600&q=80"]'::jsonb, 6),
    -- ── GIDA ürünleri ────────────────────────────────────────────────────────
    ('kiralik-gida', 'Organik Sebze & Meyve','Haftalık Sebze Sepeti','haftalık-sebze-sepeti','5 çeşit mevsim sebzesi, 3 kg, çiftçiden doğrudan.',             165, NULL, '165 TL',  'TRY', 'Taze',  '["https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80"]'::jsonb, 1),
    ('kiralik-gida', 'Organik Sebze & Meyve','Organik Domates (1 kg)','organik-domates',  'Sera domates, sertifikalı organik, kırmızı ve sarı karışım.',        45, NULL, '45 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&q=80"]'::jsonb, 2),
    ('kiralik-gida', 'Şarküteri',     'Köy Peyniri (500 gr)',    'koy-peyniri',           'Keçi sütü, geleneksel tuzlama, sertifikalı üretim.',                95, NULL, '95 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=600&q=80"]'::jsonb, 3),
    ('kiralik-gida', 'Şarküteri',     'Yöresel Zeytin Karma',    'yoresel-zeytin-karma',  '4 çeşit yöresel zeytin, 500 gr cam kavanozu.',                      75, NULL, '75 TL',   'TRY', 'Özel', '["https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=600&q=80"]'::jsonb, 4),
    ('kiralik-gida', 'Ev Yapımı',     'Çilek Reçeli (400 gr)',   'cilek-receli',          'Katkısız, geleneksel yöntem, bol meyve.',                            55, NULL, '55 TL',   'TRY', NULL,    '["https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=600&q=80"]'::jsonb, 5),
    ('kiralik-gida', 'Ev Yapımı',     'Kuru Domates & Zeytinyağı','kuru-domates-zeytinyagi','Güneşte kurutulmuş domates, özel zeytinyağı sosunda.',            85, NULL, '85 TL',   'TRY', 'Özel', '["https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&q=80"]'::jsonb, 6)
  ) AS p(store_slug, category_name, name, slug, description, price_amount, old_price_amount, price_text, currency, badge_tag, image_urls, sort_order)
  JOIN public.stores s ON s.slug = p.store_slug
  JOIN public.product_categories pc ON pc.store_id = s.id AND pc.name = p.category_name
  ON CONFLICT DO NOTHING;

END $$;
