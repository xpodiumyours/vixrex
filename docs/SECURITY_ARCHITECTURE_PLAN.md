# Vixrex Güvenlik ve Mimari Stratejisi
> Tarih: 2026-08-16  
> Hazırlayan: Yazılım Güvenlik Denetimi  
> Durum: Taslak — onay bekliyor

---

## 1. Yönetici Özeti

Bu plan, Vixrex projesinin **güvenlik duruşunu** ve **uzun vadeli bakım maliyetini** azaltmak için hazırlanmıştır.  
İki ana hedef var:

1. **Aktif güvenlik risklerini kapatmak** — 20 tur denetiminden kalan açıklar
2. **Mimariyi profesyonel seviyeye çıkarmak** — özellikle feature-first yapıya geçiş

---

## 2. Mevcut Güvenlik Durumu

### 2.1 Kapanmış Açıklar (✅ Tamamlandı)

| Tur | Açıklık | Durum | Kanıt |
|-----|---------|-------|-------|
| 1 | Rent-demo clone abuse | ✅ KAPANDI | `20260815180000_secure_rent_demo_flow.sql` |
| 2 | Audit log sahteciliği | ✅ KAPANDI | `20260815210000_default_privileges_ve_audit_log.sql` |
| 3 | Owner upload abuse | ✅ KAPANDI | Günlük kota + IP limiti |
| 4 | CI secret scanning | ✅ KAPANDI | Gitleaks eklendi |
| 5 | Report-abuse fail-open | ✅ KAPANDI | Fail-closed + rate-limit |
| 6 | Internal SECURITY DEFINER | ✅ KAPANDI | Revoke migration |
| 7 | search_path mutable | ✅ KAPANDI | SET search_path eklendi |
| 12 | Stored XSS | ✅ KAPANDI | sanitize-html allowlist |
| 13 | OAuth/Instagram | ✅ KAPANDI | state + nonce + token şifreleme |
| 14 | SSRF | ✅ KAPANDI | Instagram allowlist |
| 15 | Dependency çakışması | ✅ KAPANDI | @sentry/nextjs 10.70.0 |
| 16 | Auth hardening | ✅ KAPANDI | code_hash + session_token_hash |

### 2.2 Açık Riskler (🔴 Düzeltilmesi Gereken)

| # | Tur | Risk | Seviye | Etki |
|---|-----|------|--------|------|
| 1 | 6 | Internal SECURITY DEFINER — auth trigger'ları hala public | 🔴 Yüksek | Veri sızıntısı |
| 2 | 9 | RLS + IDOR — policy olmayan sensitive tablolar | 🔴 Yüksek | Yetki yükseltme |
| 3 | 10 | Service-role kullanımı — 11 yerde getSupabaseAdmin() | 🟠 Yüksek | Over-privilege |
| 4 | 18 | Production monitoring — Sentry DSN production'da tanımlı değil | 🟠 Orta | Gözlemlenemez |
| 5 | 19 | Vercel log analizi — yok | 🟡 Orta | Abuse görünmüyor |
| 6 | 20 | Backup + DR testi — yapılmamış | 🟡 Orta | Felaket kurtarma yok |

### 2.3 Operasyonel Eksikler

| Alan | Durum | Öneri |
|------|-------|-------|
| Platform alarmları | ⚠️ Kurulacak | Vercel + Supabase bütçe alarmları |
| Dependency güncellemeleri | ⚠️ Manuel | Dependabot / Renovate ekle |
| Pre-commit hooks | ⚠️ Yok | Husky + lint-staged ekle |
| Migration testleri | ⚠️ Yok | Her migration için unit test |

---

## 3. Risk Matrisi

### 3.1 By Severity

| Seviye | Risk Sayısı | Açıklama |
|--------|-------------|----------|
| 🔴 Kritik | 0 | Tüm kritik riskler kapatıldı |
| 🔴 Yüksek | 3 | Internal DEFINER, RLS/IDOR, service-role |
| 🟠 Orta-Yüksek | 1 | Monitoring eksikliği |
| 🟡 Orta | 2 | Log analizi, backup testi |

### 3.2 By Category

