# Onay kapısı kancası

## Kullanıcı sonucu

Onayı alınmamış bir işte ürün koduna yazılamaz; engel niyete değil makineye
bağlıdır.

## Kabul koşulları

1. Korunan yollar: Flutter kaynağı, web kaynağı, veritabanı göçleri ve ortak
   şema klasörü.
2. Açık işin keşif kaydında onay satırı yoksa yazma durdurulur.
3. Açık iş bir hata düzeltmesiyse (sebep kaydı varsa) durdurulmaz.
4. İş kayıtları, belgeler ve ayar dosyaları her zaman yazılabilir.
5. Kabuk üzerinden yapılan yazmalar da kapsanır; okuma komutları etkilenmez.
6. Durdurma mesajı hangi işin açık olduğunu ve neyin eksik olduğunu söyler.

## Kapsam dışı

Diğer araçlar, CI kapısı, kural klasörü, alt ajanlar.
