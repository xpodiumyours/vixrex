# AGENTS.md — Vixrex ortak gelişim kuralları

Bu dosya Vixrex deposunda çalışan bütün insanlar ve yapay zekâ araçları için
geçerlidir. Kuralın kaynağı kullanılan araç değil, Vixrex gelişim sistemidir.
Hiçbir araç için ayrı zorunluluk, yasak veya teslim yolu kurulamaz. Araçlara
özel dosyalar yalnız kullanım kolaylığı sağlayabilir; ortak süreci daraltamaz,
genişletemez veya başka bir aracı engelleyemez.

## Önce iş türünü belirle

1. **Yeni özellik veya davranış değişikliği:** önce Keşif yazılır — bugünkü
   çalışan hâl gerçek dosya yollarıyla ölçülür; işin nereden başlayıp nerede
   biteceği, ne ve nasıl gözükeceği, esnafa, Vixrex'e ve tüketiciye ne
   katacağı yazılır ve Furkan onaylar. Sonra `DEVELOPMENT.md` içindeki tam
   gelişim zinciri izlenir.
2. **Hata düzeltmesi:** hata yeniden görülür, gerçek sebep bulunur, en küçük
   doğru düzeltme yapılır, aynı hata tekrar denenir ve incelemeye gönderilir.
3. **Yeni fikir veya araştırma:** önce kanıt toplanır ve “yapalım mı?” kararı
   verilir. Karar verilmeden ürün kodu değiştirilmez.

Bir hata düzeltmesi yeni kullanıcı sonucu, veri yapısı, güvenlik kuralı, ekran
akışı veya yayın davranışı oluşturuyorsa artık “hata” değildir; tam gelişim
zincirine geçer.

## Ortak çalışma biçimi

1. Furkan doğal Türkçeyle sonucu söyler; teknik kapsamı ve dosyaları üretici
   araştırır ve Keşif kaydında yazılı hâle getirir.
2. Kod, belge, canlı yüzey veya yetkili araçla bulunabilen bilgi Furkan'a
   sorulmaz.
3. Yalnız para, hukuk, görünüm, içerik, veri kaybı, gizlilik, canlı işlem veya
   iki farklı ürün sonucu için tek sade soru sorulur.
4. Tahminle değişiklik yapılmaz. Mevcut davranış ve etkilenen yüzeyler önce
   ölçülür.
5. Aynı bilgi iki yerde elle tutulmaz. Flutter, Next.js ve Supabase aynı
   Vixrex çekirdeğini kullanır.
6. Başka bir işin değişiklikleri silinmez veya sahiplenilmez.
7. Aynı çalışma klasöründe iki üretici çalışmaz.
8. Flutter paneline açık ürün kararı olmadan dokunulmaz.
9. Test sonucu tek başına başarı değildir; gerçek kullanıcı yolu görülür.
10. Üreten kişi veya araç kendi işinin son incelemesini yapmış sayılmaz.
11. Dal, ana dal, yayın ve canlı doğrulama ayrı durumlar olarak bildirilir.
12. Ana dala alınan değişiklik otomatik yayımlanmaz. Canlı yayın ayrı bir
    sahip kararı ve ayrı doğrulama adımıdır.

## Kayıt ve tamamlanma

Yeni özellik ve davranış değişikliği `specs/<iş-kimliği>/` altında tam kayıt
tutar; ilk belge `kesif.md` olur. Kayıtlarda geçmeyen bir ürün dosyası
değiştirilemez — merkezi kontrol bunu ölçer. Hata düzeltmesi aynı yerde kısa
hata kaydı tutar. Yalnız araştırılan fikir ürün kodunu değiştirmez.

Bir iş ancak seçilen yolun kayıtları tamamlandığında, ilgili kontroller
geçtiğinde, gerçek davranış doğrulandığında, geri alma yolu hazır olduğunda ve
bağımsız inceleme tamamlandığında hazır sayılır.
