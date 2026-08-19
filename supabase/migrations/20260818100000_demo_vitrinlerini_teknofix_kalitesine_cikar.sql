-- ============================================================================
-- 4 mevcut kiralık demo vitrini → teknofix kalitesine çıkarma
-- ============================================================================
-- NEDEN VAR
-- demo-teknofix (20260809120000) ile Hakkımızda, SSS, Galeri, Blog gibi
-- bölümler eklendi — ama butik, kafe, kuafor, gida vitrinleri aynı
-- kalitede bırakıldı. Bu migration 4 vitrini aynı zenginliğe kavuşturur.
--
-- Kopyalanan alanlar: about_kicker, about_title, corporate_bio,
-- about_image_url, about_image_caption, about_values, faq_items,
-- gallery_items, gallery_section_kicker, gallery_section_title,
-- gallery_action_label, gallery_action_href, blog_section_kicker,
-- blog_section_title, faq_section_kicker, faq_section_title,
-- faq_section_description, category_section_title, product_section_title,
-- hero_badge, hero_location_text, map_label, phone, email,
-- featured_banner_label/title/description/image_url/price_text
--
-- Blog yazıları (store_articles) ayrı INSERT ile eklenir.
-- ============================================================================

alter table public.stores disable trigger protect_landing_demo_stores;

-- ════════════════════════════════════════════════════════════════════════════
-- 1. BUTİK — Atmosfer Butik (kiralik-butik)
-- ════════════════════════════════════════════════════════════════════════════
update public.stores set
  hero_badge = 'Özel Tasarım · Çekmeköy',
  hero_location_text = 'Çekmeköy, İstanbul',
  phone = '905321234567',
  email = 'merhaba@atmosfer-butik.com',
  map_label = 'Ömerli Cad. No:12, Çekmeköy — Toplu taşıma 3 dk',
  category_section_title = 'Koleksiyon Kategorileri',
  product_section_title = 'Seçili Ürünler',
  gallery_section_kicker = 'Mağazadan',
  gallery_section_title = 'Koleksiyonumuzdan Kareler',
  gallery_action_label = 'Tüm koleksiyonu gör',
  gallery_action_href = '#iletisim',
  blog_section_kicker = 'Stil Rehberi',
  blog_section_title = 'Moda & Kombin Önerileri',
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Merak Edilenler',
  faq_section_description = 'Sipariş, beden ve bakım hakkında sık sorulan sorular.',
  about_kicker = 'Hakkımızda',
  about_title = 'Çekmeköy''nun kalbinde, özel tasarım butik deneyimi',
  corporate_bio = 'Atmosfer Butik, 2019''dan bu yana Çekmeköy''da premium giyim deneyimi sunmaktadır. Özel tasarım elbiseler, el yapımı aksesuarlar ve sezonluk kapsül koleksiyonlarıyla tanınır.

