# Vixrex Supabase Operasyonu

## Hedef

Supabase migration zincirini şemanın tek kaynağı yapmak. Boş veritabanı repo ile kurulabilmeli.

## Çalışma Alanı

`C:\Projects\vixrex-supabase-foundation` — `feat/supabase-foundation` dalı.

## Güvenlik Kuralları

- Canlıya bağlantı, SQL, migration veya deploy YOK
- `edit_token` SELECT yetkisi AÇILMAZ
- Eski migrationlar silinmez
- Commit/push yalnız Furkan onayıyla

## Tamamlanan Aşamalar

| Aşama | Durum |
|-------|-------|
| M0 (envanter) | ✓ |
| C0 (canlı envanter) | ✓ |
| M1 (iskelet + CI) | ✓ |
| C1-R2/R3/R4 patchleri | ✓ |
| M2V (yerel doğrulama) | ✓ |
| M2 (commit) | ✓ |
| **M3 (hesap silme)** | ✓ |

## M2V Sonuçları

| Kapı | Sonuç |
|------|-------|
| db reset | ✓ GEÇTİ |
| schema diff | ✓ TEMİZ |
| test db | ✓ 19/19 PASS |

## M2 Commit

M2V kapıları yeşil. Şimdi M2 commit yapılacak.

Değişen dosyalar:
- `supabase/migrations/20260717205159_canonical_baseline.sql` — canonical baseline
- `supabase/seed.sql` — legal_documents, provider_id, hash düzeltmeleri
- `supabase/tests/database/rls.test.sql` — pgTAP testleri
- `supabase/config.toml` — yerel yapılandırma

Commit mesajı: `feat(supabase): canonical baseline ve yerel test altyapısı`

## Sonrası (M2 Sonrası)

- M3 (hesap silme + upload)
- M4 (test + workflow)
- C3 (production)
