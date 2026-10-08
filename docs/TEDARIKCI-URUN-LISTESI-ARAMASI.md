# Tedarikçi toplu ürün listesi araması

**5/16 havuz firması toplu liste/katalog yayımlıyor; 11/16'da yok, Glisa'da da bulunmadı — olmayanlarda ürünleri tek tek sayfalarda + sitemap ile veriyor.**

Tüm erişimler: **2026-10-05**, ücretsiz araçlar (HTTP GET, sayfa başına 1-2 istek).

Kapsam: `_firmalar.json` içindeki 16 havuz firması + ek olarak Glisa/Işilay.

## Tablo

| Firma | Site | Toplu liste var mı | Adres/kanıt (erişim 2026-10-05) | Ne tür | Not |
|---|---|---|---|---|---|
| Alireis Toptan Gıda | alireis.com | hayır | https://alireis.com/sitemap.xml (200, alt harita 6, ürün 3 parça) | sitemap + tek tek sayfa | Kökte katalog/bayi/XML linki yok. Woo mağaza ucu açık: `/wp-json/wc/store/v1/products` 200 |
| Aycenk Gıda | aycenk.com | hayır | https://www.aycenk.com/sitemap.xml (200, ürün 3 parça) | sitemap + tek tek sayfa | Kökte katalog/bayi linki yok. Woo ucu 200 |
| Berrak İçGiyim | berrakicgiyim.com.tr | hayır | https://www.berrakicgiyim.com.tr/xml/sitemap/product.xml (sitemap indeksi 200) | sitemap + tek tek sayfa | Görsel haritası yok. Ürün ucu denemeleri bağlantı kapatıldı (engel) |
| Emek Toptan | emektoptan.com | **evet** | https://www.emektoptan.com/sitemap.xml → `xml/sitemap_image_1..4.xml?sr=…` (200) | **toplu görsel haritası (XML)** + ürün sitemap 4 parça | Veri feed'i/Excel yok; kazanım yalnız görsel linkleri. Woo ucu 200 |
| Erdem İçGiyim | erdemicgiyim.com | hayır | https://www.erdemicgiyim.com/sitemap/products/0.xml … 5.xml | sitemap + tek tek sayfa | `/products.json` ve Woo ucu = 404. Görsel haritası yok |
| İşte Çanta | istecanta.com | **evet** | https://istecanta.com/sitemap_products_1.xml … ve https://istecanta.com/products.json (200) | **toplu JSON (Shopify)** + ürün sitemap 3 parça | Mevcut Shopify okuyucusuyla zaten çekilebilir; ek kazanım küçük |
| Kaya Zeytin | kayazeytin.com.tr | **evet** | https://www.kayazeytin.com.tr/sitemap.xml → `xml/sitemap_image_1.xml?sr=6ac3134f3f338` (200, 34 görsel örneği) | **toplu görsel haritası (XML)** + ürün sitemap | "Toptan Satış Talepleri" sayfası var (https://www.kayazeytin.com.tr/Toptan-Satis-Talepleri,DFO-1.html) ama indirilebilir liste yok. Woo ucu 200 |
| Kinzi Toptan | kinzitoptan.com | hayır | https://kinzitoptan.com/sitemap.xml → products.xml (200) | sitemap + tek tek sayfa | Kökte katalog/bayi linki yok. Mağaza ucu bağlantı kapattı (engel) |
| Koza İçGiyim | kozaicgiyim.com | **evet** | https://www.kozaicgiyim.com/sitemap.xml → 57 adet `xml/sitemap_image_*.xml` (örnek image_14: 201 loc) | **toplu görsel haritası (XML)** + ürün sitemap 2 parça | "Toptan Satış" blog sayfasında indirilebilir liste yok. Woo ucu 200 |
| Kul Gıda | kulgida.com | hayır | https://kulgida.com/product-sitemap.xml (200) | sitemap + tek tek sayfa | Kökte katalog/bayi linki yok. Woo ucu 200 |
| Santral Gıda | santralgida.com | hayır | https://santralgida.com/sitemap.xml (200, ürün 15 parça) | sitemap + tek tek sayfa | **Kök sayfa 403 – erişilemedi**; robots.txt okunuyor. Görsel haritası yok |
| Saphori | saphori.com | hayır | https://saphori.com/pages/kataloglar ("Saphori 2026 Ürün Kataloğu") + https://saphori.com/pages/toptan-b2b | katalog **sayfası** (görsel galerisi) — veri/Excel/PDF yok | İndirilebilir dosya linki bulunamadı; görseller `cdn.myikas.com` üstünde tek tek. products.xml (sitemap) var |
| Seç Salça Konserve | secsalca.com.tr | **evet** | https://www.secsalca.com.tr/sec-salca-katalog/ → https://www.secsalca.com.tr/wp-content/uploads/2022/02/New_Catalog.pdf | **indirilebilir e-Katalog (PDF)** | Ürün verisi (barkod/fiyat) PDF'te mi bilinmiyor; ayrıca ürün sitemap var. Woo ucu 200 |
| Seher Mensucat | sehermensucat.com | hayır | https://sehermensucat.com/sitemap.xml → products.xml (200) | sitemap + tek tek sayfa | Kökte katalog/bayi linki yok. Mağaza ucu bağlantı kapattı (engel). İzin "bekliyor" |
| Toptan İç Giyim Pazarı | toptanicgiyimpazari.com | hayır | https://www.toptanicgiyimpazari.com/product-sitemap.xml (+2, 200) | sitemap + tek tek sayfa | Kökte katalog/bayi linki yok. Woo ucu 200 |
| Voltaj | voltaj.com.tr | hayır | https://www.voltaj.com.tr/xml/sitemap/product.xml (sitemap indeksi 200) | sitemap + tek tek sayfa | Kökte katalog/bayi/XML linki yok; görsel haritası yok. Mağaza ucu bağlantı kapattı (engel) |
| **Glisa / Glisa Collection / Işilay** | — (resmî site yok) | **hayır – bulunamadı** | `isilay.com.tr` → natro "Premium Park Sayfası" (park); `glisatekstil.com` → DNS yok; `glisacollection.com`, `glisa.com.tr` → DNS yok | — | Ücretsiz rehberlerde site linki yok: https://www.bulurum.com/details/27447c3g533d36dg_c36b7_jb5d1c0_2 , https://firmarehberim.com/isilay-glisa-tekstil-zeytinburnu (yalnız telefon/adres). Arama motorları bot engeli nedeniyle sonuç vermedi – kesin "site yok" demiyorum |

