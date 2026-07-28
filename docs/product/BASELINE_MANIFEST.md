# Vixrex — Güvenli Temel Manifestosu (Baseline Manifest)

**Tarih:** 28 Temmuz 2026  
**Hazırlayan:** AI ajan + kullanıcı onayı  
**Durum:** Kullanıcı onayı bekliyor  

---

## 1. Git Durumu

| Alan | Değer |
|------|-------|
| Dal | `main` |
| Commit | `a51ae6a8a39b5c6be09cd20f7add5c6756129934` |
| Tarih | 2026-07-28 21:51:12 +0300 |
| Mesaj | `fix(editor): guard cover auto-publish, improve GPS accuracy handling, and fix sentry zone initialization` |
| Uzak Sunucu | `origin` (`https://github.com/xpodiumyours/vixrex.git`) |
| `origin/main` ile ilişki | Güncel, eşit |

## 2. Vercel Projeleri

### Flutter Paneli (Vixrex)

| Alan | Değer |
|------|-------|
| Vercel Proje ID | `prj_AfdnDnAcIwSCaJuBoCQh1TP1GvWR` |
| Organizasyon ID | `team_1CnMra3tKzFkbrH6Byj54ycJ` |
| Production URL | Doğrulanmadı — Vercel CLI oturumu yok |
| Production Commit | Doğrulanmadı |
| Build Komutu | `bash vercel-build.sh` |
| Çıktı Dizini | `build/web` |

### Public Web (vixrex-public)

| Alan | Değer |
|------|-------|
| Vercel Proje ID | `prj_dCMDIaefrTHg6ysiUDT7veiWI52h` |
| Organizasyon ID | `team_1CnMra3tKzFkbrH6Byj54ycJ` |
| Vercel Proje Adı | `vixrex-public` |
| Production URL | Doğrulanmadı — Vercel CLI oturumu yok |
| Production Commit | Doğrulanmadı |
| Framework | Next.js |
| Build Komutu | `npm run build` |

## 3. Supabase

| Alan | Değer |
|------|-------|
| Proje URL | `https://chfulefxczbgurtgavtp.supabase.co` |
| Migration Dizini | `supabase/migrations/` |
| Yedek Scripti | `supabase/backup/backup_database.sh` |
| Yedek Dizini | `supabase/backup/dumps/` |
| Edge Functions | `send-booking-push`, `vixrex-assistant-nlu` |
| Production Şeması | `supabase_schema.sql` (envanter) |
| Production Şema Doğrulaması | Yapılmadı — Supabase CLI bağlantısı yok |

## 4. Ortam Değişkenleri

### Flutter Paneli (`dart_defines.local.json`)

| Değişken | Değer |
|----------|-------|
| `SUPABASE_URL` | `https://chfulefxczbgurtgavtp.supabase.co` |
| `PUBLIC_SITE_URL` | `http://localhost:3000` (local) |
| `GOOGLE_WEB_CLIENT_ID` | Mevcut |
| `RECAPTCHA_SITE_KEY` | Mevcut |

Production dart defines bilgisi yerelde yok — `dart_defines.example.json` referans alınmalı.

### Public Web (`public_web/`)

Next.js env dosyaları mevcut, içerik kontrol edilmedi.

## 5. GitHub Koruma Durumu

| Kontrol | Durum |
|---------|-------|
| `main` branch protection (ruleset) | Yok |
| CODEOWNERS | Yok |
| PR şablonu | Yok |
| Açık PR'lar | `codex/` (3), `feat/` (1), diğer (2) — toplam 6 açık branch |

## 6. Mevcut CI/CD

| Workflow | Ne Yapar |
|----------|----------|
| `android-apk.yml` | Manuel Android APK paketleme |
| `public-web-lint.yml` | Yalnızca lint |
| `database-backup.yml` | Haftalık Supabase yedek |

## 7. Test Durumu

| Alan | Durum |
|------|-------|
| Test sayısı | ~52 test dosyası |
| `test/contracts/` | Yok |
| `integration_test/` | Yok |
| Flutter test | Mevcut, unit/widget ağırlıklı |
| Next.js test | Mevcut durumu doğrulanmadı |
| Supabase test | Yok |

## 8. Notlar

- Bu manifest salt okunur kontrollerle hazırlanmıştır.
- Vercel production commit, URL ve Supabase şema doğrulaması için Vercel CLI / Supabase CLI oturumu gereklidir.
- Kullanıcı onayından sonra güncellenmeyen maddeler "doğrulanmadı" olarak kalır.
