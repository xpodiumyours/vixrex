-- ============================================================================
-- Eksik Kategorilere Demo Vitrin Seed Verisi
-- 12 kategori: Giyim, Kozmetik, Dekorasyon, Elektronik, Kırtasiye,
--   Pet Shop & Veteriner, Hizmet & Danışmanlık, Eğitim & Ders,
--   Ev & Temizlik, Spor & Fitness, Sağlık & Yaşam, Oto & Araç
-- ============================================================================
-- Her vitrin teknofix kalitesinde: Hakkımızda, Galeri, SSS, Blog,
-- About (3 değer kartı), Kategori Grid, Kampanya Bandı dahil.
-- ÖNKoşul: 20260728000003_kiralik_vitrin_seed.sql uygulanmış olmalı
-- ÖNKoşul: 20260809120000_demo_teknofix_icerik_doldur.sql uygulanmış olmalı
-- ============================================================================

DO $$
DECLARE
  v_giyim_id      UUID;
  v_kozmetik_id   UUID;
  v_dekorasyon_id UUID;
  v_elektronik_id UUID;
  v_kirtasiye_id  UUID;
  v_pet_id        UUID;
  v_hizmet_id     UUID;
  v_egitim_id     UUID;
  v_evtemizlik_id UUID;
  v_spor_id       UUID;
  v_saglik_id     UUID;
  v_oto_id        UUID;
BEGIN

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ 1. MAĞAZA SEED VERİLERİ (12 yeni demo vitrin)                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

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
-- ── 1. GİYİM ────────────────────────────────────────────────────────────────
(
  'kiralik-giyim', 'Moda Evren', 'Giyim',
  'Zamansız tasarımlar, doğal kumaşlar ve sürdürülebilir moda. Her parça özenle seçilmiş, gardırobunuzun vazgeçilmezi.',
  'Moda Evren, Nişantaşı''da 2020''den beri sürdürülebilir moda anlayışıyla hizmet vermektedir. Doğal kumaşlar, yerel üretim ve zamansız tasarım prensipleriyle çalışır.',
  '905401234572', '@modaevren', 'Nişantaşı Mah. Abdi İpekçi Cad. No:55, Şişli, İstanbul',
  'Giyim', 'açık',
  'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=1600&q=80',
  'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=200&q=80',
  '{"monday":"10:00-20:00","tuesday":"10:00-20:00","wednesday":"10:00-20:00","thursday":"10:00-20:00","friday":"10:00-21:00","saturday":"10:00-21:00","sunday":"11:00-19:00"}',
  true, true,
  41.052, 28.987, 'İstanbul', 'Şişli', 'atmosfer', 'merhaba@modaevren.com', 4.8, 143,
  'Yeni Sezon Koleksiyonu', 'Doğal kumaşlar ve sürdürülebilir üretimle hazırlanan sonbahar/kış koleksiyonumuz sizleri bekliyor.',
  'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80',
  '199 TL''den başlayan fiyatlarla'),
-- ── 2. KOZMETİK ─────────────────────────────────────────────────────────────
(
  'kiralik-kozmetik', 'Güzellik Dünyası', 'Kozmetik',
  'Doğal ve organik içerikli kozmetik ürünleri. Cildinize zarar vermeyen, bitkisel kaynaklı profesyonel bakım ürünleri.',
  'Güzellik Dünyası, 2019''dan beri Maltepe''de doğal kozmetik ürünleri sunmaktadır. Vegan ve cruelty-free sertifikalı ürünler, cilt analizi ve özel bakım danışmanlığı hizmeti verir.',
  '905411234573', '@guzellikdunyasi', 'Maltepe Mah. Bağdat Cad. No:102, Maltepe, İstanbul',
  'Kozmetik', 'açık',
  'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1600&q=80',
  'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=200&q=80',
  '{"monday":"09:30-19:30","tuesday":"09:30-19:30","wednesday":"09:30-19:30","thursday":"09:30-19:30","friday":"09:30-20:00","saturday":"10:00-19:00","sunday":"11:00-18:00"}',
  true, true,
  40.937, 29.082, 'İstanbul', 'Maltepe', 'atmosfer', 'merhaba@guzellikdunyasi.com', 4.7, 167,
  'Yaz Bakım Kampanyası', 'Vegan ve cruelty-free ürünlerimizde yaz boyunca %20 indirim. Ücretsiz cilt analizi dahil.',
  'https://images.unsplash.com/photo-1570194065650-d99fb4a38691?w=800&q=80',
  '89 TL''den başlayan ürünler'),
-- ── 3. DEKORASYON ────────────────────────────────────────────────────────────
(
  'kiralik-dekorasyon', 'Yeşil Ev', 'Dekorasyon',
  'İç mekan bitkileri, çiçek aranjmanları ve el yapımı seramik ürünler. Evinize doğayı taşıyın.',
  'Yeşil Ev, Kadıköy''de 2021''den beri iç mekan dekorasyonu ve çiçek tasarımı hizmeti sunmaktadır. Canlı bitki yerleşimi, özel gün çiçekleri ve el yapımı seramik koleksiyonlarıyla tanınır.',
  '905421234574', '@yesilev.dekor', 'Fenerbahçe Mah.(postanesi Cad. No:28, Kadıköy, İstanbul',
  'Dekorasyon', 'açık',
  'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=1600&q=80',
  'https://images.unsplash.com/photo-1487530811176-3780de880c2d?w=200&q=80',
  '{"monday":"09:00-19:00","tuesday":"09:00-19:00","wednesday":"09:00-19:00","thursday":"09:00-19:00","friday":"09:00-20:00","saturday":"10:00-18:00","sunday":"10:00-17:00"}',
  true, true,
  40.983, 29.028, 'İstanbul', 'Kadıköy', 'atmosfer', 'merhaba@yesilev.com', 4.9, 112,
  'Yeni Sezon Çiçekleri', 'Taze mevsim çiçekleri ve özel aranjmanlarımız yenilendi. Online sipariş için WhatsApp.',
  'https://images.unsplash.com/photo-1487530811176-3780de880c2d?w=800&q=80',
  '75 TL''den başlayan aranjmanlar'),
-- ── 4. ELEKTRONİK ───────────────────────────────────────────────────────────
(
  'kiralik-elektronik', 'TeknoMarket', 'Elektronik',
  'Akıllı cihazlar, aksesuarlar ve teknoloji ürünleri. Güvenilir markalar, uygun fiyatlar ve 2 yıl garanti.',
  'TeknoMarket, 2018''den beri İstanbul''da teknoloji ürünleri satışı yapmaktadır. Apple, Samsung ve Xiaomi gibi önde gelen markaların yetkili satıcısıdır.',
  '905431234575', '@teknomarket.tr', 'Atatürk Mah. Millet Cad. No:77, Bağcılar, İstanbul',
  'Elektronik', 'açık',
  'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=1600&q=80',
  'https://images.unsplash.com/photo-1518770660439-4636190af475?w=200&q=80',
  '{"monday":"09:00-21:00","tuesday":"09:00-21:00","wednesday":"09:00-21:00","thursday":"09:00-21:00","friday":"09:00-22:00","saturday":"10:00-22:00","sunday":"10:00-20:00"}',
  true, true,
  41.039, 28.856, 'İstanbul', 'Bağcılar', 'atmosfer', 'merhaba@teknomarket.com', 4.6, 203,
  'Bayram Fırsatları', 'Seçili ürünlerde %30''a varan indirimler. 12 aya varan taksit seçenekleri.',
  'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&q=80',
  '49 TL''den başlayan fiyatlar'),
