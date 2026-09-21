-- Keşfet'teki kiralık vitrin havuzunu 6 kategori x 5 = 30 kanonik şablona tamamlar.
-- Kapsam: 21 yeni platform demosu + kategori/ürün/blog içeriği. Tek transaction.

BEGIN;

DO $$
DECLARE v_existing integer; v_legal integer;
BEGIN
  SELECT count(*) INTO v_existing FROM public.stores WHERE slug = ANY (ARRAY['kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]);
  IF v_existing <> 0 THEN RAISE EXCEPTION 'KIRALIK_30_PREFLIGHT_FAILED: new slug collision count=%', v_existing; END IF;
  SELECT count(DISTINCT document_type) INTO v_legal FROM public.legal_documents
  WHERE is_active=true AND document_type IN ('privacy','terms','consent');
  IF v_legal <> 3 THEN RAISE EXCEPTION 'KIRALIK_30_PREFLIGHT_FAILED: active legal documents=%', v_legal; END IF;
END;
$$;


CREATE OR REPLACE FUNCTION public.clone_demo_store_as_draft(
  p_source_slug text,
  p_new_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, extensions
AS $$
DECLARE
  v_source_id uuid;
  v_new_id uuid;
BEGIN
  IF p_new_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 THEN RAISE EXCEPTION 'INVALID_SLUG'; END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN RAISE EXCEPTION 'INVALID_EDIT_TOKEN'; END IF;

  SELECT id INTO v_source_id FROM public.stores
  WHERE slug = pg_catalog.btrim(p_source_slug) AND is_demo = true;
  IF v_source_id IS NULL THEN RAISE EXCEPTION 'SOURCE_NOT_FOUND'; END IF;

  INSERT INTO public.stores (
    slug, edit_token, user_id, cloned_from_slug,
    name, business_type, description, corporate_bio,
    whatsapp, phone, email, hero_badge, instagram, website, address,
    theme, theme_preset, status, marketplace_links, gallery_items, products,
    product_categories, offerings, catalog_link, references_link, vcard_link,
    shelf_image_url, logo_url, working_hours, is_published, is_store, kategori,
    latitude, longitude, location_accuracy_meters, location_source,
    province_code, province_name, district_code, district_name, google_business_link,
    featured_banner_label, featured_banner_title, featured_banner_description,
    featured_banner_image_url, featured_banner_price_text, faq_items,
    about_kicker, about_title, about_image_url, about_image_caption, about_values,
    gallery_section_kicker, gallery_section_title, show_storefront_rating,
    show_directions_link, edit_token_expires_at
  )
  SELECT
    pg_catalog.btrim(p_new_slug), pg_catalog.btrim(p_edit_token), null, pg_catalog.btrim(p_source_slug),
    '', business_type, description, corporate_bio,
    '', null, null, hero_badge, instagram, website, '',
    theme, theme_preset, 'draft', marketplace_links, gallery_items, products,
    product_categories, offerings, catalog_link, references_link, vcard_link,
    shelf_image_url, null, null, false, is_store, kategori,
    null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, faq_items,
    about_kicker, about_title, about_image_url, about_image_caption, about_values,
    gallery_section_kicker, gallery_section_title, show_storefront_rating,
    show_directions_link, now() + interval '14 days'
  FROM public.stores WHERE id = v_source_id
  RETURNING id INTO v_new_id;

  DROP TABLE IF EXISTS _kategori_esleme;
  CREATE TEMPORARY TABLE _kategori_esleme (eski_id uuid primary key, yeni_id uuid not null) ON COMMIT DROP;

  INSERT INTO _kategori_esleme (eski_id, yeni_id)
  SELECT id, gen_random_uuid() FROM public.product_categories WHERE store_id = v_source_id;

  INSERT INTO public.product_categories (
    id, store_id, name, slug, sort_order, is_active, product_template_key
  )
  SELECT e.yeni_id, v_new_id, k.name, k.slug, k.sort_order, k.is_active, k.product_template_key
  FROM public.product_categories k
  JOIN _kategori_esleme e ON e.eski_id = k.id
  WHERE k.store_id = v_source_id;

  INSERT INTO public.products (
    id, store_id, category_id, source_type, external_product_id,
    name, slug, description, price_amount, price_text, currency,
    stock_quantity, stock_status, image_urls, metadata, seo_title, seo_description,
    is_visible, is_active, sort_order, brand, barcode, vat_rate, variants,
    old_price_amount, badge_tag, fulfillment_region
  )
  SELECT
    gen_random_uuid(), v_new_id, e.yeni_id, p.source_type, p.external_product_id,
    p.name, p.slug, p.description, p.price_amount, p.price_text, p.currency,
    p.stock_quantity, p.stock_status, p.image_urls, p.metadata, p.seo_title, p.seo_description,
    p.is_visible, p.is_active, p.sort_order, p.brand, p.barcode, p.vat_rate, p.variants,
    p.old_price_amount, p.badge_tag, p.fulfillment_region
  FROM public.products p
  LEFT JOIN _kategori_esleme e ON e.eski_id = p.category_id
  WHERE p.store_id = v_source_id;
END;
$$;

COMMENT ON FUNCTION public.clone_demo_store_as_draft(text, text, text) IS
  'Demo vitrini taslak klon olarak kopyalar; ürün, kategori ve product_template_key korunur. Kimlik alanları boş başlar, edit token 14 gündür.';


ALTER TABLE public.stores DISABLE TRIGGER protect_landing_demo_stores;

CREATE TEMP TABLE _vixrex_kiralik_30 (
  slug text,name text,business_type text,description text,corporate_bio text,
  kategori text,district_name text,shelf_image_url text,about_title text,
  product_template_key text,base_price numeric,category_names text[],
  category_slugs text[],product_names text[]
) ON COMMIT DROP;

INSERT INTO _vixrex_kiralik_30 VALUES
('kiralik-giyim-erkek','Kent Erkek Giyim','Erkek Giyim','Gömlekten cekete, günlük ve klasik erkek giyim seçkisi.','Kent Erkek Giyim; günlük kullanım, ofis ve özel gün kombinleri için temel erkek giyim ürünlerini bir araya getiren hazır vitrin örneğidir.','Giyim','Kadıköy','https://images.unsplash.com/photo-1617137968427-85924c800a22?w=1600&q=82','Klasik ve günlük erkek giyimi tek vitrinde','fashion',490,ARRAY['Gömlek & Üst Giyim','Pantolon & Denim','Ceket & Aksesuar']::text[],ARRAY['gomlek-ust','pantolon-denim','ceket-aksesuar']::text[],ARRAY['Oxford Gömlek','Polo Yaka Tişört','Slim Fit Chino','Koyu Denim Jean','Mevsimlik Ceket','Deri Kartlık']::text[]),
('kiralik-giyim-cocuk','MiniRota Çocuk','Çocuk Giyim','Çocuklar için rahat, dayanıklı ve mevsime uygun giyim seçenekleri.','MiniRota Çocuk; günlük giyim, okul dönemi ve temel aksesuar ihtiyaçlarını tek vitrinde sunan hazır çocuk giyim şablonudur.','Giyim','Üsküdar','https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=1600&q=82','Çocukların günlük hareketine uygun rahat parçalar','fashion',390,ARRAY['Üst Giyim','Alt Giyim','Okul & Aksesuar']::text[],ARRAY['ust-giyim','alt-giyim','okul-aksesuar']::text[],ARRAY['Baskılı Sweatshirt','Pamuklu Tişört','Jogger Pantolon','Denim Salopet','Mini Sırt Çantası','Yağmurluk']::text[]),
('kiralik-giyim-tesettur','Narin Tesettür','Tesettür Giyim','Tunik, elbise, dış giyim ve tamamlayıcı şal seçenekleri.','Narin Tesettür; günlük kullanımdan özel günlere uzanan sade ve kombinlenebilir tesettür giyim ürünleri için hazırlanmış kiralık vitrin örneğidir.','Giyim','Fatih','https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=1600&q=82','Günlük ve özel gün kombinleri için sade seçki','fashion',390,ARRAY['Elbise & Tunik','Dış Giyim','Şal & Aksesuar']::text[],ARRAY['elbise-tunik','dis-giyim','sal-aksesuar']::text[],ARRAY['Kemerli Midi Elbise','Uzun Keten Tunik','Mevsimlik Trenç','Uzun Hırka','Modal Şal','Omuz Çantası']::text[]),
('kiralik-giyim-spor','Aktif Stil','Spor Giyim','Antrenman ve günlük kullanım için rahat spor giyim ürünleri.','Aktif Stil; spor salonu, yürüyüş ve günlük aktif yaşam için temel üst, alt ve aksesuar ürünlerini sunan hazır vitrin şablonudur.','Giyim','Bakırköy','https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1600&q=82','Hareket odaklı günlük spor giyim seçkisi','fashion',290,ARRAY['Üst Giyim','Alt Giyim','Spor Aksesuar']::text[],ARRAY['ust-giyim','alt-giyim','spor-aksesuar']::text[],ARRAY['Dry Fit Tişört','Fermuarlı Hoodie','Antrenman Taytı','Jogger Eşofman','Spor Çantası','Antrenman Havlusu']::text[]),
('kiralik-butik-gunluk','Mimoza Butik','Kadın Butik','Günlük kombinler için elbise, üst giyim ve aksesuar seçkisi.','Mimoza Butik; kolay kombinlenen günlük kadın giyim ürünlerini ürün, fiyat ve görselleriyle sunan hazır butik vitrini örneğidir.','Butik','Beşiktaş','https://images.unsplash.com/photo-1445205170230-053b83016050?w=1600&q=82','Günlük şehir stiline uygun seçilmiş parçalar','fashion',350,ARRAY['Elbise','Üst Giyim','Aksesuar']::text[],ARRAY['elbise','ust-giyim','aksesuar']::text[],ARRAY['Çiçek Desenli Elbise','Keten Gömlek Elbise','Oversize Gömlek','İnce Triko','Mini Omuz Çantası','Desenli Fular']::text[]),
('kiralik-butik-abiye','Lal Abiye','Abiye Butik','Nişan, davet ve özel günler için abiye ve tamamlayıcı aksesuarlar.','Lal Abiye; özel gün elbiseleri, davet kombinleri ve tamamlayıcı aksesuarları sergilemek için hazırlanmış kiralık butik şablonudur.','Butik','Şişli','https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=1600&q=82','Özel günler için abiye ve davet kombinleri','fashion',490,ARRAY['Abiye','Davet Takımları','Çanta & Aksesuar']::text[],ARRAY['abiye','davet-takimlari','canta-aksesuar']::text[],ARRAY['Saten Uzun Abiye','Taş Detaylı Midi','Ceket Pantolon Takım','Şifon İkili Takım','Portföy Çanta','İnce Taşlı Kemer']::text[]),
('kiralik-butik-aksesuar','İnci Aksesuar','Aksesuar Butik','Çanta, takı ve günlük küçük aksesuarları bir arada sunan butik.','İnci Aksesuar; çanta, takı, fular ve küçük tamamlayıcı ürünler için hazırlanmış ürün odaklı kiralık vitrin örneğidir.','Butik','Kadıköy','https://images.unsplash.com/photo-1523779917675-b6ed3a42a561?w=1600&q=82','Kombinleri tamamlayan çanta ve aksesuar seçkisi','fashion',350,ARRAY['Çanta','Takı','Şal & Küçük Aksesuar']::text[],ARRAY['canta','taki','sal-kucuk-aksesuar']::text[],ARRAY['Deri Omuz Çantası','Mini Çapraz Çanta','Halka Küpe','Katmanlı Kolye','İpek Dokulu Fular','Kartlık']::text[]),
('kiralik-butik-genc','Sokak Butik','Genç Moda Butik','Genç şehir stiline uygun üst, alt ve tamamlayıcı ürünler.','Sokak Butik; trend odaklı günlük parçaları hızlıca sergilemek isteyen küçük butiklere göre hazırlanmış kiralık vitrin şablonudur.','Butik','Bakırköy','https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1600&q=82','Genç şehir stiline uygun dinamik kombinler','fashion',390,ARRAY['Üst Giyim','Alt Giyim','Aksesuar']::text[],ARRAY['ust-giyim','alt-giyim','aksesuar']::text[],ARRAY['Crop Sweatshirt','Basic Oversize Tişört','Wide Leg Jean','Kargo Pantolon','Bucket Şapka','Mini Sırt Çantası']::text[]),
('kiralik-gida-sarkuteri','Mahalle Şarküteri','Şarküteri','Peynir, zeytin, kahvaltılık ve günlük şarküteri ürünleri.','Mahalle Şarküteri; ürün çeşitlerini, gramaj ve fiyat bilgilerini düzenli göstermek isteyen yerel şarküteriler için hazırlanmış kiralık vitrin örneğidir.','Gıda','Üsküdar','https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=1600&q=82','Kahvaltılık ve şarküteri ürünlerini açık fiyatla sunan vitrin','food',165,ARRAY['Peynir','Zeytin & Şarküteri','Kahvaltılık']::text[],ARRAY['peynir','zeytin-sarkuteri','kahvaltilik']::text[],ARRAY['Ezine Beyaz Peynir 500 g','Eski Kaşar 500 g','Gemlik Zeytin 500 g','Hindi Füme 200 g','Tahin Pekmez Seti','Köy Tereyağı 500 g']::text[]),
('kiralik-gida-manav','Taze Sepet','Manav','Mevsim sebze ve meyveleriyle günlük taze ürün vitrini.','Taze Sepet; günlük sebze-meyve çeşitlerini ve hazır sepet seçeneklerini sergilemek isteyen manavlar için hazırlanmış kiralık vitrin şablonudur.','Gıda','Kadıköy','https://images.unsplash.com/photo-1542838132-92c53300491e?w=1600&q=82','Günlük sebze ve meyveyi kolay seçilebilir biçimde gösteren vitrin','food',55,ARRAY['Sebze','Meyve','Günlük Sepet']::text[],ARRAY['sebze','meyve','gunluk-sepet']::text[],ARRAY['Domates 1 kg','Salatalık 1 kg','Elma 1 kg','Muz 1 kg','Sebze Sepeti','Meyve Sepeti']::text[]),
('kiralik-gida-kuruyemis','Kırkambar Kuruyemiş','Kuruyemiş','Kuruyemiş, kuru meyve ve atıştırmalık çeşitleri.','Kırkambar Kuruyemiş; gramajlı ürünleri, karışım paketlerini ve hediye seçeneklerini sergilemek isteyen kuruyemişçiler için hazırlanmış vitrin örneğidir.','Gıda','Fatih','https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=1600&q=82','Kuruyemiş ve kuru meyve çeşitlerini düzenli sunan vitrin','food',150,ARRAY['Kuruyemiş','Kuru Meyve','Lokum & Atıştırmalık']::text[],ARRAY['kuruyemis','kuru-meyve','lokum-atistirmalik']::text[],ARRAY['Kavrulmuş Badem 250 g','Antep Fıstığı 250 g','Kuru Kayısı 250 g','Kuru İncir 250 g','Fıstıklı Lokum 300 g','Karışık Çerez 500 g']::text[]),
('kiralik-gida-market','Semt Market','Mahalle Marketi','Temel gıda, içecek ve günlük ev ihtiyaçlarını tek vitrinde gösterir.','Semt Market; günlük ihtiyaç ürünlerini kategori, fiyat ve stok bilgileriyle sunmak isteyen mahalle marketlerine göre hazırlanmış kiralık vitrin örneğidir.','Gıda','Bağcılar','https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1600&q=82','Mahalle alışverişinin temel ürünlerini tek ekranda toplar','food',45,ARRAY['Temel Gıda','İçecek','Ev İhtiyaç']::text[],ARRAY['temel-gida','icecek','ev-ihtiyac']::text[],ARRAY['Pirinç 1 kg','Makarna 500 g','Maden Suyu 6''lı','Soğuk Çay 1 L','Kağıt Havlu 6''lı','Bulaşık Deterjanı']::text[]),
('kiralik-kafe-pastane','Fırından Pastane','Pastane','Günlük tatlılar, hamur işleri ve kahve seçenekleri.','Fırından Pastane; günlük üretim tatlı, börek ve içeceklerini fiyatlarıyla sergileyen hazır pastane vitrini örneğidir.','Kafe / Lokanta','Beşiktaş','https://images.unsplash.com/photo-1551024506-0bccd828d307?w=1600&q=82','Günlük tatlı ve hamur işi üretimini tek vitrinde gösterir','cafe_restaurant',90,ARRAY['Tatlılar','Hamur İşleri','Kahve']::text[],ARRAY['tatlilar','hamur-isleri','kahve']::text[],ARRAY['San Sebastian Cheesecake','Fırın Sütlaç','Peynirli Su Böreği','Tereyağlı Kruvasan','Filtre Kahve','Latte']::text[]),
('kiralik-kafe-kahvalti','Güne Başla Kahvaltı','Kahvaltı Salonu','Kahvaltı tabakları, sıcak seçenekler ve içecekler.','Güne Başla Kahvaltı; serpme ve tabak kahvaltı, sıcak ürün ve içecek seçeneklerini açık fiyatla sunan kiralık restoran vitrini örneğidir.','Kafe / Lokanta','Üsküdar','https://images.unsplash.com/photo-1525351484163-7529414344d8?w=1600&q=82','Kahvaltı seçeneklerini hızlı karşılaştırmaya uygun menü','cafe_restaurant',30,ARRAY['Kahvaltı Tabakları','Yumurta & Sıcak','İçecek']::text[],ARRAY['kahvalti-tabaklari','yumurta-sicak','icecek']::text[],ARRAY['Klasik Kahvaltı Tabağı','İki Kişilik Serpme','Menemen','Kaşarlı Omlet','Demleme Çay','Taze Portakal Suyu']::text[]),
('kiralik-kafe-hizli','Sokak Lezzetleri','Hızlı Yemek','Dürüm, sandviç, atıştırmalık ve hızlı servis içecekleri.','Sokak Lezzetleri; paket servis ve hızlı tüketim odaklı küçük işletmeler için ürün, fiyat ve hazırlama seçeneklerini öne çıkaran kiralık vitrin şablonudur.','Kafe / Lokanta','Şişli','https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1600&q=82','Hızlı servis ve paket sipariş için net menü yapısı','cafe_restaurant',45,ARRAY['Dürüm & Sandviç','Atıştırmalık','İçecek']::text[],ARRAY['durum-sandvic','atistirmalik','icecek']::text[],ARRAY['Tavuk Dürüm','Izgara Sandviç','Patates Kızartması','Soğan Halkası','Ev Yapımı Limonata','Ayran']::text[]),
('kiralik-kuafor-berber','Usta Berber','Erkek Berberi','Saç kesimi, sakal ve erkek bakım hizmetleri.','Usta Berber; erkek saç kesimi, sakal ve bakım hizmetlerini süre ve fiyat bilgileriyle sunan kiralık hizmet vitrini örneğidir.','Kuaför','Kadıköy','https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=1600&q=82','Randevu ve hizmet fiyatlarını net gösteren erkek berberi vitrini','service',240,ARRAY['Saç Kesimi','Sakal','Bakım']::text[],ARRAY['sac-kesimi','sakal','bakim']::text[],ARRAY['Klasik Saç Kesimi','Saç Kesimi + Yıkama','Sakal Tasarımı','Saç + Sakal Paket','Sıcak Havlu Bakımı','Saç Bakım Uygulaması']::text[]),
('kiralik-kuafor-guzellik','Işık Güzellik','Güzellik Salonu','Cilt bakımı, kaş-kirpik ve kişisel bakım hizmetleri.','Işık Güzellik; randevulu cilt bakımı ve kaş-kirpik hizmetlerini düzenli paketler halinde göstermek isteyen salonlar için hazırlanmış kiralık vitrin örneğidir.','Kuaför','Bakırköy','https://images.unsplash.com/photo-1560750588-73207b1ef5b8?w=1600&q=82','Randevulu güzellik ve bakım hizmetlerini anlaşılır sunar','service',350,ARRAY['Cilt Bakımı','Kaş & Kirpik','Bakım Paketleri']::text[],ARRAY['cilt-bakimi','kas-kirpik','bakim-paketleri']::text[],ARRAY['Klasik Cilt Bakımı','Yoğun Nem Bakımı','Kaş Tasarımı','Kirpik Lifting','Cilt + Kaş Paketi','Aylık Bakım Paketi']::text[]),
('kiralik-kuafor-nail','Nokta Nail Studio','Nail Studio','Manikür, kalıcı oje ve nail art hizmetleri.','Nokta Nail Studio; manikür, kalıcı oje ve tasarım hizmetlerini randevu odaklı sunmak isteyen küçük stüdyolar için hazırlanmış kiralık vitrin şablonudur.','Kuaför','Beşiktaş','https://images.unsplash.com/photo-1604654894610-df63bc536371?w=1600&q=82','Nail hizmetlerini süre ve fiyat bilgileriyle sunan randevu vitrini','service',180,ARRAY['Manikür','Kalıcı Oje','Nail Art']::text[],ARRAY['manikur','kalici-oje','nail-art']::text[],ARRAY['Klasik Manikür','Spa Manikür','Tek Renk Kalıcı Oje','French Kalıcı Oje','Minimal Nail Art','Detaylı Nail Art']::text[]),
('kiralik-teknik-bilgisayar','PC Usta','Bilgisayar Teknik Servis','Laptop ve masaüstü bilgisayar onarım, bakım ve yükseltme hizmetleri.','PC Usta; arıza tespiti, bakım, SSD yükseltme ve veri aktarımı gibi bilgisayar servislerini fiyat ve teslim bilgileriyle sunan kiralık vitrin örneğidir.','Teknik Servis','Şişli','https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=1600&q=82','Bilgisayar bakım ve onarım hizmetlerini açık biçimde sunar','technical_service',400,ARRAY['Laptop & PC Onarım','Bakım','SSD & Veri']::text[],ARRAY['laptop-pc-onarim','bakim','ssd-veri']::text[],ARRAY['Arıza Tespiti','Ekran Değişimi İşçiligi','Fan & Termal Bakım','Format & Kurulum','SSD Yükseltme İşçiligi','Veri Aktarımı']::text[]),
('kiralik-teknik-beyaz-esya','Ev Teknik','Beyaz Eşya Teknik Servis','Çamaşır, bulaşık, buzdolabı ve temel ev cihazı servis hizmetleri.','Ev Teknik; ev tipi cihazlarda arıza tespiti, bakım ve servis taleplerini hizmet türüne göre göstermek isteyen teknik servisler için hazırlanmış kiralık vitrin örneğidir.','Teknik Servis','Bağcılar','https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=1600&q=82','Ev cihazı servis taleplerini kategori bazlı toplar','technical_service',450,ARRAY['Çamaşır & Bulaşık','Buzdolabı','Küçük Ev Aleti']::text[],ARRAY['camasir-bulasik','buzdolabi','kucuk-ev-aleti']::text[],ARRAY['Çamaşır Makinesi Arıza Tespiti','Bulaşık Makinesi Bakımı','Soğutma Arızası Kontrolü','Kapı Conta Değişimi İşçiligi','Kahve Makinesi Kontrolü','Elektrikli Süpürge Bakımı']::text[]),
('kiralik-teknik-tv','Ekran Teknik','TV ve Elektronik Servis','TV, görüntü, bağlantı ve temel elektronik kart servisleri.','Ekran Teknik; televizyon ve ev elektroniği servislerini arıza türü, fiyat ve teslim süresiyle sergilemek isteyen işletmeler için hazırlanmış kiralık vitrin şablonudur.','Teknik Servis','Üsküdar','https://images.unsplash.com/photo-1593784991095-a205069470b6?w=1600&q=82','TV ve elektronik servis hizmetlerini anlaşılır kategorilere ayırır','technical_service',450,ARRAY['TV Onarım','Kurulum & Bağlantı','Elektronik Kart']::text[],ARRAY['tv-onarim','kurulum-baglanti','elektronik-kart']::text[],ARRAY['Görüntü Arızası Tespiti','LED Aydınlatma Kontrolü','TV Kurulum Hizmeti','Uydu Kanal Ayarı','Güç Kartı Kontrolü','HDMI Bağlantı Onarımı']::text[]);

CREATE TEMP TABLE _vixrex_kategori_gorselleri (kategori text primary key,gorseller text[]) ON COMMIT DROP;
INSERT INTO _vixrex_kategori_gorselleri VALUES
('Giyim',ARRAY['https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=900&q=80','https://images.unsplash.com/photo-1483985988355-763728e1935b?w=900&q=80','https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900&q=80','https://images.unsplash.com/photo-1445205170230-053b83016050?w=900&q=80','https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=900&q=80']::text[]),
('Butik',ARRAY['https://images.unsplash.com/photo-1445205170230-053b83016050?w=900&q=80','https://images.unsplash.com/photo-1483985988355-763728e1935b?w=900&q=80','https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=900&q=80','https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=900&q=80','https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=900&q=80']::text[]),
('Gıda',ARRAY['https://images.unsplash.com/photo-1542838132-92c53300491e?w=900&q=80','https://images.unsplash.com/photo-1540420773420-3366772f4999?w=900&q=80','https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=900&q=80','https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=900&q=80','https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=900&q=80']::text[]),
('Kafe / Lokanta',ARRAY['https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=900&q=80','https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900&q=80','https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=900&q=80','https://images.unsplash.com/photo-1551024506-0bccd828d307?w=900&q=80','https://images.unsplash.com/photo-1525351484163-7529414344d8?w=900&q=80']::text[]),
('Kuaför',ARRAY['https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=900&q=80','https://images.unsplash.com/photo-1562322140-8baeececf3df?w=900&q=80','https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=900&q=80','https://images.unsplash.com/photo-1560750588-73207b1ef5b8?w=900&q=80','https://images.unsplash.com/photo-1604654894610-df63bc536371?w=900&q=80']::text[]),
('Teknik Servis',ARRAY['https://images.unsplash.com/photo-1581092795360-fd1ca04f0952?w=900&q=80','https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=900&q=80','https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=900&q=80','https://images.unsplash.com/photo-1518770660439-4636190af475?w=900&q=80','https://images.unsplash.com/photo-1593784991095-a205069470b6?w=900&q=80']::text[]);

WITH
privacy AS (SELECT version,content_hash FROM public.legal_documents WHERE document_type='privacy' AND is_active=true LIMIT 1),
terms AS (SELECT version,content_hash FROM public.legal_documents WHERE document_type='terms' AND is_active=true LIMIT 1),
consent AS (SELECT version,content_hash FROM public.legal_documents WHERE document_type='consent' AND is_active=true LIMIT 1)
INSERT INTO public.stores (
  slug,name,business_type,description,corporate_bio,whatsapp,instagram,website,address,kategori,status,
  shelf_image_url,logo_url,working_hours,is_published,is_demo,is_store,user_id,province_name,district_name,
  theme_preset,hero_badge,faq_items,about_kicker,about_title,about_image_url,about_image_caption,about_values,
  gallery_section_kicker,gallery_section_title,gallery_items,blog_section_kicker,blog_section_title,
  category_section_title,product_section_title,show_storefront_rating,show_directions_link,product_storage_version,
  privacy_notice_acknowledged,privacy_notice_acknowledged_at,privacy_notice_version,privacy_notice_hash,
  terms_accepted,terms_accepted_at,terms_version,terms_hash,publication_consent_accepted,
  publication_consent_accepted_at,publication_consent_version,publication_consent_hash,publication_consent_withdrawn_at
)
SELECT
  v.slug,v.name,v.business_type,v.description,v.corporate_bio,'05551234567','','',
  v.district_name || ' Merkez, ' || v.district_name || ', İstanbul',v.kategori,'açık',
  v.shelf_image_url,v.shelf_image_url,
  CASE v.kategori
      WHEN 'Giyim' THEN '{"monday":"10:00-20:00","tuesday":"10:00-20:00","wednesday":"10:00-20:00","thursday":"10:00-20:00","friday":"10:00-21:00","saturday":"10:00-21:00","sunday":"11:00-19:00"}'
      WHEN 'Butik' THEN '{"monday":"10:00-20:00","tuesday":"10:00-20:00","wednesday":"10:00-20:00","thursday":"10:00-20:00","friday":"10:00-21:00","saturday":"10:00-21:00","sunday":"11:00-19:00"}'
      WHEN 'Gıda' THEN '{"monday":"08:30-20:30","tuesday":"08:30-20:30","wednesday":"08:30-20:30","thursday":"08:30-20:30","friday":"08:30-21:00","saturday":"08:30-21:00","sunday":"09:00-19:00"}'
      WHEN 'Kafe / Lokanta' THEN '{"monday":"08:30-22:00","tuesday":"08:30-22:00","wednesday":"08:30-22:00","thursday":"08:30-22:00","friday":"08:30-23:00","saturday":"09:00-23:00","sunday":"09:00-22:00"}'
      WHEN 'Kuaför' THEN '{"monday":"09:00-20:00","tuesday":"09:00-20:00","wednesday":"09:00-20:00","thursday":"09:00-20:00","friday":"09:00-20:00","saturday":"09:00-19:00","sunday":""}'
      WHEN 'Teknik Servis' THEN '{"monday":"09:00-19:00","tuesday":"09:00-19:00","wednesday":"09:00-19:00","thursday":"09:00-19:00","friday":"09:00-19:00","saturday":"10:00-18:00","sunday":""}'
      ELSE '{}' END,
  false,true,true,null,'İstanbul',v.district_name,'atmosfer','Hazır Vitrin · ' || v.business_type,
  CASE v.kategori
      WHEN 'Giyim' THEN '[{"id":"1","question":"Beden seçeneklerini nasıl öğrenebilirim?","answer":"Ürün kartındaki bilgiler yeterli değilse kiracı işletme WhatsApp üzerinden beden ve stok teyidi verebilir."},{"id":"2","question":"Stok bilgisi nasıl gösterilir?","answer":"Gerçek işletme vitrini yayına alındığında ürün stoklarını kendi kataloğundan günceller."},{"id":"3","question":"Mağazada deneme yapılabilir mi?","answer":"Gerçek kiracı adres ve çalışma saatlerini eklediğinde mağaza ziyareti bilgisi vitrinde görünür."},{"id":"4","question":"Değişim koşulları nerede yer alır?","answer":"Kiracı işletme kendi değişim ve iade koşullarını açıklama ve SSS alanlarına ekleyebilir."}]'::jsonb
      WHEN 'Butik' THEN '[{"id":"1","question":"Ürünlerin bedenleri nerede görülür?","answer":"Kiracı işletme ürün kartlarına beden ve varyant bilgilerini ekleyebilir."},{"id":"2","question":"Stok için nasıl iletişim kurulur?","answer":"Gerçek işletme kendi WhatsApp bilgisini eklediğinde stok soruları doğrudan işletmeye yönlenir."},{"id":"3","question":"Yeni ürünler nasıl öne çıkarılır?","answer":"Ürün sırası, rozet ve vitrin bölümleri kiracı tarafından güncellenebilir."},{"id":"4","question":"Değişim bilgisi nasıl belirtilir?","answer":"İşletme kendi değişim politikasını açıklama ve SSS alanlarında yayınlayabilir."}]'::jsonb
      WHEN 'Gıda' THEN '[{"id":"1","question":"Ürünler günlük olarak güncellenebilir mi?","answer":"Kiracı işletme fiyat, stok ve ürün listesini kendi çalışma düzenine göre güncelleyebilir."},{"id":"2","question":"Gramaj ve fiyat bilgisi nerede görünür?","answer":"Ürün kartında ad, açıklama ve fiyatla birlikte gramaj bilgisi de yazılabilir."},{"id":"3","question":"Sipariş nasıl alınır?","answer":"Gerçek işletme WhatsApp bilgisini eklediğinde uygun ürünlerde sipariş iletişimi kurulabilir."},{"id":"4","question":"İçerik veya alerjen bilgisi eklenebilir mi?","answer":"Ürün açıklaması ve detay alanları içerik bilgisini belirtmek için kullanılabilir."}]'::jsonb
      WHEN 'Kafe / Lokanta' THEN '[{"id":"1","question":"Menü her gün değişebilir mi?","answer":"Kiracı işletme ürünleri ve fiyatları kendi günlük menüsüne göre güncelleyebilir."},{"id":"2","question":"Paket servis bilgisi eklenebilir mi?","answer":"İşletme açıklama, ürün ve WhatsApp alanlarında paket servis bilgisini yayınlayabilir."},{"id":"3","question":"Alerjen bilgisi nerede gösterilir?","answer":"Ürün detayları ve açıklama alanları alerjen ve içerik bilgisini belirtmek için kullanılabilir."},{"id":"4","question":"Çalışma saatleri nasıl görünür?","answer":"Kiracı kendi güncel çalışma saatlerini eklediğinde vitrin ziyaretçiye açık şekilde gösterir."}]'::jsonb
      WHEN 'Kuaför' THEN '[{"id":"1","question":"Randevu almak gerekiyor mu?","answer":"Gerçek işletme randevu ve WhatsApp kanalını kendi çalışma biçimine göre etkinleştirebilir."},{"id":"2","question":"Hizmet süresi nerede belirtilir?","answer":"Hizmet açıklaması ve ürün detaylarında yaklaşık süre bilgisi verilebilir."},{"id":"3","question":"Fiyatlar güncellenebilir mi?","answer":"Kiracı işletme hizmet fiyatlarını istediği zaman kendi kataloğundan güncelleyebilir."},{"id":"4","question":"İptal veya erteleme bilgisi eklenebilir mi?","answer":"Randevu kullanan işletmeler kendi randevu kurallarını açıklama alanlarında belirtebilir."}]'::jsonb
      WHEN 'Teknik Servis' THEN '[{"id":"1","question":"Arıza tespiti nasıl anlatılır?","answer":"Hizmet kartında kapsam, yaklaşık süre ve başlangıç fiyatı açık şekilde belirtilebilir."},{"id":"2","question":"Onarım öncesi fiyat verilebilir mi?","answer":"Kiracı servis kendi fiyatlandırma yöntemini ve teklif sürecini vitrinde açıklayabilir."},{"id":"3","question":"Garanti bilgisi nerede yer alır?","answer":"Hizmet açıklaması, ürün detayı ve SSS alanları garanti bilgisini yayınlamak için kullanılabilir."},{"id":"4","question":"Teslim süresi belirtilebilir mi?","answer":"Her hizmet kartında tahmini teslim veya işlem süresi yazılabilir."}]'::jsonb
      ELSE '[]'::jsonb END,
  'Hakkımızda',v.about_title,v.shelf_image_url,v.business_type || ' için örnek vitrin görseli',
  CASE v.kategori
      WHEN 'Giyim' THEN '[{"id":"1","title":"Ürün Odaklı","description":"Beden, fiyat ve görsel bilgileri ürün kartlarında öne çıkar."},{"id":"2","title":"Kolay İletişim","description":"Kiracı kendi WhatsApp ve mağaza bilgisini ekleyebilir."},{"id":"3","title":"Esnek Katalog","description":"Ürünler ve kategoriler işletmeye göre değiştirilebilir."}]'::jsonb
      WHEN 'Butik' THEN '[{"id":"1","title":"Seçili Koleksiyon","description":"Vitrin küçük koleksiyonları düzenli sunacak biçimde hazırlanmıştır."},{"id":"2","title":"Görsel Sunum","description":"Kapak, galeri ve ürün kartları birlikte çalışır."},{"id":"3","title":"Hızlı Güncelleme","description":"Kiracı ürün ve fiyatları kendi kataloğundan yenileyebilir."}]'::jsonb
      WHEN 'Gıda' THEN '[{"id":"1","title":"Açık Fiyat","description":"Ürün, gramaj ve fiyat bilgisi kartlarda net gösterilebilir."},{"id":"2","title":"Güncel Stok","description":"Kiracı günlük ürün ve stok durumunu yönetebilir."},{"id":"3","title":"Yerel İletişim","description":"Adres, saat ve WhatsApp bilgileri işletmeye göre doldurulur."}]'::jsonb
      WHEN 'Kafe / Lokanta' THEN '[{"id":"1","title":"Net Menü","description":"Menü kategorileri ve fiyatlar tek ekranda görülebilir."},{"id":"2","title":"Sipariş Kanalı","description":"Kiracı uygun olduğunda WhatsApp sipariş yolunu ekleyebilir."},{"id":"3","title":"Günlük Güncelleme","description":"Menü ve çalışma saatleri işletme tarafından değiştirilebilir."}]'::jsonb
      WHEN 'Kuaför' THEN '[{"id":"1","title":"Hizmet Listesi","description":"Hizmet adı, fiyatı ve yaklaşık süre birlikte sunulabilir."},{"id":"2","title":"Randevu Odaklı","description":"İşletme uygun randevu kanalını vitrinde açabilir."},{"id":"3","title":"Kişisel İçerik","description":"Galeri ve hizmetler gerçek işletmeye göre değiştirilebilir."}]'::jsonb
      WHEN 'Teknik Servis' THEN '[{"id":"1","title":"Açık Kapsam","description":"Servis türü ve başlangıç fiyatı kartlarda belirtilebilir."},{"id":"2","title":"Teslim Bilgisi","description":"Yaklaşık işlem ve teslim süresi hizmete eklenebilir."},{"id":"3","title":"Güven Bilgisi","description":"Garanti, parça ve süreç bilgileri SSS alanında açıklanabilir."}]'::jsonb
      ELSE '[]'::jsonb END,
  'Galeriden','Vitrin Görselleri',
  (SELECT jsonb_agg(jsonb_build_object('id','gallery-'||(x.sira-1)::text,'imageUrl',x.url,'title',v.business_type||' vitrin görseli '||x.sira::text) ORDER BY x.sira)
   FROM unnest(g.gorseller) WITH ORDINALITY AS x(url,sira)),
  'İşletme Rehberi',v.business_type || ' İçin Kısa Rehberler',
  CASE WHEN v.kategori IN ('Kuaför','Teknik Servis') THEN 'Hizmet Kategorileri' ELSE 'Ürün Kategorileri' END,
  CASE WHEN v.kategori IN ('Kuaför','Teknik Servis') THEN 'Hizmetler' ELSE 'Ürünler' END,
  false,false,2,true,now(),p.version,p.content_hash,true,now(),t.version,t.content_hash,
  true,now(),c.version,c.content_hash,null
FROM _vixrex_kiralik_30 v
JOIN _vixrex_kategori_gorselleri g ON g.kategori=v.kategori
CROSS JOIN privacy p CROSS JOIN terms t CROSS JOIN consent c;

INSERT INTO public.product_categories (store_id,name,slug,sort_order,is_active,product_template_key)
SELECT s.id,v.category_names[i],v.category_slugs[i],i-1,true,v.product_template_key
FROM _vixrex_kiralik_30 v JOIN public.stores s ON s.slug=v.slug
CROSS JOIN LATERAL generate_subscripts(v.category_names,1) AS i;

INSERT INTO public.products (
  store_id,category_id,source_type,name,slug,description,price_amount,price_text,currency,
  stock_status,image_urls,is_visible,is_active,sort_order
)
SELECT s.id,pc.id,'manual',v.product_names[i],'urun-'||i::text,
  v.product_names[i]||' — bu hazır vitrinde örnek ürün/hizmet kartı olarak gösterilir.',
  v.base_price+((i-1)*100),(v.base_price+((i-1)*100))::text||' TL','TRY','Mevcut',
  jsonb_build_array(g.gorseller[((i-1)%array_length(g.gorseller,1))+1]),true,true,i-1
FROM _vixrex_kiralik_30 v
JOIN public.stores s ON s.slug=v.slug
JOIN _vixrex_kategori_gorselleri g ON g.kategori=v.kategori
CROSS JOIN LATERAL generate_subscripts(v.product_names,1) AS i
JOIN public.product_categories pc ON pc.store_id=s.id AND pc.slug=v.category_slugs[((i-1)/2)+1];

INSERT INTO public.store_articles (store_slug,title,slug,summary,content,cover_image_url,status,published_at)
SELECT v.slug,v.business_type||': '||a.baslik,a.slug,a.ozet,
  a.ozet||' Bu hazır vitrin örneği, gerçek kiracı işletmenin kendi bilgileriyle düzenlenmek üzere hazırlanmıştır.',
  v.shelf_image_url,'published',now()
FROM _vixrex_kiralik_30 v
CROSS JOIN (VALUES
 ('Müşterinin Baktığı Temel Bilgiler','musterinin-baktigi-bilgiler','Fiyat, görsel, kategori ve iletişim bilgisinin ilk bakışta anlaşılır olması müşterinin kararını kolaylaştırır.'),
 ('Ürün ve Hizmet Kartı Rehberi','urun-hizmet-karti-rehberi','Kartlarda kısa ad, açıklama, fiyat ve net görsel birlikte kullanıldığında vitrin daha kolay taranır.'),
 ('Vitrini Güncel Tutma Rehberi','vitrini-guncel-tutma','Fiyat, stok, hizmet ve çalışma bilgileri değiştikçe vitrinin düzenli güncellenmesi gerekir.')
) AS a(baslik,slug,ozet);


-- Temiz migration zincirinde bu dört landing demosunun eski yayın adımı,
-- aktif yasal belgeler henüz oluşmadığı için atlanabiliyor. Artık belgeler
-- mevcut: mevcut içeriklerini değiştirmeden ortak yayın kapısından geçir.
WITH
privacy AS (
  SELECT version,content_hash FROM public.legal_documents
  WHERE document_type='privacy' AND is_active=true LIMIT 1
),
terms AS (
  SELECT version,content_hash FROM public.legal_documents
  WHERE document_type='terms' AND is_active=true LIMIT 1
),
consent AS (
  SELECT version,content_hash FROM public.legal_documents
  WHERE document_type='consent' AND is_active=true LIMIT 1
)
UPDATE public.stores s SET
  is_demo=true,
  province_name=coalesce(nullif(btrim(s.province_name),''),'İstanbul'),
  district_name=coalesce(nullif(btrim(s.district_name),''),'Şişli'),
  status='açık',
  product_storage_version=2,
  privacy_notice_acknowledged=true,
  privacy_notice_acknowledged_at=coalesce(s.privacy_notice_acknowledged_at,now()),
  privacy_notice_version=p.version,
  privacy_notice_hash=p.content_hash,
  terms_accepted=true,
  terms_accepted_at=coalesce(s.terms_accepted_at,now()),
  terms_version=t.version,
  terms_hash=t.content_hash,
  publication_consent_accepted=true,
  publication_consent_accepted_at=coalesce(s.publication_consent_accepted_at,now()),
  publication_consent_version=c.version,
  publication_consent_hash=c.content_hash,
  publication_consent_withdrawn_at=null,
  is_published=true
FROM privacy p,terms t,consent c,
(VALUES
  ('demo-aymira-giyim','Aymira Giyim'),
  ('demo-lezzet-duragi','Lezzet Durağı'),
  ('demo-nova-kuafor','Nova Kuaför'),
  ('demo-teknofix','TeknoFix')
) AS expected(slug,name)
WHERE s.slug=expected.slug
  AND s.name=expected.name
  AND s.user_id IS NULL;

UPDATE public.stores SET is_published=true WHERE slug=ANY(ARRAY['kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]);

DO $$
DECLARE r record; v_products integer; v_categories integer; v_articles integer; v_faq integer; v_gallery integer; v_total integer;
BEGIN
  FOR r IN SELECT slug FROM _vixrex_kiralik_30 LOOP
    SELECT count(*) INTO v_products FROM public.products p JOIN public.stores s ON s.id=p.store_id WHERE s.slug=r.slug AND p.is_active=true AND p.is_visible=true;
    SELECT count(*) INTO v_categories FROM public.product_categories pc JOIN public.stores s ON s.id=pc.store_id WHERE s.slug=r.slug AND pc.is_active=true;
    SELECT count(*) INTO v_articles FROM public.store_articles WHERE store_slug=r.slug AND status='published';
    SELECT coalesce(jsonb_array_length(coalesce(faq_items,'[]'::jsonb)),0),coalesce(jsonb_array_length(coalesce(gallery_items,'[]'::jsonb)),0)
      INTO v_faq,v_gallery FROM public.stores WHERE slug=r.slug;
    IF v_products<6 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: % products=%',r.slug,v_products; END IF;
    IF v_categories<3 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: % categories=%',r.slug,v_categories; END IF;
    IF v_articles<3 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: % articles=%',r.slug,v_articles; END IF;
    IF v_faq<4 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: % faq=%',r.slug,v_faq; END IF;
    IF v_gallery<5 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: % gallery=%',r.slug,v_gallery; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.stores s WHERE s.slug=r.slug AND s.is_demo=true AND s.is_published=true AND s.user_id IS NULL AND s.product_storage_version=2 AND btrim(coalesce(s.about_title,''))<>'')
      THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: % store contract',r.slug; END IF;
  END LOOP;

  SELECT count(*) INTO v_total FROM public.stores WHERE is_demo=true AND is_published=true AND slug=ANY(ARRAY['demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix','kiralik-butik','kiralik-gida','kiralik-kafe','kiralik-kuafor','kiralik-teknik','kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]);
  IF v_total<>30 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: canonical published demos=%',v_total; END IF;
  IF (SELECT count(*) FROM public.stores WHERE is_demo=true AND is_published=true AND slug=ANY(ARRAY['demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix','kiralik-butik','kiralik-gida','kiralik-kafe','kiralik-kuafor','kiralik-teknik','kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]) AND kategori='Giyim')<>5 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: Giyim'; END IF;
  IF (SELECT count(*) FROM public.stores WHERE is_demo=true AND is_published=true AND slug=ANY(ARRAY['demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix','kiralik-butik','kiralik-gida','kiralik-kafe','kiralik-kuafor','kiralik-teknik','kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]) AND kategori='Butik')<>5 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: Butik'; END IF;
  IF (SELECT count(*) FROM public.stores WHERE is_demo=true AND is_published=true AND slug=ANY(ARRAY['demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix','kiralik-butik','kiralik-gida','kiralik-kafe','kiralik-kuafor','kiralik-teknik','kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]) AND kategori='Gıda')<>5 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: Gıda'; END IF;
  IF (SELECT count(*) FROM public.stores WHERE is_demo=true AND is_published=true AND slug=ANY(ARRAY['demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix','kiralik-butik','kiralik-gida','kiralik-kafe','kiralik-kuafor','kiralik-teknik','kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]) AND kategori='Kafe / Lokanta')<>5 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: Kafe / Lokanta'; END IF;
  IF (SELECT count(*) FROM public.stores WHERE is_demo=true AND is_published=true AND slug=ANY(ARRAY['demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix','kiralik-butik','kiralik-gida','kiralik-kafe','kiralik-kuafor','kiralik-teknik','kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]) AND kategori='Kuaför')<>5 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: Kuaför'; END IF;
  IF (SELECT count(*) FROM public.stores WHERE is_demo=true AND is_published=true AND slug=ANY(ARRAY['demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix','kiralik-butik','kiralik-gida','kiralik-kafe','kiralik-kuafor','kiralik-teknik','kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv']::text[]) AND kategori='Teknik Servis')<>5 THEN RAISE EXCEPTION 'KIRALIK_30_POSTCHECK_FAILED: Teknik Servis'; END IF;
END;
$$;

ALTER TABLE public.stores ENABLE TRIGGER protect_landing_demo_stores;
NOTIFY pgrst,'reload schema';
COMMIT;
