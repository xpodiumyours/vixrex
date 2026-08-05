# VixRex Next.js Sahip Önizlemesi — Tamamlama Ana Planı

## 1. Sonuç

Bu plan, 3 Ağustos 2026 tarihinde Next.js taslak önizlemesine geçilirken yarım kalan sahip düzenleme akışını tamamlar.

Hedef davranış:

1. Flutter panelindeki **Önizle** butonu tek giriş noktasıdır.
2. Buton, vitrini Next.js'in gerçek `/v/:slug` şablonunda açar.
3. Önizlemeden açılan sayfa güvenli **sahip modu** olur.
4. Sahip modunda Vixrex Asistan ve düzenleme araçları görünür.
5. Taslak veya yayınlanmış vitrin aynı sahip modu arayüzünü kullanır.
6. Düzenlemeler çalışma taslağına yazılır; kullanıcı **Yayınla** demeden müşteri vitrini değişmez.
7. Normal müşteri bağlantısında sahip araçları hiçbir koşulda görünmez.
8. İleride kiralık vitrin şablonundan kullanıcıya özel taslak üretildiğinde aynı sahip modu yeniden kullanılır.
9. **Düzenlenebilir alan sayısı beşten 41'e çıkar.** Bugün kullanıcı beş alanla (isim, WhatsApp, adres, açıklama, kategori) vitrin oluşturup yayınlayabiliyor. Plan bittiğinde vitrinde görünen her alan — bölüm başlıkları ve bölüm gizleme dahil — hem tıklayarak hem Vixrex Asistan sohbetinden düzenlenebilir olur. Alanların tek kaynağı `docs/vitrin-alan-semasi.md`'dir.
10. **Hedef, referans HTML'lerin üstüdür.** `teknik_vitrin_asistan.html` görünüş kalitesinin referansıdır, düzenleme kabiliyetinin değil — o dosyadaki asistan alanların ancak onda birine dokunabiliyor, Hakkımızda ve SSS bölümleri tıklanamıyor bile. Bu plan görünüşü referans alır, düzenlemede referansı aşar.

Bu bir yeniden yazım değildir. Mevcut Flutter Vixrex Asistan motoru, Next.js vitrin şablonu, Supabase yayınlama kuralları ve yerel editör verisi mümkün olan en küçük değişikliklerle korunur.

## 2. Mevcut Durum ve Eksik Parça

### Korunan mevcut yapı

- Flutter'daki Vixrex Asistan sohbeti, rehberlik kuralları ve işlem türleri durmaktadır.
- Flutter `StoreEditorController`, düzenleme verisinin ana sahibi olmaya devam etmektedir.
- Next.js `/v/:slug`, müşterinin ve sahibin gördüğü tek vitrin şablonudur.
- Supabase `get_store_preview` taslağı güvenli anahtarla okuyabilmektedir.
- Supabase `save_store_draft_with_token` yalnız yayınlanmamış kaydı değiştirmekte, canlı kaydı korumaktadır.
- Demo/kiralık şablonlar `is_demo` korumasıyla değiştirilemez durumdadır.

### Tamamlanmamış yapı

- Yayınlanmış vitrinde **Önizle**, sahip bağlamı olmadan normal müşteri bağlantısını açmaktadır.
- Next.js `PreviewEditorPanel`, Flutter Vixrex Asistan'dan bağımsızdır ve yalnız beş alanı düzenler.
- Next.js sahip sayfasından mevcut Vixrex Asistan işlem yönlendiricisine bağlantı yoktur.
- Yayınlanmış vitrinin canlı verisini bozmadan düzenlenebileceği ayrı çalışma taslağı yoktur.
- Kalıcı düzenleme anahtarı URL sorgusunda taşınmaktadır.
- Silinen sahip akışını yeni mimaride koruyan uçtan uca test yoktur.

## 3. Değişmez Koruma Sınırları

