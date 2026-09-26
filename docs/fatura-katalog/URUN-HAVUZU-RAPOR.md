# Ürün Havuzu — Kurulum Raporu

Tarih: 2026-09-26
Dal: `fatura/tarayici-akis`
Belge sahibi: zincirin **eksik halkası** — firma havuzundan ürün havuzuna geçiş.

Aşağıdaki her sayı depoda ölçüldü. Ölçülmeyen hiçbir şey "yapıldı" sayılmadı.

---

## 1. Ne değişti

**Önce:** faturadaki kod yalnız tek firmada (Seher Mensucat, 236 ürün) karşılık
bulabiliyordu. Diğer 54 firmanın ürünü, kodu, fotoğrafı yoktu.

**Sonra:** 16 firmanın kataloğu toplandı.

| Ölçüm | Önce | Sonra |
|---|---|---|
| Kataloğu olan firma | 1 | **16** |
| Havuzdaki ürün | 236 | **8.594** |
| Gerçek barkod taşıyan ürün | 235 | **3.061** |
| Fotoğrafı olan ürün | 230 | **8.589** |

---

## 2. Firma firma ölçüm

| Firma | Sektör | Ürün | Barkod | Fotoğraf | Okuyucu |
|---|---|---|---|---|---|
| Toptan İç Giyim Pazarı | Tekstil | 2.887 | 4 | 2.887 | woocommerce |
| İşte Çanta | Tekstil | 2.791 | 2.081 | 2.791 | shopify |
| Santral Gıda | Gıda | 1.046 | 0 | 1.046 | woocommerce |
| Berrak İçGiyim | Tekstil | 250 | 250 | 250 | jsonld (T-Soft) |
| Kinzi Toptan | Tekstil | 250 | 2 | 250 | jsonld (İkas) |
| Emek Toptan | Gıda | 250 | 72 | 250 | jsonld (İdeasoft) |
| Erdem İçGiyim | Tekstil | 247 | 0 | 247 | jsonld (Ticimax) |
| Voltaj | Tekstil | 236 | 200 | 236 | jsonld (T-Soft) |
| Seher Mensucat | Tekstil | 235 | 234 | 230 | (önceki çalışma) |
| Saphori | Gıda | 202 | 200 | 202 | jsonld (İkas) |
| Koza İçGiyim | Tekstil | 99 | 0 | 99 | jsonld (İdeasoft) |
| Alireis Toptan Gıda | Gıda | 39 | 0 | 39 | woocommerce |
| Seç Salça Konserve | Gıda | 19 | 18 | 19 | woocommerce |
| Kul Gıda | Gıda | 18 | 0 | 18 | woocommerce |
| Kaya Zeytin | Gıda | 17 | 0 | 17 | jsonld (İdeasoft) |
| Aycenk Gıda | Gıda | 8 | 0 | 8 | woocommerce |
| **TOPLAM** | | **8.594** | **3.061** | **8.589** | |

---

## 3. Nerede kaldı — desteklenmeyenler

Bunlar "yapıldı" değil; **neden yapılamadığı ölçüldü**:

- **Kapıyı kapatmış WooCommerce (7 firma):** GÜLTEKS, Forema Tekstil, Topshow,
  TowelConcept, 5 Mutlu Gıda, Başar Ticaret, Türkmenzade. Ürün adresi 404/403
  dönüyor. Zorlanmadı.
