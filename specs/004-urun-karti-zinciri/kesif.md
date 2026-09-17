# Keşif

İSTEK: "Önce ürün kartlarımızdaki eksik, ters gelişimde deneyelim bu gelişim zincirini, bakalım ne hatalar bulacak."

## Bugün ne var

Zincir şu sırada olmalı: ürün alan şablonu → esnaf formu → doğrulama → Supabase
kayıt → sahip düzenleme → görünürlük kapısı → public detay → ürün kartı.
Ölçüm, halkaların kurulu olduğunu ama üç yerde birbirine bağlanmadığını gösteriyor.

ÖLÇÜLDÜ: public_web/src/app/v/[slug]/ProductCatalog.tsx — kart ürün detay adresini taşıyor ama tıklamada bu adres iptal edilip hızlı bakış penceresi açılıyor; detay sayfasına normal tıklamayla ulaşılamıyor.
ÖLÇÜLDÜ: public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx — ikinci bir detay uygulaması duruyor ve hiçbir yerden çağrılmıyor.
ÖLÇÜLDÜ: public_web/src/lib/productCardPresentation.ts — kart için alan seçen fonksiyon üretimde hiçbir ekrandan çağrılmıyor; tek kullanıcısı testi.
ÖLÇÜLDÜ: lib/config/product_image_policy.g.dart — dosya kendini "üretilmiş" ilan ediyor ve kaynak olarak shared/product_image_policy.json gösteriyor; o kaynak da üreticisi de depoda yok.
ÖLÇÜLDÜ: public_web/src/lib/productImagePolicy.ts — görsel ölçü kuralı tanımlı ama hiçbir yerden çağrılmıyor; Flutter tarafında da çağrı yok.
ÖLÇÜLDÜ: public_web/src/components/owner/OwnerProductManager.tsx — web sahip panelinde ürün görünürlüğü hiç geçmiyor; aynı işlemi Flutter paneli yapabiliyor.
ÖLÇÜLDÜ: supabase/migrations/20260728000003_kiralik_vitrin_seed.sql — kiralık vitrin tohumunda 45 dış görsel adresi var; sunucu kuralı dış adresi reddederken tohum bu yoldan giriyor.
ÖLÇÜLDÜ: public_web/src/app/api/products/route.ts — sunucu tarafında ad ve açıklama için uzunluk sınırı yok; 80 ve 500 yalnız ekran sınırı.
ÖLÇÜLDÜ: public_web/src/lib/productStructuredData.ts — arama motoruna çıkan marka alanına ürünün markası değil mağaza adı yazılıyor.

## Gelişim nereden başlar

BAŞLANGIÇ: Okuma yüzünden. Detay sayfası ve kart kurulu ama birbirine bağlı değil; önce kullanıcının detaya ulaşabilmesi ve ölü ikinci uygulamanın kaldırılması gerekiyor. Veri ve form halkaları zaten çalışıyor.

## Nerede biter

BİTİŞ: Ziyaretçi karta tıkladığında ne göreceği kararlaştırılmış ve tek bir yoldan gidiyorsa, kartta gösterilen alanları seçen mekanizma gerçekten kullanılıyorsa, görsel kuralı üç yerde değil tek yerde duruyor ve gerçekten uygulanıyorsa, esnaf ürününü iki panelde de aynı şekilde gizleyebiliyorsa biter.

## Ne gözükecek

GÖRÜNEN: Ziyaretçi için karttan detaya giden tek ve çalışan bir yol; esnaf için web panelinde de görünürlük anahtarı; arama sonuçlarında ürünün kendi markası.

GÖRÜNÜM: Mevcut kart düzeni ve hızlı bakış penceresi korunur; yalnız tıklamanın nereye gittiği ve hangi bilginin nerede durduğu netleşir.

## Kim ne kazanır

ESNAF: Girdiği kategori alanları gerçekten görünen bir sayfaya çıkar; ürünü web panelinden de gizleyebilir.
VIXREX: Ölü kod, kullanılmayan fonksiyon ve üç kopya kural temizlenir; testlerin koruduğu şey ile kullanıcının gördüğü şey aynı olur.
TÜKETİCİ: Ürüne tıkladığında tutarlı bir sayfa görür; arama sonucunda doğru marka ile karşılaşır.

## Ne korunacak

KORUNACAK: Ürün verisinin tek kaynağı olan products tablosu yolu, esnaf formunun bugünkü alanları, iki panelin alan eşitliği ve mevcut hızlı bakış penceresinin çalışması. Bunların hiçbiri bu işlerde bozulmayacak.

## Etkilenen yüzeyler

YÜZEYLER: Next.js vitrin ve ürün detay sayfası, web sahip paneli, Flutter ürün yönetimi, görsel politikası dosyaları, kiralık vitrin tohumu, arama motoru çıktısı.

## Dokunulmayacak

KAPSAM DIŞI: Ürün alan şablonu ve kategori türetme, products tablosunun yapısı, ödeme ve yayın akışı, giriş ve yetkilendirme.

## Karar

KARAR SORUSU: yok — karta tıklayınca hızlı bakış açılır; ayrı sayfa açılmaz. Furkan'ın kararı, 2026-09-17.
ONAY: bekliyor
