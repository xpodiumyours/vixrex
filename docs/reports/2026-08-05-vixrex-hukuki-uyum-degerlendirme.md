# VixRex Türkiye Hukuki Uyum Değerlendirme Raporu

**Tarih:** 5 Ağustos 2026  
**Hazırlayan:** Kilo otomasyon (kod tabanı taraması)  
**Kanıt seviyesi:** 3 — Kodda görüldü + statik kontrol geçti  
**Uyarı:** Bu belge hukuk müşavirliği görüşü veya bağlayıcı hukuk tavsiyesi değildir. **Canlıya çıkış için mutlaka bir Türkiye’de bilişim hukuku, KVKK ve İletişim Kurumu avukatından yazılı görüş alınmalıdır.**

---

## A. Veri Envanteri

### A.1. Veri sorumlusu kimliği

| Katman | Kaynak | Değer | Durum |
|---|---|---|---|
| Flutter (kod sabit) | `lib/config/legal_config.dart:5-8` | `Aksakal Ticaret` | Placeholder fallback |
| Flutter (runtime env) | `dart-define LEGAL_DATA_CONTROLLER_TITLE` | Uygulama build zamanı belirlenir | Ayarlanmadıysa fallback kullanılır |
| Public web (statik JSX) | `public_web/src/app/privacy/page.tsx:16` | `Aksakal Ticarat` | Hardcode, fallback'den farklı |
| LEGAL_DOCUMENTS.sql | `LEGAL_DOCUMENTS.sql:21` | `[ŞİRKET ÜNVANI]` | **Placeholder — doldurulmamış** |
| Flutter legal_screen | `legal_screen.dart:474` | `vixrex.app@gmail.com` (`LegalConfig.privacyEmail`) | Fallback hardcoded |
| Public web privacy | `privacy/page.tsx:57` | `Xpodiumyours@gmail.com` | **Diğer ekrandan farklı e-posta** |

**BULGULU:** Veri sorumlusu kimliği üç farklı yerde tutarlı değil. `LEGAL_DOCUMENTS.sql` hâlâ `[ŞİRKET ÜNVANI]`, `[ADRES]`, `[E-POSTA]` placeholderlarını içirir. KVKK m.10 ve GDPR Article 13-14’e göi **zorunlu** olan veri sorumlusu kimliği eksiktir.

### A.2. İşlenen veri kategorileri ve toplama noktaları

| Veri kategorisi | Toplama noktası | Kanıt | Amaç | Hukuki sebep |
|---|---|---|---|---|
| E-posta, şifre hash | `auth_screen.dart` / `auth_service.dart` | `auth.users` tablosu | Hesap oluşturma, giriş | KVKK m.5/2-c (sözleşme ifası) |
| İşletme adı, adres, konum (lat/lng), telefon, WhatsApp, e-posta, website | Flutter editör → `store_publish_payload_builder.dart` → `stores` tablosu → `PUBLIC_STORE_SELECT` (page.tsx:141) | Anon SELECT'te açık | Vitrin görüntüleme | KVKK m.5/2-f (meşru menfaat) + açık rıza |
| Kullanıcı içerikleri (logo, galeri, ürün foto/metin) | `store_shelf_upload_service.dart` / `products` tablosu | Storage + DB | Vitrin içeriği | Açık rıza |
| Instagram kullanıcı adı, medya, token | `instagram_sync_service.dart` / `store_instagram_connections`, `store_instagram_tokens` | RPC ile token alınıyor | Instagram entegrasyonu | Açık rıza |
| Randevu: müşteri adı, telefon, notlar, saat, hizmet | `booking_service.dart` → `create_appointment_request` RPC → `appointments` tablosu | `get_appointment_by_token` RPC ile token sahibine dönülüyor | Randevu yönetimi | KVKK m.5/2-c + açık rıza |
| IP, User-Agent, oturum geçmişi | `vitrin_views` tablosu, `v3_logs` | `meta_data_deletion_requests`, loglar | Platform güvenliği, analitik | KVKK m.5/2-f (meşru menfaat) |
| Çerez tercihi, consent | `cookieConsent.ts` (localStorage) | — | Çerez yönetimi | KVKK m.5/1 (açık rıza) |

### A.3. Üçüncü taraf tedarikçiler

