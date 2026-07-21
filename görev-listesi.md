# Vixrex Görev Listesi

## ✅ Tamamlandı

- [x] Google ile Giriş Yap — Web (OAuth 2.0 + Supabase)
- [x] Android Gradle `google-services` plugin kurulumu
- [x] iOS `Info.plist` Reversed Client ID
- [x] Supabase URL Configuration (`localhost:5000` + Vercel)
- [x] Google Cloud Console authorized origins ve redirect URI
- [x] İmzalı APK üretim altyapısı
- [x] GitHub Actions Node.js 24 güncellemesi
- [x] AAB (.aab) derleme, CI imza doğrulama ve artifact paketi hazırlığı

---

## 🔲 Bekleyen Görevler

### Play Store & Faz 2 (Internal Testing)
- [ ] Play Console'da `com.xpodiumyours.vixrex` uygulamasını oluştur (Furkan)
- [ ] Play App Signing'i upload keystore (`295af3e2...`) ile etkinleştir
- [ ] İlk AAB'yi Play Console Internal Testing kanalına yükle
- [ ] Play Console'dan Play App Signing SHA-1 ve SHA-256 parmak izlerini al

### Android Google Girişi (OAuth Entegrasyonu)
- [ ] Google Cloud Console / Firebase'de Android OAuth Client ID'ye Play App Signing SHA-1 ve SHA-256 ekle
- [ ] Güncel `google-services.json` dosyasını projeye indir
- [ ] İkinci AAB'yi (daha yüksek `versionCode` ile) ürettir ve Play üzerinden güncelleme/Google Sign-In testini geç

### Genel
- [ ] Production'da Google girişi uçtan uca kabul testi

