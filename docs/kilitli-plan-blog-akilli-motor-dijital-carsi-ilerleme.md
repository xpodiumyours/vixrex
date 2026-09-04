# KİLİTLİ PLAN — İlerleme Panosu

Ana plan: `docs/kilitli-plan-blog-akilli-motor-dijital-carsi.md`
Final entegrasyon kararı: `docs/kilitli-plan-final-entegrasyon-test-karari.md`
Güvenli geri dönüş: `checkpoint/main-post-413-20260904`
Aktif PR Katman 1: `#414`
Aktif Katman 2 PR: `#415`
Aktif Katman 2 branch'i: `feat/blog-kutuphanesi-katman-2`
Aktif Katman 3 PR: `#416`
Aktif Katman 3 branch'i: `feat/vitrine-yazi-cekme-katman-3`

## Katman 1 — Vixrex Blog Omurgası

- [x] RESEARCH — mevcut blog, DB, RLS, sitemap, UX ve ölçek araştırıldı
- [x] UX-FIT — **UYGUN AMA ŞARTLI** sonucu kullanıcıya sunuldu ve şartlar onaylandı
- [x] LOOK — gerçek `store_articles` şeması/policy ve Vixrex UX yüzeyleri doğrulandı
- [x] LOCK — `store_articles`, public vitrin, Keşfet, Kirala, Flutter ve 46 alan Asistan motoru kapsam dışı kilitlendi
- [x] 1.1 BUILD — ayrı `vixrex_blog_articles` veri omurgası, RLS, index ve iki mevcut taslak migration'a alındı
- [x] 1.2 BUILD — public veri erişimi merkezi Supabase kaynağına geçirildi
- [x] 1.3 BUILD — `/blog`, `/blog/[slug]` ve sitemap merkezi kaynağa bağlandı; taslak 404 davranışı korundu
- [x] 1.4 BUILD — blog ana sayfası Vixrex `lp-*` tasarım diliyle 1200px büyüyebilir katalog düzenine çıkarıldı; detay okuma genişliği korunuyor
- [x] Güvenlik sözleşme testi — public yalnız `published`, iki mevcut yazı `draft`, `store_articles` dokunulmazlığı kaynak testine bağlandı

### 1.5 Teknik VERIFY

- [x] Secret sızıntı taraması geçti
- [x] CI auth-config işi çalıştı; bu iş secret yoksa kontrolü atlayabildiği için canlı Auth güvenliği kanıtı olarak sayılmıyor
- [x] Şema üretim/sapma kontrolü geçti
- [x] Supabase migration zinciri sıfırdan kuruldu ve GRANT güvenlik bekçisi geçti
- [x] TypeScript `tsc --noEmit` geçti
- [x] Canlı DB migration kontrollü uygulandı
- [x] Canlı DB'de 2 kayıt = 2 taslak / 0 yayın doğrulandı
- [x] Canlı DB'de RLS, unique slug ve published index doğrulandı
- [x] `anon` rolüyle taslak görünürlüğü = 0 satır doğrulandı
- [x] Katman 1 kapı testleri — 7 dosya / 32 test geçti
- [x] Production build başarıyla tamamlandı
- [x] Katman 1 teknik VERIFY tamamlandı

### Kullanıcı kararı — ekran testinin zamanı

- [x] Katman bazında teknik doğrulama devam edecek.
- [x] Her katmanda ayrı ayrı ekran test döngüsüne girilmeyecek.
- [x] Gerçek uçtan uca ekran testi Katman 1–5 tamamlandıktan sonra yapılacak.
- [ ] FINAL E2E — deneme/kiralık vitrin kirala → sahipliği aç → Vixrex Asistan ile merkezi blog yazısını vitrinin bloguna taslak çek → ekranda doğrula → düzenle/yayınla → public vitrinde doğrula → Dijital Çarşı ilişkisini doğrula.

### Baseline notları — Katman 1 kaynaklı değil

- Next.js genel lint, main'de önceden bulunan `giris/page.tsx:23` hatasında duruyor.
- Tam Vitest turunda PR #413 sonrası main'de zaten bulunan iki kontrat beklentisi kırmızı: eski 36px maskot beklentisi ve owner-draft `SERVICE_ROLE` metin beklentisi.
- Flutter format kontrolü mevcut baseline biçim farklarında kırmızı; Katman 1 Flutter dosyası değiştirmiyor.

