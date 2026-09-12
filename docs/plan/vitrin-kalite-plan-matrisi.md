# Vitrin ve Ürün Kartı Kalite — PLAN MATRİSİ

> **Bu bir kemik matris DEĞİL.** Uyum sözleşmesindeki 17 matris kalıcıdır:
> iki istemcinin uyumunu sonsuza kadar kilitler, bir hücrenin bozulması
> **hata** demektir.
>
> Bu matris geçicidir: bir hedefe giderken plandan sapmayı önler. `✗`
> hata değil **henüz yapılmadı** demektir. Satırlar bitince matris
> emekli olur, projede kalmaz.

**Referans:** Trendyol ürün detay sayfası düzeni (12 Eylül 2026'da canlı sayfa
tarayıcıyla açılıp yapısı ölçüldü). Karar Casper'a aittir: *"her vitrinin ve
ürün kartının kalitesi öyle olacak."*

**Neden uyum sözleşmesinin içinde değil:** Onlar iki istemcinin birbirine
uyumunu sorar ve kalıcıdır. Bu, dışarıdan bir kalite hedefine ne kadar
yaklaştığımızı sorar ve hedefe varınca biter.

**Kopyalanan şey DÜZEN, bileşen değil.** Trendyol bir pazaryeri: sepet, kupon,
çoklu satıcı var. Vitrinde yok ve olmayacak ([[vixrex-hedef]] kapsam sınırı).
Boş kutu kurmak, kutuyu hiç kurmamaktan kötüdür — bugünkü `Stok: Bilgi alın`
bunun canlı örneği.

**Dürüstlük kuralı (1-17 ile aynı):** `✓` yalnız kod **ve** onu kilitleyen test
birlikte görüldüyse yazılır. Test dosyasının varlığı testin geçtiği anlamına
gelmez. Kanıtı olmayan hücre `✗` kalır.

**Durum işaretleri:** `✓` tam · `△` kısmi · `✗` yok · `İstisna` bilerek dışarıda

---

## Ölçüm anı

- Ölçülen sayfa: `https://vixrex.com/v/kiralik-kuafor/urun/sac-kesimi-yikama`
- Kaynak dosya: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx` (399 satır)
- Veri: 38 ürün, 9 kiralık şablon (12 Eylül temizliği sonrası)

## Matris

| # | Öğe | Referans (Trendyol) | Vixrex bugün — kanıt | Engel | Durum |
|---|---|---|---|---|---|
| 1 | Görünür yol izi | 5 kademe: *Trendyol › Kozmetik › Cilt Bakım › Güneş Ürünü › Ürün* | **Yalnız JSON-LD**, ekranda yok — `page.tsx:258-292` `breadcrumbJsonLd`. Google görüyor, müşteri görmüyor | Kod | `✗` |
| 2 | Görsel galerisi | Büyük görsel + 8 küçüklük şerit + ok tuşları | Tek görsel. Ölçüm: **38 ürünün 38'inde `jsonb_array_length(image_urls) = 1`** | **Veri** — kod değil | `✗` |
| 3 | Puan ve değerlendirme sayısı | `★4,5 · 164 Değerlendirme` — başlığın hemen altında, **fiyattan önce** | Ürün sayfasında hiç yok (`page.tsx` içinde `rating\|puan\|review` eşleşmesi 0). Vitrin düzeyinde `stores.rating_score` var ama **esnafın kendi yazdığı sayı**, yorum tablosu yok | **Veri + hukuk** | `✗` |
| 4 | Soru-cevap sayacı | `53 Soru-Cevap` | WhatsApp düğmesi var, sayaç yok | Kod | `△` |
| 5 | Fiyat | Büyük, turuncu, tek başına satırda | `150 TL`, belirgin kutuda | Yok | `△` (test yok) |
| 6 | İki eylem düğmesi | `Şimdi Al` + `Sepete Ekle` — ikisi de satışa hizmet eder | `WhatsApp'tan ürün sor` + **`Instagram`**. İkincisi müşteriyi **siteden çıkarıyor** (`page.tsx`, 12 Instagram eşleşmesi) | Kod | `△` |
| 7 | Güven/teslimat kutusu | Hızlı Teslimat, Tahmini Teslim | Ürün sayfasında **yok** (`calisma\|acik\|saat` eşleşmesi 0). Vitrin sayfasında var: *"ŞU AN AÇIK"*, saatler, adres | Kod | `✗` |
| 8 | Satıcı kartı | Logo, ✓, `9.6` puan, takipçi, `MAĞAZAYA GİT` | Yalnız metin bağlantısı: *"← Stil Studio vitrinine dön"* | Kod | `✗` |
| 9 | İlgili/diğer seçenekler | `ÜRÜNÜN DİĞER SATICILARI` + öneriler | Hiçbiri (`ilgili\|benzer\|related` eşleşmesi 0). Sayfa çıkmaz sokak | Kod | `✗` |
| 10 | Ürün özellikleri | `Ürün Bilgileri`, `Ürün Özellikleri`, `Güvenlik Bilgileri` | Tek satır açıklama. **Süre yok** (`sure\|dakika` eşleşmesi 0) — hizmet satarken süre fiyat kadar belirleyici | Kod | `✗` |
| — | Sepet / ödeme / kupon | Var | Yok | — | `İstisna` — kiralık vitrin kapsamı dışı, bilinçli karar |

## Sayım

| Durum | Adet |
|---|---|
| `✓` kod + kilitleyen test | **0** |
| `△` kısmi | 3 |
| `✗` yok | 7 |
| `İstisna` | 1 |

## Engel türüne göre ayrım

**Kodla çözülür (7):** 1, 4, 6, 7, 8, 9, 10.

**Veri gerektirir, kodla çözülmez (2):**
- **2 — galeri:** ürün başına birden çok fotoğraf yüklenmeli.
- **3 — puan/yorum:** gerçek yorum sistemi kurulmalı. Bugünkü durum yalnız
  eksiklik değil **risk**: 131 vitrinde esnafın kendi yazdığı puan
  gösteriliyordu. 12 Eylül temizliğinden sonra 9 şablon kaldı, ama alan duruyor.
  Ya gerçek yoruma bağlanır ya kapatılır.

## Sapmayı önleyen kural

Bu matrise satır eklemeden veya bir hücreyi `✓` yapmadan önce:

1. Hücrenin kanıtı yazılır — dosya + satır, ya da ölçüm sorgusu.
2. `✓` için **kilitleyen test dosyası adı** yazılır. Adı yoksa `✓` yasak.
3. Yeni bir görünüm işi bu matriste bir satıra karşılık gelmiyorsa
   **süslemedir** ([[gorunum-isi-kiriksa-yapilir]]) — sıraya yazılır, o an
   yapılmaz.

Kilitleyen test: `public_web/tests/vitrin-urun-kalite-matrisi-contract.test.ts`
