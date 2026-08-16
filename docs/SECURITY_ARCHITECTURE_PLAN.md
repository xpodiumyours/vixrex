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

| Kriter | Hedef | Ölçüm |
|--------|-------|-------|
| Güvenlik açıkları | 0 kritik, 0 yüksek | Denetim raporu |
| Test coverage | %80+ | Codecov |
| Build time | <5 dakika | CI pipeline |
| MTTR | <1 saat | Incident log |
| Monthly cost | <$200 | Vercel/Supabase billing |
| Migration sayısı | <10 | Migration count |

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
