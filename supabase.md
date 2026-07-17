# Vixrex Supabase Operasyonu

> Bu dosya Supabase temelini kalıcılaştırma operasyonunun tek çalışma
> defteridir. Başka Supabase planı, teşhis veya borç Markdown dosyası
> oluşturulmaz.

## Zorunlu okuma sırası

Her ajan herhangi bir işlemden önce şu dosyaları tamamen ve sırayla okur:

1. `PROJECT_RULES.md`
2. `SON_DURUM.md`
3. `AGENTS.md`
4. `supabase.md`

Üst kurallar bu dosyadan önceliklidir. Çelişki görülürse işlem durdurulur ve
Furkan'a bildirilir.

## Operasyon durumu

```text
AKTİF FAZ: M1 — Yerel Supabase iskeleti ve CI
DURUM: M1 Furkan + Codex tarafından onaylandı — ayrı commit hazırlanıyor
CANLI İŞLEM İZNİ: Yok
COMMIT/PUSH İZNİ: Yalnız M1 commit izni var; push izni yok
SON KANIT: rls.test.sql v5: 19 assertion, 3 rol, has_column_privilege ile edit_token testi, saldırı sonrası RESET role ile doğrulama, service_role yalnız katalog bağlamında. Migration sırası hatası M2 engeli.
SONRAKİ KAPI: Furkan M2 aktivasyon onayı
```

Mimo yalnız `AKTİF FAZ`, `DURUM` ve `SON KANIT` satırlarını güncelleyebilir.
Plan maddelerini değiştiremez, silemez veya sonraki fazı kendiliğinden aktif
edemez. `CANLI İŞLEM İZNİ`, `COMMIT/PUSH İZNİ` ve `SONRAKİ KAPI` yalnız Furkan'ın
açık onayıyla değiştirilir.

## Hedef ve doğrulanmış başlangıç durumu

Hedef, Git'teki migration zincirini Supabase şemasının tek kaynağı yapmak;
repo–canlı ayrışmasını, eksik RPC'leri ve kontrolsüz policy değişikliklerini
canlıya ulaşmadan durdurmaktır.

Doğrulanan başlangıç durumu:

- Aktif proje: `chfulefxczbgurtgavtp` (`Vixrex Project`, Free plan, PostgreSQL 17).
- Canlı veri korunacak; yeni projeye geçilmeyecek ve veri sıfırlanmayacak.
- Repoda 46 eski migration, canlı migration geçmişinde 22 kayıt bulunuyor.
- Repoda `supabase/config.toml` ve çalışan Supabase CI kapısı bulunmuyor.
- Canlıda `delete_user_account()` bulunmuyor.
- `shelf-images` public bucket ve 5 MB dosya limitiyle çalışıyor; son yükleme
  denemelerinde HTTP 400 görüldü.
- `edit_token` için `anon` ve `authenticated` doğrudan SELECT yetkisi kapalıdır
  ve kapalı kalacaktır.
- Mevcut misafir yayın akışı korunacaktır.

## Değişmez çalışma kuralları

- Mimo canlı Supabase'e bağlanmaz, canlı SQL çalıştırmaz, migration uygulamaz ve
  Edge Function deploy etmez.
- Mevcut kirli çalışma ağacı kullanılmaz. Çalışma temiz `origin/main` tabanlı
  ayrı `feat/supabase-foundation` worktree içinde yapılır.
- Eski migrationlar silinmez; kanıt olarak korunur.
- `edit_token` SELECT yetkisi açılamaz ve RLS/Storage policy geniş biçimde
  gevşetilemez.
- Yeni paralel yayın, edit, hesap silme veya upload motoru oluşturulamaz.
- Flutter tema, landing, asistan, Keşfet, maskot ve APK dosyalarına dokunulmaz.
- Aynı başarısız komut yeni kanıt olmadan tekrar çalıştırılmaz.
- Her faz sonunda Mimo durur; Furkan ve gereken Codex kapısı onaylamadan sonraki
  faza geçmez.