| Kategori | Açık Risk | Kapanan Risk |
|----------|-----------|--------------|
| Veritabanı Güvenliği | 3 | 8 |
| API Güvenliği | 0 | 7 |
| Kimlik Doğrulama | 0 | 3 |
| Dosya Güvenliği | 0 | 3 |
| Dependency Güvenliği | 0 | 2 |
| Monitoring | 3 | 0 |
| Maliyet Güvenliği | 0 | 5 |

---

## 4. Kapsamlı Düzeltme Planı

### 4.1 Sprint 1 — Kalan Kritik Güvenlik Açıkları (Hafta 1-2)

**Hedef:** Tüm yüksek seviye riskleri kapat

#### 4.1.1 Internal SECURITY DEFINER Temizliği
- [ ] `handle_new_user`, `handle_updated_user` auth trigger'larını public’ten kaldır
- [ ] `prevent_demo_store_mutation` trigger’ını kaldır
- [ ] Tüm internal helper fonksiyonları revoke et
- [ ] **Doğrulama:** `information_schema.routine_privileges` üzerinden kontrol

#### 4.1.2 RLS + IDOR Denetimi
- [ ] Tüm sensitive tablolarda policy var mı kontrol et
- [ ] `owner_sessions`, `store_working_drafts`, `store_instagram_tokens` için policy ekle
- [ ] Her policy’i manuel test et: Kullanıcı A → Kullanıcı B verisi erişebiliyor mu?
- [ ] **Doğrulama:** Integration test suite’u çalıştır

#### 4.1.3 Service-role Kullanım Taraması
- [ ] `getSupabaseAdmin()` kullanımını haritala
- [ ] Her kullanım için gerekli mi kontrol et
- [ ] Gereksiz kullanımları `getSupabaseClient()` ile değiştir
- [ ] **Doğrulama:** Code review + static analysis

### 4.2 Sprint 2 — Maliyet ve Operasyonel Güvenlik (Hafta 3-4)

**Hedef:** Maliyet saldırılarına karşı koruma, platform alarmları

#### 4.2.1 Platform Alarmları
- [ ] Vercel: Monthly spend alarmı ($100)
- [ ] Vercel: Function execution alarmı (1M/ay)
- [ ] Supabase: Storage size alarmı (10GB)
- [ ] Supabase: Storage bandwidth alarmı (50GB/ay)
- [ ] **Doğrulama:** Test email/Slack bildirimi al

#### 4.2.2 Dependency Otomasyonu
- [ ] Dependabot veya Renovate ekle
- [ ] Günlük dependency taraması
- [ ] Auto-merge için güvenlik patch’leri ayarla
- [ ] **Doğrulama:** İlk otomatik PR oluştu mu?

#### 4.2.3 Pre-commit Hooks
- [ ] Husky ekle
- [ ] lint-staged ile format + lint + test
- [ ] Commit hook’larını test et
- [ ] **Doğrulama:** Kötü commit engelleniyor mu?

### 4.3 Sprint 3 — Monitoring ve Gözlemlenebilirlik (Hafta 5-6)

**Hedef:** Production’da ne olduğunu gör

#### 4.3.1 Sentry Yeniden Ekle
- [ ] @sentry/nextjs@10.70.0 ile uyumlu versiyon kullan
- [ ] NEXT_PUBLIC_SENTRY_DSN environment variable’ı ekle
- [ ] Error boundary ekle
- [ ] API route’larda exception handler ekle
- [ ] **Doğrulama:** Test hatasını Sentry’de gör

#### 4.3.2 Vercel Analytics
- [ ] Vercel Analytics enable et
- [ ] Web Vitals izleme
- [ ] Error tracking aktif et
- [ ] **Doğrulama:** Dashboard’da veri görünüyor mu?

#### 4.3.3 Uptime Monitoring
- [ ] UptimeRobot veya Pingdom ekle
- [ ] Critical endpoint’leri izle:
  - `/api/health` (yoksa ekle)
  - `/api/owner-upload`
  - `/api/rent-demo`
- [ ] 1 dakikada 1 kontrol, 3 kez başarısız = alert
- [ ] **Doğrulama:** Alert emaili al

### 4.4 Sprint 4 — Mimari Modernizasyon (Hafta 7-12)

**Hedef:** Feature-first architecture, bakım maliyetini düşür

#### 4.4.1 Dart Tarafı: Feature Modules
```
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── store/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── product/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── upload/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── guidance/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── core/
│   ├── errors/
│   ├── usecases/
│   ├── utils/
│   └── theme/
└── main.dart
```