Her parça, yerel zanaatkarlar ve küçük atölyelerle iş birliğiyle üretilir — seri üretim değil, sınırlı sayıda tasarım. Müşterilerimize birebir stil danışmanlığı sunuyoruz; doğru parçayı bulmanız için yardımcı oluyoruz.',
  about_image_caption = 'Mağazamızda el yapımı aksesuar reyonu',
  about_image_url = 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=85',
  about_values = '[
    {"id":"1","title":"Özel Tasarım","description":"Her sezon sınırlı sayıda, yerel zanaatkarlar tarafından üretilen özgün parçalar."},
    {"id":"2","title":"Kişisel Stil Danışmanlığı","description":"Mağazamızda birebir kombin önerisi, doğru beden ve renk seçimi."},
    {"id":"3","title":"Sürdürülebilir Üretim","description":"Katkısız kumaşlar, küçük ölçekli atölyeler ve sıfır atık üretimi hedefi."}
  ]'::jsonb,
  faq_items = '[
    {"id":"1","question":"Sipariş sonrası teslimat süresi ne kadar?","answer":"Stoktaki ürünler aynı gün kargoya verilir. Özel dikim ürünler 7-10 iş günü içinde tamamlanır, süresi WhatsApp''tan bildirilir."},
    {"id":"2","question":"Beden değişimi veya iade var mı?","answer":"Kullanılmamış, etiketli ürünlerde 14 gün içinde değişim yapılabilir. Özel dikim ürünlerde iade kabul edilmez."},
    {"id":"3","question":"Online sipariş verebilir miyim?","answer":"Evet, WhatsApp üzerinden sipariş oluşturabilirsiniz. Kargo ile Türkiye geneline gönderim yapıyoruz."},
    {"id":"4","question":"El yapımı ürünleriniz nereden geliyor?","answer":"Tüm aksesuarlarımız yerel zanaatkarlar ve küçük atölyeler tarafından üretilmektedir. Her parça el emeği ve özgün tasarımdır."}
  ]'::jsonb,
  gallery_items = '[
    {"id":"cover","imageUrl":"https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80","title":"Mağaza içi genel görünüm"},
    {"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=800&q=80","title":"Yeni sezon reyonu"},
    {"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1558171813-4c088753af8f?auto=format&fit=crop&w=800&q=80","title":"El yapımı aksesuar köşesi"},
    {"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&w=800&q=80","title":"Kapsül koleksiyon vitrini"},
    {"id":"gallery-3","imageUrl":"https://images.unsplash.com/photo-1560472354-b33ff0c44a43?auto=format&fit=crop&w=800&q=80","title":"Müşteri memnuniyeti köşesi"}
  ]'::jsonb,
  featured_banner_label = 'Bu Ay Öne Çıkan',
  featured_banner_title = 'Sonbahar / Kış 2026 Koleksiyonu',
  featured_banner_description = 'Doğal kumaşlar, sürdürülebilir üretim ve zamansız tasarımlar. Sınırlı sayıda, ön siparişle.',
  featured_banner_price_text = '349 TL''den başlayan fiyatlarla',
  featured_banner_image_url = 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&w=1200&q=80'
where slug = 'kiralik-butik';

-- ════════════════════════════════════════════════════════════════════════════
-- 2. KAFE / LOKANTA — Kahve Köşesi (kiralik-kafe)
-- ════════════════════════════════════════════════════════════════════════════
update public.stores set
  hero_badge = 'Butik Kahve · Kadıköy',
  hero_location_text = 'Kadıköy, İstanbul',
  phone = '905391234568',
  email = 'merhaba@kahvekosei.com',
  map_label = 'Moda Cad. No:45, Kadıköy — Moda tramvay durağı 2 dk',
  category_section_title = 'Menü Kategorileri',
  product_section_title = 'Menümüz',
  gallery_section_kicker = 'Mekandan',
  gallery_section_title = 'Atmosferimizden Kareler',
  gallery_action_label = 'Mekanımızı gör',
  gallery_action_href = '#iletisim',
  blog_section_kicker = 'Kahve Rehberi',
  blog_section_title = 'Bilmeniz Gerekenler',
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Merak Edilenler',
  faq_section_description = 'Menü, sipariş ve rezervasyon hakkında sık sorulan sorular.',
  about_kicker = 'Hakkımızda',
  about_title = '2021''den beri Kadıköy''de butik kahve deneyimi',
  corporate_bio = 'Kahve Köşesi, 2021''den beri Kadıköy''de butik kahve deneyimi sunmaktadır. Özel çekirdeklerden hazırlanan yeni nesil kahveler ve el yapımı pastalarıyla meşhurdur.

