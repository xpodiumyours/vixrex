# public_web ESLint borcu (ayrı kalite işi)

> **Son güncelleme:** 14 Temmuz 2026  
> **Durum:** Tamamlandı — ayrı kalite çalışmasında kapatıldı  
> **Kapsam:** `public_web/` içinde `npm run lint`  
> **İlk ölçüm:** 38 problem (28 error + 10 warning) — 14 Temmuz 2026  
> **Son ölçüm:** 0 error + 0 warning — 14 Temmuz 2026

Bu dosya, `MIMARI_SORUNLAR_VE_COZUM.md` içindeki route sahipliği işinin
**dışında** tamamlanan lint temizliğinin kalıcı kaydıdır. Mimari çalışma
değiştirilmedi; kalite borcu ayrı dal ve PR kapsamında kapatıldı.

---

## Neden ayrı?

| Soru | Cevap |
|------|--------|
| Route / `vercel.json` değişikliğinden mi çıktı? | **Hayır** |
| Ne zaman birikti? | Instagram testleri ~28 Haziran; cookie ~11 Temmuz; sayfa JSX daha eski |
| Neden şimdi göründü? | Mimari doğrulamada `npm run lint` çalıştırıldı; CI lint kapısı yoktu |
| Mimari PR’a fix karıştırılsın mı? | **Hayır** — bu listede ayrı iş |

Detay teşhis: Codex + Cursor envanteri (14 Temmuz).

---

## Komut

```bash
cd public_web
npm.cmd run lint
```

İlk çalıştırma: **28 error, 10 warning** → toplam **38**.  
Temizlik sonrası: **0 error, 0 warning**.

---

## Tamamlanan kümeler

### L1 — Instagram API testleri (`no-explicit-any` + unused)

**Öncelik:** Yüksek (hataların çoğunluğu burası)

| Dosya | Tipik sorun |
|-------|-------------|
| `tests/api/instagram/callback.test.ts` | `any`, unused import |
| `tests/api/instagram/connect.test.ts` | unused import |
| `tests/api/instagram/data-deletion.test.ts` | çoklu `any` |
| `tests/api/instagram/disconnect.test.ts` | `any`, unused import |
| `tests/api/instagram/import.test.ts` | çoklu `any` |
| `tests/api/instagram/media.test.ts` | `any`, unused |
| `tests/api/instagram/status.test.ts` | `any`, unused import |

**Yapılan:** Mock tipleri gerçek fonksiyon dönüş tiplerinden türetildi; query
sonuçları `unknown` ile modellendi ve kullanılmayan import’lar silindi.

**Uygulanmayan alternatif:** `tests/**` ignore edilmedi; ESLint kuralları
gevşetilmeden gerçek tip temizliği yapıldı.

---

### L2 — Cookie consent (`react-hooks/set-state-in-effect`)

**Öncelik:** Orta (Next 16 hooks kuralı)

| Dosya | Sorun |
|-------|--------|
| `src/components/cookie-consent/AnalyticsLoader.tsx` | `useEffect` içinde senkron `setConsent(readConsent())` |
| `src/components/cookie-consent/CookieBanner.tsx` | `useEffect` içinde senkron `setVisible` / `setAnalytics` |

**Yapılan:** Consent, `useSyncExternalStore` ile SSR snapshot korunarak izlendi;
effect içindeki senkron state güncellemeleri kaldırıldı.

---

### L3 — Public sayfalar (küçük)

**Öncelik:** Düşük / hızlı kazanım

| Dosya | Sorun |
|-------|--------|
| `src/app/v/[slug]/page.tsx` | `WhatsApp'tan` → `react/no-unescaped-entities`; kullanılmayan `_` |
| `src/app/v/[slug]/urun/[productSlug]/page.tsx` | kullanılmayan `image` |

**Yapılan:** Apostrof escape edildi ve unused değişkenler kaldırıldı.

---

### L4 — API route `any`

**Öncelik:** Orta

| Dosya | Sorun |
|-------|--------|
| `src/app/api/instagram/disconnect/route.ts` | `no-explicit-any` |
| `src/app/api/meta/data-deletion/route.ts` | `no-explicit-any` |

**Yapılan:** Ürün payload alanları `unknown` üzerinden güvenli string
daraltmasıyla okunuyor.

---

## Uygulanan sıra (ayrı kalite PR)

1. [x] **L3** — TSX apostrof ve unused temizliği  
2. [x] **L2** — Cookie consent harici-store refactor’u  
3. [x] **L4** — İki API route için `unknown` alan daraltması  
4. [x] **L1** — Instagram test mock tipleri ve unused import temizliği

Her dilim: `npm.cmd run lint` + ilgili `npm.cmd test` (Instagram testleri).

---

## Tamamlanma kapısı

- [x] `npm run lint` → **0 error, 0 warning**  
- [x] Lint borcu mimari plandan ayrı tutuldu ve bu kalite kaydında kapatıldı  
- [x] Instagram / cookie kodunda açık `any` ve yasaklı effect kalıbı kalmadı  
- [x] `npm test` → **7 dosya, 18 test geçti**  
- [x] `npm run build` → **Next.js 16.2.9 production build geçti**  
- [x] `.github/workflows/public-web-lint.yml` ile yeni PR’larda lint kapısı eklendi  

---

## Bilinçli dışarıda bırakılanlar

- Flutter `dart analyze` / `widget_test` borçları → burada değil (MIMARI §10 / ayrı Flutter işi).  
- Canlı redirect / mobil cihaz doğrulaması → mimari plan.  
- UI parite → mimari plan dışı (ayrı ürün işi).

---

## İlgili dosyalar

| Dosya | Rol |
|-------|-----|
| `public_web/eslint.config.mjs` | Lint kuralları; şu an `tests/` ignore edilmiyor |
| `public_web/package.json` | `lint`: `eslint` · `eslint-config-next` 16.2.9 |

---

*Bu kayıt mimari route planına (`MIMARI_SORUNLAR_VE_COZUM.md`) bağlanmaz;
kalite borcu ayrı çalışmada kapatılmıştır.*