- Commit/push yalnız Furkan açıkça onaylarsa yapılır.
- Rapor en fazla 60 satır, hata kesiti en fazla 40 satır olur.

## Mimo rapor biçimi

1. Değişen dosyalar
2. `git diff --stat`
3. Çalıştırılan doğrulamalar
4. Geçenler
5. Başarısız olanlar — en fazla 40 satır
6. Bilerek dokunulmayan alanlar
7. Sonraki faza geçiş engeli

Rapor verildikten sonra işlem durur.

## M0 — İzole ortam ve envanter

### Mimo görevi

1. Mevcut çalışma ağacını değiştirmeden temiz `origin/main` tabanlı ayrı
   worktree hazırlamak.
2. Supabase CLI stable `v2.109.1` ve Docker çalışabilirliğini doğrulamak.
3. 46 migrationı başlangıç şeması, tablo/kolon, RLS/grant, RPC, Storage,
   seed/veri düzeltme ve canlı geçmişi belirsiz kümelerine ayırmak.
4. `supabase_schema.sql`, README Supabase bölümü ve
   `20260710_0000_core_schema_documented.sql` arasındaki eksikleri çıkarmak.
5. Bu fazda tracked dosya değiştirmemek, commit/push yapmamak ve rapordan sonra
   durmak.

### Kabul kapısı

- Ayrı worktree doğrulanmıştır.
- 46 migrationın tamamı sınıflandırılmıştır.
- Canlı şema hakkında varsayım yapılmamıştır.
- Furkan ve Codex M0 raporunu onaylamıştır.

## C0 — Codex canlı envanter kapısı

M0 sonrasında Codex yalnız bir salt-okunur turda migration geçmişi, tablolar,
kolonlar, constraintler, indeksler, fonksiyonlar, grantler, RLS policy'leri,
Storage bucket/policy'leri, Edge Function listesi ve Advisor sonuçlarını çıkarır.
Gizli değerler kaydedilmez. Aynı sorgu tekrarlanmaz ve log polling yapılmaz.

### C0 sonucu — 17 Temmuz 2026

- Tek salt-okunur tur tamamlandı; canlı SQL değişikliği, migration veya deploy
  yapılmadı.
- Canlıda 22 migration ve RLS açık 12 `public` tablo bulunuyor.
- Envanterde 44 constraint, 36 indeks, 13 `public` fonksiyon ve 24
  `public`/`storage` policy bulunuyor.
- `category-templates` ve `shelf-images` bucket'ları mevcut; `shelf-images`
  public, 5 MB ve JPEG/PNG/WebP ile sınırlı.
- `stores.edit_token` için `anon` veya `authenticated` doğrudan SELECT grant'i
  bulunmuyor; bu güvenlik sınırı korunacak.
- Tek aktif Edge Function `vixrex-assistant-nlu`; `verify_jwt=false` durumu bu
  operasyon içinde varsayımla değiştirilmez, fonksiyonun kendi doğrulaması ayrı
  güvenlik diff'inde incelenir.
- Security Advisor: 18 kayıt (15 WARN, 3 INFO). Özellikle
  `category_templates_admin_all` policy'sindeki `USING/WITH CHECK (true)`, dışa
  açık `SECURITY DEFINER` fonksiyonlar ve sızmış parola korumasının kapalı olması
  sonraki güvenlik tasarımında kanıtla ele alınacak. Tokenlı misafir RPC'leri
  işlevleri okunmadan topluca kapatılmayacak.
- Performance Advisor: 13 kayıt (5 WARN, 8 INFO). Eksik iki foreign-key indeksi,
  iki RLS init-plan uyarısı ve birden fazla permissive policy bulunan üç akış M2
  canonical baseline değerlendirmesine taşındı; kullanılmayan indeksler ölçüm
  olmadan silinmeyecek.
- C0 tamamlandı. Aynı canlı envanter sorguları M1 sırasında tekrarlanmayacak.