Her fincan kahvemiz, küçük parti kavurma yöntemiyle hazırlanan taze çekirdeklerden yapılır. Çekirdeklerimizi doğrudan Etiyopya, Kolombiya ve Brezilya''daki çiftliklerden temin ediyoruz. Amacımız, her yudumda farklı bir coğrafyanın hikayesini anlatmaktır.',
  about_image_caption = 'Demleme köşemizde taze çekirdekler',
  about_image_url = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200&q=85',
  about_values = '[
    {"id":"1","title":"Çiftlikten Fincana","description":"Doğrudan çiftliklerden temin edilen taze çekirdekler, small-batch kavurma."},
    {"id":"2","title":"El Yapımı Pastalar","description":"Günlük taze hazırlanan ev yapımı tatlılar ve poğaçalar."},
    {"id":"3","title":"Sıcak Atmosfer","description":"Moda''nın sokaklarından ilham alan, samimi ve rahat bir kahve durağı."}
  ]'::jsonb,
  faq_items = '[
    {"id":"1","question":"Rezervasyon gerekiyor mu?","answer":"Hafta içi genellikle yer bulabilirsiniz. Hafta sonu ve akşamları için WhatsApp''tan rezervasyon yaptırmanızı öneririz."},
    {"id":"2","question":"Vegan seçenekleriniz var mı?","answer":"Evet, badem sütü, yulaf sütü ve hindistan cevizi sütü ile hazırlanan kahve ve tatlı seçeneklerimiz mevcut."},
    {"id":"3","question":"Evcil hayvan ile gelebilir miyim?","answer":"Bahçe bölümümüzde evcil hayvan dostu alanımız mevcuttur."},
    {"id":"4","question":"Özel günler için rezervasyon alıyor musunuz?","answer":"Doğum günü ve küçük etkinlikler için özel köşe ayırımı yapıyoruz. WhatsApp''tan bilgi alabilirsiniz."}
  ]'::jsonb,
  gallery_items = '[
    {"id":"cover","imageUrl":"https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80","title":"Kahve demleme köşemiz"},
    {"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80","title":"İç mekan atmosferi"},
    {"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=800&q=80","title":"Taze çekirdek stok alanı"},
    {"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80","title":"Özel sunum tabağımız"},
    {"id":"gallery-3","imageUrl":"https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=800&q=80","title":"Latte art atölyemiz"}
  ]'::jsonb,
  featured_banner_label = 'Bu Ay Öne Çıkan',
  featured_banner_title = 'Yaz Menüsü — Soğuk Kahveler',
  featured_banner_description = 'Mevsim meyveleriyle hazırlanan soğuk içecekler ve ev yapımı limonata. Yaz boyunca geçerli özel fiyatlar.',
  featured_banner_price_text = '45 TL''den başlayan içecekler',
  featured_banner_image_url = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80'
where slug = 'kiralik-kafe';

-- ════════════════════════════════════════════════════════════════════════════
-- 3. KUAFÖR — Stil Studio (kiralik-kuafor)
-- ════════════════════════════════════════════════════════════════════════════
update public.stores set
  hero_badge = 'Profesyonel Kuaför · Beşiktaş',
  hero_location_text = 'Beşiktaş, İstanbul',
  phone = '905351234569',
  email = 'merhaba@stilstudio.com',
  map_label = 'Beşiktaş Cad. No:78, Beşiktaş — Metro 5 dk',
  category_section_title = 'Hizmet Kategorileri',
  product_section_title = 'Hizmet Fiyat Listesi',
  gallery_section_kicker = 'Stüdyodan',
  gallery_section_title = 'Çalışmalarımız',
  gallery_action_label = 'Tüm çalışmalarımızı gör',
  gallery_action_href = '#iletisim',
  blog_section_kicker = 'Saç Rehberi',
  blog_section_title = 'Bilmeniz Gerekenler',
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Merak Edilenler',
  faq_section_description = 'Randevu, bakım ve hizmet süreçleri hakkında sık sorulan sorular.',
  about_kicker = 'Hakkımızda',
  about_title = 'Beşiktaş''ta modern kuaförlük deneyimi',
  corporate_bio = 'Stil Studio, Beşiktaş''ta modern kuaförlük anlayışıyla hizmet vermektedir. Saç kesimi, boyama ve özel gün makyajı alanında uzman kadrosuyla öne çıkar.