1. Flutter müşteri vitrini veya vitrin önizlemesi çizmez.
2. Next.js `/v/:slug` tek vitrin görünümüdür; ikinci bir vitrin şablonu oluşturulmaz.
3. Normal müşteri isteği yalnız yayınlanmış veriyi görür.
4. Sahip taslağı müşteri yanıtına, SEO verisine, sitemap'e veya paylaşım bağlantısına sızmaz.
5. Yayınlanmış kayıt, önizleme düzenlemesi sırasında doğrudan değiştirilmez.
6. Demo ve kiralık şablon kaynakları değiştirilemez; ileride kiralama başladığında kullanıcıya özel kopya oluşturulur.
7. Kalıcı `edit_token` yeni sahip URL'lerine yazılmaz.
8. `service_role` veya başka bir sır tarayıcıya gönderilmez.
9. Vixrex Asistan bir değişikliği kullanıcı onayı olmadan kaydetmez.
10. Ücretli OpenAI çağrıları bu çalışma kapsamında etkinleştirilmez.
11. Mevcut giriş, yayınlama, ürün, galeri, randevu, blog, paylaşım ve müşteri vitrin akışları korunur.
12. Kullanıcıya ait mevcut çalışma alanı değişiklikleri bu çalışmaya dahil edilmez.

## 4. Kavramlar

- **Müşteri vitrini:** Herkesin açabildiği, yalnız yayınlanmış veriyi gösteren Next.js sayfası.
- **Sahip önizlemesi:** Önizle butonundan açılan, aynı Next.js şablonuna sahip araçları ekleyen özel oturum.
- **Çalışma taslağı:** Sahibin henüz yayınlamadığı değişiklikler. Canlı vitrinden bağımsızdır.
- **Sahip oturumu:** Belirli bir vitrin ve kullanıcı için kısa süreli düzenleme yetkisi.
- **Vixrex Asistan:** Mevcut rehberlik ve işlem sözleşmesini kullanan, sahibin çalışma taslağını düzenlemesine yardımcı olan arayüz.
- **Kiralık şablon:** Keşfet'te incelenen, değiştirilemez örnek vitrin.
- **Kiralanmış vitrin:** Şablondan kullanıcı adına oluşturulmuş bağımsız çalışma taslağı ve daha sonra canlı vitrin.

## 5. Hedef Mimari

### 5.1 Tek sahip önizleme arayüzü

Flutter'ın öğreneceği tek arayüz şudur:

`openOwnerPreview(storeData) -> ownerPreviewUrl`

Bu arayüzün arkasındaki uygulama:

- Taslak yoksa oluşturur veya günceller.
- Yayınlanmış vitrin için çalışma taslağı oluşturur veya mevcut taslağı açar.
- Kısa süreli, tek kullanımlık sahip kodu üretir.
- Next.js sahip giriş adresini döndürür.
- Taslak/yayınlanmış ayrımını çağırandan saklar.

### 5.2 Sahip oturumu

Kalıcı düzenleme anahtarıyla doğrudan sayfa açmak yerine:

1. Flutter, kullanıcı oturumu veya mevcut edit yetkisiyle kısa süreli tek kullanımlık kod ister.
2. Next.js kodu sunucu tarafında doğrular.
3. Kod hemen tüketilir ve tekrar kullanılamaz.
4. Next.js güvenli, `HttpOnly`, `Secure`, `SameSite=Lax` sahip çerezi oluşturur.
5. Tarayıcı temiz `/v/:slug` adresine yönlendirilir; gizli değer adres çubuğunda kalmaz.
6. Sahip çerezi yalnız ilgili vitrin ve sınırlı süre için geçerlidir.
7. Oturum süresi dolduğunda sayfa müşteri moduna düşmez; düzenlemeyi durdurup yeniden Önizle ile giriş ister.

### 5.3 Çalışma taslağı

- Yayınlanmamış mevcut mağaza kaydı taslak kaynak olarak kullanılabilir.
- Yayınlanmış vitrinin değişiklikleri ayrı bir çalışma taslağında tutulur.
- Next.js sahip görünümü varsa çalışma taslağını, yoksa canlı veriyi temel alır.
- Müşteri görünümü her zaman canlı kaydı okur.
- Yayınla işlemi mevcut doğrulayıcıları çalıştırır, başarılıysa çalışma taslağını canlı kayda atomik olarak uygular.
- Yayın sırasında sürüm çakışması varsa sessiz ezme yapılmaz; kullanıcıya yeniden yükleme/uzlaştırma mesajı gösterilir.

### 5.4 Vixrex Asistan bağlantısı

Vixrex Asistan'ın ekran uygulaması Flutter ve Next.js'te farklı olabilir; işlem sözleşmesi tek olmalıdır.