| Tedarikçi | Ülke/Region | Veri erişimi | Alt işleyen | DPA/SCC |
|---|---|---|---|---|
| Supabase | AWS US-East-1 (varsayılan) | Veritabanı, Auth, Storage | Belirli değil | **Yok** |
| Vercel | Küresel edge | Web hosting | Belirli değil | **Yok** |
| Google (GA4) | ABD | Analitik (IP anonimleştirilerek) | Belirli değil | **Yok** |
| Google (Harita) | ABD | Harita embed linki | Belirli değil | **Yok** |
| Meta (Instagram) | ABD | Instagram token/medya | Belirli değil | **Yok** |
| Cloudflare (Turnstile) | Küresel | Bot korumu | Belirli değil | **Yok** |
| Google (reCAPTCHA) | ABD | Bot korumu | Belirli değil | **Yok** |

**BULGULU:** Hiçbir tedarikçi için KVKK m.9 uygunluğu sağlayan geçerli DPA/SCC yok. Supabase’un veri merkezi bölgesi `.env.local.bulut-yedek`’de `chfulefxczbgurtgavtp.supabase.co` olarak gösteriliyor (ABD varsayımı). VERBİS kaydı henüz yapılmamış.

### A.4. Saklama süreleri

| Veri | Saklama süresi | Otomatik silme |
|---|---|---|
| accounts/users | Hesap silinene kadar | `delete_user_account()` RPC (manuel tetikleme) |
| stores | Hesap silinene kadar | `delete_user_account` cascade |
| appointments | **Sınırsız** | Yok |
| vitrin_views | **Sınırsız** | Yok |
| Instagram token | Bağlantı kırılana kadar | `disconnect` RPC |
| cookie consent | Tarayıcı depolama süresince | Yok |

**BULGULU:** `appointments`, `vitrin_views` ve diğer bazı tablolar için otomatik saklama süresi ve silme mekanizması yok.

---

## B. Risk Matrisi

