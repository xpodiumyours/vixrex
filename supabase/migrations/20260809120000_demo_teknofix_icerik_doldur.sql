-- demo-teknofix'i C:\teknik_vitrin_asistan.html (FixTech) referans kalitesine
-- tasir: Hakkimizda, SSS, urun/hizmet listesi, galeri basliklari, 3 blog
-- yazisi ve bolum basliklarinin tamami gercek/spesifik icerikle dolduruluyor.
--
-- Neden dogrudan SQL: mevcut demo satiri zaten bir SQL seed migration'i ile
-- yaratilmisti (20260803190248_..._landing_demo_drafts_seed.sql), manuel
-- panelden degil. Ayni yontemle devam ediliyor.
--
-- Onemli bulgu: eski seed script urunleri "offerings" (artik kod tarafindan
-- okunmayan, terk edilmis) sutununa yazmisti. Canli sayfa (page.tsx) urunleri
-- ayri "products"/"product_categories" tablolarindan okuyor - bu yuzden urun
-- bolumu yapisal olarak hep bos kaliyordu. Bu migration urunleri dogru
-- tablolara yaziyor.

-- 1) stores tablosundaki metin/JSON alanlari
update public.stores set
  hero_badge = 'Yetkili Teknik Servis · Şişli',
  description = '10 yıllık tecrübeyle telefon, tablet ve bilgisayar onarımında hızlı, garantili ve şeffaf hizmet.',
  hero_location_text = 'Şişli, İstanbul',
  working_hours = 'Pzt–Cmt 09:00–19:30, Pazar kapalı',
  phone = '02122345678',
  email = 'info@teknofix.com.tr',
  map_label = 'Atatürk Caddesi, Şişli — Metro Şişli-Mecidiyeköy 5 dk',
  category_section_title = 'Hizmet Kategorileri',
  product_section_title = 'Servis Fiyat Listesi',
  gallery_section_kicker = 'Atölyeden',
  gallery_section_title = 'Çalışmalarımız',
  gallery_action_label = 'Tüm çalışmalarımızı gör',
  gallery_action_href = '#iletisim',
  blog_section_kicker = 'Teknik Rehber',
  blog_section_title = 'Bilmeniz Gerekenler',
  faq_section_kicker = 'Sıkça Sorulan Sorular',
  faq_section_title = 'Merak Edilenler',
  faq_section_description = 'Onarım süreci, garanti ve teslim süreleri hakkında sık sorulan sorular.',
  about_kicker = 'Hakkımızda',
  about_title = '10 yıllık tecrübeyle şeffaf ve garantili teknik servis',
  corporate_bio = 'TeknoFix, 2015 yılından bu yana Şişli''de telefon, tablet ve bilgisayar onarımı yapan bağımsız bir teknik servistir. Apple, Samsung ve genel Android/Windows cihazlarında orijinal ve OEM eşdeğeri parçalarla çalışıyor, her onarım öncesi ücretsiz arıza tespiti sunuyoruz.

Müşterilerimize açık fiyatlandırma ve yazılı garanti veriyoruz — onarım başlamadan önce net fiyat söylenir, sürpriz ek ücret çıkmaz. Ekibimiz düzenli olarak üretici sertifikalı eğitimlerden geçiyor.',
  about_image_caption = 'Atölyemizde titiz bir onarım süreci',
  about_values = '[
    {"id":"1","title":"Şeffaf Fiyatlandırma","description":"Tespit sonrası net fiyat, onayınız alınmadan işlem başlamaz."},
    {"id":"2","title":"Orijinal Parça Garantisi","description":"Kullanılan tüm parçalarda 6 ay yazılı garanti, iş takibi SMS ile bildirilir."},
    {"id":"3","title":"Aynı Gün Teslim","description":"Ekran ve batarya değişimlerinin büyük kısmı 1-2 saat içinde tamamlanır."}
  ]'::jsonb,
  faq_items = '[
    {"id":"1","question":"Cihazımı bırakmadan önce fiyat öğrenebilir miyim?","answer":"Evet, ücretsiz arıza tespiti sonrası net fiyatı WhatsApp veya telefonla bildiriyoruz, onayınız olmadan işlem başlamaz."},
    {"id":"2","question":"Garanti süresi ne kadar?","answer":"Tüm ekran, batarya ve parça değişimlerinde 6 ay yazılı garanti veriyoruz."},
    {"id":"3","question":"Verilerim onarım sırasında güvende mi?","answer":"Evet, veri güvenliği önceliğimiz; onarım öncesi isterseniz yedekleme desteği de sağlıyoruz."},
    {"id":"4","question":"Aynı gün teslim garantisi var mı?","answer":"Ekran ve batarya değişimlerinin büyük kısmı stok müsaitse aynı gün teslim edilir; anakart onarımları 2-3 iş günü sürebilir."}
  ]'::jsonb,
  gallery_items = '[
    {"id":"cover","imageUrl":"https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=800&q=80","title":"Atölyemizden bir kare — hassas komponent onarımı"},
    {"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=800&q=80","title":"Orijinal parça stok alanımız"},
    {"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=800&q=80","title":"iPhone ekran değişimi anı"},
    {"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1585771724684-38269d6639fd?auto=format&fit=crop&w=800&q=80","title":"Laptop anakart tamiri, mikroskop altında"}
  ]'::jsonb,
  featured_banner_label = 'Bu Ay Öne Çıkan',
  featured_banner_title = 'Ekran Değişiminde %15 İndirim',
  featured_banner_description = 'Ağustos ayı boyunca tüm telefon ekran değişimlerinde geçerli, orijinal parça garantisiyle.',
  featured_banner_price_text = '%15 İndirim',
  featured_banner_image_url = 'https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=1200&q=80'
