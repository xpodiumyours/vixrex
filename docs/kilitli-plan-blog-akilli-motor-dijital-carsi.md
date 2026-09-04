# KİLİTLİ PLAN — Vixrex Blog → Blog Kütüphanesi → Vitrine Yazı Çekme → Asistan Blog Komutları → Dijital Çarşı Bağlantı Omurgası

## 0. Güvenli başlangıç noktası

- Sabit geri dönüş noktası: `main@95af697707e5f908b1f9b2aed95279f374557004`
- Ayrı checkpoint branch: `checkpoint/main-post-413-20260904`
- Bu plan için çalışma branch'i: `plan/blog-akilli-motor-dijital-carsi`
- PR #413 sonrası doğrulanmış sahiplik/asistan davranışı başlangıç kabul edilir.
- Main doğrudan geliştirme alanı değildir. Her katman ayrı PR ile ilerler.

## 1. Değişmez sıra

Bu sıra kilitlidir:

1. **Vixrex Blog Omurgası**
2. **Merkezi Blog Kütüphanesi**
3. **Vitrine Yazı Çekme / Taslak Enjeksiyonu**
4. **Vixrex Asistan Blog Komutları**
5. **Dijital Çarşı Bağlantı Omurgası**

Bir katman doğrulanmadan sonraki katmana geçilmez.

## 2. Çalışma yöntemi — RESEARCH → LOOK → LOCK → BUILD → VERIFY → DECIDE → MERGE

Her katmanda aynı zorunlu döngü uygulanır. **Araştırma ve uygunluk onayı tamamlanmadan kodlama başlamaz.**

### RESEARCH — araştırma kapısı
Her katmanda önce yalnız araştırma yapılır:
- Mevcut Vixrex kodu ve veri modeli incelenir.
- Canlı davranış ve varsa ekran görüntüleri doğrulanır.
- Mevcut Vixrex UX dili, bileşenleri, mobil/masaüstü davranışı ve bilgi mimarisiyle uyum araştırılır.
- Gerekliyse resmi teknik kaynaklar ve güncel web standartları araştırılır.
- Mevcut çalışan akışlara etkisi ve regresyon yüzeyi çıkarılır.
- Alternatifler yalnız doğrulanabilir farklarla karşılaştırılır.

**Araştırma çıktısı:**
1. Mevcut gerçeklik
2. Hedefle uyum
3. Dokunulacak yüzeyler
4. Dokunulmaması gereken yüzeyler
5. Riskler
6. Önerilen en küçük güvenli yaklaşım
7. Doğrulama yöntemi

### UX-FIT — Vixrex uygunluk onayı
Araştırmadan sonra ayrı uygunluk kontrolü yapılır:
- Yeni ekran mevcut Vixrex tasarım dilinden kopuyor mu?
- Sahiplik, Keşfet ve public vitrin arasında farklı uygulama hissi oluşturuyor mu?
- Mobilde mevcut asistan/owner davranışını bozuyor mu?
- Kullanıcıya yeni ve gereksiz öğrenme yükü getiriyor mu?
- Mevcut bileşenler yeniden kullanılabiliyor mu?
- Yeni akış Vixrex'in "tek veri, tek görünüm, tek asistan" ilkesine uyuyor mu?

**Kural:** Araştırma + UX-FIT sonucu kullanıcıya sunulur. Kullanıcının açık onayı olmadan BUILD aşamasına geçilmez.

### LOOK — teknik mevcut durum doğrulaması
- Sadece o katmanın mevcut kodu, DB şeması, API'leri ve canlı davranışı incelenir.
- Varsayım yapılmaz; mevcut durum doğrulanır.
- RESEARCH bulguları gerçek kod/veri ile yeniden teyit edilir.

### LOCK — kapsam kilidi
- O katmanın kapsamı, dokunulacak yüzeyleri ve DoD maddeleri kilitlenir.
- Sonradan yeni özellik eklenmez; yeni ihtiyaç ayrı alt plan olur.
- Kullanıcı onayından sonra kapsam değiştirilmez; değişiklik gerekiyorsa yeniden RESEARCH kapısına dönülür.

### BUILD — en küçük güvenli uygulama
- En küçük güvenli değişiklik yapılır.
- Çalışan mevcut akışlar yeniden yazılmaz.
- Gereksiz refactor yapılmaz.
- Araştırmada doğrulanmayan yeni davranış eklenmez.

### VERIFY — uygulama sonrası doğrulama
- Tip/test/build
- Gerekirse migration güvenlik kontrolü
- Preview
- Mobil/masaüstü ekran doğrulaması
- Public vitrin regresyon kontrolü
- Araştırmada tanımlanan kabul kriterlerinin tek tek doğrulanması
- Yeni davranışın Vixrex UX-FIT kriterlerini uygulama sonrasında da koruduğunun kontrolü

