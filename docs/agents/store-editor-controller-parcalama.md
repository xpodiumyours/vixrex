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
| 2 | Yasal onay damgalama (~65 satır, sabit tarihli fallback riski var) | Yapılmadı |
| 3 | Canlı/taslak realtime dinleyicileri (~180 satır, ham Supabase sorguları) | Yapılmadı |
| 4 | `StoreLocationMixin`/`StoreMediaMixin` içindeki gerçek iş mantığı (GPS eşleştirme, upload orkestrasyon) → enjekte edilebilir servisler | Yapılmadı |
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