| # | Risk | Kanıt | Legal dayanak | Öncelik |
|---|---|---|---|---|
| B1 | **Tek “master” kutuyla üç farklı hukuki rıza tek seferde veriliyor / geri alınamıyor** | `legal_consent_section.dart:97-118` — `onChanged` bir kutuyla `onPrivacyChanged(true)`, `onTermsChanged(true)`, `onPublicationChanged(true)` hep birlikte çağrılıyor | KVKK m.5/1, m.11; GDPR Art. 7 | **Kritik** |
| B2 | **Yasal belgelerde placeholder şirket kimliği** | `LEGAL_DOCUMENTS.sql:21` — `[ŞİRKET ÜNVANI]`, `[ADRES]`, `[E-POSTA]` | KVKK m.10; 5651 m.4 | **Kritik** |
| B3 | **Veri sorumlusu kimliği platform içinde tutarsız** | `privacy/page.tsx:57` → `Xpodiumyours@gmail.com`; `legal_config.dart:25` → `vixrex.app@gmail.com`; `LEGAL_DOCUMENTS.sql:21` → `[E-POSTA]` | KVKK m.10 | **Kritik** |
| B4 | **Versiyon çelişkisi: DB’de 07-07, kodda 07-05 fallback** | `LEGAL_DOCUMENTS.sql:15` → `privacy-2026-07-07-v1`; `store_editor_controller.dart:545` → `privacy-2026-07-05` | KVKK m.10; GDPR Art. 7(2) | Yüksek |
| B5 | **Mağaza içeriği için hukuka aykırı bildirim-kaldırma kanalı yok** | `api/report-abuse/route.ts:7` — yalnızca `articleId` (blog), `storeId`/`slug`/`contentId` yok | 5651 m.8, m.9 | **Kritik** |
| B6 | **OWNER_SESSION_SECRET production env dosyasında eksik** | `.env.local.bulut-yedek` — 10 satır, `OWNER_SESSION_SECRET` yok; Vercel dashboard’da belki var ama kod/ayar belgesinde yok | KVKK m.12 (sır yönetimi) | Yüksek |
| B7 | **PUBLIC_STORE_SELECT anon için PII açıklar** | `page.tsx:141-150` — `phone, email, latitude, longitude` anon SELECT’te | KVKK m.5/2-f (amaçla sınırlılık); GDPR Art. 5(1)(c) | Orta |
| B8 | **get_appointment_by_token plaintext PII döndürüyor** | `20260622_add_booking_system.sql:462-484` — `customer_name`, `customer_phone`, `customer_notes` | KVKK m.5/2-c; 6630 (randevu saklama) | Orta |
| B9 | **get_public_booking_slots diğer müşterilerin isimlerini (maskeli) ve pending flag’ini sızdırıyor** | `20260622_add_booking_system.sql:249-262` | KVKK m.5/2-f | Orta |
| B10 | **Çerez politikası sayfası yok** — banner “yakında yayınlanacaktır” diyor | `CookieBanner.tsx:51` | KVKK Çerez Rehberi; e-İleti m.5 | Yüksek |
| B11 | **GA4 / analitik çerez eksikliği privacy metnine çelişiyor** | `privacy/page.tsx:39` “Üçüncü taraf çerez veya izleme teknolojisi kullanılmaz” ama `AnalyticsLoader.tsx:21-38` GA4 yükleniyor | KVKK m.10 | Orta |
| B12 | **Marketing consent kategorisi ama hiçbir marketing script’i yok** | `cookieConsent.ts:7` (marketing: boolean), `AnalyticsLoader.tsx` — sadece analytics yükleniyor | KVKK Çerez Rehberi | Düş |
| B13 | **non-auth kullanıcılar için veri dışa aktarma yok** | `auth_service.dart:194` sadece `currentUser` gerektiriyor; anon PreviewEditorPanel’da anon veri yok | KVKK m.11 (eruşim hakkı) | Orta |
| B14 | **randevu formunda CAPTCHA yok** — sadece 5 randevu/24h/phone limiti | `create_appointment_request` RPC — `20260622_add_booking_system.sql:310-318` | KVKK m.12; kişisel veri güvenliği | Orta |
| B15 | **Üretken AI devredi dışı ama OpenAI anahtarı env’de** | `vixrex-assistant-nlu/index.ts:15` — `assistantEnabled = false`; `.env.example` OPENAI_API_KEY | KVKK m.5/2-f; Rehber 15 | Düş |
| B16 | **Instagram scope yalnızca basic** | `.env.example:23` — `INSTAGRAM_SCOPES=instagram_business_basic` | KVKK m.5/2-c (veri minimizasyonu) | Düş |
| B17 | **appointment_reschedule_requests saklama süresi yok** | `20260622_add_booking_system.sql:48-54` | 6630 | Orta |
| B18 | **GDPR/KVKK “hak iddiali” mekanizması eksik** — sadece Flutter auth_user export var | `auth_service.dart:194-262` | KVKK m.11 | Orta |
| B19 | **legal_acceptance_events log trigger’ı var ama store update RPC'leri bypass edebilir** | `store_publish_payload_builder.dart:97` — `explicit_consent_given` mapping farklı (store_consent_accepted değil) | KVKK m.5/1; GDPR Art. 7(2) | Orta |
| B20 | **privacy metninde “fatura, muhasebe” saklama sözü var ama ödeme sistemi yok** | `privacy/page.tsx:43-44` | 6502 (e-fatura) | Düş |

---

## C. Yasal Mevzuat Uyumu Detayları

### C.1. 6698 sayılı KVKK

| Madde | Durum | Açıklama |
|---|---|---|
| m.3 (Amaç) | **Eksik** | Amaçlar kısmen belgelenmiş (`LEGAL_DOCUMENTS.sql:28-29`) ama veri akış matrisi eksik. Her alan için amaç/hukuki sebep/ilişki ayrı olarak belgelense de, sistemdeki her yazma noktası bunları tutmuyor. |
| m.4 (İlkeler) | **Kısmen** | Belirli, açık, meşru amaç var. Amaçla bağlantılılık ve sınırlılık `privacy/page.tsx` metninde genel ifadelerle geçiyor; kodda ayrı ayrı doğrulama yok. |
| m.5 (Hukuki sebep) | **Kısmen** | Sözleşme ifası, açık rıza, meşru menfaat belirtilmiş. Ancak müşteri randevu verileri için sadece açık rıza var — sağlık/veri özel nitelik varsa daha yüksek seviyeye gerekir. |
| m.7 (Veri saklama) | **Yetersiz** | `appointments`, `vitrin_views`, `article_reports` için otomatik silme yok. `delete_user_account` hepsini siler ama zamanlı/otomatik değil. |
| m.9 (Yurt dışı aktarım) | **YOK** | Supabase, Vercel, Google, Meta, Cloudflare tüm yurt dışı. DPA/SCC yok. VERBİS kaydı yok. |
| m.10 (Aydınlatma) | **YETERSİZ** | Aydınlatma metni placeholderlar içeriyor. Şirket kimliği tutarsız. |
| m.11 (Haklar) | **Kısmen** | `exportMyData()`, `deleteAccount()` Flutter’da var. Ama: anon kullanıcılar (vitrin ziyaretçileri) erişim/silme hakkı için kanallar yok. Randevu verisi sahibinden başka kimse token ile erişemeyecek ama `reporter_ip` gibi veriler anonim toplama var. |
| m.12 (Güvenlik) | **Kısmen** | RLS var, `edit_token` SELECT’ten çıkarıldı, token hash’lenerek saklanıyor. Ama `marketing` çerez kategorisi tanımlı ama uygulanmıyor; reCAPTCHA skoru 0.3 (düşük). `OWNER_SESSION_SECRET` production’da belirsiz. |