- Rehberlik durumu ortak vitrin özetinden üretilir.
- Asistan eylemleri serbest JSON güncellemesi değil, izin verilen tipli komutlardır.
- İlk komut kümesi mevcut doğrulanmış alanları kapsar: işletme adı, WhatsApp, adres, açıklama ve kategori.
- Mevcut hızlı eylemler ilgili sahip düzenleme bölümünü açar: kapak, galeri, ürünler, kategori, konum ve yayınlama.
- Karmaşık alanlar için asistan doğrudan veri uydurmaz; ilgili düzenleyiciyi açar.
- Her değişiklik önce öneri/onay, sonra çalışma taslağına kayıt şeklinde ilerler.
- Kayıttan sonra Next.js veriyi yeniden okuyarak gerçek vitrin şablonunu günceller.
- Asistan erişilemezse manuel sahip düzenleme araçları çalışmaya devam eder.

Ücretli/yapay zekâ tabanlı serbest metin önerisi mevcut kodda kapalıdır. Bu plan yalnız mevcut kural tabanlı davranışı ve güvenli onaylı komutları bağlar. OpenAI özelliğinin etkinleştirilmesi ücret ve ürün kararı olduğu için ayrı açık onay gerektirir.

### 5.5 Kiralık vitrin uyumu

Bu çalışma kiralama ve ödeme özelliğini uygulamaz; ancak sahip önizlemesini buna hazırlar:

- Kiralık şablon sahibi oturumuyla düzenlenemez.
- Gelecekte kiralama başarılı olduğunda şablon kullanıcıya özel çalışma taslağına kopyalanır.
- Kullanıcı bu yeni taslağı aynı `openOwnerPreview` arayüzüyle açar.
- Şablon, kiralama kaydı ve kullanıcı vitrini ayrı kimliklere sahip olur.

## 6. Uygulama Aşamaları ve Küçük Commitler

Her commit sonunda ilgili statik kontroller ve dar test grubu geçmelidir. Bir commit sonraki commit tamamlanmadan da güvenli ve geri alınabilir durumda olmalıdır.

### Commit 1 — Mevcut davranışı sözleşme testleriyle kilitle

- Müşteri `/v/:slug` isteğinin sahip araçları göstermediğini test et.
- Mevcut taslak önizlemenin doğru token olmadan açılamadığını test et.
- Demo/kiralık şablonun değiştirilemediğini test et.
- Flutter Önizle butonunun taslak ve yayınlanmış durumda bugün hangi adresi açtığını testle görünür hale getir.
- Production davranışını değiştirme.

### Commit 2 — Sahip önizleme bağlantı modelini ekle

- Taslak ve yayınlanmış ayrımını gizleyen tek sahip önizleme sonuç modelini ekle.
- Flutter URL üretimini bu model arkasına al.
- Eski `preview_token` bağlantısını geçici uyumluluk yolu olarak koru.
- Henüz yeni oturum üretme; davranış değişikliğini küçük tut.

### Commit 3 — Kısa süreli sahip oturumu migration'ını ekle

- Sahip oturumlarının yalnız hash'lenmiş kodunu, vitrin kimliğini, kullanıcı kimliğini, son kullanma ve tüketilme zamanını tutan sürümlü migration oluştur.
- Oturum oluşturma ve tek kullanımlık kod tüketme fonksiyonlarını ekle.
- Yalnız doğrulanmış sahip veya geçerli edit yetkisi oturum oluşturabilsin.
- Demo/kiralık şablon için oturum oluşturmayı reddet.
- Public RLS politikalarını değiştirme.
- SQL sözleşme ve yetki testlerini ekle.

### Commit 4 — Next.js sahip kodu değişimini ve güvenli çerezi ekle

- Next.js sunucu rotasında tek kullanımlık kodu doğrula.
- Güvenli sahip çerezini oluştur ve gizli sorgu değerini temiz URL'ye yönlendir.
- Hatalı, kullanılmış veya süresi dolmuş kodu açık hata durumuyla reddet.
- Sahip yanıtlarını `private, no-store`; müşteri yanıtlarını mevcut public davranışla sun.
- Sahip çerezinin başka slug için kullanılamadığını test et.

### Commit 5 — Flutter Önizle butonunu tek sahip girişine bağla