-- ── 5. KIRTASİYE ────────────────────────────────────────────────────────────
(
  'kiralik-kirtasiye', 'Hayal Gücü', 'Kırtasiye',
  'Sanat malzemeleri, okul gereçleri ve yaratıcı hobi setleri. Her yaşa uygun geniş ürün yelpazesi.',
  'Hayal Gücü, Beşiktaş''ta 2017''den beri kırtasiye ve sanat malzemeleri satışı yapmaktadır. Öğrenciler ve sanatçılar için profesyonel malzemeler, atölye çalışmaları düzenler.',
  '905441234576', '@hayalgucu.kirtasiye', 'Sinanpaşa Mah. Ortabahçe Cad. No:34, Beşiktaş, İstanbul',
  'Kırtasiye', 'açık',
  'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=1600&q=80',
  'https://images.unsplash.com/photo-1456735190827-d1262f71b8a3?w=200&q=80',
  '{"monday":"09:00-19:00","tuesday":"09:00-19:00","wednesday":"09:00-19:00","thursday":"09:00-19:00","friday":"09:00-20:00","saturday":"10:00-18:00","sunday":"11:00-17:00"}',
  true, true,
  41.043, 29.005, 'İstanbul', 'Beşiktaş', 'atmosfer', 'merhaba@hayalgucu.com', 4.8, 89,
  'Okula Dönüş Kampanyası', 'Tüm okul gereçlerinde %25 indirim. Kalem, defter ve çanta setleri özel fiyatlarla.',
  'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=800&q=80',
  '9 TL''den başlayan ürünler'),
-- ── 6. PET SHOP & VETERİNER ─────────────────────────────────────────────────
(
  'kiralik-petshop', 'Pati Dostu', 'Pet Shop & Veteriner',
  'Evcil hayvan mamaları, aksesuarları ve veteriner hizmetleri. Patili dostlarınız için her şey.',
  'Pati Dostu, 2020''den beri Bakırköy''de evcil hayvan sahiplerine hizmet vermektedir. Premium mamalar, profesyonel bakım ve deneyimli veteriner hekim kadrosuyla güvenilir adres.',
  '905451234577', '@pati.dostu', 'Ataköy Mah. İskele Cad. No:61, Bakırköy, İstanbul',
  'Pet Shop & Veteriner', 'açık',
  'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=1600&q=80',
  'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=200&q=80',
  '{"monday":"09:00-20:00","tuesday":"09:00-20:00","wednesday":"09:00-20:00","thursday":"09:00-20:00","friday":"09:00-20:00","saturday":"09:00-19:00","sunday":"10:00-18:00"}',
  true, true,
  40.982, 28.846, 'İstanbul', 'Bakırköy', 'atmosfer', 'merhaba@patidostu.com', 4.9, 178,
  'Yavru Hayvan Kampanyası', 'İlk 3 ay mama ve aksesuar setlerinde %20 indirim. Ücretsiz veteriner kontrolü dahil.',
  'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800&q=80',
  '45 TL''den başlayan ürünler'),
-- ── 7. HİZMET & DANIŞMANLIK ────────────────────────────────────────────────
(
  'kiralik-danismanlik', 'Bilge Danışmanlık', 'Hizmet & Danışmanlık',
  'Mali müşavirlik, hukuki danışmanlık ve kurumsal yönetim hizmetleri. İşletmenizin güvencesi.',
  'Bilge Danışmanlık, 2016''dan beri Kanyon İş Merkezi''nde profesyonel danışmanlık hizmeti sunmaktadır. Deneyimli kadromuzla vergi, hukuk ve işletme yönetimi alanlarında uzmanlaşmıştır.',
  '905461234578', '@bilge.danismanlik', 'Levent Mah. Büyükdere Cad. No:185, Şişli, İstanbul',
  'Hizmet & Danışmanlık', 'açık',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1600&q=80',
  'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=200&q=80',
  '{"monday":"09:00-18:00","tuesday":"09:00-18:00","wednesday":"09:00-18:00","thursday":"09:00-18:00","friday":"09:00-17:00","saturday":"","sunday":""}',
  true, true,
  41.081, 29.011, 'İstanbul', 'Şişli', 'atmosfer', 'merhaba@bilgedanismanlik.com', 4.7, 64,
  'Yeni Şirketlere Özel', 'Kuruluşundan itibaren 3 ay ücretsiz mali müşavirlik danışmanlığı. Randevu için ulaşın.',
  'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&q=80',
  '500 TL''den başlayan paketler'),
-- ── 8. EĞİTİM & DERS ───────────────────────────────────────────────────────
(
  'kiralik-egitim', 'Başarı Akademisi', 'Eğitim & Ders',
  'Birebir özel ders, sınav hazırlık ve online eğitim programları. Her öğrenciye özel planlama.',
  'Başarı Akademisi, 2018''den beri Üsküdar''da birebir eğitim hizmeti sunmaktadır. Deneyimli öğretmen kadrosuyla LGS, YKS ve KPSS hazırlık programları, dil dersleri ve online eğitim imkanları.',
  '905471234579', '@basari.akademisi', 'Çamlıca Mah. Millet Cad. No:42, Üsküdar, İstanbul',
  'Eğitim & Ders', 'açık',
  'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=1600&q=80',
  'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=200&q=80',
  '{"monday":"08:00-21:00","tuesday":"08:00-21:00","wednesday":"08:00-21:00","thursday":"08:00-21:00","friday":"08:00-20:00","saturday":"09:00-18:00","sunday":""}',
  true, true,
  41.023, 29.034, 'İstanbul', 'Üsküdar', 'atmosfer', 'merhaba@basariakademisi.com', 4.9, 231,
  'Deneme Dersi Kampanyası', 'İlk ders ücretsiz! Deneme dersi sonrasında kayıt yaptırana %15 indirim.',
  'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&q=80',
  '150 TL/saat''den başlayan dersler'),
-- ── 9. EV & TEMİZLİK ────────────────────────────────────────────────────────
(
  'kiralik-temizlik', 'Pırıl Temizlik', 'Ev & Temizlik',
  'Profesyonel ev, ofis ve koltuk temizliği. Çevre dostu ürünler, eğitimli ekip, garantili hizmet.',
  'Pırıl Temizlik, 2019''dan beri İstanbul genelinde temizlik hizmeti sunmaktadır. Eco-label sertifikalı ürünler, eğitimli personel ve %100 müşteri memnuniyeti garantisi ile çalışır.',
  '905481234580', '@piril.temizlik', 'Bahçelievler Mah. Merkez Cad. No:15, Bahçelievler, İstanbul',
  'Ev & Temizlik', 'açık',
  'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=1600&q=80',
  'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=200&q=80',
  '{"monday":"07:00-20:00","tuesday":"07:00-20:00","wednesday":"07:00-20:00","thursday":"07:00-20:00","friday":"07:00-20:00","saturday":"08:00-18:00","sunday":"09:00-15:00"}',
  true, true,
  41.004, 28.852, 'İstanbul', 'Bahçelievler', 'atmosfer', 'merhaba@piriltemizlik.com', 4.8, 312,
  'İlk Temizlik %30 İndirimli', 'Yeni müşterilerimize ilk temizlik hizmetinde %30 indirim. Eco-friendly ürünler dahil.',
  'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=800&q=80',
  '350 TL''den başlayan temizlik'),