## Katman 2 — Merkezi Blog Kütüphanesi

- [x] RESEARCH — merkezi tablo, store blog modeli, 19 sektör, 81 il/ilçe kaynağı, görsel hattı ve güncel SEO/tarama kuralları doğrulandı; sonuç **UYGUN AMA ŞARTLI**
- [x] UX-FIT — merkezi kütüphane public `lp-*` Vixrex dilinde kalacak; owner/Keşfet/global shell değişmeyecek
- [x] SECURITY/RISK — taslak RLS, tek kategori kaynağı, merkezi admin görsel yetkisi, filtre URL patlaması ve relation bütünlüğü riskleri çıkarıldı
- [x] LOOK — canlı şema, RLS, `/api/articles`, owner blog editörü, public blog, kategori/konum kaynakları ve görsel upload çekirdeği gerçek kod/veriyle teyit edildi
- [x] LOCK — 9 BUILD sınırı, 7 konu ailesi, kullanım amacı sözlüğü, konum ve etiket sınırları kullanıcı devam onayıyla kilitlendi
- [x] 2.1 BUILD — `shared/blog_taxonomy.json` ile 7 konu + 7 amaç tek kaynağa alındı; sektörler mevcut 19 kategori kaynağını kullanıyor
- [x] 2.2 BUILD — merkezi tabloya konu/amaç/sektör/konum/etiket/provenance metadata migration'ı ve FK ilgili-yazı relation tablosu eklendi
- [x] 2.3 BUILD — public veri katmanı konu/sektör/il/etiket filtreleri ve ilgili yazı sorgusuyla genişletildi
- [x] 2.4 BUILD — `/blog/konu/[topic]`, `/blog/sektor/[sector]`, kütüphane kartları, kapak görselleri ve kontrollü sitemap bağlantıları eklendi
- [x] 2.5 BUILD — merkezi kapak yükleme owner-session'dan ayrıldı; platform admin + mevcut 1600px/82 sıkıştırma çekirdeği kullanılıyor

### Katman 2 Teknik VERIFY

- [x] Secret sızıntı taraması geçti
- [x] CI auth-config işi çalıştı; canlı Security Advisor ayrı kontrol edildi ve `Leaked Password Protection` kapalı olduğu doğrulandı
- [x] Şema üretim/sapma kontrolü geçti
- [x] Katman 2 değişen dosyalarında hedefli lint geçti
- [x] TypeScript `tsc --noEmit` geçti
- [x] Katman 1 + Katman 2 blog sözleşme testleri — 3 dosya / 22 test geçti
- [x] Production build geçti
- [x] Supabase migration zinciri sıfırdan + GRANT güvenlik bekçisi geçti
- [x] Katman 2 migration canlı DB'ye kontrollü uygulandı
- [x] Canlı DB metadata ve relation RLS doğrulandı; mevcut 2 yazı hâlâ taslak, 0 yayın
- [x] `anon` rolüyle merkezi taslak yazı görünürlüğü = 0; relation görünürlüğü = 0
- [x] Migration sonrası production build tekrar çalıştırıldı; yeni metadata kolonları canlı DB'de okunarak build temiz geçti
- [x] Katman 2 Teknik VERIFY tamamlandı

Not: Genel Next.js lint yalnız main'de önceden bulunan `giris/page.tsx:23` hatasında kırmızı; Katman 2 değişen dosyalarının hedefli lint'i yeşil. Flutter genel biçim kontrolü de mevcut baseline farklarında kırmızı; Katman 2 Flutter dosyası değiştirmiyor.

Araştırma: `docs/research/katman-2-merkezi-blog-kutuphanesi-arastirma.md`
LOCK: `docs/research/katman-2-merkezi-blog-kutuphanesi-lock.md`

## Katman 2.5 — Katman 3 Öncesi Profesyonel Sertleştirme

Plan: `docs/research/katman-2-5-profesyonel-sertlestirme.md`