- Önizle tıklamasında editör verisini yerel olarak senkronla.
- Taslak vitrini güvenli şekilde kaydet.
- Yayınlanmış vitrin için canlı link yerine sahip oturumu oluştur.
- Her iki durumda Next.js sahip giriş adresini yeni sekmede aç.
- Kopyala/Paylaş/Canlıyı Aç düğmelerini müşteri bağlantısında bırak; yalnız Önizle sahip moduna girsin.
- Taslak ve yayınlanmış durum için widget/controller testlerini ekle.

### Commit 6 — Yayınlanmış vitrin çalışma taslağını ekle

- Canlı kayıt ile sahibin çalışma taslağını ayıran sürümlü veri yapısını ekle.
- İlk açılışta canlı veriden çalışma taslağı üret.
- Sonraki açılışlarda mevcut taslağı koru.
- Taslak verisine yalnız sahip oturumu üzerinden erişim ver.
- Canlı kayıt güncellendiyse sürüm çakışmasını algıla.
- Müşteri sorgularının çalışma taslağını hiçbir şekilde okuyamadığını test et.

### Commit 7 — Next.js sahip çalışma alanı kabuğunu ekle

- Gerçek `VitrinProfileView` etrafına yalnız sahip oturumunda görünen çalışma alanı ekle.
- Masaüstünde yan panel, mobilde açılır çekmece kullan.
- Taslak/yayında durumu, kaydetme durumu, oturum süresi ve hata durumlarını göster.
- Mevcut beş alan panelini yeni kabuğa taşı; aynı anda iki kayıt yolu bırakma.
- Müşteri görünümünün HTML ve görsel yapısının değişmediğini test et.

### Commit 8 — Onaylı sahip düzenleme komutlarını ekle

**Önkoşul: `docs/vitrin-alan-semasi.md`.** Düzenlenebilir alanların tek kaynağı o dosyadır; 41 tekil alan ve 7 liste orada tanımlıdır.

**Bu adımın asıl amacı beş alanı çalıştırmak değil, mekanizmayı kurmaktır.** Bugün kullanıcı beş alanla vitrin oluşturup yayınlayabiliyor (`PreviewEditorPanel`: isim, WhatsApp, adres, açıklama, kategori). Hedef 41'dir. Aradaki fark kod değil, sıradır — mekanizma şemadan beslenirse kalan 36 alan Commit 10'da satır eklemekle açılır.

- Alan güncelleme komutlarını tipli ve izin listeli hale getir. **İzin listesi şemadan okunur; elle yazılmaz.**
- Komut katmanı **arayüzden bağımsız** olmalı: Commit 9'da hem asistan sohbeti hem tıkla-düzenle aynı komutları çağıracak. Komutlar belirli bir panele veya bileşene bağlanmaz.
- Sunucu doğrulaması da şemadaki `tip` ve `doğrulama` sütunlarından üretilir. **Alan başına ayrı doğrulayıcı yazılmaz.**
- İlk küme olarak işletme adı, WhatsApp, adres, açıklama ve kategori çalıştırılır — fakat **beş ayrı dallanma yazılarak değil**, şemanın beş satırı olarak.
- Kabul ölçütü: altıncı bir alanı açmak için **yalnız şemaya satır eklemek** yeterli olmalı. Kod değişikliği gerekiyorsa mekanizma yanlış kurulmuştur.
- Başarılı kayıttan sonra Next.js vitrini güncelle.
- Geçersiz alan, izinsiz vitrin, demo şablon ve süresi dolmuş oturum testlerini ekle.

### Commit 9 — Sahip panelini Vixrex Asistan'a çevir ve tıkla-düzenleyi bağla

**Karar (2026-08-05):** Sahip paneli bir form DEĞİL, asistan sohbetidir. Commit 7'de geçici olarak taşınan beş alanlı `PreviewEditorPanel` burada **kaldırılır**; yerine asistan geçer. Aksi hâlde Flutter formu + Next.js formu + asistan olmak üzere üç kapı oluşur ve aynı alan için iki kayıt yolu doğar (bkz. `VIXREX_RULES.md` §1).

