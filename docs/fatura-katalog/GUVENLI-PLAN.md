# Faturadan Kataloğa — Güvenli Tamamlama Planı

Tarih: 2026-09-22  
Dal: `plan/fatura-katalog-guvenli-20260922`  
Taban: `main@0034fe06942c4fdbe625f24bc338ef8cfa6e8a0b`

## 1. Değişmeyecek hedef

Esnaf yalnızca gerçek faturayı fotoğraf veya dosya olarak verir.

Vixrex:
1. faturayı gerçekten okur,
2. ürün satırlarını gerçekten ayırır,
3. model / barkod / ürün adı / renk-varyant / beden / adet / alış fiyatı / satır toplamını kaynaktan çıkarır,
4. ürün kimliğini gerçek verilerle çözmeye çalışır,
5. izinli ve doğrulanabilir ürün bilgisi/görseli bulursa ekler,
6. satış fiyatını alış fiyatından ayrı tutar,
7. ürün kartlarını taslak olarak hazırlar,
8. esnaf onaylamadan yayınlamaz,
9. onaylanan ürünleri mevcut Vixrex Product CORE üzerinden vitrinde yayınlar.

Başarı, yalnız gerçek fatura girdisinden gerçek sistem çıktısı üretildiğinde kabul edilir.

## 2. Kırmızı çizgiler

Aşağıdakiler bu çalışmada başarı kanıtı OLAMAZ:

- önceden elle yazılmış ürün listesi,
- faturadan elle kopyalanmış barkod/model/fiyatların sistem çıktısı gibi gösterilmesi,
- sentetik veya sahte OCR sonucu,
- hardcoded ürün kartları,
- timeout ile ilerleyen demo tarama,
- gerçek dış servis bağlantısı yokken “ürün bulundu” simülasyonu,
- görsel bulunamadığında rastgele internet görseli,
- AI'ın kaynakta bulunmayan barkod, fiyat, model veya ürün gerçeği üretmesi,
- yalnızca testin yeşil olması,
- yalnızca HTML/prototipin çalışması,
- yalnızca birkaç örnek için özel yazılmış kural,
- “MVP” adı altında üretim hedefinin daha dar/sahte bir sürümle değiştirilmesi.

Bir alan doğrulanamıyorsa sonuç `doğrulanamadı` olarak kalır. Sistem boşluğu uydurarak doldurmaz.

## 3. Kullanıcıya teknik iş yükleme yasağı

Kullanıcıdan şu işler istenmez:

- JSON hazırlamak,
- barkod listesi yazmak,
- doğru cevap dosyası doldurmak,
- OCR ayarı seçmek,
- model eşleştirme kuralı belirlemek,
- test verisi üretmek,
- API biçimi tanımlamak,
- teknik doğrulama yapmak.

Kullanıcının sağlayacağı normal girdi, gerçek hayatta esnafın sağlayacağı girdiden daha teknik olamaz: örneğin fatura fotoğrafı.

Teknik araştırma, veri bağlantısı, test, ölçüm ve doğrulama bu çalışma kapsamının sorumluluğudur.

## 4. Kanıt kuralı

Bir bilgi “doğru” kabul edilmeden önce gerçek bir kaynağa bağlanır.

Kanıt önceliği:
1. faturanın kendisi,
2. barkod/GTIN matematiksel doğrulaması ve satır toplamı hesapları,
3. gerçek tedarikçi / üretici XML veya API verisi,
4. gerçek Vixrex ürün hafızasında daha önce doğrulanmış kayıt,
5. bağımsız ikinci okuma/servis sonucu.

İki kaynak çelişirse sonuç otomatik olarak doğru sayılmaz. Belirsiz kalır ve raporda gösterilir.

Eski `work/fatura-katalog-e2e-20260922` dalındaki elle hazırlanmış referans kayıtlar ve ölçüm sonuçları bu plan için gerçeklik kaynağı değildir ve yeni dala taşınmaz.

## 5. Ölçüm sistemi kuralı

Ölçüm sistemi geliştirilen motorun kendi cevabını “doğru cevap” olarak kullanamaz.

Ölçüm:
- gerçek kaynak görüntüsünü saklar veya güvenli referansını tutar,
- sistemin ham çıktısını ayrı kaydeder,
- doğrulanmış dış/bağımsız kanıtı ayrı tutar,
- hangi alanın hangi kanıtla doğrulandığını gösterir,
- doğrulanamayan alanı skora zorla katmaz,
- yanlış, eksik ve fazla ürünü ayrı raporlar,
- aynı ölçüm setini her geliştirme sonrası tekrar çalıştırır.

Ölçüm motoru ile üretim motoru aynı sabit/hardcoded ürün verisini paylaşamaz.

## 6. Kapsam kilidi

Bu çalışma yalnız şu uçtan uca yolu tamamlar:

`gerçek fatura → gerçek okuma → ürün satırı → ürün kimliği → zenginleştirme → taslak ürün kartı → satış fiyatı/onay → Product CORE → vitrin`

Bu çalışma sırasında aşağıdakiler açılmaz:
- ödeme sistemi,
- 46 vitrin alanı,
- Vixrex asistan NLU,
- kiralık vitrin sistemi,
- keşfet tasarımı,
- blog,
- randevu,
- genel public vitrin tasarımı,
- yeni e-ticaret altyapısı.

Yeni bir ihtiyaç çıkarsa `DURUM.md` içindeki Park alanına yazılır. Kullanıcı onayı olmadan kapsama alınmaz.

