---
name: vixrex-islem-butcesi
description: Vixrex reposunda gereksiz araç çağrısı, tekrar tarama, kontrolsüz format, yerel test/build, GitHub/Vercel sorgusu, deploy ve APK işlemini engeller. Repo, dosya, kod, belge, inceleme, commit, push, PR, CI, Vercel, Supabase, APK veya release içeren her görevde görev başında kullan; kullanıcının "yalnız kontrol et", "yalnız commit/push", "test/build çalıştırma" gibi kapsam sınırlarını zorunlu kilit kabul et.
---

# Vixrex İşlem Bütçesi

## Ana kural

Görev başında bu dosyayı bir kez tamamen oku ve bütün adımlarda uygula. Aynı turda
dosyayı tekrar açma; yalnız bağlam sıkıştırıldıysa, dosya değiştiyse veya yeni görev
türü geldiyse yeniden oku.

Her işlemden önce şu cümleyi içinden tamamla:

> Bu işlemin çıktısı şu anki kararı değiştirecek: [somut karar].

Somut karar yazılamıyorsa işlemi yapma.

## 1. Görevi kilitle

İlk araç çağrısından önce görevi yalnız bir sınıfa koy ve izin verilen işlemleri kısa
biçimde kullanıcıya bildir.

| Görev sınıfı | İzin verilen varsayılan işlemler | Yasak varsayılan işlemler |
|---|---|---|
| İnceleme / teşhis | Bir hedefli `rg`, ilgili küçük dosya kesitleri, gerekirse tek durum sorgusu | Dosya değiştirme, format, test, build, commit, deploy |
| Belge / kural | Kullanıcının adını verdiği belgeler, küçük patch, `git diff --check`, hedefli referans taraması | Uygulama formatı, analyze, test, build, deploy |
| Kod değişikliği | Bir hedefli tarama, en küçük patch, değişen davranışa tek orantılı doğrulama | Repo geneli refactor, alakasız test/build, deploy |
| Yalnız commit / push | Bir `git status`, açık dosya listesiyle stage, commit, push | Format, analyze, test, build, `gh auth`, PR, Vercel sorgusu, deploy |
| Deploy / Vercel | Açıkça istenen tek deploy veya tek durum sorgusu | Kod değişikliği, yeniden deploy, polling |
| APK / release | Onaylı workflow ve release belgesindeki kapılar | Yerel paralel imzalama, yeni anahtar, normal push ile otomatik APK |

Kullanıcı görevi daraltırsa önceki geniş planı hemen bırak. “Daha güvenli olur”
gerekçesi kullanıcının açık kapsamını genişletmez.

## 2. İşlem izin tablosu

| İşlem | Yalnız şu durumda gerekli | Kilit |
|---|---|---|
| `rg` / dosya arama | Dosya veya çağrı yolu henüz bilinmiyorsa | Aynı kanıt için ikinci repo taraması yapma |
| Tam dosya okuma | Üst kural veya seçilen skill zorunluysa ya da küçük kesit kararı vermeye yetmiyorsa | Alakasız belge ve skill okuma |
| Format | Kullanıcı açıkça isterse veya değişen dosya biçim kapısını gerçekten geçemiyorsa | Yalnız açık değişen dosyalar; repo geneli format yasak |
| Analyze | Dart kodu değiştiyse ve yerel doğrulama isteniyorsa veya uzak CI bu kapıyı çalıştırmıyorsa | Commit/push-only görevinde çalıştırma |
| Hedefli test | Davranış değiştiyse ve son değişiklikten sonra aynı kanıt henüz alınmadıysa | Aynı testi değişiklik olmadan tekrar çalıştırma |
| Tam test paketi | Kullanıcı derin doğrulama isterse, büyük refactor varsa veya release kapısı açıkça gerektiriyorsa | Küçük değişiklikte alışkanlık için çalıştırma |
| Flutter / Next build | Build dosyası veya build davranışı değiştiyse, yerel artifact isteniyorsa ya da uzak CI yoksa | Commit/push-only görevinde veya CI aynı build'i açıyorsa çalıştırma |
| `gh auth` / GitHub API | PR, issue, Actions sorgusu veya GitHub API işlemi gerçekten isteniyorsa | Normal `git commit/push` için çalıştırma |
| Vercel sorgusu / deploy | Kullanıcı canlı durum veya deploy isterse ve commit kimliği biliniyorsa | Push sonrası otomatik bekleme ve periyodik sorgu yasak |
| APK workflow | Kullanıcı açıkça APK isterse | Normal kod push'unda tetikleme |
| Bağımlılık kurma / ağ | Gerekli ve onaylı doğrulama eksik bağımlılık yüzünden bloke olduysa | Önleyici veya alışkanlık amaçlı kurulum yasak |

Uzak CI aynı analyze/test/build kapısını otomatik çalıştırıyorsa ve kullanıcı yerel
çalıştırmayı istemiyorsa yerelde tekrarlama. Doğrulamayı “CI bekliyor” diye raporla;
kanıt gelmeden “geçti” deme.

## 3. Format ve mekanik diff kilidi

Format işleminden önce `git diff --stat` ile kapsamı kaydet. Format sonrasında:

- değişen dosya sayısı arttıysa,
- kullanıcı kapsamı dışında dosya oluştuysa,
- ekleme/silme toplamı anlamlı değişikliğe göre belirgin biçimde büyüdüyse,
- satır sonu veya generated gürültüsü oluştuysa,

stage, commit ve push yapma. Dur, mekanik gürültüyü ayrı tut ve Furkan'a bildir.
“Formatter güvenlidir” varsayımı bu kilidi geçmez.

## 4. Git kilidi

- Commit ve push yalnız açık kullanıcı isteğiyle yapılır.
- Karışık çalışma ağacında `git add -A` kullanma; dosyaları açıkça yaz.
- Geçici plan, log, build çıktısı, generated dosya ve kullanıcı tarafından
  onaylanmamış yeni dosyayı stage etme.
- Kullanıcı “yalnız commit/push” dediyse branch, PR, `gh`, format, test, build,
  deploy veya APK işlemi ekleme.
- Commit öncesi stage listesini göster; commit sonrası yalnız commit kimliği ve
  push sonucunu raporla.

## 5. Durdurma kapısı

Şunlardan biri olursa yeni işlem başlatma:

- Kullanıcı kapsam dışı işlemden rahatsız olduğunu söyledi.
- Aynı komut yeni değişiklik olmadan tekrar çalışacak.
- Araç çıktısı mevcut kararı değiştirmeyecek.
- İşlem yeni izin, ağ, kurulum, tam build veya geniş dosya değişikliği gerektiriyor.
- Format veya araç kullanımı diff'i büyüttü.
- Uzak CI/deploy zaten başladı.

Önce durumu tek paragrafta açıkla; ancak Furkan açıkça devam derse kapsamı genişlet.

## 6. Kısa teslim

Yalnız şunları raporla:

1. Yapılan somut işlem.
2. Değişen veya stage edilen dosyalar.
3. Gerçekten alınan doğrulama; çalıştırılmayanı geçmiş gibi gösterme.
4. Kalan tek risk veya kullanıcı adımı.

Süreç günlüğü, tekrar açıklama ve yapılmayan işlemlerin uzun listesini verme.
