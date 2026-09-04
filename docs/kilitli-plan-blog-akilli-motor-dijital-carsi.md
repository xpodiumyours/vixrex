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

## 2. Çalışma yöntemi — LOOK döngüsü

Her katmanda aynı döngü uygulanır:

### LOOK
- Sadece o katmanın mevcut kodu, DB şeması ve canlı davranışı incelenir.
- Varsayım yapılmaz; mevcut durum doğrulanır.

### LOCK
- O katmanın kapsamı, dokunulacak yüzeyleri ve DoD maddeleri kilitlenir.
- Sonradan yeni özellik eklenmez; yeni ihtiyaç ayrı alt plan olur.

### BUILD
- En küçük güvenli değişiklik yapılır.
- Çalışan mevcut akışlar yeniden yazılmaz.

### VERIFY
- Tip/test/build
- Gerekirse migration güvenlik kontrolü
- Preview
- Mobil/masaüstü ekran doğrulaması
- Public vitrin regresyon kontrolü

### DECIDE
- Sonuç kullanıcıya kısa ve doğrulanabilir biçimde sunulur.
- Kullanıcı onayı yoksa main'e merge edilmez.

### MERGE
- Sadece doğrulanmış ve onaylanmış katman main'e iner.
- Sonraki katman yeni main'den başlar.

## 3. GİRİŞ — Katman 1: Vixrex Blog Omurgası

### Amaç
Mevcut `/blog` yüzeyini günlük büyüyebilen gerçek bir Vixrex içerik sistemine dönüştürmek.

### Mevcut gerçeklik
- `/blog` route'u var.
- Vixrex yazıları şu an kod içindeki `blogYazilari.ts` dosyasında tutuluyor.
- Yayında yazı yoksa `/blog` bilinçli 404 veriyor.
- Esnaf yazıları ayrı olarak `store_articles` tablosunda yaşıyor.

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

## 4. GELİŞME — Katman 2: Merkezi Blog Kütüphanesi

### Amaç
Vixrex blogunu yalnız yazı listesi olmaktan çıkarıp esnaf ve asistanın kullanabileceği yapılandırılmış bilgi kütüphanesine çevirmek.

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

## 5. GELİŞME — Katman 3: Vitrine Yazı Çekme / Taslak Enjeksiyonu

### Amaç
Bir Vixrex merkezi yazısını kullanıcının kendi vitrininin bloguna güvenli biçimde çekebilmek.

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

## 6. GELİŞME — Katman 4: Vixrex Asistan Blog Komutları

### Amaç
Mevcut 46 vitrin alanı motorunu bozmadan, Asistan'a ayrı bir blog eylem alanı kazandırmak.

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

## 7. SONUÇ — Katman 5: Dijital Çarşı Bağlantı Omurgası

### Amaç
Blog içeriğini Vixrex'teki işletmeleri birbirine ve tüketiciye bağlayan ilk kontrollü ağ yüzeyine çevirmek.

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

## 8. Katmanlı detay kapısı

Ana sıra değiştirilmez. Her başlık gerektiğinde kendi alt planına açılabilir:

- `1.x` Blog veri modeli ve migration
- `1.x` Blog ana sayfa UX
- `2.x` Taksonomi ve arama
- `3.x` Import/taslak güvenliği
- `4.x` Asistan niyet sözlüğü
- `4.x` Blog eylem adapteri
- `5.x` Store connection veri modeli
- `5.x` Dijital Çarşı görünüm kuralları

Alt planlar ana sırayı değiştiremez.

## 9. Giriş → Gelişme → Sonuç çerçevesi

### Giriş
Vixrex önce kendi içerik omurgasını ve merkezi bilgi kütüphanesini kurar.

### Gelişme
Esnaf bu bilgiyi kendi vitrinine güvenli taslak olarak çeker; Vixrex Asistan bu işlemi konuşarak yönetebilir hale gelir.

### Sonuç
İçerik yalnız okunmaz; Vixrex yazıları, vitrinler ve yerel işletmeler arasında doğrulanabilir bağlantılar kurarak Dijital Çarşı'nın içerik ve keşif omurgasını oluşturur.

## 10. Merge kuralları

- Her katman ayrı PR.
- Önce test/Preview/ekran doğrulaması.
- Kullanıcının açık onayı olmadan main'e merge yok.
- Bir katmanda regresyon varsa bir sonraki katmana geçilmez.
- Geri dönüş gerektiğinde `checkpoint/main-post-413-20260904` güvenli başlangıç noktasıdır.