- Mevcut Vixrex yolculuk durumunu Next.js'in tüketebileceği ortak bir özet sözleşmesine dönüştür.
- Sahip paneline Vixrex Asistan sohbetini ve hızlı eylemleri ekle; `PreviewEditorPanel`'i panelden çıkar.
- **Tıkla-düzenle mekanizmasını kur.** Referans: `teknik_vitrin_asistan.html`. Üç parçadan oluşur:
  1. Vitrindeki öğelere `data-vixrex-editable="<anahtar>"` ve `data-vixrex-label="<Türkçe ad>"` konur. Değerler `docs/vitrin-alan-semasi.md` şemasından gelir, elle yazılmaz.
  2. Sayfada tek bir tıklama dinleyicisi en yakın işaretli öğeyi bulur, paneli açar, o alanı vurgular ve kullanıcıya hangi alanı seçtiğini söyler.
  3. Kullanıcının yazdığı değer Commit 8'in tipli komutuna gider. **Alan başına ayrı dallanma yazılmaz** — referans HTML'de sekiz elle yazılmış dal var ve bu yüzden orada yalnız dokuz alan tıklanabiliyor, Hakkımızda ve SSS tıklanamıyor bile. Biz bunu şemadan üretiyoruz.
- Sohbet tek yol değildir: tıklanan alan için panelde uygun giriş kutusu da açılabilir (görsel yükleme, çalışma saati gibi alanlar sohbetle zor).
- Asistan önerisini kullanıcı onaylamadan kaydetme.
- Asistan kapalı/ulaşılamaz olduğunda Flutter manuel paneli yedek yol olarak çalışmaya devam eder.
- Flutter'daki mevcut asistanı silme; iki yüzey aynı işlem adlarını kullanmalı.

### Commit 10 — Kalan alanları aç ve karmaşık bölümleri bağla

Commit 8'in mekanizması doğru kurulduysa bu adım **kod yazmak değil, şemaya satır eklemektir.** Beş alandan 41'e çıkış burada tamamlanır.

**Sırayla açılacak tekil alanlar** (`docs/vitrin-alan-semasi.md` §5): hero rozet ve konum metni, işletme türü, logo, kapak görseli, tema ön ayarı, telefon, e-posta, harita etiketi ve bağlantısı, çalışma saatleri, Instagram, web sitesi, kampanya bandının beş alanı, Hakkımızda'nın beş alanı, galeri ve blog ve SSS bölüm başlıkları, görünürlük anahtarları.

**Bölüm başlıkları için varsayılan kuralı korunur** (§8): kolon boşsa `vitrinCopy.ts` içindeki kategori varsayılanı gösterilir, sahip yazdıysa onunki. `vitrinCopy.ts` silinmez.

**`section_visibility` bağlanır:** sahip bir bölümü kapatabilsin. Boş nesne bugünkü davranışı korur.

**Listeler ayrı komut tipi ister** (§6): ürünler, kategoriler, galeri kareleri, SSS, değer kartları, pazaryeri bağlantıları, blog yazıları. Bunlar `ekle` / `düzenle` / `sil` / `sırala` komutlarıyla yönetilir; tekil alan komutuyla değil.

- 2026-08-04'te eklenen 12 kolon `PUBLIC_STORE_SELECT` listesine eklenir; aksi hâlde müşteri yanıtına girmezler.
- Kapak, galeri, ürün/kategori, konum ve çalışma saatleri için mevcut doğrulama ve depolama kuralları yeniden kullanılır.
- Görsel yüklemelerde tür, boyut, sahiplik ve güvenli URL kontrolü korunur.
- Bir bölüm tamamlanmadan diğerine geçilmez; her biri ayrı küçük commit olabilir.
- **Ürün kaynağı netleştirilir:** ürünler bugün hem `products` JSONB kolonunda hem ayrı tabloda tutulabiliyor (`product_storage_version`). Ürün komutları yazılmadan önce tek kaynak seçilir.

### Commit 11 — Taslaktan yayınlama ve vazgeçme akışını tamamla

- Sahip moduna `Yayınla` ve `Taslak değişikliklerini bırak` işlemlerini ekle.
- Yayınlamada mevcut yasal ve zorunlu alan doğrulamalarını çalıştır.
- Başarılı yayınlamayı atomik yap ve Next.js önbelleğini yenile.
- Başarısız yayınlamada canlı vitrini ve çalışma taslağını koru.
- Vazgeçmede yalnız çalışma taslağını kaldır; canlı veriye dokunma.

### Commit 12 — Kalıcı token URL yolunu kaldır

**Not (2026-08-05):** `PreviewEditorPanel`'in sahip panelinden çıkarılması bu adımdan **Commit 9'a alındı** — asistan onun yerine geçtiği için orada kaldırılıyor. Burada yalnız eski URL yolu kalıyor.