- [x] 2.5.1 Migration history eşitliği — owner catalog ve blog sertleştirme migration sürümleri canlı Supabase history ile eşitlendi; son kod HEAD'i üzerinde migration zinciri sıfırdan başarıyla kuruldu
- [x] 2.5.2 Blog RLS performans sertleştirmesi — admin policy'lerinde `(select auth.uid())` kullanımı canlıya uygulandı; canlı Performance Advisor'da iki Vixrex blog tablosu için `auth_rls_initplan` uyarısı kalmadığı doğrulandı
- [x] 2.5.3 Gerçek allow/deny + admin API davranış testleri — yerel gerçek Supabase + production Next.js üzerinde RLS ve admin API davranış testi başarıyla geçti
- [x] 2.5.4 Auth security raporlaması düzeltildi — CI job ile canlı Advisor sonucu ayrı tutuluyor; canlıda `Leaked Password Protection` kapalı olduğu açıkça kaydedildi
- [x] 2.5.5 Taslak içerik doğruluğu + provenance — iki taslak birincil Google kaynaklarıyla güncellendi; `source_urls` dolduruldu; canlı DB'de ikisinin de hâlâ `draft` olduğu doğrulandı
- [x] Katman 2.5 kapısı — migration zinciri + GRANT + production build + gerçek RLS/admin API doğrulamasının son turu başarıyla geçti
- [x] Geçici Katman 2.5 doğrulama workflow'u kanıt alındıktan sonra branch'ten kaldırıldı

## Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu

Araştırma: `docs/research/katman-3-vitrine-yazi-cekme-arastirma.md`
LOCK: `docs/research/katman-3-vitrine-yazi-cekme-lock.md`

- [x] RESEARCH — merkezi yazı modeli, canlı `store_articles`, CRUD, owner-session, Flutter/Next.js blog davranışı, duplicate/canonical riski ve ölçek araştırıldı; sonuç **UYGUN AMA ŞARTLI**
- [x] UX-FIT — mevcut Blog Yönetimi + mevcut editör yeniden kullanılacak; paralel blog yönetim ekranı kurulmayacak
- [x] SECURITY/RISK — yalnız published kaynak, zorunlu draft, DB owner-session tekrar doğrulaması, kaynak ilişkisi ve idempotency şartları çıkarıldı
- [x] LOOK — canlı `store_articles` kolon/constraint/policy/index/trigger yapısı ve gerçek Next.js/Flutter CRUD yüzeyleri doğrulandı
- [x] LOCK — 12 ürün/güvenlik şartı kullanıcı tarafından açıkça onaylandı; source provenance, iki import modu, idempotency ve mevcut editörü yeniden kullanma sınırları kilitlendi
- [x] 3.1 BUILD — `store_articles` kaynak provenance alanları, kaynak-slug partial unique idempotency ve DB owner doğrulamalı published→draft import RPC'si kodlandı
- [x] 3.2 BUILD — Next.js owner-session cookie + DB session tekrar doğrulamalı dar import API adapter'ı kodlandı
- [x] 3.3 BUILD — bounded merkezi kütüphane seçimi mevcut Next.js Blog Yönetimi yüzeyine bağlandı; import sonrası mevcut editör açılıyor
- [x] 3.4 BUILD — Flutter aynı merkezi published kütüphane ve aynı import RPC sözleşmesine bağlandı; ayrı backend kurulmadı
- [x] BUILD tamamlandı — kilitli Katman 3 kapsamındaki kod yüzeyleri tamamlandı; kaynak sözleşme testi ve gerçek DB davranış testi eklendi
- [ ] Teknik VERIFY

**KURAL:** BUILD tamamlandı işareti doğrulandı anlamına gelmez. Katman 3 migration canlıya uygulanmadı; Teknik VERIFY tüm kapıları geçmeden canlıya uygulanmayacak ve Katman 4 başlamayacak.

## Sonraki katmanlar

- [ ] Katman 4 — Vixrex Asistan Blog Komutları
- [ ] Katman 5 — Dijital Çarşı Bağlantı Omurgası

## Main kuralı

- [ ] MERGE — yalnız kullanıcı açık onay verirse

> Kural: Tik yalnız gerçekten tamamlanan adıma konur. Katman bazında teknik güvenlik doğrulaması atlanmaz; gerçek kullanıcı ekran kabul testi final entegrasyon kapısında yapılır.
