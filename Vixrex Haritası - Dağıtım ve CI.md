# Vixrex Haritası - Dağıtım ve CI

> Ölçülmüş dağıtım/CI yapısı — 25 Eylül 2026, commit `08f03553`. Üst not: [[Vixrex Haritası]].

## İki ayrı Vercel projesi (`.vercel/project.json`)

| Proje | Ne çalıştırır | Not |
| --- | --- | --- |
| `vixrex-app` | Flutter web (`vercel-build.sh`, çıktı `build/web`) | `noindex` |
| `vixrex-public` | Next.js (`npm run build`) | cron: `/api/cron/send-premium-reminders` |

## Alan adı

`vixrex.com` → public projesi (`siteUrl.ts` sabiti). Kök `vercel.json` `/v/*`, `/sitemap.xml`, `/robots.txt`'yi public'e yönlendirir.

## CI

- `.github/workflows/ci.yml` + `changed_surfaces.py` — değişime göre `flutter` / `schema` / `public_web` yüzeyleri ayrılır; bilinmeyen path tüm işleri açar.
- 6 workflow: `ci`, `android-apk`, `database-backup`, `teslimat`, `gorsel-referans`, `assistant-safety`.

## Test tabanı

| Ne | Sayı |
| --- | --- |
| Dart testi (`test/` + `test/ocr` + 1 `integration_test`) | 113 |
| Web birim testi (`public_web/tests`) | 224 |
| Playwright spec (`public_web/e2e`) | 11 |

---

İlgili notlar: [[Vixrex Haritası]], [[Vixrex Haritası - Next.js]], [[Vixrex Haritası - İş Durumu]]