- Kalıcı `preview_token` URL desteğini önce kullanımdan kaldırılmış olarak işaretle, sonra güvenli geçiş süresi sonunda kaldır. Buna bağlı `openLegacyDraft` yolu da temizlenir.
- `PreviewEditorPanel` bileşeni Commit 9'da panelden çıkarıldıysa ve başka kullanan kalmadıysa dosyası burada silinir.
- Silinen eski Flutter vitrin render kodunu geri getirme.
- Mimari sözleşme testini güncelle: vitrin yalnız Next.js'te, sahip araçları yalnız sahip oturumunda.

### Commit 13 — Tam doğrulama ve yayın hazırlığı

- Flutter format ve analizini çalıştır.
- İlgili Flutter unit/widget testlerini çalıştır.
- Supabase migration zincirini yerelde sıfırdan doğrula.
- Next.js lint, type-check/test ve production build çalıştır.
- Taslak, yayınlanmış, müşteri, hatalı oturum, mobil ve masaüstü akışlarını yerelde doğrula.
- Preview deploy'da doğru commit ve iki Vercel projesini ayrı ayrı doğrula.
- Production deploy, migration uygulama ve canlı smoke test için ayrıca açık yetki al.

## 6.1 Keşfedilen açık işler (planda yoktu)

Bunlar plan yazılırken görülmemiş, çalışma sırasında ortaya çıktı. Plan adımı değildirler; sırası geldiğinde ele alınır.

### A. Kategoriye göre aksiyon butonları bağlanmadı

`public_web/src/lib/vitrinProfile.ts` her kategori için hangi butonların çıkacağını tanımlıyor (`primaryActions`), fakat bu liste hiçbir yerde okunmuyor. Vitrindeki butonlar sabit: "Hemen Ara", "WhatsApp", "Yol Tarifi".

Sonucu iki yönlü:
- Kuaför, teknik servis, kozmetik gibi hizmet kategorilerinde **randevu butonu çıkmıyor** — randevu altyapısı tamamen kurulu (`/v/:slug/randevu`, sihirbaz, takip ekranı) ama müşteri erişemiyor.
- Butik, giyim gibi ürün kategorilerinde randevu zaten çıkmamalı — bu doğru ama tesadüfen doğru; kural işlemiyor.

