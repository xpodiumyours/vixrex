# Ürün kartı çalışması — devir belgesi

> 2026-09-15. İşi devralan ajan buradan devam eder.
> Kaynak dal: `work/product-live-ready-20260914` (PR #489) — **merge edilmedi,
> referans olarak duruyor, silinmeyecek.**

## GÜNCEL DURUM (2026-09-15, son güncelleme)

**Kod main'de ve doğrulandı. Canlıya ÇIKMADI.**

main'in birleşmiş hâli yerelde baştan koşuldu:

| Kapı | Sonuç |
|---|---|
| `flutter analyze` | temiz |
| `flutter test` | 737 test geçti |
| `tsc --noEmit` | temiz |
| `vitest run` | 1513 test geçti |
| `eslint` | 0 hata (3 uyarı, önceden vardı) |
| `next build` | başarılı |

**Canlı neden güncel değil:** Vercel ücretsiz plan derleme kotası doldu.
`vixrex-public` projesinde üretime çıkan tek dağıtım commit `263bd237` — yani
yalnız #491 (ölü kod temizliği). #492, #493, #494, #495 main'de ama canlıda
DEĞİL. Ürün kartı bu yüzden eski görünüyor.

**Yapılacak tek şey:** Vercel panelinde `vixrex-public` → Deployments →
`vixrex-public-q0lzzdzpq` (mesajı "feat(urun): Flutter tarafini zengin urun
modeline esitle") → **Promote to Production**. Bu derleme READY durumda ve beş
fazın tamamını içeriyor; yeni derleme gerektirmez, kota yemez. Alternatif:
kota sıfırlanınca main'e bir commit atmak.

**Canlı doğrulama tuzağı:** sayfada `Hızlı` kelimesiyle arama YAPMA — "Hızlı
Teknik" adlı vitrine denk gelip yanlış olumlu veriyor. `ProductQuickView`
veya `Barkod` gibi yalnız yeni kodda geçen bir ize bak.

**CI durumu:** Beş PR main'e inerken şu üç iş HİÇ koşmadı — Flutter analiz/test,
şema sapma kontrolü, GRANT güvenlik bekçisi. Koşan ve geçen dört kapı:
Değişiklik yüzeyi, Secret sızıntı taraması, Supabase auth kontrolü, Vercel
derlemesi. Üç işin koşmama sebebi `subosito/flutter-action`'ın self-hosted
Windows runner'da düşmesiydi; PR #497 bunu runner'da kurulu Flutter 3.44.4'e
bağlıyor. #497 inince bu üç kapı ilk kez gerçekten koşacak ve beş PR geriye
dönük doğrulanmış olacak.

---

## Karar: dal referans, main gerçeklik

Dev dal 100 dosya, +13.966/−3.368, 11 migration. Tek parça merge edilmedi;
içinden fazlar tek tek alındı. Sebep: dalda canlıyı kıran dört davranış vardı
(aşağıda) ve o dalda CI hiç gerçekten koşmamıştı.

## main'e inen ve CANLIDA olan (2026-09-15)

| PR | Ne |
|---|---|
| #491 | Erişilemez sahip paneli dalı + kullanılmayan katalog prop'u temizliği |
| #492 | Zengin ürün kartı + hızlı bakış + zengin ürün detay sayfası (okuma yolu) |
| #493 | Esnaf zengin alan girişi + asgari çekirdek migration |
| #494 | Kategori şablonları esnaf yönetiminde |
| #495 | Flutter tarafı zengin ürün modeline eşitlendi |

Canlıya uygulanan migration: `20260915010000_product_rich_core_minimal`.
Doğrulandı: şablon kolonu var, 38 kategori `generic`, dört yeni fonksiyon
canlıda, görsel tetikleyicisi **kurulmadı**, 68 ürün yerinde ve yayında.

Zengin alanlar canlıda henüz boş; esnaf doldurduğu an kartta ve detayda görünür.

## Bilerek ALINMAYAN dört davranış — geri getirilmemeli

1. **Kategori `service` şablonuna geçince marka/barkod/stok/özellik silinmesi.**
   Kullanıcı verisini sessizce siliyor, onaylanmış bir ürün kararı değil.
   Hem `api/products/route.ts` hem `product_category_metadata_service.dart`
   tarafında kaldırıldı. Bunu şart koşan üç Flutter testi gerçek davranışa
   göre düzeltildi.
2. **Şablon dışı kalan ürün özelliklerinin düzenlemede silinmesi.**
3. **`metadata.templateKey` dolu eski ürünün kalıcı 422 alması** — düzenlenemez
   hale geliyordu.
4. **En az 3 görsel kuralının veritabanı tetikleyicisinde olması.**
   Canlıdaki 68 ürünün TAMAMI 1–2 görselli; tetikleyici kurulursa esnaf mevcut
   ürününün fotoğrafını değiştiremez. Kural kaybolmadı: Flutter'da
   `ProductImagePolicy.validateForPublish` olarak duruyor, yayın kapısına
   bağlanmayı bekliyor. Üst sınır 11 zaten uygulanıyor.

## Kalan iki adım

**A — Toplu yükleme (Excel/CSV/XML yeni alanları taşısın)**

Daldan alınacaklar:
`public_web/src/app/api/products/batch/route.ts`,
`public_web/src/components/owner/BulkProductUpload.tsx`,
`lib/services/bulk_product_upload_service.dart`,
`lib/services/xml_product_upload_service.dart`,
`lib/screens/bulk_product_upload_screen.dart`,
`lib/controllers/bulk_product_upload_controller.dart`,
`lib/widgets/xml_upload_dialog.dart`

Dikkat: `batch/route.ts` daldaki halinde tek kötü satır yüzünden 100'lük
yüklemenin tamamını 422 ile iptal ediyor; satır atlanacak şekilde düzeltilmeli.
Ayrıca `product_management_sheet.dart` içindeki `_openBulkUpload` çağrısı bu
fazda mevcut imzaya uyarlandı; toplu yükleme ekranı gelince `onSaved` geri
dönüş tipi tekrar `Future<bool>` olacak.

**B — Görsel kalite + yayın kapısı**

Daldan alınacaklar: `lib/services/store_publish_validator.dart`,
`lib/services/store_publish_service.dart`,
`lib/services/image_optimization_service.dart`,
`lib/services/store_shelf_upload_service.dart`,
`public_web/src/lib/productImageCleanup.ts`,
`public_web/src/lib/gorselSikistir.ts`,
`public_web/src/app/api/product-image-upload/route.ts`

Kurallar: en az 3 görsel YALNIZ yayın kapısında uygulanacak, veritabanı
tetikleyicisi olarak DEĞİL. Görsel temizlik servisi dosya siliyor; yalnız
başka üründe kullanılmayan ve Vixrex yükleme yolundan gelmiş görseller
silinmeli, dış CDN ve mağaza görselleri silinmemeli. Bu fazın kabul kanıtı
silmenin YAPILMADIĞI durumları göstermektir.

## Nasıl çalışılır

Her faz için `origin/main`'den ayrı worktree aç, daldan yalnız o fazın
dosyalarını `git checkout work/product-live-ready-20260914 -- <yollar>` ile al,
eksik bağımlılıkları tip kontrolü/analiz söyleyene kadar ekle, kapıları koş,
kendi PR'ını aç. Ana klasörde (`C:\Projects\vixrex`) çalışma; orada başka ajan
olabilir.

Kapılar: `public_web` içinde `npm run typecheck`, `npx vitest run`,
`npm run lint`, `npm run build`; kökte `flutter analyze`, `flutter test`.
Son ölçüm: 1513 web testi, 737 Flutter testi yeşil.

## Bilinen altyapı sorunları

- CI'daki **Flutter — analiz ve testler** ve **Şema üretim hattı** işleri
  self-hosted runner'da "Setup Flutter" adımında düşüyor. Kod sorunu değil.
- Runner daha önce Git Bash yerine WSL bash kullanıyordu; `C:\vixrex-runner\.env`
  dosyasına doğru PATH yazılarak düzeltildi. Yeniden başlatılırken eski oturum
  çakışması verirse birkaç dakika sonra kendiliğinden bağlanır.
- `supabase_schema.sql` kök dosyası 2026-08-16'dan beri güncellenmedi;
  veritabanı gerçeği `supabase/migrations/` ve canlı Supabase'dir.

## Tek veri kaynağı — açık borç

`shared/product_attribute_schema.json` iki taraftan da okunuyor (doğru), ama
sayısal sınırlar ve enum etiketleri hâlâ elle kopyalanmış. Diğer ortak
şemalarda olan "JSON'dan üret → sapma var mı" CI kapısı ürün şeması için
kurulmadı. Yeni şablon veya alan eklenmeden önce bu kapı kurulmalı.