## Bulunan toplu listeler

Toplu **veri** listesi (XML/CSV/Excel/JSON feed, bayi kataloğu indir):
- **istecanta.com** — https://istecanta.com/products.json (Shopify toplu JSON, 200)
- **secsalca.com.tr** — https://www.secsalca.com.tr/wp-content/uploads/2022/02/New_Catalog.pdf (e-Katalog PDF)

Toplu **görsel** linki (mevcut tarama hattının ötesinde kazanım):
- **emektoptan.com** — https://www.emektoptan.com/sitemap.xml içinde `xml/sitemap_image_1..4.xml`
- **kayazeytin.com.tr** — https://www.kayazeytin.com.tr/sitemap.xml içinde `xml/sitemap_image_1.xml?sr=6ac3134f3f338`
- **kozaicgiyim.com** — https://www.kozaicgiyim.com/sitemap.xml içinde 57 parça `xml/sitemap_image_*.xml`

Katalog sayfası olan ama dosya/veri vermeyen:
- **saphori.com** — https://saphori.com/pages/kataloglar (görsel galeri), https://saphori.com/pages/toptan-b2b

## Olmayanlar — mevcut tarama yoluyla gidilecek

Kök sayfada katalog/XML/Excel/bayi listesi ilanı **olmayan** firmalar (hepsi ürünlerini tek tek sayfalarda veriyor; erişim 2026-10-05):
alireis.com, aycenk.com, berrakicgiyim.com.tr, erdemicgiyim.com, kinzitoptan.com, kulgida.com, santralgida.com, sehermensucat.com, toptanicgiyimpazari.com, voltaj.com.tr — ve kısmen saphori.com.

Ortak durum:
- 16 firmanın **tamamı** `sitemap.xml` yayımlıyor; 14'ünde ayrı ürün sitemap'i var (yalnızca URL listesi, veri değil).
- Toplu veri ucu denemeleri: Woo mağaza ucu 8 sitede açık (alireis, aycenk, emek, kayazeytin, koza, kulgida, secsalca, toptanicgiyimpazari), erdemicgiyim'de 404, 6 sitede bağlantı engellendi. Bunlar README'deki mevcut hatanın konusu.
- Glisa/Işilay: havuzda da yok, resmî sitesinde toplu liste de yok/erişilemedi.
