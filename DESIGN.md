# VIXREX TASARIM ANAYASASI (`DESIGN.md`)

> **Durum:** Kilitli (Kurucu Kararı — 22 Kasım 2026)  
> **Kapsam:** `vixrex.com` karşılama, `/kesfet`, `/giris`, `/app` (Esnaf Paneli), `/v/[slug]` (Dijital Vitrin), `/izin-talebi/[token]` (Üretici Onay Portalı) ve Flutter mobil uygulaması.  
> **Bağlayıcılık:** Bu dosya Vixrex'in görsel ve arayüz anayasasıdır. Hiçbir yapay zeka ajanı veya geliştirici, kurucunun açık onayı olmadan buradaki 6 çekirdek kararı, renk tokenlarını, logo kaynağını veya yasaklar listesini değiştiremez.

---

## 1. Kurucu Tarafından Kilitlenen 6 Çekirdek Tasarım Kararı

1. **Tek Marka Mavisi (`#147DFF`) Her Yerde:** Karşılama, Keşfet, Esnaf Paneli ve Dijital Vitrin arasında renk bölünmesi yoktur. Tüm birincil butonlar, aktif durumlar, bağlantılar ve marka parıltıları tek ana mavi **`#147DFF`** üzerinden çalışır. Eski `#38A0E4` vitrin mavisi ve `rgba(56, 160, 228, ...)` gölgeleri yeni kodda kullanılmaz ve kademeli olarak `#147DFF` ailesine taşınır.
2. **Koyu Lacivert Vitrin ve Panel (Varsayılan ve Tek Tema):** Dijital vitrin (`/v/[slug]`) ve esnaf paneli (`/app`) koyu lacivert tasarım dilini korur (`#050B1A` / `#08132D` / `#0B1730`). Beyaz arka planlı klasik e-ticaret temasına geçilmez.
3. **Tek Resmi Logo — Orijinal Kristal V Maskot + `Vixrex`:** Canlı karşılama ekranının sağ altında duran orijinal kristal V maskotu tek resmi görsel kaynaktır. Tüm sayfalarda (Karşılama, Keşfet, Giriş, Panel, Vitrin, Üretici Portalı) yalnızca bu maskot ve yanında `Vixrex` marka yazısı kullanılır.
4. **Ürün Kartı Birincil Aksiyonu — "Bugün Rafta Ayırt" + "WhatsApp'tan Sor" Önde:** Vixrex bir kargo pazaryeri değil, mahalle esnafının dijital vitrinidir. Ürün kartı ve ürün detayında birincil aksiyonlar sırasıyla **`Bugün Rafta Ayırt`** (Adıma Ayırt) ve **`WhatsApp'tan Sor`** butonlarıdır; sepet/listeye ekleme ikincil aksiyon olarak kalır.
5. **Üstte %50 Geniş Resmi Marka Rafı (Üretici ↔ Esnaf Köprüsü):** Faturayla doğrulanmış ve üretici izni/kataloğu bağlı markalar (ör. Alize, İzeltaş), vitrinin üst bölümünde mağaza kimliğinin hemen altında, standart ürün raflarına göre **%50 daha geniş** özel **"Resmi Katalogdan Doğrulanmış"** rafı olarak öne çıkarılır. Mağazanın diğer ürünleri bu rafın altında standart ızgarada listelenir.
6. **Görsel Atmosfer — Hafif Canlı Mavi Vurgulu Modern:** Mevcut Vixrex panelindeki temiz, koyu lacivert ve hafif canlı mavi vurgulu modern çizgi korunur. Kontrolsüz neon, çok renkli gökkuşağı gradyanları veya aşırı parlak animasyonlar yasaktır.

---

## 2. Resmi Logo ve Maskot Kaynağı (Tek Doğru Kaynak)

Depodaki logo karmaşasını bitirmek için tüm arayüzler **yalnızca** aşağıdaki resmi dosyayı ve bileşeni kullanır:

| Kullanım | Resmi Yol / Bileşen | Açıklama |
| :--- | :--- | :--- |
| **Web Bileşeni (Zorunlu)** | `public_web/src/app/v/[slug]/components/VixrexAvatar.tsx` | Tüm web yüzeylerinde tek giriş noktası (`<VixrexAvatar />`). |
| **Web Görsel Dosyası** | `public_web/public/images/vixrex_v_crystal_mascot.webp` | Canlı karşılama ekranı sağ alt (`MascotFab.tsx`) ve `VixrexAvatar` tarafından kullanılan orijinal kristal V maskotu. |
| **Yüksek Çözünürlük PNG (Web + Flutter)** | `public_web/public/vixrex_v_crystal_mascot.png` ve `assets/images/vixrex_v_crystal_mascot.png` | İki platform arasında bayt eşitliği korunan ana PNG kaynağı. |

