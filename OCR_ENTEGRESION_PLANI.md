# VixRex OCR Entegrasyon Planı
> Premium Özellik: Fotoğraftan, Faturadan veya Raf Etiketinden Ürün Çıkarma
> Tarih: 2026-07-09

---

## 1. Mimari Tasarım

### Mevcut Yapı
```
lib/
  core/           → Result<T>, SupabaseErrorMapper
  services/       → ChatbotService, StorePublishService vb.
  controllers/    → StoreEditorController vb.
  screens/        → VixRexScreen (asistan)
  config/         → ChatbotConfig (intent tanımları)
```

### Yeni Eklenecekler
```
lib/
  core/
    result.dart              → Mevcut (dokunulmayacak)
    supabase_error_mapper.dart → Mevcut (dokunulmayacak)
  services/
    ocr/                     → YENİ KLASÖR
      ocr_service.dart       → Ana OCR servisi
      ocr_text_parser.dart   → Metin ayrıştırma
      ocr_price_parser.dart  → Fiyat çıkarma
      ocr_image_preprocessor.dart → Görsel ön işleme
      ocr_product_matcher.dart    → Ürün eşleştirme
      ocr_excel_verifier.dart     → Excel doğrulama
    excel/                   → YENİ KLASÖR
      excel_service.dart     → Excel okuma
      product_database.dart  → Ürün veritabanı
  models/
    ocr_result.dart          → OCR sonucu modeli
    detected_product.dart    → Tespit edilen ürün
  controllers/
    ocr_controller.dart      → OCR state yönetimi
  screens/
    ocr_scanner_screen.dart  → OCR tarama ekranı
  config/
    premium_config.dart      → Premium özellik ayarları
```

---

## 2. Servis Mimari Detayı

### 2.1 OCR Servisi (ocr_service.dart)
```dart
/// Ana OCR servisi. Tüm OCR işlemlerini koordine eder.
class OcrService {
  final OcrTextParser textParser;
  final OcrPriceParser priceParser;
  final OcrImagePreprocessor imagePreprocessor;
  final OcrProductMatcher productMatcher;
  final OcrExcelVerifier excelVerifier;

  const OcrService({
    required this.textParser,
    required this.priceParser,
    required this.imagePreprocessor,
    required this.productMatcher,
    required this.excelVerifier,
  });

  /// Görüntüden ürün kataloğu oluşturur.
  Future<Result<OcrCatalogResult>> analyzeImage(Uint8List imageBytes) async {
    // 1. Görseli ön işle
    final preprocessed = await imagePreprocessor.preprocess(imageBytes);

    // 2. OCR ile metni oku
    final textResult = await textParser.parseFromImage(preprocessed);

    // 3. Fiyatları çıkar
    final prices = priceParser.extractPrices(textResult.rawText);

    // 4. Ürünleri eşleştir
    final products = await productMatcher.matchProducts(
      textResult.lines,
      prices,
    );

    // 5. Excel ile doğrula
    final verified = await excelVerifier.verify(products);

    return Result.success(OcrCatalogResult(
      rawText: textResult.rawText,
      products: verified,
      confidence: _calculateConfidence(verified),
    ));
  }
}
```

### 2.2 OCR Controller (ocr_controller.dart)
```dart
class OcrController extends ChangeNotifier {
  final OcrService _ocrService;
  
  OcrCatalogResult? _result;
  bool _isProcessing = false;
  String? _errorMessage;

  OcrController({required OcrService ocrService}) : _ocrService = ocrService;

  /// Görüntüyü analiz et
  Future<void> analyzeImage(Uint8List imageBytes) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _ocrService.analyzeImage(imageBytes);

    result.when(
      success: (catalog) {
        _result = catalog;
        _isProcessing = false;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _isProcessing = false;
        notifyListeners();
      },
    );
  }

  /// Ürünü onayla
  void approveProduct(int index) {
    if (_result == null) return;
    _result!.products[index].isApproved = true;
    notifyListeners();
  }

  /// Ürünü düzenle
  void updateProduct(int index, DetectedProduct updated) {
    if (_result == null) return;
    _result!.products[index] = updated;
    notifyListeners();
  }

  /// Onaylanan ürünleri kaydet
  Future<Result<void>> saveApprovedProducts() async {
    // VixRex product servisine kaydet
  }
}
```

---

## 3. Premium Özellik Yapısı

### 3.1 Ücretlendirme Modeli
```
Ücretsiz Kullanıcı:
- Manuel ürün ekleme (mevcut)
- 5 ürün/sayfa

Premium Kullanıcı:
- OCR ile otomatik ürün çıkarma
- Sınırsız ürün
- Toplu yükleme
- Excel ile içe aktarma
```

