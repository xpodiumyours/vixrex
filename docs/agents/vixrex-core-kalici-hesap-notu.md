# VIXREX CORE — kalıcı hesap sahipliği (2026-08-26)

Codex'in yarım kalan planının devamı. Plan altı adımdı; bu belge ne
yapıldığını, neye dayandığını ve nasıl geri alınacağını kaydeder.

## Neden gerekti — ölçüm

Canlı veritabanında ölçüldü (tahmin değil):

| Ölçüm | Değer |
|---|---|
| `stores` satır sayısı | 29 |
| `user_id` DOLU olan satır | **0** |
| `auth.users` toplam | 175 (172'si anonim) |
| Kaynak demo vitrindeki ürün | 6 |
| Kiralanan klondaki ürün | **0** |

Yani bugüne kadar hiçbir vitrin hiçbir hesaba bağlanmadı ve kiralanan her
vitrin boş doğuyordu.

## Bulunan dört kırık halka

1. **Sahiplik sorgusu canlıda hiç çalışmıyordu.**
   `AuthService.getStoreForCurrentUser()` `stores` üzerinde doğrudan
   `.eq('user_id', ...)` filtreliyordu. V-09 (`20260818050000`) o kolonun
   SELECT'ini `authenticated`'ten revoke etti; PostgreSQL WHERE'de geçen
   kolon için de SELECT yetkisi arar, sorgunun tamamı 42501 ile düşüyordu.
   `20260820210000` aynı hatayı Keşfet ve `StorePublishedInfoLookupService`
   için düzeltmiş, bu çağrıyı atlamıştı.

2. **`link_store_to_user` çalışma anında patlıyordu.** Gövdesinde
   `pg_catalog.coalesce(...)` vardı — `coalesce` bir parser yapısıdır,
   `pg_catalog` altında böyle bir fonksiyon yoktur. Her çağrı 42883 veriyordu.
   plpgsql gövdesi CREATE anında derlenmediği için migration sorunsuz
   uygulanmış, hata yalnız çağrıda çıkıyordu.

3. **Anonim oturum tuzağı.** Uygulama açılışta herkese anonim oturum açıyor
   (`main.dart _oturumuGuvenceyeAl`). Anonim kullanıcı da Postgres'e göre
   `authenticated` ve `auth.uid()`'i var — eski bağlama fonksiyonu vitrini
   o geçici kimliğe kilitleyebilirdi.

4. **Kiralık token 24 saatlik.** V-15 (`20260824050000`) klon token'ına 24
   saatlik ömür verdi. Sahiplik kalıcı olsa bile ertesi gün vitrin
   düzenlenemez hale geliyordu.

## Ayrıca bulunan regresyon

`20260824050000` (V-15, PR #340) `clone_demo_store_as_draft`'ı yalnız
`edit_token_expires_at` eklemek için `CREATE OR REPLACE` etti — ama gövdeyi
ürün kopyalama **öncesi** sürümden aldı. `20260815000000`'ın eklediği
kategori/ürün kopyalama ve `cloned_from_slug` sessizce düştü. Migration
defteri "uygulandı" diyor, canlıdaki fonksiyon eski. 24 Ağustos'tan beri
kiralanan her vitrin boş doğuyor.

Bu migration iki sürümü birleştirir: ürün/kategori kopyalama geri gelir,
V-15'in 24 saatlik token süresi korunur.

## Yapılanlar

**Veritabanı** — `supabase/migrations/20260826000000_vixrex_core_kalici_hesap_sahipligi.sql`

| Parça | İş |
|---|---|
| `stores_tek_vitrin_per_user` | Kısmi UNIQUE index — tek-vitrin kuralının tek gerçek garantisi |
| `is_permanent_user()` | Anonim oturumu kalıcı hesaptan ayırır |
| `claim_store_for_user()` | Atomik sahiplenme; tek-vitrin + anonim yasağı + token'ı 1 yıla çeker |
| `bootstrap_owner_state()` | "Yeni cihazda açılış": vitrin + kendi edit_token'ı + çalışma taslağı tek çağrıda |
| `rent_demo_for_account()` | Hesaplı kiralama — klon SAHİPLİ doğar, token 1 yıllık |
| `link_store_to_user()` | Eski APK'lar için boolean saran kabuk |
| `clone_demo_store_as_draft()` | Regresyon onarımı (yukarıda) |

**Uygulama**

- `lib/models/owner_bootstrap_state.dart` — `OwnerBootstrapState`, `StoreClaimResult`
- `lib/services/owner_bootstrap_service.dart` — sunucu durumunu okur, cihaza yazar
- `lib/services/demo_rental_service.dart` — hesaplı kiralama
- `AuthService` — `getOwnerState`, `claimStore`, `claimDeviceStore`; kimlik
  bağlandıktan hemen sonra sahiplenme
- `AppRouter.navigateToRentDemo` — hesaplı yol / misafir yolu ayrımı
- `StorePublishedInfoLookupService` — edit_token artık sunucudan da gelebiliyor
- İki repository'deki aynı 42501 hatası düzeltildi

### Ezme kuralı

Cihazdaki taslak sunucudakinden **yeni** ise üzerine yazılmaz. Çevrimdışı
yapılan düzenleme, başka cihazdan giriş yapıldı diye silinmez. Zaman
damgalarından biri okunamıyorsa sunucu kazanır — sunucudaki veri en az bir
kez bilinçli kaydedilmiştir.

## Kapsam dışı kalan

Codex'in 5. adımı — "Next.js SEO landing/Keşfet girişlerini hesaplı Flutter
kiralama akışına yönlendir" — **yapılamadı**: yönlendirilecek yüzey henüz
yok. Next tarafında ne platform ana sayfası ne `/kesfet` dizini var
(açık iş #344). O iş kapandığında bu adım tek bir yönlendirme eklemekten
ibaret olacak; sözleşme tarafı hazır.

## Doğrulama

- Migration'ın tamamı canlı veritabanında **geri alınan** işlemlerde
  çalıştırıldı (`begin; … rollback;`): anonim sahiplenemiyor, tek-vitrin
  kuralı tutuyor, token 1 yıla uzuyor, sırlar sızmıyor, klon 6 ürün +
  3 kategori ile doğuyor, aynı işlemde ikinci klon çalışıyor.
- `flutter analyze lib/` — temiz.
- `test/vixrex_core_sahiplik_test.dart` — 21 test, hepsi geçiyor.
- Etkilenen mevcut testler (auth, hesap bağlama, anonim oturum, rota
  sözleşmesi, misafir yayın token'ı, kritik akış, keşfet) — 24 test geçiyor.

**Ölçülmedi:** gerçek cihazda uçtan uca akış. Migration canlıya
uygulanmadan APK/web'de test edilemez.

## Geri dönüş

Migration henüz canlıya uygulanmadıysa: dosyayı silmek yeterli, uygulama
kodu eski RPC'leri çağırmaya devam etmez çünkü kod da aynı commit'te.
Tamamını geri almak için commit'i revert et.

Canlıya uygulandıysa geri dönüş SQL'i:

```sql
BEGIN;
DROP INDEX IF EXISTS public.stores_tek_vitrin_per_user;
DROP FUNCTION IF EXISTS public.bootstrap_owner_state();
DROP FUNCTION IF EXISTS public.claim_store_for_user(text);
DROP FUNCTION IF EXISTS public.rent_demo_for_account(text);
DROP FUNCTION IF EXISTS public.is_permanent_user();
-- link_store_to_user ve clone_demo_store_as_draft'ı 20260824050000'deki
-- gövdelerine geri almak gerekir; DROP ETME, o migration'ı yeniden çalıştır.
COMMIT;
NOTIFY pgrst, 'reload schema';
```

Dikkat: index'i düşürmek tek-vitrin garantisini kaldırır. Sahiplenmiş
satırlar `user_id` doluyken kalır, veri kaybı olmaz.

## Sıradaki adım

Migration canlıya uygulanmalı. Uygulandıktan sonra gerçek akış tek seferde
doğrulanmalı: Keşfet → Kirala → (giriş yapılmışsa) vitrin hesapta mı,
ürünleri geldi mi, başka cihazdan girişte vitrin ve taslak açılıyor mu.
