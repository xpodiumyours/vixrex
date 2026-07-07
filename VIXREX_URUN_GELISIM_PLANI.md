# VixRex Ürün Yönetimi Gelişim Planı
> Ürün yükleme hızı ve rakip analizine dayalı geliştirme yol haritası
> Tarih: 2026-07-07

---

## 1. Mevcut Durum Analizi

### Ürün Yükleme Akışı (Şu An)
```
Ürün Yönetimi Sayfası → Yeni Ürün Ekle → Form Doldur → Kaydet → Yerel Depolama → Yayınla → Supabase
```

### Sorunlar
| Sorun | Etki | Çözüm |
|---|---|---|
| Tek tek ürün ekleme | Yavaş (10 ürün = 10 form) | Toplu yükleme |
| Fatura/ürün fotoğrafından çıkarma | Yok | OCR entegrasyonu |
| Barkod ile ekleme | Yok | Barkod tarama |
| Ürün variesyonu | Yok (beden, renk) | Çoklu varyasyon |
| Görsel optimizasyon | Manuel | Otomatik sıkıştırma |
| SEO Optimizasyonu | Yok | Otomatik başlık/açıklama |

---

## 2. Rakip Karşılaştırması

### Trendyol Ürün Yükleme
```
1. Excel şablonu indir
2. Ürünleri doldur
3. Yükle → Otomatik doğrulama
4. Görselleri toplu yükle
5. Barkod ile eşleştir
6. Fiyat/rekabet analizi
7. Yayınla
```

### VixRex İçin Önerilen Akış
```
1. Hızlı ekleme (tek tıklama)
2. Çoklu yöntem seçimi:
   a. Manuel form
   b. Fotoğraftan OCR
   c. Faturadan çıkarma
   d. Barkod tarama
   e. Toplu Excel yükleme
3. Otomatik optimizasyon
4. SEO önerileri
5. Yayınla
```

---

## 3. Gelişim Planı

### Aşama 1: Hızlı Ürün Ekleme (1-2 Hafta)

#### UI Tasarımı
```
┌─────────────────────────────────────────┐
│  Ürün Yönetimi                          │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ 📝      │ │ 📷      │ │ 📄      │  │
│  │ Manuel   │ │ Fotoğraf│ │ Fatura  │  │
│  │ Ekle     │ │ Çıkar   │ │ Çıkar   │  │
│  └─────────┘ └─────────┘ └─────────┘  │
│  ┌─────────┐ ┌─────────┐              │
│  │ 📊      │ │ 🏷️      │              │
│  │ Barkod  │ │ Toplu   │              │
│  │ Tarama  │ │ Yükle   │              │
│  └─────────┘ └─────────┘              │
├─────────────────────────────────────────┤
│  Mevcut Ürünler (4)        [Ürünleri Yönet] │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐     │
│  │ 🖼️  │ │ 🖼️  │ │ 🖼️  │ │ 🖼️  │     │
│  │fff  │ │ddd2 │ │xxxx │ │ Yeni│     │
│  └─────┘ └─────┘ └─────┘ └─────┘     │
└─────────────────────────────────────────┘
```

#### Yapılacaklar
- [ ] Ürün ekleme butonlarını yeniden tasarla
- [ ] Hızlı ekleme modal'ı oluştur
- [ ] Her yöntem için ayrı wizard
- [ ] Görsel yükleme iyileştirmesi (drag & drop)

### Aşama 2: Fotoğraftan Ürün Çıkarma (2-3 Hafta)

#### Teknik Yapı
```
Fotoğraf → ML Kit OCR → Metin çıkarma → Ürün adı/fiyat çıkarma → Onay → Kaydet
```

#### UI Tasarımı
```
┌─────────────────────────────────────────┐
│  📷 Fotoğraftan Ürün Çıkar             │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │    [Fotoğraf Seç veya Çek]         ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  Algılanan Ürünler:                     │
│  ┌─────────────────────────────────────┐│
│  │ ✅ Ülker Çikolata    - 15.00 ₺    ││
│  │ ✅ Çaykur Çay        - 45.00 ₺    ││
│  │ ✅ Ekmek Kızartma    - 120.00 ₺   ││
│  └─────────────────────────────────────┘│
│                                         │
│  [Tümünü Seç]  [Seçili Olarak Ekle]    │
└─────────────────────────────────────────┘
```

