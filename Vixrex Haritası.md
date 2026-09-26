# Vixrex Haritası

> **Bu nedir:** VixRex'in gerçek yapısı — **yalnız çalışan koddan okunarak** hazırlandı (25 Eylül 2026, dal `faz1/kiralik-vitrin-kalite`, commit `08f03553`).
> README ve plan belgeleri **kaynak sayılmadı**; buradaki her sayı dosya sayımı, her zincir doğrudan kod okunarak doğrulanmıştır.
> Okunmayan tek şey: canlı veritabanı şeması (migration dosyalarından okundu, canlıdan teyit edilmedi).

---

## 1. Genel yapı — tek depo, iki uygulama, tek backend

```text
┌─────────────────────────────┐      ┌──────────────────────────────────┐
│ Flutter (lib/)              │      │ Next.js 16 (public_web/)         │
│ Esnaf paneli + mobil uygulama│      │ Vitrinler, landing, keşfet, blog │
│ 22 ekran · 101 servis       │      │ 75 lib · 55 component · 46 API   │
└──────────────┬──────────────┘      └──────────────┬───────────────────┘
               │  supabase_flutter                 │  @supabase/supabase-js
               └───────────────┬────────────────────┘
                               ▼
               ┌───────────────────────────────────┐
               │ Supabase                          │
               │ 26 tablo · 43 RPC · 127 migration │
               │ 3 Edge Function · Realtime        │
               └───────────────────────────────────┘
               ▲
               │ ortak sözleşmeler (13 JSON)
        shared/ — iki uygulamanın da okuduğu tek kaynak
```

| Yüzey | Ne | Ölçüm |
| --- | --- | --- |
| `lib/` | Flutter: esnaf paneli ve mobil uygulama | 22 ekran (`*_screen.dart`), 101 servis, 13 controller, 12 repository, 102 widget, 23 model |
| `public_web/` | Next.js: vitrinler, landing, keşfet, web paneli | 75 lib dosyası, 55 component, **46 API route** |
| `shared/` | İki uygulamanın ortak sözleşmeleri | 13 JSON |
| `supabase/` | Backend | 127 migration, 26 tablo, 43 RPC, 3 edge function |
| `tool/` | Şema/üretim araçları | 15 dosya (`*_uret.dart`, `sema_disa_aktar.ts`, `canli_durum.ts`, `harita_dogrula.mjs`…) |

## 2. Modül notları (haritanın parçaları)

| Not | İçerik |
| --- | --- |
| [[Vixrex Haritası - Flutter]] | `lib/` yapısı: giriş, router, panel sekmeleri, katman zinciri, servis grupları |
| [[Vixrex Haritası - Next.js]] | `public_web/`: sayfa grupları, 46 API route'un görev dağılımı |
| [[Vixrex Haritası - Supabase]] | 26 tablo, 43 RPC, 3 edge function — migration dosyalarından |
| [[Vixrex Haritası - shared ve tool]] | Ortak sözleşmeler (13 JSON) ve üretim zinciri (`tool/` 15 dosya) |
| [[Vixrex Haritası - Akışlar]] | Kritik veri akışları: yayınlama, canlı senkron, asistan (koddan doğrulanmış zincirler) |
| [[Vixrex Haritası - Dağıtım ve CI]] | İki Vercel projesi, alan adı yönlendirmesi, CI workflow'ları, test tabanı |
| [[Vixrex Haritası - İş Durumu]] | Açık dal, güncel çalışma ve bu haritanın görmediği şeyler |

## 3. Repo'nun kendi belgeleri (haritadan ayrı, kaynak değil)

- [[README]] — giriş belgesi (iddialarını doğrulamak için bu haritayı kullan)
- [[CLAUDE]] / [[AGENTS]] — ajan talimatları
- [[CONTRIBUTING]] · [[SECURITY]]
- [[GOREV-vitrin-kalite]] · [[KIRALIK-VITRIN-KALITE-PLANI]] · [[KIRALIK-VITRIN-TAMAMLAMA-PLANI]] · [[ILERLEME-TABLOSU]] — güncel iş planları
- [[URUN-KARTI-DEVIR]] · [[tek-kaynak-gecis]] — geçmiş devir/geçiş notları

---

İlgili notlar: [[Vixrex Haritası - Akışlar]], [[Vixrex Haritası - İş Durumu]]