-- ── 10. SPOR & FITNESS ──────────────────────────────────────────────────────
(
  'kiralik-spor', 'Fit Life Studio', 'Spor & Fitness',
  'Birebir personal trainer, beslenme programı ve grup dersleri. Sağlıklı yaşam için profesyonel destek.',
  'Fit Life Studio, 2020''den beri Ataşehir''de fitness ve wellness hizmeti sunmaktadır. Sertifikali personal trainer''lar, kişiye özel beslenme programları ve modern ekipmanlarla donatılmış salon.',
  '905491234581', '@fitlife.studio', 'Ataşehir Bulvarı No:102, Ataşehir, İstanbul',
  'Spor & Fitness', 'açık',
  'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1600&q=80',
  'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=200&q=80',
  '{"monday":"06:00-23:00","tuesday":"06:00-23:00","wednesday":"06:00-23:00","thursday":"06:00-23:00","friday":"06:00-23:00","saturday":"07:00-22:00","sunday":"08:00-21:00"}',
  true, true,
  40.990, 29.111, 'İstanbul', 'Ataşehir', 'atmosfer', 'merhaba@fitlifestudio.com', 4.8, 156,
  'Üyelik Kampanyası', 'Yıllık üyelik alanlara 2 ay hediye. Kişisel antrenör seansı dahil.',
  'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80',
  '299 TL/ay''dan başlayan üyelik'),
-- ── 11. SAĞLIK & YAŞAM ─────────────────────────────────────────────────────
(
  'kiralik-saglik', 'Wellness Klinik', 'Sağlık & Yaşam',
  'Diyetisyen, fizyoterapi ve psikolojik danışmanlık. Bütünsel sağlık yaklaşımıyla size özel çözümler.',
  'Wellness Klinik, 2018''den beri Suadiye''de bütünsel sağlık hizmeti sunmaktadır. Uzman diyetisyen, fizyoterapist ve klinik psikolog kadrosuyla entegre tedavi yaklaşımları.',
  '905501234582', '@wellness.klinik', 'Suadiye Mah. Bağdat Cad. No:215, Kadıköy, İstanbul',
  'Sağlık & Yaşam', 'açık',
  'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=1600&q=80',
  'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=200&q=80',
  '{"monday":"08:00-20:00","tuesday":"08:00-20:00","wednesday":"08:00-20:00","thursday":"08:00-20:00","friday":"08:00-19:00","saturday":"09:00-14:00","sunday":""}',
  true, true,
  40.969, 29.068, 'İstanbul', 'Kadıköy', 'atmosfer', 'merhaba@wellnessklinik.com', 4.9, 198,
  'Ücretsiz İlk Danışmanlık', 'İlk diyetisyen veya psikolog görüşmesi ücretsiz. Randevu için WhatsApp.',
  'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=800&q=80',
  '200 TL''den başlayan seanslar'),
-- ── 12. OTO & ARAÇ HİZMETLERİ ──────────────────────────────────────────────
(
  'kiralik-oto', 'OtoKülah', 'Oto & Araç Hizmetleri',
  'Detaylı oto yıkama, periyodik bakım ve ekspertiz hizmetleri. Aracınız bizim için değerli.',
  'OtoKülah, 2017''den beri Beyoğlu''nda oto bakım ve yıkama hizmeti sunmaktadır. Profesyonel ekip, eco-friendly ürünler ve müşteri memnuniyeti odaklı hizmet anlayışı.',
  '905511234583', '@otokulah', 'Kurtuluş Mah. Dolapdere Cad. No:88, Beyoğlu, İstanbul',
  'Oto & Araç Hizmetleri', 'açık',
  'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?w=1600&q=80',
  'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=200&q=80',
  '{"monday":"08:00-19:00","tuesday":"08:00-19:00","wednesday":"08:00-19:00","thursday":"08:00-19:00","friday":"08:00-19:00","saturday":"09:00-18:00","sunday":"10:00-16:00"}',
  true, true,
  41.049, 28.977, 'İstanbul', 'Beyoğlu', 'atmosfer', 'merhaba@otokulah.com', 4.7, 145,
  'Yaz Bakım Kampanyası', 'Detaylı iç-dış yıkama ve pasta cila hizmetinde %25 indirim. Aynı gün teslimat.',
  'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=800&q=80',
  '199 TL''den başlayan yıkama')
ON CONFLICT (slug) DO NOTHING;

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ 2. STORE ID'LERİNİ AL (yeni eklenenler)                                 ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

SELECT id INTO v_giyim_id      FROM public.stores WHERE slug = 'kiralik-giyim';
SELECT id INTO v_kozmetik_id   FROM public.stores WHERE slug = 'kiralik-kozmetik';
SELECT id INTO v_dekorasyon_id FROM public.stores WHERE slug = 'kiralik-dekorasyon';
SELECT id INTO v_elektronik_id FROM public.stores WHERE slug = 'kiralik-elektronik';
SELECT id INTO v_kirtasiye_id  FROM public.stores WHERE slug = 'kiralik-kirtasiye';
SELECT id INTO v_pet_id        FROM public.stores WHERE slug = 'kiralik-petshop';
SELECT id INTO v_hizmet_id     FROM public.stores WHERE slug = 'kiralik-danismanlik';
SELECT id INTO v_egitim_id     FROM public.stores WHERE slug = 'kiralik-egitim';
SELECT id INTO v_evtemizlik_id FROM public.stores WHERE slug = 'kiralik-temizlik';
SELECT id INTO v_spor_id       FROM public.stores WHERE slug = 'kiralik-spor';
SELECT id INTO v_saglik_id     FROM public.stores WHERE slug = 'kiralik-saglik';
SELECT id INTO v_oto_id        FROM public.stores WHERE slug = 'kiralik-oto';

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ 3. ÜRÜN KATEGORİLERİ                                                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

