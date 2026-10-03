# Vixrex Control Map Protocol v2

> **ARŞİV (2026-10-03):** Bu protokol artık uygulanmıyor. `state.json`
> 2026-09-28'de donmuş, `control-map-system` dalı main'den ayrı, Base44
> omurgası aktif değil. Güncel çalışma düzeni `AGENTS.md` ve
> `.github/workflows/ci.yml` içindedir. Bu klasör yalnız geçmiş kaydıdır.

## Kilitli kapsam
Kalıcı panel URL'si Base44 üzerinde kalır. Base44 yalnız görüntü/komuta yüzeyidir.
Vixrex kontrol haritasının kodu, yapısı, canlı durumu ve ajan yönetimi GitHub'dadır.

## Kanonik omurga
Repo: `xpodiumyours/vixrex`
Branch: `control-map-system`

- `control-map-system/map.json` — Vixrex ön yüz/arka uç/veri/altyapı node ve ilişkileri.
- `control-map-system/state.json` — ölçülmüş canlı sinyaller.
- `control-map-system/management.json` — ortak ajan/yönetim sözleşmesi.
- `control-map-system/protocol.md` — bu kurallar.
- `control-map-system/web/` — panelin platformdan bağımsız referans arayüzü.

## Ortak yönetim
Aktif görevlerin ortak gerçeği GitHub Issues'tır.
Görev başlığı: `[CONTROL:<node_key>] <görev>`

Bir görev ilgili Vixrex node'una bağlıdır. Issue state, assignee ve yorumlar ortak yönetim gerçeğidir.
ChatGPT, Base44 ajanı ve diğer ajanlar aynı GitHub issue/branch omurgasını kullanır.
Base44 AI limiti omurgayı veya diğer ajanların çalışmasını durdurmaz.

## Canlı sinyal kuralları
GitHub = kod + CI
Vercel = deploy
Supabase = production veri
/api/health = runtime
Playwright/E2E = kullanıcı akışı

KOD / PREVIEW / CANLI / VERİ / E2E ayrıdır.
Kanıt yoksa `unknown`; tahminle `healthy` verilmez.

## Ajan çalışma kuralı
1. Node ve doğrudan bağımlılıkları oku.
2. Açık `[CONTROL:<node_key>]` issue var mı kontrol et.
3. Varsa aynı görevi çoğaltma; mevcut görevi kullan.
4. İlgisiz kapsamı değiştirme.
5. Ajan kendi işini kanıtsız green ilan edemez.

## Kullanıcı onayı olmadan yasak
- main merge
- production deploy / publish
- DB schema / RLS değişikliği
- auth / ödeme / güvenlik ayarı
- geri döndürülemez veri değişikliği

## Base44
Base44 veritabanı kanonik kaynak değildir; yalnız görünüm/cache olabilir.
Panel GitHub kanonik omurgasındaki durum ve görevleri göstermelidir.
