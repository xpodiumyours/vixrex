# İki istemci ortak omurga denetimi

Bu kayıt, Flutter düzenleyicisi ile Next.js vitrininin hangi kararları ortak
çekirdekte, hangilerini yüzeye özel adapter'larda tuttuğunu belgeler. Ortak
çekirdekler küçük sözleşmeler üzerinden tüketilir; iki istemcinin sunum ve
operasyon akışları birleştirilmez.

## Mevcut ortak çekirdek

- Vitrin alan şeması: `shared/vitrin_alanlari.json`
- Kullanıcı mesaj kataloğu: `shared/vixrex_mesajlar.json`
- Ürün slug ve ürün yazma RPC'leri
- Sahip oturumu, çalışma taslağı güvenliği ve çakışma denetimi
- Yasal onay ve premium yayın kapıları

## #237 ile ortaklaştırılan kararlar

- Kategori kimliği: sabit ID, sıra, canonical kısa etiket ve alias'lar
- Yayın hazırlığı: isim, kategori, Türkiye mobil WhatsApp, adres, il ve ilçe
- Mağaza kolon sözleşmesi: düzenlenebilir alanların ortak alan şemasından seçimi

## Yüzeye özel kalan kararlar

- Flutter: OCR, Excel içe/dışa aktarma ve çevrimdışı işlemler
- Next.js: render, SEO, CTA ve vitrin metinleri
- Flutter kategori ikonları, hizmet önerileri ve şablon grupları
- Next.js kategori ailesi, bölüm başlığı, CTA ve WhatsApp metinleri
- İki rehberlik/kalite motorunun yüzeye özgü yorumları

## Sınırlar

Kategori tablosu, foreign key ve canlı veri dönüşümü eklenmez. Eski etiketler
alias olarak çözülür. Mevcut yayınlı vitrinler yeni kapı nedeniyle kendiliğinden
kapanmaz; yalnız ilk yayın veya yeniden yayın sırasında ortak hazırlık denetlenir.
`shared/` veya `tool/` değişiklikleri CI'da şema üretimini ve iki istemcinin
kontrollerini birlikte çalıştırır.