### Logo Temizlik Kuralları
- **Kullanımı Yasak / Temizlenecek Eski Dosyalar:** `public_web/public/images/vixrex_maskot_ikon.png`, `assets/images/vixrex_maskot_ikon.png`, `assets/images/vixrex_mascot.webp` ve farklı sayfalardaki el çizimi / düz SVG "V" logoları yeni bileşenlerde kullanılmaz.
- **Parıltı Rengi Güncellemesi:** `VixrexAvatar.tsx` içindeki `rgba(56,160,228,...)` parıltı değerleri `#147DFF` (`rgba(20,125,255,...)`) olarak hizalanır.
- **Üst Menü (Header) Kuralı:** Karşılama, `/kesfet`, `/giris`, `/app` ve `/v/[slug]` üst çubuğunda her zaman `<VixrexAvatar />` + **`Vixrex`** birlikte yer alır; farklı sayfalarda farklı logo görünemez.

---

## 3. Renk Sistemi (`shared/renkler.json` Tek Kaynak)

Tüm renkler `shared/renkler.json` dosyasından türetilir; bileşen içine serbest hex kodu gömülmez.

| Token | Hex Kodu | Kullanım Alanı |
| :--- | :--- | :--- |
| `primary` (`--color-lp-primary`) | `#147DFF` | Tek ana marka mavisi: birincil butonlar, aktif sekmeler, bağlantılar, odak halkası, maskot vurgusu |
| `secondary` (`--color-lp-secondary`) | `#57B7FF` | İkincil mavi vurgu, rozet kenarlıkları, hafif hover vurgusu |
| `onPrimary` | `#06152F` | Parlak mavi/açık vurgulu zemin üzerindeki koyu metin |
| `bgEditor` | `#050B1A` | Ana sayfa ve koyu vitrin arka planı |
| `bgLight` | `#08132D` | İkincil bölüm arka planı |
| `surface` | `#0B1730` | Ürün kartı, panel kartı ve modal yüzeyi |
| `surfaceSoft` | `#112448` | Kart içi ikincil kutu, arama alanı, hover yüzeyi |
| `turquoiseSurface` | `#102B59` | Seçili filtre, öne çıkan bilgi bandı, resmi marka rafı vurgusu |
| `border` | `#294D88` | Kart kenarlığı, ayırıcı çizgiler |
| `text` | `#F7FBFF` | Ana başlık ve birincil metin |
| `textAlt` | `#D9E7FF` | Açıklama metni ve ikincil başlıklar |
| `muted` | `#A9BBDA` | Yardımcı etiketler, meta bilgiler |
| `mint` | `#10B981` | Doğrulanmış marka / stokta / onaylandı rozeti ve WhatsApp uyumlu başarı durumu |
| `pink` (vurgu moru) | `#8B5CF6` | Yalnızca özel yapay zeka / asistan rozeti gibi ikincil işaretler (ana buton rengi olamaz) |

### Kontrast ve Fotoğraf Kuralı
- **WCAG AA Zorunluluğu:** Koyu zemin üzerindeki tüm okunabilir gövde metinlerinde minimum **4.5:1** kontrast sağlanır.
- **Beyaz Zeminli Ürün Fotoğrafları:** Üretici kataloglarından gelen beyaz arka planlı ürün fotoğrafları asla ters çevrilmez (`invert`) veya karartılmaz; yuvarlatılmış, temiz ve kontrollü bir çerçeve içinde doğal renkleriyle sunulur.
- **Kaydırma Çubukları (Scrollbar):** Koyu temada sistemin parlak beyaz/gri kaydırma çubuğu bırakılmaz; koyu lacivert zeminle uyumlu ince mavi kaydırma çubuğu kullanılır.

---

## 4. Tipografi ve Dil Kuralları

- **Ana Yazı Tipi:** `Outfit` (yerel `woff2`, ağırlıklar `300`–`900`, `public_web/src/app/layout.tsx` üzerinden yüklü).
- **Vitrin Gösterim Yazı Tipi:** `Instrument Serif` (`--font-vitrin-display-src`, yalnızca seçili vitrin başlık vurgularında).
- **Esnaf Dostu Türkçe Zorunluluğu:** Arayüzde geliştirici veya veritabanı jargonu bulunamaz.
  - Yanlış: `Konum — Enlem`, `Konum — Boylam`, `Görsel Alt Yazısı`, `in_stock`, `54,6 TL`, `SKU_ID`.
  - Doğru: `Mağaza Konumu`, `Fotoğraf Açıklaması`, `Rafta Var`, `54,60 ₺`, `Ürün Kodu`.
- **Fiyat Biçimi:** Türkiye standardında iki kuruş basamağı ve `₺` simgesiyle gösterilir (ör. `145,00 ₺`, `54,60 ₺`).

---

## 5. Yerleşim, Ekran Boyutları ve Bileşen Standartları

### 5.1. Üç Sabit Ekran Ölçüsü (Sıfır Taşma)
Her sayfa ve bileşen aşağıdaki üç genişlikte yatay taşma (`overflow-x = 0`) ve metin kırpılması olmadan çalışır:
- **Mobil:** `390 px`
- **Tablet:** `768 px`
- **Masaüstü:** `1280 px`