### C.2. 5846 sayılı Fikyol Hakları

| Madde | Durum | Açıklama |
|---|---|---|
| Madde 3 (Telifsiz) | **Risk** | `terms-2026-07-07-v1`’de “fikri mülkiyet… [ŞİRKET]’a aittir” placeholder. Kullanıcı içeriklerine dair yeterince ayrıntılı değil. |
| İçerik sorumluluğu | **Risk** | `5651 m.8` uyarınca Türkiye’de yer sağlayıcı olarak işlev gördüğünde hukuka aykırı içerikten sorumluluk doğar. VixRex’in vitrin barındırıcılığı rolü net değil; düzenleme yapılmamış. |

### C.3. 5651 sayılı Medya Yasası / İletişim Kurumu

| Madde | Durum | Açıklama |
|---|---|---|
| m.3 (TKİB kaydı) | **Gereksiz** | Medya kuruluşu değil. |
| m.4-5 (Yer sağlayıcı) | **Koşula bağlı** | VixRex, kullanıcıların kendi içeriklerini yayınladığı bir platform. Eğer “hizmet sunucu” statüsünde 10.000+ aylık görüntülenme/100.000+ kullanıcıya ulaşıyorsa IYS/İletişim Kurumu kaydı zorunlu olabilir. |
| m.8 (Telif ihlali) | **Mevcut kısmen** | Bildir-imzalama mekanizması tanımı var ama sadece blog yazıları için. |
| m.9-10 (Hukuka aykırı içerik) | **Eksik** | Hukuka aykırı içerik bildirim-kaldırma kanalı yalnızca blog yazıları için var. Mağaza vitrini içeriği için **yok**. |

### C.4. 6502 sayılı Tüketici Hukuku / Mesafeli Sözleşmeler

| Madde | Durum | Açıklama |
|---|---|---|
| 6502 | **Değil** | Vixrex ücretli hizmet satmıyor (hâlâ). `premium_config.dart` yalnızca OCR limiti ve abonelik yok. Bu kural altında **değil**. |
| Mesafeli sözleşme | **Değil** | Satış/ödeme yok. |
| 6563 (İletişim Kurumu) | **Gereksiz** | Elektronik ileti göndermiyor (WhatsApp yönlendirme var, ama VixRex göndermiyor). |

### C.5. Ticaret Bakanlığı / İYS

| Madde | Durum | Açıklama |
|---|---|---|
| 6563 m.2 | **Gereksiz** | Ticari elektronik ileti göndermiyor. Instagram entegrasyonu var ama VixRex mesaj göndermiyor. |
| İYS kaydı | **Gereksiz** | Aynı sebep. |

---

## D. Teknik Kontrol Sonuçları

### D.1. Consent / Consent Management

| Bileşen | Dosya | Durum |
|---|---|---|
| Flutter consent UI | `legal_consent_section.dart:97-118` | ❌ Tek checkbox → 3 consent ayrılmamış |
| Flutter legal validator | `store_publish_legal_validator.dart:6-18` | ✅ Üç ayrı kontrol var (ama UI onları birleştiriyor) |
| DB trigger | `20260628_add_versioned_legal_documents...sql:160-290` | ✅ separate event log; ama UI’dan gelen “hepsi aynı anda” veri DB’ye bire bir yansıyor |
| Public web consent | `CookieBanner.tsx:54-108` | ✅ kategori ayrımı, ama çerez politikası metni eksik |
| Legal doc version | `LEGAL_DOCUMENTS.sql:15`, `store_editor_controller.dart:545` | ❌ 07-07 vs 07-05 çelişkisi |

