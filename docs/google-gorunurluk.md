# Google Görünürlüğü ve Ürün Konumu

> Ürün kararı ve plan sonrası iş listesi. Karar tarihi: 2026-08-05.
> Bu bir kural değil; uygulanınca `implementation_plan.md`'ye adım olarak girer.

## 1. Hedef

Bir müşteri Google'da veya Google Lens ile bir ürün aradığında, **"bu ürün sana en yakın şu esnafta var"** sonucunun çıkması. Vitrin sahibi böylece Instagram'da göremediği müşteriyi görür.

**Hedef uygulama içi arama değildir.** Kullanıcıların VixRex uygulamasını açıp ürün araması beklenmiyor. Trafik Google'dan gelecek.

## 2. Bugünkü eksik — küçük ve net

Ürün sayfasının Google'a gönderdiği etikette satıcı bilgisi yalnız isimden ibaret:

```
offers.seller = { "@type": "LocalBusiness", name: <mağaza adı> }
```

Adres yok, ilçe/il yok, koordinat yok. Google "bu ürün nerede satılıyor" sorusuna cevap bulamıyor.

**Eklenecek:** satıcıya `address` (özellikle `addressLocality` = ilçe, `addressRegion` = il) ve `geo` (enlem/boylam). Mağazada üçü de zaten var (`address`, `district_name`, `province_name`, `latitude`, `longitude`); yalnız ürün etiketine bağlanmamış.

Dosya: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`

Not: mağaza sayfasındaki `LocalBusiness` etiketinde de `addressLocality` ve `addressRegion` eksik; yalnız `streetAddress` ve `addressCountry` var. Yerel aramanın en önemli iki alanı bunlar.

## 3. Üç kademe — sıra önemli

| Kademe | Ne sağlar | Kim yapar | Zorluk |
|---|---|---|---|
| **1. Ürün etiketine adres + koordinat** | Ürün sayfası aramada konumuyla çıkar | biz | küçük |
| **2. Her esnafın Google İşletme Profili** | "Yakınımdaki" sonuçlarına girer | esnaf; `google_business_link` kolonu hazır | esnafın işi |
| **3. Google Merchant Center ürün akışı + yerel envanter** | **Lens ve Alışveriş'te "yakınında var" çıkar** | biz | büyük, ayrı entegrasyon |

**Dürüst not:** Lens'in "yakınındaki dükkânda var" demesi ağırlıklı olarak 3. kademeden gelir, sayfadaki etiketten değil. Ama 1 ve 2 olmadan 3 çalışmaz — Merchant Center ürün sayfasını doğrular. Bu yüzden sıra atlanamaz.

## 4. Ürün konumu — nasıl doldurulacak

**Karar: her ürün kartında konum bulunur.**

Uygulama biçimi — esnafı yormadan:

- Ürün eklenince konum **mağazanın konumundan otomatik gelir**.
- Esnaf isterse o üründe değiştirebilir: "depodan kargo", "yalnız 2. şubede" gibi.
- Zorunluluk korunur (her üründe konum vardır), ama esnaf 40 ürün için 40 kez aynı şeyi yazmaz.

**Sebep:** ürünün konumu genelde mağazanın konumudur. Her ürün için ayrı sormak, kırk ürünü olan esnafı yorar ve yarıda bıraktırır.

Mevcut durum: `products.fulfillment_region` kolonu var, Flutter ürün düzenleyicide "Teslim bölgesi (isteğe bağlı)" olarak duruyor, müşteri ürün kartında gösteriliyor. Bugün **serbest metin ve isteğe bağlı**. Yapılacak: mağaza konumundan varsayılan doldurma ve zorunlu hâle getirme.

## 5. Ne zaman yapılmalı

**Plan bittikten sonra.** Sebebi: bu özellik dolu ve doğru içeriğe bağlıdır. Vitrin düzenleme tamamlanmadan içerik dolmaz, içerik dolmadan Google'da gösterilecek bir şey olmaz.

**İstisna:** 2. bölümdeki etiket düzeltmesi küçüktür ve içerikten bağımsızdır; Commit 10 sırasında birlikte yapılabilir.

## 6. Gerçeklik notu

Bu belge yazıldığında sistemdeki 105 vitrinin tamamı geliştiricinin açtığı **test hesabıdır**; gerçek kullanıcı yoktur. Google görünürlüğü ancak gerçek işletmeler yayına girdikten sonra anlam kazanır.

İlk gerçek işletme: geliştiricinin babasının giyim dükkânı (kategori: `giyim`).

**Ayrıca:** yayına çıkmadan önce test vitrinlerinin silinmesi veya gizlenmesi gerekir. Seed edilmiş demo vitrinlerde uydurma değerlendirme puanları vardır (`rating_score`, `review_count`); gerçek kullanıcılarla yan yana listelenmemelidirler.
