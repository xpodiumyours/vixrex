# VixRex — Proje Kuralları

> Bu dosya Matt Pocock skill paketinin çalışma yöntemini tekrar etmez veya değiştirmez.
> Yalnızca VixRex’e özel proje bilgilerini, güvenlik sınırlarını, kanıt seviyelerini ve canlı sistem kurallarını tanımlar.
> Kullanıcı bir skill’i açıkça çağırdığında veya istek bir skill’in tarifine doğrudan uyduğunda, skill’in normal adımları ve üreteceği belgeler görev kapsamındadır.

## 1. Proje Sınırları

VixRex, işletmeler için dijital vitrin ve müşteri yönetim platformudur.

- `lib/`: Flutter Web/Mobil işletme paneli.
- `public_web/`: Next.js müşteri vitrini (`/v/:slug`).
- Supabase: PostgreSQL, Auth ve Storage.
- Vercel: Flutter paneli ve Next.js public site iki ayrı projedir.
- Bir yüzeyde çalışırken diğer yüzey yalnızca gerçek bir bağlantı kanıtlanırsa kapsama alınır.
- **Değişmez kural — vitrin görünümü yalnızca Next.js'te render edilir:** Flutter, müşterinin veya esnafın göreceği vitrin/önizleme sayfasını kendi başına bir daha ASLA çizmez (özel bir widget ağacıyla, `PreviewScreen` benzeri bir ekranla veya başka bir yöntemle). Esnafın "önizleme" ihtiyacı da dahil, her görünüm `public_web`'in gerçek `/v/:slug` şablonu üzerinden karşılanır — yayın öncesi taslaklar için `?preview_token=` ile (bkz. `save_store_draft_with_token` / `get_store_preview` Supabase fonksiyonları). Flutter yalnızca: veriyi düzenler, Supabase'e yazar, Next.js linkini (yayın veya taslak) açar. Bu kural 2026-08-03'te, aylarca süren Flutter/Next.js vitrin tekrarı karmaşasından sonra kesinleşti — yeniden açılması kullanıcının açık isteğini gerektirir.

- **Değişmez kural — düzenlemenin iki kapısı vardır, üçüncüsü açılmaz:** (1) **Flutter manuel üyelik paneli** — büyük form, toplu işlem, OCR/Excel, çevrimdışı çalışma. (2) **Next.js sahip paneli — Vixrex Asistan.** Vitrin önizlemesinde açılan panel bir form değil, asistan sohbetidir; vitrindeki bir alana tıklandığında panel o alana odaklanır ve kullanıcı ister sohbete yazar ister açılan kutuyu doldurur. İkisi de aynı alan şemasına bakar, aynı doğrulamadan geçer, aynı çalışma taslağına yazar. **Next.js tarafında ikinci bir form paneli açılmaz** — o üçüncü kapı olur ve aynı alan için iki kayıt yolu doğurur. Düzenlenebilir alanların tek kaynağı `docs/vitrin-alan-semasi.md` dosyasıdır; yeni alan önce oraya yazılır, sonra koda geçer. Şemadaki `anahtar` ve `etiket` sütunları, vitrindeki öğelere konan `data-vixrex-editable` / `data-vixrex-label` işaretlerinin kaynağıdır.

- **Flutter manuel üyelik paneli yerinde kalır:** Taşınmaz, silinmez. Rolü arka plan ve yedek yoldur — çevrimdışı düzenleme, sahip oturumu açılamadığında iş durmaması, ve OCR/Excel/toplu yükleme akışlarının kalması için. Bu panel veriyi düzenler ve Supabase'e yazar; **vitrini çizmez.** Vitrin render kuralı aynen geçerlidir. Bu iki kural 2026-08-04'te, düzenleme yüzeyinde Flutter/Next.js karmaşasının ikinci kez yaşanmaması için kesinleşti; yeniden açılması kullanıcının açık isteğini gerektirir.

## 2. Kullanıcıyla İletişim

- Kullanıcı teknik terim veya İngilizce bilmek zorunda değildir.
- Kullanıcı ekran görüntüsü ve doğal dille ne istediğini anlatabilir. AI bunu teknik göreve çevirir.
- Yanıtlar Türkçe, kısa ve sade olur. Zorunlu bir teknik terim ilk kullanımda basitçe açıklanır.
- Komut, dosya yolu ve altyapı ayrıntısı yalnızca karar veya işlem için gerekliyse gösterilir.
- Koddan, dosyadan veya resmî kaynaktan bulunabilecek gerçekler kullanıcıya sorulmaz; araştırılır.
- Ürün kararı ve tercih gereken konular kullanıcıya tek tek sorulur. Her soruyla birlikte önerilen cevap ve kısa gerekçesi verilir.
- Kullanıcı açık onay verdiyse aynı onay tekrar istenmez.
- Sonuç önce söylenir: “hazır”, “hazır değil”, “test edilmedi” veya “canlıda doğrulandı”.