### D.2. RLS / Yetki

| Tablo/Fonksiyon | RLS | Not |
|---|---|---|
| `stores` SELECT | ✅ `is_published=true` (anon), `user_id=auth.uid()` (auth) | ❌ `edit_token` SELECT’ten çıkarıldı (`20260717_close_store_authorization_gap.sql:7-27`) ama `PUBLIC_STORE_SELECT` telefon/email/lat-lng içeriyor |
| `appointments` SELECT | ✅ sadece owner | ✓ |
| `get_appointment_by_token` | SECURITY DEFINER | ❌ plaintext PII döndürüyor (müşteri kendisi token alıyor ama rate limit yok) |
| `get_public_booking_slots` | SECURITY DEFINER, anon’a grant | ❌ `confirmed_names` (maskeli) + `has_pending` diğer müşterilerin rezervasyon bilgisini veriyor |
| `owner_sessions` | ✅ Hash’li, tek kullanımlık | ✓ (HMAC+timingSafe) |
| `delete_user_account` | SECURITY DEFINER | ✅ auth-only; tüm veriyi siliyor |

### D.3. Çerezler

| Çerez | Amaç | Gerekli mi | Rıza |
|---|---|---|---|
| localStorage `vixrex_cookie_consent` | Consent kaydı | ✅ | Gerekli |
| GA4 gtag | Analitik | ❌ | ✅ anon’a verilmiş (AnalyticsLoader.tsx:21) |
| Session cookie | Sahip oturumu | ✅ | Gerekli |

**Bulgu:** GA4 `anonymize_ip: true` ile yapılandırılmış. Ama `privacy/page.tsx` “Üçüncü taraf çerez veya izleme teknolojisi kullanılmaz” diyor — **çelişki**.

### D.4. Veri silme / ihrac

| Özellik | Durum |
|---|---|
| Hesap silme (`delete_user_account`) | ✅ RPC, cascade delete, auth-only |
| Veri dışa aktarma (`exportMyData`) | ✅ Flutter’daki auth user için; edit_token, instagram token çıkarılıyor |
| Meta data deletion callback | ✅ `/api/meta/data-deletion`, `meta_data_deletion_requests` tablosu |
| Cookie consent | ✅ localStorage, geri alma mekananız var |
| Anon veri (vitrin_view IP) | ❌ silme mekanizması yok |

### D.5. İçerik bildirim / kaldırma

| İçerik tip | Bildirim mekanizması | Durum |
|---|---|---|
| Blog yazısı | `/api/report-abuse` → `article_reports` | ✅ |
| Mağaza vitrini | — | ❌ YOK |
| Ürün fotoğrafı | — | ❌ YOK |
| Instagram medyası | — | ❌ YOK |

### D.6. Üretken AI

| Bileşen | Durum |
|---|---|
| `vixrex-assistant-nlu/index.ts` | `assistantEnabled = false` (satır 15). OpenAI çağrısı yapılmıyor. |
| OpenAI API key | `.env.example`’da tanımlı, production’da belki tanımlı | 
| Prompt | “Yasal onay, kimlik, ödeme ve hassas kişisel veri isteme veya çıkarma” yönünde (satır 109) |

### D.7. Reklam / Satış sistemi

| Özellik | Durum |
|---|---|
| Premium abonelik | ❌ `premium_config.dart` — sadece OCR limiti, abonelik/yenileme/ödeme yok |
| Satıcı komisyonu | ❌ yok |
| Mesafeli sözleşme | ❌ yok |
| Fiyat/ödeme ekranı | ❌ yok |

---

## E. Eksikler / Aksiyon Gerektirenler

### E.1. Kritik — 72 saat içinde düzeltilmeli

1. **Consent UI tekrarlanmalı**  
   - `legal_consent_section.dart`’da master checkbox kaldırılır.  
   - Üç ayrı kutu: (a) Aydınlatma metni (KVKK), (b) Kullanım şartı, (c) Kamuya yayınlama açık rızası.  
   - Her bir ayrı ayrı işaretlenip ayrı ayrı kapatılabilir.  
   - `store_editor_controller.dart`’daki `isLegalPublishReady` zaten 3’ü kontrol ediyor; `publish()` için de hepsi gerekli.