### 5.2. Dijital Vitrin Sayfası (`/v/[slug]`) Hiyerarşisi
1. **Mağaza Kimliği (Üst Bant):** Dükkan adı, gerçek konumu, açık/kapalı durumu, tek tıkla WhatsApp ve yol tarifi. (`vixrex.com/v//v/` gibi çift yol veya `0 fotoğraf` gibi kırık sayaçlar yasaktır.)
2. **Resmi Marka Rafı (Üstte %50 Geniş):** Faturayla doğrulanmış üretici markaları (ör. Alize) bu bölümde standart raflara göre **%50 daha geniş** kart/raf düzeniyle, **`Resmi Katalogdan Doğrulanmış`** rozetiyle en üstte sergilenir.
3. **Diğer Mağaza Ürünleri (Alt Izgara):** Esnafın kendi eklediği veya diğer markalara ait ürünler temiz ızgara düzeninde listelenir.

### 5.3. Ürün Kartı Anatomisi ve Görsel Kalite Standardı
- **Tek Ürün = Tek Kart:** Aynı marka + normalize ürün adı + adet + varyant imzasına sahip kayıtlar tek kartta birleşir (`ayniUrunMu`); farklı barkoda (GTIN) sahip iki ürün asla birleştirilmez.
- **Görsel Çözünürlük Tabanı:** `shared/product_image_policy.json` uyarınca ürün görselinin kısa kenarı **en az `1200 px`** olmalıdır. Mobil `390 px` ekranda 2x kart görseli en az `326×408 px` netliğinde sunulur.
- **Telif Kilitli Ürünler:** Üretici onayı bekleyen ürünlerde dev boş gri/siyah kutular gösterilmez; kompakt, temiz bilgi satırı ve tek tıkla üretici onay akışı bağlantısı sunulur.
- **Kart Aksiyon Sırası:**
  1. **`Bugün Rafta Ayırt`** (birincil `#147DFF` buton)
  2. **`WhatsApp'tan Sor`** (ikincil yeşil/kontrastlı hızlı erişim)
  3. Detay / sepet aksiyonu (ikincil)

### 5.4. Hızlı İnceleme (`ProductQuickView`) ve Panel Üst Çubuğu
- **Hızlı İnceleme Modalı:** Kapatma (`×`) düğmesi yalnızca sağ üst köşede ve içeriğe binmeden durur. Yüklenmemiş veya tek görselli ürünlerde boş siyah küçük resim (thumbnail) kutuları çizilmez.
- **Panel Üst Ölçüm Hapı (`OwnerGoogleOlcumHapi.tsx`):** Yalnızca gerçek Google Analytics 4 Data API verisini (son 7 gün) gösterir; veri yoksa tahmin veya sahte sayı üretilmez.

---

## 6. Kesin Yasaklar (Vibe-Coding ve Eski MVP Kalıntıları)

Aşağıdaki hataların herhangi biri görüldüğünde PR kabul edilmez ve canlıya alınmaz:

1. **Üç Farklı Logo:** Karşılama, `/kesfet`, `/giris` ve `/app` arasında farklı logo/ikon kullanmak.
2. **Çift Mavi Çatışması:** Panelde `#147DFF`, vitrinde `#38A0E4` gibi iki farklı ana mavi kullanmak.
3. **Sahte Sosyal Kanıt:** Gerçek veriye dayanmayan `4.9 (128 değerlendirme)` gibi uydurma puan veya yorum sayıları göstermek.
4. **Çift Arama Kutusu / Çift `×`:** `/kesfet` veya vitrin arama alanında üst üste binen çift arama kutusu veya çift temizleme (`×`) düğmesi.
5. **Canlıda Test Mağazaları:** `/kesfet` gibi halka açık listelerde `Deneme2222`, `sssss`, `test` gibi geliştirici kayıtlarını göstermek.
6. **Geliştirici Jargonu ve Ham Kod Metni:** Arayüzde `Enlem/Boylam`, `in_stock`, `null`, `undefined`, ham İngilizce durum kodları veya tek ondalıklı fiyat (`54,6 TL`) bırakmak.
7. **Kırık Modal ve Boş Küçük Resimler:** Sola taşan `×` butonu veya boş siyah thumbnail kareleri.
8. **Kontrolsüz Gradyan / Beyaz Vitrin:** Koyu lacivert kimliği bozan beyaz vitrin zeminleri veya çok renkli neon efektler.

---

## 7. Otomatik Doğrulama ve Kalite Kapıları

Her arayüz değişikliğinde aşağıdaki kapılar geçilmeden PR birleştirilmez:

- **Başlangıç Kontrolü:** `node tool/baslangic-kontrol.mjs` (depo anayasası ve `DESIGN.md` uyumu)
- **Vitrin Kart Kalite Denetçisi:** `node tool/kart-kalite.js https://vixrex.com/v/<vitrin>` (çift kart, düşük çözünürlüklü görsel, kategori tekrarı, yatay taşma ve kırpılan metin kontrolü; hata varsa çıkış kodu `1` döner)
- **Görsel Referans Güncelleme:** Kasıtlı tasarım değişikliği sonrası `.github/workflows/gorsel-referans-yenile.yml` ile ekran görüntüsü referansları güncellenir.
