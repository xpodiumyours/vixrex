# ADR 2026-11-02 — OpenRouter <-> Vixrex gorev ayrimi

Durum: oneri (P0) · Karar sahibi: Casper · Yurutme/duzelten: DSH · Dogrulama: DSH (bagimsiz olcum)

## Karar
Fatura -> urun karti hatti iki katmana ayrilir:
- OpenRouter: okuma + resmi kaynak arastirmasi + gorsel secimi + urun kimligi/kanonik karar + sema dayatmasi (2 preset: okuma, kart; kart icinde subagent kadrosu).
- Vixrex: yetki, is/idempotency, guvenli saklama, fiyat/stok null, yayin kapisi, riza, hata/retry, gorsel indirme + hak durumu.

## Gerekce
- Elle JSON iki kod arasinda tasimak MVP; preset sayisi/sema surumlenmedigi icin repo<->canli ayrismistir (kart: repo 5544 karakter vs canli v9 3828).
- OpenRouter yerlesik primitifleri (structured outputs strict, server tools, subagent/advisor/fusion, preset surum + designated) tek giris + tip guvenli sozlesme saglar.

## Hedef mimari
- 2 preset: vixrex-qwen-fatura-okuma-suzme (aracsiz), vixrex-urun-karti-v2 (web_search+web_fetch + arastirmaci + gorsel-secici subagent'lari + opsiyonel danisman advisor).
- Tek sozlesme: openrouter/preset-sozlesmesi.json (JSON Schema, strict, additionalProperties:false); Vixrex'te savunmaci elle parse ile dogrulanir; Zod dogrulamasi sonraki sertlestirme.
- Flag: PRESET_AKIS = mevcut | yeni; geri alma = flag. (gozlem modu ileride eklenebilir.)

## Kaynak-of-truth
- Canli designated surum = calisan gercek. Repo openrouter/*.json = sabitlenmis snapshot (slug + designated id + hash); sync scripti (read-only) eslesmeyi dogrular.
- Env override'lari kaldirilir; preset secimi yalniz kod sabiti + flag.

## Acik sorular
1. designated vs latest: API @preset/slug cagrisinda hangisi kullaniliyor? (dokumanlar celiskili; P2'de kontrollu cagriyla dogrulanacak.)
2. Kart presetinde tek kaynak yonu: repo kopyasi canliya yeni surum mu, yoksa repo snapshot canli v9'a mi esitlenecek? (Casper karari)

## Guven siniri (onaysiz gecilmez)
Para, kimlik/yetki, DB, deploy, migration, magaza yayini, KVKK, preset yazma, anahtar.

## Olcum (2026-11-02)
- Canli 6 preset; designated: okuma v22, gorsel v2, kart v9; v21 bozuk surum duruyor.
- Uretim Vercel env: yalniz OPENROUTER_API_KEY; OPENROUTER_PRESET/KART_PRESET yok -> uretim reader=VARSAYILAN, kart=urun-kart-olusturucu (canli v9).
- Yerel .env.local'de olmayan slug (vixrex-fatura-urun-kartlari-master) — yalniz dev tehlikesi.