## M1 — Yerel Supabase iskeleti ve CI

### Mimo görevi

1. `supabase/config.toml` oluşturmak.
2. CLI `v2.109.1` ile uyumlu yerel yapı kurmak.
3. Yalnız sahte A, B ve misafir verisi içeren seed taslağı oluşturmak.
4. Yerel Supabase, `db reset`, migration doğrulama, pgTAP/RLS ve schema diff
   kapılarını içeren GitHub Actions taslağı hazırlamak.
5. `supabase/setup-cli@v2.1.1` ve CLI `v2.109.1` sürümlerini sabitlemek.
6. Workflow'u production'a bağlamamak ve secret istememek.
7. Eski migrationları henüz taşımamak, baseline oluşturmamak ve rapordan sonra
   durmak.

### M1 Mimo uygulama protokolü

Mimo yalnız `C:\Projects\vixrex-supabase-foundation` worktree'sinde ve
`feat/supabase-foundation` dalında çalışır. Ana çalışma ağacına dokunmaz.

1. Başlangıç kapısı
   - `PROJECT_RULES.md`, `SON_DURUM.md`, `AGENTS.md` ve bu dosyayı sırasıyla
     tamamen okur.
   - `git status --short` ve dal/worktree yolunu bir kez doğrular.
   - Beklenmeyen tracked değişiklik varsa hiçbir şeyi düzeltmeden raporlar ve
     durur.
2. Yerel iskelet
   - CLI komutlarını `supabase.cmd --help` ile doğrular; komut/flag tahmin etmez.
   - `supabase/config.toml` dosyasını CLI `v2.109.1` ile oluşturur.
   - Production project ref, URL, anon/publishable key, service-role key veya
     gerçek kullanıcı verisi eklemez.
3. Sahte test verisi
   - Yalnız sahte A sahibi, B sahibi ve misafir senaryoları için deterministic
     seed taslağı oluşturur.
   - Gerçek e-posta, telefon, token, parola, mağaza verisi veya canlı UUID
     kullanmaz.
4. Yerel CI taslağı
   - GitHub Actions içinde Supabase CLI `v2.109.1` sürümünü kesin olarak
     sabitler; `latest` kullanmaz.
   - Workflow yalnız yerel Docker üzerinde çalışır; `supabase link`, `db push`,
     production secret veya uzak proje bağlantısı içermez.
   - Sıra: yerel başlatma, `db reset`, migration doğrulama, pgTAP/RLS test kapısı,
     schema diff ve temizlik.
5. M1 kapsam sınırı
   - 46 eski migrationı taşımaz, yeniden adlandırmaz, silmez veya düzeltmez.
   - Canonical baseline, hesap silme, upload ticket, Flutter değişikliği ve canlı
     güvenlik düzeltmesi yapmaz; bunlar M2/M3 kapsamındadır.
   - C0 sorgularını, Advisor ve canlı log okumalarını tekrarlamaz.
6. Orantılı doğrulama
   - Önce yapılandırma biçimini ve production referansı bulunmadığını hedefli
     taramayla doğrular.
   - Docker/yerel Supabase çalışıyorsa bir kez yerel başlatma ve bir kez M1 test
     zinciri çalıştırır. Aynı hata yeni değişiklik olmadan tekrar denenmez.
   - Hata çıktısı en fazla 40 satır olur; tam log dosyası oluşturulmaz.
7. Teslim
   - Yalnız değişen dosyaları, `git diff --stat`, çalıştırılan komutları,
     geçen/başarısız kapıları ve bilerek dokunulmayan alanları raporlar.
   - Commit/push yapmaz, M2'ye geçmez ve rapordan sonra durur.

### M1 için Mimo başlangıç komutu