#### Yapılacaklar
- [ ] ML Kit OCR entegrasyonu
- [ ] Fatura formatı tanıma (TR formatı)
- [ ] Fiyat çıkarma regex
- [ ] Ürün adı çıkarma
- [ ] Kategori eşleştirme
- [ ] Toplu onay/arayüzü

### Aşama 3: Barkod ile Ürün Ekleme (1-2 Hafta)

#### Teknik Yapı
```
Barkod → Google Barcode API → Ürün bilgisi → Otomatik doldurma → Kaydet
```

#### UI Tasarımı
```
┌─────────────────────────────────────────┐
│  🏷️ Barkod ile Ürün Ekle              │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │    [Kamerayı barkoda doğrultun]    ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  Barkod: 8690123456789                  │
│  Ürün: Ülker Çikolata 80g               │
│  Kategori: Gıda > Atıştırmalık          │
│  Fiyat: 15.00 ₺                        │
│                                         │
│  [Kaydet]  [Düzenle]                    │
└─────────────────────────────────────────┘
```

#### Yapılacaklar
- [ ] camera paketi entegrasyonu
- [ ] Google Barcode API entegrasyonu
- [ ] Barkod veritabanı (Open Food Facts)
- [ ] Otomatik ürün doldurma
- [ ] Manuel düzenleme seçeneği

### Aşama 4: Toplu Excel Yükleme (2 Hafta)

#### UI Tasarımı
```
┌─────────────────────────────────────────┐
│  📊 Toplu Ürün Yükleme                 │
├─────────────────────────────────────────┤
│  1. Şablonu İndir                       │
│  2. Ürünleri doldur                     │
│  3. Dosyayı yükle                       │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📁 Excel dosyasını sürükleyin     ││
│  │     veya tıklayın                  ││
│  └─────────────────────────────────────┘│
│                                         │
│  Yükleme Durumu:                        │
│  ✅ 10/10 ürün yüklendi                 │
│  ⚠️ 2 uyarı: Fiyat formatı düzeltilmeli│
└─────────────────────────────────────────┘
```

#### Yapılacaklar
- [ ] Excel şablonu oluştur
- [ ] Excel okuma (excel paketi)
- [ ] Doğrulama motoru
- [ ] Hata raporu
- [ ] Toplu görsel yükleme

### Aşama 5: Ürün Varyasyonları (2-3 Hafta)

#### Veri Yapısı
```dart
class ProductVariant {
  final String id;
  final String type; // 'beden', 'renk', 'boyut'
  final String value; // 'M', 'Kırmızı', '1kg'
  final double? priceModifier; // +5₺, -2₺
  final int stock;
  final String? sku;
}
```

#### UI Tasarımı
```
┌─────────────────────────────────────────┐
│  👕 Ürün Varyasyonları                  │
├─────────────────────────────────────────┤
│  Renkler:                               │
│  [Kırmızı] [Mavi] [Yeşil] [+ Renk Ekle]│
│                                         │
│  Bedenler:                              │
│  [S] [M] [L] [XL] [+ Beden Ekle]       │
│                                         │
│  Fiyat Farkı:                           │
│  Renk: +0₺  Beden: +0₺                 │
│                                         │
│  Stok: Her varyasyon için ayrı          │
└─────────────────────────────────────────┘
```

---

## 4. SEO Optimizasyonu

### Otomatik SEO Önerileri
```
Ürün Adı: "Kırmızı Kadın Tişört"
→ SEO Önerisi: "Kırmızı Kadın Tişört - %100 Pamuk - S/M/L Beden"

Açıklama: "Güzel tişört"
→ SEO Önerisi: "Kırmızı Kadın Tişört, %100 pamuklu kumaş, rahat kesim.
   S, M, L beden seçenekleri mevcuttur. Makinede yıkanabilir."
```