## 7. Güvenli geliştirme sınırı

Bu dalda:
- main'e doğrudan yazılmaz,
- PR açılmaz,
- merge yapılmaz,
- production deploy yapılmaz,
- canlı Supabase migration uygulanmaz,
- canlı veri değiştirilmez,
- gerçek fatura dış AI'a kullanıcı onayı olmadan gönderilmez,
- `verify-*` adlı deploy tetikleyen dal kullanılmaz.

Her kod adımından önce:
1. ilgili dosyalar salt-okuma incelenir,
2. aynı dosyalardaki son commitler kontrol edilir,
3. değişecek yüzey yazılır,
4. yalnız o yüzey değiştirilir.

## 8. Fazlar

### Faz A — Gerçek giriş ve ham okuma

Amaç: gerçek fatura fotoğrafı sisteme verildiğinde sistemin gerçekten ne okuduğunu elde etmek.

Çıktı:
- gerçek OCR ham metni,
- satır ve konum bilgileri,
- görüntü kalitesi/okunabilirlik durumu.

Yasak:
- elle ürün doldurma,
- sentetik OCR,
- beklenen ürünü kod içine yazma.

Kabul:
- aynı gerçek dosya sisteme girer ve ham OCR çıktısı otomatik oluşur.

### Faz B — Gerçek ürün satırı çıkarma

Amaç: ham okumadan ürün satırlarını kayıpsız ayırmak.

Çıktı:
- model,
- barkod,
- ürün adı,
- renk/varyant,
- beden,
- adet,
- alış fiyatı,
- satır toplamı,
- her alanın kaynağı ve güven durumu.

Kabul:
- alanlar yalnız OCR/kaynak veriden gelir,
- bulunmayan bilgi uydurulmaz,
- toplamlar aritmetik olarak kontrol edilir.

### Faz C — Ürün kimliği

Amaç: faturadaki satırın hangi gerçek ürüne ait olduğunu çözmek.

Sıra:
1. GTIN/barkod,
2. tedarikçi + model/SKU,
3. Vixrex doğrulanmış ürün hafızası,
4. gerçek tedarikçi/üretici feed'i,
5. kontrollü benzerlik,
6. doğrulanamadı.

Kabul:
- eşleşmenin kaynağı görünür,
- belirsiz eşleşme kesin ürün gibi sunulmaz.

### Faz D — Ürün bilgisi ve görsel

Amaç: ürün kartını gerçek ve kullanım hakkı belli verilerle tamamlamak.

Kaynak sırası:
1. doğrulanmış Vixrex kaydı,
2. tedarikçi/üretici XML/API,
3. izinli resmi veri kaynağı,
4. esnafın kendi görseli.

Kabul:
- her görselin kaynağı bilinir,
- rastgele web görseli kullanılmaz,
- bilgi bulunamazsa alan boş/doğrulanamadı kalır.

### Faz E — Taslak ürün kartları

Amaç: gerçek çıkarılan/zenginleştirilen veriyi mevcut Product CORE biçimine dönüştürmek.

Kurallar:
- alış fiyatı müşteri satış fiyatı değildir,
- ürün önce taslaktır,
- esnaf onayı olmadan public olmaz,
- aynı fatura tekrar işlenince kopya üretmemelidir.

### Faz F — Ön yüz

Hedef, daha önce çizilen “Faturanı çek. Ürünlerin hazır olsun.” deneyimidir.

Flutter ve Next.js aynı gerçek backend sonucunu kullanır:
- fatura seç,
- gerçek işleme durumu,
- hazırlanan gerçek kartlar,
- satış fiyatı,
- onay,
- yayın.

UI için ikinci sahte veri sistemi kurulmaz.

### Faz G — Ölçüm ve kabul

Gerçek fatura seti sistemden geçirilir.

Her fatura için gösterilecek:
- kaç ürün satırı bulundu,
- kaç alan doğrudan kaynaktan doğrulandı,
- kaç alan bağımsız kaynakla doğrulandı,
- kaç alan doğrulanamadı,
- eksik/fazla ürün,
- toplam adet/tutar tutarlılığı,
- dış servis çağrısı,
- AI çağrısı,
- maliyet,
- insan müdahalesi gereken yer.

Başarı raporu, hardcoded/elle girilmiş ürün verisine dayanamaz.

## 9. Her adımda kullanıcıya gösterilecek rapor

Her tamamlanan adımda `DURUM.md` güncellenir ve kullanıcıya şu beş cevap verilir:

1. **Önce ne vardı?**
2. **Tam olarak ne değiştirdik?**
3. **Gerçek girdide ne kazandık?**
4. **Ne hâlâ çalışmıyor / doğrulanamadı?**
5. **Canlıya, main'e veya başka sisteme dokunuldu mu?**

“Bitti”, “çalışıyor” veya “hazır” kelimeleri ancak ilgili kabul kanıtı gerçekten üretildiyse kullanılır.

## 10. Tamamlanmış sayılma şartı

Bu iş ancak şu gerçek kullanıcı akışı kanıtlandığında tamamlanır:

`fatura fotoğrafı yükle → otomatik oku → gerçek ürünleri çıkar → doğrulanabilir ürün bilgisi/görseli tamamla → satış fiyatını belirle → onayla → Vixrex ürün kartlarını oluştur → vitrinde göster`

Bu zincirin herhangi bir adımı demo, hardcoded, elle doldurulmuş veya simüle ise çalışma tamamlanmış sayılmaz.
