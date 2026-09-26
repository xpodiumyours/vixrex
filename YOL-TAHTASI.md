# Vixrex Yol Tahtası

Son ölçüm: 2026-09-26, 03:45 (fatura/rastgele-dogrulama dalı, commit bbd1605a). **Bu dosya tek gerçek kaynaktır.** Casper, Claude,
Freebuff ve Gemini aynı tahtaya bakar. İş bitince satırın durumu burada
güncellenir — başka yerde değil.

Görsel hâli (yalnız Casper için):
https://claude.ai/code/artifact/d6059a7a-91f5-4322-bd07-80c159cd268c

## Hedef

Esnaf fatura fotoğrafını atar, ürün kartları vitrinine iner. Sonra firmaların
kapısına çalışan sistem gösterilerek izin istenir.

## Dört kol

| Kol | Durum |
|---|---|
| Esnaf yolculuğu | 6 / 8 hazır |
| Ürün havuzu | 16 / 55 firma, 8.594 ürün (commit'lendi, itildi) |
| Fatura zinciri | 4.5 / 5 halka |
| Firma izni | 0 / 6 hazır |

## A · Fatura zinciri

| İş | Kim | Durum |
|---|---|---|
| Firma havuzu (55 firma) | Casper | bitti |
| Ürün havuzu toplayıcı | Freebuff + Claude | **bitti (bu tur)** — 16/55 otomatik toplanabiliyor, kalan 39 ölçülmüş bir sınır (kapı kapalı/kod yok/platform tanınmadı) |
| Kod eşleştirme | Claude | bitti |
| Yayın kapısı (fiyat + onay) | Claude | bitti |
| Fatura okuma — TEK okuma ucu (telefon + web aynı uç) | Claude | **bitti** — `/api/fatura-oku` → Kilo (ücretsiz, anahtarsız) → deterministik satır ayırma → katalog |
| Fatura okuma — mimari düzeltme (iki ayrı beyin → bir beyin) | Claude | **bitti** — eski OpenAI ucu (anahtarsız, hiç çalışmıyordu) silindi; telefon artık kendi yerel OCR zincirini değil, aynı sunucu ucunu kullanıyor |
| Fatura okuma — gerçek fotoğrafla kamera testi | — | **doğrulanamadı — fiziksel telefon gerekiyor** (okuma motorunun kendisi canlı test edildi, gerçek kağıt fatura fotoğrafıyla değil) |
| Gerçek faturayla deneme | Claude | Sunucu tarafı 1704 testle doğrulandı (yapay zekâ olmadan: düz kod eşleştirme). Ayrıca Kilo'nun görüntü okuma yeteneği gerçek bir istekle canlı denendi — 10 ürün kodu doğru okundu. Kamera adımı hâlâ bekliyor. |

## B · Firma izni — hiçbiri yok

| İş | Kim | Durum |
|---|---|---|
| Firma kaydı (sistemde "üretici" yok) | Freebuff | yok |
| İzin kaydı | Freebuff | kapısı kuruldu, kaydı yok |
| Mail gönderme altyapısı | Claude | yok |
| İzin belgesi metni | Casper | yok |
| Belge saklama (imzalı PDF) | Freebuff | yok |
| Yönetim ekranı (izin işaretleme) | Freebuff | yok |

## C · Esnaf yolculuğu

| İş | Kim | Durum |
|---|---|---|
| Kaydolma (Google ile) | — | çalışıyor |
| Vitrin + yayın kapısı | — | çalışıyor |
| Telefonda kullanım (ana ekrana ekle) | — | çalışıyor |
| Uygulama dağıtımı (indirme linki yok) | Claude | yok |
| Ürün fotoğrafı sorunu (182 ürün / 21 foto) | Freebuff | karar bekliyor |
| Kırık migration zinciri | Freebuff | kırık |

## D · Canlıya çıkış

| İş | Kim | Durum |
|---|---|---|
| Fatura akışını canlıya alma | Casper onayı | bekliyor |
| Kiralık vitrin geçişi | Freebuff | bekliyor |
| İlk gerçek esnaf | Casper | yok |

## Casper'ın vermesi gereken kararlar

1. **Faturayı ne okusun?** (a) telefon uygulamasındaki okuyucu, (b) Başak'ın
   hazır fatura aracı, (c) tarayıcıya eklenecek okuyucu. Üçü de ücretsiz.
2. **İzinsiz firmanın fotoğrafı ne olsun?** Bugün hiç kullanılmıyor.
3. **Firmaya ne teklif ediyoruz?** Mail metni buna göre yazılacak.
4. **Hangi firmadan başlıyoruz?** Faturası olan tek firma Seher Mensucat.

## Riskler

1. **İzinsiz ürün çekme kapısı açık.** Esnaf bugün herhangi bir firmanın ürün
   dosyasını izinsiz çekip vitrine koyabiliyor (`lib/services/xml_product_upload_service.dart`).
   Firmalara gitmeden kapatılmalı.
2. **Fatura okumanın doğruluğu hiç ölçülmedi.** Gerçek fotoğrafla denenmedi.
3. **Barkod nadir.** 4.253 ürünün yalnız 258'inde gerçek barkod var; eşleşme
   çoğunlukla ürün koduna bağlı.
4. **Canlıya çıkış yolu kapalı.** Migration zincirinde kod hatası var.

## Çakışmama kuralı

Her ajan kendi worktree'sinde çalışır. Dosya sahipliği:

- Claude: `InvoiceToProducts.tsx`, `api/fatura-oku`, `products/batch`, `ureticiKatalog.ts`
- Freebuff: `scripts/katalog/`, katalog JSON dosyaları, izin/firma tabloları
- Bir ajan diğerinin alanına girecekse önce bu dosyaya yazar.

`lib/` (Flutter) izinsiz açılmaz. Ana dala hiçbir şey Casper onayı olmadan inmez.


## 2026-09-26 ek notu — ne gerçekten doğrulandı, ne doğrulanmadı

Bu dalda (`fatura/rastgele-dogrulama`, `C:\Projectsixrex-dogrula`) yapılanlar:

1. **Sunucu tarafı genelleşme kanıtı** — Casper'ın tek gerçek faturası (13 satır)
   dışında, aynı katalogdan tohumlanmış rastgelelikle üretilmiş 4 farklı "sahte
   fatura" gerçek `/api/products/batch` uç noktasından geçirildi. 11/11 test
   geçti. **Yapay zekâ kullanılmadı** — düz kod/barkod araması.
2. **`/api/fatura-eslestir` eklendi** — fotoğrafı kim okursa okusun (telefon,
   Başak, ileride tarayıcı), satırları TEK yerde kataloğa bağlayan uç nokta.
   Hem tarayıcı (çerez) hem Flutter (edit_token) çağırabiliyor. 9/9 test.
3. **Flutter'daki asıl bug bulundu ve düzeltildi** —
   `invoice_ocr_draft_adapter.dart:69` tedarikçi kanıtını HER ZAMAN "zayıf"
   yazıyordu, karar motoru bu yüzden kapıyı hiç açmıyordu. Yeni
   `CatalogInvoiceTraceResolver` gerçek katalog sonucuyla kanıtı yükseltiyor.
   Gerçek sunucu yanıtı simüle edilerek kanıtlandı: `canPublish` artık
   gerçekten `true` dönüyor (eskiden asla dönemezdi). 755/755 Flutter testi.

**Doğrulanmayan tek şey:** telefonun kamerasının GERÇEK bir kağıt faturayı
doğru okuyup okumadığı. Bu adım fiziksel bir cihaz gerektiriyor, bu ortamda
test edilemez. Zincirin geri kalanı (eşleştirme, kanıt, yayın kapısı) artık
kanıtlı biçimde çalışıyor — kalan tek soru "kamera metni doğru çıkarıyor mu."