Bağlanacak veri sayfadan zaten gönderiliyor (`profile` prop'u, şu an kullanılmadığı için lint uyarısı veriyor). Randevu butonu iki koşula bağlanmalı: kategori uygun **ve** `isBookingEnabled` true.

### B. Landing şablon kataloğunda 7 kategori eksik

`lib/widgets/landing/landing_template_category.dart` **12** kategori gösteriyor; sistemde **19** var. Landing'de teklif edilmeyen 7 kategori:

`kozmetik`, `elektronik`, `kirtasiye`, `hizmet_danismanlik`, `egitim_ders`, `ev_temizlik`, `pet_shop_veteriner`

Bunlar **bozuk değil** — `business_category_config.dart`, `vitrinProfile.ts` ve `vitrinCopy.ts` içinde tanımları tam; seçilirlerse doğru çalışırlar. Yalnızca landing sayfasından seçilemiyorlar.

Tercih mi, gözden kaçma mı belirsiz. "19 kategoriye özel vitrin" hedefi için kullanıcının hepsini seçebilmesi gerekir.

**Not:** kategori zinciri denetlendi ve SAĞLAM. Landing anahtarları (`berber`, `butik_giyim` gibi) `BusinessCategoryConfig.labelForKey` ile Türkçe etikete çevriliyor, `stores.kategori` etiketi saklıyor, Next.js `resolveVitrinProfile` üç katmanlı çözüyor (tam eşleşme → Türkçe normalleştirme → anahtar kelime). Flutter `&`, Next.js `/` kullanmasına rağmen üçüncü katman yakalıyor. 12 landing kategorisinin 12'si de doğru profile düşüyor.

### C. Bağlanmamış diğer prop'lar

`status`, `isClosed`, `workingHoursWeek`, `marketplaceLinks`, `logoUrl`, `googleBusinessLink`, `referencesUrl` sayfadan gönderiliyor ama vitrinde çizilmiyor. Silinmemeli — her biri için "kayıp özellik mi, bilerek mi kaldırıldı" kararı ayrı verilecek. Özellikle `status`/`isClosed`: açık/kapalı mantığı `workingHours.ts` içinde var ama hiçbir gösterge çizilmiyor.

## 7. Kabul Kriterleri

1. Taslak vitrinde Önizle, Next.js sahip modunu açar.
2. Yayınlanmış vitrinde Önizle, müşteri linki yerine Next.js sahip modunu açar.
3. Aynı sayfada Vixrex Asistan ve düzenleme araçları görünür.
4. Normal müşteri linkinde sahip araçlarına ait metin, veri veya kod yolu etkin değildir.
5. Onaylanan alan değişikliği sahip önizlemesinde görünür.
6. Yayınlanmış vitrinin müşteri görünümü yayın komutuna kadar değişmez.
7. Yayınlama başarılı olduğunda müşteri vitrini yeni sürümü gösterir.
8. Yayınlama başarısız olduğunda eski canlı vitrin çalışmaya devam eder.
9. Sahip kodu tek kullanımlıktır; süresi dolmuş veya başka slug'a ait kod reddedilir.
10. Demo/kiralık şablon düzenlenemez.
11. Asistan kullanılamasa bile manuel düzenleme ve yayınlama mümkündür.
12. Mevcut ürün, galeri, randevu, blog, SEO ve paylaşım akışlarında gerileme yoktur.

## 8. Test Matrisi

| Durum | Beklenen sonuç |
|---|---|
| İsimsiz/boş yeni taslak | Önizleme hazırlanmaz; anlaşılır eksik bilgi mesajı gösterilir |
| Yayınlanmamış taslak | Sahip oturumu açılır, müşteri erişimi reddedilir |
| Yayınlanmış vitrin | Sahip çalışma taslağı açılır, canlı veri korunur |
| Normal müşteri bağlantısı | Yalnız canlı vitrin ve müşteri eylemleri görünür |
| Yanlış sahip kodu | Sahip modu açılmaz |
| Kullanılmış sahip kodu | İkinci kullanım reddedilir |
| Süresi dolmuş oturum | Kayıt durur, yeniden Önizle istenir |
| Başka vitrine ait oturum | Erişim reddedilir |
| Demo/kiralık şablon | Salt okunur kalır |
| Asistan önerisi reddedildi | Taslak değişmez |
| Asistan önerisi onaylandı | Yalnız izin verilen alan değişir |
| Yayın doğrulaması başarısız | Canlı ve taslak korunur |
| Yayın başarılı | Canlı sürüm atomik güncellenir |
| Mobil ekran | Vitrin ve sahip çekmecesi taşmadan kullanılabilir |
| Masaüstü ekran | Vitrin ve asistan yan yana kullanılabilir |

## 9. Kapsam Dışı

- Eski Flutter `PreviewScreen` veya `PublicVitrinScreen` render ağacını geri getirmek.
- Müşteri vitrininin tasarımını yeniden yapmak.
- Kiralama ödemesi, süre uzatma, iptal ve tahsilat sistemi.
- Kiralık şablonu doğrudan düzenlenebilir hale getirmek.
- OpenAI veya ücretli başka bir servisi etkinleştirmek.
- İstek dışı ürün, randevu, blog, SEO veya Keşfet değişiklikleri.
- Canlı migration, production deploy veya push.

## 10. Geri Dönüş Stratejisi

- Her aşama ayrı küçük commit olur; toplu geri alma yerine sorunlu commit `git revert` ile geri alınabilir.
- Yeni tablolar ve fonksiyonlar müşteri yolundan bağımsız eklenir; özellik bayrağı kapalıyken mevcut müşteri vitrini çalışır.
- Flutter Önizle yönlendirmesi, yeni sahip oturumu doğrulanana kadar eski taslak önizleme yoluna kontrollü geri düşebilir.
- Yeni sahip paneli tamamlanmadan eski beş alan paneli kaldırılmaz.
- Production migration uygulanmadan önce yedek, ileri migration ve geri dönüş SQL'i hazırlanır.
- Canlı doğrulama başarısızsa müşteri rotasına dokunmadan sahip modu kapatılır.

## 11. Uygulama Kapısı

Bu dosya onaylanmadan production kodu, migration veya test davranışı değiştirilmez. Uygulama başladığında adımlar sırayla yürütülür; koruma sınırını değiştiren yeni bir ürün kararı çıkarsa çalışma durdurulur ve plan güncellenir.
