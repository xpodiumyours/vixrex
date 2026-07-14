# Mobil APK güncelleme — Cursor uygulama planı

> **Sahip isteği:** Telefon APK'sının unutulan elle build sürecini kaldır.
> **Durum:** Faz 1 yerel kapıları geçti — PR, iki imzalı CI build ve telefon kabulü bekliyor.
> **Tarih:** 15 Temmuz 2026
> **Dal:** `feat/android-ci-apk`

## 1. Hedef ve gerçek başarı tanımı

Mobil kod main dalına girdiğinde GitHub Actions, indirilebilir ve kalıcı aynı
anahtarla imzalanmış Android APK üretecek. Başarı yalnız “APK oluştu” değildir:

1. Birinci CI APK telefona kurulur.
2. İkinci bir commit/run daha yüksek versionCode ile yeni APK üretir.
3. İkinci APK, birincisi kaldırılmadan üzerine kurulur.
4. Kullanıcı oturumu ve yerel veri korunur.
5. Kritik Vixrex akışı gerçek cihazda geçer.

Web/Vercel deploy akışı değişmez. iOS ve Play Store yayını Faz 1 kapsamında değildir.

## 2. Ön doğrulama — Cursor kod yazmadan önce

- [x] PROJECT_RULES.md, SON_DURUM.md, AGENTS.md ve TARAMA.md tamamen okundu.
- [x] Çalışma ağacı listelendi; kapsam dışı dosyaya dokunulmadı.
- [x] Yeni çalışma `feat/android-ci-apk` dalında yapıldı.
- [x] Paket kimliği com.xpodiumyours.vixrex doğrulandı; değiştirilmedi.
- [x] Araç sürümü Flutter 3.44.4 / Dart 3.12.2 doğrulandı.
- [x] Furkan kalıcı upload keystore, güvenli yedek ve altı GitHub Actions Secret adımını tamamladı.

## 3. Değişmez güvenlik ve imzalama kararları

### 3.1 Kalıcı anahtar Faz 1'den itibaren zorunlu

android/app/build.gradle.kts şu anda key.properties bulunmazsa release build'i
debug anahtarıyla imzalıyor. CI için bu davranış kabul edilmez; geçici runner
anahtarı değişebilir ve APK bir öncekinin üzerine kurulamaz.

Cursor:

1. Furkan'ın açık katılımıyla tek bir upload keystore oluşturulması için adım adım yönlendirir.
2. Keystore'u veya şifreleri Git'e, artifact'a, loga ya da sohbet çıktısına yazmaz.
3. Keystore'un güvenli çevrimdışı yedeği alınmadan devam etmez.
4. Release build'in key yoksa debug'a düşmesini kaldırır; anlaşılır hata ile build'i durdurur.
5. Debug build davranışını değiştirmez.

GitHub Actions secret adları:

| Secret | İçerik |
|---|---|
| ANDROID_KEYSTORE_BASE64 | Keystore dosyasının base64 karşılığı |
| ANDROID_KEYSTORE_PASSWORD | Store şifresi |
| ANDROID_KEY_ALIAS | Alias; hedef vixrex |
| ANDROID_KEY_PASSWORD | Key şifresi |
| SUPABASE_URL | Mobil Supabase URL |
| SUPABASE_PUBLISHABLE_KEY | İstemci publishable/anon anahtarı |

GitHub Variable veya workflow sabiti:

- PUBLIC_SITE_URL=https://vixrex-public.vercel.app

İsteğe bağlı, yalnız ürün davranışı kullanıyorsa:

- ONESIGNAL_APP_ID
- SENTRY_DSN
- INSTAGRAM_SYNC_ENABLED=false (hazır değilse)

SUPABASE_SERVICE_ROLE_KEY, Meta client secret veya başka server-only secret
Flutter APK'ya kesinlikle gömülmez.

### 3.2 Sürüm stratejisi

Mevcut sürüm 1.0.0+1. Dağıtılan her APK'nın versionCode değeri öncekinden büyük olmalıdır.

