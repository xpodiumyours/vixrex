# Katman 2 — Merkezi Blog Kütüphanesi LOCK

Durum: **LOCK tamamlandı. Kullanıcı BUILD için devam onayı verdi.**

## Değişmez sınırlar

1. `vixrex_blog_articles` merkezi makale tablosu genişletilir; ikinci merkezi makale tablosu açılmaz.
2. `store_articles` Katman 2'de değiştirilmez.
3. Sektör kaynağı yalnız `shared/business_categories.json` içindeki 19 kanonik ID'dir.
4. Konum kaynağı mevcut Vixrex il/ilçe omurgasıdır; yeni şehir veritabanı açılmaz.
5. Public taslak/yayın RLS davranışı korunur.
6. Public blog mevcut `lp-*` Vixrex tasarım dilinde kalır; Keşfet, owner shell, Kirala ve Asistan kapsam dışıdır.
7. İlgili yazılar referans bütünlüğü olan ayrı relation tablosunda tutulur.
8. Görsel sıkıştırma çekirdeği mevcut `gorselSikistir.ts` ile aynı 1600px / kalite 82 standardını kullanır; owner-upload yetki modeli merkezi blog için kullanılmaz.
9. Katman 3 vitrine yazı çekme ve Katman 4 Asistan komutları bu BUILD'e alınmaz.

## Kanonik konu aileleri

- `google-yerel-gorunurluk` — Google ve yerel görünürlük
- `dijital-vitrin-web` — Dijital vitrin ve web görünümü
- `urun-hizmet-fiyat` — Ürün, hizmet ve fiyat/katalog
- `musteri-iletisim-satis` — Müşteri iletişimi, paylaşım ve satış
- `randevu-isletme-yonetimi` — Randevu ve işletme yönetimi
- `vixrex-kullanimi` — Vixrex kullanımı ve yayınlama
- `dijital-carsi-baglantilar` — Dijital Çarşı ve işletme bağlantıları

## Kanonik kullanım amaçları

Konu ile amaç ayrı tutulur. Amaç, yazının esnafa hangi sonucu sağlamaya çalıştığını belirtir.

- `gorunurluk-artirma` — Dijital/yerel görünürlüğü artırma
- `musteri-kazanma` — Yeni müşteriye ulaşma
- `guven-artirma` — İşletme bilgisini daha güvenilir ve anlaşılır sunma
- `iletisim-satis` — İletişim ve satışa dönüşümü kolaylaştırma
- `isletme-yonetimi` — Günlük işletme/randevu işini düzenleme
- `vixrex-kullanimi` — Vixrex özelliklerini doğru kullanma
- `yerel-isbirligi` — Diğer işletmelerle bağlantı ve yerel işbirliği kurma

## Konum kapsamı

- `national` — Türkiye geneli
- `province` — bir veya birden fazla il
- `district` — il + ilçe hedefi

İl için mevcut `province_code`; ilçe için il koduyla birlikte mevcut Vixrex ilçe adı kullanılır.

## Etiket ve kaynak sınırı

- Etiketler yardımcı sinyaldir; ana konu veya sektör yerine geçmez.
- Makale başına en fazla 8 normalize etiket.
- Kaynak/provenance bilgisi merkezi makalede tutulur; taslaklar public'e sızmaz.

## BUILD sırası

1. Shared blog taksonomi sözleşmesi.
2. Merkezi DB metadata + relation migration.
3. Public veri erişim katmanını metadata ile genişletme.
4. Kontrollü konu/sektör katalog route'ları ve blog katalog UX'i.
5. Teknik VERIFY.

Gerçek kullanıcı ekran kabul testi planın final E2E kapısında yapılacaktır.