**Her feature şunları içerir:**
- `data/`: Repository implementations, models
- `domain/`: Entities, use cases, repository interfaces
- `presentation/`: Widgets, screens, controllers

**Fayda:**
- Her feature bağımsız test edilebilir
- Yeni feature ekleme kolay
- Bakım maliyeti düşer

#### 4.4.2 Next.js Tarafı: App Router Stabilizasyon
- [ ] Tüm route’ları `app/` altında organize et
- [ ] API route’ları feature-based böl
- [ ] Shared components kütüphanesi kur
- [ ] **Doğrulama:** Build + test geçer

#### 4.4.3 Supabase Migration Stratejisi
- [ ] Migration naming convention’a geç
- [ ] Her migration tek sorumluluk
- [ ] Migration test framework’ü kur
- [ ] **Doğrulama:** Her migration test ediliyor

---

## 5. Uygulama Yol Haritası

### Faz 1: Güvenlik Kapanışı (Hafta 1-2)
- Internal DEFINER revoke
- RLS policy denetimi
- Service-role audit
- **Teslimat:** Güvenlik denetimi raporu

### Faz 2: Operasyonel Güvenlik (Hafta 3-4)
- Platform alarmları
- Dependency otomasyonu
- Pre-commit hooks
- **Teslimat:** Otomasyon raporu

### Faz 3: Gözlemlenebilirlik (Hafta 5-6)
- Sentry entegrasyonu
- Vercel Analytics
- Uptime monitoring
- **Teslimat:** Monitoring dashboard

### Faz 4: Mimari Modernizasyon (Hafta 7-12)
- Feature-first Dart yapısı
- Next.js app router organizasyonu
- Supabase migration framework
- **Teslimat:** Mimari dokümantasyon

---

## 6. Test Stratejisi

### 6.1 Güvenlik Testleri

| Test Türü | Kapsam | Sıklık | Otomasyon |
|-----------|--------|--------|-----------|
| Unit test | Tüm RPC, controller, validator | Her commit | ✅ CI |
| Integration test | Auth, RLS, IDOR | Her PR | ✅ CI |
| Security scan | Gitleaks, npm audit | Her commit | ✅ CI |
| Dependency check | Dependabot | Günlük | ✅ GitHub |
| Penetration test | SSRF, XSS, IDOR | Aylık | ⚠️ Manuel |

### 6.2 Regression Test

- Her sprint sonu full test suite
- Critical path’ler E2E test
- Performance test (maliyet profili)

---

## 7. Monitoring ve Alarm Stratejisi

### 7.1 Critical Metrics

| Metrik | Eşik | Aksiyon |
|--------|------|---------|
| Error rate | >1% | Immediate alert |
| API latency | >2s | Warning |
| Storage size | >10GB | Alert + review |
| Monthly spend | >$100 | Immediate review |
| Failed login attempts | >10/dk | Block IP |

### 7.2 Alert Channels

- **P0 (Kritik):** SMS + Email + Slack
- **P1 (Yüksek):** Email + Slack
- **P2 (Orta):** Slack
- **P3 (Düşük):** Weekly digest

---

## 8. Maliyet Koruması

### 8.1 Kod Seviyesi
- ✅ Per-store günlük upload limiti: 100/24s
- ✅ Per-IP günlük upload limiti: 50/24s
- ✅ ReCAPTCHA + rate-limit
- ✅ Fail-closed security controls

### 8.2 Platform Seviyesi
- ✅ Vercel bütçe alarmı
- ✅ Supabase kota alarmı
- ⚠️ Cloudflare WAF (opsiyonel)

### 8.3 İzleme
- Maliyet dashboard (Vercel + Supabase)
- Haftalık maliyet raporu
- Anormal kullanım pattern’leri

---

## 9. Başarı Kriterleri

### 9.1 Güvenlik (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Kritik güvenlik açıkları | **0** | Denetim raporu | Her sprint başı otomatik tarama |
| Yüksek güvenlik açıkları | **0** | Denetim raporu | Her sprint başı otomatik tarama |
| Orta güvenlik açıkları | **0** | Denetim raporu | Aylık denetim |
| Güvenlik tarafından onaylanmamış PR | **0** | GitHub PR review | CI’da engelle |
| Production’da plaintext secret | **0** | Gitleaks + manual | Her commit’te tarama |
| CAPTCHA/reCAPTCHA olan endpoint’lerde fail-open | **0** | Code review | Her PR’da kontrol |
| RPC’lerden anon/authenticated yetkisi olan internal | **0** | SQL audit | Her migration sonrası |

