# KİLİTLİ PLAN — İlerleme Panosu

Ana plan: `docs/kilitli-plan-blog-akilli-motor-dijital-carsi.md`
Final entegrasyon kararı: `docs/kilitli-plan-final-entegrasyon-test-karari.md`
Güvenli geri dönüş: `checkpoint/main-post-413-20260904`
Aktif PR: `#414`
Aktif araştırma branch'i: `research/blog-kutuphanesi-katman-2`

## Katman 1 — Vixrex Blog Omurgası

- [x] RESEARCH — mevcut blog, DB, RLS, sitemap, UX ve ölçek araştırıldı
- [x] UX-FIT — **UYGUN AMA ŞARTLI** sonucu kullanıcıya sunuldu ve şartlar onaylandı
- [x] LOOK — gerçek kod, canlı `store_articles` şeması/policy ve Vixrex UX yüzeyleri doğrulandı
- [x] LOCK — `store_articles`, public vitrin, Keşfet, Kirala, Flutter ve 46 alan Asistan motoru kapsam dışı kilitlendi
- [x] 1.1 BUILD — ayrı `vixrex_blog_articles` veri omurgası, RLS, index ve iki mevcut taslak migration'a alındı
- [x] 1.2 BUILD — public veri erişimi merkezi Supabase kaynağına geçirildi
- [x] 1.3 BUILD — `/blog`, `/blog/[slug]` ve sitemap merkezi kaynağa bağlandı; taslak 404 davranışı korundu
- [x] 1.4 BUILD — blog ana sayfası Vixrex `lp-*` tasarım diliyle 1200px büyüyebilir katalog düzenine çıkarıldı; detay okuma genişliği korunuyor
- [x] Güvenlik sözleşme testi — public yalnız `published`, iki mevcut yazı `draft`, `store_articles` dokunulmazlığı kaynak testine bağlandı

### 1.5 Teknik VERIFY

- [x] Secret sızıntı taraması geçti
- [x] Supabase auth security config kontrolü geçti
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
- [ ] LOCK — araştırmadaki 9 BUILD şartı kullanıcı onayından sonra kilitlenecek
- [ ] BUILD
- [ ] Teknik VERIFY

Araştırma: `docs/research/katman-2-merkezi-blog-kutuphanesi-arastirma.md`

## Sonraki katmanlar

- [ ] Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu
- [ ] Katman 4 — Vixrex Asistan Blog Komutları
- [ ] Katman 5 — Dijital Çarşı Bağlantı Omurgası

## Main kuralı

- [ ] MERGE — yalnız kullanıcı açık onay verirse

> Kural: Tik yalnız gerçekten tamamlanan adıma konur. Katman bazında teknik güvenlik doğrulaması atlanmaz; gerçek kullanıcı ekran kabul testi final entegrasyon kapısında yapılır.
