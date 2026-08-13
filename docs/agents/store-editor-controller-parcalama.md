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
| 5 | ~37 basit alan setter'ı → tek yazma cephesi | ✅ Tamamlandı (2026-08-13). Controller 1140 → 1089 satır. ~26 tek-alan setter'ı ve 3 çok-alanlı setter (`updateAboutSection`, `updateGallerySectionMeta`, `updateFeaturedCampaign`) yeni `_guncelle(void Function(StoreData) yaz)` yardımcısına yönlendirildi — her biri 3-4 satırdan 1-2 satıra indi. Genişletilmiş mantık taşıyan setter'lar (kategori, booking, yasal onay, bölüm görünürlüğü, `@override` mixin delegeleri) bilerek DOKUNULMADI, davranışları `_guncelle`'nin tek satır yazma deseninden farklı. Public API (metot adları/imzaları) hiç değişmedi. `flutter analyze` temiz, tam paket 431/431 yeşil. |
| 5+ | Şema tabanlı tek yazma cephesi (`updateField`, ADR 0001) | ✅ Tamamlandı (2026-08-13, PR #144). Controller 1089 → 1159 satır (satır sayısı AZALMADI, arttı). 23 tek-alan setter'ı Next.js'teki `vitrinFieldSchema.ts` ile aynı şemaya (`vitrin_alanlari.g.dart`) bakan tek bir `updateField(anahtar, deger)`'e yönlendirildi. Kazanım satır değil: iki istemcinin (Flutter/Next.js) aynı yazma desenini kullanması, alan eklerken iki ayrı yerde ayrı setter yazma riskinin kalkması. |

**5 fazın hepsi + updateField konsolidasyonu tamamlandı — ama dürüst sonuç: `store_editor_controller.dart` hâlâ 1159 satır, AGENTS.md'nin 400 satır sınırının yaklaşık 2,9 katı.** Bu ilk plan başından beri "400'e indirir" demiyordu. Aşağıdaki Faz 6-9, o "ayrı, daha büyük mimari adım" — burada başlıyor.

Faz 1'in gerçek şekli için `lib/services/product_catalog_sync_service.dart`
şablon örnektir: `const` constructor, tek dosyada dar/derin arayüz,
controller-state callback'i yok, davranış birebir korunmuş (düzeltme ayrı).

## Faz 6-9: Cephe (facade) yaklaşımı — 2026-08-13'te planlandı

Casper'ın talebi üzerine: "5 faz + updateField bitti ama hâlâ çok büyük,
bölme işini erteleme, gerçek bir plan yap" (2026-08-13). Önceki tur
"gerekirse ileride bakarız" dedi — bu yanlıştı, çünkü dosyada gerçekten
ayrılabilir, birbirinden bağımsız 4 iş akışı var (aşağıda), sadece "trivial
setter" değil.

**Yöntem: cephe/kompozisyon, parçalama değil.** `StoreEditorController`
sınıfı AYNI KALIR — aynı sınıf adı, aynı metot adları/imzaları,
`ChangeNotifier` aynı. UI tarafında (~15+ ekran) TEK BİR SATIR değişmez.
İçeride her metot artık 5 yeni, bağımsız test edilebilir sınıftan birine
1-3 satırla devrediyor. Bu, satır sayısını düşürürken riski neredeyse
sıfırlarken (çağıran taraf hiç dokunulmuyor) gerçek karmaşıklığı da
gerçekten taşıyor (pass-through değil — "deletion test": bu sınıfları
silersek karmaşıklık controller'a geri döner, yani gerçek iş yapıyorlar).

| Faz | Yeni modül | Taşınan iş | Tahmini satır |
|---|---|---|---|
| 6 | `StoreContentEditingService` | `updateField` switch'i + `updateAboutSection`/`updateGallerySectionMeta`/`updateFeaturedCampaign` (çoklu-alan yazımı) | ✅ Tamamlandı (2026-08-13). Controller 1159 → 1111 satır. `_contentEditingService` state/notify bilmiyor, yalnız `StoreData` mutasyonu — controller `_guncelle`/`notifyListeners` kararını kendinde tutuyor. `flutter analyze` temiz, tam paket 443/443 yeşil (7 yeni test: `test/store_content_editing_service_test.dart`). |
| 7 | `StorePublishFlowService` | `publish`, `saveLocally`, `openOwnerPreview`, `deleteVitrin`, `withdrawPublicationConsent`, `ensureDraftEditToken` — **en kritik yol, en dikkatli test edilecek faz** | ~170 |
| 8 | `StoreProductCatalogController` | `syncCatalogToRemote`, `addProduct(ById)`, `removeProduct(ById)`, `updateProduct(Imported)`, `ensureRemoteStoreId`, `_loadRemoteProductsIfReady`, `_isUuid`, `_revalidateStoreCache` | ~150 |
| 9 | `StoreHydrationController` | `initialize`, `_syncInitialData`, canlı dinleme başlat/durdur orkestrasyonu, `_pullFromCloudIfNewer`, `_fetchPublishedInfoFromSupabase` | ~150 |

**Dürüst projeksiyon:** 4 fazın hepsi bitince controller ~1159 satırdan
~550-650 satıra iner (getter'lar + constructor/wiring + kalan booking/yasal
onay/kategori setter'ları geride kalıyor — bunlar gerçekten controller'a
ait, kendi state'lerini `_data` üzerinden yan etkilerle değiştiriyorlar).
**Tam 400'e inmeyebilir** — ama her yeni modül kendi başına 400'ün çok
altında, dar ve derin bir arayüze sahip olacak, ki AGENTS.md kuralının asıl
amacı bu (tek dosyanın her şeyi yapması değil).

Her faz kendi PR'ı, kendi testi, `flutter analyze` + tam paket (436 test)
yeşil şartı ile ilerler — önceki 5 fazla aynı disiplin. Faz 7 (yayın akışı)
paraya/canlı vitrine en yakın kod olduğu için ekstra dikkatle yapılacak.

## Sıradaki fazı almadan önce

Bu tablo bir taahhüt değil, sadece "nerede kaldık" notu — sıradaki fazın
kesin kapsamı (hangi metodlar, hangi yeni dosya, hangi testler) o an
`store_editor_controller.dart`'ın gerçek hâline bakılarak belirlenir; burada
önceden detaylandırılmaz (kod o zamana kadar değişmiş olabilir).

Her faz kendi başına PR olur; Kapsam kontrolü (12 dosya/600 satır, bkz.
AGENTS.md) otomatik uyarır. Bir fazın gerçekten tek PR'da bitmeyecek kadar
büyük çıkması normaldir — büyürse alt-fazlara bölünür, tek seferde
zorlanmaz.
