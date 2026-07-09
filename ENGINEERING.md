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

## 3. Öncelikli Aksiyon Planı (Launch Path)

### Faz 1: Güvenlik, Veri Bütünlüğü ve Yasal Uyum (Hafta 1)
- [ ] **Eksik Şema:** `0000_core_schema.sql` oluşturularak `stores` ve `vitrin_views` tabloları dökümante edilmeli.
- [ ] **PII Güvenliği:** Randevu sorgularında telefon numaralarını maskeleyen View/RPC katmanı.
- [ ] **KVKK:** Kullanıcı silme (`delete_user_account`) fonksiyonunun randevu verilerini de kapsadığından emin olunmalı.
- [ ] **OCR Tahkimatı:** Limit kontrolü veritabanı tarafında atomik RPC'ye taşınmalı.

### Faz 2: Üretim Kalitesi ve Hata Yönetimi (Hafta 1)
- [ ] **UI Feedback:** Tüm controller'lardaki `try-catch` blokları kullanıcıya (Toast/Dialog) hata döndürecek hale getirilmeli.
- [ ] **Görsel Resize:** Flutter tarafında yüklenen görseller 1MB altına zorlanmalı (Storage ve Bandwidth tasarrufu).
- [ ] **Validation:** WhatsApp numarası ve Sosyal Medya linkleri için regex validasyonu (Next.js tarafında kırılmaları önlemek için).

### Faz 3: Next.js / SEO / UX (Hafta 2)
- [ ] **On-demand Revalidation:** Vitrin güncellendiğinde Next.js cache'ini tetikleyen webhook.
- [ ] **OpenGraph:** WhatsApp/Instagram paylaşımları için dinamik görsel optimizasyonu.
- [ ] **Loading States:** Randevu alma ve Vitrin yükleme sırasında "Skeleton" veya "Loader" ekranları.

## 4. Kritik Kontrol Listesi (Go-Live Checklist)
1. [ ] Supabase RLS politikaları "authenticated" ve "anon" rollerine göre test edildi mi?
2. [ ] Next.js üretim build'i (`npm run build`) hata veriyor mu?
3. [ ] Flutter Web build boyutu ve açılış hızı kabul edilebilir mi?
4. [ ] Randevu token'ları e-posta veya SMS ile gitmiyorsa, kullanıcıya "bu linki saklayın" uyarısı veriliyor mu?
