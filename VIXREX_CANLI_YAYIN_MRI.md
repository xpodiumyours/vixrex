# VixRex Canlı Yayın MRI

> Kod + roadmap taraması — 2026-07-11  
> Kaynak: `DEMO_MVP_GERCEK_URUN_GECIS_HARITASI.md`, `ENGINEERING.md`, `production-checklist`, `lib/`, `public_web/`, `supabase/migrations/`

---

## Özet

| Metrik | Değer |
|--------|-------|
| Genel hazırlık (doc) | ~%45 |
| Çekirdek vitrin | ~%90 |
| BLOCKER sayısı | 8 |
| E2E / CI gate | 0 |

**Karar:** Çekirdek vitrin akışı ürün seviyesinde. Türkiye’de gerçek kullanıcıya açmak için KVKK, auth kurtarma, demo Keşfet, push/ops ve env kilitleri **BLOCKER**. Soft launch (web) mümkün; App Store / Play henüz değil.

---

## Katman hazırlık skoru (tahmini)

| Katman | % |
|--------|--:|
| Çekirdek vitrin | 90 |
| Güvenlik / RLS | 70 |
| Bildirim | 35 |
| KVKK / Legal | 40 |
| Auth kurtarma | 25 |
| Ops / E2E / CI | 15 |
| Çerez / Web | 10 |

---

## BLOCKER — yayına çıkmadan önce

| ID | Alan | Bulgu | Düzeltme |
|----|------|-------|----------|
| B1 | KVKK / Legal | Privacy metninde `[RESMİ UNVAN]` placeholder; draft belgeler aktive edilmiş | Hukuki inceleme + final metin + yeniden damga |
| B2 | Web KVKK | Cookie consent banner yok; terms/consent/data-deletion web sayfaları eksik | Çerez bildirimi + `LegalConfig` URL’leriyle parity |
| B3 | Auth | Şifre sıfırlama ve e-posta doğrulama yok | Supabase reset + verify UI |
| B4 | Keşfet demo | API düşünce mock mağaza (Aymira vb.) listeleniyor | Prod’da mock kapalı; empty/error + retry |
| B5 | Push | OneSignal init + yerel inbox; sunucu gönderimi yok | Edge function ile gönder **veya** push vaadini kaldır |
| B6 | Ops | E2E yok, CI workflow yok, Go-Live checklist boş | Playwright kritik akış + CI gate |
| B7 | Env / Deploy | `ONESIGNAL_APP_ID` ve `SENTRY_DSN` Vercel Flutter build’e geçmiyor | `dart-define`’lara ekle; prod env zorunlu |
| B8 | Domain | Custom domain doğrulanmamış; `PublicSiteConfig` drift (`vitrinx-two` vs `vixrex.app`) | Tek canonical URL + DNS/SSL doğrulama |

**Kanıt yolları:** `supabase/migrations/20260628_*`, `20260705_*`, `public_web` (yalnız `/privacy`), `auth_service` / `auth_screen`, `explore_controller._getMockStores`, `push_notification_service`, `ENGINEERING.md`, `vercel-build.sh`, `public_site_config`.

---

## HIGH — hemen / soft launch ile birlikte

| Madde | Detay |
|-------|-------|
| Hesap silme UI | RPC var; Ayarlar’da silme akışı yok (yalnız SSS metni) |
| Veri dışa aktarma | KVKK erişim hakkı — export endpoint/UI yok |
| Randevu PII | İsim/telefon açık metin; RLS var, şifreleme yok |
| ISR revalidation | `REVALIDATION_SECRET` boş ise sessizce atlanır |
| Web blog parity | Makaleler web’de var, Flutter public vitrinde yok |
| privacyEmail default | `Xpodiumyours@gmail.com` — kurumsal kanal değil |
| Booking timezone | `ENGINEERING.md`’de işaretli takvim riski |
| Native store | Faz 6 durdurulmuş; Play/App Store yayını yok |

---

## Zaten sağlam (demo değil)

- Vitrin oluştur → düzenle → yasal onay → yayınla
- Public vitrin (Flutter + Next.js SSR)
- Ürün CRUD + toplu CSV/Excel
- Randevu + WhatsApp bilgilendirme
- Keşfet (Supabase bağlıyken)
- `delete_user_account` cascade + appointment RLS migration’ları
- OCR sunucu limit RPC
- Yardım/SSS + profil link/QR (Complete bağlı)

---

## Neden hâlâ “demo” hissi

1. Keşfet düşünce kurgu mağaza gösteriyor — katalog “örnek” kalıyor.
2. Push tercihi var ama uzak cihaza gönderim yok — yerel inbox.
3. Landing hero Unsplash + sabit demo profiller (pazarlama OK, marka riski).
4. Preview/editor’da WhatsApp/randevu SnackBar demosu (bilinçli; `publicMode`’da gerçek).
5. Dokümanlar %45 diyor; `ENGINEERING.md` Faz 1–5 “done” ama Go-Live kutuları boş — doc drift.

---

## Soft launch sırası (minimum yol)

| Adım | Başlık | İş |
|------|--------|-----|
| 1 | Legal kilit | Final KVKK metinleri, web terms/consent/silme, çerez banner |
| 2 | Auth kurtarma | Şifremi unuttum + e-posta doğrulama |
| 3 | Demo kes | Keşfet mock kapalı; push vaadi = gerçek gönderim veya kaldır |
| 4 | Prod env | Domain, Supabase, `REVALIDATION_SECRET`, Sentry, OneSignal `dart-define` |
| 5 | Gate | Kritik E2E (kayıt→yayın→public) + production-checklist manuel |
| 6 | Soft launch | Web (`app.vixrex.app` + `vixrex.app`); native store sonra |

Native mağaza (Faz 6) bilinçli ertelenmiş. İlk açılış hedefi: Flutter web + Next.js public vitrin, doğrulanmış domain ve tamamlanmış KVKK yüzeyi.

---

## Not

Bu dosya kod değişikliği değildir; canlı yayın karar listesidir. Cursor canvas kopyası:  
`%USERPROFILE%\.cursor\projects\c-Projects-vixrex\canvases\vixrex-launch-mri.canvas.tsx`