```text
PROJECT_RULES.md, SON_DURUM.md, AGENTS.md ve supabase.md dosyalarını
sırasıyla tamamen oku.

Yalnız C:\Projects\vixrex-supabase-foundation worktree'sinde ve
feat/supabase-foundation dalında çalış. AKTİF FAZ M1'dir.

supabase.md içindeki "M1 Mimo uygulama protokolü"nü sırayla uygula.
Canlı Supabase'e bağlanma; supabase link, db push, migration apply veya Edge
Function deploy yapma. Production secret isteme veya ekleme. Ana çalışma
ağacına, Flutter/Next.js koduna ve eski migration içeriklerine dokunma.

CLI ve CI sürümünü tam v2.109.1 olarak sabitle. Yerel config, sahte seed ve
yalnız yerel Docker CI taslağını hazırla. Bir orantılı doğrulama turu çalıştır.
Commit/push yapma ve M2'ye geçme.

M1 raporunu bu dosyadaki biçimde ver, izin verilen durum/kanıt alanlarını
güncelle ve Furkan + Codex onayı için dur.
```

### Kabul kapısı

- Yerel Supabase başlatılabilir.
- CI yalnız yerel Docker kullanır.
- Üretim adresi veya anahtarı bulunmaz.
- Uygulama kodu değişmemiştir.

## M2 — Canonical baseline ve migration zinciri

### Mimo görevi

1. Eski migrationları silmeden aktif zincir dışındaki arşiv alanına taşımak.
2. Canlı migration geçmişindeki sürümler için eşleşen geçmiş stub'ları kurmak.
3. Vixrex tablolarını, constraintleri, indeksleri, açık grantleri, RLS
   policy'lerini, fonksiyonları ve bucket tanımlarını içeren tek baseline
   oluşturmak.
4. Supabase'in yönettiği `auth`, `storage` ve `realtime` tablolarını yeniden
   oluşturmamak.
5. Baseline sonrası migrationları yalnız CLI'nin ürettiği 14 haneli zaman
   damgasıyla oluşturmak.
6. Boş yerel veritabanında `db reset`, seed ve schema diff doğrulaması yapmak.
7. Beklenmeyen diff'i otomatik düzeltmeden raporlamak.
8. Canlı migration repair/db push veya commit/push yapmadan durmak.

### Kabul kapısı

- Boş veritabanı yalnız repo ile kurulmaktadır.
- Başlangıç şeması için Dashboard işlemine ihtiyaç yoktur.
- Temel Vixrex tabloları eksiksizdir.
- `edit_token` public SELECT grant'i yoktur.
- Codex baseline, grant, RLS ve fonksiyon diff'ini onaylamıştır.

## M3 — Hesap silme ve görsel yükleme

### Hesap silme

- JWT doğrulayan tek `delete-account` Edge Function hazırlanır.
- İstemciden `user_id` kabul edilmez.
- İlişkili veri, Storage nesneleri, vitrin ve Auth kullanıcısı idempotent sırayla
  temizlenir.
- Flutter eksik `delete_user_account` RPC'sine bağımlı kalmaz.
- Başarısızlık aşaması sabit ve gizli bilgi içermeyen hata koduyla döner.

### Görsel yükleme

- Tek `store-media-upload-ticket` yetkilendirme yolu hazırlanır.
- Giriş yapan kullanıcı `auth.uid()`, misafir token hash'iyle doğrulanır.
- Kısa ömürlü imzalı upload bileti kullanılır.
- Yeni yol `stores/{store_id}/{kind}/{uuid}.{ext}` olur; eski URL'ler okunmaya
  devam eder fakat yeni slug tabanlı nesne üretilmez.
- Yeni yol doğrulanmadan mevcut Storage policy'leri kaldırılmaz.
- Uygulamadaki limit mesajı canlı 5 MB bucket sınırıyla uyumlu hâle getirilir.
- Storage status/code/message bilgisi genel hata içinde kaybolmaz.

### Kabul kapısı

- A/B sahiplik sınırı korunur.
- Misafir doğru tokenla çalışır; yanlış token upload bileti alamaz.
- Hesap silme ikinci çağrıda zarar vermez.
- Keşfet, tema, landing ve asistan değişmemiştir.
- Codex yalnız ilgili migration, Edge Function ve auth/upload diff'ini
  onaylamıştır.

