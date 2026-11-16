# Eksik ve uyum tablosu — canlı ↔ PR #741 (resmî kaynak doğrulamalı)

Tarih: 2026-11-13 · Yöntem: Yalnız resmî doküman + canlı API okuması + repo kodu.
**Ajan çıktıları, commit mesajları ve test isimleri kabul kanıtı sayılmaz.**
Kabul yalnız: yeşil CI, gerçek fatura koşusu, preview'da fiyat→onay→vitrin kanıtı ile olur.

## Resmî kaynaklardan öğrenilenler

| Konu | Resmî kaynak | Öğrenilen |
|---|---|---|
| Preset sürümü | openrouter.ai/docs/guides/features/presets.md | API ile adreslenen presette **latest sürüm** çalışır; yeni sürüm yazmak designated/active sürümü değiştirir; istek alanları preset değerlerini shallow-merge ile ezer |
| Structured outputs | openrouter.ai/docs/guides/features/structured-outputs.md | `strict:true` bile her provider'da birebir garanti vermez; destek **endpoint bazında** değişir; `require_parameters:true` gerekir |
| Web search | openrouter.ai/docs/guides/features/server-tools/web-search.md | `max_results` (1-25), `max_uses`, `max_total_results` ile bütçe sınırlanabilir |
| Web fetch | openrouter.ai/docs/guides/features/server-tools/web-fetch.md | `max_uses` aşılınca araç hata döndürür; `allowed_domains`/`blocked_domains` araç seviyesinde zorlanabilir |
| Provider routing | openrouter.ai/docs/guides/routing/provider-selection.md | `only` uygun provider kümesini kısıtlar, `order` deneme sırasıdır, `allow_fallbacks` yedek davranışını belirler; çelişik ayar tahmin edilemezlik üretir |
| Ürün verisi | schema.org/Product | `brand`, `gtin`, `image`, `manufacturer`, `offers` üretici köprüsünün asgarî dilidir |

## Canlı ↔ 741 karşılaştırması

| Bileşen | Canlı (üretim) | PR #741 (dal) | Durum |
|---|---|---|---|
| Kart preseti | `urun-kart-olusturucu` v9 (main kod) + OpenRouter'da `vixrex-urun-karti-v2` v19 | `preset-kart.json` araştırma-only (v19 ile eşit) | Preset canlıda v19 ile eşit |
| `vixrex-urun-karti-v2` v19 şeması | `invoice_data`, `card_status`, `consumer_sale_price`, `stock_quantity` modelden istenmiyor | Sözleşme ile birebir uyumlu (`items` saf JSON) | Eşitlendi |
| Provider | v19: `order=[ionstream]`, `allow_fallbacks=true`, `require_parameters=true` | `preset-kart.json`: `order=[ionstream]`, `allow_fallbacks=true`, `require_parameters=true` | Eşitlendi |
| Araç bütçesi | search `max_uses:30`, `max_total_results:60`, fetch `max_uses:40` + `blocked_domains` | `preset-kart.json` ile birebir aynı | Eşitlendi |
| Vixrex araştırma tekrarı | Main'de görsel tamamlama+seçim Vixrex'te yeniden araştırma yapıyor | Dalda Vixrex tarafı araştırma/görsel seçimi kaldırıldı; `presetAkis` iş kaydına yazılıyor | Merge'e kadar üretimde açık |
| Satır hatası / kümeleme | Tek gövde; ticari sır alanları modele gidiyor | Dalda alış fiyatı/toplam maskeleniyor, üretici kümeleme (`ureticiKumesi`) ve tak-çıkar priz (`faturaPriz.ts`) var | Dalda tamam |
| Yayın izin kapısı | Üretimdeki fonksiyon PR sürümü değil; 20261105/20261107 migration'ları üretimde yok | Dalda migration (20261107120000) ve TS sözlüğü (`DOGRULANMIS_HAK_DURUMLARI`) var | Preview/üretim migration doğrulaması açık |

## Doğrulanmış eksikler

| # | Eksik | Taraf | Önem | Durum |
|---|---|---|---|---|
| G1 | Aday tarif (`preset-kart.json`) OpenRouter `vixrex-urun-karti-v2` v19 ile eşitlendi | OpenRouter | Kritik | Kapandı (v19 canlıda) |
| G2 | İlk kart çağrısı arka plan RPC kuyruğunda tek gövde; çok satırlı faturada üretici kümeleme (`groups`) ile tek aramada gruplanıyor | Vixrex (`faturaKartPreset.ts`) | Yüksek | Dalda üretici kümeleme eklendi; gerçek fatura koşusu ile doğrulanacak |
| G3 | Kart başına preset/akış, model, generationId ve kaynak (`fetched_at`, `snippet`) kanıtı | Vixrex | Yüksek (üretici denetimi) | Dalda tamam (`fe5d981a`, `ccad1592`) |
| G4 | Hak durumu sözlüğü TS (`DOGRULANMIS_HAK_DURUMLARI`) ↔ SQL (`20261107120000`) arasında üç doğrulanmış durumla (`verified_supplier_permission`, `verified_feed_terms`, `merchant_owned_media`) eşitlendi | Vixrex | Yüksek | Dalda tamam |
| G5 | Başka oturumun testi CI'ı kırdı (kayıt yükleme kurulumu yok) | Vixrex test | Orta | Kapandı |
| G6 | Gerçek faturayla 10/20 satır kabul koşusu yok | Kabul | Kritik | Açık — kullanıcı faturası + ücretli koşu onayı ister |
| G7 | Üretim (main) hâlâ çift araştırma + eski presetle çalışıyor | Geçiş | Yüksek | Merge'e kadar açık |

## Üretici köprüsü kabul listesi (üreticinin bakacağı kanıtlar)

- [x] Görsel üretici sitesinden alınıp Vixrex deposuna kopyalanıyor; kaynak sayfa + boyut + hak kaydı saklanıyor
- [x] Structured data: schema.org Product, doğrulanmış GTIN (sağlama basamaklı), brand, image, offers
- [x] Reddedilen/geri çekilen izin ve doğrulanmamış görsel hak durumu yayın kapısında denetleniyor (dal migration'ı `20261107120000`)
- [x] Kart başına: resmî alan adı, açılan ürün sayfası, preset sürümü, generation kimliği, çekim zamanı (G3 — dalda tamam)
- [x] İzin sözlüğü TS ↔ SQL tek kaynaktan (`DOGRULANMIS_HAK_DURUMLARI`) eşitlendi (G4 — dalda tamam)
- [ ] Gerçek fatura kabul koşusu kanıtı (G6)
