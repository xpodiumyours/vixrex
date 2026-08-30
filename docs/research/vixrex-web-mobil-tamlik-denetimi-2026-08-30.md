# VixRex Web + Mobil Mimari Tamlık Denetimi — 2026-08-30

> Kod-okuma denetimi (kod değişikliği yapılmadı). Dal: `claude/vixrex-web-mobile-audit-heteuu`,
> HEAD `455d846` (main ile aynı geçmiş). 6 paralel araştırma turuyla yapıldı; her bulgu dosya/satır
> kanıtına dayanır. Bu dosya CONTEXT.md'nin `docs/research/` referans desenine uyar — CONTEXT.md
> güncellenirken buraya işaret eder (bkz. "Şu anki teknik/ürün durumu" bölümü, 2026-08-30 girdisi).

## Kalibrasyon notu

Denetim talebi simetrik bir "Flutter = Next.js" hedefi varsayıyordu. Kod ve
`VIXREX_RULES.md` bunu doğrulamıyor: proje kuralları **kasıtlı olarak asimetrik**
bir mimari tanımlıyor — Flutter referans/hedef kalite, Next.js eşitlenecek taraf
("Yön daima Flutter → Next.js"), vitrin render'ı yalnızca Next.js'te, düzenlemenin
yalnızca iki kapısı var (Flutter manuel panel + Next.js Vixrex Asistan sohbeti).
Bu denetimde "yalnız bir tarafta olması" tek başına eksiklik sayılmadı; yalnız üç
durumda gerçek eksiklik işaretlendi: (a) proje kendi kuralına aykırıysa, (b) iki
taraf aynı veriye çelişen şekilde erişiyorsa, (c) esnafın temel akışını fiilen
engelliyorsa.

## Tek cümlelik gerçek durum

Vixrex bugün kasıtlı olarak asimetrik, tek yönlü bir eşitleme mimarisi; Next.js
hızla "yalnız SEO renderer"dan neredeyse tam bir web uygulamasına evrilmiş
(ödeme, hesap yönetimi, ürün/kategori/randevu/blog CRUD dahil) ve çoğu akışta
ortak Supabase RPC'leri üzerinden Flutter ile senkron çalışıyor — ama zincirin
en az bir yerinde (ürün kategorisi) Flutter tarafı gerçek ilişkisel tabloya hiç
yazmadan sahte yerel ID üretiyor (**P0 zincir kopukluğu**) ve Next.js'in owner
yetkilendirmesi Supabase Auth'un yanında bağımsız bir HMAC-token/edit_token
kanalı da kabul ediyor (kasıtlı ama "aynı kimlik = aynı sahip" varsayımını
kısmen deliyor).

## P0 — Ürün kategorisi zincir kopukluğu (yeni tespit, en kritik bulgu)

- Flutter: `lib/screens/product_category_management_screen.dart` — kategori
  ekleme/silme/yeniden adlandırma tamamen yerel bellek state'inde; yeni
  kategori ID'si sahte üretiliyor: `'category-${DateTime.now().microsecondsSinceEpoch}'`
  (satır 57-64). `StoreEditorController.syncCatalogToRemote`
  (`lib/controllers/store_editor_controller.dart:733-770`, özellikle satır 754)
  kategorileri **hiçbir RPC'ye göndermiyor**, yalnız bellekte tutuyor.
  `upsert_store_category` RPC'sine Flutter'dan hiçbir çağrı yok (`grep` — 0 sonuç).
- Ürün senkronu (`ProductCatalogSyncService.syncCatalog`) yalnızca `categoryId`
  gerçek bir UUID ise kategoriyi ürüne bağlıyor; sahte yerel ID'ler UUID
  olmadığından `clearCategory:true` ile ürün **kategorisiz** kaydediliyor.
- Flutter'daki kategori listesinin kaynağı da ayrı: `StoreData.fromJson` legacy
  `stores.product_categories` **JSONB kolonundan** okuyor
  (`lib/models/store_data_dto.dart:122,146`), ilişkisel `product_categories`
  tablosundan değil.
- Next.js tarafı ise doğru: `public_web/src/app/api/product-categories/route.ts`
  gerçekten `product_categories` tablosuna INSERT/UPDATE/DELETE yapıyor +
  `upsert_store_category` RPC'sini kullanıyor.
- **Sonuç:** Flutter'da oluşturulan yeni kategoriler Next.js'te asla görünmez;
  ürün-kategori ilişkisi Flutter'dan asla kurulamaz. Bu, mevcut ekranlar
  çalışıyor gibi görünse de ("kategori seçilebiliyor") DB'de gerçek bir ilişki
  kurmuyor — klasik "VAR ama KULLANILABİLİR değil" durumu.

## Diğer öne çıkan bulgular (özet — detay için konuşma kaydına/PR'a bakınız)

- **Auth/ownership — KISMİ ORTAK.** `stores.user_id`/`auth.uid()` zinciri her
  iki tarafta ortak; ama Next.js owner-yetkilendirmesi asıl olarak
  `vixrex_owner_session` HMAC-imzalı HttpOnly çerezi + `edit_token` üzerinden
  çalışıyor (`public_web/src/lib/ownerSession.ts`, `create_owner_session` RPC)
  ve bu kanal **Supabase Auth login olmadan** da tam CRUD yetkisi veriyor
  (`create_owner_session`, `auth.uid()=stores.user_id` YA DA edit_token
  eşleşmesini eşit sayıyor). Kasıtlı ve kod içi yorumlarla gerekçeli (önizleme/
  handoff/rent-demo akışları için gerekli) — **kaldırılacak bir hata değil**,
  ama "owner = auth.uid()" varsayımıyla yazılan yeni kod bu ikinci kanalı
  hesaba katmalı.
