# Vixrex Project Rules

Bu dosya, prompt ne kadar kısa veya belirsiz olursa olsun bu repoda çalışan bütün
kod ajanları için bağlayıcıdır. Kullanıcının doğru teknik terimleri bilmesini
bekleme; mevcut mimariyi incelemek ve çelişki üretmemek ajanın sorumluluğudur.

## 0. Zorunlu okuma ve kural hiyerarşisi

Her AI ajanı herhangi bir dosyaya dokunmadan önce sırasıyla şunları tamamen okur:

1. [`PROJECT_RULES.md`](PROJECT_RULES.md) — kullanıcı anayasası, çalışma biçimi ve
   dokunulmaz alanlar için en üst kuraldır.
2. Varsa `SON_DURUM.md` — yalnız güncel oturum devridir.
3. Bu `AGENTS.md` — güncel teknik mimari ve repo sözleşmesidir.
4. İlgili alt dizindeki `AGENTS.md` ve görevle eşleşen
   `.cursor/skills/*/SKILL.md` / `.agents/skills/*/SKILL.md` dosyaları — yalnız
   ek kural koyabilir, üst kuralları gevşetemez. Asistan işlerinde
   [`.cursor/skills/vixrex-asistan-bagla/SKILL.md`](.cursor/skills/vixrex-asistan-bagla/SKILL.md)
   **her adımda** okunur ve uygulanır (plan, tarama, kod, test, rapor).

`PROJECT_RULES.md`, Furkan'ın açık onayı olmadan silinemez, yeniden adlandırılamaz,
kısaltılamaz veya etkisizleştirilemez. Kullanıcı anayasası ile güncel teknik bilgi
arasında çelişki görülürse ajan sessizce seçim yapmaz; değişiklikten önce Furkan'a
çelişkiyi açıkça bildirir ve yön ister.

### 0.1 Zorunlu uyma ve kaynak bütçesi

`PROJECT_RULES.md` bölüm **3.2 AI kaynak ve token disiplini**, okuma listesinin
bağlayıcı parçasıdır. Ajanın "Kurallar okundu" yazması uyum kanıtı değildir;
çalışma sırasında aşağıdaki kapılar zorunludur:

- İlk araç çağrısından önce en küçük kanıt bütçesini belirle: bir hedefli tarama,
  bir küçük değişiklik ve bir orantılı doğrulama turu.
- Yeni bir değişiklik veya yeni hata kanıtı yoksa aynı komutu tekrar çalıştırma.
- Uzak CI/deploy işini başlattıktan sonra bekleme veya periyodik polling yapma;
  run kimliğini bildirip kontrolü kullanıcıya bırak.
- Tam log yerine önce başarısız adımın en fazla 80 satırlık hedefli kesitini oku.
- Bu bütçeyi aşmak gerekiyorsa devam etmeden önce Furkan'a maliyeti ve gerekçeyi
  söyleyip açık onay al.
- Kural ihlali fark edilirse yeni işlem başlatma; durumu kısa biçimde devret.

## 1. Değişmez mimari sahiplik

Aşağıdaki sahiplik tablosu bağlayıcı mimari karardır.

| Yüzey | Tek sahibi | Kural |
|---|---|---|
| Mobil işletme uygulaması | Flutter | Public vitrin uygulama içinde `PublicVitrinScreen` ile açılır. |
| Web editör ve yönetim | Flutter | App host public müşteri HTML'i render etmez. |
| Web müşteri vitrini | Next.js `public_web` | `/v/:slug` ve alt rotaların tek web renderer'ıdır. |
| SEO, canonical, sitemap, robots | Next.js `public_web` | İkinci bir SEO shell veya API fallback oluşturulmaz. |

Aktif geçici originler:

- App: `https://vixrex-app.vercel.app`
- Public: `https://vixrex-public.vercel.app`

## 2. Paralel yol oluşturma yasağı

- Aynı kullanıcı akışı için ikinci renderer, router, API shell, rewrite veya
  sessiz fallback ekleme.
- Yeni uygulama bir eski yolun yerini alıyorsa, aynı task içinde eski yolu ve
  ölü referansları kaldır. Geçiş tamamlanmadan task'ı tamamlandı sayma.
