# Vixrex Yol Tahtası

Son ölçüm: 2026-09-26. **Bu dosya tek gerçek kaynaktır.** Casper, Claude,
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
| Ürün havuzu | 7 / 55 firma, 4.253 ürün |
| Fatura zinciri | 4 / 5 halka |
| Firma izni | 0 / 6 hazır |

## A · Fatura zinciri

| İş | Kim | Durum |
|---|---|---|
| Firma havuzu (55 firma) | Casper | bitti |
| Ürün havuzu toplayıcı | Freebuff | 7 firma bitti, sürüyor |
| Kod eşleştirme | Claude | bitti |
| Yayın kapısı (fiyat + onay) | Claude | bitti |
| **Fatura okuma** | Claude | **karar bekliyor** |
| Gerçek faturayla deneme | Claude | yapılmadı |

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
