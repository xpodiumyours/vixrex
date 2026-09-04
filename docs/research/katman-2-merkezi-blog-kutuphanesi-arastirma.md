# Katman 2 — Merkezi Blog Kütüphanesi Araştırması

Durum: **RESEARCH başladı — henüz tamamlandı tiki yok.**

## 1. Mevcut gerçeklik

- `vixrex_blog_articles` bugün yalnız temel yazı alanlarını taşıyor: slug, başlık, özet, içerik, kapak görseli, durum, okuma süresi ve tarihler.
- Katman 2 için gereken konu, sektör, yer, kullanım amacı, etiket, kaynak/provenance ve ilgili-yazı ilişkileri henüz veri modelinde yok.
- Public veri erişim katmanı da yalnız temel alanları seçiyor.
- Blog ana sayfası şu an tüm kartları tek tip `Rehber` olarak gösteriyor; kategori/konu filtresi veya arama yok.

## 2. Vixrex kategori kaynağı

- Yeni bir işletme kategori listesi icat edilmemeli.
- `shared/business_categories.json` mevcut tek kanonik kaynaktır.
- Burada 19 kategori vardır ve Katman 2 sektör eşleşmesi bu kimlikleri yeniden kullanmalıdır.
- Böylece blog kütüphanesi ile vitrin kategorileri arasında ikinci bir sözlük oluşmaz.

## 3. Yer/konum bulgusu

- `stores` tablosunda `district_code` ve `district_name` mevcut.
- Ayrı, doğrulanmış bir `city`/`province` alanı bu ilk taramada bulunmadı.
- Bu nedenle şehir/ilçe taksonomisi henüz kilitlenmemeli; mevcut konum kaynağının tamamı araştırılmadan yeni şehir sözlüğü eklenmeyecek.

## 4. Görsel kalite bulgusu

Vixrex'in mevcut sunucu görsel hattı zaten ortak standart taşıyor:
- uzun kenar en fazla 1600 px
- kalite 82
- 1 MB üzeri durumda yedek sıkıştırma
- küçük görseller büyütülmüyor
- EXIF taşınmıyor
- Flutter ve web aynı parametreleri kullanıyor

Katman 2 blog görselleri için ayrı, çelişen bir sıkıştırma standardı oluşturulmamalı. Blog kapak yükleme hattı kurulursa mevcut `gorselSikistir.ts` davranışını yeniden kullanması araştırılacak.

## 5. SEO / bilgi mimarisi araştırma bulgusu

Google Search Central güncel rehberleri iki önemli sınır koyuyor:
- Kategori/alt kategori gibi gerçek bağlantılar, sayfalar arası ilişkiyi anlamaya yardımcı olur.
- Çok sayıda URL-parametreli filtre kombinasyonu gereksiz/sonsuz tarama alanı oluşturabilir.

Bu nedenle ilk güvenli yaklaşım:
- indekslenebilir, anlamlı ana konu/sektör sayfaları kontrollü route'lar olsun;
- serbest filtre kombinasyonlarının her biri ayrı SEO sayfasına dönüşmesin;
- iç bağlantılar merkezi blog → konu/sektör → yazı zincirini açık taşısın.

## 6. Görsel SEO doğrulaması

Google güncel Image SEO rehberi:
- yüksek kaliteli ama optimize edilmiş görseller,
- responsive sunum,
- standart `<img>`/`picture` kullanımı,
- anlamlı `alt` metni,
- içerikle ilgili ve temsil edici ana görsel
öneriyor.

Vixrex'te exact piksel/kalite standardı Google'dan değil mevcut Vixrex medya hattından alınacak; Google araştırması yalnız keşfedilebilirlik ve sunum kurallarını doğrular.

## 7. Şimdilik kilitlenebilenler

- Sektör kaynağı: mevcut 19 kanonik Vixrex kategorisi.
- Merkezi yazı tablosu ayrı kalacak; `store_articles` ile karıştırılmayacak.
- Taksonomi makine tarafından sorgulanabilir olacak.
- Serbest filtre URL patlaması oluşturulmayacak.
- Görsel kalite hattı mevcut Vixrex 1600/82 standardıyla uyumlu olacak.

## 8. Araştırma tamamlanmadan kilitlenmeyecekler

- Bilgi türlerinin kesin sayısı.
- Konu ana kategorilerinin kesin isim ve sayısı.
- Şehir/ilçe modelinin kesin yapısı.
- Etiketlerin serbest metin mi kontrollü sözlük mü olacağı.
- İlgili-yazı ilişkisinin kolon mu ayrı ilişki tablosu mu olacağı.
- Blog kapaklarının oranı ve görsel yükleme UX'i.

## 9. Sonraki RESEARCH işi

1. Vixrex'in mevcut konum/district kaynağını tam izle.
2. Mevcut `store_articles` konu/şehir/SEO alanlarını incele; yeniden kullanılabilecek kavramları ayır.
3. Blog bilgi türleri için gerçek esnaf kullanım senaryolarını mevcut Vixrex akışlarından çıkar.
4. Görsel yükleme/depo yolunun blog için yeniden kullanılabilirliğini doğrula.
5. Sonuçta Katman 2 için **UYGUN / UYGUN AMA ŞARTLI / UYGUN DEĞİL** kararı ver.
