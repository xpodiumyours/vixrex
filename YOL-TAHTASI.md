# Vixrex Yol Tahtası

Son ölçüm: 2026-09-28 (32 maddelik Checkup turu kapandı: #585 + #586 birleşti, kayıtsız 2 migration canlıya uygulandı, randevu butonu canlıda ölçüldü). **Bu dosya tek gerçek kaynaktır.** Casper, Claude,
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
| Kırık migration zinciri | Freebuff | **düzeldi (bu tur)** — canlıya uygulama yolu açıldı (`migration-uygula` işi); zincir yerel Supabase'de sıfırdan yeşil |

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
4. **Canlıya çıkış yolu açıldı (27 Eylül).** İki mod var: tek dosya
   (`migration-uygula/<dosya adı>`) ve toplu
   (`migration-uygula-toplu/<başlangıç dosyası>`) — toplu mod, kayıt
   tablosunda (`public.uygulanan_migrationlar`, sha256'lı) kayıtlı olanları
   atlar, kayıtsızları sırayla uygular; yarım kalan koşu aynı etiketle
   kaldığı yerden devam eder. Vitrin Ölçer migration'ı canlıda uygulandı ve
   canlı API'den doğrulandı.

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


## 2026-09-27 ek notu — vitrin ölçüm katmanı canlıya çıktı

Ölçülenler (hepsi canlıya karşı):

1. **Canlı veritabanı gerçekten gerideydi.** `vitrin_product_likes` tablosu ve
   `get_product_social_state` / `get_vitrin_olcer_summary` fonksiyonları canlıda
   yoktu (`PGRST205` / `PGRST202`) — yani #563'ün etkileşim katmanı canlıda
   ölüydü; kod main'deydi, veritabanı nesneleri yoktu.
2. **Canlıya uygulama yolu yoktu.** Ajan makinelerinde canlı veritabanı
   anahtarı yok, ajanın workflow tetikleme yetkisi de yok (dispatch API'si 403).
   Bu tur `migration-uygula` işi eklendi: Actions düğmesi veya
   `git push origin migration-uygula/<dosya adı>` etiketi ile tek dosya,
   `ON_ERROR_STOP=1` ve kendi `begin/commit` bloğu içinde uygulanıyor.
3. **Uygulandı ve doğrulandı.** `20260926180000_vitrin_olcer_profesyonel.sql`
   canlı koşuda `COMMIT` etti; ardından canlı API'den:
   `get_product_social_state('kiralik-aymira-giyim','keten-midi-elbise')` →
   HTTP 200 `{"liked":false,"like_count":0,"comment_count":0,"comments":[]}`.
   Yeni tablolar anon'a kapalı (401) — tasarım gereği yalnız dar RPC'ler açık.

**Doğrulanmayan:** beğeni/yorum/sepet akışının gerçek tarayıcıda uçtan uca
yürünmesi (ekran görülmedi) ve gerçek kullanıcı oturumuyla sahip panosu.

## 2026-09-27 ek notu 2 — toplu migration modu

4. **Toplu mod eklendi ve canlıda sınandı.** `migration-uygula-toplu/<dosya>`
   etiketi, verilen dosyadan itibaren kayıtsız migration'ları sırayla uygular;
   kayıt `public.uygulanan_migrationlar` tablosunda (`ad`, `sha256`,
   `uygulayan`, `calisma_id`). Canlı kanıt: ilk koşu (36312545718)
   `uygulanan=1`, ikinci koşu (36312615616) `atlandi (kayitli)` →
   "Yeni migration yok - canli zaten guncel." Kayıtlı dosyanın içeriği
   sonradan değişirse koşu uyarı verir.
5. **Canlıda ölçülen hata düzeltildi.** `psql -c` psql değişkenlerini yerine
   koymuyor (koşu 36312023523: `syntax error at or near ":"`); kayıt SQL'i
   artık geçici dosyaya yazılıp `-f` ile çalıştırılıyor. Aynı etiket iki kez
   itilemediği için etiket sonuna `#ek` eklenebiliyor.

## 2026-09-28 ek notu — 32 maddelik Checkup turu kapandı

6. **Denetim + düzeltme kapandı.** 32 maddelik kontrol listesinin dört dalgası
   (W1 sözleşme, W2 keşfet-para-kimlik, W3 müşteri-güven, W4 yapı-kural)
   `verify-web-cerrahi-20260928` dalında sonuçlandı → PR #586 main'de.
   Kapatılan kusurlar: vitrin görünümünden **eksik randevu linki**
   (`isBookingEnabled` hiç kullanılmıyordu → "Randevu Sistemi" açıkken hero'da
   "Randevu Al → /v/<slug>/randevu"), /giris + /kayit'te misafir verisi
   bağlama notu (/hesap-bagla), toplu yüklemede kategori eşleme + görsel
   süzgeci, keşfet kartında puan, kök hata sınırı (`src/app/error.tsx`).
   Birleşimde main'in kararları korundu: #583 noindex, website CTA kaldırma.
7. **Görsel referanslar PR #585 ile main'de.** Randevu görsel testinde 404
   esnekliği kalktı (canlıda kesin 200); Linux temelleri `gorsel-referans-yenile`
   işiyle canlıdan yenilendi (`maxDiffPixelRatio: 0.30`,
   `--update-snapshots=all` — tolerans içi değişimler de yazılır).
8. **Kayıtsız kalan 2 migration canlıya uygulandı** (bkz. 27 Eylül notu 2):
   `20260927120000_fix_delete_user_account_vitrin_kullanici_verileri` (KVKK
   hesap silme zinciri) + `20260927121000_vitrin_olcer_donem_araligi_birlestir`
   (Ölçer dönem hesabı). Toplu koşu 36362338913: `uygulanan=2 atlanan=1
   değişen=0`.
9. **Kapılar:** vitest 246/246 (1851 test), tsc, eslint, üretim derlemesi —
   hepsi yeşil. **Canlı ölçüm:** production dağıtım `68aa8c05` READY;
   `vixrex.com/v/kiralik-lezzet-duragi` 200 ve "Randevu Al" butonu canlıda
   görünüyor (önbellek kırıcıyla ölçüldü).

**Doğrulanan:** randevu butonu canlıda. **Doğrulanmayan:** gerçek kullanıcı
oturumuyla randevu sihirbazının uçtan uca doldurulması (bkz. 27 Eylül notu).