Faz 1 CI kuralı:

- versionName: pubspec.yaml içindeki insan sürümü (1.0.0).
- versionCode: workflow içinde 10000 + GITHUB_RUN_NUMBER.
- Workflow adı korunur; sayaç sıfırlanacaksa önce son build numarası kontrol edilir.
- Artifact adında sürüm, build numarası ve kısa commit SHA bulunur.

Play Internal Testing'e geçerken son versionCode kaydedilir ve Play'e yüklenen
her AAB bu değerden büyük olur.

## 4. Faz 1 — GitHub Actions APK

### 4.1 Cursor'un dosya kapsamı

- .github/workflows/android-apk.yml — yeni workflow
- android/app/build.gradle.kts — release key yoksa fail-fast
- Gerekirse android/key.properties.template — yalnız örnek alan adları
- MOBIL_APK_GUNCELLEME.md, TARAMA.md, SON_DURUM.md — durum/kanıt

UI, route, public web, Supabase şeması ve generated plugin dosyaları kapsam dışıdır.

### 4.2 Workflow tetikleyicileri

- workflow_dispatch — Furkan elle çalıştırabilsin.
- push: main yalnız şu mobil yollarında:
  - lib/**
  - assets/**
  - android/**
  - pubspec.yaml
  - pubspec.lock
  - .github/workflows/android-apk.yml

Doküman-only commit APK dakikası tüketmez. Workflow izni contents: read olur.
Aynı ref için eski koşuyu iptal edecek concurrency grubu eklenir.

### 4.3 Sabit araç zinciri

- Runner: ubuntu-latest
- Java: Temurin 17
- Flutter: tam sürüm 3.44.4, stable channel, cache açık
- Paket kurulumu: flutter pub get

“En son stable” kullanılmaz; sürüm yükseltme ayrı ve testli görevdir.

### 4.4 Build öncesi kapılar

Sırayla:

1. Gerekli secret'ların boş olmadığını değerleri yazdırmadan kontrol et.
2. dart analyze
3. flutter test test/critical_flow_smoke_test.dart test/architecture_routing_contract_test.dart test/public_site_config_test.dart
4. Keystore'u secret'tan geçici dosyaya çöz.
5. android/key.properties dosyasını loga şifre basmadan oluştur.
6. Hesaplanan BUILD_NUMBER değerini GitHub özetine yaz.

Bir kapı kırılırsa APK yüklenmez ve görev tamamlandı sayılmaz.

### 4.5 Build ve artifact

Build şu değerlerle yapılır:

- flutter build apk --release
- --build-name=1.0.0
- --build-number=(10000 + GITHUB_RUN_NUMBER)
- --dart-define=SUPABASE_URL=(secret)
- --dart-define=SUPABASE_PUBLISHABLE_KEY=(secret)
- --dart-define=PUBLIC_SITE_URL=https://vixrex-public.vercel.app

Secret değerleri loga açık basılmaz.

Üretilecekler:

- build/app/outputs/flutter-apk/app-release.apk
- APK SHA-256 checksum dosyası
- Artifact adı: vixrex-android-(version)-(build)-(short-sha)
- Retention: 14 gün

Artifact için actions/upload-artifact@v4 kullanılır. İş sonunda if: always()
ile geçici android/key.properties ve keystore dosyası silinir.

## 5. Faz 1 kabul kapısı — iki ardışık build zorunlu

Yerel doğrulama (15 Temmuz 2026):

- [x] `dart analyze` → `No issues found`.
- [x] Üç hedefli test dosyası → 15/15 test geçti.
- [x] Flutter 3.44.4 ile debug APK derlendi.
- [x] Kotlin 2.2 uyumu için `sentry_flutter` 9.3.0'a sabitlendi; debug derleme tekrar geçti.
- [x] Git durumunda yalnız planlanan yedi dosya var; keystore / `key.properties` takip edilmiyor.
- [ ] İmzalı release APK yalnız GitHub Actions üzerinde doğrulanacak.

- [ ] Workflow manuel çalıştırıldı ve yeşil.
- [ ] Analyze ve üç hedefli test dosyası geçti.
- [ ] Birinci APK indirildi; paket adı ve versionCode doğrulandı.
- [ ] İmza sertifikası SHA-256 parmak izi kaydedildi (secret değildir).
- [ ] Birinci APK telefona kuruldu ve giriş yapıldı.
- [ ] İkinci run daha büyük versionCode üretti.
- [ ] İkinci APK'nın sertifika parmak izi birinciyle aynı.
- [ ] İkinci APK, uygulama kaldırılmadan üzerine kuruldu.
- [ ] Oturum ve yerel veri korundu.
- [ ] Keşfet → kendi vitrin → Düzenle → Vitrinim akışı geçti.
- [ ] Workflow log/artifact içinde keystore veya şifre bulunmadı.
- [ ] Generated plugin veya kapsam dışı dosya commit'e girmedi.
- [ ] Furkan ekran görüntüsüyle “geç” dedi.

Bu maddelerin tamamı kanıtlanmadan Faz 1 tamamlandı yapılmaz.

## 6. Furkan'ın telefon testi

1. GitHub → Actions → Android APK → son yeşil run.
2. Artifact bölümünden Vixrex APK paketini indir.
3. İlk APK'yı kur ve Vixrex hesabına giriş yap.
4. İkinci workflow run'ından yeni APK'yı indir.
5. Eski uygulamayı kaldırmadan yeni APK'yı kur.
6. Telefon “uygulama güncellensin mi?” demeli; imza uyuşmazlığı vermemeli.
7. Uygulamayı aç; oturum ve yerel kaydın durduğunu kontrol et.
8. Keşfet → kendi kartın → Düzenle; Vitrinim açılmalı.
9. Sonucu ekran görüntüsüyle onayla.

“Eski uygulamayı kaldır ve yeniden kur” güncelleme testini geçirmez.

## 7. Faz 2 — Play Internal Testing

Faz 1 tamamlanmadan başlanmaz.

- Play Console uygulaması ve Play App Signing kurulur.
- Aynı upload key güvenli biçimde kullanılır.
- flutter build appbundle --release ile AAB üretilir.
- VersionCode son APK build numarasından büyük tutulur.
- İlk dilimde CI artifact + elle Internal yükleme tercih edilir.
- Furkan ve en az bir testçi Internal linkten güncelleme alır.
- Play dağıtımı başladıktan sonra test güncellemeleri Play üzerinden yürütülür.

## 8. Cursor'a yasaklar

- Keystore/şifreyi kendi başına üretip kullanıcıya göstermeden geçmek.
- Keystore, key.properties veya secret'ı commit etmek.
- Release build'de debug signing fallback bırakmak.
- Her run aynı versionCode ile APK üretmek.
- Flutter latest/stable driftine izin vermek.
- Başarısız testleri ignore etmek veya continue-on-error kullanmak.
- Telefon üstüne-kurma testi olmadan tamamlandı demek.
- Web/Vercel, UI, route veya generated plugin dosyalarını bu PR'a karıştırmak.

## 9. Cursor teslim raporu

1. Değişen dosyaların kısa listesi.
2. GitHub Actions run bağlantısı.
3. Artifact adı, versionName/versionCode ve commit SHA.
4. İki APK'nın aynı sertifika parmak izi kanıtı.
5. Analyze/test sonuçları.
6. Telefon üstüne-kurma ve oturum koruma sonucu.
7. Dokunulmaz alanlara etkisi: beklenen “yok”; varsa açık risk.

## 10. Durum

| Faz | Durum |
|---|---|
| Plan doğrulaması | **tamamlandı** |
| Faz 1 — workflow + Gradle fail-fast | **yerel kapılar geçti — PR/CI bekliyor** |
| Faz 1 — iki build/telefon kabulü | bekliyor (keystore + Secrets şart) |
| Faz 2 — Play Internal AAB | bekliyor |
| Faz 3 — minimum sürüm uyarısı | ertelendi |
