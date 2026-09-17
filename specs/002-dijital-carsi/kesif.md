# Keşif

İSTEK: "Dijital çarşı için vitrinlerin birbirine dijital ve görünüm olarak bağlantılarını kurabilmeleri ve vitrin hediyeleşme sistemi istiyorum."

## Bugün ne var

ÖLÇÜLDÜ: supabase/migrations/00000000000000_temel_sema_bulut_20260805.sql — vitrin tek tabloda tutuluyor; iki vitrini birbirine bağlayan hiçbir sütun, ilişki veya tablo yok.
ÖLÇÜLDÜ: public_web/src/lib/explore.ts — keşif, yayındaki en son güncellenmiş 50 vitrini düz liste olarak getiriyor; gruplama, komşuluk veya çarşı kavramı yok.
ÖLÇÜLDÜ: public_web/src/components/kesfet/KesfetIcerik.tsx — "favoriler" yalnız ziyaretçinin kendi tarayıcısında duruyor, kaydedilmiyor ve vitrinleri birbirine bağlamıyor.
ÖLÇÜLDÜ: public_web/src/app/v/[slug]/VitrinProfileView.tsx — vitrin sayfası sabit bölüm sırasıyla tek başına çalışıyor; başka bir vitrine açılan hiçbir yer yok.
ÖLÇÜLDÜ: shared/vitrin_alanlari.json — esnafın düzenleyebildiği 46 alanın hiçbiri tema, renk veya görünüm değil.
ÖLÇÜLDÜ: lib/theme/vitrin_theme_preset.dart — tema altyapısı yazılmış ama kullanılmıyor; vitrin teması esnafa sorulmadan sabit atanıyor.
ÖLÇÜLDÜ: public_web/src/lib/paytr.ts — aylık ücret sunucu tarafında sabit; ödeme kimlikleri ortamda yoksa istek reddediliyor, yani ödeme canlıda henüz çalışmıyor.
ÖLÇÜLDÜ: public_web/src/app/api/paytr/create-link/route.ts — ödeme her zaman vitrinin kendi sahibinin oturumuyla başlıyor; başkası adına ödeme kavramı yok.
ÖLÇÜLDÜ: supabase/migrations/20260818050000_fix_stores_public_user_id_exposure.sql — vitrin sahibinin kimliği herkese açık okumadan bilerek çıkarılmış; bağ ve hediye kayıtları bunu bozmadan kurulmalı.

## Gelişim nereden başlar

BAŞLANGIÇ: Veriden. Bugün iki vitrini birbirine bağlayan hiçbir kayıt yok; çarşı, komşuluk, ortak görünüm ve hediyeleşmenin tamamı bu eksik halkanın üstüne kurulur. Ekrandan veya görünümden başlamak, kaynağı olmayan veriyi ekranda tasarlamak olur.

## Nerede biter

BİTİŞ: Bir esnaf başka bir vitrini çarşı komşusu olarak eklediğinde, karşı taraf kabul ettiğinde, iki vitrin birbirinin sayfasında aynı çarşı imzasıyla göründüğünde ve ziyaretçi birinden diğerine tek dokunuşla geçebildiğinde. Hediyeleşmenin bitişi ayrıdır ve ödeme canlıda çalışmadan tanımlanamaz.

## Ne gözükecek

GÖRÜNEN: Vitrin sayfasında "Çarşı komşuları" bölümü — komşu vitrinlerin adı, kategorisi, küçük görseli ve doğrudan bağlantısı. Esnaf panelinde komşu arama, istek gönderme ve gelen isteği kabul veya ret ekranı. Keşifte aynı çarşıya ait vitrinlerin birlikte görünmesi.

GÖRÜNÜM: Komşu bölümü mevcut bölüm düzeninin dilinde olur — aynı başlık biçimi, aynı kart ölçüsü, gizlenebilir bölüm anahtarı. Üç hâl baştan tarif edilir: komşusu yokken bölüm hiç görünmez, istek beklerken esnafa görünür ziyaretçiye görünmez, kabul edilince herkese görünür.

## Kim ne kazanır

ESNAF: Tek başına bir vitrin yerine, birbirine ziyaretçi gönderen bir komşuluğun içinde yer alır; yanındaki dükkânın müşterisi ona da uğrar.
VIXREX: Vitrinler arası ilk gerçek ilişki kurulur; keşif düz listeden çarşıya döner ve platformun tutunma sebebi tek tek vitrinler olmaktan çıkar.
TÜKETİCİ: Bir vitrini gezerken aynı çarşıdaki diğer dükkânları da görür; arama yapmadan komşuya geçer, gerçek çarşıda olduğu gibi dolaşır.

## Etkilenen yüzeyler

YÜZEYLER: Veritabanı (yeni ilişki tablosu ve erişim kuralları), Next.js vitrin sayfası, keşif sayfası, Flutter paneli, web'deki Vixrex Asistan paneli, mesaj kataloğu ve otomatik kontroller.

## Dokunulmayacak

KAPSAM DIŞI: Mevcut bölüm sırası ve vitrin şablonu; ürün kataloğu; ödeme tutarı ve kiralama akışı; vitrin sahibinin kimliğini herkese açık okumadan çıkaran güvenlik düzenlemeleri.

## Karar

KARAR SORUSU: Çarşı komşuluğu nasıl kurulur — esnaf esnafı davet edip karşı taraf kabul ederek mi, aynı konumdakiler kendiliğinden mi, yoksa aynı kategoridekiler kendiliğinden mi?
ONAY: bekliyor
