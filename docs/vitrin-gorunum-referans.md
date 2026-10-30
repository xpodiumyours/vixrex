# Vitrin görünümü — referans ve kurallar (2026-10-28)

Soru: ürün kartı, açıklama ve düğmelerin görünümü için **nereden öğrenerek**
bu işi tamamlayabiliriz? Bu doküman üç araştırmanın (TR market uygulamaları,
Baymard e-ticaret UX araştırmaları, WhatsApp/Meta rehberleri + koyu tema
kaynakları) sonucudur. Her kuralın yanında kaynağı vardır.

---

## 1. Öğrenme adresleri (öncelik sırasıyla)

1. **Baymard Institute** — kanıta dayalı e-ticaret kullanıcı deneyimi
   araştırmaları; market/gıda için özel araştırma hattı var (2026 güncellemesi:
   70 kullanıcı/site oturumu, 8 site, 650+ saat yeni araştırma).
   <https://baymard.com/research-articles/online-grocery-ecommerce-ux-2026>
2. **Türkiye hızlı market uygulamaları** — Getir, Migros Hemen, Yemeksepeti
   Market (eski Banabi), Trendyol Go, A101 Kapıda, Cepte ŞOK. En güncel gerçek
   referans bunların kendisi; telefonda yan yana bakmak gerekir. Uygulama
   mağazası ekran görüntüleri başlangıç noktası:
   <https://play.google.com/store/apps/details?id=com.getir>
3. **WhatsApp Business resmî rehberi + Meta Business Learn** — sipariş alan
   küçük işletme düzenleri, katalog kuralları, mesaj şablonları:
   <https://whatsappbusiness.com/resources/resource-library/whatsapp-business-app-resources-whatsapp-business-catalog/>
4. **WCAG 2.2 kontrast** (4.5:1) ve **NN/g koyu tema** yazıları — renk ve
   okunabilirlik güvencesi:
   <https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html> ·
   <https://www.nngroup.com/articles/dark-mode-users-issues/>

---

## 2. Kanıtlarla kart anatomisi (Baymard)

Market kullanıcılarının **yalnızca yarısı ürün detay sayfasına giriyor**;
çoğu listeden sepete ekliyor. Bu yüzden kart, karar için gereken bilgiyle
dolu olmalı ve sipariş karttan başlamalıdır.

Kartın sırası (her kartta aynı):

1. **Ürün görseli** — en az 2-3 görsele erişim işareti (varsa)
2. **Ürün adı** — marka + çeşit + miktar; en fazla 3-4 satır
3. **Toplam fiyat + birim fiyat** (₺/kg, ₺/L, ₺/adet) — birim fiyat göstermeyen
   sitelerin oranı benchmark'ta %67-86; gösteren ciddi fark yaratır
4. **Stok / kampanya** — açıkça, düşük kontrastta değil
5. **Ana eylem: "Sepete ekle"** — eklenince aynı yerde **adet seçiciye**
   dönüşür (`− 2 +`); ekleme sonucu kartta görünür ("1 adet sepette" gibi)

Kurallar:

- Benzer kartlarda aynı bilgi aynı sırada; bilgiler görsel olarak ayrık
  (tek metin yığını değil).
- Hızlı bakış (quick view) yalnız listede olmayan **az sayıda kararı**
  göstermeli (etiket/besin, ek görsel, varyant); liste bilgisini tekrar
  etmemeli, sipariş yolunu kapatmamalı.
- Açıklama: her kullanıcı en az bir noktada açıklamaya başvuruyor. Yapı:
  (a) 1-2 cümle somut tanım — ürünü ayırt eden nitelik, (b) başlıklı detay:
  içerik, alerjen, besin/porsiyon, saklama. "Resmî sayfada tanıtılıyor"
  gibi kaynak raporu dili yasak; reklam şişkinliği yasak.
