# VixRex Engineering & Roadmap

Bu doküman, MVP aşamasından profesyonel ürüne geçiş sürecindeki teknik analizleri, riskleri ve iyileştirme planlarını içerir. AI destekli geliştirme (Vibe Coding) sürecinde teknik borç ve mantıksal tutarlılığı korumak için referans alınmalıdır.

## 1. Mevcut Durum (Röntgen) Özeti
*   **Mimari:** Flutter tarafında `StoreEditorController` "God Object" durumunda. İş mantığı, UI yönetimi ve servis çağrıları iç içe geçmiş.
*   **Güvenlik:** RLS (Row Level Security) politikaları bazı yerlerde (özellikle OCR limiti) istemci beyanına güveniyor. Kişisel veriler (PII) açık metin olarak tutuluyor.
*   **Veritabanı:** Çekirdek şema SQL'leri (stores, vitrin_views) eksik. Migration zinciri "hotfix" odaklı ilerlemiş.
*   **SEO & Performans:** Next.js tarafında 300s sabit revalidation var, anlık güncelleme mekanizması eksik.

## 2. Kritik Riskler
1.  **Veri Sızıntısı:** `appointments` tablosundaki müşteri telefonları ve isimleri token sahibi herkes tarafından okunabilir.
2.  **Logic Bypass:** OCR günlük limitleri Flutter tarafında manipüle edilebilir.
3.  **Bakım Zorluğu:** Controller katmanındaki `try-catch` bloklarının hataları yutması (silent failure) hata ayıklamayı zorlaştırıyor.
4.  **Timezone Kaymaları:** Randevu saatlerinin sunucu ve işletme lokasyonu arasında senkronize olmaması riski.

## 3. Öncelikli Aksiyon Planı

### Faz 1: Güvenlik ve Veri Bütünlüğü (Kritik)
- [ ] `0000_core_schema.sql` oluşturularak eksik tablolar dökümante edilmeli.
- [ ] Randevu token sorgularında PII verilerini maskeleyen View'lar veya RPC'ler kullanılmalı.
- [ ] OCR limit kontrolü `security definer` bir RPC fonksiyonuna taşınmalı (`decrement_ocr_usage`).
- [ ] `link_store_to_user` fonksiyonundaki `security definer` yetkileri denetlenmeli.

### Faz 2: Flutter Mimari Refactoring (Teknik Borç)
- [ ] `StoreEditorController` parçalanmalı:
    - `StoreMediaController` (Kapak/Galeri işlemleri)
    - `StoreLocationController` (GPS/Adres işlemleri)
    - `StorePublishController` (Yayınlama/Token işlemleri)
- [ ] Global bir `ErrorHandler` servisi kurulmalı, `debugPrint` yerine `Failure` nesneleri dönülmeli.
- [ ] `edit_token` yerel cihazda daha güvenli (Secure Storage) saklanmalı.

### Faz 3: Ürünleşme ve Ölçeklenme
- [ ] **On-demand Revalidation:** Vitrin güncellendiğinde Vercel cache'ini temizleyen webhook entegrasyonu.
- [ ] **Premium Layer:** Premium üyelik kontrolünü merkezi bir `SubscriptionService` üzerinden backend doğrulamalı yapma.
- [ ] **Timezone Fix:** İşletme bazlı `timezone` alanı eklenerek randevu hesaplamalarının bu alan üzerinden yapılması.

## 4. Geliştirme Notları (AI için Talimatlar)
*   Yeni bir özellik eklemeden önce mutlaka RLS politikasını sorgula.
*   İş mantığını (Business Logic) mümkünse UI Controller'dan Service veya Repository katmanına taşı.
*   Hata yakalama bloklarında hatayı yutma, kullanıcıya aksiyon alabileceği bir geri bildirim ver.
