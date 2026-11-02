# OpenRouter preset envanteri (2026-11-02, read-only)

| Slug | Designated | Model | response_format | sistem(uzunluk) | repo eslesmesi |
|---|---|---|---|---|---|
| vixrex-qwen-fatura-okuma-suzme | v22 | qwen/qwen3.5-flash-02-23 | json_object | 2051 | OK (preset-okuma.json) |
| urun-kart-olusturucu | v9 | deepseek/deepseek-v4.1-flash-1017 | json_schema | 3828 | FARKLI (preset-kart.json 5544) |
| urun-gorsel-secim | v2 | qwen/qwen3.5-flash-02-23 | json_object | 1757 | OK (preset-gorsel-secim.json) |
| vixrex-urun-karti-resmi-v1 | v7 | deepseek-v4.1-flash | json_schema | 3828 | legacy (kart v9 ile ayni icerik) |
| vixrex-fatura-okuma-metin-v1 | v5 | qwen flash | json_object | 2051 | legacy (okuma ile ayni) |
| deneme-api-davranis-1792855041 | v3 | deepseek-v4.1-flash | — | 58 | test preset |

Notlar:
- vixrex-qwen-fatura-okuma-suzme v21 bozuk: model=@preset/kendisi, sistem bos, rf yok (designated DEGIL).
- urun-kart-olusturucu v7/v8/v9 = vixrex-urun-karti-resmi-v1 v5/v6/v7 ile ayni icerik (cift slug).
- Kod referanslari: reader faturaArkaPlanIslemi.ts OKUMA_PRESET=@preset/vixrex-qwen-fatura-okuma-suzme; card URUN_KART_PRESET=@preset/urun-kart-olusturucu; gorsel GORSEL_SECIM_PRESET=@preset/urun-gorsel-secim (faturaGorselSecimi.ts).
- Uretim Vercel env: OPENROUTER_PRESET/KART_PRESET/MODEL/MANAGEMENT yok; yalniz OPENROUTER_API_KEY.
