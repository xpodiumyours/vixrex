# Vixrex — Google Play Store yayın öncesi tek rehber

Tarih: 26 Kasım 2026 · Paket: `com.vixrex.app` · Kaynak: `main` / PR (bkz. PR gövdesi)

Bu dosya Play Console'a kopyalanacak metinleri ve doğrulanmış adımları içerir.
İçinde sahte imza parmak izi, sahte hesap bilgisi veya yer tutucu görsel yoktur.

## 1) Android izinleri → Data Safety eşlemesi

Kaynak: `android/app/src/main/AndroidManifest.xml`

| İzin | Uygulamadaki gerçek iş | Data Safety etkisi |
|---|---|---|
| `CAMERA` | Fotoğraftan/faturadan ürün çıkarma (OCR). Fotoğraf mobil cihazdan `/api/fatura-oku` sunucu ucuna iletilir; işlem (Gemini / OpenRouter yedek zinciri) sunucu tarafında yapılır. Veri sunucuda işlenir, ürün eklendiğinde seçilen görsel Supabase depolamaya yüklenir. | **Photos** → "Collected" + "Shared"; amaç: App functionality (fotoğraf işlendikten sonra sunucu tarafında işlenir) |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Vitrin adresini GPS ile doldurma; ters coğrafi kodlama için OpenStreetMap Nominatim'e koordinat gönderilir. | **Precise location** → "Collected" + "Shared"; amaç: App functionality |
| `POST_NOTIFICATIONS` | OneSignal ile randevu/ürün bildirimleri; kullanıcı açıkça izin verir, ayarlardan kapatabilir. | **Identifiers** (OneSignal player ID) → "Collected" + "Shared"; amaç: App functionality / Notifications |
| `INTERNET` | Supabase, vixrex.com, OpenStreetMap, OneSignal HTTPS çağrıları. | Veri aktarımı **TLS/HTTPS** ile şifrelenir → "Data is encrypted in transit" işaretli |
| `READ/WRITE_EXTERNAL_STORAGE` (`maxSdkVersion=32`) | Eski Android sürümlerinde galeriden görsel seçimi. | Ek veri kategorisi açmaz (Photos zaten işaretli) |

Uygulama ayrıca Google ile giriş yapar (Google Sign-In): **Personal info** (ad, e-posta, Google hesap kimliği)
→ "Collected", amaç: App functionality / Account management.

### Data Safety formunda işaretlenecek kutucuklar

- **Data collected:** Personal info (name, email), Photos (camera / uploaded store images),
  Precise location, Identifiers (Google account ID, OneSignal player ID), User content
  (vitrin metinleri, ürün bilgileri).
- **Purposes:** App functionality, Account management, Analytics yok, Advertising yok,
  Developer communications yok (vitrin sahibine yönelik bildirimler uygulama işlevidir).
- **Shared with third parties:** Evet — Supabase (veri ve görsel barındırma),
  Cloudflare R2 (görsel CDN), OpenStreetMap Nominatim (koordinat → adres),
  OneSignal (push kimliği), Google (giriş).
- **Data is encrypted in transit:** Evet.
- **Data can be deleted:** Evet — `https://vixrex.com/legal/data-deletion` (ölçüm: HTTP 200).
- **Data collected in background:** Hayır.
- **Collected but not linked to identity / temporary:** Hayır; veri vitrin/hesap kimliğine bağlıdır.
- **Financial info / Payment info / Contacts / Call logs / SMS / Health / Browsing history:**
  Hayır. Ödeme akışı uygulama dışında, web üzerinde yürür; uygulamada kart veya ödeme verisi alınmaz.
- **Crash logs:** Dağıtım derlemesinde Sentry DSN verilmediği için toplanmaz.

Gizlilik politikası: `https://vixrex.com/privacy` (ölçüm: HTTP 200).

## 2) App Access — Review ekibine verilecek İngilizce test talimatı