### 3.2 Premium Kontrol (premium_config.dart)
```dart
class PremiumConfig {
  static const int freeProductLimit = 5;
  static const bool ocrEnabledForFree = false;
  static const bool bulkUploadEnabledForFree = false;

  /// Kullanıcının premium olup olmadığını kontrol et
  static bool isPremium(UserProfile profile) {
    return profile.isPremium ?? false;
  }

  /// OCR kullanımı için izin var mı?
  static bool canUseOcr(UserProfile profile) {
    return isPremium(profile);
  }
}
```

### 3.3 Supabase Tabloları
```sql
-- Kullanıcı premium durumu
ALTER TABLE profiles ADD COLUMN is_premium BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN premium_expires_at TIMESTAMP;

-- OCR geçmişi
CREATE TABLE ocr_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  image_url TEXT,
  products JSONB,
  confidence DECIMAL,
  created_at TIMESTAMP DEFAULT now()
);

-- Sıfır Maliyetli Eğitim Veri Seti (Feedback Loop)
CREATE TABLE ocr_feedback_dataset (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  raw_ocr_text TEXT NOT NULL,
  corrected_products JSONB NOT NULL, -- Kullanıcının düzelttiği nihai [ad, fiyat] listesi
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);
```

---

## 4. VixRex Asistan Entegrasyonu

### 4.1 Yeni Intent'ler (chatbot_config.dart)
```dart
// Mevcut intent'lere eklenecekler:
ChatbotIntent(
  id: 'ocr_scan',
  keywords: ['fotoğraf', 'fatura', 'tara', 'ürün ekle', 'katalog oluştur'],
  response: 'Fotoğraftan ürün çıkarma özelliği premium gerektirir.',
),

ChatbotIntent(
  id: 'ocr_premium_info',
  keywords: ['premium', 'üyelik', 'ocr', 'otomatik'],
  response: 'Premium üyelik ile fotoğraf/faturadan otomatik ürün çıkarma...',
),
```

### 4.2 Asistan Akışı
```
Kullanıcı: "Fotoğraftan ürün ekle"
     ↓
VixRex: "Bu özellik premium gerektirir. Satın almak ister misiniz?"
     ↓
Kullanıcı: "Evet"
     ↓
VixRex: "Ödeme sayfasını açıyorum..." (Stripe/iyzico)
     ↓
Ödeme tamamlandı → Premium aktif
     ↓
VixRex: "Şimdi fotoğrafınızı çekebilirsiniz"
     ↓
Kamera aç → Fotoğraf çek → OCR çalıştır
     ↓
VixRex: "3 ürün bulundu. Onaylıyor musunuz?"
     ↓
Kullanıcı: "Evet"
     ↓
Vitrine ekle
```

---

## 5. UI/UX Tasarımı

### 5.1 OCR Tarama Ekranı
```
┌─────────────────────────────────────────┐
│  📷 Fotoğraftan Ürün Çıkar             │
├─────────────────────────────────────────┤
│  [ Fiş/Fatura Modu ]  👉[ Raf/Etiket Modu ]│
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────────┐│
│  │                                     ││
│  │    [Kamerayı doğrultun]            ││
│  │                                     ││
│  │  [Sarı/Beyaz Etiketleri Netleyin]   ││
│  │                                     ││
│  └─────────────────────────────────────┘│
│                                         │
│  [Fotoğraf Çek]  [Galeriden Seç]       │
│                                         │
├─────────────────────────────────────────┤
│  ⏳ Analiz ediliyor...                 │
│  ████████████░░░░ 65%                  │
├─────────────────────────────────────────┤
│  ✅ Bulunan Ürünler:                    │
│  ┌─────────────────────────────────────┐│
│  │ Biscolata Mood 110g   54.99 ₺  ✅  ││
│  │ Dankek Rulo Pasta     70.00 ₺  ✅  ││
│  │ Kekstra Çilekli       11.00 ₺  ✅  ││
│  └─────────────────────────────────────┘│
│                                         │
│  [Tümünü Onayla]  [Düzenle]            │
└─────────────────────────────────────────┘
```

### 5.2 Premium Satın Alma Ekranı
```
┌─────────────────────────────────────────┐
│  ⭐ Premium Üyelik                      │
├─────────────────────────────────────────┤
│                                         │
│  📷 Fotoğraftan Ürün Çıkarma           │
│  📄 Faturadan Otomatik Kayıt           │
│  📊 Toplu Excel Yükleme                │
│  🏷️ Barkod Tarama                      │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │ Aylık: 49.99 ₺                     ││
│  │ Yıllık: 399.99 ₺ (33.33 ₺/ay)     ││
│  └─────────────────────────────────────┘│
│                                         │
│  [30 Gün Ücretsiz Dene]                │
└─────────────────────────────────────────┘
```

---

## 6. Uygulama Adımları

