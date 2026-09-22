# Faturadan Kataloğa — Durum Defteri

Çalışma dalı: `work/fatura-katalog-e2e-20260922`  
Kilitli plan: `docs/fatura-katalog/TAMAMLAMA-PLANI.md`  
Başlangıç main SHA: `0034fe06942c4fdbe625f24bc338ef8cfa6e8a0b`

Bu dosya kullanıcıya çalışma dalında ne değiştiğini görünür tutar. Her tamamlanan geliştirme adımında aynı commit içinde güncellenir.

## Anlık durum

| Alan | Durum |
|---|---|
| Aktif faz | Faz 0 — Ölçüm motoru ve başlangıç çizgisi |
| Kod geliştirme | Ölçüm motoru kuruldu; mevcut Vixrex çıktısına bağlantı sırada |
| Main değişikliği | Yok |
| Canlı Supabase değişikliği | Yok |
| PR | Yok |
| Merge | Yok |
| Deploy / Preview | Yok |
| Dış AI gerçek fatura çağrısı | Yok |
| Son doğrulanmış adım | Ölçüm motoru + referans doğru cevap + motor testleri |

## Faz takibi

| Faz | Durum | Kullanıcıya görünen kazanım |
|---|---|---|
| 0 — Ölçüm motoru ve başlangıç çizgisi | Devam ediyor | Ölçüm motoru hazır; sırada mevcut Vixrex'in gerçek başlangıç raporu var |
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

### Kontrol noktası 1 — Ölçüm motoru

**Neyi geliştirdik**  
Fatura çıktısını doğru cevapla karşılaştıran bağımsız bir ölçüm motoru kurduk.

**Neyi değiştirdik**  
Yalnız geliştirme/ölçüm araçları eklendi. Production OCR, kullanıcı arayüzü, veritabanı ve Product CORE değiştirilmedi.

**Ne elde ettik**  
Motor artık ürün satırı, eksik/fazla ürün, model, barkod, ürün adı, renk/varyant, beden, adet, alış fiyatı, satır toplamı, toplam adet ve toplam tutarı ayrı ayrı ölçebiliyor. Referans faturanın 13 ürün / 75 adet / 6.034,00 TL doğru cevabı kayıtlı.

**Neye dokunmadık**  
Mevcut OCR davranışı, Flutter/Next.js ekranları, canlı veritabanı, ürün yayınlama akışı, dış AI servisleri.

**Kanıt / test durumu**  
Ölçüm motorunun 3 kendi testi geçti. Kusursuz referans girdi 13/13 ürün, 75/75 adet, 6.034,00/6.034,00 TL ve %100 alan doğruluğu verdi. Eksik barkod + yanlış adet ile eksik/fazla ürün senaryoları ayrı ayrı yakalandı. Mevcut Vixrex çıktısı henüz motora bağlanmadı; Faz 0 bu yüzden tamamlanmadı.

## Aktif faz için kontrol kartı

### Faz 0 — Şimdiki nokta

Tamamlanan:
- ölçüm motoru,
- referans faturanın doğru cevap dosyası,
- motorun kendi doğrulama testleri.

Sıradaki tek iş:
- mevcut Vixrex'in bu fatura için ürettiği gerçek çıktıyı ölçüm motoruna bağlamak ve başlangıç raporunu almak.

Bu fazda değişmesine izin verilenler:
- ölçüm aracı,
- test/fixture dosyaları,
- mevcut çıktıyı ölçüm aracına taşıyan test adaptörü,
- bu durum defteri.

Bu fazda değişmesi yasak olanlar:
- production OCR davranışı,
- veritabanı şeması,
- Flutter/Next.js kullanıcı arayüzü,
- Product CORE yazma davranışı,
- canlı veri.

Faz 0 ancak mevcut Vixrex için gerçek başlangıç raporu görüldüğünde tamamlanır.

## Park alanı

Buraya yalnız plan sırasında ortaya çıkan ama aktif fazın dışında kalan fikirler yazılır. Kullanıcı onayı olmadan uygulanmaz.

Şimdilik boş.
