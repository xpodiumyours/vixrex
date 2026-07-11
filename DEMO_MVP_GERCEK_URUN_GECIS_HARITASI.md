# VixRex Demo/MVP'den Gerçek Ürüne Geçiş Haritası
> Kapsamlı İlerleme Tablosu - Bildirim, Çerez, Analytics ve Production Hazırlığı
> Başlangıç: 2026-07-10

---

## Mevcut Durum Analizi

### ✅ Mevcut Bileşenler (Tamamlandı)
- [x] Flutter uygulaması (Vitrin oluşturma, düzenleme, canlı önizleme)
- [x] Next.js public web (Public vitrin, SEO, sitemap, robots)
- [x] Supabase (Database, Auth, Storage, RLS, RPC)
- [x] Vercel yapılandırması (Flutter + Next.js)
- [x] OneSignal: initialize + kullanıcı login/logout + tıklama deep link (`/bookings/:slug`)
- [x] Sentry entegrasyonu (Error tracking)
- [x] Legal consent section (Privacy, Terms, Publication consent) — UI
- [x] OCR sistemi (Google ML Kit, Fuzzy matching, Confidence)
- [x] Randevu sistemi (Booking, Appointments, Reschedule)
- [x] WhatsApp entegrasyonu
- [x] QR kod oluşturma
- [x] Keşfet ekranı
- [x] Galeri yönetimi
- [x] Ürün ve hizmet yönetimi
- [x] Bildirim ayarları UI (Profil → Uygulama Ayarları)
- [x] Notification preferences (randevu push aç/kapa, SharedPreferences)
- [x] In-app notifications + bildirim geçmişi ekranı
- [x] FAQ / Help center (Kullanım & Destek SSS)
- [x] Social sharing (vitrin link / QR paylaşım)
- [x] Content moderation UI (Blog moderasyon, admin)
- [x] User data deletion automation (RPC `delete_user_account` cascade)
- [x] Spam protection (kısmi: Turnstile / article spam)
- [x] Bildirim template'leri (onay / red / hatırlatma / talep)
- [x] Bildirim gönderme mantığı (Edge Function `send-booking-push` → OneSignal)
- [x] Çerez yönetimi + consent banner + tercihler (public_web)
- [x] GA4 kapısı (`NEXT_PUBLIC_GA_ID`, analitik çerezi açıkken)
- [x] Hesap silme UI (Ayarlar → SİL onayı → `deleteAccount`)
- [x] Password reset (Auth ekranı → Supabase `resetPasswordForEmail`)
- [x] Keşfet: API hatasında mock vitrin yok (empty + retry)
- [x] User data export (Ayarlar → JSON paylaş; edit_token ayıklı)
- [x] Mobil↔Web public parity Faz 1 (randevu path, logo/Google, Web Sitesi CTA)
- [x] Kategori → özellik paketi (randevu ayarı/UI; Ayarlar satırı)
- [x] Flutter editör `noindex` + Google Haritalar rehber kartı kaldırıldı
- [x] Public SEO meta sıkılaştırma (OG/Twitter absolute, robots index)
- [ ] **Ops — senin tarafta:** Google Search Console (`vixrex.app` + sitemap)

### Mobil ↔ Web Public Vitrin Eşitliği

**Faz 1 (tamamlandı — soft launch zorunlu)**
- [x] Randevu URL: Flutter + Next.js → `/v/{slug}/randevu` ve `/v/{slug}/randevu/{token}`
- [x] Eski `#randevu_token=` hash → path redirect (geriye uyum)
- [x] Public fetch: `logo_url` + `google_business_link`
- [x] “Web Sitesi” butonu → `store.website` (vitrin self-link değil)

**Faz 2 (backlog — soft launch sonrası)**
- [ ] Flutter public yazılar: `/v/:slug/yazilar` (+ detay) — şu an yalnız Next.js
- [ ] Next.js vCard gerçek `.vcf` indirme
- [ ] WhatsApp prefill metin hizası (Flutter kategori şablonu ↔ web generic)
- [ ] Flutter ürün detayda IG `sourcePermalink`
- [ ] Tema / view analytics polish (isteğe bağlı)

**Bilinçli farklı bırakılanlar:** SEO SSR / çerez / GA4 = web-only; Editör / Keşfet / Ayarlar / push inbox = Flutter-only.

