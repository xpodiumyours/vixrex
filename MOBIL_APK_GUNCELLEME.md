# Mobil APK güncelleme — Cursor uygulama planı

> **Sahip isteği:** Telefon APK'sının unutulan elle build sürecini kaldır.
> **Durum:** Faz 1 tamamlandı — iki imzalı CI build ve gerçek telefon üstüne-kurma kabulü geçti.
> **Tarih:** 15 Temmuz 2026
> **Dal:** `main` — PR #18, merge `cc3ec16`

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

- [x] PROJECT_RULES.md, SON_DURUM.md ve AGENTS.md tamamen okundu.
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
- MOBIL_APK_GUNCELLEME.md ve SON_DURUM.md — durum/kanıt

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
- [x] İmzalı release APK GitHub Actions üzerinde doğrulandı.

- [x] İlk push run'ı ve ikinci manuel workflow run'ı yeşil.
- [x] Analyze ve üç hedefli test dosyası iki CI run'ında geçti.
- [x] Birinci APK indirildi; `com.xpodiumyours.vixrex`, `1.0.0 (10001)` doğrulandı.
- [x] İmza sertifikası SHA-256 parmak izi kaydedildi (secret değildir).
- [x] Birinci APK telefona kuruldu ve giriş yapıldı.
- [x] İkinci run `versionCode 10002` üretti.
- [x] İkinci APK'nın sertifika parmak izi birinciyle aynı.
- [x] İkinci APK, build 10001 kaldırılmadan üzerine kuruldu.
- [x] Oturum ve yerel veri korundu.
- [x] Keşfet → kendi vitrin → Düzenle → Vitrinim akışı geçti.
- [x] Workflow log/artifact içinde keystore veya şifre bulunmadı.
- [x] Generated plugin veya kapsam dışı dosya commit'e girmedi.
- [x] Furkan “akış düzgün çalıştı” diyerek gerçek cihaz kabulünü verdi.

### 5.1 Kabul kanıtı

