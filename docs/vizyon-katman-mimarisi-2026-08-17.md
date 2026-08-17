# VixRex — Vizyon: Katman Mimarisi (2026-08-17)

> Bu not, Casper'ın ürün vizyonunu tek yerde tutar — teknik detaylara dalıp
> unutulmasın diye. Aktif iş planı GitHub Issues'tadır; bu belge **yön** ve
> **kararlar** içindir, iş listesi değildir.

## Tek taban fikri

VixRex'in tüm gelecek ürünleri **tek tabanın katmanlarıdır**: VİTRİN.

```
        ┌─────────────────────────────────────┐
        │  B2B — toptan sipariş / tedarik      │  ← en üst katman
        ├─────────────────────────────────────┤
        │  Kurye / Teslimat — lojistik         │
        ├─────────────────────────────────────┤
        │  Al-Sat — müşteri siparişi           │
        ├─────────────────────────────────────┤
        │  VİTRİN — ürün + konum + iletişim    │  ← taban (zaten var)
        └─────────────────────────────────────┘
```

Kural: **vitrin değişmez**; değişen, müşteri "Satın al"a bastıktan sonra
ne olacağıdır. Her katman bir öncekini **kullanır, baştan yazılmaz**.
Dört ayrı ürün değil — **tek ürünün dört modu**.

## Katmanlar

| # | Katman | Ne yapar | Hangi veriyi üretir |
|---|---|---|---|
| 1 | **Kiralama** (şu an) | Hazır vitrin + 14 gün deneme + aylık 299 TL premium | gelir, esnaf ağı |
| 2 | **Al-Sat** | Vitrinden sipariş akışı (müşteri ürünü görür, ister) | sipariş verisi |
| 3 | **Kurye / Teslimat** | Siparişin lojistiği — kurye eşleştirme | teslimat verisi |
| 4 | **B2B** | Esnafın tedarikçisiyle sipariş (aynı vitrin, toptan mod) | toptan sipariş |

**Önemli gözlem (2026-08-17):** vitrinin içeriği zaten web sitesi
seviyesinde (hakkında, galeri, blog, SSS, ürün, harita, iletişim). "B2B
seviyesinde vitrin" için eksik olan içerik değil, **işlem katmanıdır**
(sipariş). Bu yüzden satış/B2B vitrin gelişimi ile kurye teslimat fikri
**aynı başlangıç noktasıdır** — ikisi de aynı içerik-tamam vitrine işlem
ekler.

## Kurye / Teslimat fikri (2026-08-17)

- **Büyüme sezgisi:** Kuryeler zaten Telegram kanallarında. Ayrı uygulama
  yapıp indirme beklemek yerine, ilanları **Telegram botuyla kanallara
  iletmek** — sıfır indirme eşiği, hazır ağda büyüme.
- **Açık kaynak mantığı:** Çekirdek eşleştirme mantığını açık kaynak
  yapmak (her şehir kendi kurabilsin) güven + kanallarda hızlı yayılma
  sağlar; pazar ağı (esnaf + kurye + vitrinler) VixRex'te kalır.
  Dikkat: kopyalanabilir, destek yükü gelir — ama yerel teslimatta
  **ağ kazanır, kod değil**.
- **Sıra:** Al-Sat'tan siparişler gerçekten akmaya başlayınca devreye
  girer. Önce kanal/bot ile talep doğrulanır, sonra ayrı uygulama.

## Tüketici uygulaması vizyonu (kuzey yıldızı)

Uygulama tutarsa: **Google Lens tarzı bir tüketici uygulaması** — ürün
aranır, **en yakın konumda** bulunur. Bu vizyonun gerektirdiği veri zinciri:

```
ürün → onu satan vitrin → vitrinin koordinatı
```

Bu zincir bugün doğru kurulursa, tüketici uygulaması "yeni bir arama
katmanı eklemek" olur — veriyi baştan kurmak değil.

## Konum kuralı (karar, 2026-08-17)

> **Bir ürünün konumu = onu satan vitrinin konumu.** Esnaf hiçbir şey
> yazmaz; sistem otomatik eşleştirir, başka seçenek yok.

Gerekçe:
1. **Sürtünme veriyi öldürür** — esnafa "her ürüne konum gir" dersen
   çoğu girmeyi bırakır → boş veri → ne SEO ne tüketici uygulaması çalışır.
   Otomatik eşleştirme %100 doluluk garantiler.
2. **Tek kaynak, çelişki yok** — konum vitrinde bir kez tutulur, ürün
   ondan türetilir.
3. **Esnafın gerçeği** — kuaför, kafe, butik, teknik servis tek konumludur.
   Çok şubeli/tedarik esnaf ihtiyacı gelince ayrıca çözülür (kolay).

Teslimat yapan esnaf için de mağaza konumu yeterlidir ("nereden geliyor"
bilgisi); teslimat kapsamı/rota konusu sonraya bırakılır (Casper onayı, 2026-08-17).

## Sıralama kuralı

```
Şimdi:  vitrinler + kiralama + Google görünürlüğü   (ilk gelir)
Sonra:  Al-Sat akışı                                 (sipariş verisi)
Sonra:  Kurye teslimat                               (kanallarda büyüme)
En son: B2B                                          (esnafın web sitesi)
```

Her aşama **veriyle** karar verilir: kiralama patladı mı → al-sat;
siparişler geldi mi → kurye. Hayalle değil, sayıyla.

## Rekabet notu (Casper'ın görüşü, 2026-08-17)

Yapı kopyalanabilir ve devler karşısında avantaj sınırlıdır; ancak
kopyalanması zor olanlar: **içerik birikimi** (100 vitrinlik katalog),
**mikro esnaf odağı** (devlerin umursamadığı kesim) ve **hız** (tek karar
verici). Yol değerlidir; güvenlikli ve adım adım ilerlenir.

## Bağlantılar

- [[Vixrex Baslangic]] — proje haritası (yol satırı buraya bağlanır)
- [[google-gorunurluk]] — konum kuralının SEO ayağı
- [[VIXREX_RULES]] — değişmez kurallar
- [[vixrex-paytr-abonelik-odeme-2026-08-17]] — katman 1'in ödeme altyapısı