### ❌ Eksik Bileşenler (Production için Gerekli)
- [ ] Notification analytics yok
- [ ] Push notification scheduling yok
- [ ] Email notifications yok
- [ ] SMS notifications yok
- [ ] 2FA yok
- [ ] Rate limiting yok (genel API)
- [ ] Admin panel yok (tam; blog moderasyon hariç)
- [ ] Dashboard yok
- [ ] User analytics yok
- [ ] Business analytics yok
- [ ] Revenue tracking yok
- [ ] A/B testing yok
- [ ] Feature flags yok
- [ ] Performance monitoring yok
- [ ] Uptime monitoring yok
- [ ] Backup strategy yok
- [ ] Disaster recovery yok
- [ ] Load testing yok
- [ ] Security audit yok
- [ ] Penetration testing yok
- [ ] Compliance audit yok
- [ ] Documentation yok
- [ ] API documentation yok
- [ ] User documentation yok
- [ ] Admin documentation yok
- [ ] Onboarding flow yok
- [ ] Tutorial yok
- [ ] Support system yok (contact form / ticket)
- [ ] Contact form yok
- [ ] Feedback system yok
- [ ] Rating system yok
- [ ] Review system yok
- [ ] Referral system yok
- [ ] Loyalty program yok
- [ ] Premium subscription yok
- [ ] Payment gateway yok
- [ ] Invoice system yok
- [ ] Tax management yok
- [ ] Multi-language yok
- [ ] Multi-currency yok
- [ ] Mobile app (iOS/Android) altyapısı var, production build eksik
- [ ] PWA yok
- [ ] Offline mode yok

### Ertelenen işlemler (sonraya — bilinçli)
**Resmi / hukuki evrak**
- [ ] Data retention policy
- [ ] Privacy policy tamamlanmamış (içerik final / hukuki inceleme)
- [ ] Terms of service tamamlanmamış
- [ ] Cookie policy yok
- [ ] GDPR/KVKK uyumluluğu eksik (hukuki paket)

**Markalı auth e-postası (Supabase ops)**
- [ ] Custom SMTP (Resend/SendGrid vb.) — gönderen: `VixRex` / `noreply@…`
- [ ] Domain SPF/DKIM/DMARC
- [ ] Auth e-posta şablonları (Confirm signup, Reset password) VixRex markası
- [ ] Site URL + Redirect URLs (doğrulama / şifre sıfırlama linkleri)
- [ ] Email verification akışı production’da markalı mail ile tamamlanır
  - Not: Uygulama tarafında kayıt sonrası “doğrulama mailine tıkla” uyarısı var; gönderici hâlâ varsayılan Supabase olabilir.

---

## Hazırlık Durumu: ~%60

| Kategori | Durum | % |
|---|---|---|
| **Core Features** | ✅ Tamamlandı | 92% |
| **Bildirim Sistemi** | ⚠️ Template + Edge gönderim + UI/inbox | 70% |
| **Çerez Yönetimi** | ⚠️ Banner + tercihler + GA4 kapısı (resmi politika ertelendi) | 60% |
| **Analytics** | ⚠️ Sentry + GA4 (çerez izniyle) | 55% |
| **Legal/Compliance** | ⚠️ UI + veri export/silme; resmi içerik ertelendi | 48% |
| **Security** | ⚠️ Hesap silme + şifre sıfırlama + export; 2FA/rate limit eksik | 60% |
| **Monitoring** | ⚠️ Sentry var, eksik | 40% |
| **Documentation** | ❌ Yok | 0% |
| **Support** | ⚠️ SSS var | 30% |
| **Monetization** | ❌ Yok | 0% |
| **Genel** | **⚠️ Soft-launch hazırlık** | **~60%** |

---

## Gerçekçi İlerleme Tablosu (16 Hafta - %45 → %90)

### Hafta 1-2: Bildirim Sistemi Aktifleştirme
**Hedef:** OneSignal tam aktif kullanım

- [ ] Bildirim ayarları UI oluştur
- [ ] Bildirim template'leri oluştur (randevu onayı, iptal, hatırlatma)
- [ ] Bildirim gönderme servisi oluştur
- [ ] Randevu bildirimleri entegre et
- [ ] Bildirim tercihleri UI oluştur
- [ ] Bildirim geçmişi ekranı oluştur
- [ ] Push notification scheduling
- [ ] In-app notifications
- [ ] Test: 50 kullanıcı ile bildirim testi

**Zorluk:** Orta
**Süre:** 2 hafta
**API Maliyeti:** $0 (OneSignal free tier)
**Etki:** Bildirim sistemi %20 → %80

### Hafta 3-4: Çerez Yönetimi ve GDPR/KVKK Uyumu
**Hedef:** Web çerez yönetimi ve uyumluluk

- [ ] Çerez consent banner oluştur (Next.js)
- [ ] Çerez tercihleri yönetimi UI oluştur
- [ ] Çerez kategorileri (gerekli, analitik, pazarlama)
- [ ] Çerez consent storage (Supabase)
- [ ] GDPR/KVKK uyumluluğu kontrolü
- [ ] Privacy policy tamamlama
- [ ] Terms of service tamamlama
- [ ] Cookie policy oluşturma
- [ ] Data retention policy oluşturma
- [x] User data export fonksiyonu
- [x] User data deletion automation
- [ ] Legal documents public web'de yayınla

