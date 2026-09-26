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

## Yapılanlar

| Tarih | Ajan | İş | PR |
|---|---|---|---|
| 2026-09-26 | Claude Code | Faturadan gerçek vitrin ürününe tek sistem: 2 fatura dalı birleşti, okuyucu gpt-5.6-luna'ya geçti (gerçek faturada 13/13 doğru), belge gerçeği kapısı, izin tek kaynağa bağlandı, alış fiyatı kilitli tabloya alındı, tedarikçi sınırlama, ürün havuzu 16 firma / 8.594 ürün | [#560](https://github.com/xpodiumyours/vixrex/pull/560) |
