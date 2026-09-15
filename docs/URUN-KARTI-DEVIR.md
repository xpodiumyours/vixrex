# Ürün kartı çalışması — devir belgesi

> 2026-09-15. İşi devralan ajan buradan devam eder.
> Kaynak dal: `work/product-live-ready-20260914` (PR #489) — **merge edilmedi,
> referans olarak duruyor, silinmeyecek.**

## İLERLEME KAYDI — 2026-09-15

### PR #500 — Flutter toplu yükleme zengin alan eşitliği

Dal: `work/product-bulk-rich-flutter-20260915` — güncel `main`
`1304624820f98b9e1455dc488c1fe8f0525492fb` üzerinden açıldı.

Kapsam yalnız iki dosya:
- `lib/services/bulk_product_upload_service.dart`
- `test/bulk_product_upload_rich_parity_test.dart`

#489'dan kurtarılan gelişmeler: Excel/CSV içe aktarmada marka, barkod/GTIN,
SKU, stok adedi, çoklu görsel ve rich metadata v2.

#489'dan aynen ALINMAYAN / düzeltilen davranışlar:
- Minimum 3 görsel içe aktarma sırasında zorunlu yapılmadı; bu kural yalnız
  yayın kapısına aittir.
- Görselsiz satır `imageUrls.first` nedeniyle çökmeyecek; `imagePath` null kalır.
- Geçersiz görsel adresi sessizce atılmayacak; satır hatası olarak döner.
- `Stok=10`, içinde `0` bulunduğu için yanlışlıkla `Tükendi` sayılmayacak.
- SKU barkod alanına yazılmayacak.

Eklenen hedef testler bu davranışları kapsıyor. PR açıldıktan sonraki ilk durum:
GitHub CI run `34930679144` queued; Vercel iki proje için günlük build-rate-limit
nedeniyle failure gösteriyor. Bu nedenle #500 **henüz merge hazır değil** ve
CI/test sonucu görülmeden main'e indirilmeyecek.

Sonraki toplu-yükleme alt parçaları #500 merge edildikten sonra yeni `main`
üzerinden açılacak. Önceden ayrı branch/PR açılmayacak; bu sırada yalnız fark
incelemesi yapılabilir.

## GÜNCEL DURUM — doğrulanmış gerçeklik

### 1. Kod / main

Ürün kartı fazları #491–#495 `main` içinde. Güncel `main` başı
`1304624820f98b9e1455dc488c1fe8f0525492fb` (`chore: urun karti calismasini
uretime al`). Bu commit **boş commit**: önceki `a4e1c8bc...` ile karşılaştırmada
değişen dosya yok. Dolayısıyla bu commit ürün kodunu değiştirmedi veya geri
almadı; yalnız yeni dağıtım/CI tetiklemiş oldu.

Birleşmiş ürün kodu daha önce yerelde baştan koşturuldu:

| Kapı | Yerel sonuç |
|---|---|
| `flutter analyze` | temiz |
| `flutter test` | 737 test geçti |
| `tsc --noEmit` | temiz |
| `vitest run` | 1513 test geçti |
| `eslint` | 0 hata (3 uyarı, önceden vardı) |
| `next build` | başarılı |

Bu tablo **yerel doğrulamadır; CI doğrulaması değildir.**

### 2. Vercel / production durumu

Önceki durumda `vixrex-public` üretimi `263bd237` (#491) üzerindeydi ve
#492–#495 production'a çıkmamıştı. Daha sonra `main`e boş commit
`1304624820...` atıldı. GitHub üzerindeki Vercel kontrolleri bu commit için
hem `vixrex-public` hem `vixrex-app` tarafında **SUCCESS** durumda.

Ancak yalnız bu check sonucu production aliasının gerçekten bu commit'e
bağlandığını kanıtlamaz. Bağlı Vercel erişiminde deployment listesi 403 verdiği
için production aliası bağımsız olarak doğrulanamadı. Bu nedenle bu belgede
şu iki cümleden hiçbiri kanıt olmadan kullanılmayacak:

- “#492–#495 kesinlikle hâlâ production'da değil.”
- “#492–#495 kesinlikle production'a çıktı.”

**Yapılacak doğrulama:** Vercel panelinde production deployment/aliasın commit
`1304624820...` veya #492–#495'i içeren eşdeğer build üzerinde olduğu görülmeli.
Eski `vixrex-public-q0lzzdzpq` Preview'ını promote etme talimatı artık tek
geçerli yol olarak yazılmayacak; çünkü son boş commit sonrasında yeni Vercel
check'leri başarılı oldu.

### 3. CI — PR #497 ve gerçek kapı durumu

PR #497 açık ve merge edilmedi. Değiştirdiği **tek dosya** `.github/workflows/ci.yml`.
Yaptığı iş yalnız iki self-hosted Windows job'ında `subosito/flutter-action`
yerine runner'da kurulu Flutter 3.44.4'ü kullanmak:

- `Flutter — analiz ve testler`
- `Şema üretim hattı — sapma kontrolü`

**PR #497 GRANT güvenlik bekçisini değiştirmiyor.** GRANT işi `ubuntu-latest`
üzerinde ayrı çalışıyor.

PR #497 head `452fbb1e...` için CI run `34922636949` son gözlemde:

| İş | Durum |
|---|---|
| Supabase auth security config check | başarılı |
| Değişiklik yüzeyi | başarılı |
| Secret sızıntı taraması | başarılı |
| Flutter — analiz ve testler | queued |
| Şema üretim hattı — sapma kontrolü | queued |
| Next.js — lint, tip, test, build | queued |
| Supabase yerel doğrulama — GRANT güvenlik bekçisi | **failure** |
| Next.js E2E | skipped |

GRANT işinin logu GitHub'dan alınamadığı için failure'ın gerçek bir GRANT
ihali mi, `ubuntu-latest`/kota/altyapı sorunu mu olduğu **doğrulanamadı**.
Bu ayrım çözülmeden “üç kapı doğrulandı” denmeyecek.

**Doğru sıra:**
1. Self-hosted runner çalışır hale gelir; queued Flutter/şema (ve bekleyen diğer
   runner işleri) gerçekten koşar.
2. GRANT failure'ın nedeni ayrı incelenir ve yeşile dönmeden güvenlik kapısı
   geçmiş sayılmaz.
3. #497 güncel `main`e karşı yeniden CI görmeden merge edilmez.
4. Bundan sonra ürün fazlarına devam edilir.

---

## Karar: dal referans, main gerçeklik

Dev dal 100 dosya, +13.966/−3.368, 11 migration. Tek parça merge edilmedi;
içinden fazlar tek tek alındı. Sebep: dalda canlıyı kıran dört davranış vardı
(aşağıda) ve o dalda CI hiç gerçekten koşmamıştı.

## main'e inen ürün fazları (production durumu ayrıca doğrulanır)

| PR | Ne |
|---|---|
| #491 | Erişilemez sahip paneli dalı + kullanılmayan katalog prop'u temizliği |
| #492 | Zengin ürün kartı + hızlı bakış + zengin ürün detay sayfası (okuma yolu) |
| #493 | Esnaf zengin alan girişi + asgari çekirdek migration |
| #494 | Kategori şablonları esnaf yönetiminde |
| #495 | Flutter tarafı zengin ürün modeline eşitlendi |

Repo migration dosyası:
`supabase/migrations/20260915010000_product_rich_core_minimal.sql`.
Canlı Supabase migration geçmişinde aynı ad `product_rich_core_minimal` olarak
uygulanmış durumda (canlı kayıt sürümü `20260915022230`). Bu iki kimlik ayrı
kaynaklardan geldiği için biri diğerinin yerine yazılmayacak.

Doğrulanan canlı DB durumu: ürün çekirdeği migration'ı mevcut. Görsel
zorunluluğunun tehlikeli DB tetikleyicisi bu güvenli çekirdeğin parçası olarak
alınmadı.

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
   Canlıdaki mevcut ürünleri kilitleme riski nedeniyle DB tetikleyicisi olarak
   alınmadı. Kural Flutter'da `ProductImagePolicy.validateForPublish` olarak
   yayın kapısına bağlanmayı bekliyor. Üst sınır 11 korunuyor.

## Sıradaki ürün işleri — sıra değiştirilmeyecek

### 0 — Önce CI gerçekliğini kapat

- PR #497'nin self-hosted Flutter/şema işleri gerçekten koşacak.
- GRANT güvenlik bekçisi failure nedeni doğrulanacak ve yeşil olacak.
- Production alias bağımsız doğrulanacak.

Bu üçü tamamlanmadan yeni ürün fazı `main`e merge edilmeyecek.

### A — Toplu yükleme (Excel/CSV/XML yeni alanları taşısın)

Daldan referans alınacak yüzeyler:
`public_web/src/app/api/products/batch/route.ts`,
`public_web/src/components/owner/BulkProductUpload.tsx`,
`lib/services/bulk_product_upload_service.dart`,
`lib/services/xml_product_upload_service.dart`,
`lib/screens/bulk_product_upload_screen.dart`,
`lib/controllers/bulk_product_upload_controller.dart`,
`lib/widgets/xml_upload_dialog.dart`.

Daldaki kod olduğu gibi alınmayacak. Özellikle `batch/route.ts` içindeki tek
hatalı satırın tüm 100'lük yüklemeyi 422 ile kesen davranışı Vixrex'e taşınmaz;
satır bazlı hata/başarı davranışı güncel `main` sözleşmesine göre doğrulanır.
`product_management_sheet.dart` içindeki `_openBulkUpload` bağlantısı da güncel
imzaya göre bağlanır; eski dalın imzası körlemesine geri getirilmez.

### B — Görsel kalite + yayın kapısı

Daldan referans alınacak yüzeyler:
`lib/services/store_publish_validator.dart`,
`lib/services/store_publish_service.dart`,
`lib/services/image_optimization_service.dart`,
`lib/services/store_shelf_upload_service.dart`,
`public_web/src/lib/productImageCleanup.ts`,
`public_web/src/lib/gorselSikistir.ts`,
`public_web/src/app/api/product-image-upload/route.ts`.

Kurallar: en az 3 görsel **yalnız yayın kapısında** uygulanacak, DB tetikleyicisi
olarak değil. Görsel temizlik yalnız Vixrex ürün yükleme yolundan gelen ve başka
üründe kullanılmayan dosyaya dokunabilir. Dış CDN, başka ürün ve mağaza görseli
silinmez. Kabul kanıtı hem silinen hem **silinmeyen** durumları kapsar.

### C — Ürün şeması sapma kapısı

`shared/product_attribute_schema.json` Flutter ve Next.js için ortak kaynak
olarak korunacak. Sayısal sınırlar/enum etiketleri gibi elle kopyalanan
parçaların sapmasını yakalayan CI kontrolü ürün şeması için kurulacak. Yeni
ürün alanı/şablonu bu kapıdan önce eklenmeyecek.

## Çalışma yöntemi

Her faz güncel `origin/main`den ayrı branch/worktree ile açılır. Eski ürün dalı
merge edilmez; yalnız doğrulanmış parça referans alınır. Her PR tek amaçlıdır.

Kapılar: `public_web` içinde `npm run typecheck`, `npx vitest run`,
`npm run lint`, `npm run build`; Flutter tarafında `flutter analyze`,
`flutter test`; migration/yetki değişiyorsa GRANT güvenlik bekçisi ve canlı
Supabase doğrulaması ayrıca gerekir.

## Bilinen altyapı gerçekleri

- Flutter ve şema drift işleri self-hosted Windows runner kullanıyor.
- GRANT güvenlik bekçisi `ubuntu-latest` kullanıyor; #497 kapsamı dışında.
- `supabase_schema.sql` kök snapshot'ı veritabanı hakikati değildir;
  `supabase/migrations/` ve canlı Supabase esas alınır.
- Vercel check `success` ile production alias doğrulaması aynı şey değildir.

## Değişmez koruma kuralları

- Çalışan Product CORE paralel ikinci ürün sistemiyle değiştirilmeyecek.
- `main` tek kod hakikati; canlı DB tek veri hakikati.
- Eski `work/product-live-ready-20260914` dalı topluca merge edilmeyecek.
- Sessiz veri silen dört davranış geri getirilmeyecek.
- Bir kapı queued/skipped/failure iken “CI doğruladı” yazılmayacak.
- Production alias görülmeden “canlıya çıktı” yazılmayacak.
