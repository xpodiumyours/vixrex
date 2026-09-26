# Ajan Ortak Listesi

> **Bu nedir:** Bu depoda birden fazla ajan çalışıyor. Kim ne bitirdi, tek
> satırda burada durur. Amaç: aynı işi iki kez yapmamak ve birbirinin ayağına
> basmamak.

## Ortak kurallar (Casper, 2026-09-26)

1. **Aynı anda ana dala birleştirmeyin.** Ana dal kapısı Casper'da.
2. **Dal adı önekleri ayrık olsun.** Buffy (Freebuff) → `freebuff/`,
   Claude Code → `fatura/`, `faz*/`, `fix/` gibi kendi önekleri.
3. **Biten her işi buraya tek satır düş.** Tarih + kim + ne + PR numarası.
4. **Ana dala inmeden önce `git pull` yap.**

> Not: en alta ekleyin, araya girmeyin — iki ajan aynı anda yazarsa çakışma
> en aza insin.

## Fatura okuyucu — AÇIK (2026-09-26)

`OPENROUTER_API_KEY` canlı (production) ortama eklendi. Fatura okuma açık.

Kontrol: `curl https://vixrex.com/api/fatura-okuyucu-durumu` → `{"hazir":true}`

Anahtar biterse/iptal olursa cevap `{"hazir":false}` olur ve "Faturadan Ekle"
düğmesi kendiliğinden gizlenir — kimse hata görmez. Bakiye:
openrouter.ai/settings/credits (fatura başına ~7 kuruş).

## Yapılanlar

| Tarih | Ajan | İş | PR |
|---|---|---|---|
| 2026-09-26 | Claude Code | Faturadan gerçek vitrin ürününe tek sistem: 2 fatura dalı birleşti, okuyucu gpt-5.6-luna'ya geçti (gerçek faturada 13/13 doğru), belge gerçeği kapısı, izin tek kaynağa bağlandı, alış fiyatı kilitli tabloya alındı, tedarikçi sınırlama, ürün havuzu 16 firma / 8.594 ürün | [#560](https://github.com/xpodiumyours/vixrex/pull/560) |
| 2026-09-26 | Buffy (Freebuff) | Asistan panelinde sessiz hata yutma kapandı — hatalar sohbete yazılıyor, döngü kırıcı eklendi (25 Eylül'de mahsur kalmış fix ana dala taşındı) | [#564](https://github.com/xpodiumyours/vixrex/pull/564) |
| 2026-09-26 | Buffy (Freebuff) | Dal süpürmesi: 70+ dal tarandı, mahsur kalan tek gerçek fix #564'tü. `fix/vitrin-gorsel-duzeltme`'deki 2 SQL ana dala alınmadı (Unsplash adresleri "görseller kendi depomuzda" kararına aykırı, eski kimliklerle canlıda 0 satır buluyor) — fikri Faz 2 fotoğraf kimliği işine kanıt olarak taşındı | — |
