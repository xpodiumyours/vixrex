# Vixrex Haritası - shared ve tool

> Kaynak: `shared/` ve `tool/` — 25 Eylül 2026, commit `08f03553`. Üst not: [[Vixrex Haritası]].

## `shared/` — ortak sözleşmeler (13 JSON)

İki uygulamanın da okuduğu **tek kaynak**:
`business_categories`, `fiyatlandirma` (premium fiyat), `product_attribute_schema`, `product_image_policy`, `renkler`, `vitrin_alanlari`, `vitrin_field` sözleşmeleri, `working_hours_contract`, `vixrex_mesajlar`, `vixrex_niyet_sozlugu` ve NLU senaryo dosyaları.

Asistan metinlerinin tek kaynağı `shared/vixrex_mesajlar.json`; niyet sözlüğü `shared/vixrex_niyet_sozlugu.json`.

## Üretim yönü (koddan doğrulandı)

```text
public_web/src/lib/vitrinFieldSchema.ts
  → tool/sema_disa_aktar.ts
  → shared/vitrin_alanlari.json
  → tool/alan_semasi_uret.dart
  → lib/config/*.g.dart
```

## `tool/` — 15 dosya

| Dosya | Ne |
| --- | --- |
| `alan_semasi_uret.dart`, `business_categories_uret.dart`, `fiyatlandirma_uret.dart`, `fotograf_kurali_uret.dart`, `mesaj_semasi_uret.dart`, `renk_uret.dart` | shared JSON'larından Dart/TS kodu üretir |
| `sema_disa_aktar.ts` | Web şemasını shared'a aktarır |
| `canli_durum.ts` | Salt okunur canlı ölçüm (`node tool/canli_durum.ts`) |
| `duman_testi.mjs`, `vixrex_assistant_local_check.ps1` | Yerel hızlı kontroller |
| `sablon_gorsellerini_tasi.mjs`, `sahipsiz_gorselleri_temizle.mjs` | Depolama temizlik araçları |
| `harita_dogrula.mjs` | Harita notlarındaki dosya sayılarını gerçek kodla doğrular (`node tool/harita_dogrula.mjs`) |
| `merge-hazir.sh`, `sync_skills.sh` | Süreç yardımcıları |

---

İlgili notlar: [[Vixrex Haritası]], [[Vixrex Haritası - Akışlar]], [[tek-kaynak-gecis]]