- Web ve native davranışını açık platform koşuluyla ayır; mobil kullanıcıyı
  public web'e gönderme.
- Geçici deploy/domain hatasını yeni kalıcı kod yoluyla yamama. Önce mevcut
  host, route ve environment sahipliğini doğrula.
- Aktif ürün adı `Vixrex`tir. Arşiv/deneme kaynaklarını açık kullanıcı talebi
  olmadan yeniden adlandırma veya üretim akışına bağlama.

## 3. Zorunlu çalışma sırası

1. Önce `rg` ile mevcut ekran, route, service, fallback ve domain kullanımını ara.
2. Değişiklikten önce tek sahibin kim olduğunu yazılı mimariyle karşılaştır.
3. En küçük çözümü uygula; kapsam dışı UI veya özellik çalışması ekleme.
4. Değişen davranış için otomatik sözleşme testi ekle veya mevcut testi güncelle.
5. Eski yolun gerçekten kaldırıldığını repo taramasıyla doğrula.
6. Yerel test/build, ardından gerekiyorsa preview ve canlı kabul testi çalıştır.
7. Kanıt tamamlanmadan plan kutusunu `[x]` yapma ve “tamamlandı” deme.

## 4. Public vitrin değişiklik kapısı

Public vitrin, route, domain, Vercel veya navigasyon değişikliğinde en az şunlar
geçmelidir:

```powershell
flutter test test\architecture_routing_contract_test.dart test\public_site_config_test.dart
dart analyze
npm.cmd --prefix public_web run build
```

Ayrıca şu davranışlar doğrulanır:

- App host `/v/*`, `/sitemap.xml` ve `/robots.txt` isteklerini public hosta
  redirect eder; app host bunları rewrite/render etmez.
- Alt route ve query string korunur.
- Public `/v/:slug` Next.js HTML üretir ve Flutter bootstrap içermez.
- Native vitrin akışı Flutter içinde kalır.

Mevcut lint veya test borcu yeni hata eklemek için gerekçe değildir. Kapsam dışı
önceden var olan hata açıkça raporlanır; gizlenmez ve yanlışlıkla “geçti” denmez.

## 5. Plan sapması kontrolü

Her değişiklikten önce ve sonra sor:

1. Tek sahipliği güçlendiriyor mu?
2. Yeni bir paralel yol veya fallback yaratıyor mu?
3. Mobil kullanıcıyı uygulama dışına çıkarıyor mu?
4. Değiştirilen eski yol aynı task içinde emekli edildi mi?
5. Kod, test, README ve mimari belge aynı davranışı anlatıyor mu?

2 veya 3 için cevap “evet”, 4 veya 5 için cevap “hayır” ise değişikliği durdur;
mimari karar netleşmeden uygulama yapma.

## 6. Alt dizin kuralları

Bir alt dizinde başka `AGENTS.md` varsa bu kök kurallara ek olarak uygulanır.
Özellikle `public_web/AGENTS.md`, Next.js sürümüne ait yerel dokümantasyonu
okumayı zorunlu kılar.

## 7. Android üretim imzası sözleşmesi

- Tek Android release hattı `.github/workflows/android-apk.yml` dosyasıdır;
  paralel bir imzalama veya dağıtım yolu oluşturma.
- Bütün üretim APK/AAB dosyalarını mevcut kalıcı upload keystore ile imzala.
  Beklenen upload sertifikası SHA-256 değeri:
  `295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24`.
- Keystore, şifre veya beklenen sertifika yoksa ya da uyuşmuyorsa işlemi
  durdur; yeni anahtar üretme, anahtar döndürme veya debug imzasına düşme.
- Her release'te package adını, artan `versionCode` değerini, upload sertifika
  parmak izini ve artifact checksum'unu doğrula.
- Play App Signing sonrasında upload sertifikası ile Google'ın app signing
  sertifikasını iki ayrı kimlik olarak kaydet ve raporla.
- Ayrıntılı kabul kapıları ve sonraki işler için
  `MOBIL_APK_GUNCELLEME.md` belgesini uygula.

## 8. Bulgu ve doğrulama sözleşmesi