**Zorluk:** Yüksek
**Süre:** 2 hafta
**API Maliyeti:** $0
**Etki:** Legal/Compliance %40 → %80

### Hafta 5-6: Analytics ve Monitoring
**Hedef:** GA4 entegrasyonu ve gelişmiş monitoring

- [ ] GA4 entegrasyonu (Flutter + Next.js)
- [ ] Event tracking (user actions, vitrin views, bookings)
- [ ] User analytics dashboard
- [ ] Business analytics dashboard
- [ ] Performance monitoring (Lighthouse, Web Vitals)
- [ ] Uptime monitoring (UptimeRobot veya Pingdom)
- [ ] Custom events (OCR kullanımı, premium özellikler)
- [ ] Funnel analysis (vitrin oluşturma → yayınlama)
- [ ] Retention analysis
- [ ] Conversion tracking

**Zorluk:** Orta
**Süre:** 2 hafta
**API Maliyeti:** $0 (GA4 free tier)
**Etki:** Analytics %30 → %80

### Hafta 7-8: Security ve Compliance
**Hedef:** Güvenlik ve uyumluluk iyileştirmesi

- [ ] Email verification (Supabase Auth) — **ertelendi:** custom SMTP + VixRex şablonları ile birlikte
- [x] Password reset (Supabase Auth)
- [ ] 2FA (Two-Factor Authentication)
- [ ] Rate limiting (API endpoints)
- [ ] Spam protection (honeypot, rate limit)
- [ ] Content moderation UI (admin panel)
- [ ] Admin panel oluştur
- [ ] User management (admin panel)
- [ ] Content approval workflow
- [ ] Security audit (üçüncü parti veya internal)
- [ ] Penetration testing (basic)
- [ ] Security headers (CSP, HSTS, X-Frame-Options)

**Zorluk:** Yüksek
**Süre:** 2 hafta
**API Maliyeti:** $0
**Etki:** Security %50 → %80

### Hafta 9-10: Documentation ve Support
**Hedef:** Dokümantasyon ve destek sistemi

- [ ] API documentation (Swagger/OpenAPI)
- [ ] User documentation (help center)
- [ ] Admin documentation
- [ ] Onboarding flow oluştur
- [ ] Tutorial (interactive)
- [ ] Help center (FAQ, guides)
- [ ] Support system (contact form, email)
- [ ] Feedback system (in-app)
- [ ] Rating system (vitrinler için)
- [ ] Review system (müşteriler için)
- [ ] Social sharing (WhatsApp, Facebook, Twitter)
- [ ] Contact form (public web)

**Zorluk:** Orta
**Süre:** 2 hafta
**API Maliyeti:** $0
**Etki:** Documentation %0 → %70, Support %0 → %60

### Hafta 11-12: Monetization ve Premium Features
**Hedef:** Gelir modeli ve premium özellikler

- [ ] Premium subscription model tasarımı
- [ ] Payment gateway entegrasyonu (Iyzico veya Stripe)
- [ ] Subscription management UI
- [ ] Invoice system
- [ ] Tax management (KDV)
- [ ] Premium features (sınırsız OCR, toplu yükleme, Excel içe aktarma)
- [ ] Feature flags (premium vs free)
- [ ] Pricing page
- [ ] Trial period
- [ ] Cancellation flow
- [ ] Revenue tracking (analytics)

**Zorluk:** Yüksek
**Süre:** 2 hafta
**API Maliyeti:** Payment gateway %2-3 transaction fee
**Etki:** Monetization %0 → %70

### Hafta 13-14: Mobile App ve PWA
**Hedef:** Mobil uygulama ve PWA

- [ ] iOS build yapılandırması
- [ ] Android build yapılandırması
- [ ] App Store optimization (ASO)
- [ ] Play Store optimization
- [ ] PWA manifest oluştur
- [ ] Service worker oluştur
- [ ] Offline mode (basic)
- [ ] Push notifications (mobile)
- [ ] Deep linking
- [ ] App icons ve splash screens
- [ ] TestFlight beta testing
- [ ] Google Play Internal Testing

**Zorluk:** Yüksek
**Süre:** 2 hafta
**API Maliyeti:** $99/yıl (Apple Developer), $25 one-time (Google Play)
**Etki:** Mobile app %0 → %80

### Hafta 15-16: Production Hazırlığı ve Launch
**Hedef:** Production ready ve launch