### Yapılacaklar
- [ ] Otomatik başlık optimizasyonu
- [ ] Anahtar kelime önerisi
- [ ] Meta tag oluşturma
- [ ] Structured data (JSON-LD)
- [ ] Rakip fiyat analizi

---

## 5. UI/UX İyileştirmeleri

### Ürün Yönetim Sayfası Yeniden Tasarımı
```
┌─────────────────────────────────────────────────────────┐
│  Ürün Yönetimi                                    [Ekle]│
├─────────────────────────────────────────────────────────┤
│  🔍 Ürün ara...                        Kategori: [Tümü] │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐│
│  │ 🖼️  Ülker Çikolata 80g                             ││
│  │     Gıda > Atıştırmalık    15.00 ₺    ✅ Mevcut    ││
│  │     [Düzenle] [Sil] [Görsel Ekle]                  ││
│  ├─────────────────────────────────────────────────────┤│
│  │ 🖼️  Çaykur Rize Çay 500g                          ││
│  │     Gıda > İçecek          45.00 ₺    ✅ Mevcut    ││
│  │     [Düzenle] [Sil] [Görsel Ekle]                  ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  Hızlı Ekleme:                                          │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐             │
│  │ 📝  │ │ 📷  │ │ 📄  │ │ 🏷️  │ │ 📊  │             │
│  │Manuel│ │Fotoğ│ │Fatura│ │Barkod│ │Toplu│             │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘             │
└─────────────────────────────────────────────────────────┘
```

---

## 6. Öncelik Sıralaması

| Sıra | Özellik | Süre | Etki | Zorluk |
|---|---|---|---|---|
| 1 | Hızlı ürün ekleme UI'ı | 1-2 hafta | Yüksek | Düşük |
| 2 | Fotoğraftan ürün çıkarma | 2-3 hafta | Çok yüksek | Orta |
| 3 | Toplu Excel yükleme | 2 hafta | Yüksek | Orta |
| 4 | Barkod tarama | 1-2 hafta | Orta | Orta |
| 5 | Ürün varyasyonları | 2-3 hafta | Yüksek | Yüksek |
| 6 | SEO optimizasyonu | 2 hafta | Orta | Orta |

---

## 7. Teknik Gereksinimler

### Paketler
```yaml
dependencies:
  # OCR ve Görsel İşleme
  google_mlkit_text_recognition: ^0.11.0
  google_mlkit_object_detection: ^0.11.0
  
  # Barkod Tarama
  mobile_scanner: ^3.5.5
  
  # Excel İşleme
  excel: ^4.0.0
  
  # Görsel Optimizasyonu
  image: ^4.1.0
  
  # Dosya Seçimi
  file_picker: ^6.1.1
```

### API Gereksinimleri
- Google ML Kit (cihaz içi, ücretsiz)
- Open Food Facts API (barkod için, ücretsiz)
- Google Barcode API (barkod için, ücretsiz)

---

## 8. Zaman Çizelgesi

```
Hafta 1-2:  Hızlı ürün ekleme UI'ı
Hafta 3-5:  Fotoğraftan ürün çıkarma
Hafta 6-7:  Toplu Excel yükleme
Hafta 8-9:  Barkod tarama
Hafta 10-12: Ürün varyasyonları
Hafta 13-14: SEO optimizasyonu
```

**Toplam:** ~14 hafta (3.5 ay)

---

## 9. Başarı Kriterleri

| Kriter | Hedef |
|---|---|
| Ürün ekleme süresi | 10 ürün < 5 dakika |
| OCR doğruluk oranı | > %80 |
| Barkod tanma oranı | > %90 |
| Excel yükleme başarı oranı | > %95 |
| Kullanıcı memnuniyeti | > 4/5 |

---

## 10. Riskler ve Azaltma

| Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|
| OCR doğruluk düşük | Orta | Yüksek | Manuel düzenleme seçeneği |
| Barkod veritabanı eksik | Düşük | Orta | Open Food Facts + manuel |
| Excel format hataları | Yüksek | Orta | Şablon + doğrulama |
| Performans yavaşlığı | Düşük | Yüksek | Asenkron işleme |