### 9.2 Test ve Kalite (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Unit test coverage | **≥ %90** | Codecov | Her PR’da coverage raporu |
| Integration test coverage | **≥ %80** | Codecov | Her PR’da coverage raporu |
| Tüm critical path’lerin testi | **%100** | Test suite | Her sprint sonu |
| CI pipeline başarı oranı | **%100** | GitHub Actions | Her commit’te |
| Build süresi | **< 5 dakika** | CI pipeline | Her commit’te |
| Lint hata sayısı | **0** | ESLint + Flutter analyze | Her commit’te |
| TypeScript/Dart type hatası | **0** | tsc + dart analyze | Her commit’te |

### 9.3 Güvenlik Odaklı Code Review (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Tüm PR’ların en az 1 onayı | **%100** | GitHub branch protection | CI’da engelle |
| Güvenlik ile ilgili değişikliklerin security review’u | **%100** | GitHub review | PR template + CI |
| Critical path değişiklikleri için 2 onay | **%100** | GitHub branch protection | CI’da engelle |
| Review süresi | **< 24 saat** | GitHub metrics | Aylık rapor |

### 9.4 Maliyet ve Performans (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Monthly Vercel spend | **< $150** | Vercel dashboard | Haftalık kontrol |
| Monthly Supabase spend | **< $100** | Supabase billing | Haftalık kontrol |
| API latency (p95) | **< 500ms** | Vercel Analytics | Günlük |
| Storage kullanımı | **< 20GB** | Supabase dashboard | Günlük |
| Storage bandwidth | **< 100GB/ay** | Supabase dashboard | Haftalık |
| Function execution | **< 1M/ay** | Vercel dashboard | Haftalık |
| Maliyet alarmı tetiklenme süresi | **< 5 dakika** | Platform alarm log | Aylık test |
| Gecikmeli ödeme / borç | **0 kez** | Billing history | Aylık kontrol |

### 9.5 Monitoring ve Gözlemlenebilirlik (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Production error visibility | **%100** | Sentry dashboard | Her incident’ta |
| Uptime | **≥ 99.9%** | UptimeRobot/Pingdom | Aylık |
| MTTR (Mean Time To Recovery) | **< 30 dakika** | Incident log | Aylık |
| Alert yanlış alarm oranı | **< 5%** | Alert log | Aylık |
| Log retention | **≥ 30 gün** | Platform settings | Aylık kontrol |

### 9.6 Backup ve Felaket Kurtarma (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Backup sıklığı | **Günlük** | Supabase dashboard | Otomatik |
| Backup retention | **≥ 7 gün** | Supabase dashboard | Aylık kontrol |
| Restore test sıklığı | **Haftalık** | Runbook | Haftalık test |
| RTO (Recovery Time Objective) | **< 4 saat** | Restore test | Haftalık |
| RPO (Recovery Point Objective) | **< 24 saat** | Backup frequency | Günlük |

### 9.7 Dependency ve Supply Chain (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Gecikmeli güvenlik patch’leri | **0** | Dependabot/Renovate | Günlük |
| Dependency yaşı | **< 6 ay** | `npm audit` + `flutter pub outdated` | Haftalık |
| Lock file conflicts | **0** | CI pipeline | Her commit’te |
| Unused dependencies | **0** | `npm prune` + `flutter pub deps` | Haftalık |

### 9.8 Migration ve Schema (Sert Kriterler)

| Kriter | Hedef | Ölçüm | Doğrulama |
|--------|-------|-------|-----------|
| Migration başına satır | **< 200** | Migration files | Her migration’da |
| Migration başına sorumluluk | **1** | Migration naming | Her migration’da |
| Migration test coverage | **%100** | Test suite | Her migration sonrası |
| Schema drift | **0** | CI validation | Her commit’te |
| Production migration hatası | **0** | Incident log | Aylık |

---

## 10. Kilitli Sıralama — Kesin Öncelikler