## 3. VixRex Koruma Kuralları

1. **Varsayım yok:** Dosya, özellik, hata, canlı durum ve servis bağlantısı okunmadan gerçek kabul edilmez.
2. **İstek dışı ürün değişikliği yok:** Kullanıcının istemediği özellik, ekran davranışı veya ürün kararı uygulanmaz.
3. **İlgisiz düzeltme yok:** İnceleme sırasında bulunan başka sorun bildirilir; kullanıcı kapsama almadıkça düzeltilmez.
4. **Çalışan akışı koru:** Mevcut ekran, geri dönüş yolu ve kayıt/yayın akışı kanıt olmadan kaldırılmaz veya yönlendirilmez.
5. **Testi sonuca uydurma:** Test sırf geçsin diye silinmez, gevşetilmez veya yanlış davranışı kabul edecek şekilde değiştirilmez.
6. **Uydurma bağımlılık yok:** Yeni paket veya servis için resmî kaynak, güncel sürüm, lisans ve gerçek ihtiyaç doğrulanır.
7. **Sır ve kişisel veri yok:** API anahtarı, token, parola ve gerçek kullanıcı verisi koda, loga, mesaja veya test dosyasına yazılmaz.
8. **Rules dosyası kullanıcıya aittir:** Bu dosya yalnızca kullanıcının açık isteğiyle değiştirilir.

## 4. Yetki Sınırları

- Okuma, arama, diff ve durum kontrolü için ayrıca onay gerekmez.
- Kullanıcının açıkça istediği değişiklik, tarif edilen görev kapsamına onaydır.
- Açıkça çağrılan veya göreve doğrudan uyan skill’in normal dosya, belge, test, rapor, issue ve inceleme adımları skill kapsamındadır.
- Push, production deploy, canlı veritabanı işlemi, production verisi silme ve ücret oluşturabilecek işlem açık yetki gerektirir.
- Kullanıcı bu işlemleri aynı istekte açıkça verdiyse tekrar onay istenmez.
- Production dosyası/ekranı silme, geçmişi yeniden yazma, force push, geniş toplu taşıma ve veri kaybı riski olan SQL için hedef ve geri dönüş yolu bilinmeden işlem yapılmaz.
- Skill’in açıkça geçici olarak ürettiği prototip, araştırma veya rapor dosyaları production özelliği sayılmaz.
- İsteğe bağlı harici kontrol aracı eksikse proje “eksik kurulum” sayılmaz; mevcut resmî proje araçları kullanılır.

## 5. Kanıt Seviyeleri

Bir özellik için yalnızca ulaşılan seviye söylenir:

1. **Kodda görüldü:** Bağlantı ve mantık dosyalarda mevcut.
2. **Statik kontrol geçti:** Format, analiz veya type-check temiz.
3. **Otomatik test geçti:** İlgili testler başarılı.
4. **Yerelde doğrulandı:** Gerçek kullanıcı akışı yerelde çalıştı.
5. **Canlıda doğrulandı:** Doğru commit ve doğru URL üzerinde çalıştı.

“Kodda var” ifadesi “gerçekten çalışıyor” veya “canlıda hazır” anlamına gelmez.
Prototip yalnızca cevapladığı tasarım sorusu için kanıttır; production özelliğinin çalıştığını kanıtlamaz.

## 6. Aşamaya Göre Kontrol Kapıları

Çalışma yöntemini ilgili skill belirler. Aşağıdaki kapılardan yalnızca görevin etkiledikleri uygulanır:

1. **Keşif:** Problem kanıtı, hedef kullanıcı ve veri toplama izni.
2. **Ürün tanımı:** Amaç, başarı ölçüsü ve kapsam dışı olanlar.
3. **Gereksinim:** Roller, ana akışlar, erişilebilirlik, veri ve yetkilendirme sınırları.
4. **Prototip:** Riskli fikir küçük örnekle sınanır; demo production hazır sayılmaz.
5. **UI/UX:** Mobil/masaüstü, yükleme, hata, boş durum ve anlaşılır mesajlar.
6. **Teknik mimari:** Flutter/Next/Supabase sahipliği, veri akışı ve geri dönüş yolu.
7. **Backend/veritabanı:** Girdi doğrulama, RLS, migration, indeks, log ve yedek.
8. **Frontend:** Client/server doğrulaması, responsive yapı, veri saklama ve hata yakalama.
9. **Test/kalite:** Göreve uygun unit, widget, integration/E2E, güvenlik ve erişilebilirlik.
10. **Production hazırlığı:** Ortam değişkenleri, domain/SSL, SEO, izleme, yedek ve rollback.
11. **Yayınlama:** Migration sırası, production build, smoke test ve yayın sonrası kontrol.
12. **Bakım/kapatma:** Geri bildirim, güvenlik borcu, veri dışa aktarma/silme ve güvenli arşivleme.

