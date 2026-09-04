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
- [ ] 1.5 VERIFY — GitHub CI migration zinciri / güvenlik / tip / test / build sonucu
- [ ] 1.5 VERIFY — merkezi migration'ın kontrollü DB doğrulaması
- [ ] 1.5 VERIFY — gerçek yayın satırıyla Preview mobil + masaüstü ekran doğrulaması
- [ ] 1.5 VERIFY — `/v/[slug]`, Keşfet, Kirala/sahiplik regresyon kontrolü
- [ ] DECIDE — geçen/kalan maddeler kullanıcıya sunulacak
- [ ] MERGE — yalnız kullanıcı açık onay verirse

## Sonraki katmanlar

- [ ] Katman 2 — Merkezi Blog Kütüphanesi
- [ ] Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu
- [ ] Katman 4 — Vixrex Asistan Blog Komutları
- [ ] Katman 5 — Dijital Çarşı Bağlantı Omurgası

> Kural: Tik yalnız gerçekten tamamlanan adıma konur. VERIFY geçmeden Katman 1 tamamlandı sayılmaz; Katman 2 başlamaz.
