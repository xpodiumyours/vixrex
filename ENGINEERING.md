# VixRex Engineering & Roadmap

> MVP → Production geçiş planı. Her faz bağımsız çalışılabilir, sıralama zorunlu değil.

---

## Mevcut Durum (10 Temmuz 2026)

| Katman | Durum | Eksik |
|---|---|---|
| Flutter uygulaması | 14 ekran, 23 servis, OCR | Native mobil yok (sadece web) |
| Next.js public vitrin | SSR, SEO, sitemap | Revalidation webhook eksik |
| Supabase | Auth, Storage, RLS aktif | stores/vitrin_views ilk SQL'i eksik |
| Deploy | Vercel aktif | Custom domain doğrulanmamış |
| Test | 263 unit test | E2E test yok |
| Toplu ürün yükleme | Excel/CSV parse hazır | Entegre edildi |
| Randevu sistemi | Çalışıyor | Timezone sorunu var |
| Ödeme | Yok | Planlanmamış |

---

## FAZ 1: Kritik Güvenlik & Yasal (3-4 gün)

Bu faz olmadan production'a çıkmak riskli.

### 1.1 Eksik Şema SQL'i
- `stores` ve `vitrin_views` tablolarının ilk oluşturma SQL'i yazılmamış
- Yeni Supabase projesi kurulduğunda migration'lar çalışmayacak
- **Yapılacak:** `0000_core_schema.sql` oluştur, mevcut tablo yapısını belgele

### 1.2 PII Güvenliği
- `appointments` tablosunda müşteri telefonları ve isimleri açık metin
- Herhangi bir edit token sahibi tüm randevuları görebilir
- **Yapılacak:** RLS politikalarını sıkılaştır, edit token ile sadece kendi randevularını göstersin

### 1.3 KVKK Uyumu
- `delete_user_account` fonksiyonu randevu verilerini siliyor mu?
- Kullanıcı verisi silme talebi endpoint'i çalışıyor mu?
- **Yapılacak:** Silme fonksiyonunu test et, randevu/makale/galeri verilerini kapsadığından emin ol

### 1.4 OCR Limit Tahkimatı
- OCR günlük limiti Flutter tarafında tutuluyor → manipüle edilebilir
- **Yapılacak:** Limit kontrolünü Supabase RPC'ye taşı, atomik say

---

## FAZ 2: Ürün Kalitesi (3-4 gün)

Kullanıcı deneyimini production seviyesine çıkarmak.

### 2.1 Hata Yönetimi
- Controller'lardaki `try-catch` blokları hataları yutuyor (silent failure)
- Kullanıcıya hata mesajı gösterilmiyor
- **Yapılacak:** Her async operasyonda kullanıcıya hata mesajı + retry mekanizması

### 2.2 Görsel Optimizasyon
- Yüklenen görseller boyut kontrolünden geçmiyor
- Storage ve bandwidth israfı
- **Yapılacak:** Flutter tarafında 1MB max, JPEG kalite 85, WebP dönüşümü

### 2.3 Form Validasyonu
- WhatsApp numarası formatı doğrulanmıyor
- Sosyal medya linkleri geçersiz girilebiliyor
- **Yapılacak:** Regex validasyonu (TR telefon: 5XX XXX XX XX)

### 2.4 Loading & Empty States
- Bazı ekranlarda skeleton/loading eksik
- Boş durum mesajları yetersiz
- **Yapılacak:** Her ekranda skeleton + empty + error state

---

## FAZ 3: SEO & Performance (2-3 gün)

Google'da görünür olmak ve hızlı yüklenmek.

### 3.1 On-demand Revalidation
- Vitrin güncellendiğinde Next.js cache'i 300sn bekliyor
- **Yapılacak:** Flutter'dan publish sonrası Next.js webhook'unu tetikle

### 3.2 OpenGraph Dinamik Görsel
- WhatsApp/Instagram'da paylaşılan linkler düz görünüyor
- **Yapılacak:** `/api/og?slug=xxx` ile dinamik görsel üret