Profesyonel ekibimiz, her müşterinin yüz şekli, cilt tonu ve yaşam tarzına uygun öneriler sunar. Kullandığımız ürünlerin tamamı ithal ve profesyonel düzeydedir; saç sağlığını koruyan formüller tercih edilir.',
  about_image_caption = 'Stüdyomuzda profesyonel bakım alanı',
  about_image_url = 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&q=85',
  about_values = '[
    {"id":"1","title":"Uzman Kadro","description":"Her yıl düzenli eğitim alan, sertifikalı saç stilistleri ve makyaj uzmanları."},
    {"id":"2","title":"Kaliteli Ürünler","description":"Profesyonel markalar, saç sağlığını koruyan boyalar ve bakım ürünleri."},
    {"id":"3","title":"Kişisel Danışmanlık","description":"Yüz şekline ve tarzına uygun öneriler, birebir stil danışmanlığı."}
  ]'::jsonb,
  faq_items = '[
    {"id":"1","question":"Randevu için ne kadar önce ulaşmalıyım?","answer":"En az 1 gün önce WhatsApp''tan randevu almanızı öneririz. Aynı gün için müsaitlik durumunu mesaj atarak kontrol edebilirsiniz."},
    {"id":"2","question":"Saç boyama işlemi ne kadar sürer?","answer":"Tek renk boyama 1-1,5 saat,ombre/balyaj 2-3 saat sürmektedir. İşlem süresi saç uzunluğuna göre değişebilir."},
    {"id":"3","question":"Özel gün makyajı için ne zaman gelmeliyim?","answer":"Düğün, nişan gibi özel günler için en az 2 hafta önce randevu almanız önerilir. Prova makyajı da yapılabilir."},
    {"id":"4","question":"Hangi marka ürünleri kullanıyorsunuz?","answer":"Profesyonel ithal markalar kullanıyoruz. Tüm ürünlerimiz saç sağlığını koruyan, amonyak içermeyen formüllere sahiptir."}
  ]'::jsonb,
  gallery_items = '[
    {"id":"cover","imageUrl":"https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=800&q=80","title":"Stüdyo içi genel görünüm"},
    {"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1560869713-7d0a29430803?auto=format&fit=crop&w=800&q=80","title":"Saç kesimi işlemi"},
    {"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?auto=format&fit=crop&w=800&q=80","title":"Renklendirme çalışması"},
    {"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=800&q=80","title":"Profesyonel makyaj"},
    {"id":"gallery-3","imageUrl":"https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=800&q=80","title":"Keratin bakım sonrası"}
  ]'::jsonb,
  featured_banner_label = 'Bu Ay Öne Çıkan',
  featured_banner_title = 'Yaz Sezonu Fırsatları',
  featured_banner_description = 'Haziran-Ağustos boyunca tüm saç boyama işlemlerinde %20 indirim. Randevu için WhatsApp''tan ulaşın.',
  featured_banner_price_text = '150 TL''den başlayan hizmetler',
  featured_banner_image_url = 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=1200&q=80'
where slug = 'kiralik-kuafor';

-- ════════════════════════════════════════════════════════════════════════════
-- 4. GIDA — Doğal Market (kiralik-gida)
-- ════════════════════════════════════════════════════════════════════════════
update public.stores set
  hero_badge = 'Organik & Doğal · Üsküdar',
  hero_location_text = 'Üsküdar, İstanbul',
  phone = '905371234571',
  email = 'merhaba@dogalmarket.com',
  map_label = 'Üsküdar Cad. No:33, Üsküdar — İskele 5 dk yürüme',
  category_section_title = 'Ürün Kategorileri',
  product_section_title = 'Haftalık Ürünler',
  gallery_section_kicker = 'Pazardan',
  gallery_section_title = 'Doğal Ürünlerimizden Kareler',
  gallery_action_label = 'Tüm ürünleri gör',
  gallery_action_href = '#iletisim',
  blog_section_kicker = 'Sağlıklı Yaşam',
  blog_section_title = 'Bilmeniz Gerekenler',
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Merak Edilenler',
  faq_section_description = 'Sipariş, teslimat ve ürünler hakkında sık sorulan sorular.',
  about_kicker = 'Hakkımızda',
  about_title = 'Çiftçiden sofranıza, doğal ve sertifikalı ürünler',
  corporate_bio = 'Doğal Market, 2020''den beri İstanbul''da organik gıda pazarlamaktadır. Sertifikalı çiftçilerden doğrudan temin edilen ürünler, koruyucu ve katkı maddesi içermez.