### DECIDE
- Sonuç kullanıcıya kısa ve doğrulanabilir biçimde sunulur.
- Geçen/kalan maddeler açıkça ayrılır.
- Kullanıcı onayı yoksa main'e merge edilmez.

### MERGE
- Sadece araştırılmış, UX uyumu onaylanmış, doğrulanmış ve kullanıcı tarafından onaylanmış katman main'e iner.
- Sonraki katman yeni main'den ve yeniden RESEARCH aşamasından başlar.

## 3. Her katman için zorunlu araştırma paketi

Aşağıdaki araştırma paketi 1–5 arasındaki her katmanda tekrar edilir:

### A. Kod ve veri araştırması
- Mevcut dosyalar, route'lar, API'ler, tablolar, RLS/policy ve ortak veri kaynakları
- Mevcut davranışın gerçek kaynağı
- Aynı işi zaten yapan yüzey varsa yeniden icat edilmemesi

### B. UX araştırması
- Mevcut Vixrex ekran yapısı
- Mobil ve masaüstü davranış
- CTA, başlık, kart, liste, sheet/modal ve asistan kullanım biçimi
- Keşfet, owner ve public vitrinle görsel/davranış paritesi

### C. Ürün akışı araştırması
- Esnaf ne görür?
- Tüketici ne görür?
- Hangi adım açık kullanıcı onayı gerektirir?
- Hangi veri taslak, hangisi public olur?

### D. Güvenlik ve regresyon araştırması
- Yetkisiz erişim
- Taslak/public veri sızıntısı
- RLS ve owner-session etkisi
- Mevcut vitrin, Kirala, Keşfet ve Asistan akışlarına etkisi

### E. Ölçek araştırması
- Günlük içerik artışı
- 1000+ yazı
- çoklu sektör/şehir
- sorgu, sitemap ve sayfa üretim maliyeti
- veri modelinin gelecekteki Dijital Çarşı ilişkilerine uygunluğu

### F. Onay kapısı
Her katman için araştırma sonucu şu üç durumdan biriyle kapanır:
- **UYGUN — BUILD'e geçilebilir**
- **UYGUN AMA ŞARTLI — belirtilen risk giderilmeden BUILD yok**
- **UYGUN DEĞİL — plan yeniden tasarlanır**

Kullanıcının açık onayı olmadan BUILD başlamaz.

## 4. GİRİŞ — Katman 1: Vixrex Blog Omurgası

### Amaç
Mevcut `/blog` yüzeyini günlük büyüyebilen gerçek bir Vixrex içerik sistemine dönüştürmek.

### Mevcut gerçeklik
- `/blog` route'u var.
- Vixrex yazıları şu an kod içindeki `blogYazilari.ts` dosyasında tutuluyor.
- Yayında yazı yoksa `/blog` bilinçli 404 veriyor.
- Esnaf yazıları ayrı olarak `store_articles` tablosunda yaşıyor.

### Araştırma kapısı
- Mevcut `(site)/blog`, sitemap, metadata ve `blogYazilari.ts` akışı incelenir.
- Vixrex landing/yardım/Keşfet tasarım diliyle blog ana sayfa UX uyumu karşılaştırılır.
- Merkezi içerik için yeni tablo mu, mevcut modelin genişletilmesi mi daha güvenli doğrulanır.
- Public RLS, taslak/yayın ayrımı ve sitemap davranışı araştırılır.
- 1000+ yazı büyümesi için veri ve sayfalama modeli doğrulanır.

### Bu katmanda yapılacak
- Vixrex'in kendi yazıları için kalıcı merkezi içerik modeli oluşturulur.
- Mevcut iki taslak yazı yeni modele taşınır.
- `/blog` ve `/blog/[slug]` yeni merkezi kaynaktan okur.
- Taslak/yayın durumu korunur.
- Sitemap ve canonical davranışı korunur.
- Büyük liste görünümü; kategori, konu ve ileride şehir/sektör genişlemesine uygun hale getirilir.

### Bu katmanda yapılmayacak
- Asistan entegrasyonu yok.
- Esnaf vitrini içine yazı çekme yok.
- Vitrinler arası bağlantı yok.
- Toplu otomatik yayın yok.

### DoD
- Mevcut `/blog` davranışı kırılmaz.
- Taslak yazı public'e sızmaz.
- En az bir yazı yayınlandığında liste ve detay sayfası doğru açılır.
- 1000+ yazıya doğru veri modeliyle büyüyebilir.
- Main public vitrin davranışında regresyon yok.
- Blog görünümü mevcut Vixrex UX diliyle uyumlu olduğu ekran doğrulamasıyla onaylanır.

## 5. GELİŞME — Katman 2: Merkezi Blog Kütüphanesi

