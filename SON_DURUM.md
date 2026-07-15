TARİH: 15 Temmuz 2026
BUGÜN YAPILAN: Public kök navigasyonu PR #23 ve Explore test kararlılığı PR #24 ile main'e birleştirildi; Play AAB kodu güncel main üzerinde 20/20 test ve analiz 0 hata geçti.
YARIM KALAN: AAB dalı GitHub Actions kabulü; Play Console uygulama ve Play App Signing kurulumu; iki Internal Testing sürümü ve gerçek cihaz güncelleme kabulü.
SIRADAKİ ADIM: codex/play-internal-aab dalında workflow_dispatch çalıştır ve artifact package/versionCode/checksum/upload sertifikasını doğrula; Play işlemlerini Furkan ile yap.
DOKUNULAN DOSYALAR: .github/workflows/android-apk.yml, test/android_apk_workflow_contract_test.dart, MOBIL_APK_GUNCELLEME.md, SON_DURUM.md
DİKKAT: Yeni keystore veya paralel release hattı oluşturma; AAB yalnız mevcut kalıcı upload sertifikası SHA-256 295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24 ile kabul edilir.