INSERT INTO public.product_categories (store_id, name, slug, sort_order) VALUES
  -- Giyim
  (v_giyim_id, 'Yeni Sezon', 'yeni-sezon', 1),
  (v_giyim_id, 'Dış Giyim', 'dis-giyim', 2),
  (v_giyim_id, 'Aksesuar', 'aksesuar', 3),
  -- Kozmetik
  (v_kozmetik_id, 'Cilt Bakımı', 'cilt-bakimi', 1),
  (v_kozmetik_id, 'Makyaj Ürünleri', 'makyaj-urunleri', 2),
  (v_kozmetik_id, 'Parfüm', 'parfum', 3),
  -- Dekorasyon
  (v_dekorasyon_id, 'Canlı Bitki', 'canli-bitki', 1),
  (v_dekorasyon_id, 'Çiçek Aranjmanı', 'cicek-aranjmani', 2),
  (v_dekorasyon_id, 'Seramik Objeler', 'seramik-objeler', 3),
  -- Elektronik
  (v_elektronik_id, 'Telefon Aksesuar', 'telefon-aksesuar', 1),
  (v_elektronik_id, 'Kulaklık', 'kulaklik', 2),
  (v_elektronik_id, 'Giyilebilir Teknoloji', 'giyilebilir', 3),
  -- Kırtasiye
  (v_kirtasiye_id, 'Okul Gereçleri', 'okul-gerecleri', 1),
  (v_kirtasiye_id, 'Sanat Malzemeleri', 'sanat-malzemeleri', 2),
  (v_kirtasiye_id, 'Defter & Ajanda', 'defter-ajanda', 3),
  -- Pet Shop
  (v_pet_id, 'Mama & Gıda', 'mama-gida', 1),
  (v_pet_id, 'Aksesuar', 'aksesuar', 2),
  (v_pet_id, 'Bakım Ürünleri', 'bakim-urunleri', 3),
  -- Danışmanlık
  (v_hizmet_id, 'Mali Müşavirlik', 'mali-musavirlik', 1),
  (v_hizmet_id, 'Hukuki Danışmanlık', 'hukuki-danismanlik', 2),
  (v_hizmet_id, 'Kariyer Koçluğu', 'kariyer-koclugu', 3),
  -- Eğitim
  (v_egitim_id, 'Özel Ders', 'ozel-ders', 1),
  (v_egitim_id, 'Sınav Hazırlık', 'sinav-hazirlik', 2),
  (v_egitim_id, 'Online Eğitim', 'online-egitim', 3),
  -- Ev Temizlik
  (v_evtemizlik_id, 'Ev Temizliği', 'ev-temizligi', 1),
  (v_evtemizlik_id, 'Koltuk Yıkama', 'koltuk-yikama', 2),
  (v_evtemizlik_id, 'Dezenfeksiyon', 'dezenfeksiyon', 3),
  -- Spor
  (v_spor_id, 'PT Seansları', 'pt-seanslari', 1),
  (v_spor_id, 'Grup Dersleri', 'grup-dersleri', 2),
  (v_spor_id, 'Beslenme Programı', 'beslenme-programi', 3),
  -- Sağlık
  (v_saglik_id, 'Diyetisyen', 'diyetisyen', 1),
  (v_saglik_id, 'Fizyoterapi', 'fizyoterapi', 2),
  (v_saglik_id, 'Psikoloji', 'psikoloji', 3),
  -- Oto
  (v_oto_id, 'Oto Yıkama', 'oto-yikama', 1),
  (v_oto_id, 'Periyodik Bakim', 'periyodik-bakim', 2),
  (v_oto_id, 'Ekspertiz', 'ekspertiz', 3)