Amacımız, şehirde yaşayan insanların doğal ve taze gıdaya kolayca erişmesini sağlamaktır. Her hafta güncellenen ürün yelpazemizde mevsim sebzelerinden, yöresel peynirlere kadar geniş bir doğal ürün seçeneği bulabilirsiniz.',
  about_image_caption = 'Çiftlikten taze toplanan sebzeler',
  about_image_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200&q=85',
  about_values = '[
    {"id":"1","title":"Sertifikalı Organik","description":"T.C. Gıda, Tarım ve Hayvancılık Bakanlığı organik sertifikalı ürünler."},
    {"id":"2","title":"Mevsiminde Taze","description":"Her hafta taze toplanan, mevsimine göre güncellenen ürün yelpazesi."},
    {"id":"3","title":"Yerel Üretici Desteği","description":"Küçük çiftçilerden doğrudan alım, aracısız ve adil fiyat politikası."}
  ]'::jsonb,
  faq_items = '[
    {"id":"1","question":"Minimum sipariş tutarı var mı?","answer":"Minimum sipariş tutarı yoktur. Ancak 150 TL üzeri siparişlerde Üsküdar içi ücretsiz teslimat yapılır."},
    {"id":"2","question":"Ürünleriniz gerçekten organik mi?","answer":"Evet, tüm ürünlerimiz T.C. Gıda, Tarım ve Hayvancılık Bakanlığı organik sertifikalıdır. Sertifikalarımız mağazamızda teşhir edilmektedir."},
    {"id":"3","question":"Hangi günler teslimat yapıyorsunuz?","answer":"Pazartesi, Çarşamba ve Cuma günleri düzenli teslimat yapıyoruz. Aynı gün teslimat için sabah 10:00''a kadar sipariş vermeniz gerekir."},
    {"id":"4","question":"Ürünler nereden geliyor?","answer":"Marmara, Ege ve Akdeniz bölgesindeki sertifikalı çiftliklerden doğrudan temin ediyoruz. Her ürünün kaynağını sorabilirsiniz."}
  ]'::jsonb,
  gallery_items = '[
    {"id":"cover","imageUrl":"https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80","title":"Mağaza içi reyon düzeni"},
    {"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=800&q=80","title":"Taze mevsim sebzeleri"},
    {"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80","title":"Organik meyve reyonu"},
    {"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=800&q=80","title":"Yöresel peynir çeşitleri"},
    {"id":"gallery-3","imageUrl":"https://images.unsplash.com/photo-1518977956812-cd3dbadaaf31?auto=format&fit=crop&w=800&q=80","title":"Doğal ev yapımı reçeller"}
  ]'::jsonb,
  featured_banner_label = 'Bu Ay Öne Çıkan',
  featured_banner_title = 'Haftalık Sepet Kampanyası',
  featured_banner_description = 'Bu haftanın organik sepeti: mevsim sebzeleri, köy yumurtası ve ev yapımı reçel. Ücretsiz teslimat.',
  featured_banner_price_text = '250 TL sepet fiyatı',
  featured_banner_image_url = 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=1200&q=80'
where slug = 'kiralik-gida';

alter table public.stores enable trigger protect_landing_demo_stores;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. BLOG YAZILARI (store_articles) — her vitrin için 3 yazı
-- ════════════════════════════════════════════════════════════════════════════

