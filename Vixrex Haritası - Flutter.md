# Vixrex Haritası - Flutter

> Kaynak: `lib/` — 25 Eylül 2026, commit `08f03553`. Üst not: [[Vixrex Haritası]].

## Giriş zinciri

`lib/main.dart` → Sentry → Supabase (`SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` dart-define) → OneSignal → `GoRouter`.

## Router — `lib/config/app_router.dart`

- `/` landing · `/auth` · `/onboarding-chat` · `/app` ve `/home` → `HomeShellScreen` · `/bookings/:slug`
- **`/v/*` Flutter'a ait değil**: her `/v/:slug...` yolu `PublicSiteRedirectScreen` ile Next.js'e (`https://vixrex.com`) dış bağlantıda açılır. Müşteri yüzünün tek kaynağı Next.js.
- Legal sayfaları: `privacy`, `terms`, `consent`, `dataDeletion`, `/legal/:type`.

## Panel sekmeleri — `home_shell_screen.dart`

**Vitrinim → Keşfet → Vixrex (asistan) → Profil → Moderasyon (yalnız admin)**

## Katman zinciri

`controller → service → repository → Supabase`
ör. `ProductController → ProductService → SupabaseProductRepository`.

## Ölçümler (dosya sayımı)

| Ne | Sayı |
| --- | --- |
| Ekran (`*_screen.dart`) | 22 (`lib/screens/` altında 33 dart dosyası; farkı bulk upload & my_vitrin alt widget'ları) |
| Servis (`lib/services/`) | 101 |
| Controller | 13 |
| Repository (`*_repository.dart`) | 12 |
| Widget (`lib/widgets/`) | 102 |
| Model | 23 |

## Öne çıkan servis grupları

- **Yayınlama zinciri**: `store_publish_*` (validator, payload_builder, slug_generator, legal_validator) + `store_draft_persistence_service`
- **Ürün**: `product_service`, `bulk_product_upload_service`, `xml_product_upload_service`, `lib/services/ocr/`, `lib/services/excel/`
- **Asistan NLU**: `lib/services/vixrex_nlu/` (11 dosya: intent_resolver, clarifier, value_extractor, normalizer, executor…) + `vixrex_assistant_nlu_service.dart` → **Edge Function `vixrex-assistant-nlu`'yu çağırır**
- **Realtime**: `store_realtime_sync_service.dart` → `vitrin_<slug>` ve `draft:<slug>` kanalları

Ayrıntılar: [[Vixrex Haritası - Akışlar]] · backend tarafı: [[Vixrex Haritası - Supabase]]

---

İlgili notlar: [[Vixrex Haritası]], [[Vixrex Haritası - Next.js]], [[Vixrex Haritası - shared ve tool]]