ON CONFLICT (store_id, slug) DO NOTHING;

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ 4. ÜRÜNLER (her vitrin için 6 örnek ürün)                               ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

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
  -- ── GİYİM ürünleri ────────────────────────────────────────────────────
  ('kiralik-giyim', 'Yeni Sezon', 'Slim Fit Kot Pantolon', 'slim-fit-kot', 'Esnek kumaş, modern kesim, 3 renk seçeneği.', 399, 499, '399 TL', 'TRY', '-20%', '["https://images.unsplash.com/photo-1542272604-787c3835535d?w=600&q=80"]'::jsonb, 1),
  ('kiralik-giyim', 'Yeni Sezon', 'Oversize Tişört', 'oversize-tisort', '%100 pamuk, rahat kesim, 5 renk.', 149, NULL, '149 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&q=80"]'::jsonb, 2),
  ('kiralik-giyim', 'Dış Giyim', 'Deri Ceket', 'deri-ceket', 'Suni deri, astarlı, slim fit kesim.', 899, 1199, '899 TL', 'TRY', '-25%', '["https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80"]'::jsonb, 3),
  ('kiralik-giyim', 'Dış Giyim', 'Kapşonlu Sweatshirt', 'kapsonlu-sweat', 'Kalın pamuklu, içi polarlı, oversize.', 349, NULL, '349 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&q=80"]'::jsonb, 4),
  ('kiralik-giyim', 'Aksesuar', 'Deri Kemer', 'deri-kemer', 'El yapımı, \"%100 dana derisi, 3 beden.', 249, NULL, '249 TL', 'TRY', 'Özel', '["https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&q=80"]'::jsonb, 5),
  ('kiralik-giyim', 'Aksesuar', ' Şapka & Berе', 'sapka-bere', 'Pamuklu, unisex, 4 renk seçeneği.', 99, NULL, '99 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1576871337632-b9aef4c17ab9?w=600&q=80"]'::jsonb, 6),

  -- ── KOZMETİK ürünleri ─────────────────────────────────────────────────
  ('kiralik-kozmetik', 'Cilt Bakımı', 'Nemlendirici Yüz Kremi', 'nemlendirici-krem', 'Hyaluronik asitli, 50ml, tüm cilt tipleri için.', 189, NULL, '189 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?w=600&q=80"]'::jsonb, 1),
  ('kiralik-kozmetik', 'Cilt Bakımı', 'Vitamin C Serum', 'vitamin-c-serum', '%15 C vitamini, 30ml, aydınlatıcı etki.', 249, 299, '249 TL', 'TRY', '-17%', '["https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=600&q=80"]'::jsonb, 2),
  ('kiralik-kozmetik', 'Makyaj Ürünleri', 'Mat Ruj Seti', 'mat-ruj-seti', '6 renk, uzun süreli mat formül.', 299, NULL, '299 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=600&q=80"]'::jsonb, 3),
  ('kiralik-kozmetik', 'Makyaj Ürünleri', 'Maskara Volume', 'maskara-volume', 'Hacim veren, topaklanma yapmayan formül.', 129, NULL, '129 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&q=80"]'::jsonb, 4),
  ('kiralik-kozmetik', 'Parfüm', 'Doğal Parfüm Yağı', 'doga-parfum', '10ml roller, 8 saat kalıcılık, bitkisel.', 159, NULL, '159 TL', 'TRY', 'Özel', '["https://images.unsplash.com/photo-1541643600914-78b084683601?w=600&q=80"]'::jsonb, 5),
  ('kiralik-kozmetik', 'Parfüm', 'Çiçek Kokulu Set', 'cicek-kokulu-set', '3''lü parfüm seti, 15ml boyutunda.', 399, 499, '399 TL', 'TRY', '-20%', '["https://images.unsplash.com/photo-1594035910387-fc65c4e0d532?w=600&q=80"]'::jsonb, 6),

  -- ── DEKORASYON ürünleri ───────────────────────────────────────────────
  ('kiralik-dekorasyon', 'Canlı Bitki', 'Monstera Deliciosa', 'monstera', '75cm, saksı dahil, bakım kılavuzu included.', 299, NULL, '299 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=600&q=80"]'::jsonb, 1),
  ('kiralik-dekorasyon', 'Canlı Bitki', 'Saksı Çiçeği Seti (3''lü)', 'saksi-cicek-seti', 'Farklı boyutlarda 3 saksı çiçeği.', 449, NULL, '449 TL', 'TRY', 'Özel', '["https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=600&q=80"]'::jsonb, 2),
  ('kiralik-dekorasyon', 'Çiçek Aranjmanı', 'Gelin Buketi', 'gelin-buketi', 'Taze çiçeklerle özel tasarım gelin buketi.', 599, NULL, '599 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1487530811176-3780de880c2d?w=600&q=80"]'::jsonb, 3),
  ('kiralik-dekorasyon', 'Çiçek Aranjmanı', 'Masa Çiçeği', 'masa-cicegi', 'Cam vazo ile birlikte, 20 dal karışık.', 179, NULL, '179 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1490750967868-88aa4f44baee?w=600&q=80"]'::jsonb, 4),
  ('kiralik-dekorasyon', 'Seramik Objeler', 'El Yapımı Saksı', 'el-yapimi-saksi', 'Seramik, el boyaması, 15cm çap.', 149, NULL, '149 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=600&q=80"]'::jsonb, 5),
  ('kiralik-dekorasyon', 'Seramik Objeler', 'Seramik Vazo', 'seramik-vazo', 'Modern tasarım, el yapımı, 25cm.', 229, NULL, '229 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?w=600&q=80"]'::jsonb, 6),

  -- ── ELEKTRONİK ürünleri ───────────────────────────────────────────────
  ('kiralik-elektronik', 'Telefon Aksesuar', 'Magsafe Kılıf', 'magsafe-kilif', 'Manyetik şarj uyumlu, silikon koruma.', 199, NULL, '199 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=600&q=80"]'::jsonb, 1),
  ('kiralik-elektronik', 'Telefon Aksesuar', 'Hızlı Şarj Adaptörü', 'hizli-sarj', '65W GaN, USB-C, tüm cihazlarla uyumlu.', 349, 399, '349 TL', 'TRY', '-13%', '["https://images.unsplash.com/photo-1583394838336-acd977736f90?w=600&q=80"]'::jsonb, 2),
  ('kiralik-elektronik', 'Kulaklık', 'ANC Bluetooth Kulaklık', 'anc-kulaklik', 'Aktif gürültü engelleme, 30 saat pil.', 599, 799, '599 TL', 'TRY', '-25%', '["https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&q=80"]'::jsonb, 3),
  ('kiralik-elektronik', 'Kulaklık', 'Kablosuz Spor Kulaklık', 'spor-kulaklik', 'Ter ve su geçirmez, kulak çengelli.', 299, NULL, '299 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1590658268037-6bf12f032f55?w=600&q=80"]'::jsonb, 4),
  ('kiralik-elektronik', 'Giyilebilir Teknoloji', 'Akıllı Bileklik', 'akilli-bileklik', 'Adım sayar, kalp ritmi, uyku takibi.', 449, 549, '449 TL', 'TRY', '-18%', '["https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=600&q=80"]'::jsonb, 5),
  ('kiralik-elektronik', 'Giyilebilir Teknoloji', 'Powerbank 20000mAh', 'powerbank', 'Hızlı şarj, 2 çıkış, LED gösterge.', 249, NULL, '249 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=600&q=80"]'::jsonb, 6),

  -- ── KIRTASİYE ürünleri ────────────────────────────────────────────────
  ('kiralik-kirtasiye', 'Okul Gereçleri', 'Renkli Kalem Seti (24''lü)', 'renkli-kalem-seti', 'Canlı renkler, kurumayan formül.', 89, NULL, '89 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=600&q=80"]'::jsonb, 1),
  ('kiralik-kirtasiye', 'Okul Gereçleri', 'Peluş Kalemtıraş', 'pelus-kalemtiras', 'Yumuşak peluş, kompakt tasarım.', 49, NULL, '49 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1456735190827-d1262f71b8a3?w=600&q=80"]'::jsonb, 2),
  ('kiralik-kirtasiye', 'Sanat Malzemeleri', 'Akrilik Boya Seti (12 Renk)', 'akrilik-boya-seti', 'Profesyonel kalite, 12x12ml tüp.', 199, 249, '199 TL', 'TRY', '-20%', '["https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&q=80"]'::jsonb, 3),
  ('kiralik-kirtasiye', 'Sanat Malzemeleri', 'Tuval Seti (3''lü)', 'tuval-seti', '3 farklı boyut, pamuklu tuval, ahşap iskelet.', 149, NULL, '149 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&q=80"]'::jsonb, 4),
  ('kiralik-kirtasiye', 'Defter & Ajanda', 'Haftalık Planner', 'haftalik-planner', 'A5 boyut, 52 hafta, yapışkan notlu.', 129, NULL, '129 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=600&q=80"]'::jsonb, 5),
  ('kiralik-kirtasiye', 'Defter & Ajanda', 'Çizgili Defter Seti (3''lü)', 'cizgili-defter-seti', 'A5, 80 yaprak, yumuşak kapak.', 79, NULL, '79 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1544816155-12df9643f363?w=600&q=80"]'::jsonb, 6),

  -- ── PET SHOP ürünleri ─────────────────────────────────────────────────
  ('kiralik-petshop', 'Mama & Gıda', 'Kuru Köpek Maması (3kg)', 'kopek-mamasi', 'Yüksek protein, doğal içerik, 3kg paket.', 349, NULL, '349 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=600&q=80"]'::jsonb, 1),
  ('kiralik-petshop', 'Mama & Gıda', 'Kedi Maması Premium (2kg)', 'kedi-mamasi', 'Somon balıklı, tahılsız, 2kg.', 299, 349, '299 TL', 'TRY', '-14%', '["https://images.unsplash.com/photo-1574158622682-e40e69881006?w=600&q=80"]'::jsonb, 2),
  ('kiralik-petshop', 'Aksesuar', 'Köpek Tasması & Kayış Seti', 'tasma-kayis-seti', 'Deri, ayarlanabilir, 3 beden seçeneği.', 199, NULL, '199 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=600&q=80"]'::jsonb, 3),
  ('kiralik-petshop', 'Aksesuar', 'Kedi Oyuncağı Seti (5''li)', 'kedi-oyuncagi-seti', 'Tüylü, ringsiz, farklı türlerde 5 oyuncak.', 129, NULL, '129 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1574158622682-e40e69881006?w=600&q=80"]'::jsonb, 4),
  ('kiralik-petshop', 'Bakım Ürünleri', 'Evcil Hayvan Şampuanı', 'sampuan', 'Doğal içerikli, hassas ciltler için.', 89, NULL, '89 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1516750105099-4b8b915c4024?w=600&q=80"]'::jsonb, 5),
  ('kiralik-petshop', 'Bakım Ürünleri', 'Tarak & Fırça Seti', 'tarak-firca-seti', 'Kısa ve uzun tüylü hayvanlar için.', 69, NULL, '69 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1516750105099-4b8b915c4024?w=600&q=80"]'::jsonb, 6),

  -- ── DANIŞMANLIK ürünleri ─────────────────────────────────────────────
  ('kiralik-danismanlik', 'Mali Müşavirlik', 'Vergi Danışmanlığı', 'vergi-danismanligi', 'Aylık vergi süreç yönetimi ve raporlama.', 500, NULL, '500 TL/ay', 'TRY', NULL, '["https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600&q=80"]'::jsonb, 1),
  ('kiralik-danismanlik', 'Mali Müşavirlik', 'Bilanço Hazırlama', 'bilanco', 'Yıllık bilanço ve gelir tablosu hazırlama.', 2000, NULL, '2.000 TL', 'TRY', 'Özel', '["https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=600&q=80"]'::jsonb, 2),
  ('kiralik-danismanlik', 'Hukuki Danışmanlık', 'Sözleşme İncelemesi', 'sozlesme-inceleme', 'Ticari sözleşme hukuki analiz ve rapor.', 750, NULL, '750 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600&q=80"]'::jsonb, 3),
  ('kiralik-danismanlik', 'Hukuki Danışmanlık', 'İş Hukuku Danışmanlığı', 'is-hukuku', 'Personel sözleşmesi, iş kanunu danışmanlığı.', 1000, NULL, '1.000 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=600&q=80"]'::jsonb, 4),
  ('kiralik-danismanlik', 'Kariyer Koçluğu', 'CV & LinkedIn Optimizasyonu', 'cv-linkedin', 'Profesyonel CV yazımı ve LinkedIn profili.', 300, NULL, '300 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80"]'::jsonb, 5),
  ('kiralik-danismanlik', 'Kariyer Koçluğu', 'Mülakat Simülasyonu', 'mulakat-simulasyonu', 'Birebir mülakat provası ve geri bildirim.', 400, NULL, '400 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=600&q=80"]'::jsonb, 6),

  -- ── EĞİTİM ürünleri ──────────────────────────────────────────────────
  ('kiralik-egitim', 'Özel Ders', 'Matematik Dersi (1 Saat)', 'matematik-dersi', 'Lise ve üniversite düzeyi, birebir.', 200, NULL, '200 TL/saat', 'TRY', NULL, '["https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=600&q=80"]'::jsonb, 1),
  ('kiralik-egitim', 'Özel Ders', 'İngilizce Konuşma Pratiği', 'ingilizce-pratik', 'Native speaker ile birebir konuşma seansı.', 250, NULL, '250 TL/saat', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=600&q=80"]'::jsonb, 2),
  ('kiralik-egitim', 'Sınav Hazırlık', 'LGS Hazırlık Paketi', 'lgs-hazirlik', '12 haftalık yoğun LGS hazırlık programı.', 3000, 3500, '3.000 TL', 'TRY', '-14%', '["https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=600&q=80"]'::jsonb, 3),
  ('kiralik-egitim', 'Sınav Hazırlık', 'KPSS Grup Dersi', 'kpss-grup', '8 kişilik grup, haftada 2 gün, 3 ay.', 2500, NULL, '2.500 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&q=80"]'::jsonb, 4),
  ('kiralik-egitim', 'Online Eğitim', 'Python Programlama Kursu', 'python-kursu', '40 saat online video + canlı ders.', 1500, NULL, '1.500 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1526379095098-d400fd0bf935?w=600&q=80"]'::jsonb, 5),
  ('kiralik-egitim', 'Online Eğitim', 'Grafik Tasarım Atölyesi', 'grafik-tasarim', 'Photoshop + Illustrator, 20 saat online.', 800, NULL, '800 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1561070791-2526d30994b5?w=600&q=80"]'::jsonb, 6),

  -- ── EV TEMİZLİK ürünleri ─────────────────────────────────────────────
  ('kiralik-temizlik', 'Ev Temizliği', '3+1 Daire Temizliği', '3plus1-temizlik', 'Dip köşe temizlik, 4-5 saat, eco ürünler.', 350, NULL, '350 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&q=80"]'::jsonb, 1),
  ('kiralik-temizlik', 'Ev Temizliği', 'Villa / Geniş Alan Temizliği', 'villa-temizlik', '2 katlı villa, 6-8 saat, 2 kişilik ekip.', 700, NULL, '700 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1563453392212-326f5e854473?w=600&q=80"]'::jsonb, 2),
  ('kiralik-temizlik', 'Koltuk Yıkama', '3lü Koltuk Yıkama', 'koltuk-yikama', 'Kuru köpük methodu, leke giderici dahil.', 250, 300, '250 TL', 'TRY', '-17%', '["https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=600&q=80"]'::jsonb, 3),
  ('kiralik-temizlik', 'Koltuk Yıkama', 'Halı Yıkama (m2)', 'hali-yikama', 'Endüstriyel makine, derin temizlik.', 45, NULL, '45 TL/m²', 'TRY', NULL, '["https://images.unsplash.com/photo-1558317374-067fb5f30001?w=600&q=80"]'::jsonb, 4),
  ('kiralik-temizlik', 'Dezenfeksiyon', 'İşyeri Dezenfeksiyonu', 'isyeri-dezenfeksiyon', 'ULV yöntemi, virüs/bakteri öldürücü.', 500, NULL, '500 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=600&q=80"]'::jsonb, 5),
  ('kiralik-temizlik', 'Dezenfeksiyon', 'Ev Dezenfeksiyonu', 'ev-dezenfeksiyon', '100m²''ye kadar, 2 saat, eco-friendly.', 300, NULL, '300 TL', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1585421514738-01798e348b17?w=600&q=80"]'::jsonb, 6),

  -- ── SPOR ürünleri ────────────────────────────────────────────────────
  ('kiralik-spor', 'PT Seansları', 'Birebir PT (1 Saat)', 'birebir-pt', 'Kişisel antrenör, salon üyeliği dahil.', 350, NULL, '350 TL/saat', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80"]'::jsonb, 1),
  ('kiralik-spor', 'PT Seansları', '4 Seans PT Paketi', '4-seans-pt', '4 birebir seans, beslenme danışmanlığı dahil.', 1200, 1400, '1.200 TL', 'TRY', '-14%', '["https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&q=80"]'::jsonb, 2),
  ('kiralik-spor', 'Grup Dersleri', 'Pilates Grup Dersi', 'pilates-grup', '8 kişilik grup, haftada 3 gün.', 600, NULL, '600 TL/ay', 'TRY', NULL, '["https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&q=80"]'::jsonb, 3),
  ('kiralik-spor', 'Grup Dersleri', 'CrossFit Grup Dersi', 'crossfit-grup', '12 kişilik grup, yüksek yoğunluklu.', 700, NULL, '700 TL/ay', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1534258936925-c58bed479fcb?w=600&q=80"]'::jsonb, 4),
  ('kiralik-spor', 'Beslenme Programı', 'Kişiye Özel Beslenme Listesi', 'beslenme-listesi', 'Diyetisyen eşliğinde kişiye özel plan.', 500, NULL, '500 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&q=80"]'::jsonb, 5),
  ('kiralik-spor', 'Beslenme Programı', '12 Haftalık Dönüşüm Programı', 'donusum-programi', 'Beslenme + antrenman + haftalık takip.', 3000, 3500, '3.000 TL', 'TRY', 'Özel', '["https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&q=80"]'::jsonb, 6),

  -- ── SAĞLIK ürünleri ──────────────────────────────────────────────────
  ('kiralik-saglik', 'Diyetisyen', 'İlk Görüşme & Analiz', 'ilk-gorusme', 'Kapsamlı vücut analizi ve beslenme değerlendirmesi.', 250, NULL, '250 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&q=80"]'::jsonb, 1),
  ('kiralik-saglik', 'Diyetisyen', 'Aylık Takip Paketi', 'aylik-takip', '4 seans + haftalık menü planı + online destek.', 800, NULL, '800 TL/ay', 'TRY', NULL, '["https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&q=80"]'::jsonb, 2),
  ('kiralik-saglik', 'Fizyoterapi', 'Bel Ağrısı Rehabilitasyonu', 'bel-rehab', '6 seans, birebir fizyoterapi.', 1200, 1500, '1.200 TL', 'TRY', '-20%', '["https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80"]'::jsonb, 3),
  ('kiralik-saglik', 'Fizyoterapi', 'Spor Yaralanması Rehabilitasyonu', 'spor-rehab', 'Özel egzersiz programı, 8 seans.', 1800, NULL, '1.800 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=600&q=80"]'::jsonb, 4),
  ('kiralik-saglik', 'Psikoloji', 'Bireysel Terapi Seansı', 'bireysel-terapi', '50 dakika, online veya yüz yüze.', 400, NULL, '400 TL/seans', 'TRY', NULL, '["https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=600&q=80"]'::jsonb, 5),
  ('kiralik-saglik', 'Psikoloji', 'Çift Terapisi', 'cift-terapisi', '90 dakika, çiftlerle iletişim danışmanlığı.', 600, NULL, '600 TL/seans', 'TRY', 'Yeni', '["https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=600&q=80"]'::jsonb, 6),

  -- ── OTO ürünleri ─────────────────────────────────────────────────────
  ('kiralik-oto', 'Oto Yıkama', 'Dış Yıkama Paketi', 'dis-yikama', 'Dış yıkama, jant temizliği, parlatma.', 150, NULL, '150 TL', 'TRY', 'Popüler', '["https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=600&q=80"]'::jsonb, 1),
  ('kiralik-oto', 'Oto Yıkama', 'İç-Dış Detaylı Yıkama', 'ic-dis-yikama', 'Detaylı iç temizlik + dış yıkama + motor yıkama.', 350, 450, '350 TL', 'TRY', '-22%', '["https://images.unsplash.com/photo-1507136566006-cfc505b114fc?w=600&q=80"]'::jsonb, 2),
  ('kiralik-oto', 'Periyodik Bakim', 'Motor Yağı Değişimi', 'motor-yagi', 'Filtre dahil, tüm marka ve modeller.', 500, NULL, '500 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=600&q=80"]'::jsonb, 3),
  ('kiralik-oto', 'Periyodik Bakim', 'Balata Değişimi', 'balata-degisimi', 'Ön ve arka balata, orijinal parça.', 800, NULL, '800 TL', 'TRY', NULL, '["https://images.unsplash.com/photo-1487754180451-c456f719a1fc?w=600&q=80"]'::jsonb, 4),
  ('kiralik-oto', 'Ekspertiz', 'İkinci El Ekspertiz', 'ikinci-el-ekspertiz', 'Detaylı ekspertiz raporu, 200+ kontrol noktası.', 1500, NULL, '1.500 TL', 'TRY', 'Özel', '["https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=600&q=80"]'::jsonb, 5),
  ('kiralik-oto', 'Ekspertiz', 'Pasta Cila', 'pasta-cila', '3 kat cila, 16 saat kuruma, 6 ay koruma.', 800, 1000, '800 TL', 'TRY', '-20%', '["https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&q=80"]'::jsonb, 6)
) AS p(store_slug, category_name, name, slug, description, price_amount, old_price_amount, price_text, currency, badge_tag, image_urls, sort_order)
JOIN public.stores s ON s.slug = p.store_slug
JOIN public.product_categories pc ON pc.store_id = s.id AND pc.name = p.category_name
ON CONFLICT DO NOTHING;

END $$;

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ 5. HER VİTRİN İÇİN TEKNOFİX KALİTESİNDE VİTRİN İÇERİĞİ               ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- Teknofix kalite standardı: about, gallery, faq, blog, sections
-- Her demo vitrin için aynı yapıyı oluşturuyoruz.
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN SELECT id, slug, name FROM public.stores WHERE is_demo = true LOOP

    -- HAKKIMIZDA
    UPDATE public.stores
    SET about_kicker = CASE
      WHEN slug LIKE '%giyim%' THEN 'Moda Tutkumuz'
      WHEN slug LIKE '%kozmetik%' THEN 'Güzellik Felsefemiz'
      WHEN slug LIKE '%dekorasyon%' THEN 'Doğanın Sesi'
      WHEN slug LIKE '%elektronik%' THEN 'Teknoloji Güvencemiz'
      WHEN slug LIKE '%kirtasiye%' THEN 'Hayal Gücümüz'
      WHEN slug LIKE '%pet%' THEN 'Patili Dostlarımız'
      WHEN slug LIKE '%danismanlik%' THEN 'Uzman Kadromuz'
      WHEN slug LIKE '%egitim%' THEN 'Eğitim Anlayışımız'
      WHEN slug LIKE '%temizlik%' THEN 'Temizlik Standartlarımız'
      WHEN slug LIKE '%spor%' THEN 'Spor Felsefemiz'
      WHEN slug LIKE '%saglik%' THEN 'Sağlık Yaklaşımımız'
      WHEN slug LIKE '%oto%' THEN 'Otomotiv Deneyimimiz'
      WHEN slug LIKE '%butik%' THEN 'Butik Anlayışımız'
      WHEN slug LIKE '%kafe%' THEN 'Kahve Tutkumuz'
      WHEN slug LIKE '%kuafor%' THEN 'Stil Ustalığımız'
      WHEN slug LIKE '%teknik%' THEN 'Teknik Uzmanlığımız'
      WHEN slug LIKE '%gida%' THEN 'Doğal Lezzetlerimiz'
      ELSE 'Hikayemiz'
    END,
    about_title = CASE
      WHEN slug LIKE '%giyim%' THEN 'Zamansız Moda, Bilinçli Tüketim'
      WHEN slug LIKE '%kozmetik%' THEN 'Doğal Güzellik, Bilimsel Bakım'
      WHEN slug LIKE '%dekorasyon%' THEN 'Yaşam Alanlarınıza Doğallık Katıyoruz'
      WHEN slug LIKE '%elektronik%' THEN 'Teknolojiyi Güvenle Kullanın'
      WHEN slug LIKE '%kirtasiye%' THEN 'Yaratıcılığınızı Keşfedin'
      WHEN slug LIKE '%pet%' THEN 'Minik Dostlar Büyük Sevgi'
      WHEN slug LIKE '%danismanlik%' THEN 'İşletmenizin Güvencesi'
      WHEN slug LIKE '%egitim%' THEN 'Başarıya Giden Yol'
      WHEN slug LIKE '%temizlik%' THEN 'Pırıl Pırıl Mekanlar'
      WHEN slug LIKE '%spor%' THEN 'Sağlıklı Yaşam, Güçlü Beden'
      WHEN slug LIKE '%saglik%' THEN 'Bütünsel Sağlık Anlayışı'
      WHEN slug LIKE '%oto%' THEN 'Aracınız Değerli, Biz Biliyoruz'
      WHEN slug LIKE '%butik%' THEN 'Özel Tasarımlar, Sınırlı Üretim'
      WHEN slug LIKE '%kafe%' THEN 'Özenle Demlenen Her Yudum'
      WHEN slug LIKE '%kuafor%' THEN 'Stilinizi Yeniden Tanımlıyoruz'
      WHEN slug LIKE '%teknik%' THEN 'Güvenilir Onarım, Hızlı Teslimat'
      WHEN slug LIKE '%gida%' THEN 'Çiftçiden Sofranıza'
      ELSE 'Hikayemizi Keşfedin'
    END,
    about_image_url = shelf_image_url,
    about_values = CASE
      WHEN slug LIKE '%giyim%' THEN '[{"icon":"eco","title":"Sürdürülebilir Üretim","text":"Doğal kumaşlar ve çevre dostu boyalar kullanıyoruz."},{"icon":"star","title":"Kalite Garantisi","text":"Her parça titizlikle kontrol edilir."},{"icon":"favorite","title":"Müşteri Memnuniyeti","text":"%98 memnuniyet oranı ile çalışıyoruz."}]'::jsonb
      WHEN slug LIKE '%kozmetik%' THEN '[{"icon":"eco","title":"Vegan & Cruelty-Free","text":"Hiçbir ürünümüzde hayvan testi yoktur."},{"icon":"spa","title":"Doğal İçerikler","text":"Bitkisel kaynaklı, saf formüller."},{"icon":"verified","title":"Dermatolog Onaylı","text":"Uzmanlar tarafından test edilmiştir."}]'::jsonb
      WHEN slug LIKE '%dekorasyon%' THEN '[{"icon":"eco","title":"Sürdürülebilir Tasarım","text":"Doğal malzemeler ve yerel üretim."},{"icon":"favorite","title":"El Yapımı Ürünler","text":"Her parça benzersiz ve özenle yapılmış."},{"icon":"local_florist","title":"Taze Çiçek Garantisi","text":"7 gün taze kalma garantisi."}]'::jsonb
      WHEN slug LIKE '%elektronik%' THEN '[{"icon":"verified","title":"Orjinal Ürün Garantisi","text":"Tüm ürünler orjinal ve sertifikalı."},{"icon":"build","title":"Teknik Destek","text":"Satış sonrası kesintisiz destek."},{"icon":"local_shipping","title":"Hızlı Teslimat","text":"Aynı gün kargo, ertesi gün teslimat."}]'::jsonb
      WHEN slug LIKE '%kirtasiye%' THEN '[{"icon":"palette","title":"Profesyonel Kalite","text":"Sanatçılar için profesyonel malzemeler."},{"icon":"school","title":"Eğitim Desteği","text":"Atölye çalışmaları ve ücretsiz danışmanlık."},{"icon":"eco","title":"Çevre Dostu","text":"Geri dönüştürülebilir ambalajlar."}]'::jsonb
      WHEN slug LIKE '%pet%' THEN '[{"icon":"favorite","title":"Hayvan Sever Kadro","text":"Tüm ekibimiz hayvansever ve eğitimli."},{"icon":"verified","title":"Sertifikalı Ürünler","text":"Güvenilir markalar, orjinal ürünler."},{"icon":"local_hospital","title":"Veteriner Desteği","text":"7/24 veteriner danışma hattı."}]'::jsonb
      WHEN slug LIKE '%danismanlik%' THEN '[{"icon":"verified","title":"Sertifikalı Uzmanlar","text":"Alanında uzman, deneyimli kadro."},{"icon":"security","title":"Gizlilik Garantisi","text":"Müşteri bilgileri kesinlikle gizli tutulur."},{"icon":"trending_up","title":"Sonuç Odaklı","text":"Ölçülebilir sonuçlar ve raporlama."}]'::jsonb
      WHEN slug LIKE '%egitim%' THEN '[{"icon":"school","title":"Deneyimli Öğretmenler","text":"Alanında uzman, sertifikalı eğitimciler."},{"icon":"groups","title":"Küçük Gruplar","text":"Maksimum 8 kişilik sınıflar."},{"icon":"trending_up","title":"Başarı Garantisi","text":"%90''ın üzerinde öğrencimiz hedefine ulaştı."}]'::jsonb
      WHEN slug LIKE '%temizlik%' THEN '[{"icon":"eco","title":"Eco-Friendly Ürünler","text":"Çevre dostu, sertifikalı temizlik ürünleri."},{"icon":"verified","title":"Eğitimli Personel","text":"Güvenilir, sigortalı ve eğitimli ekip."},{"icon":"thumb_up","title":"Memnuniyet Garantisi","text":"Hizmetten memnun kalmazsanız ücretsiz tekrar."}]'::jsonb
      WHEN slug LIKE '%spor%' THEN '[{"icon":"verified","title":"Sertifikali Antrenörler","text":"NSCA ve ACE sertifikalı uzman kadro."},{"icon":"fitness_center","title":"Modern Ekipmanlar","text":"En son teknoloji spor aletleri."},{"icon":"favorite","title":"Kişisel Program","text":"Her bireye özel antrenman ve beslenme planı."}]'::jsonb
      WHEN slug LIKE '%saglik%' THEN '[{"icon":"verified","title":"Uzman Kadro","text":"Alanında uzman diyetisyen, fizyoterapist ve psikologlar."},{"icon":"security","title":"Gizlilik","text":"Sağlık bilgileriniz kesinlikle gizli tutulur."},{"icon":"trending_up", "title":"Kanıta Dayalı Yaklaşım","text":"Bilimsel verilere dayalı tedavi yöntemleri."}]'::jsonb
      WHEN slug LIKE '%oto%' THEN '[{"icon":"verified","title":"Otomobil Uzmanı","text":"10+ yıllık deneyim, tüm markalar."},{"icon":"build","title":"Orijinal Parça","text":"Garantili, orijinal yedek parça."},{"icon":"local_shipping","title":"Aynı Gün Teslimat","text":"Çoğu işlem aynı gün içinde tamamlanır."}]'::jsonb
      ELSE '[{"icon":"star","title":"Kalite","text":"En yüksek standartlarda hizmet."},{"icon":"favorite","title":"Müşteri Odaklı","text":"Memnuniyetiniz bizim önceliğimiz."},{"icon":"verified","title":"Güvenilir","text":"Alanında uzman, deneyimli kadro."}]'::jsonb
    END,
    -- GALERİ
    gallery_items = '[{"url":"' || COALESCE(shelf_image_url, 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80') || '","title":"Mağazamızdan Bir Kare"},{"url":"' || COALESCE(logo_url, 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800&q=80') || '","title":"İşletme Logomuz"},{"url":"https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800&q=80","title":"Çalışma Alanımız"},{"url":"https://images.unsplash.com/photo-1497215842964-222b430dc094?w=800&q=80","title":"İç Mekanımız"},{"url":"https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80","title":"Ekibimiz"}]'::jsonb,
    -- BLOG
    blog_posts = '[{"title":"İşletmemizi Tanıyın","summary":"' || COALESCE(description, 'Hikayemizi keşfedin.') || '","image_url":"' || COALESCE(shelf_image_url, 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80') || '"},{"title":"Bu Ayın Öne Çıkanları","summary":"En çok tercih edilen ürünlerimiz ve hizmetlerimiz bu ayda öne çıkıyor.","image_url":"https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&q=80"},{"title":"Müşterilerimizin Yorumları","summary":"Sizlerin deneyimleri bizim en büyük referansımızdır. Memnuniyet oranımız %98.","image_url":"https://images.unsplash.com/photo-1552664730-d307ca884978?w=800&q=80"}]'::jsonb,
    -- SSS
    faq_items = '[{"q":"Randevu nasıl alınır?","a":"WhatsApp butonuna tıklayarak veya telefon numaramızdan bize ulaşarak randevu alabilirsiniz."},{"q":"Ödeme seçenekleri nelerdir?","a":"Nakit, kredi kartı ve banka kartı ile ödeme kabul ediyoruz."},{"q":"İptal ve değişiklik politikanız nedir?","a":"Randevunuzu 24 saat öncesinden iptal edebilirsiniz."},{"q":"Çalışma saatleriniz nedir?","a":"Pazartesi-Cumartesi hizmetinizdeyiz. Detaylı saatler için vitrinimizi inceleyin."}]'::jsonb,
    -- Section başlıkları
    about_section_title = 'Hakkımızda',
    gallery_section_title = 'Galerimizden Kareler',
    blog_section_title = 'Blog & Duyurular',
    faq_section_title = 'Sıkça Sorulan Sorular'
    WHERE id = rec.id;

  END LOOP;
END $$;
