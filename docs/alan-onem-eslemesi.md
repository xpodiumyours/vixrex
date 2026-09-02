# Alan × İşletme Türü Önem Eşleştirmesi

> **BU DOSYA ELLE DÜZENLENMEZ.** `tool/alan_onem_esleme_uret.py` tarafından
> üretilir — kuralı değiştirmek için önce o script'i güncelle, sonra tekrar
> çalıştır (`python3 tool/alan_onem_esleme_uret.py`). Makine tarafı:
> `docs/alan-onem-eslemesi.json`.

Esnaf danışma isteğinde tarif edilen dört adımlı planın **üçüncü adımı**:
`docs/vitrin-alan-semasi.md` (46 alan Vixrex'te ne işe yarar) ile
`docs/esnaf-bilgi-tabani.md` (19 kategorinin iş-modeli öznitelikleri)
birleşiyor — her kategori için 46 alanın hangisi **temel**, hangisi
**değerli**, hangisi **duruma bağlı**, hangisi **ilgisiz**.

## Önem sınıfları — bu doküman özelinde

Bunlar `docs/vitrin-alan-semasi.md`'deki platform-geneli `zorunlu`/`kalite`/
`isteğe bağlı` sınıflandırmasıyla **aynı şey değil**. O sınıflandırma
"vitrin yayına hazır mı" sorusuna cevap verir ve kategoriden bağımsızdır.
Buradaki dört sınıf "bu işletme türü için bu alanın dolu olması ne kadar
değer yaratır" sorusuna cevap verir ve kategoriye göre değişir — ikisi
kasıtlı olarak ayrışabilir. Örnek: `adres` platformda her zaman zorunludur
(yayın kapısı), ama tamamen uzaktan çalışan bir danışmanlık için işletme
türü açısından yalnız "duruma bağlı" — esnaf doldurur çünkü platform
istiyor, ama dolmaması müşteri deneyimini bozmaz.

| Sınıf | Anlamı |
|---|---|
| **Temel** | Bu işletme türünde boşsa müşteri deneyimi doğrudan bozulur veya vitrin eksik/yanıltıcı görünür. |
| **Değerli** | Boşsa vitrin çalışır ama bu işletme türü için somut bir fırsat kaçar (güven, SEO, dönüşüm). |
| **Duruma bağlı** | İşletmenin kendi tercihine kalmış — bazı işletmeler için işe yarar, bazıları için nötr. |
| **İlgisiz** | Bu işletme türünün iş modeliyle örtüşmüyor; boş kalması beklenir. |

## Yöntem

`docs/esnaf-bilgi-tabani.md`'deki 8 öznitelikten (A fiziksel ziyaret,
B randevu kritikliği, C sunum türü, D güven ağırlığı, E görsel kanıt,
F kampanya eğilimi, G sosyal medya, H içerik/SEO) her alan için bir kural
üretir — 46 alanın 46'sı da `tool/alan_onem_esleme_uret.py` içindeki
`hesapla()` fonksiyonunda tek tek tanımlı. Kural örnekleri:

- `çalışma saatleri` → B'ye bağlı: B=yüksek olan kategoride (kuaför, teknik
  servis, oto/araç, ev temizlik, spor/fitness, sağlık/yaşam, gıda, fırın,
  kafe/lokanta, pet/veteriner) **temel**; B=orta olanlarda (perakende grubu,
  danışmanlık, eğitim) **değerli**.
- `hakkında yazısı` → D'ye bağlı: D=yüksek olan (çoğu hizmet kategorisi)
  **temel**; D=orta (perakende/gıda/spor) **değerli**; D=düşük (kırtasiye)
  **duruma bağlı**.
- `adres`/`harita*`/`enlem`/`boylam`/`yol tarifi` → A'ya bağlı: A=hayır
  (yalnız Ev Temizlik) olduğunda konum alanlarının çoğu **ilgisiz**'e düşer.
- `kampanya bandı` (5 alan) → F'ye bağlı: F=düşük olan Danışmanlık ve
  Sağlık/Yaşam'da **ilgisiz**; perakende/gıda grubunda F=yüksek olduğu için
  **değerli**.

Bu bir **ilk-geçiş sezgisel model** — planın dördüncü adımı (gerçek Vixrex
kullanım verisiyle doğrulama) henüz yapılmadı. Kurallar yanlışsa,
`tool/alan_onem_esleme_uret.py`'deki `hesapla()` veya `docs/esnaf-bilgi-tabani.md`'deki
öznitelik tablosu düzeltilir, script tekrar çalıştırılır — bu dosya elle
yamanmaz.