2. ** Yasal belgeler placeholderlarından kurtarılmalı**  
   - `LEGAL_DOCUMENTS.sql`’deki `[ŞİRKET ÜNVANI]`, `[ADRES]`, `[E-POSTA]` placeholderları gerçek değerlerle değiştirilmeli.  
   - Flutter `legal_config.dart` fallback değerleri (`Aksakal Ticaret`, `vixrex.app@gmail.com`) DB’deki metinlerle **eşleştilmeli**.  
   - `privacy/page.tsx`’deki `Xpodiumyours@gmail.com` tüm platformda aynı olacak şekilde düzeltilmeli.

3. **Versiyon çelişkisi giderilmeli**  
   - `store_editor_controller.dart:545-558` fallback’ları DB’deki `privacy-2026-07-07-v1` sürümüyle aynı yapılmalı.

4. **Hukuka aykırı içerik bildirim mekanizması mağaza vitrinine eklenmeli**  
   - `api/report-abuse/route.ts` genişletilmeli: `storeSlug` veya `storeId` alıp `store_content_reports` tablosuna kaydeder.  
   - `20260622_add_booking_system.sql` migration’da `article_reports` sadece makale için; store için yeni tablo.  
   - Kaldırma kararı için admin paneli/güvenlik ekranı kurulmalı (5651 m.9).

5. **OWNER_SESSION_SECRET production’da kontrol edilmeli**  
   - `.env.local.bulut-yedek` eksik. Vercel dashboard’dan doğrulanmalı; eksikse `assertOwnerSessionConfigured()` hata verir, owner preview kırılır.  
   - Güvenli 32+ karakterlik secret en azından fallback olarak yazılmalı (kodda değil, env’de).

6. **Çerez politikası sayfası yayınlanmalı**  
   - Cookie banner’daki “Resmi çerez politikası yakında yayınlanacaktır” yerine gerçek bir `/cookie-policy` sayfası.  
   - Çerez envanteri tablosu içermeli (amac, süre, taraf).

7. **Privacy metnindeki çelişki düzeltilmeli**  
   - `privacy/page.tsx:39` “Üçüncü taraf çerez veya izleme teknolojisi kullanılmaz” GA4 kullanımına göre güncellenmeli.

### E.2. Orta vadeli — canlıya çıkmadan önce

8. **KVKK m.9 yurt dışı transfer** — Supabase/Vercel/Google/Meta/Cloudflare için DPA/SCC hazırlanmalı; VERBİS kaydı yapılmalı.
9. **Veri saklama süreleri** — `appointments`, `vitrin_views` için retention policy (ör. 2 yıl sonra soft-delete).
10. **Rate limiting** — `get_appointment_by_token` için token bazlı rate limit.
11. **Marketing consent** — Ya marketing script ihtiyacını kapat, kategoriyi kaldır; ya da gerçek marketing özelliği ekle.
12. **Anon veri erişim** — Vitrin ziyaretçisinin KVKK m.11 hakları için anon erişim/reklam-gizliliği mekanizması tasarla (şu an sadece auth user için export var).
13. **get_public_booking_slots** — `confirmed_names` ve `has_pending` kaldır; yalnızca `slots_left` yeterli.
14. **Legal consent event trigger bypass kontrolü** — `store_publish_payload_builder.dart:97` `explicit_consent_given` mapping’inin `publication_consent_accepted`e doğru eşlendiği doğrulanmalı.

---

## F. DURDUR Kararı

### DURDUR — canlıya çıkış engeli var

Aşağıdaki **kritik** risklerden en az ikisi düzeltilmeden (kanıtlanmamış yerelde + kod review’u geçmiş) VixRex’in geniş kitleye açık yayını **yasal olarak destansız değildir**:

| # | Risk | Minimum düzeltme | Dosya |
|---|---|---|---|
| B1 | Tek consent kutusu | 3 ayrı kutu | `legal_consent_section.dart` |
| B2 | Placeholder yasal belgeler | Gerçek şirket kimliği | `LEGAL_DOCUMENTS.sql` |
| B3 | Tutarsız veri sorumlusu | Tek e-posta kimliği | `privacy/page.tsx`, `legal_config.dart` |
| B5 | Mağaza içeriği bildirim yok | store content report API | `api/report-abuse/route.ts` |
| B6 | OWNER_SESSION_SECRET yok | env/production kontrol | `.env.local.bulut-yedek`, Vercel |