- Ön taramada bulunan kapsam dışı sorunu aynı değişikliğe ekleme; yerini,
  kanıtını, etkisini ve durumunu raporla, Furkan onayından sonra ayrı küçük iş yap.
- Bir bulguya `düzeltildi` denebilmesi için ilgili test/build/canlı kabul kanıtı
  bulunmalıdır. Kanıt yoksa en fazla `açık` veya `doğrulandı` kullan.
- Yeni regresyonu eski borçtan ayır; mimari, kalite, UI ve güvenlik kapsamlarını
  tek PR'da sebepsiz birleştirme.
- Geçici bulgular için yeni borç/teşhis Markdown dosyaları üretme. İlgili mevcut
  alan belgesini veya Furkan'ın onayladığı GitHub işini kullan.
- Doküman-only değişiklikte `git diff --check`, kırık referans taraması ve sabit
  dosya biçimi kontrolü uygula. Kod değişikliğinde ilgili platform kapılarını da
  çalıştır; alakasız uzun testleri yalnız alışkanlık olduğu için çalıştırma.
- Tamamlanmış kayıtları aktif repo defterinde sonsuza kadar çoğaltma; kalıcı
  kararları kurallara taşı, geçmiş kanıtı Git commit/PR kayıtlarında bırak.

## Cursor Cloud specific instructions

Bu bölüm, güncelleme betiği (bağımlılık kurulumu) çalıştırıldıktan sonra başlayan
gelecekteki cloud agent oturumları içindir. Standart komutlar `README.md`
"Kontrol listesi" bölümünde ve `public_web/package.json` içindedir; burada yalnız
Cloud ortamına özgü, az bilinen davranışlar özetlenir.

- **Platform farkı:** `README.md` komutları Windows/PowerShell içindir (`npm.cmd`,
  ters bölü `` ` ``). Cloud (Linux) ortamında `npm`, `flutter`, `dart` komutlarını
  doğrudan; satır devamı için `\` kullan.
- **Flutter SDK:** Snapshot'ta `~/flutter` altında kuruludur (stable, Dart >=3.7.2)
  ve PATH `~/.bashrc` içine eklenmiştir. Login/interaktif kabukta `flutter`
  doğrudan çalışır; script içinde garanti gerekiyorsa `"$HOME/flutter/bin/flutter"`
  kullan.
- **Backend = hosted Supabase; yerel Supabase/Docker YOK.** `supabase/config.toml`
  bulunmaz, `supabase start` akışı beklenmez. Gerçek backend akışları (giriş,
  yayınlama, Keşfet listesi, `/v/:slug` verisi) yalnız Secrets panelinden gelen
  `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` (public_web için ayrıca
  `SUPABASE_SERVICE_ROLE_KEY`) ile çalışır.
- **Secret olmadan da uygulama açılır (beklenen davranış):** `lib/main.dart`,
  Supabase config yoksa init'i atlar ve çökmеz. İstemci-taraflı akışlar (landing,
  `Vitrinim` editörü, işletme adından otomatik `/v/:slug` slug üretimi ve canlı
  önizleme) backend olmadan çalışır. Bu durumda `Keşfet` "Vitrinler yüklenemedi"
  uyarısı gösterir — bu bir hata değil, Supabase secret eksikliğinin sonucudur.
- **public_web secret olmadan boot eder:** `src/lib/supabase.ts` placeholder
  fallback kullanır; `npm run dev`/`build`/`lint`/`test` secret olmadan geçer.
  Ancak `/v/[slug]` gerçek veriyi ancak geçerli Supabase ile render eder.
- **Yerel çalıştırma (dev):**
  - public_web: `npm --prefix public_web run dev` → `http://localhost:3000`
  - Flutter web: `flutter run -d web-server --web-port 8080 --dart-define=PUBLIC_SITE_URL="http://localhost:3000"` → `http://localhost:8080` (masaüstü tarayıcı için `-d chrome` da kullanılabilir).
- Flutter için `--dart-define` değerleri sıcak yeniden yükleme (hot reload) ile
  değişmez; `SUPABASE_URL` gibi define'ları değiştirdiğinde `flutter run`'ı
  yeniden başlat.