## 19 kategori + Diğer

### Giyim

*İş modeli: perakende · fiziksel ziyaret: evet · randevu kritikliği: orta · sunum: urun · güven ağırlığı: orta · görsel kanıt: yuksek · kampanya: yuksek · sosyal medya: yuksek · içerik/SEO: dusuk*

- **Temel:** İşletme Adı, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Açık Adres, İl, İlçe, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Mahalle, Harita Kartı Etiketi, Çalışma Saatleri, Instagram Kullanıcı Adı, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı
- **Duruma bağlı:** Telefon, Web Sitesi, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **İlgisiz:** E-posta, Referanslar Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Butik

*İş modeli: perakende · fiziksel ziyaret: evet · randevu kritikliği: orta · sunum: urun · güven ağırlığı: orta · görsel kanıt: yuksek · kampanya: yuksek · sosyal medya: yuksek · içerik/SEO: dusuk*

- **Temel:** İşletme Adı, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Açık Adres, İl, İlçe, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Mahalle, Harita Kartı Etiketi, Çalışma Saatleri, Instagram Kullanıcı Adı, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı
- **Duruma bağlı:** Telefon, Web Sitesi, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **İlgisiz:** E-posta, Referanslar Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Gıda

*İş modeli: gida · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: urun · güven ağırlığı: orta · görsel kanıt: orta · kampanya: yuksek · sosyal medya: orta · içerik/SEO: dusuk*

- **Temel:** İşletme Adı, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Telefon, Mahalle, Harita Kartı Etiketi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı, Değerlendirme Puanını Göster
- **Duruma bağlı:** Instagram Kullanıcı Adı, Web Sitesi, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması
- **İlgisiz:** E-posta, Referanslar Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Fırın

*İş modeli: gida · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: urun · güven ağırlığı: orta · görsel kanıt: orta · kampanya: yuksek · sosyal medya: orta · içerik/SEO: dusuk*

- **Temel:** İşletme Adı, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Telefon, Mahalle, Harita Kartı Etiketi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı, Değerlendirme Puanını Göster
- **Duruma bağlı:** Instagram Kullanıcı Adı, Web Sitesi, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması
- **İlgisiz:** E-posta, Referanslar Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Kozmetik

*İş modeli: perakende · fiziksel ziyaret: evet · randevu kritikliği: orta · sunum: urun · güven ağırlığı: orta · görsel kanıt: yuksek · kampanya: yuksek · sosyal medya: yuksek · içerik/SEO: orta*

- **Temel:** İşletme Adı, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Açık Adres, İl, İlçe, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Mahalle, Harita Kartı Etiketi, Çalışma Saatleri, Instagram Kullanıcı Adı, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı
- **Duruma bağlı:** Telefon, Web Sitesi, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Blog Üst Başlık, Blog Bölüm Başlığı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **İlgisiz:** E-posta, Referanslar Bağlantısı

### Dekorasyon

*İş modeli: perakende · fiziksel ziyaret: evet · randevu kritikliği: orta · sunum: urun · güven ağırlığı: orta · görsel kanıt: yuksek · kampanya: orta · sosyal medya: yuksek · içerik/SEO: orta*

- **Temel:** İşletme Adı, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Açık Adres, İl, İlçe, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Mahalle, Harita Kartı Etiketi, Çalışma Saatleri, Instagram Kullanıcı Adı, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Hakkımızda Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı
- **Duruma bağlı:** Telefon, Web Sitesi, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Blog Üst Başlık, Blog Bölüm Başlığı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **İlgisiz:** E-posta, Referanslar Bağlantısı

### Elektronik

*İş modeli: perakende · fiziksel ziyaret: evet · randevu kritikliği: orta · sunum: urun · güven ağırlığı: orta · görsel kanıt: dusuk · kampanya: yuksek · sosyal medya: dusuk · içerik/SEO: orta*

- **Temel:** İşletme Adı, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Mahalle, Harita Kartı Etiketi, Çalışma Saatleri, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı
- **Duruma bağlı:** Telefon, Instagram Kullanıcı Adı, Web Sitesi, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Blog Üst Başlık, Blog Bölüm Başlığı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **İlgisiz:** E-posta, Referanslar Bağlantısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı

### Kırtasiye

*İş modeli: perakende · fiziksel ziyaret: evet · randevu kritikliği: orta · sunum: urun · güven ağırlığı: dusuk · görsel kanıt: dusuk · kampanya: orta · sosyal medya: dusuk · içerik/SEO: dusuk*

- **Temel:** İşletme Adı, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Mahalle, Harita Kartı Etiketi, Çalışma Saatleri, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı
- **Duruma bağlı:** Telefon, Instagram Kullanıcı Adı, Web Sitesi, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Başlığı, Hakkımızda Yazısı, Hakkımızda Görseli, Görsel Alt Yazısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **İlgisiz:** E-posta, Hakkımızda Üst Başlık, Referanslar Bağlantısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Kafe / Lokanta

*İş modeli: gida · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: menu · güven ağırlığı: orta · görsel kanıt: yuksek · kampanya: yuksek · sosyal medya: yuksek · içerik/SEO: orta*

- **Temel:** İşletme Adı, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Ürün Bölümü Başlığı
- **Değerli:** Hero Rozet Metni, Kısa Tanıtım, Hero Konum Metni, İşletme Türü, Logo, Telefon, Mahalle, Harita Kartı Etiketi, Instagram Kullanıcı Adı, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, Değerlendirme Puanını Göster
- **Duruma bağlı:** Web Sitesi, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Blog Üst Başlık, Blog Bölüm Başlığı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması
- **İlgisiz:** E-posta, Referanslar Bağlantısı

### Kuaför

*İş modeli: hizmet · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: hizmet · güven ağırlığı: yuksek · görsel kanıt: yuksek · kampanya: orta · sosyal medya: yuksek · içerik/SEO: dusuk*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, Hero Konum Metni, İşletme Türü, Logo, Telefon, Mahalle, Harita Kartı Etiketi, Instagram Kullanıcı Adı, Web Sitesi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** E-posta, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Görsel Alt Yazısı
- **İlgisiz:** Blog Üst Başlık, Blog Bölüm Başlığı

### Teknik Servis

*İş modeli: hizmet · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: hizmet · güven ağırlığı: yuksek · görsel kanıt: orta · kampanya: orta · sosyal medya: dusuk · içerik/SEO: orta*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Telefon, Mahalle, Harita Kartı Etiketi, Web Sitesi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** E-posta, Instagram Kullanıcı Adı, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Görsel Alt Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Danışmanlık

*İş modeli: hizmet · fiziksel ziyaret: kismen · randevu kritikliği: orta · sunum: hizmet · güven ağırlığı: yuksek · görsel kanıt: dusuk · kampanya: dusuk · sosyal medya: dusuk · içerik/SEO: yuksek*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, WhatsApp Numarası, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, İşletme Türü, Logo, Kapak / Hero Görseli, İl, İlçe, Çalışma Saatleri, Web Sitesi, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** Hero Konum Metni, Telefon, E-posta, Açık Adres, Mahalle, Instagram Kullanıcı Adı, Kategori Bölümü Başlığı, Hakkımızda Üst Başlık, Görsel Alt Yazısı
- **İlgisiz:** Harita Kartı Etiketi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı

### Eğitim

*İş modeli: hizmet · fiziksel ziyaret: kismen · randevu kritikliği: orta · sunum: ders · güven ağırlığı: yuksek · görsel kanıt: dusuk · kampanya: orta · sosyal medya: orta · içerik/SEO: yuksek*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, WhatsApp Numarası, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, İşletme Türü, Logo, Kapak / Hero Görseli, İl, İlçe, Çalışma Saatleri, Web Sitesi, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** Hero Konum Metni, Telefon, E-posta, Açık Adres, Mahalle, Instagram Kullanıcı Adı, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Görsel Alt Yazısı
- **İlgisiz:** Harita Kartı Etiketi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı

### Ev Temizlik

*İş modeli: hizmet · fiziksel ziyaret: hayir · randevu kritikliği: yuksek · sunum: hizmet · güven ağırlığı: yuksek · görsel kanıt: yuksek · kampanya: orta · sosyal medya: dusuk · içerik/SEO: dusuk*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Çalışma Saatleri, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, İşletme Türü, Logo, Telefon, İl, İlçe, Web Sitesi, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** E-posta, Açık Adres, Mahalle, Instagram Kullanıcı Adı, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Görsel Alt Yazısı
- **İlgisiz:** Hero Konum Metni, Harita Kartı Etiketi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Blog Üst Başlık, Blog Bölüm Başlığı

