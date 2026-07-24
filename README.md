# VixRex

> **Küçük işletmeler için dijital vitrin kartı ve müşteri yönetim platformu.**

VixRex; küçük işletmelerin, hizmet sağlayıcılarının ve sanatkarların dijital ortamda vitrin oluşturmalarını, ürün/hizmet kataloglarını yönetmelerini, OCR ve Excel ile toplu ürün yüklemelerini, randevu almalarını ve yapay zeka destekli asistan ile etkileşime geçmelerini sağlayan hibrit bir platformdur.

---

## 🏗️ Sistem Mimarisi

VixRex iki ana bileşenden oluşan ikili bir mimariye sahiptir:

```
vixrex/
├── lib/               # Flutter İşletme Yönetim Paneli (Web & Mobil)
└── public_web/        # Next.js SEO Uyumlu Müşteri Vitrin Sitesi
```

1. **İşletme Yönetim Paneli (Flutter Web & Mobile)**:
   - İşletme sahiplerinin vitrin düzenlediği, ürün/kategori ve randevu yönettiği, OCR ile toplu veri aktardığı yönetim ekranıdır.
2. **Müşteri Vitrin Sitesi (`public_web` - Next.js App Router)**:
   - `/v/:slug` adresi üzerinden müşterilere sunulan SEO odaklı, yüksek hızlı vitrin ve online randevu alma yüzüdür.

---

## 🛠️ Teknoloji Yığını

### Ana Uygulama (Flutter - `lib/`)
* **SDK:** Dart SDK `^3.7.2` / Flutter 3.x
* **Veritabanı & Kimlik Doğrulama:** Supabase (`supabase_flutter ^2.12.4`)
* **Sayfa Yönlendirme:** `go_router ^14.3.0`
* **Metin Tanıma & OCR:** `google_mlkit_text_recognition 0.15.1`
* **Dosya İşleme:** `excel ^4.0.0`, `file_picker`, `image_picker`, `flutter_image_compress`
* **Anlık Bildirimler:** OneSignal (`onesignal_flutter ^5.2.0`)
* **Hata Takibi:** Sentry (`sentry_flutter 9.3.0`)

### Müşteri Yüzü (`public_web/`)
* **Framework:** Next.js (TypeScript, App Router)
* **Veri Katmanı:** Supabase JS Client (`@supabase/supabase-js`)
* **Stil:** Tailwind CSS

---

## 🚀 Öne Çıkan Özellikler

- 🏪 **Dijital Vitrin Editörü (`my_vitrin`):** İşletme bilgileri, logo/kapak görselleri, sosyal medya bağları ve tema özelleştirmeleri.
- 📸 **OCR ile Toplu Ürün Yükleme (`ocr_scanner_screen`):** Menü, broşür veya fiziki listelerden görsel metin tanıma (ML Kit) ile anında ürün kartları oluşturma.
- 📊 **Excel ile Toplu Veri Aktarımı (`bulk_product_upload_screen`):** Toplu ürün ve stok listelerini tek tıkla sisteme aktarma.
- 📅 **Randevu & Booking Takibi (`booking_management_screen`):** Hizmet bazlı randevu takvimleri, onay süreçleri ve müşteri randevu izleme bağlantıları (`/v/:slug/randevu/:token`).
- 🤖 **VixRex Yapay Zeka Asistanı (`vixrex_onboarding_chat_screen`):** Mağaza kurulumu, öneriler ve hızlı işlem yönlendirmeleri sunan etkileşimli sohbet asistanı.
- 🔍 **Keşfet Ekranı (`explore_screen`):** Platformdaki yayınlanmış işletmeleri listeleme, arama ve favorilere ekleme.
- 📝 **İçerik & Blog Yönetimi (`blog_editor_screen`):** İşletmelerin duyuru ve blog yazıları paylaşması.

---

## 💻 Yerel Geliştirme Ortamı

### Gereksinimler
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.7.2`)
- [Node.js](https://nodejs.org/) (`>= 18.x` — `public_web` için)

### Ana Uygulamayı Çalıştırma (Flutter)

```bash
# Bağımlılıkları yükleyin
flutter pub get

# Chrome üzerinde başlatın (Supabase ortam değişkenleri ile)
flutter run -d chrome \
  --dart-define=SUPABASE_URL="YOUR_SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="YOUR_SUPABASE_KEY"
```

### Müşteri Yüzünü Çalıştırma (Next.js)

```bash
cd public_web
npm install
npm run dev
```

---

## ⚙️ Çevre Değişkenleri (Environment Variables)

### Flutter Ana Uygulama (`--dart-define`)
| Değişken | Açıklama |
| :--- | :--- |
| `SUPABASE_URL` | Supabase proje URL adresi *(Zorunlu)* |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase anonim API anahtarı *(Zorunlu)* |
| `ONESIGNAL_APP_ID` | OneSignal bildirim uygulaması ID *(Opsiyonel)* |
| `SENTRY_DSN` | Sentry hata izleme DSN adresi *(Opsiyonel)* |
| `PUBLIC_SITE_URL` | Müşteri vitrinlerinin yönlendirileceği kamu adresi |

### Next.js Müşteri Yüzü (`public_web/.env.local`)
```env
NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_KEY
```

---

## 🌐 Yayınlama (Deployment)

Proje **Vercel** üzerinde iki ayrı uygulama olarak yayınlanmaktadır:

1. **`vixrex-app`**: Flutter Web release derlemesi (`vercel-build.sh` betiği ile).
2. **`vixrex-public`**: `public_web` dizinindeki Next.js uygulaması.

---

## 📄 Lisans

Bu proje özel mülkiyete tabidir. Tüm hakları saklıdır.