## 7. Flutter Kontrol Kapısı

- Production için değişen Dart dosyaları formatlanır.
- `dart analyze` veya `flutter analyze` hatasız olmalıdır.
- Değişiklikle ilgili unit/widget testleri çalıştırılır.
- Kayıt, giriş, ürün, yayınlama veya silme gibi temel akış etkileniyorsa ilgili smoke/integration testi çalıştırılır.
- Flutter Web production yayını öncesi release build doğrulanır.
- Geçici ve açıkça işaretlenmiş prototip production kontrolünden geçmek zorunda değildir; gerçek koda aktarılırsa tüm kontroller uygulanır.
- Test başarısızsa nedeni açıklanmadan “hazır” denmez.

## 8. Next.js Kontrol Kapısı

- Production değişikliği `public_web` içindeyse TypeScript/build kontrolü yapılır.
- Production yayını öncesi `npm run build` başarılı olmalıdır.
- `/v/:slug`, ürün, yazı, randevu, sitemap ve metadata etkileri görev kapsamına göre kontrol edilir.
- Flutter paneli ve Next.js public site birbirinin yerine test edilmiş sayılmaz.
- Geçici prototip gerçek route veya bileşene dönüştürülürse production kontrolleri uygulanır.

## 9. Supabase ve Veritabanı

- Canlı şema Dashboard veya SQL Editor üzerinden sessizce değiştirilmez; sürümlü migration kullanılır.
- Daha önce uygulanmış migration sonradan değiştirilmez. Yeni değişiklik için yeni migration oluşturulur.
- `ALTER TABLE` otomatik olarak yasak değildir. `ADD COLUMN` gibi gerekli ve veri koruyan işlemler incelenip migration ile yapılabilir.
- `DROP`, kolon türü değiştirme, toplu `UPDATE/DELETE`, constraint ve RLS değişiklikleri yüksek risklidir; yedek/geri dönüş ve açık onay gerektirir.
- `CREATE IF NOT EXISTS` veya `ADD COLUMN IF NOT EXISTS` tek başına güvenlik kanıtı değildir; mevcut şema ve beklenen sonuç kontrol edilir.
- İstemciden erişilen `public` tablolarında RLS açık ve politikalar sahiplik/yetki sınırına uygun olmalıdır.
- `service_role`, gizli anahtar ve production parolası Flutter/Next istemcisine konmaz.
- Migration production öncesi yerelde uygulanır ve mümkünse sıfırdan migration zinciriyle test edilir.
- XML/CSV/Excel gibi dış girdiler güvenilmez kabul edilir; bozuk dosya, eksik alan, tekrar kayıt, büyük dosya ve güvenli URL sınırları test edilir.

## 10. Git ve Deploy

- Kirli çalışma alanında kullanıcıya ait değişiklikler korunur.
- Commit öncesi `git diff` ve `git diff --cached` görülür.
- Yalnızca görev ve çağrılan skill kapsamındaki dosyalar stage edilir.
- Test geçmediyse commit mesajında veya sonuç raporunda başarısız ya da atlanan test açıkça belirtilir.
- Force push ve `git reset --hard` kullanılmaz.
- Vercel’de feature branch preview içindir; production branch canlı içindir.
- Flutter ve public Vercel projeleri ayrı sonuç verir. Birinin deploy olması diğerinin başarılı olduğu anlamına gelmez.
- Canlı doğrulamada commit, proje, URL ve durum eşleştirilir; erişim yoksa “doğrulanmadı” denir.
- Gereksiz sürekli takip yapılmaz; istenen doğrulama yapılıp sonuç verilir.

## 11. Hata ve Geri Dönüş

- Önce hata metni, son değişiklikler ve doğru çalışan referans incelenir.
- Kök neden bulunmadan art arda tahmini düzeltmeler yapılmaz.
- Geri dönüş için tercihen yeni bir `git revert` commit’i kullanılır.
- Production verisini veya kullanıcı çalışmasını etkileyen geri alma hedefi kesin değilse işlem durdurulur.
- Hata raporunda gerçek durum saklanmaz; “başarısız”, “engellendi” veya “test edilmedi” açıkça söylenir.

## 12. Resmî Dayanaklar

- OWASP: Secure Coding with AI Cheat Sheet
- NIST: Secure Software Development Framework (SP 800-218)
- GitHub Docs: Copilot agent risks, review ve branch protections
- Flutter Docs: Testing ve web release
- Next.js Docs: Testing ve production checklist
- Supabase Docs: Database migrations, RLS ve API security
- Vercel Docs: Git deployments, preview ve production environments

Bu kaynaklar VixRex’in teknik güvenlik kapılarını destekler. Görevin çalışma yöntemini ise uygun Matt Pocock skill’i belirler.
