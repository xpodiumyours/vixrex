# VixRex — Bağlam (Vault kök notu)

> Bu dosya bir **hub/index not**. Uzun bir sohbet raydan çıktığında veya yeni
> bir model/oturum işe başlarken, önce bunu, sonra aşağıdaki `[[wikilink]]`
> ile işaretli notları okuyarak dakikalar içinde bağlam kazanır — 100
> mesajlık geçmişi yeniden anlatmaya gerek kalmaz.
>
> **ÖNCE OKU — Casper ile çalışma notu:** [[casper-calisma-notu-2026-08-17]]
> (kullanıcıyı tanıma + sohbetten kopmadan devam etme — her oturum başında okunur,
> her oturum sonunda güncellenir; dosya şişirilmez, yalnız değişen yerler tazelenir).

## Vault kuralı (2026-08-15, kullanıcı kararı)

**Kod/runtime = mevcut teknik gerçek. Bu dosya + `docs/adr/` = onaylanmış
hedefler ve kararlar.**

Çelişki çıkarsa **kod kazanır** — Vault (bu dosya, ADR'ler) yanlış/eski
kalmışsa güncellenir, kod ona uydurulmaz. Sebep: kod her zaman çalışan,
doğrulanabilir gerçek; bir not eskiyip unutulabilir ama kimse fark etmez.
Gerekçesi: [[0003-vault-baglam-kurali]].

**Pratik sonuç:** Bir iddia burada veya bir ADR'de yazıyor ama kodda
doğrulanamıyorsa (ör. bir dosya/fonksiyon artık yok, davranış değişmiş) —
önce kodu doğru kabul et, sonra bu notu düzelt. Tersini yapma.

## VixRex nedir (onaylanmış hedef)

Esnafın (küçük işletme sahibi) **kod bilmeden, tek tıkla** dijital vitrin
sahibi olmasını sağlayan platform. Merkezi felsefe: "esnaf yazıya tıklar,
VixRex Asistan değiştirir" — form doldurtmak değil, sohbet/tıkla-değiştir
deneyimi.

İki istemci:
- **Flutter** (`lib/`) — esnafın kendi paneli: sahiplik, vitrin kurulumu,
  ürün/kategori yönetimi, randevu, Instagram senkronu.
- **Next.js** (`public_web/`) — herkese açık vitrin sayfaları (`/v/:slug`)
  + sahip modunda "Vixrex Asistan" tıkla-değiştir paneli.

İkisi de aynı Supabase/Postgres çekirdeğine yazar. Hangi mantığın **tek
omurgada** (backend/DB) hangisinin **istemciye özel** kalacağı bilinçli bir
karar: [[0001-vixrex-core-omurga-ve-uzman-beyinler]].

## Şu anki teknik/ürün durumu (2026-08-17 itibariyle — bu bölüm en hızlı
eskiyen kısım, kod ile çelişirse KOD kazanır)

