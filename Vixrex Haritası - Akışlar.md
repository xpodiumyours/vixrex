# Vixrex Haritası - Akışlar

> Koddan doğrulanmış kritik veri zincirleri — 25 Eylül 2026, commit `08f03553`. Üst not: [[Vixrex Haritası]].

## 1. Vitrin kurma → yayınlama

```text
Landing asistanı (LandingAsistanSohbeti)
  → POST /api/create-store
  → get_or_create_working_draft (RPC)
  → Esnaf paneli (/app web veya Flutter /app) + sahip oturumu (ownerSession)
  → POST /api/owner-publish
  → publish_working_draft (RPC)
  → /v/:slug (müşteri görünümü)
```

## 2. Canlı senkronizasyon (her iki istemcide de aynı)

```text
stores satırı değişti   → Realtime kanalı `vitrin_<slug>`  → iki taraf da dinliyor
Asistan taslakta alan   → Realtime kanalı `draft:<slug>`   → alan_guncellendi olayı
```

Kaynaklar: `lib/services/store_realtime_sync_service.dart`, `public_web/src/lib/canliVitrinSenkron.ts`, `public_web/src/lib/workingDraftBroadcast.ts`.

## 3. Asistan (üç parça)

```text
Flutter:  lib/services/vixrex_nlu/*  ─────────────┐
Web:      vixrexNluPipeline.ts (~340 satır)  ─────┤→ niyet/değer çıkarma, netleştirme, doğrulama
Edge:     supabase/functions/vixrex-assistant-nlu ─┘
```

- Metinlerin tek kaynağı: `shared/vixrex_mesajlar.json`
- Niyet sözlüğü: `shared/vixrex_niyet_sozlugu.json`
- Ayrıntı: [[Vixrex Haritası - Flutter]], [[Vixrex Haritası - Supabase]], [[Vixrex Haritası - shared ve tool]]

---

İlgili notlar: [[Vixrex Haritası]], [[Vixrex Haritası - Next.js]]
