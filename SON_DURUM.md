TARİH: 15 Temmuz 2026
BUGÜN YAPILAN: Yerel analyze ve 15/15 test geçti; APK değişiklikleri feat/android-ci-apk dalına gönderildi; taslak PR #18 açıldı ve iki Vercel preview kontrolü yeşil.
YARIM KALAN: PR #18 birleşme onayı; iki imzalı CI APK'nın sürüm ve imza kontrolü; telefonda üstüne-kurma, oturum ve kritik akış kabulü.
SIRADAKİ ADIM: Furkan onayıyla PR #18'i main'e birleştir; ilk Android APK workflow'unu ve imzalı artifact'ı doğrula.
DOKUNULAN DOSYALAR: .github/workflows/android-apk.yml, android/app/build.gradle.kts, android/key.properties.template, pubspec.yaml, pubspec.lock, MOBIL_APK_GUNCELLEME.md, SON_DURUM.md
DİKKAT: Release debug fallback yoktur; keystore/şifre Git'e veya loga giremez; gerçek imzalı APK ve telefon kabulü olmadan Faz 1 tamamlandı sayılmaz.