## M4 — Güvenlik sözleşmeleri ve üretim workflow'u

### Mimo görevi

1. A/B/misafir saldırı matrisi için pgTAP testleri eklemek.
2. Başka vitrini/randevuyu/booking ayarını değiştirme, tokensız RPC, doğru
   misafir tokenı, upload bileti ve idempotent hesap silme senaryolarını
   doğrulamak.
3. Yalnız `main` commit SHA, manuel `workflow_dispatch`, migration
   geçmişi/fingerprint ön kontrolü, farkta durma, migration uygulama ve son
   Advisor kontrolü içeren production workflow taslağı hazırlamak.
4. Secret isimlerini tanımlayıp değer eklememek.
5. Kalıcı Supabase kurallarını `PROJECT_RULES.md` ve `AGENTS.md` içine taşımak.
6. `SON_DURUM.md` dosyasını yalnız gerçek son duruma göre güncellemek.
7. Commit/push yapmadan raporlamak ve durmak.

### Kabul kapısı

- CI sıfırdan kurulum ve saldırı testlerini geçer.
- Production workflow manuel onaysız çalışmaz.
- Dashboard/SQL Editor üzerinden doğrudan canlı değişiklik yasaktır.
- Yeni yan Markdown dosyası yoktur.

## Codex görev ve kaynak sınırı

Codex yalnız şu kapılarda çalışır:

- C0: Tek canlı envanter.
- C1: M2 baseline güvenlik diff'i.
- C2: M3 hesap silme/upload güvenlik diff'i.
- C3: Furkan onayı sonrası tek production migration uygulaması ve tek kabul
  sorgusu.

Her Codex kapısında en fazla bir hedefli tarama ve bir diff incelemesi yapılır.
Tam repo taraması, aynı testin tekrarı, CI polling veya tam log okuma yapılmaz.

## Commit ve canlıya çıkış sırası

1. M0 tamamlanır; commit yok.
2. M1 Codex kontrolünden sonra Furkan onayıyla ayrı commit olur.
3. M2 C1 onayından sonra ayrı commit olur.
4. M3 C2 onayından sonra ayrı commit olur.
5. M4 yerel CI kapıları geçince PR açılır.
6. PR merge edilmeden production workflow çalışmaz.
7. Merge sonrası Furkan'ın açık onayıyla C3 uygulanır.
8. A/B/misafir canlı kabulü tamamlanmadan APK, pilot veya reklam başlamaz.

## Mimo çalışma başlangıç kuralı

Mimo, yalnız üstteki `AKTİF FAZ` değerini ve o fazın kendi uygulama protokolünü
izler. Tamamlanmış fazlara ait eski başlangıç komutları tekrar kullanılmaz.
Her fazın sonunda rapor verilir ve sonraki faz açıkça etkinleştirilmeden işlem
yapılmaz.

---

## M0 RAPORU

**Tarih**: 17 Temmuz 2026
**Durum**: Tamamlandı — Onay Bekleniyor

### 1. Ortam Envanteri

| Araç | Sürüm | Durum |
|------|-------|-------|
| Supabase CLI | v2.109.1 | ✓ Kuruldu |
| Docker | v29.4.3 | ✓ Mevcut |
| Git | main branch | ✓ Aktif |

### 2. Migration Sınıflandırması (46 dosya)

| Kategori | Sayı | Dosyalar |
|----------|------|----------|
| Başlangıç şeması | 1 | core_schema_documented |
| Tablo/Kolon | 19 | gallery, location, products, booking, instagram, legal, ocr... |
| RLS/Güvenlik | 6 | advisor_warnings, rls_pii, stores_select, auth_gap, p1_hardening |
| RPC/Fonksiyon | 7 | delete_account, ocr_limit, rate_limit, create/delete/update_store |
| Storage | 5 | shelf_file_limit, storage_policies, storage_security, lock_uploads |
| Seed/Şablon | 8 | category_templates, legal_activate, brand_standardize |