where slug = 'demo-teknofix';

-- 2) Kategoriler (product_categories) — yalnizca yoksa ekle
with hedef as (
  select id as store_id from public.stores where slug = 'demo-teknofix'
),
kategori_listesi (isim, sira) as (
  values
    ('Telefon Ekran & Batarya Değişimi', 0),
    ('Bilgisayar & Laptop Servisi', 1),
    ('Tablet Onarımı', 2),
    ('Aksesuar & Yedek Parça', 3)
)
insert into public.product_categories (store_id, name, slug, is_active, sort_order)
select hedef.store_id, kl.isim,
  lower(regexp_replace(kl.isim, '[^a-zA-Z0-9şüğıçöŞÜĞİÇÖ\s-]', '', 'g')),
  true, kl.sira
from hedef, kategori_listesi kl
where not exists (
  select 1 from public.product_categories pc
  where pc.store_id = hedef.store_id and lower(pc.name) = lower(kl.isim)
);

-- 3) Urunler (products) — daha once bu demo icin urun girilmemisse ekle
with hedef as (
  select id as store_id from public.stores where slug = 'demo-teknofix'
),
kat as (
  select pc.id, pc.name from public.product_categories pc, hedef
  where pc.store_id = hedef.store_id
),
urun_listesi (ad, aciklama, fiyat_metin, fiyat_sayi, eski_fiyat, kategori_adi, teslim, sira) as (
  values
    ('iPhone Orijinal Ekran Değişimi', 'Apple onaylı orijinal ekran, dokunmatik ve renk kalibrasyonu test edilerek teslim edilir.', '2.450 TL', 2450, null::numeric, 'Telefon Ekran & Batarya Değişimi', 'Şişli ve çevresi aynı gün, İstanbul geneli kargo', 0),
    ('Samsung Galaxy Batarya Değişimi', 'Orijinal kapasiteli batarya, değişim sonrası kalibrasyon yapılır.', '850 TL', 850, null::numeric, 'Telefon Ekran & Batarya Değişimi', 'Şişli ve çevresi aynı gün, İstanbul geneli kargo', 1),
    ('Telefon Kamera Modülü Değişimi', 'Otofokus ve netlik testi yapılarak teslim edilir.', '1.100 TL', 1100, null::numeric, 'Telefon Ekran & Batarya Değişimi', 'Şişli ve çevresi aynı gün, İstanbul geneli kargo', 2),
    ('MacBook Klavye & Tuş Takımı Değişimi', 'Kelebek/makas mekanizma değişimi, tüm tuşlar test edilir.', '1.850 TL', 1850, null::numeric, 'Bilgisayar & Laptop Servisi', '2 iş günü, teslimat İstanbul geneli kargo', 0),
    ('Laptop Anakart Arıza Tespiti & Onarımı', 'Ücretsiz ön inceleme sonrası net onarım fiyatı bildirilir.', '600 TL (tespit)', 600, null::numeric, 'Bilgisayar & Laptop Servisi', '2-3 iş günü', 1),
    ('Data Kurtarma (HDD/SSD)', 'Fiziksel/mantıksal arızalı disklerden veri kurtarma.', '950 TL''den başlar', 950, null::numeric, 'Bilgisayar & Laptop Servisi', '3-5 iş günü', 2),
    ('iPad Ekran Değişimi', 'Orijinal ekran + dokunmatik katman, su sızdırmazlık testiyle teslim.', '1.950 TL', 1950, null::numeric, 'Tablet Onarımı', 'Aynı gün, İstanbul geneli kargo', 0),
    ('Orijinal Şarj Aleti & Kablo Seti', 'Apple/Samsung uyumlu, orijinal amper değeriyle hızlı şarj.', '450 TL', 450, null::numeric, 'Aksesuar & Yedek Parça', 'Stoktan aynı gün', 0)
)
insert into public.products (
  store_id, name, slug, description, price_text, price_amount,
  image_urls, category_id, source_type, is_visible, is_active, sort_order,
  fulfillment_region, stock_status
)
select
  hedef.store_id,
  ul.ad,
  lower(regexp_replace(ul.ad, '[^a-zA-Z0-9şüğıçöŞÜĞİÇÖ\s-]', '', 'g')),
  ul.aciklama,
  ul.fiyat_metin,
  ul.fiyat_sayi,
  '["https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&q=80"]'::jsonb,
  kat.id,
  'manual',
  true, true,
  ul.sira,
  ul.teslim,
  'Mevcut'