- [ ] Load testing (k1000 concurrent users)
- [ ] Performance optimization (lazy loading, caching)
- [ ] Backup strategy (automated daily backups)
- [ ] Disaster recovery plan
- [ ] Error handling iyileştirme
- [ ] Monitoring dashboard (Grafana veya Datadog)
- [ ] Alert system (Sentry, UptimeRobot)
- [ ] Beta launch (100 kullanıcı)
- [ ] User feedback toplama
- [ ] Bug fix'ler
- [ ] Marketing materials (landing page, social media)
- [ ] Launch announcement
- [ ] Post-launch monitoring

**Zorluk:** Orta
**Süre:** 2 hafta
**API Maliyeti:** $0 (monitoring tools free tier)
**Etki:** Production ready

---

## Maliyet Analizi

### Geliştirme Maliyeti (16 Hafta)

| Kategori | Tahmini Maliyet |
|---|---|
| **Bildirim Sistemi** | 15,000₺ |
| **Çerez/GDPR** | 20,000₺ |
| **Analytics** | 10,000₺ |
| **Security** | 25,000₺ |
| **Documentation/Support** | 15,000₺ |
| **Monetization** | 30,000₺ |
| **Mobile App/PWA** | 35,000₺ |
| **Production Hazırlığı** | 20,000₺ |
| **Toplam** | **170,000₺** |

### İşletme Maliyeti (Aylık)

| Kalemi | Maliyet |
|---|---|
| **Supabase Pro** | $25/ay |
| **OneSignal Pro** | $9/ay |
| **Sentry** | $26/ay |
| **UptimeRobot** | $0 (free tier) |
| **Payment Gateway** | %2-3 transaction fee |
| **Apple Developer** | $99/yıl |
| **Google Play** | $25 one-time |
| **Domain** | $12/yıl |
| **SSL** | $0 (Let's Encrypt) |
| **Toplam** | **~$60/ay** |

### Tasarruflu Alternatif (Aylık)

| Kalemi | Orijinal | Tasarruflu |
|---|---|---|
| **Supabase** | $25 | $0 (free tier) |
| **OneSignal** | $9 | $0 (free tier - 10K users) |
| **Sentry** | $26 | $0 (Firebase Crashlytics) |
| **Toplam** | **$60** | **$0** |

---

## Riskler ve Çözümler

| Risk | Olasılık | Etki | Çözüm |
|---|---|---|---|
| **GDPR/KVKK uyumsuzluğu** | Orta | Çok yüksek | Legal danışmanlık, compliance audit |
| **Payment gateway reddi** | Orta | Yüksek | Alternatif gateway'ler (Iyzico, Stripe) |
| **App Store reddi** | Orta | Orta | Apple guidelines takibi, beta testing |
| **Performance sorunları** | Orta | Orta | Load testing, caching, CDN |
| **Security breach** | Düşük | Çok yüksek | Security audit, penetration testing |
| **User adoption düşük** | Orta | Yüksek | Marketing, onboarding, tutorial |
| **Revenue yetersiz** | Orta | Yüksek | Pricing optimization, premium features |
| **Supabase limit doldu** | Düşük | Orta | Pro plan upgrade veya migration |

---

## Başarı Metrikleri

### Kısa Vadeli (4 Hafta)
- **Bildirim Sistemi:** %80 aktif
- **Çerez Yönetimi:** %80 aktif
- **Analytics:** GA4 entegre
- **Legal/Compliance:** %80 uyumlu

### Orta Vadeli (8 Hafta)
- **Security:** %80 güvenli
- **Documentation:** %70 tamamlanmış
- **Support:** %60 aktif
- **Monetization:** %70 hazır

### Uzun Vadeli (16 Hafta)
- **Mobile App:** iOS + Android yayınlanmış
- **PWA:** Aktif
- **Production Ready:** %90
- **Revenue:** Aktif
- **User Base:** 1,000+ kullanıcı

---

## Sonuç

### Demo/MVP'den Gerçek Ürüne Geçiş

**Mevcut Durum:** %45 (MVP seviyesi)
**Hedef Durum:** %90 (Production ready)
**Süre:** 16 hafta (4 ay)
**Maliyet:** 170,000₺ geliştirme + $0/ay işletme (tasarruflu)

### Tavsiye

**16 haftalık plan ile başlayın.**

Bu plan ile:
- 4 ayda production ready
- Bildirim sistemi tam aktif
- GDPR/KVKK uyumlu
- Analytics entegre
- Security gelişmiş
- Documentation tamamlanmış
- Monetization hazır
- Mobile app yayınlanmış
- 0₺ aylık işletme maliyeti

---

*Son güncelleme: 2026-07-11*
*Sonraki review: 2026-07-18*