### Amaç
Vixrex blogunu yalnız yazı listesi olmaktan çıkarıp esnaf ve asistanın kullanabileceği yapılandırılmış bilgi kütüphanesine çevirmek.

### Araştırma kapısı
- Mevcut business category core ve yer/konum veri yapıları incelenir.
- Yeni taksonominin mevcut kategori kaynaklarıyla çakışmaması doğrulanır.
- Kullanıcıların büyük içerik kataloğunda konu/sector/şehir bulma UX'i araştırılır.
- Arama/filtreleme ihtiyacı mevcut veri büyüklüğü ve gelecekteki ölçekle karşılaştırılır.

### Kilitli içerik nitelikleri
- konu
- sektör/kategori
- şehir/ilçe uygunluğu
- kullanım amacı
- etiketler
- yayın durumu
- güncelleme tarihi
- kaynak/provenance bilgisi
- ilişkilendirilebilir ilgili yazılar

### Görünüm
- Ana blog: öne çıkan içerik + kategori/konu blokları + son yazılar
- Kategori/konu sayfalarına büyüyebilir yapı
- Mobilde taranabilir, masaüstünde geniş katalog hissi

### DoD
- Yazılar yalnız başlığa göre değil yapılandırılmış sınıflandırmayla bulunabilir.
- Kütüphane büyüdükçe tek dosya/tek dev liste darboğazına dönüşmez.
- Esnaf ve asistan için makine tarafından sorgulanabilir bir içerik kaynağı oluşur.
- Taksonomi mevcut Vixrex kategori/veri kaynaklarıyla uyumlu olduğu doğrulanır.

## 6. GELİŞME — Katman 3: Vitrine Yazı Çekme / Taslak Enjeksiyonu

### Amaç
Bir Vixrex merkezi yazısını kullanıcının kendi vitrininin bloguna güvenli biçimde çekebilmek.

### Araştırma kapısı
- Mevcut `store_articles` CRUD, RLS, owner-session ve yayın akışı incelenir.
- Flutter/Next.js davranış eşitliği araştırılır.
- Kopya içerik ve kaynak ilişkisinin veri modelinde nasıl tutulacağı doğrulanır.
- Esnafın seçme → taslak oluşturma → düzenleme → yayınlama UX'i mevcut owner ekranına uygunluk açısından incelenir.

### Kilitli davranış
- Kullanıcı yazıyı seçer.
- Sistem doğrudan yayınlamaz.
- `store_articles` içinde **taslak** oluşturur.
- Kaynak Vixrex yazısıyla ilişki kaydedilir.
- Aynı yazının aynı vitrine istemeden tekrar tekrar kopyalanması engellenir.
- Esnaf taslağı görür, düzenler ve mevcut yayın akışıyla yayınlar.

### İçerik çoğaltma kuralı
Aynı merkezi yazının yüzlerce vitrine birebir SEO kopyası olarak otomatik yayınlanması yasaktır.

İki güvenli mod bırakılır:
1. **Kaynak bağlantılı kısa sürüm**
2. **Vitrine uyarlanmış taslak sürüm**

### DoD
- Yetkisiz kullanıcı başka vitrinin bloguna yazı ekleyemez.
- Yazı hiçbir koşulda açık onay olmadan `published` olmaz.
- Kaynak bağlantısı kaybolmaz.
- Mevcut `store_articles` CRUD akışı kırılmaz.
- Owner UX'inde yeni akış mevcut asistan/sahiplik davranışını bozmaz.

## 7. GELİŞME — Katman 4: Vixrex Asistan Blog Komutları

### Amaç
Mevcut 46 vitrin alanı motorunu bozmadan, Asistan'a ayrı bir blog eylem alanı kazandırmak.

### Araştırma kapısı
- Mevcut 46 alan niyet boru hattı ve mesaj/owner action akışı incelenir.
- Blog komutlarının mevcut niyet sözlüğüne karışmadan ayrı domain olarak nasıl bağlanacağı doğrulanır.
- Belirsizlik, onay, hata ve başarı mesajlarının mevcut Vixrex Asistan UX'iyle uyumu araştırılır.
- Feature flag kapalı davranış eşitliği test stratejisi kilitlenir.

### Mimari kural
Blog komutları 46 alan sözlüğünün içine zorla sokulmaz.

Ayrı niyet ailesi oluşturulur:
- `blog_yazisi_bul`
- `blog_yazisi_oner`
- `blog_yazisi_taslak_ekle`
- `blog_taslaklarini_listele`
- `blog_taslak_duzenle`
- `blog_yayinla` (yalnız açık kullanıcı onayıyla)

### Örnek deterministik akış
`"Google'da görünmek hakkında vitrinin bloguna yazı ekle"`