### 3.3 Core Web Vitals
- Flutter Web boyutu büyük olabilir
- **Yapılacak:** Lighthouse skoru 80+ hedefle, bundle split

---

## FAZ 4: Native Mobil (5-7 gün)

Flutter Web yeterli değil — APK/App Store gerekiyor.

### 4.1 Android APK
- Flutter web'i native'e çevir
- Android build config (splash screen, icon, signing)
- Google Play Store hesabı + mağaza girişi

### 4.2 iOS
- Xcode build config
- App Store Connect hesabı
- Apple Developer ücreti ($99/yıl)

### 4.3 Push Notification
- Firebase Cloud Messaging entegrasyonu
- Randevu hatırlatması, yeni mesaj bildirimi

---

## FAZ 5: Analitik & İzleme (2-3 gün)

Kullanıcı davranışını anlamak.

### 5.1 Analytics
- Firebase Analytics veya Mixpanel
- Kritik eventler: vitrin oluşturma, randevu alma, QR tarama

### 5.2 Crash Reporting
- Sentry veya Firebase Crashlytics
- Production hatalarını anında yakala

### 5.3 Monitoring
- Uptime kontrolü (Supabase, Vercel)
- Hata oranı eşiği aşarsa bildirim

---

## FAZ 6: Mağaza Başvuruları (2-3 gün)

App Store ve Google Play'e göndermek.

### 6.1 Google Play
- Mağaza girişi (screenshots, açıklama, gizlilik politikası)
- Veri silme callback endpoint'i
- Content rating questionnaire

### 6.2 App Store
- App Store Connect hesabı
- Review süreci (7-14 gün sürebilir)
- Human Interface Guidelines uyumu

---

## İlerleme Durumu (10 Temmuz 2026)

| Faz | Durum | Tamamlanan |
|---|---|---|
| Faz 1: Güvenlik | ✅ Tamamlandı | Core schema, delete cascade, RLS, OCR limit RPC |
| Faz 2: Ürün kalitesi | ✅ Tamamlanan | Silent catch, WhatsApp validasyonu, görsel 1MB |
| Faz 3: SEO | ✅ Tamamlandı | Publish sonrası revalidation |
| Faz 4: Native mobil | ✅ Tamamlandı | OneSignal push notification eklendi |
| Faz 5: Analitik | ✅ Tamamlandı | Sentry crash reporting eklendi |
| Faz 6: Mağaza | ⏸️ Beklemede | T4/T5'e bağımlı |

### Ücretsiz Altyapı Planı (Firebase'siz)
| İhtiyaç | Çözüm | Maliyet |
|---|---|---|
| Push Notification | OneSignal | Ücretsiz (sınırsız mobil push) |
| Crash Reporting | Sentry | Ücretsiz (5K hata/ay) |
| Analytics | Supabase (mevcut) | Ücretsiz |
| Uptime | Sentry | Ücretsiz (1 monitor) |

### Kalan Manuel Adımlar
1. OneSignal hesabı oluştur → API key al
2. Sentry hesabı oluştur → DSN key al
3. Android release signing key oluştur (Play Store için)

---

## Kritik Kontrol Listesi (Go-Live)

- [ ] Supabase RLS politikaları test edildi
- [ ] stores/vitrin_views şeması dökümante edildi
- [ ] PII verileri maskeleme çalışıyor
- [ ] KVKK silme fonksiyonu test edildi
- [ ] OCR limiti sunucu tarafında
- [ ] Tüm ekranlarda error/loading/empty state var
- [ ] Görseller 1MB altında
- [ ] WhatsApp validasyonu çalışıyor
- [ ] On-demand revalidation çalışıyor
- [ ] Android APK build alındı
- [ ] Crash reporting aktif
- [ ] Analytics eventleri tanımlı
- [ ] Google Play mağaza girişi hazır