Aşağıdaki sıralama **kesin ve değişmez**.  
Önce tamamlanmalı, sonra bir sonraki adıma geçilmeli.

### Öncelik 1 — Güvenlik Kapanışı (Sprint 1, Hafta 1-2)
**Kritik kural:** Bu sprint bitmeden Sprint 2’ye geçilmez.

1. **Internal SECURITY DEFINER** — auth trigger’ları public’ten çıkar
2. **RLS + IDOR** — tüm sensitive tablolarda policy ekle/test et
3. **Service-role audit** — gereksiz `getSupabaseAdmin()` kullanımlarını kaldır
4. **Doğrulama:** Otomatik penetration test + manual review

### Öncelik 2 — Operasyonel Güvenlik (Sprint 2, Hafta 3-4)
**Kritik kural:** Sprint 1’in tüm testleri geçmeli.

1. **Platform alarmları** — Vercel + Supabase + Cloudflare
2. **Dependency otomasyonu** — Dependabot veya Renovate
3. **Pre-commit hooks** — Husky + lint-staged
4. **Doğrulama:** Test ortamında alarm tetikleme testi

### Öncelik 3 — Gözlemlenebilirlik (Sprint 3, Hafta 5-6)
**Kritik kural:** Sprint 2’nin tüm otomasyonu çalışır olmalı.

1. **Sentry** — Next.js 16 uyumlu, production DSN ile
2. **Vercel Analytics** — Web Vitals + error tracking
3. **Uptime monitoring** — critical endpoint’ler
4. **Doğrulama:** Test hatasını Sentry’de gör, uptime testi geç

### Öncelik 4 — Mimari Modernizasyon (Sprint 4, Hafta 7-12)
**Kritik kural:** Sprint 3’ün tüm monitoring’i aktif olmalı.

1. **Feature-first Dart architecture** — lib/features/ yapısı
2. **Migration framework** — tek sorumluluk, <200 satır
3. **Schema tracking** — migration metadata table
4. **Doğrulama:** Her feature bağımsız test edilebiliyor

---

## 11. Red Lines (Asla Aşılmayacak Kurallar)

1. **Production’da plaintext secret yok** — CI’da Gitleaks engeller
2. **Fail-open security control yok** — CAPTCHA, auth, rate-limit her zaman fail-closed
3. **Internal RPC’ler public’te değil** — her migration sonrası SQL audit
4. **Migration tekrar uygulanamaz** — idempotent, versioned
5. **Test coverage %90’ın altına düşmez** — CI’da engelle
6. **Merge edilmiş PR’ların testleri geçmeli** — branch protection
7. **Backup testi geçmemişse production’da değişiklik yok** — manual gate

---

## 12. Incident Response Checklist

Production’da güvenlik olayı olduğunda:

- [ ] **0-5 dakika:** Alert al, severity belirle (P0/P1/P2)
- [ ] **5-15 dakika:** İlk müdahale — rollback veya hotfix
- [ ] **15-30 dakika:** Kök neden analizi
- [ ] **1 saat:** Postmortem başlat
- [ ] **24 saat:** Rapor tamamla, düzeltmeleri planla

---

## 13. Review ve Onay

| Rol | İsim | Onay Tarihi | İmza |
|-----|------|-------------|------|
| Yazılım Mühendisi | [Boş] | _____ | _____ |
| Güvenlik Mühendisi | [Boş] | _____ | _____ |
| Teknik Lider | [Boş] | _____ | _____ |


---

## 10. Riskler ve Azaltma

| Risk | Olasılık | Etki | Azaltma |
|------|----------|------|---------|
| Migration hatası | Orta | Yüksek | Test + staging |
| Dependency breaking change | Düşük | Orta | Dependabot + review |
| Cost spike | Orta | Yüksek | Alarmlar + kod limitleri |
| Team velocity düşmesi | Yüksek | Orta | Incremental refactor |

---

## 11. Sonraki Adımlar

1. **Bu planı onayla** — review + sign-off
2. **Sprint 1’i başlat** — Internal DEFINER + RLS
3. **Her sprint sonu demo** — göster, feedback al
4. **Aylık denetim** — güvenlik durumu güncelle

---

## 12. Ekler

- A: Güvenlik denetimi detaylı raporu
- B: Mimari diagramları
- C: Test suite yapısı
- D: CI/CD pipeline tanımı
