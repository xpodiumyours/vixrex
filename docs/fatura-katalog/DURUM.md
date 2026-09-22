# Faturadan Kataloğa — Durum Defteri

Çalışma dalı: `work/fatura-katalog-e2e-20260922`  
Kilitli plan: `docs/fatura-katalog/TAMAMLAMA-PLANI.md`  
Başlangıç main SHA: `0034fe06942c4fdbe625f24bc338ef8cfa6e8a0b`

Bu dosya kullanıcıya çalışma dalında ne değiştiğini görünür tutar. Her tamamlanan geliştirme adımında aynı commit içinde güncellenir.

## Anlık durum

| Alan | Durum |
|---|---|
| Aktif faz | Faz 0 — Referans ve regresyon kilidi |
| Kod geliştirme | Henüz başlamadı |
| Main değişikliği | Yok |
| Canlı Supabase değişikliği | Yok |
| PR | Yok |
| Merge | Yok |
| Deploy / Preview | Yok |
| Dış AI gerçek fatura çağrısı | Yok |
| Son doğrulanmış adım | Plan + sapma/görünürlük kilidi |

## Faz takibi

| Faz | Durum | Kullanıcıya görünen kazanım |
|---|---|---|
| 0 — Referans ve regresyon kilidi | Sıradaki | Mevcut durum ve referans fatura ölçülebilir hale gelecek |
| 1 — Fatura satırı veri modeli | Bekliyor | Barkod/model/beden/fiyat kaybolmadan taşınacak |
| 2 — Gerçek fatura ayrıştırıcı | Bekliyor | Fatura gerçek satırlara ayrılacak |
| 3 — Ürün kimliği ve hafıza | Bekliyor | Aynı ürün tekrar tekrar keşfedilmeyecek |
| 4 — Zenginleştirme ve maliyet kapısı | Bekliyor | Yalnız gerektiğinde dış servis/AI kullanılacak |
| 5 — Görsel kaynağı | Bekliyor | İzinli ürün görselleri kaynaklı ve izlenebilir olacak |
| 6 — Ortak fatura hazırlama servisi | Bekliyor | Flutter ve Next.js aynı ürün hazırlama mantığını kullanacak |
| 7 — Ön yüz bağlantısı | Bekliyor | Hedef HTML akışı gerçek veriye bağlanacak |
| 8 — Kayıt/yayın köprüsü | Bekliyor | Onaylanan kartlar güvenli biçimde Product CORE'a yazılacak |
| 9 — Veri güvenliği | Bekliyor | Fatura ve dış servis verisi kontrollü saklanacak |
| 10 — Maliyet ölçümü | Bekliyor | Fatura/ürün başına gerçek maliyet görülecek |
| 11 — Kabul kapıları | Bekliyor | Uçtan uca çalışma kanıtlanacak |

## Tamamlanan adımlar

### Kontrol noktası 0 — Plan ve çalışma sınırı

**Neyi geliştirdik**  
Faturadan kataloğa işini tek dalda, fazlara ayrılmış ve canlıdan izole bir çalışma haline getirdik.

**Neyi değiştirdik**  
Yalnız dokümantasyon ve çalışma kontrolü eklendi. Üretim kodu değişmedi.

**Ne elde ettik**  
Hedef, kapsam dışı işler, güvenlik sınırı, fazlar ve kabul koşulları tek yerde sabitlendi. Her sonraki adımın bu dosyada görünür olması zorunlu hale geldi.

**Neye dokunmadık**  
Main, canlı Supabase, Vercel production, mevcut ürünler, 46 vitrin alanı, ödeme ve asistan NLU.

**Kanıt / test durumu**  
Bu aşama kod davranışını değiştirmiyor. Dal normal çalışma dalıdır; PR/merge/deploy yok.

## Aktif faz için kontrol kartı

### Faz 0 — Başlamadan önce

Amaç:
- referans faturayı test fixture'ına dönüştürmek,
- mevcut OCR ve Product CORE davranışını değiştirmeden başlangıç ölçümünü almak,
- hangi testlerin zaten var olduğunu çıkarmak.

Bu fazda değişmesine izin verilenler:
- test/fixture dosyaları,
- yalnız testleri destekleyen zararsız test yardımcıları,
- bu durum defteri.

Bu fazda değişmesi yasak olanlar:
- production OCR davranışı,
- veritabanı şeması,
- Flutter/Next.js kullanıcı arayüzü,
- Product CORE yazma davranışı,
- canlı veri.

Faz 0 kabul kanıtı:
- referans fatura için 13 ürün,
- 75 toplam adet,
- 6.034,00 TL toplam,
- her satır için model/barkod/varyant/beden/miktar/fiyat beklenenleri fixture olarak kayıtlı,
- mevcut sistemin başarısız olduğu noktalar test çıktısıyla görünür.

## Park alanı

Buraya yalnız plan sırasında ortaya çıkan ama aktif fazın dışında kalan fikirler yazılır. Kullanıcı onayı olmadan uygulanmaz.

Şimdilik boş.
