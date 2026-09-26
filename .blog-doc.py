from pathlib import Path
p=Path('public_web/BLOG_TESLIM.md')
p.write_text('''# Vixrex Blog — araştırma, tasarım ve teslim

11 Eylül 2026. Çalışma dalı: `work/blog-complete-20260911`.

## Ürün kararı

Kurumsal blog `vixrex.com/blog`, yazılar `/blog/<slug>` adresindedir. İşletmelerin kendi vitrin yazıları olan `/v/<slug>/yazilar` ile ayrı kalır. Aynı Vixrex üst/alt gezinmesi kullanılır.

Önerilen erişim: landing üst menüsünde sade **Blog** bağlantısı; şablonlardan sonra ve son oluşturma çağrısından önce üç rehberlik bölüm; altbilgide kalıcı Blog bağlantısı. Blog birincil oluşturma eyleminin önüne geçirilmez. Mobilde de Blog sözcüğü görünür. Bütün girişler mevcut yayın anahtarını izler.

Bu yerleşim araştırmadan üretilen tasarım tercihidir; Vixrex müşterileri üzerinde yapılmış bir dönüşüm testi sonucu değildir.

## Araştırma ve uygulama karşılığı

| Kaynak | Bulgudan çıkarılan uygulama kararı |
| --- | --- |
| [NN/g — Corporate Blogs: Front Page Structure](https://www.nngroup.com/articles/corporate-blogs-front-page-structure/) | Ana sayfada tam yazılar yerine başlık ve kısa özetlerle konu seçimi. Öne çıkan rehber ve taranabilir kartlar. Araştırmanın tarihi 2010; güncel performans ölçümü olarak kullanılmadı. |
| [Wix Blog](https://www.wix.com/blog) ve [Shopify Blog](https://www.shopify.com/blog) | Ürün sitesinin altında blog, konu temelli keşif ve rehberlerden ürüne geçiş örnekleri incelendi. Bu sitelerin dönüşüm başarısı hakkında iddia üretilmedi. |
| [NN/g — Table of Contents](https://www.nngroup.com/articles/table-of-contents/) | Çok bölümlü yazıda masaüstü içindekiler, mobilde açılır içindekiler. Kısa ama bölümlü bir rehber yalnız okuma süresi nedeniyle bu erişimi kaybetmez. |
| [Google — Helpful, reliable, people-first content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content) | Her yazı belirli işletme sorusuna cevap verir. Yazarlık, kaynak ve kontrol tarihleri görünür; doğrulanmamış satış, sıralama veya süre vaatleri kullanılmaz. |
| [Google — Article structured data](https://developers.google.com/search/docs/appearance/structured-data/article) | Yazı başlığı, gerçek yazar türü, yayın/güncelleme tarihleri, paylaşım görseli ve BlogPosting verisi. Arama sonucu görünümü veya sıralama garantisi verilmez. |
| [W3C — Page structure](https://www.w3.org/WAI/tutorials/page-structure/) ve [Target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum) | Anlamlı başlık hiyerarşisi, gezinme adları, içeriğe geç bağlantısı, görünür klavye odağı, 44px kontrol hedefi ve duyurulan arama sonuçları. Tam WCAG uygunluk sertifikası iddia edilmez. |

## Görsel yaklaşım

Mevcut Vixrex lacivert/mavi renkleri ve Outfit yazı ailesi kullanılır. Büyük başlık, geniş boşluklar, tek öne çıkan rehber ve hafif kart listesi vardır. Kapaklar konuya özgü şematik SVG çizimleridir; gerçek ürün ekranı ya da müşteri fotoğrafı olarak sunulmaz. Sahte müşteri logosu, başarı oranı veya anonim uzman kimliği eklenmedi.

Kartın tamamı bir bağlantıdır. Arama Türkçe harflerin harfsiz karşılıklarını da kabul eder (`kuafor` → `kuaför`). Boş kategori gösterilmez. Filtreler temizlenebilir; boş sonuçta geri dönüş eylemi vardır. Liste yalnız rehber türünü gösterip haberleri/hikâyeleri saklamaz. Dokuz kart sonrası daha fazla göster eylemi hazırdır.

## İçerik paketi

Altı yazı taslaktır:

1. İlk dijital vitrinin: yayın öncesi hazırlık listesi.
2. Müşteri mesajlarına açık yanıtlar: 5 örnek.
3. Kafe menüsünü telefonda okunur hâle getir.
4. Telefonla ürün fotoğrafı: sade bir çekim planı.
5. Kuaför salonu için dijital vitrin nasıl hazırlanır? (önceki taslak)
6. İşletmemi Google'da nasıl gösterebilirim? (önceki taslak)

İlk dört metin genel uygulama önerileri ve açıkça örnek olarak sunulan metinlerdir. Müşteri araştırması, deney sonucu veya uzman onayı iddiası taşımaz. Gerçek içerik olmadan işletme hikâyesi veya ürün haberi oluşturulmadı; bu kategoriler içerik gelince görünür.

Google rehberinin kaynak kontrolünde [işletme kuralları](https://support.google.com/business/answer/3038177?hl=tr), [doğrulama](https://support.google.com/business/answer/7107242?hl=tr), [teknik gereksinimler](https://developers.google.com/search/docs/essentials/technical) ve [yeniden tarama](https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl?hl=tr) belgeleri açıldı. Önceki taslakta yer alan `3039617` düzenleme belgesi bu turda açılamadı; o kaynağın yeniden kontrol edildiği iddia edilmez. Mevcut son kontrol tarihleri bu nedenle topluca bugüne çekilmedi.

## Editoryal çalışma

Kaynak `src/data/blogYazilari.ts`. CMS veya yeni veritabanı yok. Her yazıda soru, kategori, gövde, kaynaklar, yazar, görsel kullanım alanları ve tarihler var. Yayın ilkeleri `/blog/yayin-ilkeleri` sayfasında; düzeltme bildirimi mevcut iletişim sayfasına gider.

Yazı yayımlanacaksa editör metni ve kaynakları kontrol eder; `yayinda: true`, `durum: "yayinda"`, gerçek `yayinTarihi` ve `sonKontrolTarihi` girilir. Esaslı değişiklikte güncelleme tarihi ve notu eklenir. Görsel kullanılırsa alt metni, kaynağı ve kullanım bilgisi tamamlanır. Yayın filtresi liste, yazı, RSS, paylaşım görseli, landing ve sitemap için ortak kalır.

## Önizleme ve yayın sınırı

Yerel önizleme: geliştirme sunucusunda `BLOG_ONIZLEME=1`. `NODE_ENV=production` iken bu değişken taslak açamaz. Önizlemede noindex ve görünür taslak bandı vardır. Kaynak taslakları değiştirilmez. Bu mekanizma dağıtıma açık bir önizleme API'si değildir.

Çalışma ortamında: `http://127.0.0.1:3107/blog`. Normal üretim derlemesi 3108 portunda kapalı yayın davranışıyla kontrol edildi. Main birleştirmesi ve canlı dağıtım yapılmadı. Yayın kararı kullanıcı incelemesini bekliyor.

## Kabul kontrolleri

- Tüm Next.js birim testleri: 1.479 başarılı, 3 mevcut todo.
- Üretim derlemesi: Webpack ile başarılı; yerel node_modules junction kullandığı için bu çalışma ortamında Webpack seçildi. Vercel/Turbopack dağıtımı bu sonuçla doğrulanmış sayılmaz.
- Gerçek Chromium: masaüstü arama/filtre/sıfırlama, 320px ve 390px taşma/içindekiler, altı yazı, metadata, RSS, OG PNG, 404, kopyalama ve hata geri bildirimi testleri.
- Landing blog geçişi ilk geliştirme testinde zaman aşımına uğradı; aynı akışın tekrar kontrolü geçti. Üretim performansı ölçümü yapılmadı.
- Üretim modunda taslak blog, yazı, RSS, kapak ve yayın ilkeleri 404; landing blog bağlantısı ve sitemap blog URL'leri yok.
- Lintte blog dışındaki mevcut uyarılar ayrıca raporlanır. Tam canlı SEO, Search Console ve müşteri kullanılabilirlik araştırması yapılmadı.

Test komutları: `npm test`, `npm run lint`, `npm run build -- --webpack`, `npx playwright test --config=playwright.blog.config.ts`.
''',encoding='utf-8')