### Spor / Fitness

*İş modeli: hizmet · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: hizmet · güven ağırlığı: orta · görsel kanıt: orta · kampanya: yuksek · sosyal medya: yuksek · içerik/SEO: orta*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri
- **Değerli:** Hero Rozet Metni, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Telefon, Mahalle, Harita Kartı Etiketi, Instagram Kullanıcı Adı, Web Sitesi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Ürün Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Yazısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** E-posta, Kategori Bölümü Başlığı, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Referanslar Bağlantısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Pet / Veteriner

*İş modeli: perakende · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: karma · güven ağırlığı: yuksek · görsel kanıt: orta · kampanya: orta · sosyal medya: orta · içerik/SEO: orta*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Telefon, Mahalle, Harita Kartı Etiketi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Kategori Bölümü Başlığı, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** E-posta, Instagram Kullanıcı Adı, Web Sitesi, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Görsel Alt Yazısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Sağlık / Yaşam

*İş modeli: hizmet · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: hizmet · güven ağırlığı: yuksek · görsel kanıt: dusuk · kampanya: dusuk · sosyal medya: dusuk · içerik/SEO: yuksek*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, Hero Konum Metni, İşletme Türü, Logo, Kapak / Hero Görseli, Telefon, Mahalle, Harita Kartı Etiketi, Web Sitesi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** E-posta, Instagram Kullanıcı Adı, Kategori Bölümü Başlığı, Hakkımızda Üst Başlık, Görsel Alt Yazısı
- **İlgisiz:** Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı

### Oto / Araç

*İş modeli: hizmet · fiziksel ziyaret: evet · randevu kritikliği: yuksek · sunum: hizmet · güven ağırlığı: yuksek · görsel kanıt: yuksek · kampanya: orta · sosyal medya: dusuk · içerik/SEO: orta*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, Kapak / Hero Görseli, WhatsApp Numarası, Açık Adres, İl, İlçe, Çalışma Saatleri, Hakkımızda Yazısı
- **Değerli:** Hero Rozet Metni, Hero Konum Metni, İşletme Türü, Logo, Telefon, Mahalle, Harita Kartı Etiketi, Web Sitesi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster, Ürün Bölümü Başlığı, Hakkımızda Başlığı, Hakkımızda Görseli, Referanslar Bağlantısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması, Değerlendirme Puanını Göster
- **Duruma bağlı:** E-posta, Instagram Kullanıcı Adı, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Görsel Alt Yazısı, Blog Üst Başlık, Blog Bölüm Başlığı

### Diğer

*İş modeli: diger · fiziksel ziyaret: kismen · randevu kritikliği: orta · sunum: hizmet · güven ağırlığı: orta · görsel kanıt: orta · kampanya: orta · sosyal medya: orta · içerik/SEO: orta*

- **Temel:** İşletme Adı, Kısa Tanıtım, İşletme Kategorisi, WhatsApp Numarası
- **Değerli:** Hero Rozet Metni, İşletme Türü, Logo, Kapak / Hero Görseli, İl, İlçe, Çalışma Saatleri, Web Sitesi, Ürün Bölümü Başlığı, Hakkımızda Yazısı, SSS Üst Başlık, SSS Bölüm Başlığı, SSS Bölüm Açıklaması
- **Duruma bağlı:** Hero Konum Metni, Telefon, E-posta, Açık Adres, Mahalle, Instagram Kullanıcı Adı, Kategori Bölümü Başlığı, Kampanya Etiketi, Kampanya Başlığı, Kampanya Açıklaması, Kampanya Görseli, Kampanya Fiyat Metni, Hakkımızda Üst Başlık, Hakkımızda Başlığı, Hakkımızda Görseli, Görsel Alt Yazısı, Referanslar Bağlantısı, Galeri Üst Başlık, Galeri Başlığı, Galeri Buton Metni, Galeri Buton Bağlantısı, Blog Üst Başlık, Blog Bölüm Başlığı, Değerlendirme Puanını Göster
- **İlgisiz:** Harita Kartı Etiketi, Google İşletme / Harita Bağlantısı, Konum — Enlem, Konum — Boylam, Yol Tarifi Butonunu Göster