- Stok yoksa sessizce devre dışı bırakma; açık yaz. İkamayı her üründe
  zorunlu kılma (kullanıcıların %76'sı ikame seçiminde zorlanıyor) — sipariş
  genelinde tek tercih yeterli.
- Teslimat bilgisi erken görünmeli (kullanıcıların %64'ü eklemeden önce
  maliyet arıyor): teslimat ücreti/saati/eşiği sepet çevresinde.

Kaynaklar: <https://baymard.com/research-articles/grocery-add-to-cart-buttons> ·
<https://baymard.com/research-articles/price-per-unit> ·
<https://baymard.com/research-articles/product-listing-information> ·
<https://baymard.com/research-articles/list-item-design-ecommerce> ·
<https://baymard.com/research-articles/product-descriptions> ·
<https://baymard.com/research-articles/ecommerce-quick-views> ·
<https://baymard.com/research-articles/handling-out-of-stock-products> ·
<https://baymard.com/research-articles/grocery-substitutions> ·
<https://baymard.com/research-articles/show-shipping-costs-on-product-pages>

---

## 3. TR market uygulamalarından dersler

- **Sepete ekleme kartta:** Banabi/Yemeksepeti Market arama sonucundan direkt
  ekleme yapıyordu; ekleme ikonu adede dönüşüyordu. Migros Hemen "1 adet
  sepette" bildirimiyle ekleme sonucunu görünür kılıyordu.
- **Ekleme akışı bölünmesin:** Getir incelemesi, ekleme anında görünür teyit
  olmamasının kullanıcıyı sepet sayacına bakmaya zorladığını olumsuz not
  ediyor. Adres/üyelik gibi adımlar ekleme sırasında sorulmamalı.
- **Detay sadeliği:** kısa metin + gramaj + fiyat + ekleme. Küçük puntolu,
  başlıksız metin yığını kullanıcıya yük (Migros Hemen incelemesi).
- **Teslimat bilgisi erken:** A101 Kapıda denemesinde teslimat ücreti ve
  saatlerinin sepetten önce görünmemesi eleştirilmiş.
- **Görsel standardı:** Getir, 12.000+ üründe ortak ışık/kadraj/ölçek standardı
  kurmuş. Kart tutarlılığının yolu tek tip fotoğraf alanı.

Kaynak: <https://medium.com/pupahouse/getir-i%CC%87stegelsin-migros-hemen-ve-banabi-uygulamalar%C4%B1nda-sipari%C5%9F-s%C3%BCreci-kullan%C4%B1c%C4%B1-deneyimi-8626278d4295> ·
<https://webrazzi.com/2020/05/05/a101-kapida-eve-teslimat-denedik/>

---

## 4. WhatsApp sipariş akışı (düzen)

Katalog: net fotoğraf, somut ürün adı (marka + çeşit + miktar), fiyat,
güncel stok; olmayan ürün gizlenir. Akış: QR/link → karşılama (açık saat +
teslimat bölgesi) → katalog/sepet → **tek mesajda sipariş özeti** (ürün ×
adet, ara toplam, teslimat ücreti, toplam, tahmini zaman) → müşteri onayı →
durum mesajları. Kaynak:
<https://whatsappbusiness.com/resources/resource-library/ads-that-click-to-whatsapp-smb-guide/>

---

## 5. Koyu tema kuralları

- WCAG AA: normal metin **4.5:1** kontrast; fiyat ve ana eylem asla soluk gri
  değil. Fiyatı yalnız renkle değil, boyut + kalınlık + konumla ayır.
- Beyaz zeminli ürün fotoğrafını **karartma/ters çevirme**; fotoğrafı kontrollü
  bir yüzeyle (ince çerçeve, hafif nötr ton) koyu zemine oturt. Gıdanın gerçek
  rengini koru.
- Ana eylem kartta TEK ve tutarlı vurgu rengiyle; beğeni/paylaş gibi ikincil
  kontroller onunla yarışmasın.

---

## 6. Bugünkü vitrinle fark (neyi değiştiririz)

| # | Bugünkü hâl | Kurala göre olması gereken |
|---|---|---|
| 1 | Kartın ana eylemi "Hızlı incele →"; sipariş pencere içinde | Kartta doğrudan **Sepete ekle**, eklenince `− adet +` |
| 2 | Birim fiyat yok | Her kartta **₺/kg, ₺/L, ₺/adet** |
| 3 | Görseller tutarsız (beyaz kutu + pazarlama görseli yan yana) | Tek tip fotoğraf alanı; fotoğraf karartılmaz, çerçevelenir |
| 4 | Kart çipi "Kakaolu · 60 g · Çikolatalı" tek satır | Ayrık hiyerarşi: ad / miktar / fiyat / stok |
| 5 | Fiyat küçük, "Hızlı incele" fiyatla yarışıyor | Fiyat 2. en belirgin öğe; eylem tek |
| 6 | Beğeni + yorum bloğu sipariş eylemiyle aynı ağırlıkta | İkincil bölüme; sipariş kararını gölgelemesin |
| 7 | Açıklamalar uzun/kaynak raporu dili | 1-2 cümle somut tanım + başlıklı detay (PR #704 preset'i yeni kartlar için düzeltti) |
| 8 | Teslimat/ücret/saat bilgisi yok | Sepet ve sipariş mesajında erken ve açık |
| 9 | Sipariş mesajı ürün listesi | Şablon: ürün × adet, teslimat, saat, stok alternatifi, toplam + teyit |

---

## 7. Önerilen kart spesi (özet)

```
┌──────────────────────────┐
│ [ foto — 4:5, tek tip ]  │  ← %10 indirim rozeti (varsa)
│                          │
├──────────────────────────┤
│ MARKA                    │  küçük, sönük
│ Ürün adı (1-2 satır)     │  kalın, beyaz
│ 1 kg · ₺41,60/kg         │  miktar + birim fiyat
│ 54,60 TL                 │  büyük, belirgin (eski fiyat üstü çizili)
│ ● Mevcut                 │
│ [    Sepete ekle    ]    │  TEK ana eylem → [ − 1 + ]
└──────────────────────────┘
```

Pencere: fotoğraf galerisi + karar bilgileri (marka, gramaj, birim fiyat,
stok) + 1-2 cümle açıklama + **altta sabit "Sepete ekle"**; "WhatsApp'tan
soru" ikincil; beğeni/yorum en altta.