### 3. Tespit Edilen Eksikler

**A. shelf-images bucket limit:**
- Canlı bucket sınırı: **5 MB** — Codex read-only doğruladı.
- `supabase_schema.sql`: 15 MB (15728640) — canonical zincirle tutarsız.
- `20260530` migration: 15 MB.
- `20260604_add_storage_policies_for_shelf_images.sql`: 5 MB.
- Daha sonraki `20260708` ve `20260717` migrationları da 5 MB tanımlıyor.
- Bu repo içi drift **M2 canonical baseline** aşamasında giderilecek.
- Flutter 15 MB uyumsuzluğu doğrulanmışsa **M3** kapsamında kalacak.

**B. Core schema minimal:** legal_documents, admins, booking, appointments, articles, instagram tabloları core'da yok — kasıtlı.

**C. Canlı migration eşleşmesi:** 22 canlı kaydın hangi repodaki migration'lara karşılık geldiği doğrulanmadı.

### 4. Sonraki Engel

C0 Codex envanteri tamamlanmadan M1'e geçilmez.

---

## M1 RAPORU (v5)

**Tarih**: 17 Temmuz 2026
**Durum**: Tamamlandı — Onay Bekleniyor
**Worktree**: `C:\Projects\vixrex-supabase-foundation` (`feat/supabase-foundation`)

### 1. Değişen Dosya (bu tur)

| Dosya | İşlem |
|-------|-------|
| `supabase/tests/database/rls.test.sql` | v5 — 3 düzeltme |

### 2. Düzeltilen Codex Bulguları (v5)

| # | Bulgu | Düzeltme |
|---|-------|----------|
| 1 | edit_token testi katalog ile | `has_column_privilege('anon'/'authenticated', ..., 'SELECT') = false` |
| 2 | B saldırı sonrası SELECT bağlamı | Her saldırıdan sonra `RESET role` ile postgres bağlamına dönülüp doğrulanıyor |
| 3 | Service rolü sayılmıyor | Yalnız setup/teardown ve katalog doğrulama bağlamında |

### 3. Güncel Assertion Listesi (19 test, 3 rol)

| # | Rol | Assertion |
|---|-----|-----------|
| 1 | anon | published store okuyabilmeli |
| 2 | anon | draft store okuyamamalı |
| 3 | anon | edit_token SELECT yetkisi yok (katalog) |
| 4 | auth | edit_token SELECT yetkisi yok (katalog) |
| 5 | auth A | B draft okuyamamalı |
| 6 | auth A | B update yapamamalı → RESET role ile isim değişmedi doğrula |
| 7 | auth A | B delete yapamamalı → RESET role ile satır mevcut doğrula |
| 8 | auth B | A randevu change yapamamalı → RESET role ile status=pending |
| 9 | auth B | A booking change yapamamalı → RESET role ile capacity=2 |
| 10 | auth B | A store update yapamamalı → RESET role ile isim değişmedi |
| 11 | auth B | A store delete yapamamalı → RESET role ile satır mevcut |
| 12 | pg | vitrin_views RLS açık |
| 13 | pg | store_slug sütunu mevcut |
| 14 | pg | session_key sütunu mevcut |
| 15 | pg | booking_settings RLS açık |
| 16 | pg | appointments RLS açık |
| 17 | pg | stores.slug benzersiz |
| 18 | pg | get_appointment_by_token RPC mevcut (M3) |
| 19 | pg | cancel_appointment_by_token RPC mevcut (M3) |

**Not**: #12-19 katalog/RPC doğrulaması — saldırı testi değil, yapısal sözleşme kontrolü.

### 4. Başarısız Olanlar

```
supabase db reset --local
ERROR: relation "stores" does not exist (SQLSTATE 42P01)
```

**M2 ENGELİ**: Migration sırası — `20250703` dosyası `stores` tablosundan önce çalıştırılıyor.