- **Kodu olmayan katalog (4 firma):** Kazee, Zeynep Giyim, Lila Tekstil (ürün
  sayfasında ürün kodu yok, 250'şer ürün okundu), Goldfresh Mutfak (29 ürün).
  Kodsuz ürün faturayla eşleşemez; bu yüzden havuza alınmadı.
- **Türkmen Gıda (1.640 ürün):** WooCommerce açık ama ürünlerinde kod yok —
  yalnız kodsuz ürün listeliyor. Eşleştirme için kullanılamıyor.
- **İlya Tekstil (37 ürün):** Aynı durum — kod yok, fotoğraf yok.
- **NevresimToptan.com (OpenCart):** Site haritası boş, standart ürün adresi yok.
- **Ulaşılamayan (3 firma):** Beds and Covers, Demir Gıda Pazarlama, Makro Plus
  Gıda. Kök adres 5xx/ağ hatası verdi.
- **Kalan 39 firma:** henüz taranmadı. `node scripts/katalog/tara.mjs` ile
  otomatiklere bakılır; elle gerekenler `--platform=jsonld` ile.

---

## 4. Bulunan gerçek sınırlar

1. **Ürün kodu var, barkod az.** 8.594 ürünün 3.061'inde gerçek barkod var.
   Eşleştirme çoğunlukla **model kodu** üzerinden olacak. Barkod yalnız
   Shopify ve birkaç sitede dolu.
2. **Kod her firmada aynı biçimde değil.** Seher'de `ELT1302` gibi üretici
   kodu; Kul Gıda'da `0282`; Aycenk'te `KP1`. Çok kısa kodlar (4 karakterden
   az) yanlış eşleşmeyi önlemek için bilerek aranmaz.
3. **Sitedeki fiyat perakende fiyatı.** Havuzda **fiyat tutulmuyor**; alış
   fiyatı yalnız faturadan gelir.
4. **Katalog hacmi büyük.** Toplam ~8 MB. Bu yüzden kataloglar `src/` dışında
   tutulur ve uygulama çalışırken okur; `next.config.ts` içindeki
   `outputFileTracingIncludes` dağıtıma katılmasını sağlar.

---

## 5. Görsel izin kapısı

Mevcut kod `izinDurumu: "bekliyor"` yazıyordu ama fotoğraflar yine de
kullanılıyordu. Artık **gerçek bir kapı** var:

> `ureticiUrunuBul` fotoğrafı yalnız firmanın izni `"var"` ise döner.
> İzin yoksa ürünün adı, markası ve açıklaması gelir; `gorseller` boş kalır.

Bugün **hiçbir firmanın izni "var" değil** (Seher dâhil). Yani faturadan gelen
ürünlerin fotoğrafı henüz akmıyor — bu bir hata değil, bilinçli kapıdır.

İzin vermek için `public_web/src/lib/ureticiKatalog.ts` içindeki firma
satırında `izinDurumu` alanı `"var"` yapılır. İzin listesi tek yerde durur.

---

## 6. Doğrulama

- `npx vitest run` → **1.686 test geçti** (225 dosya).
- `npx tsc --noEmit` → temiz.
- Ürün havuzu için 30 yeni test:
  - `tests/katalog/toplayici.test.ts` (14): kod/barkod normalleştirme, HTML
    temizleme, kodsuz ürünün elenmesi, tekrar eden görsellerin atılması, sayılar.
  - `tests/api/uretici-katalog.test.ts` (16): çok firmalı yükleme, Casper'ın
    faturasındaki 12 gerçek kod, barkodun koddan önce gelmesi, kısa kodun
    eşleşmemesi, izin kapısı, **her katalog dosyasının firma listesinde
    karşılığı olması**.

---

## 7. Kalan 39 firma tarandı — sonuç

26.09.2026, 02:1x: kalan 39 firmanın tamamı denendi.

- **Otomatik okuyucu (woocommerce/shopify), tüm 55 firma üzerinde tekrar
  koşuldu.** Daha önce toplanan 16 katalog bozulmadı (dosyalar aynı kaldı,
  sayıları değişmedi — doğrulandı). Yeni firma eklenmedi: kalan firmaların
  hiçbiri bu iki platformu kullanmıyor.
- **`jsonld` okuyucusu, kalan 22 firmada örnek modda (`--sinir-urun=5`,
  dosya YAZMADAN) denendi:**
  - 13 firma: sitemap/ürün sayfası bulundu ama JSON-LD kaydında `sku`/`mpn`/
    `gtin` alanlarının hiçbiri dolu değil → **kod yok**. (Ak-Tekstil, Donella
    İç Giyim, Merter Giyim, ToptanÇeyiz, Özsa Özen-İş, Maviyelken Home,
    Yasin Örme, İşmont, Kazımoğlu Çeyiz, Turkiye Textil, Özşen Triko,
    Bool Tüketim + ilk taramadan Ak-Tekstil)
  - 9 firma: `sitemap.xml` üzerinden ürün adresi bulunamadı → **tanınmadı**.
    (Beyaz Nevresim, Merterium, İstanbul Toptan İç Giyim/Tozcu, Güngören
    Tişört, Önlükçüm, Alya İş Elbiseleri, Berdan Tekstil, Karasoy Kumaşçılık,
    Ömrüm Toplu Tüketim)
- **Donella İç Giyim ayrıca elle incelendi:** ürün görselleri
  `order.donella.com.tr` alt alan adında duruyor (ör. `0632P` kodu), ama o
  alt alan adı eski bir platform kullanıyor (Windows-1254 kodlama, 404 dönen
  tahmini adresler) ve genel okuyucularla uyumlu değil. Zorlanmadı — bu firma
  **elle** (firma ile doğrudan veri isteyerek) ele alınmalı.

**Sonuç: 16/55 firma otomatik yollarla toplanabiliyor. Kalan 39'u otomatik
araç kapsamıyor** — ya kapıları kapalı/kod yok (17'si, madde 3'te), ya da
genel okuyucuların anlayacağı bir yapı sunmuyor (22'si, yukarıda). Bu firmalar
için tek yol: **doğrudan firmadan ürün dosyası istemek** — zaten izin
konuşmasının bir parçası olarak planlanan adım.

## 8. Sıradaki iş

1. Firma izinlerini al ve `izinDurumu` alanını `"var"` işaretle — fotoğraflar
   o zaman akmaya başlar. İzin istenirken, otomatik toplanamayan 22 firmadan
   ürün dosyaları da istenmeli.
2. **Gerçek faturayla uçtan uca dene:** fatura → kod → katalog eşleşmesi →
   ürün kartı. Sunucu tarafı rastgele faturalarla doğrulandı
   (`fatura/rastgele-dogrulama` dalı), gerçek fotoğrafla henüz denenmedi.
3. Havuz daha da büyürse katalogları veritabanına taşı ve eşleştirmeyi indeksli
   sorguya çevir; dosya okuma her soğuk başlangıçta tüm katalogları belleğe alır.
