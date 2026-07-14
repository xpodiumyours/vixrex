TARİH: 15 Temmuz 2026
BUGÜN YAPILAN: Keystore/yedek ve altı GitHub Secret hazırlandı; Flutter 3.44.4 + Sentry 9.3.0 debug APK geçti; dart analyze hatasız ve üç hedefli dosyada 15/15 test yeşil.
YARIM KALAN: Commit/PR/merge; iki imzalı CI APK'nın sürüm ve imza kontrolü; telefonda üstüne-kurma, oturum ve kritik akış kabulü.
SIRADAKİ ADIM: Yedi dosyalık APK değişikliğini tek commit ile feat/android-ci-apk dalına kaydet, GitHub'a gönder ve PR aç.
DOKUNULAN DOSYALAR: .github/workflows/android-apk.yml, android/app/build.gradle.kts, android/key.properties.template, pubspec.yaml, pubspec.lock, MOBIL_APK_GUNCELLEME.md, SON_DURUM.md
DİKKAT: Release debug fallback yoktur; keystore/şifre Git'e veya loga giremez; gerçek imzalı APK ve telefon kabulü olmadan Faz 1 tamamlandı sayılmaz.