| Run | Artifact | versionCode | APK SHA-256 | Sertifika SHA-256 |
|---|---|---:|---|---|
| [29370463146](https://github.com/xpodiumyours/vixrex/actions/runs/29370463146) | `vixrex-android-1.0.0-10001-cc3ec16` | 10001 | `1a08d71cde43e172752722b162ea0e527a462aa7c40198e46ab1b847d6e9df48` | `295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24` |
| [29371434810](https://github.com/xpodiumyours/vixrex/actions/runs/29371434810) | `vixrex-android-1.0.0-10002-cc3ec16` | 10002 | `3e9649a55b9408309584572e23a6743d95e144d9c7adfa1928086d1a8f9e6c64` | `295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24` |

Telefondaki eski demo APK farklı imzalı olduğu için build 10001 ilk denemede üzerine
kurulamadı. Kullanıcının özel yerel ayarı olmadığı doğrulandı; eski demo bir kez
kaldırılıp kalıcı üretim anahtarlı build 10001 kuruldu. Asıl güncelleme kabulü olan
`10001 → 10002` geçişi uygulama silinmeden başarıyla tamamlandı.

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
| Faz 1 — workflow + Gradle fail-fast | **tamamlandı** |
| Faz 1 — iki build/telefon kabulü | **tamamlandı** |
| Faz 2 — Play Internal AAB | bekliyor |
| Faz 3 — minimum sürüm uyarısı | ertelendi |

## 11. Onay bekleyen iki gelecek iş

Bu iki iş aynı PR'a konmaz ve aşağıdaki sırayla yürütülür. Birinci iş yeşile
dönmeden ikinci iş için kod veya Play Console değişikliği yapılmaz.

### 11.A T-010 — GitHub Actions Node.js 24 major bakımı

**Amaç:** Çalışan APK hattının davranışını değiştirmeden Node.js 20 geçiş
uyarılarını kaldırmak.

15 Temmuz 2026 tarihli resmî action belgelerine göre hedefler:

| Mevcut | Hedef |
|---|---|
| `actions/checkout@v4` | `actions/checkout@v7` |
| `actions/setup-java@v4` | `actions/setup-java@v5` |
| `actions/upload-artifact@v4` | `actions/upload-artifact@v6` |

Uygulama sırası:

1. Ayrı bir `codex/` bakım dalı aç.
2. Yalnız `.github/workflows/android-apk.yml` içindeki bu üç `uses` major
   değerini değiştir. Trigger, permission, secret, Flutter/Java sürümü,
   versionCode hesabı, imzalama ve artifact içeriğine dokunma.
3. Dalda `workflow_dispatch` çalıştır.
4. Analyze, test, release APK, checksum ve imza doğrulama adımlarının tamamının
   yeşil olduğunu kontrol et.
5. Artifact içindeki package adını, artan `versionCode` değerini ve upload
   sertifikası SHA-256 değerini doğrula. Beklenen sertifika:
   `295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24`.
6. Log ve annotation'larda Node.js 20 uyarısının kalmadığını ve secret
   sızıntısı olmadığını doğrula.
7. Küçük bir PR aç, birleştir ve `main` run'ının da yeşil olduğunu doğrula.
8. Kanıt bağlantılarını bu belgenin §11.A sonuç bölümüne ekleyip T-010'u
   `düzeltildi` olarak kaydet; `SON_DURUM.md` dosyasını altı satır kuralıyla
   güncelle.

Tamamlanma kapısı:

- Yalnız üç action major'u değişmiş olmalı.
- Dal ve `main` run'ı yeşil olmalı.
- APK'nın package, versionCode, checksum ve kalıcı upload imzası doğrulanmalı.
- Uygulama kodu değişmediği için telefon kabul testi tekrarlanmaz; imza/package
  doğrulaması başarısızsa iş tamamlanmış sayılmaz.

### 11.B Faz 2 — Play Internal Testing ve AAB

**Ön koşullar:** T-010 kapanmış olmalı. Play geliştirici hesabı ücreti, hesap
türü, kimlik ve cihaz doğrulaması Furkan'ın katılımı ve açık onayı olmadan
başlatılmaz. Ajan ödeme yapmaz veya hesap açılışını kendi başına tamamlamaz.

Değişmezler:

- Paket kimliği `com.xpodiumyours.vixrex` olarak kalır.
- AAB, APK ile aynı kalıcı upload keystore kullanılarak imzalanır.
- AAB `versionCode` değeri işlem günündeki son Android CI build numarasından
  büyük olur; sabit `10002` eşiğine güvenilmez.
- Google Play'in güncel target API ve hesap koşulları işlem günü resmî
  belgelerden yeniden kontrol edilir.
- Ayrı bir imzalama hattı açılmaz. Mevcut
  `.github/workflows/android-apk.yml`, elle tetiklenen run'da imzalı AAB'yi de
  üretecek şekilde genişletilir; APK güvenlik kapıları korunur.

Uygulama sırası:

1. Furkan ile Play Console geliştirici hesabı türünü seç; ücret, kimlik ve
   gerekiyorsa gerçek Android cihaz doğrulamasını kullanıcı tamamlasın.
2. Play Console'da **Vixrex** uygulamasını oluştur ve paket kimliğini ilk
   yüklemeden önce tekrar doğrula.
3. Play App Signing'i etkinleştir. Kalıcı upload sertifikası ile Google'ın app
   signing sertifikasının SHA-256 parmak izlerini iki ayrı kayıt olarak sakla.
4. Mevcut workflow'a yalnız `workflow_dispatch` sırasında çalışan imzalı
   `flutter build appbundle --release` adımı ve AAB artifact'ı ekle. Otomatik
   Play yüklemesi ilk dilimde kurulmaz.
5. Analyze ve testleri çalıştır; AAB imzasını, package adını, versionCode'u,
   checksum'u ve upload sertifikasını CI içinde doğrula.
6. AAB'yi Furkan'ın katılımıyla elle Internal Testing kanalına yükle. Furkan ve
   en az bir ikinci Google hesabını testçi listesine ekle.
7. Play test bağlantısından temiz kurulum yap; giriş ve kritik akışı doğrula.
8. Daha yüksek versionCode ile ikinci Internal AAB üretip Play'e yükle. İlk
   kurulumu silmeden Play üzerinden güncelle ve oturum/yerel veri korunmasını
   doğrula.
9. İki release bağlantısını, upload ve app signing sertifika parmak izlerini,
   versionCode'ları ve cihaz kabul sonucunu bu belgeye kaydet.
10. Yalnız bu kanıtlar tamamlanınca Faz 2 durumunu `tamamlandı` yap.

Tamamlanma kapısı:

- İki Internal release aynı upload anahtarı ve artan versionCode ile kabul
  edilmiş olmalı.
- İkinci sürüm, birincisi kaldırılmadan Play üzerinden güncellenmiş olmalı.
- Play App Signing sertifikası ile upload sertifikası ayrı ayrı kaydedilmiş
  olmalı.
- Uygulama yalnız Internal Testing'de kaldığı sürece Data safety muafiyeti
  geçerlidir. Closed, open veya production öncesinde Data safety, gizlilik ve
  mağaza metinleri ayrı iş olarak tamamlanır.
- Yeni kişisel geliştirici hesabı production'a geçecekse Google'ın o tarihteki
  closed test şartı ayrıca uygulanır; bu şart Faz 2 Internal kabulünün parçası
  değildir.

## 12. Resmî dayanaklar

15 Temmuz 2026'da kontrol edilen birincil kaynaklar:

- GitHub Actions: [checkout](https://github.com/actions/checkout),
  [setup-java](https://github.com/actions/setup-java),
  [upload-artifact releases](https://github.com/actions/upload-artifact/releases)
- Flutter: [Android release ve app bundle](https://docs.flutter.dev/deployment/android)
- Google Play: [uygulama oluşturma ve release](https://support.google.com/googleplay/android-developer/answer/9859152?hl=tr),
  [Internal Testing](https://support.google.com/googleplay/android-developer/answer/9845334?hl=tr),
  [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=tr),
  [uygulama güncelleme koşulları](https://support.google.com/googleplay/android-developer/answer/9859350?hl=tr),
  [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=tr)

Sürüm ve Play politika koşulları değişebileceği için uygulama gününde bu
kaynaklar tekrar kontrol edilir.
