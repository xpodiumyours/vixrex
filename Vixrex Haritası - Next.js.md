# Vixrex Haritası - Next.js

> Kaynak: `public_web/` (Next.js 16) — 25 Eylül 2026, commit `08f03553`. Üst not: [[Vixrex Haritası]].

## Ölçümler

| Ne | Sayı |
| --- | --- |
| Lib dosyası (`src/lib/`) | 75 |
| Component (`src/components/`) | 55 |
| API route (`src/app/api/**/route.ts`) | **46** |

## Sayfa grupları (`src/app/`)

| Grup | Yollar |
| --- | --- |
| Kurumsal site `(site)` | `/` (landing + asistan sohbeti), `/kesfet`, `/kesfet/:kategori`, `/blog` (+`/:slug`, `/kapak/:slug`, `/rss.xml`, `/yayin-ilkeleri`), `/hakkimizda`, `/iletisim`, `/yardim` |
| Esnaf web paneli | `/app`, `/app/urunler`, `/app/vixrex`, `/app/hesap`, `/app/profil`, `/app/ayarlar`, `/app/bildirimler` |
| Müşteri vitrini | `/v/:slug`, `/v/:slug/urun/:productSlug`, `/v/:slug/randevu[/:token]`, `/v/:slug/yazilar[/:articleSlug]` |
| Vitrin sahiplik | `/v/:slug/randevu-yonetim`, `/v/:slug/blog-yonetim[/:articleSlug]` (owner session çerezi ile) |
| Hesap | `/giris` (Google OAuth), `/kayit`, `/sifre-sifirla`, `/hesap-bagla`, `/instagram/baglanti-tamamlandi` |
| Diğer | `/rent-demo` (kiralık vitrin akışı), `/legal/:type`, `/privacy`, `/data-deletion/status/[code]`, `/sitemap.xml`, `/robots.txt` |

## API grupları (46 route)

- **Vitrin oluşturma/yayınlama**: `create-store`, `owner-publish` (→ `publish_working_draft` RPC), `owner-draft*` (save/restore/skip/undo/batch), `owner-session[-extend]`, `owner-workspace`, `owner-bootstrap`, `owner-discard`, `owner-structured-field`
- **Ürün**: `products`, `product-categories`, `product-image-upload`, `category-images`
- **Randevu**: `appointments`, `create-booking`, `owner-booking-settings`
- **Ödeme**: `paytr/create-link`, `paytr/callback` (+ `src/lib/paytr.ts`)
- **Instagram**: `connect`, `callback`, `disconnect`, `import`, `media`, `status`
- **Diğer**: `revalidate`, `verify-recaptcha`, `report-abuse`, `account`, `articles`, `meta`, `location`, `health`, `cron/send-premium-reminders` (Vercel cron: her gün 06:00), `rent-demo`, `owner-refresh`, `owner-upload`, `owner-accept-legal`, `owner-dashboard`

## Not

- Müşteri yüzünün **tek kaynağı** bu taraf; Flutter `/v/*` yollarını buraya yönlendirir (bkz. [[Vixrex Haritası - Flutter]]).
- Asistanın web tarafı: `vixrexNluPipeline.ts` (~340 satır, client) — bkz. [[Vixrex Haritası - Akışlar]].
- Kurumsal blog **dosya tabanlı**: `src/data/blogYazilari.ts` (kodda kural: CMS/veritabanı eklenmez); `store_articles` yalnız vitrin "yazılar" içindir. Ayrıştırma: `src/lib/blogIcerik.ts` (ham HTML yok).

---

İlgili notlar: [[Vixrex Haritası]], [[Vixrex Haritası - Supabase]], [[Vixrex Haritası - Dağıtım ve CI]]