Aşağıdaki metni **App access → Sign-in details** alanına kopyalayın. Köşeli parantez içindeki
yerleri Casper doldurur; depoya gerçek şifre yazılmaz.

```text
App name: Vixrex
Package: com.vixrex.app
Build under review: [paste version name / build number]

1. Open the app. No payment, purchase or subscription is required to test it.
2. On the welcome screen, tap "Start" (or "Hazır Vitrin Seç") and choose any
   ready-made showcase template.
3. You can explore the app without signing in: browse "Keşfet", open a store
   card, and use the assistant chat.
4. To test account features, tap "Sign in with Google" and use this test
   account:
      Email: [test account e-mail]
      Password: [test account password - provide to Google only, not in the repo]
   If Google asks for phone verification, use: [test phone number]
5. After signing in, go to "Vitrinim", edit the business name and WhatsApp
   number, then tap "Publish" to see the web link / QR code.
6. Optional: open the camera/OCR flow and scan a product label, or allow
   location access to fill the store address. Both permissions are optional;
   the app works if you deny them.
7. Notifications are optional. If prompted, allow them once to see a test
   notification; you can disable them in app settings.

Notes for the reviewer:
- No in-app billing, price promise or external payment link is shown in the app.
- Demo data is sufficient; no production database changes are needed.
- Contact for access problems: [support e-mail / Play Console contact].
```

## 3) Mağaza varlıkları ve doğrulama

Klasör: `android/store-assets/`

- `icon-512x512.png` — 512×512, 32-bit RGBA (alpha), ≤ 1024 KB
- `feature-graphic-1024x500.png` — 1024×500, 24-bit RGB (alfa yok), `#050B1A` zemin + `#147DFF` marka vurgusu
- `screenshot-01..04.png` — 1080×1920, 24-bit RGB (alfa yok), uygulamanın gerçek ekranlarından alınmış

Doğrulama (depa kökünden):

```powershell
python tool/play_store_asset_dogrula.py
```

Betik PNG IHDR başlığından genişlik/yükseklik/bit derinliği/renk kanalını okur, dosya
boyutunu kontrol eder ve en az 4 ekran görüntüsü arar. Çıktı "TAMAM" değilse Play Console
yüklemesine geçmeyin.

## 4) App Links / assetlinks.json — Play App Signing sonrası

Bu PR'da `public_web/public/.well-known/assetlinks.json` içine **sahte SHA-256 yazılmadı**.
Yapılacak adım:

1. AAB'yi Play Console → App integrity → **App signing** sayfasına yükleyin.
2. "App signing key certificate" altındaki **SHA-256 fingerprint** değerini kopyalayın
   (upload key parmak izi değil; Play App Signing sertifikası).
3. `public_web/public/.well-known/assetlinks.json` dosyasını oluşturun; `relation`
   `"delegate_permission/common.handle_all_urls"`, `target.namespace` `"android_app"`,
   `package_name` `"com.vixrex.app"`, `sha256_cert_fingerprints` dizisine gerçek parmak izini yazın.
4. AndroidManifest'te ilgili activity intent-filter'ında `android:autoVerify="true"`
   bulunmalı; eklenmeden önce bu rehberin kapsamı dışıdır.
5. Yayından sonra `https://vixrex.com/.well-known/assetlinks.json` adresinin HTTP 200
   döndüğünü ve parmak izinin Console ile aynı olduğunu ölçün.

## 5) APK / AAB derleme

Yer (sürüm dosyaları `build/app/outputs/` altındadır):

```powershell
flutter build apk --release
flutter build appbundle --release
```

CI'daki `Android APK` işi `android/key.properties` + upload keystore secret'larıyla aynı
çıktıyı üretir ve `dist/` altına APK + AAB + SHA-256 özetleri koyar. Play Console'a
yüklenecek dosya **AAB**'dir; yerel derleme upload anahtarıyla imzalanır, Play App
Signing sertifikası Console tarafından eklenir.

Geri alma: bu işin commit'i tek bir commit ise `git revert <sha>`; dal hâlâ açıksa dal silinir.