→ niyet: `blog_yazisi_taslak_ekle`
→ konu: Google görünürlüğü
→ mevcut mağaza kategorisi/konumu
→ merkezi kütüphaneden uygun yazı
→ kullanıcıya seçim/özet
→ açık onay
→ `store_articles` taslağı

### DoD
- Mevcut 46 alan motoru davranış eşitliğini korur.
- Feature flag kapalıyken mevcut asistan davranışı değişmez.
- Belirsiz istekte otomatik yayın yapılmaz.
- Hata halinde başarı mesajı üretilmez.
- Mobil asistan UX'i #413 sonrası doğrulanmış davranışı korur.

## 8. SONUÇ — Katman 5: Dijital Çarşı Bağlantı Omurgası

### Amaç
Blog içeriğini Vixrex'teki işletmeleri birbirine ve tüketiciye bağlayan ilk kontrollü ağ yüzeyine çevirmek.

### Araştırma kapısı
- Mevcut Keşfet, vitrin blogu, public vitrin ve planlanan Dijital Çarşı ilişkileri birlikte incelenir.
- Kullanıcıya gösterilecek "ilgili işletme" ilişkisinin hangi doğrulanabilir verilere dayanacağı kilitlenir.
- SEO/internal-link faydası ile spam/backlink ağı riski resmi arama motoru rehberleriyle karşılaştırılır.
- Mobilde ilgili vitrin/rehber bloklarının mevcut public vitrin UX'ini bozmaması doğrulanır.

### Temel ilişki türleri
- yazı ↔ ilgili Vixrex vitrini
- yazı ↔ sektör
- yazı ↔ şehir/ilçe
- vitrin ↔ ilgili/tamamlayıcı vitrin
- vitrin ↔ bağlı dijital çarşı

### Kullanıcı görünümü
Bir merkezi rehberde:
- ilgili işletmeler
- aynı bölgede ilgili vitrinler
- tamamlayıcı hizmetler
- ilgili başka rehberler

Bir vitrin blog yazısında:
- kaynak Vixrex rehberi
- ilgili yerel vitrinler
- varsa bağlı dijital çarşı

### Güvenlik/kalite kuralı
- Otomatik bağlantı yalnız doğrulanmış ilişki kurallarına göre oluşturulur.
- Rastgele backlink ağı kurulmaz.
- Kullanıcıyı yanıltan sahte ortaklık/iş birliği ifadesi üretilmez.

### DoD
- Blog, keşfet ve vitrinler arasında gerçek internal-link grafiği oluşur.
- İlişkiler DB'de açıkça temsil edilir.
- Bağlantılar kullanıcıya neden gösterildiği anlaşılır biçimde sunulur.
- Dijital Çarşı'nın sonraki davet/hediyeleşme katmanları bu omurgaya bağlanabilir.
- Public UX ve SEO davranışı araştırma aşamasındaki kabul kriterleriyle tekrar doğrulanır.

## 9. Katmanlı detay kapısı

Ana sıra değiştirilmez. Her başlık gerektiğinde kendi alt planına açılabilir:

- `1.x` Blog veri modeli ve migration
- `1.x` Blog ana sayfa UX
- `2.x` Taksonomi ve arama
- `3.x` Import/taslak güvenliği
- `4.x` Asistan niyet sözlüğü
- `4.x` Blog eylem adapteri
- `5.x` Store connection veri modeli
- `5.x` Dijital Çarşı görünüm kuralları

Her `x` alt planı da kendi RESEARCH → UX-FIT → LOOK → LOCK → BUILD → VERIFY kapılarından geçer.
Alt planlar ana sırayı değiştiremez.

## 10. Giriş → Gelişme → Sonuç çerçevesi

### Giriş
Vixrex önce kendi içerik omurgasını ve merkezi bilgi kütüphanesini kurar.

### Gelişme
Esnaf bu bilgiyi kendi vitrinine güvenli taslak olarak çeker; Vixrex Asistan bu işlemi konuşarak yönetebilir hale gelir.

### Sonuç
İçerik yalnız okunmaz; Vixrex yazıları, vitrinler ve yerel işletmeler arasında doğrulanabilir bağlantılar kurarak Dijital Çarşı'nın içerik ve keşif omurgasını oluşturur.

## 11. Merge kuralları

- Her katman ayrı PR.
- Her katman önce RESEARCH + UX-FIT raporu ve kullanıcı onayından geçer.
- Araştırma onayı olmadan kod yazılmaz.
- Önce test/Preview/ekran doğrulaması.
- Kullanıcının açık onayı olmadan main'e merge yok.
- Bir katmanda regresyon varsa bir sonraki katmana geçilmez.
- Geri dönüş gerektiğinde `checkpoint/main-post-413-20260904` güvenli başlangıç noktasıdır.