### Aşama 1: Altyapı (1 hafta)
- [ ] OCR servislerini oluştur
- [ ] Model dosyalarını ekle
- [ ] Excel servisini oluştur
- [ ] Testleri yaz

### Aşama 2: Asistan Entegrasyonu (1 hafta)
- [ ] Yeni intent'leri ekle
- [ ] Quick reply'leri güncelle
- [ ] Premium kontrol mekanizması

### Aşama 3: UI/UX (1 hafta)
- [ ] OCR tarama ekranı
- [ ] Premium satın alma ekranı
- [ ] Sonuç ekranı

### Aşama 4: Test ve Yayına Alma (1 hafta)
- [ ] Unit testler
- [ ] Widget testler
- [ ] Entegrasyon testleri
- [ ] Manuel test

---

## 7. Risk Değerlendirmesi

| Risk | Olasılık | Etki | Çözüm |
|---|---|---|---|
| OCR doğruluk düşük | Yüksek | Yüksek | Excel doğrulama + lokal fuzzy matching + manuel düzeltme geri bildirimi |
| Premium ödeme sorunu | Orta | Yüksek | Stripe/iyzico entegrasyonu |
| Performans yavaşlığı | Orta | Orta | Asenkron işleme + cache |
| Bellek kullanımı yüksek | Düşük | Orta | Görsel optimizasyon |

---

## 8. Sıfır Maliyetli Eğitim Seti ve Aktif Öğrenme (Active Learning) Stratejisi

Piyasadaki büyük OCR sağlayıcılarının (Google, AWS vb.) kullandığı veri seti hazırlama yöntemleri analiz edilerek, **0 API maliyeti** ile çalışacak aşağıdaki döngü tasarlanmıştır:

### 8.1 Çevrimdışı Sentetik Fiş Üreteci (Synthetic Data Generation)
Geliştirme aşamasında parser algoritmalarını (regex kuralları, fiyat filtreleri vb.) test etmek ve eğitmek için lokal bir simülatör kullanılacaktır:
*   Rastgele mağaza adları, Türkçe ürün adları, KDV oranları ve fiyat kombinasyonları üretilir.
*   Farklı font, satır kayması, karakter bozulması ve gürültü (noise) senaryoları simüle edilerek ham metinler oluşturulur.
*   Bu metinler lokal test suite üzerinden geçirilerek regex doğruluğu sıfır maliyetle ölçülür.

### 8.2 Aktif Öğrenme Geri Besleme Döngüsü (User-in-the-Loop Feedback)
Kullanıcıların canlı uygulamadaki düzeltmeleri sisteme geri besleme olarak kazandırılır:
1.  **OCR Çıktısı Alınır:** `OcrService` görseli tarayıp ham metni ve başlangıç eşleşmelerini çıkarır.
2.  **Kullanıcı Düzeltme Yapar:** Arayüzde hatalı fiyatları, eksik ürün isimlerini el ile günceller.
3.  **Supabase'e Kaydedilir:** Ham OCR metni ile kullanıcının onayladığı nihai düzeltilmiş ürünler `ocr_feedback_dataset` tablosuna yazılır.
4.  **Kural İyileştirme:** Bu veri seti zamanla analiz edilerek, en çok hata yapılan kelime çiftleri için regex kuralları ve lokal fuzzy matching sözlüğü otomatik optimize edilir.

### 8.3 Raf ve Fiyat Etiketi Tarama Analizi (Shelf Label Parsing)
Fiş/Faturaya ek olarak market/bakkal raflarından ve sarı/beyaz fiyat etiketlerinden ürün çıkarımı için özel kurallar uygulanacaktır:
*   **Paket Görselleri vs Etiketler:** Paket üzerindeki süslü logolar (örn: "Dankek", "Biscolata Mood") yerine doğrudan altlarındaki beyaz/sarı dikdörtgen raf etiketleri (fiyat etiketleri) hedeflenecektir. Bu etiketlerin üzerindeki yazılar daha düz, standart ve okunaklıdır.
*   **İndirim Etiketleri Algılama:** Sarı indirim etiketlerindeki devasa indirimli fiyat ile üstü çizili eski fiyatı ayırt etmek için regex kuralı geliştirilecektir (örn: `İNDİRİM \d+[\.,]\d{2}` deseniyle büyük fontlu indirimli fiyat önceliklendirilir).
*   **Hizalama ve Blok Analizi:** ML Kit'ten gelen bounding box (çerçeve) koordinatları kullanılarak, aynı etikete ait olan `Ürün Adı` ve `Fiyat` metin grupları dikey/yatay yakınlıklarına göre gruplandırılacaktır. Böylece farklı ürünlerin fiyatlarının birbirine karışması engellenecektir.

---

## 9. Sonraki Adımlar

Bu planı onaylarsan, Aşama 1'den başlayarak uygulamaya geçebilirim.

Onaylıyor musun?
