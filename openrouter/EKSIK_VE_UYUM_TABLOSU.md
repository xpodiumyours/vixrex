# Eksik ve uyum tablosu — canlı ↔ PR #741 (resmî kaynak doğrulamalı)

Tarih: 2026-11-09 · Yöntem: Yalnız resmî doküman + canlı API okuması + repo kodu.
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
| Kart preseti | `urun-kart-olusturucu` v9 (main kod) + preview'da v2 v7 | Aday `preset-kart.json` araştırma-only | Aday **canlıda yok** |
| Canlı v2 v7 şeması | `invoice_data`, `card_status`, `consumer_sale_price`, `stock_quantity` modelden istiyor | Aday istemiyor (sözleşme) | Çelişki sürüyor |
| Provider | v7: `only=[ionstream]`, `order=[ionstream, wafer]` | Aday (güncel): `only/order=[ionstream]`, `allow_fallbacks=false`, `require_parameters=true` | Aday düzeltildi |
| Araç bütçesi | fetch `max_uses:40`, search sınırsız | Aday: search `max_uses:10`, `max_total_results:30`, fetch `blocked_domains` pazaryeri/sosyal/wiki | Aday düzeltildi |
| Vixrex araştırma tekrarı | Main'de görsel tamamlama+seçim Vixrex'te yeniden araştırma yapıyor | Yeni yolda yok; `presetAkis` iş kaydına yazılıyor | Merge'e kadar üretimde açık |
| Satır hatası | Tek satır tüm işi düşürüyordu | Yeni yolda karantina + bir kez alt küme tamamlama | Dalda tamam |
| Yayın izin kapısı | Üretimdeki fonksiyon PR sürümü değil; 20261105/20261107 migration'ları üretimde yok | Dalda migration var | Preview doğrulaması açık |

## Doğrulanmış eksikler

| # | Eksik | Taraf | Önem | Durum |
|---|---|---|---|---|
| G1 | Aday tarif canlı presette değil; çalışan sürüm eski şemayla sözleşmeye aykırı | OpenRouter | Kritik | Açık — canlı yazım ayrı onay + kabul koşusu ister |
| G2 | İlk kart çağrısı hâlâ tek gövde; 20 satırda fetch bütçesi aşılıyor | Zorunlu Vixrex (RPC kuyruğu) | Kritik | Açık — parçalı kuyruk tasarımı gerekli |
| G3 | Kart başına preset sürümü/model/generation/fetch zamanı kanıtı saklanmıyor | Zorunlu Vixrex | Yüksek (üretici denetimi) | Açık |
| G4 | Hak durumu sözlüğü TS ↔ SQL arasında tutarsız (`merchant_attestation` kaldırıldı; TS yalnız `verified_supplier_permission` tanıyor, SQL üç durum) | Zorunlu Vixrex | Yüksek | Açık — tek sözlük kararı gerekli |
| G5 | Başka oturumun testi CI'ı kırdı (kayıt yükleme kurulumu yok) | Vixrex test | Orta | Düzeltme işlendi, CI bekleniyor |
| G6 | Gerçek faturayla 10/20 satır kabul koşusu yok | Kabul | Kritik | Açık — kullanıcı faturası + ücretli koşu onayı ister |
| G7 | Üretim (main) hâlâ çift araştırma + eski presetle çalışıyor | Geçiş | Yüksek | Merge'e kadar açık |

## Üretici köprüsü kabul listesi (üreticinin bakacağı kanıtlar)

- [x] Görsel üretici sitesinden alınıp Vixrex deposuna kopyalanıyor; kaynak sayfa + boyut + hak kaydı saklanıyor
- [x] Structured data: schema.org Product, doğrulanmış GTIN (sağlama basamaklı), brand, image, offers
- [x] Reddedilen/geri çekilen izin yayın kapısında denetleniyor (dal migration'ı)
- [ ] Kart başına: resmî alan adı, açılan ürün sayfası, preset sürümü, generation kimliği, çekim zamanı (G3)
- [ ] İzin sözlüğü tek kaynaktan (G4) ve üreticiye sunulabilir izin zinciri raporu
- [ ] Gerçek fatura kabul koşusu kanıtı (G6)