### Önerilen çıktı

1. **Hukukçu onayı zorunlu.** Özellikle B1 (consent), B2 (belge placeholder), B5 (içerik bildirim) ve B6 (secret) için bir bilişim hukuku avukatının kodu/örnek ekranları gözden geçirmesi gerekir.
2. **Yertinde düzeltmelerden sonra** yerel Supabase + Vercel staging’de doğrulanır.
3. **Canlıya çıkma öncesi:** Kanıtlanmış düzeltmeler, `code-review` skill’i çalıştırılır.
4. **Canlıda doğrulama:** Gerçek bir demo mağazanın yayınlı `/v/:slug` sayfası cihazda açılır; consent akışı, footer’daki veri sorumlusu linki, çerez banner’ı, hukuka aykırı bildirim butonu gözle kontrol edilir.

### Etki: Kapatılan kapılar

- Eğer yalnızca consent ve belge düzeltilirse, B5 (hukuka aykırı içerik) hala var. 5651 m.8-9’a göre bu engellemeyi açmaya kadar **halka açık her mağaza linkinin Google aramalarında indexlenmesi BTK/İletişim Kurumu kararına bağlanabilir.**
- Eğer sadece UI/UX düzeltilirse, B2 (placeholder) hukuki aydınlatma eksisini çözer. Ama VERBİS, SCC, çerez envanteri eksikliği halinde **KVKK m.9 ve m.12** cezası doğmaya devam eder.
- Eğer sadece `.env` düzeltilirse, consent ve içerik bildirim eksikliği hukuki temel eksikliğini korur.

---

## Ek: Dosya Referans Dizini

| Dosya | Konum | Açıklama |
|---|---|---|
| `LEGAL_DOCUMENTS.sql` | repo root | Yasal metinler — placeholder içeriyor |
| `lib/config/legal_config.dart` | Flutter | Fallback şirket kimliği |
| `lib/widgets/editor/legal_consent_section.dart:97` | Flutter | **Master consent checkbox — kritik** |
| `lib/controllers/store_editor_controller.dart:545` | Flutter | **Fallback version 07-05 — çelişki** |
| `lib/services/auth_service.dart:194` | Flutter | `exportMyData`, `deleteAccount` |
| `lib/services/store_publish_legal_validator.dart` | Flutter | 3 consent kontrolü |
| `lib/services/store_publish_payload_builder.dart:97` | Flutter | `explicit_consent_given` mapping |
| `public_web/src/app/v/[slug]/page.tsx:141` | Next.js | `PUBLIC_STORE_SELECT` — PII içiyor |
| `public_web/src/app/privacy/page.tsx` | Next.js | **Statik privacy — farklı e-posta** |
| `public_web/src/app/api/report-abuse/route.ts:7` | Next.js | **Yalnızca article_id** |
| `public_web/src/components/cookie-consent/*` | Next.js | Cookie banner + GA4 anonçel |
| `public_web/src/app/robots.txt/route.ts` | Next.js | robots.txt |
| `public_web/src/app/sitemap.xml/route.ts` | Next.js | sitemap.xml |
| `public_web/.env.local.bulut-yedek` | .env | **OWNER_SESSION_SECRET yok** |
| `supabase/migrations/20260622_add_booking_system.sql:148` | Supabase | `get_public_booking_slots` — confirmed_names |
| `supabase/migrations/20260622_add_booking_system.sql:432` | Supabase | `get_appointment_by_token` — plaintext PII |
| `supabase/migrations/20260717_close_store_authorization_gap.sql:7` | Supabase | `edit_token` SELECT’tan çıkarıldı |
| `supabase/migrations/20260628_add_versioned_legal_documents...sql:160` | Supabase | legal_acceptance_events trigger |
| `supabase/functions/vixrex-assistant-nlu/index.ts:15` | Edge fn | `assistantEnabled = false` |
| `docs/research/vixrex-hukuki-uyum-2026-08-05.md` | Research | Bu raporun dayandığı araştırma belgesi |