> **GÜVENLİ GERİ DÖNÜŞ NOKTASI (2026-08-17):** Premium/Kiralık Vitrin
> planına başlamadan önceki canlı durum. Git: `main` @ `e160f71`;
> `docs/context-baglama` dalı main'den 2 commit ileride (skill tek kaynak +
> PR kapsam CI), çalışma ağacı temiz. Canlıda çalışanlar: "Bu vitrini
> kirala" akışı ÜCRETSİZ (ödeme altyapısı YOK), deneme temizliği 30 saat
> (yayınlanmayan taslağı siler), premium DB şeması YOK (profiles yalnız
> id/email), Flutter `PremiumService` iskeleti hiçbir ekrana bağlı değil.
> Bu plandan sonra bu not eskirse güncellenir; kod çelişirse kod kazanır.
>
> **GÜNCELLEME (2026-08-17, akşam):** 2 dal commit'i (skill tek kaynak +
> PR kapsam CI) PR #207 olarak açıldı (merge bekliyor). Yerel ana dal artık
> `bring/premium-base` (origin/main @ `2ac4c0b` + PR #207'in 2 commit'i);
> 6 premium PR'ın tamamı bu dalın üzerinde uncommitted duruyor. Not: yerel
> main, origin/main'den ayrılmış ~9 eski commit taşıyordu — bunlar bilerek
> main'e taşınmadı (origin'deki yeni sürümleriyle aşılmıştı). Derin geri
> dönüş noktası değişmedi: premium öncesi canlı durum main @ `e160f71`.
> Kod çelişirse kod kazanır.
>
> **GÜNCELLEME (2026-08-17, gece):** 5 premium migration CANLIYA UYGULANDI
> (Management API üzerinden, `chfulefxczbgurtgavtp`): `20260817000000`
> (premium şema + koruma tetikleyicisi), `20260817010000` (14 gün deneme +
> taslağa dön + cron), `20260817020000` (yayın kapısı), `20260817030000`
> (PayTR RPC'leri), `20260817040000` (durum okuma). Canlı doğrulandı: kolon,
> tetikleyici, premium_orders+RLS, 5 fonksiyon, 2 cron işi, fail-closed
> spot testler (STORE_NOT_FOUND/UNKNOWN_ORDER). DİKKAT: yayın kapısı
> (#3) artık AKTİF — premium'suz kiralık vitrin yayınlanamaz; web PR'ları
> (ödemeli akış) henüz deploy değil, pencere açık. Kayıtlar canlı
> `schema_migrations`'da (CLI formatı). Web kodları hâlâ uncommitted,
> `bring/premium-base` üzerinde; PR #207 merge bekliyor.

- **Web + Mobil mimari tamlık denetimi (2026-08-30):** Kod-okuma denetimi
  (değişiklik yapılmadı), tam rapor:
  `docs/research/vixrex-web-mobil-tamlik-denetimi-2026-08-30.md`.
  **Yeni P0 bulgu:** ürün kategorisi Flutter tarafında ilişkisel
  `product_categories` tablosuna hiç yazılmıyor —
  `product_category_management_screen.dart` yerel bellekte sahte ID
  (`category-${microsaniye}`) üretiyor, `syncCatalogToRemote`
  (`store_editor_controller.dart:733-770`) bunu hiçbir RPC'ye göndermiyor;
  ürün gerçek UUID kategoriye bağlanamayınca kategorisiz kaydediliyor.
  Next.js tarafı (`/api/product-categories`, `upsert_store_category` RPC)
  doğru çalışıyor. Flutter'da oluşturulan yeni kategoriler bu yüzden
  Next.js'te asla görünmüyor — henüz düzeltilmedi.
  **Auth/ownership notu:** `stores.user_id`/`auth.uid()` zinciri ortak, ama
  Next.js owner-yetkilendirmesi asıl olarak `vixrex_owner_session` HMAC
  çerezi + `edit_token` üzerinden çalışıyor ve bu kanal Supabase Auth
  login'siz de tam CRUD yetkisi veriyor (kasıtlı — önizleme/handoff/rent-demo
  akışları için gerekli, kaldırılacak bir hata değil, ama "owner = auth.uid()"
  varsayımıyla yeni kod yazılırken hesaba katılmalı).
  **Aşağıdaki üç eski not artık geçersiz, kod ilerlemiş (kod kazanır
  kuralı gereği burada düzeltiliyor):** (1) "Kategori etiketi uyuşmazlığı"
  notu (bkz. altta) — etiket metinleri `shared/business_categories.json` ile
  senkron edildi (PR #319/commit `d159072`), CI drift kontrolü var; **ama bu,
  yukarıdaki YENİ P0 ilişkisel zincir sorunuyla karıştırılmamalı, o hâlâ
  açık.** (2) "#229 sitemap ürün URL'si üretmiyor" — çözüldü,
  `sitemap.xml/route.ts:157-170` ürün URL'lerini XML'e ekliyor. (3) "#255
  vitrin_views dolmuyor" — çözüldü, migration `20260823120000_...` canlıya
  uygulanmış ve `VitrinViewTracker.tsx` doğru çalışıyor. (4) Premium/PayTR
  "web PR'ları henüz deploy değil" notu (altta, 2026-08-17 gece) — artık
  eski: `api/paytr/callback/route.ts` commit `b13fcab` (2026-08-29) ile
  main'de, imza+tutar doğrulaması kodda mevcut.
- **CSP/görseller (2026-08-17):** #193'ün `img-src *` → allowlist dönüşümü
  vitrinlerin gerçekte kullandığı hostları (images.unsplash.com, api.qrserver.com)
  ve maps.google.com'u (frame-src) listeye eklememişti — görseller sessizce
  engelleniyordu. PR #197 ile eklendi + kontrat testi ve E2E görsel yükleme
  testi (canlı tarayıcı, main push'ta) eklendi. Font kırılmasıyla (#196) aynı
  desendi: CSP daraltılırken gerçek kaynaklar taranmadan liste kesilmişti.
- **CI onarımı (2026-08-17):** ci.yml #189'dan beri HİÇ çalışmıyordu — step-level
  `if` içinde `secrets` context'i kullanımı workflow'u GitHub'da geçersiz
  kılıyordu (0s "invalid workflow" fail). Düzeltildi (PR #197); Flutter/Next.js
  testleri, gitleaks ve auth check yeniden CI'da koşuyor. Ders: PR check
  listesinde ci.yml job'ları görünmüyorsa workflow geçersizdir, sessizce
  "yeşil" gibi görünür.
- **Güvenlik:** rent-demo klon RPC'si, audit-log yetkileri, varsayılan
  fonksiyon izinleri, upload/report oran sınırları güvenlik taramasıyla
  kapatıldı (PR #183-188, main'de). CSP/Sentry/CI güvenlik kontrolü ayrı
  bir oturumda (Kilo CLI) paralel işleniyor — bu dosya o işin bittiğini
  VARSAYMAZ, kodda doğrula.
- **Instagram ürün içe aktarma:** kod tam (Meta OAuth ile bağlanma, medya
  seçme, ürüne aktarma) ama **`INSTAGRAM_SYNC_ENABLED=false`** —
  `lib/config/instagram_sync_config.dart`. Meta App Review'a henüz
  başvurulmadı (2026-08-15 itibariyle). Bilinen eksikler: sayfalama yok
  (yalnız ilk ~25 medya), toplu seçim yok (tek tek), video/reels
  desteklenmiyor (yalnız fotoğraf). Araştırma:
  `docs/research/vixrex-google-urun-yerel-seo-2026-08-15.md`.
- **Vixrex Asistan rehberli tamamlama:** [[0002-vixrex-asistan-rehberli-tamamlama]]
  kararına göre kural-tabanlı (gerçek LLM çağrısı yok) — bilinçli, maliyet/
  tutarlılık gerekçesiyle.
- **Tek Asistan Planı tamamlandı (2026-08-17, kod doğrulaması 2026-08-19):**
  üç aşama da koda girdi — tek mesaj katalogu (`shared/vixrex_mesajlar.json`),
  tek şema (`shared/vitrin_alanlari.json`), tek "sırada ne var" motoru (iki
  istemci de şemadaki `zorunlu` işaretinden karar verir). CI'da
  `schema-drift` sapma kontrolü var (`.github/workflows/ci.yml`). Detay:
  `docs/tek-asistan-plani.md`.
- **Vixrex Asistan'dan yasal onay verilebiliyor (2026-08-20, PR #267):**
  kirala akışı Next.js'te tıkanıyordu — yayınlamak için gizlilik/şartlar/
  yayın izni onayı zorunluydu ama onu vermenin tek yolu Flutter üyelik
  paneliydi. Yeni `accept_store_legal_consent` RPC'si + `/api/owner-accept-legal`
  + `/legal/[type]` sayfası + PublishBar'da onay kutusu ile kapatıldı.
  Migration canlıya uygulandı (`chfulefxczbgurtgavtp`, `supabase db push`
  ile doğrulandı). Gerçek tarayıcıda uçtan uca test edilirken 2 entegrasyon
  hatası bulunup düzeltildi (sahip panelinin donmuş taslak kopyasından
  okuması, `stores`taki koşulsuz versiyon artırma tetikleyicisinin
  yayınlamayı yanlışça reddetmesi).
- **Karşılama üçe bölündü — "Hazır Vitrin Seç" (2026-08-20, PR #268):**
  onboarding sohbetindeki tek "Evet, Oluşturalım" yolu üçe ayrıldı: Hazır
  Vitrin Seç (Keşfet'i yalnız kiralık şablonlarla sohbetin üstüne açar),
  Sıfırdan Oluştur (eski yol, adı değişti), Bakınıyorum. Kategori artık
  kiralanan şablondan geliyor, ayrıca sorulmuyor bu yolda.
- **Kategori etiketi uyuşmazlığı (2026-08-20, henüz açılmadı):** Flutter
  (`business_category_config.dart`) ve Next.js (`vitrinProfile.ts`) 19
  kategoriden 7'sini farklı yazıyor (ör. "Danışmanlık" / "Hizmet &
  Danışmanlık") — DB'de kategori tablosu + foreign key ile kilitleme
  planı bu yüzden durduruldu, önce etiketler hizalanmalı. Next.js'in kısa
  hali kazanacak diye karar verildi ama kod henüz yazılmadı.
- **Dış denetim bulguları (2026-08-20, GitHub #229-266):** ChatGPT'nin
  çıkardığı, Kilo Code'un kod üzerinden doğruladığı 38 bulgu issue olarak
  kayıt altına alındı — sitemap ürün URL'si üretmiyor (#229), şube
  desteklenmiyor (#256), `vitrin_views` tablosu dolmuyor gibi görünüyor
  (#255) dahil. Triage tamamlandı (2026-08-25): 24 kapanmıştı, kalanlar
  etiketlendi; kod işi olan tek aday #235'ti.
- **Şablon görselleri kendi depomuza taşındı (2026-08-25, #235,
  commit `638e863` yerelde — push bekliyor):** hazır vitrin görselleri
  artık Unsplash değil, kendi `category-templates` bucket'ımızdan
  servis ediliyor. Canlıdaki 349 satırdan 23'ünün Unsplash adresi ZATEN
  ölmüştü (404) → pasifleştirildi (hiçbir vitrin/ürün etkilenmedi).
  Eski adresler yeni `source_url` kolonunda. Havuzu BÜYÜTME kapsam
  dışında bırakıldı — ayrı iş. Migration canlıya Management API ile
  uygulandı ve `schema_migrations`'a kaydedildi.

## Kalıcı kararlar (ADR'ler)

- [[0001-vixrex-core-omurga-ve-uzman-beyinler]] — hangi mantık tek omurgada, hangisi istemciye özel.
- [[0002-vixrex-asistan-rehberli-tamamlama]] — rehberlik motoru neden kural-tabanlı, LLM değil.
- [[0003-vault-baglam-kurali]] — bu dosyanın kendisinin var oluş gerekçesi.

## Diğer kaynaklar (bu dosyanın YERİNE geçmez, tamamlar)

- `AGENTS.md` — ajan başlangıç sırası, yetki sınırları, skill akışı.
- `VIXREX_RULES.md` — ürün/güvenlik/kanıt/canlı sistem sınırları (operasyonel kurallar).
- `docs/agents/repository-guide.md` — teknik depo haritası.
- `docs/agents/store-editor-controller-parcalama.md` — devam eden controller parçalama işinin durumu.
- `docs/vitrin-alan-semasi.md` — vitrin alanlarının tek kaynağı (canonical: `public_web/src/lib/vitrinFieldSchema.ts`).
- `docs/durum.md` — güncel durum notları.
- `docs/kok-neden-arastirmasi.md` — kök neden araştırmaları.
- `docs/e2e-otomasyon-plani.md` — E2E otomasyon planı.
- `docs/dal-durum-haritasi.md` — dal durum haritası.
- `docs/arsiv/` — tamamlanmış işlerin arşivi (ör. `vixrex-asistan-13-faz-plani-2026-08-06`).
- `docs/research/` — araştırma notları (ör. google ürün/yere SEO,
  `vixrex-web-mobil-tamlik-denetimi-2026-08-30.md` — web+mobil mimari
  tamlık denetimi, açık P0: ürün kategorisi ilişkisel zincir kopukluğu).
- `docs/adr/` — kalıcı mimari kararlar (0001 omurga, 0002 asistan, 0003 vault kuralı).
