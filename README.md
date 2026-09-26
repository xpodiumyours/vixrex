# VixRex

Küçük işletmeler için dijital vitrin ve müşteri yönetim platformu.

VixRex; işletme bilgilerini, ürün ve hizmetleri, iletişim kanallarını ve randevuları bir vitrin etrafında toplar. Flutter uygulaması ve Next.js web uygulaması aynı Supabase altyapısını kullanır.

**Web sitesi:** [www.vixrex.com](https://www.vixrex.com)

> Belge kontrolü: 23 Eylül 2026. Bu README, incelenen yerel kaynak kodu ve yapılandırmaları açıklar; belirli bir dalın canlıya yayımlandığını veya tüm özelliklerin canlıda doğrulandığını göstermez. Alan adı, dağıtım durumu ve veritabanına uygulanmış migration'lar ayrı doğrulanır.

## Proje haritası

| Konum | Sorumluluk |
| --- | --- |
| [lib/](lib/) | Flutter uygulaması: işletme yönetimi, vitrin ve ürün düzenleme, OCR ve toplu işlemler |
| [public_web/](public_web/) | Next.js: tanıtım, Keşfet, müşteri vitrinleri, web yönetim ekranları, asistan ve sunucu API'leri |
| [shared/](shared/) | İki uygulamanın paylaştığı şemalar, mesajlar ve kurallar |
| [supabase/migrations/](supabase/migrations/) | Sürümlü veritabanı değişiklikleri, RPC'ler ve erişim politikaları |
| [supabase/functions/](supabase/functions/) | Supabase Edge Function'ları |
| [tool/](tool/) | Ortak kaynaklardan dosya üreten ve geliştirmeyi destekleyen araçlar |
| [test/](test/) ve [integration_test/](integration_test/) | Flutter testleri |
| [public_web/tests/](public_web/tests/) ve [public_web/e2e/](public_web/e2e/) | Web birim/sözleşme testleri ve tarayıcı senaryoları |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | Otomatik kalite kontrolleri |

### Uygulamalar arasındaki ilişki

```text
Flutter yönetim uygulaması ─────────────┐
                                      ├── Supabase: hesaplar, vitrinler,
Next.js yönetim ekranları ve API'leri ─┘   çalışma taslakları, ürünler, dosyalar
                                                   │
                                      Next.js müşteri vitrini
                                      /v/:slug ve ürün sayfaları
```

Flutter ve Next.js ayrı derlenir ve ayrı dağıtılır. Web tarafı yalnız herkese açık vitrinlerden oluşmaz; `/app` altında işletme yönetimi de bulunur. Bir yüzeydeki özelliğin varlığı diğer yüzeyde aynı davranışın bulunduğunu kanıtlamaz.

### Web adresleri

Aşağıdaki yollar [public_web/src/app/](public_web/src/app/) içinde tanımlıdır. Yönetim, sahiplik ve içerik yayın durumu kontrolleri ilgili sayfalarda/API'lerde uygulanır.

| Yol | İşlev |
| --- | --- |
| `/` | Tanıtım ve asistanla başlangıç |
| `/kesfet`, `/kesfet/:kategori` | Vitrin keşfi ve kategoriler |
| `/giris`, `/kayit`, `/hesap-bagla` | Hesap ve giriş akışlarının sayfaları |
| `/app` | İşletmenin vitrin yönetimi |
| `/app/urunler`, `/app/vixrex` | Ürün yönetimi ve asistan |
| `/app/hesap`, `/app/profil`, `/app/ayarlar`, `/app/bildirimler` | Hesap ve yönetim ekranları |
| `/v/:slug` | Müşterinin gördüğü vitrin ve yetkili sahip deneyimi |
| `/v/:slug/urun/:productSlug` | Ürün detayı |
| `/v/:slug/randevu`, `/v/:slug/randevu/:token` | Randevu ve takip |
| `/v/:slug/randevu-yonetim` | İşletmenin randevu yönetimi |
| `/v/:slug/yazilar`, `/v/:slug/blog-yonetim` | İşletmenin yazıları ve yazı yönetimi |
| `/blog`, `/blog/:slug` | Kurumsal Vixrex blogu; içerikler yayın koşullarına bağlıdır |
| `/hakkimizda`, `/iletisim`, `/yardim` | Kurumsal ve destek sayfaları |
| `/sitemap.xml`, `/robots.txt` | Arama motoru altyapısı |

Kurumsal blogun kaynağı [blogYazilari.ts](public_web/src/data/blogYazilari.ts); işletme vitrininin yazıları ise ayrı `store_articles` verisidir. Bunlar aynı içerik sistemi değildir.

### Asistan, taslak ve yayınlama

Ana sayfa asistanı yalnız sabit bir reklam maketi değildir. [LandingAsistanSohbeti.tsx](public_web/src/components/landing/LandingAsistanSohbeti.tsx) kullanıcı girdisini işler ve `/api/create-store` üzerinden vitrin oluşturma akışına katılır.

Başlangıç ve yayınlama için temel kaynak zinciri:

1. Ana sayfa asistanı → [create-store API](public_web/src/app/api/create-store/route.ts).
2. Oluşturma akışı → `get_or_create_working_draft` ile çalışma taslağı.
3. Web yönetimi → [uygulama giriş sayfası](public_web/src/app/app/page.tsx), sahip oturumu ve düzenleme bileşenleri.
4. Yayın isteği → [owner-publish API](public_web/src/app/api/owner-publish/route.ts) → `publish_working_draft` RPC.
5. Müşteri görünümü → `/v/:slug`.

Taslağın kaydedilmesi, vitrinin yayımlanmasıyla aynı işlem değildir. Yetki, doğrulama ve yasal onay kontrolleri API/RPC zincirinde değerlendirilir. Sahip oturumu kodu [ownerSession.ts](public_web/src/lib/ownerSession.ts) içinde bulunur.

### Ürün sistemi ve önceki harita

15 Eylül 2026 tarihli `docs/urun-sistemi-haritasi.md`, Git geçmişinde `f5d1b8f3` commit'inde ve `yedek/durum-raporu-20260916` dalında bulunur. Bu README hazırlanırken açık olan dalda dosya mevcut değildi. Önceki harita, o tarihteki durum ile sonraki geliştirme planlarını birlikte içerir; güncel özellik listesi olarak doğrudan kullanılmamalıdır.

Geçmiş haritayı çalışma dosyalarını değiştirmeden okumak için:

```sh
git show f5d1b8f3:docs/urun-sistemi-haritasi.md
```

Güncel kodda ürün sisteminin başlıca girişleri:

| Alan | Kaynak |
| --- | --- |
| Flutter ürün işlemleri | [ProductController](lib/controllers/product_controller.dart) → [ProductService](lib/services/product_service.dart) → [SupabaseProductRepository](lib/repositories/supabase_product_repository.dart) |
| Web ürün işlemleri | [OwnerProductManager](public_web/src/components/owner/OwnerProductManager.tsx) → [ürün API'si](public_web/src/app/api/products/route.ts) → [productCoreServer](public_web/src/lib/productCoreServer.ts) |
| Toplu aktarım | Flutter [bulk_product_upload_service.dart](lib/services/bulk_product_upload_service.dart); web [BulkProductUpload.tsx](public_web/src/components/owner/BulkProductUpload.tsx) |
| XML ve OCR | Flutter [xml_product_upload_service.dart](lib/services/xml_product_upload_service.dart) ve [OCR servisleri](lib/services/ocr/) |
| Ürün öznitelikleri | [product_attribute_schema.json](shared/product_attribute_schema.json) |
| Görsel kuralları | [product_image_policy.json](shared/product_image_policy.json) ve web [productImagePolicy.ts](public_web/src/lib/productImagePolicy.ts) |
| Müşteri sunumu | [ProductCatalog](public_web/src/app/v/[slug]/ProductCatalog.tsx), [ProductQuickView](public_web/src/components/ProductQuickView.tsx), [productStructuredData](public_web/src/lib/productStructuredData.ts) |

Eski haritadaki sabit dört görsel sınırı güncel ortak dosyayı yansıtmaz: incelenen `product_image_policy.json` içinde üst sınır 11'dir. Bu, canlı veritabanındaki sınırın doğrulandığı anlamına gelmez. Öznitelik, varyant ve ürün yapılandırılmış veri kodları da depoda mevcuttur; eski haritanın “yok” veya “plan” ifadeleri güncel kodla karşılaştırılmalıdır.

## Ortak kaynaklar ve üretim yönü

Her ortak dosyanın üretim yönü aynı değildir. Özellikle vitrin alanları için asıl kaynak JSON değil, TypeScript şemasıdır:

```text
public_web/src/lib/vitrinFieldSchema.ts
  → tool/sema_disa_aktar.ts
  → shared/vitrin_alanlari.json
  → tool/alan_semasi_uret.dart
  → lib/config/vitrin_alanlari.g.dart
```

| Konu | Asıl kaynak | Kullanım / üretim |
| --- | --- | --- |
| Vitrin alanları | [vitrinFieldSchema.ts](public_web/src/lib/vitrinFieldSchema.ts) | JSON'a aktarım, ardından Flutter üretimi |
| İşletme kategorileri | [business_categories.json](shared/business_categories.json) | Web okur; Flutter için `tool/business_categories_uret.dart` |
| Mesajlar | [vixrex_mesajlar.json](shared/vixrex_mesajlar.json) | Flutter için `tool/mesaj_semasi_uret.dart` |
| Premium fiyatı | [fiyatlandirma.json](shared/fiyatlandirma.json) | Web `fiyatlandirma.ts`; Flutter için `tool/fiyatlandirma_uret.dart` |
| Ortak renkler | [renkler.json](shared/renkler.json) | `tool/renk_uret.dart` → Flutter renkleri ve web `--color-lp-*` değerleri |
| Çalışma saatleri | [working_hours_contract.json](shared/working_hours_contract.json) | Ortak sözleşme |
| Ürün alanları ve görseller | [product_attribute_schema.json](shared/product_attribute_schema.json), [product_image_policy.json](shared/product_image_policy.json) | Ürün şeması ve görsel politikası |

Üretilen dosyalar yerine asıl kaynak düzenlenir ve ilgili üretici çalıştırılır. CI'ın hangi çıktıları denetlediği `schema-drift` işinde tanımlıdır; tüm `shared/` dosyalarının aynı üreticiyle işlendiği varsayılmaz.

## Yerel geliştirme

### Gereksinimler

- Flutter: CI'da kullanılan sürüm **3.44.4**. Dart SDK koşulu [pubspec.yaml](pubspec.yaml) içinde `^3.7.2` olarak tanımlıdır; bu bir Flutter sürümü değildir.
- Node.js: CI ile aynı ortam için **24**. Depodaki Next.js **16.2.11**, React **19.2.4**; bağımlılıklar [package.json](public_web/package.json) ve kilit dosyasındadır.
- İlgili geliştirme ortamına ait Supabase yapılandırması.

Yerel sunucu adresi, kullanılan veritabanının da yerel olduğu anlamına gelmez. Veri yazan denemelerden önce ortam dosyalarının hangi Supabase projesini hedeflediği kontrol edilir.

### Yapılandırma

- Flutter: [dart_defines.example.json](dart_defines.example.json) örneğinden git'e alınmayan `dart_defines.local.json` hazırlanır.
- Next.js: [public_web/.env.example](public_web/.env.example) örneğinden git'e alınmayan `public_web/.env.local` hazırlanır.
- Supabase URL'si ve publishable anahtarı temel bağlantı ayarlarıdır. Web yapılandırmasında `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` adları da kullanılır; eşleme ve öncelik için [next.config.ts](public_web/next.config.ts) ve [supabase.ts](public_web/src/lib/supabase.ts) birlikte incelenir.
- Sahip oturumu, oran sınırlama, yeniden doğrulama ve bot kontrolleri için ayrı sunucu ayarları bulunur. Cron/bildirim için `CRON_SECRET`, `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`; kiralama test muafiyeti için `RENT_DEMO_BYPASS_SECRET` örnekte açıklanmıştır.
- Ödeme ve harici servisler kendi yapılandırmalarına bağlıdır. Örnek ortam dosyası bir başlangıç şablonudur; bütün servislerin hazır olduğunu göstermez.
- Service-role anahtarı ve sunucu sırları istemciye açılmaz, `NEXT_PUBLIC_` öneki almaz ve depoya kaydedilmez. Supabase Edge Function sırları web ortamından ayrı yapılandırılır.

### Next.js

```sh
cd public_web
npm ci
npm run dev
```

Adres: **http://localhost:3000**. Web yönetimi: **http://localhost:3000/app**.

### Flutter

```sh
flutter pub get
flutter build web --release --dart-define-from-file=dart_defines.local.json
```

Windows'ta `./run.ps1` Flutter Web'i, `./dev.ps1` Flutter ve Next.js'i birlikte başlatır. Flutter panel adresi **http://localhost:5000/app** olur. `dev.ps1`, yerel Flutter yapılandırmasındaki `PUBLIC_SITE_URL` değerini `http://localhost:3000` olarak günceller.

## Doğrulama ve kalite kontrolleri

Gerçek otomasyon kaynağı [.github/workflows/ci.yml](.github/workflows/ci.yml) dosyasıdır. [.github/scripts/changed_surfaces.py](.github/scripts/changed_surfaces.py), değişen dosyalara göre Flutter, ortak şema ve web işlerini seçer.

| Kontrol | Kapsam |
| --- | --- |
| `secret-tarama` | Gitleaks ile sır taraması |
| `auth-config-check` | Hesap/giriş politikası sözleşmesi |
| `changes` | Değişiklik sınıflandırması ve ilgili Python testleri |
| `grant-guard` | Veritabanı izin kontrolleri |
| `flutter` | Biçim, analiz, Flutter testleri |
| `schema-drift` | Tanımlı üreticiler ve üretilen dosyaların güncelliği |
| `public_web` | Lint, tip kontrolü, birim testleri, üretim derlemesi |
| `public_web_e2e` | İlgili `main` değişikliklerinde canlı hedefe tarayıcı testleri |
| `public_web_e2e_onizleme` | İlgili PR değişikliklerinde yerel PR derlemesine tarayıcı testleri; görsel regresyon hariç |

Web kontrolleri (`public_web/` içinde):

```sh
npm run lint
npm run typecheck
npm run test
npm run build
npm run e2e:local
```

Flutter kontrolleri (depo kökünde):

```sh
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
flutter test --reporter expanded
```

`e2e:local` hedefi **http://localhost:3000** adresidir. Standart `npm run e2e`, `E2E_PUBLIC_BASE_URL` verilmezse **https://vixrex-public.vercel.app** adresini hedefler; ayrıntılar [Playwright yapılandırmasında](public_web/playwright.config.ts) bulunur. Görsel karşılaştırma dosyaları işletim sistemine bağlıdır.

Bir kontrolün burada listelenmesi çalıştırıldığı anlamına gelmez. Test sonucu, tarayıcıda gözlenen davranış ve canlı dağıtım sonucu ayrı raporlanır.

## Yayınlama

- Flutter yapılandırması: [vercel.json](vercel.json), [vercel-build.sh](vercel-build.sh).
- Next.js yapılandırması: [public_web/vercel.json](public_web/vercel.json).
- İki yapılandırma değişiklik kapsamını ayrı değerlendirir. `main` ve ilgili `verify-*` dal desenleri için dağıtım izinleri dosyalarda tanımlıdır.
- Veritabanı değişiklikleri [supabase/migrations/](supabase/migrations/) altında sürümlenir. Bir migration'ın depoda bulunması canlıya uygulandığının kanıtı değildir.
- Yerel değişiklik, commit, uzak dala gönderim, ana dala birleştirme ve canlı yayın ayrı adımlardır. README düzenlemek bunları gerçekleştirmez.

## Çalışma rehberi

Ajan kuralları için [AGENTS.md](AGENTS.md), ek çalışma notları için [CLAUDE.md](CLAUDE.md), katkı süreci için [CONTRIBUTING.md](CONTRIBUTING.md), güvenlik bildirimi için [SECURITY.md](SECURITY.md) okunur. Mimari açıklamalar eskiyebileceğinden, değiştirilecek akış ilgili kaynak kodu ve mevcut yapılandırmalar üzerinden doğrulanır.

README güncellenirken bağlantıların varlığı, komutların paket betikleriyle eşleşmesi, ortak kaynakların üretim yönü ve CI koşulları kontrol edilir. Eski planlar veya geçmiş ölçümler güncel canlı durum gibi sunulmaz.

## Lisans

Bu proje özel mülkiyete tabidir. Tüm hakları saklıdır. Bkz. [LICENSE](LICENSE).
