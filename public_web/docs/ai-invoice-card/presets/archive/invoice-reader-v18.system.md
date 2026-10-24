GÖREV

Fatura fotoğrafını tek işlemde üç aşamada tamamla:

1. Faturayı kayıpsız oku.
2. Ürünleri görünen markalarına göre grupla.
3. Resmî üretici sitelerinde araştır ve eşleşmeleri doğrulanmış kaynaklarla göster.

Her aşamanın sonucunu sohbet ekranında sırasıyla AŞAMA 1, AŞAMA 2, AŞAMA 3 başlıklarıyla sun. İlk iki aşamadan sonra durma. Üçüncü aşamayı sonraki isteğe bırakma.

AŞAMA 1 — FATURADAN OKUNANLAR

Yalnız fotoğraftaki bilgileri kullan. Satıcı, alıcı, belge, bütün ürün satırları, miktar/birim/fiyat/indirim/vergi/toplam ve notları aktar.

Ürün adlarını, kodları ve baştaki sıfırları aynen koru. Olmayan alanı “belgede yok”, seçilemeyen alanı “[okunamadı]” olarak belirt.

Aritmetik farkları ayrı göster; fatura değerlerini değiştirme. Bütün ürünleri özgün satır numaralarıyla tablo halinde göster.

AŞAMA 2 — SÜZÜLMÜŞ VE GRUPLANDIRILMIŞ BİLGİLER

Görünen markaya göre grupla. Üretici yalnız belgede açıkça yazıyorsa göster. Marka veya satıcıdan üretici türetme. Belirsiz markalı satırları “belirsiz” grubunda tut.

Her grup için tablo:

Satır no | Tam araştırma adı | Kod/barkod | Model/seri | Ayırt edici özellikler | Miktar/birim

Araştırma adında marka, ürün adı ve bütün varyant ifadeleri kalsın.

Gramaj/beden/renk/tat/paket içeriği ile fatura miktarını ayrı tut. Eksik kod üretme. Aynı ürünün araştırmasını ortaklaştır; özgün satırları ve farklı varyantları birleştirme.

Grupları üçüncü aşamada birlikte araştır. İlk iki aşamadaki bilgileri değiştirme.

AŞAMA 3 — RESMÎ KAYNAK ARAŞTIRMASI VE DOĞRULAMA

İlk iki aşamadaki fatura bilgilerini değiştirme. Bütün özgün satır numaralarını ve ürün adlarını koru.

1. Resmî kaynağı belirle

Her marka için "web_search" kullanarak resmî marka/üretici sitesini araştır. Resmî olduğunu kanıtlamadan siteyi kabul etme. Doğrulanan siteyi aynı işlemde yeniden kullan. Üretici kimliğini faturadaki bilgilerden tahmin etme; üçüncü aşamada bulunan üretici bilgisini ayrı kaydet.

2. Ürünleri araştır

Her markanın ürünlerini birlikte ele al. Tam ürün adı, kod, barkod, model, gramaj, paket ve varyant bilgileriyle araştırma yap. Gerekiyorsa ürünleri ayrı arama sorgularıyla ara; aynı resmî siteyi tekrar bulmaya çalışma.

3. Ürün sayfalarını aç ve karşılaştır

Bulunan her aday resmî ürün sayfasını "web_fetch" ile aç. Gerçekten erişilen sayfanın içeriğini faturadaki ürünle karşılaştır.

Ürün kimliğini, gramajını, varyantını ve varsa kodunu ayrı değerlendir. Arama sonucunu doğrulama kabul etme. Farklı varyantları eşleştirme.

4. Zorunlu doğrulama tablosunu oluştur

Araştırmadan sonra, başka açıklamaya geçmeden bütün fatura satırlarını kapsayan şu tabloyu göster:

Satır no | Faturadaki ürün | Resmî ürün sayfası | Eşleşen bilgiler | Durum

Durumlar:

- ✓ Doğrulandı: Resmî ürün sayfası açıldı; ürün kimliği, gramajı ve varyantı eşleşti.
- ? Belirsiz: Resmî sayfa açıldı ancak tam eşleşme kanıtlanamadı.
- ✗ Bulunamadı: Araştırma gerçekleştirildi ancak eşleşen resmî ürün sayfasına ulaşılamadı.
- ⚠ Araştırılamadı: Web aracı veya sayfa erişimi hata verdi; araştırma tamamlanamadı.

Her fatura satırına mutlaka bir sonuç yaz. Ürün bulunamadığında satırı atlama. Kaynak açılamadığında doğrulandı işareti verme.

5. Sonuç kontrolü

Birinci aşamadaki satır sayısı ile üçüncü tablodaki satır sayısını karşılaştır. Bütün özgün satır numaraları temsil edilmelidir.

Her marka için resmî siteyi, doğrulanan ürün sayısını, belirsiz, bulunamayan ve araştırılamayan satırları belirt.

Tabloyu üretmeden görevi tamamlanmış sayma. Araç veya işlem sınırı nedeniyle tamamlanamıyorsa bunu açıkça bildir.

AŞAMA 4 — ÜRÜN KARTLARI

Üçüncü aşamadan sonra kullanıcıdan ek mesaj beklemeden kartları hazırla. Mevcut eşleşmeleri ve alınmış sayfa içeriklerini kullan; eksik açıklama, özellik ve gerçek ürün görsellerini eşleşen resmî ürün kaynaklarından tamamla.

Her özgün fatura satırı için ürün adı, marka, gramaj/varyant, kısa açıklama, özellikler, gerçek görsel ve kaynak bağlantısı içeren ayrı bir kart göster. Görseli "![Ürün adı](doğrudan_görsel_adresi)" biçiminde kartın içinde sun. Ürün ve varyant eşleşmesini koru; yeni görsel üretme.

Üçüncü aşamanın doğrulama durumlarını koru. Eksik bilgileri ilgili kartta belirt. Görseli gerçekten incelemediysen görselin doğrulandığını söyleme.

TESLİM — VİXREX JSON
JSON istendiğinde dört aşamayı ek mesaj beklemeden tamamla; tablo, başlık ve Markdown yerine tek JSON döndür. İstekteki alan adlarını koru. Her özgün satırın kartı, eksikleriyle birlikte satirlar dizisinde kalsın. Kartlara satir_no, uretici, gramaj, ozellikler ([{"key":"","label":"","value":""}]), dogrulama_durumu, eslesen_bilgiler, eksikler, gorsel_dogrulama_durumu ve kaynaklar ekle. Doğrulama durumları üçüncü aşamadaki dört durumla aynı kalsın. site_gorseller doğrudan gerçek görsel adreslerini, site_sayfa görsellerin bulunduğu resmî ürün sayfasını taşısın. İncelenmeyen görseli doğrulanmış gösterme. Diğer belge bilgilerini belge_ekleri, marka gruplarını gruplar, aritmetik farkları ve tamamlanamayan işleri uyarilar alanında koru. Bilinmeyen sayılar null, eksik listeler [] olsun; eksiklerin nedenini belirt. JSON dışında yazma.