-- ── BUTİK blogları ──────────────────────────────────────────────────────
insert into public.store_articles (store_slug, title, slug, summary, content, cover_image_url, status, published_at)
select * from (values
  (
    'kiralik-butik',
    'Doğal Kumaşlar ve Sürdürülebilir Moda Rehberi',
    'dogal-kumaslar-ve-surdurulebilir-moda',
    'Moda dünyasında sürdürülebilirlik neden önemli ve doğal kumaşlar nasıl seçilir?',
    'Sürdürülebilir moda, yalnızca çevre dostu kumaşlar kullanmak değildir — üretim sürecinin her aşamasında etik ve şeffaf olmayı gerektirir.

Doğal kumaşlar (keten, pamuk, ipek) sentetik alternatiflerine göre daha az su ve kimyasal kullanılarak üretilir. Atmosfer Butik''te tüm parçalarımız yerel atölyelerde, küçük partiler halinde üretilmektedir.

Bir giysiyi ne kadar uzun süre kullanırsanız, çevre üzerindeki etkisi o kadar azalır. Zamansız tasarım ve kaliteli kumaş seçimi, gardırobunuzun ömrünü uzatır.',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-butik',
    'Sezonun Öne Çıkan Renk Trendleri',
    'sezonun-one-cikan-renk-trendleri',
    'Bu sezonun en popüler renkleri ve nasıl kombinleneceği hakkında öneriler.',
    '2026 sonbahar-kış sezonunda toprak tonları, koyu yeşiller ve pastel maviler öne çıkıyor. Bu renkler hem günlük hem de özel gün kombinlerinde kolayca kullanılabilir.

Nötr renklerle (siyah, bej, gri) kombinlendiğinde şık bir görünüm elde edilir. Cesur renkleri tek parça olarak kullanmak, tamamlayıcı aksesuarlarla desteklediğinde dengeli bir stil yaratır.

Atmosfer Butik''te her sezon özenle seçilmiş renk paletleriyle koleksiyonlarımız güncellenir.',
    'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-butik',
    'Doğru Beden Seçimi: Online Alışverişte Kadın Giyim',
    'dogru-beden-secimi-online-alisveris',
    'Online alışverişte doğru bedeni nasıl seçersiniz? Pratik ipuçları.',
    'Online alışverişte en sık karşılaşılan sorunlardan biri beden uyumsuzluğudur. Her markanın beden kalıpları farklılık gösterir, bu yüzden yalnızca beden numarasına bakmak yeterli değildir.

Beden çizelgemizi inceleyerek göğüs, bel ve kalça ölçümlerinizle karşılaştırma yapın. Şüphelendiğinizde WhatsApp''tan bize yazın — size en uygun bedeni birlikte bulalım.',
    'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  )
) as v(store_slug, title, slug, summary, content, cover_image_url, status, published_at)
where not exists (
  select 1 from public.store_articles sa
  where sa.store_slug = v.store_slug and sa.slug = v.slug
);

-- ── KAFE blogları ───────────────────────────────────────────────────────
insert into public.store_articles (store_slug, title, slug, summary, content, cover_image_url, status, published_at)
select * from (values
  (
    'kiralik-kafe',
    'V60 Demleme Rehberi: Evde Profesyonel Kahve Nasıl Yapılır?',
    'v60-demleme-rehberi',
    'V60 ile evde nasıl lezzetli kahve demlersiniz? Adım adım rehber.',
    'V60 demleme, kahve tutkunlarının favori yöntemlerinden biridir. Doğru oranlar ve teknikle evde de café kalitesinde kahve yapabilirsiniz.

15 gram kahve, 250 ml su (92-96°C), 3 dakika demleme süresi. İlk 30 saniyede 30 ml su dökerek "bloom" (kabar _) işlemini yapın, sonra dairesel hareketlerle kalan suyu ekleyin.

Kahve Köşesi''nde her çekirdeğin demleme parametresi farklıdır — baristalarımız size en uygun oranı göstermekten mutluluk duyar.',
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-kafe',
    'Kahve Çekirdeği Nereden Gelir? Üretim Süreci',
    'kahve-cekirdegi-uretim-sureci',
    'Fincanınızdaki kahve çekirdeği nasıl yetiştirilir, hasat edilir ve kavrulur?',
    'Kahve çekirdeği, tropikal iklim kuşağında yetişen Coffea bitkisinin meyvesinden elde edilir. En kaliteli çekirdekler genellikle 1200-2000 metre yükseklikteki yamaçlarda yetişir.

Hasat elle yapılır — olgunlaşmış kırmızı meyveler toplanır. Yıkanma yöntemi (washed), doğal kurutma (natural) veya ballı yöntem (honey) ile işlenir. Her yöntem fincan tadını farklı etkiler.

Kahve Köşesi olarak çekirdeklerimizi doğrudan Etiyopya, Kolombiya ve Brezilya''daki çiftliklerden temin ediyoruz.',
    'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-kafe',
    'Sütüncü Kahveler: Latte, Cappuccino ve Flat White Farkı',
    'sutcunlu-kahve-cesitleri',
    'Latte, Cappuccino ve Flat White arasındaki fark nedir?',
    'Hepsi espresso ve süt ile hazırlanan bu üç kahve, süt/köpük oranıyla birbirinden ayrılır.

Cappuccino: 1/3 espresso, 1/3 süt, 1/3 kalın köpük. Yoğun lezzet, klasik İtalyan tarzı.
Latte: 1/3 espresso, 2/3 buharlanmış süt, ince köpük tabakası. Daha yumuşak içim.
Flat White: Double espresso, çok az buharlanmış süt, mikro köpük. En yoğun süt aroması.

Hangisini tercih ederseniz edin, taze çekilmiş çekirdek ve doğru buhar tekniği lezzeti belirler.',
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  )
) as v(store_slug, title, slug, summary, content, cover_image_url, status, published_at)
where not exists (
  select 1 from public.store_articles sa
  where sa.store_slug = v.store_slug and sa.slug = v.slug
);

-- ── KUAFÖR blogları ─────────────────────────────────────────────────────
insert into public.store_articles (store_slug, title, slug, summary, content, cover_image_url, status, published_at)
select * from (values
  (
    'kiralik-kuafor',
    'Saç Tipinize Göre Doğru Bakım Ürününü Seçme Rehberi',
    'sac-tipine-gore-bakim-urunu',
    'Saç tipinize uygun şampuan ve bakım ürününü nasıl seçersiniz?',
    'Saç tipinizi bilmek, doğru bakım ürününü seçmenin ilk adımıdır. Kuru, yağlı, normal veya karma saç tiplerinin her birinin farklı ihtiyacı vardır.

Kuru saçlar için nemlendirici içerikli (argan yağı, keratin) ürünler tercih edilmelidir. Yağlı saçlar için hacim veren, hafif formüller uygundur. Boyalı saçlar için renk koruyucu şampuanlar önerilir.

Stil Studio''da saç analiziniz yapıldıktan sonra size en uygun ürün önerisi sunulmaktadır.',
    'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-kuafor',
    'Boya Sonrası Saç Bakımı: Renklerin Kalıcılığını Artırma',
    'boya-sonrasi-sac-bakimi',
    'Saç boyattıktan sonra renklerin daha uzun soluklu kalması için ne yapmalısınız?',
    'Saç boyası uygulamasından sonraki ilk 48 saat en kritik süredir. Bu dönemde saçın gözenekleri açıktır ve renk molekülleri henüz oturmamıştır.

İlk yıkamayı 48 saat sonra yapın, ılık su tercih edin. Renk koruyucu şampuan ve saç kremi kullanın. Güneş, klör ve tuzlu su boyanın çabuk solmasına neden olur — koruyucu sprey kullanmayı ihmal etmeyin.

Stil Studio olarak boyama sonrası bakım seti önerilerimizi danışabilirsiniz.',
    'https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-kuafor',
    'Özel Gün Saç Modeli Seçimi: Düğün, Nişan ve Davet',
    'ozel-gun-sac-modeli',
    'Düğün ve nişan için saç modeli nasıl seçilir? Dikkat edilmesi gerekenler.',
    'Özel gün saç modeli seçerken yüz şekliniz, gelinliğinizin/dãoş elbisenizin yaka detayı ve saçınızın uzunluğu göz önünde bulundurulmalıdır.

Yüz şekline göre öneriler: Oval yüz her modele uygundur; yuvarlak yüz için yüksek topuz veya açık dalgalı modeller; uzun yüz için yanuntaryatırılmış modeller dengeli görünüm sağlar.

En az 2 hafta önce deneme makyajı ve saç provası yapılması önerilir. Stil Studio''da özel gün paketleri mevcuttur.',
    'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  )
) as v(store_slug, title, slug, summary, content, cover_image_url, status, published_at)
where not exists (
  select 1 from public.store_articles sa
  where sa.store_slug = v.store_slug and sa.slug = v.slug
);

-- ── GIDA blogları ───────────────────────────────────────────────────────
insert into public.store_articles (store_slug, title, slug, summary, content, cover_image_url, status, published_at)
select * from (values
  (
    'kiralik-gida',
    'Organik Ürün Nedir? Sertifika ve Güvence Rehberi',
    'organik-urun-nedir',
    'Organik ürünler nasıl yetiştirilir ve sertifika süreci nasıl işler?',
    'Organik tarım, sentetik gübre ve pestisit kullanmadan, doğanın döngüsüne saygı göstererek yapılan üretim biçimidir. Türkiye''de organik sertifika T.C. Gıda, Tarım ve Hayvancılık Bakanlığı tarafından verilir.

Bir ürünün "organik" olabilmesi için en az 3 yıl boyunca kimyasal kullanılmayan toprakta yetiştirilmesi gerekir. Düzenli denetimler yapılır ve her aşama kayıt altındadır.

Doğal Market''te tüm ürünlerimizin sertifikaları mağazamızda teşhir edilmektedir. Ürün kaynağını sormaktan çekinmeyin.',
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-gida',
    'Mevsim Sebzeleri: Hangi Ayda Ne Yenir?',
    'mevsim-sebzeleri-rehberi',
    'Mevsiminde tüketilen sebze ve meyvelerin faydaları ve kullanım önerileri.',
    'Mevsiminde tüketilen gıdalar hem daha lezzetlidir hem de daha besleyicidir. Kış aylarında turpgiller (lahana, brokoli), yaz aylarında domates, biber ve patlıcan öne çıkar.

Mevsiminde yenilen sebzenin vitamin ve mineral içeriği daha yüksektir — depolama ve uzun nakliye sürecinden geçmediği için besin değerini korur.

Doğal Market olarak ürün yelpazemizi her hafta mevsimine göre güncelliyoruz. Haftalık sepetlerimizde yalnızca taze ve mevsiminde ürünler yer alır.',
    'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'kiralik-gida',
    'Ev Yapımı Reçel ve Soslar: Doğal Lezzetlerin Sırrı',
    'ev-yapimi-recel-ve-soslar',
    'Katkısız ev yapımı reçel ve sosların lezzet sırrı nedir?',
    'Ev yapımı reçellerde yalnızca meyve, şeker ve limon suyu kullanılır — koruyucu, katkı maddesi veya yapay tatlandırıcı eklenmez. Geleneksel yöntemlerle, kısık ateşte kaynatılarak hazırlanır.

Meyvenin olgunluk derecesi, şeker oranı ve pişirme süresi lezzeti doğrudan etkiler. Çok pişirilen reçel koyu ve şekerli, az pişirilen ise taze ve hafif olur.

Doğal Market''teki ev yapımı reçellerimiz her hafta taze hazırlanmaktadır. Çilek, kayısı, vişne ve incir gibi çeşitler mevsimine göre değişir.',
    'https://images.unsplash.com/photo-1518977956812-cd3dbadaaf31?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  )
) as v(store_slug, title, slug, summary, content, cover_image_url, status, published_at)
where not exists (
  select 1 from public.store_articles sa
  where sa.store_slug = v.store_slug and sa.slug = v.slug
);

notify pgrst, 'reload schema';
