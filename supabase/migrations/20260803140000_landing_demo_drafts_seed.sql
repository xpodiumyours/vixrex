-- Landing sayfasındaki 4 sabit pazarlama demo'sunu (Aymira Giyim, Lezzet
-- Durağı, Nova Kuaför, TeknoFix) Supabase'e TASLAK olarak yazar.
-- Bilinçli olarak is_published = false: Keşfet ekranı yalnızca
-- is_published = true satırları listeliyor, bu yüzden bu satırlar Keşfet'e
-- hiç karışmaz. Yalnızca sabit preview_token ile /v/{slug}?preview_token=...
-- üzerinden Next.js'in gerçek şablonunda görünürler.
--
-- edit_token'lar rastgele değil, okunabilir sabitler — bu satırlar gerçek
-- kullanıcı verisi değil, herkese açık pazarlama içeriği; gizlilik riski yok.

insert into public.stores (
  slug, edit_token, name, business_type, description, theme, status,
  whatsapp, website, address, latitude, longitude, kategori,
  gallery_items, offerings, marketplace_links, is_published, shelf_image_url
) values
(
  'demo-aymira-giyim',
  'landing-demo-aymira-giyim-2026',
  'Aymira Giyim',
  'KADIN GİYİM / BUTİK',
  'Yeni sezon reyonları ve mağaza fotoğrafları tek vitrinde.',
  'Premium',
  'draft',
  '05551234567',
  'aymiragiyim.com',
  'Atatürk Cad. No:24, Şişli, İstanbul',
  41.0606, 28.9878,
  'Giyim',
  '[{"id":"cover","imageUrl":"https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=400&q=80"},{"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-3","imageUrl":"https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=300&q=80"}]'::jsonb,
  '[{"id":"1","title":"Elbise Seçenekleri","description":"Yeni sezon özel tasarım elbiseler","price":"Mağazada sorunuz"},{"id":"2","title":"Triko & Hırka","description":"Farklı renk ve beden alternatifleriyle","price":"Mağazada sorunuz"},{"id":"3","title":"Yeni Sezon Ceket","description":"Şık ve modern günlük ceketler","price":"Mağazada sorunuz"}]'::jsonb,
  '[{"id":"0","platform":"Vitrin galerisi","url":"google.com","subtitle":"Raf ve reyon fotoğrafları"},{"id":"1","platform":"Trendyol","url":"trendyol.com/magaza/demo","subtitle":"Mağazayı ziyaret edin"}]'::jsonb,
  false,
  'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=1200&q=80'
),
(
  'demo-lezzet-duragi',
  'landing-demo-lezzet-duragi-2026',
  'Lezzet Durağı',
  'KAFE / RESTORAN',
  'Menü, konum ve WhatsApp sipariş bilgileri tek ekranda.',
  'Premium',
  'draft',
  '05551234567',
  'lezzetduragi.com',
  'Atatürk Cad. No:24, Şişli, İstanbul',
  41.0422, 29.0084,
  'Kafe / Lokanta',
  '[{"id":"cover","imageUrl":"https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400&q=80"},{"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-3","imageUrl":"https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=300&q=80"}]'::jsonb,
  '[{"id":"1","title":"Günün Menüsü","description":"Ana yemek + çorba + içecek menüsü","price":"120 TL"},{"id":"2","title":"Ev Yapımı Mantı","description":"Yoğurtlu ve tereyağlı soslu el yapımı mantı","price":"95 TL"}]'::jsonb,
  '[{"id":"0","platform":"Günün menüsü","url":"google.com","subtitle":"Sıcak yemek ve tatlılar"},{"id":"1","platform":"Paket servis","url":"google.com","subtitle":"WhatsApp ile sipariş"}]'::jsonb,
  false,
  'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80'
),
(
  'demo-nova-kuafor',
  'landing-demo-nova-kuafor-2026',
  'Nova Kuaför',
  'KUAFÖR / GÜZELLİK',
  'Randevu, hizmetler ve sosyal medya bağlantıları hazır.',
  'Premium',
  'draft',
  '05551234567',
  'novakuafor.com',
  'Atatürk Cad. No:24, Şişli, İstanbul',
  41.0370, 28.9850,
  'Kuaför',
  '[{"id":"cover","imageUrl":"https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=400&q=80"}]'::jsonb,
  '[{"id":"1","title":"Saç Kesimi & Tasarım","description":"Yıkama ve fön dahil komple saç tasarımı","price":"180 TL"},{"id":"2","title":"Saç Boyama & Keratin","description":"Saç yapısına özel organik keratin bakımı","price":"450 TL"}]'::jsonb,
  '[]'::jsonb,
  false,
  'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=1200&q=80'
),
(
  'demo-teknofix',
  'landing-demo-teknofix-2026',
  'TeknoFix',
  'TELEFON TEKNİK SERVİS',
  'Servis talebi, adres ve güvenilir iletişim tek vitrinde.',
  'Premium',
  'draft',
  '05551234567',
  'teknofix.com',
  'Atatürk Cad. No:24, Şişli, İstanbul',
  41.0150, 28.9740,
  'Teknik Servis',
  '[{"id":"cover","imageUrl":"https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=400&q=80"},{"id":"gallery-0","imageUrl":"https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-1","imageUrl":"https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=300&q=80"},{"id":"gallery-2","imageUrl":"https://images.unsplash.com/photo-1585771724684-38269d6639fd?auto=format&fit=crop&w=300&q=80"}]'::jsonb,
  '[{"id":"1","title":"Telefon Ekran Değişimi","description":"30 dakikada hızlı ekran değişimi ve garanti","price":"Mağazada sorunuz"},{"id":"2","title":"Batarya Değişimi","description":"Yüksek kapasiteli batarya yenilemesi","price":"Mağazada sorunuz"}]'::jsonb,
  '[{"id":"0","platform":"Servis kaydı","url":"google.com","subtitle":"Ekran, batarya ve bakım"},{"id":"1","platform":"Google yorumları","url":"google.com","subtitle":"Müşteri güveni"}]'::jsonb,
  false,
  'https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=1200&q=80'
)
on conflict (slug) do nothing;

notify pgrst, 'reload schema';