- **Draft mimarisi karma, üç mekanizma:** (1) yayın-öncesi DB taslağı
  (`save_store_draft_with_token`), (2) yayın-sonrası DB çalışma taslağı
  (`store_working_drafts`, `get_or_create_working_draft`), (3) cihaz-içi
  SharedPreferences (yalnız Flutter, hızlı yerel echo). (2) zaten cihazlar
  arası kalıcı taslak ihtiyacını karşılıyor — "taslak yalnız local storage'a
  bağımlı" varsayımı **hatalı**, karıştırılmamalı.
- **Yayınlanan veri Flutter'a zaman-damgalı koşulla akıyor**
  (`lib/services/store_realtime_sync_service.dart:38-72`) — yerel veri
  buluttan daha yeniyse bulut verisi reddediliyor (çevrimdışı koruması).
  Yayınlanmamış taslak değişikliği ise Flutter'a **yalnız bildirim** olarak
  geliyor, gerçek değer hiç aktarılmıyor (satır 122-140, kasıtlı güvenlik
  tasarımı — broadcast kanalı oturumsuz da dinlenebilir).
- **Fiyat/stok sayısal alanları iki istemcide de eksik:** `products.price_amount`
  ve `products.stock_quantity` DB'de var, `update_store_product` RPC'si
  destekliyor, ama ne Flutter'ın ne Next.js'in ürün formu bu alanları tam
  soruyor (yalnız `priceText` serbest metin + `stockStatus` 3 sabit değer).
- **Varyant (renk/beden) tamamen ölü:** `products.variants` jsonb kolonu var,
  hiçbir RPC/UI kullanmıyor.
- **Ölü kod:** Flutter `ProductController` sınıfı hiç instantiate edilmiyor
  (gerçek yol `ProductCatalogSyncService`); `StoreRepository.insertStore()`
  kullanılmıyor (gerçek yol `StorePublishService.publishStore()`); Flutter
  `PublicProductScreen` route'a bağlı değil (kasıtlı — `PublicSiteRedirectScreen`
  onun yerini aldı).
- **QR/WhatsApp mantığı iki platformda bağımsız tekrarlanmış** (DUPLICATE,
  P2 mimari borç) — Flutter `qr_flutter`(native)+`whatsapp_link_helper.dart`,
  Next.js `api.qrserver.com`(3.parti)+kendi `wa.me` üretimi. Ortak kod yok.
- **Native paylaşım Next.js'te yok** — yalnız "linki kopyala"; Flutter'da
  `share_plus` ile tam native OS paylaşımı var.

## CONTEXT.md'deki eski notların güncel kod karşısında durumu

| CONTEXT.md notu (tarih) | Denetim sonucu (2026-08-30) |
|---|---|
| "Kategori etiketi uyuşmazlığı (2026-08-20, henüz açılmadı)" | **Çözülmüş.** `shared/business_categories.json` ortak sözleşmesi + `tool/business_categories_uret.dart` üretimi + CI drift kontrolü (`.github/workflows/ci.yml:250,290,293,304-305`) — PR #319/commit `d159072`, 22 Ağustos. Not: bu, yukarıdaki YENİ P0 (kategori **ilişki** zinciri) ile karıştırılmamalı — etiket metni sorunu ayrı, ilişkisel yazma sorunu ayrı. |
| "#229 sitemap ürün URL'si üretmiyor" | **Çözülmüş.** `public_web/src/app/sitemap.xml/route.ts:157-170` her mağaza için `/v/{slug}/urun/{productSlug}` URL'lerini XML'e ekliyor. |
| "#255 vitrin_views tablosu dolmuyor gibi görünüyor" | **Çözülmüş.** Migration `20260823120000_vitrin_views_kaynak_genisletme.sql` canlıya uygulanmış (commit `b3453d9` mesajı: *"canliya UYGULANDI... dogrulandi"*), `VitrinViewTracker.tsx` sahip modunda mount edilmeden `record_vitrin_view` RPC'sini çağırıyor. |
| "Premium: web PR'ları henüz deploy değil, pencere açık (2026-08-17 gece)" | **Deploy edilmiş.** `public_web/src/app/api/paytr/callback/route.ts` son değişikliği commit `b13fcab`, 2026-08-29, main dalında. İmza doğrulaması (`timingSafeEqual`) + tutar eşleşme kontrolü (AMOUNT_MISMATCH) kodda mevcut. |

## Platform tamlık oranı (yaklaşık, özellik matrisinden)

- Flutter: ~%78 — owner-panel/admin kapsamında çoğu akış TAM; kategori zinciri
  kopuk, fiyat/stok sayısal alan UI'da yok, varyant yok, premium satın alma
  UI'ı yok.
- Next.js: ~%72 — SEO/public çekirdek olgun, owner-panel hızla genişliyor;
  native paylaşım yok, serbest arama yok (kasıtlı), admin/moderasyon yok.
- Ortak backend/senkron: ~%68 — CRUD/publish akışları ortak RPC'lerle sağlam
  senkron; kategori zinciri ve fiyat/stok alan eksikliği bu oranı düşürüyor.

## Tam özellik matrisi ve 20 senaryo detayı

Bu dosya özet niteliğindedir. Tam 30+ satırlık özellik matrisi, route
envanteri, veri modeli karşılaştırması ve 6 kullanıcı senaryosu bu denetimi
üreten oturumun transkriptindedir (bu depoya ayrı bir dosya olarak
taşınmadı — gerekirse ilgili GitHub PR/issue'ya eklenebilir).
