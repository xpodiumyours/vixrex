# StoreEditorController parçalama — nerede kaldık

`lib/controllers/store_editor_controller.dart` AGENTS.md'nin 400 satır / 20
üye sınırının çok üstünde başladı (1388 satır). İş küçük, tek başına
gönderilebilir fazlara bölünüyor; her faz kendi PR'ı, kendi testi.

**Bu dosyayı güncelleyen ajan (hangi araç olursa olsun) önce
`docs/agents/repository-guide.md` ve `AGENTS.md`'yi okumuş olmalı — burada
tekrar edilmiyor.**

## Durum

| Faz | Konu | Durum |
|---|---|---|
| 1 | Ürün kataloğu CRUD/senkron → `ProductCatalogSyncService` | ✅ Tamamlandı (PR #137, 2026-08-12). Controller 1388 → 1272 satır. |
| 2 | Yasal onay damgalama (~65 satır, sabit tarihli fallback riski var) | ✅ Tamamlandı (2026-08-13). Controller 1272 → 1229 satır. DeepSeek'in bıraktığı ilk taslak sabit-tarihli fallback riskini düzeltmek yerine tekrar üretmişti (gerçek sunucu sürüm/hash'ini hiç okumuyordu, ağ hatasında da fallback yazmıyordu) — yeniden yazıldı, orijinal davranış (`docs.privacy.version`/`.contentHash` başarıda, `_ensureFallbackStamps` her koşulda) birebir korundu. `flutter analyze` temiz, `test/publish_legal_stamp_fix_test.dart` (3) ve `test/store_editor_controller_test.dart` (18) yeşil. |
| 3 | Canlı/taslak realtime dinleyicileri (~180 satır, ham Supabase sorguları) | ✅ Tamamlandı (2026-08-13). Controller 1229 → 1140 satır. `StoreRealtimeSyncService` iki kanalı da (canlı `stores` UPDATE + taslak `alan_guncellendi` broadcast) ve `pullFromCloudIfNewer`'ı sahiplendi; kanal referansları serviste (stateful), `_data`/`notifyListeners` kararı callback'lerle controller'da kalıyor. `flutter analyze` temiz, tam paket 426/426 yeşil. Realtime davranışı doğrudan test edilmiyordu (canlı Supabase gerektirir) — bu fazdan önce de öyleydi, kapsam dışı bırakıldı. |
| 4 | `StoreLocationMixin`/`StoreMediaMixin` içindeki gerçek iş mantığı (GPS eşleştirme, upload orkestrasyon) → enjekte edilebilir servisler | ✅ Tamamlandı (2026-08-13). Ana controller dosyası bu fazdan etkilenmedi (kod zaten mixin'lerdeydi) — asıl kazanım test edilebilirlik. `StoreLocationFetchService` (GPS + doğruluk + adres çözme + il/ilçe eşleştirme, `store_location_mixin.dart` 213→121 satır) ve `StoreMediaUploadService` (kapak+galeri yükleme orkestrasyonu, `store_media_mixin.dart` 188→163 satır). İl/ilçe eşleştirme artık GPS'siz test ediliyor (`test/store_location_fetch_service_test.dart`, 5 yeni test). Yol boyunca eski bir kontrat testi (`test/gps_adres_test.dart`) bulundu — kod taşınınca yanlış dosyaya bakıyordu, düzeltildi. `flutter analyze` temiz, tam paket 431/431 yeşil. |
| 5 | ~37 basit alan setter'ı → tek yazma cephesi | Yapılmadı |

Faz 1'in gerçek şekli için `lib/services/product_catalog_sync_service.dart`
şablon örnektir: `const` constructor, tek dosyada dar/derin arayüz,
controller-state callback'i yok, davranış birebir korunmuş (düzeltme ayrı).

## Sıradaki fazı almadan önce

Bu tablo bir taahhüt değil, sadece "nerede kaldık" notu — sıradaki fazın
kesin kapsamı (hangi metodlar, hangi yeni dosya, hangi testler) o an
`store_editor_controller.dart`'ın gerçek hâline bakılarak belirlenir; burada
önceden detaylandırılmaz (kod o zamana kadar değişmiş olabilir).

Her faz kendi başına PR olur; Kapsam kontrolü (12 dosya/600 satır, bkz.
AGENTS.md) otomatik uyarır. Bir fazın gerçekten tek PR'da bitmeyecek kadar
büyük çıkması normaldir — büyürse alt-fazlara bölünür, tek seferde
zorlanmaz.
