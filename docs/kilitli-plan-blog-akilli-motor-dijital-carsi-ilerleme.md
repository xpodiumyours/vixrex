# KİLİTLİ PLAN — İlerleme Panosu

Ana plan: `docs/kilitli-plan-blog-akilli-motor-dijital-carsi.md`
Güvenli geri dönüş: `checkpoint/main-post-413-20260904`
Aktif PR: `#414`

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

### 1.5 VERIFY

- [x] Secret sızıntı taraması geçti
- [x] Supabase auth security config kontrolü geçti
- [x] Şema üretim/sapma kontrolü geçti
- [x] Supabase migration zinciri sıfırdan kuruldu ve GRANT güvenlik bekçisi geçti
- [x] TypeScript `tsc --noEmit` geçti
- [x] Canlı DB migration kontrollü uygulandı
- [x] Canlı DB'de 2 kayıt = 2 taslak / 0 yayın doğrulandı
- [x] Canlı DB'de RLS, unique slug ve published index doğrulandı
- [x] `anon` rolüyle taslak görünürlüğü = 0 satır doğrulandı
- [x] İlk tam test turunda Katman 1 kaynaklı sitemap mock uyumsuzluğu bulundu ve fail-closed düzeltildi
- [x] Katman 1 kapı testleri son turu — 7 dosya / 32 test geçti
- [x] Production build — Next.js 16.2.11 production build başarıyla tamamlandı
- [ ] Gerçek yayın satırıyla Preview mobil + masaüstü ekran doğrulaması
- [ ] `/v/[slug]`, Keşfet, Kirala/sahiplik regresyon kontrolü

### Baseline notları — Katman 1 kaynaklı değil

- Next.js genel lint, main'de önceden bulunan `giris/page.tsx:23` hatasında duruyor.
- Tam Vitest turunda PR #413 sonrası main'de zaten bulunan iki kontrat beklentisi kırmızı: eski 36px maskot beklentisi ve owner-draft `SERVICE_ROLE` metin beklentisi. Katman 1 bu dosyalara dokunmuyor.
- Tam test envanteri: 143 test dosyasından 141 geçti; 1022 testten 1019 geçti, 2 baseline hata ve 1 todo kaldı.
- Flutter format kontrolü mevcut baseline biçim farklarında kırmızı; Katman 1 Flutter dosyası değiştirmiyor.

- [ ] DECIDE — geçen/kalan maddeler kullanıcıya sunulacak
- [ ] MERGE — yalnız kullanıcı açık onay verirse

## Sonraki katmanlar

- [ ] Katman 2 — Merkezi Blog Kütüphanesi
- [ ] Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu
- [ ] Katman 4 — Vixrex Asistan Blog Komutları
- [ ] Katman 5 — Dijital Çarşı Bağlantı Omurgası

> Kural: Tik yalnız gerçekten tamamlanan adıma konur. VERIFY geçmeden Katman 1 tamamlandı sayılmaz; Katman 2 başlamaz.
