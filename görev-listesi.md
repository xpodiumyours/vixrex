# Vixrex Görev Listesi

## ✅ Tamamlandı

- [x] Google ile Giriş Yap — Web (OAuth 2.0 + Supabase)
- [x] Android Gradle `google-services` plugin kurulumu
- [x] iOS `Info.plist` Reversed Client ID
- [x] Supabase URL Configuration (`localhost:5000` + Vercel)
- [x] Google Cloud Console authorized origins ve redirect URI
- [x] İmzalı APK üretim altyapısı
- [x] GitHub Actions Node.js 24 güncellemesi

---

## 🔲 Bekleyen Görevler

### Android Google Girişi
- [ ] Google Cloud Console'da **Android OAuth Client ID** oluştur
  - Package: `com.xpodiumyours.vixrex`
  - SHA-256 (production): `295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24`
  - SHA-1 (debug): `42:42:DA:51:DD:D2:0D:8A:AF:7C:27:54:D0:EB:73:CE:B0:DF:82:8B`
- [ ] `google-services.json`'a Android Client ID'yi ekle

### Play Store
- [ ] Play Console uygulama kurulumu
- [ ] Play App Signing kurulumu
- [ ] AAB branch'ini (`codex/play-internal-aab`) `main`e birleştir
- [ ] Internal Testing'e AAB yükle
- [ ] İki sürümlü gerçek cihaz güncelleme testi

### Genel
- [ ] Production'da Google girişi uçtan uca kabul testi