from hedef
join urun_listesi ul on true
join kat on kat.name = ul.kategori_adi
where not exists (
  select 1 from public.products p
  where p.store_id = hedef.store_id and lower(p.name) = lower(ul.ad)
);

-- 4) Blog yazilari (store_articles)
insert into public.store_articles (store_slug, title, slug, summary, content, cover_image_url, status, published_at)
select * from (values
  (
    'demo-teknofix',
    'Telefon Ekranı Kırıldığında İlk 24 Saatte Yapılması Gerekenler',
    'telefon-ekrani-kirildiginda-ilk-24-saat',
    'Ekranınız kırıldıysa panik yapmadan önce bu adımları takip edin — veri kaybını ve maliyeti azaltabilirsiniz.',
    'Telefon ekranınız kırıldığında ilk yapmanız gereken cihazı kapatmak ve daha fazla baskı uygulamamaktır. Çatlak ekranla kullanmaya devam etmek, dokunmatik katmana zarar vererek onarım maliyetini artırabilir.

Cihazınızı mümkünse anti-statik bir poşete koyun ve doğrudan güneş ışığından uzak tutun. Sıvı teması varsa cihazı kesinlikle şarja takmayın.

TeknoFix''te ücretsiz arıza tespiti ile hem ekranın hem alttaki panelin durumu kontrol edilir. Çoğu iPhone ve Samsung modelinde orijinal ekran değişimi aynı gün, 1-2 saat içinde tamamlanır.',
    'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'demo-teknofix',
    'Laptop Aşırı Isınıyorsa Nedenleri ve Çözümleri',
    'laptop-asiri-isinmasi-nedenleri-ve-cozumleri',
    'Laptopunuz çalışırken aşırı ısınıyorsa bu nedenleri kontrol edin.',
    'Laptop aşırı ısınmasının en sık nedeni toz birikimi ve kurumuş termal pattır — fan ve radyatör düzenli temizlenmezse performans düşer.

İkinci yaygın neden arka planda çalışan yoğun uygulamalardır; görev yöneticisinden yüksek CPU kullanan süreçler kontrol edilmeli.

TeknoFix''te laptop temizliği ve termal pat yenileme hizmeti sunuyoruz; ortalama işlem süresi 45 dakikadır ve cihazınızı beklerken teslim alabilirsiniz.',
    'https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  ),
  (
    'demo-teknofix',
    'Orijinal Parça ile Muadil Parça Arasındaki Fark Nedir?',
    'orijinal-parca-ile-muadil-parca-arasindaki-fark',
    'Ekran ve batarya değişiminde "orijinal" ile "muadil" parça arasındaki gerçek farkı anlatıyoruz.',
    'Orijinal parça, üreticinin kendi fabrikasında ürettiği veya sertifikalı tedarikçiden gelen parçadır; renk doğruluğu, dokunmatik hassasiyeti ve dayanıklılık açısından cihazın orijinaline en yakın sonucu verir.

Muadil (OEM eşdeğeri) parçalar daha uygun fiyatlıdır ama kalite aralığı geniştir — bazı muadiller orijinale çok yakın performans gösterirken bazıları daha kısa ömürlü olabilir.

TeknoFix''te hangi parçayı kullandığımızı işlem öncesi açıkça belirtiyoruz, karar her zaman müşteriye ait.',
    'https://images.unsplash.com/photo-1585771724684-38269d6639fd?auto=format&fit=crop&w=1200&q=80',
    'published',
    now()
  )
) as v(store_slug, title, slug, summary, content, cover_image_url, status, published_at)
where not exists (
  select 1 from public.store_articles sa
  where sa.store_slug = v.store_slug and sa.slug = v.slug
);

notify pgrst, 'reload schema';
