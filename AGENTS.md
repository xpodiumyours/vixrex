# AGENTS.md — Vixrex ortak gelişim kuralları

Bu dosya Vixrex deposunda çalışan insan veya yapay zekâ ayrımı olmadan bütün
üreticiler için geçerlidir. Hiçbir araç, model veya firma için ayrı gelişim
yolu yoktur.

## Zorunlu gelişim zinciri

Her yeni özellik, hata düzeltmesi, güvenlik, veri, içerik, tasarım, altyapı
ve ayar değişikliği `DEVELOPMENT.md` içindeki zinciri eksiksiz izler:

Anayasa → Specify → Clarify → Plan → Checklist → Tasks → Analyze →
Implement → Converge → gerekirse Implement/Converge tekrarı → Review/PR.

Bir aşama atlandıysa kod hazır sayılmaz. Zincirin kayıtları
`specs/<iş-kimliği>/` altında tutulur. Ortak GitHub kontrolü bu kayıtlar
olmadan teslimata izin vermez.

## Çalışma biçimi

1. Furkan doğal Türkçeyle sonucu söyler; teknik kapsamı ve dosyaları üretici
   araştırır.
2. Kod, belge, canlı yüzey veya yetkili araçla bulunabilen bilgi Furkan'a
   sorulmaz.
3. Yalnız para, hukuk, görünüm, içerik, veri kaybı, gizlilik, canlı işlem veya
   iki farklı ürün sonucu için tek sade soru sorulur.
4. Tahminle değişiklik yapılmaz. Mevcut davranış ve etkilenen bütün yüzeyler
   önce ölçülür.
5. Aynı bilgi iki yerde elle tutulmaz. Flutter, Next.js ve Supabase aynı
   Vixrex çekirdeğini kullanır.
6. Başka bir işin değişiklikleri silinmez veya sahiplenilmez.
7. Aynı çalışma klasöründe iki üretici çalışmaz.
8. Flutter paneline açık ürün kararı olmadan dokunulmaz.
9. Test sonucu tek başına başarı değildir; gerçek kullanıcı yolu görülür.
10. Üreten kişi veya ajan kendi işinin son incelemesini yapmış sayılmaz.
11. Dal, ana dal, yayın ve canlı doğrulama ayrı durumlar olarak bildirilir.
12. Ana dala alınan değişiklik otomatik yayımlanmaz. Canlı yayın ayrı bir
    sahip kararı ve ayrı doğrulama adımıdır.

## Tamamlanma

Bir iş yalnız şu koşullarda tamamdır:

- Anayasa ve bütün gelişim aşamaları kayıtlıdır.
- Belirsizlikler çözülmüştür.
- Plan ile görevler arasında çelişki yoktur.
- Bütün görevler tamamlanmıştır.
- Uygulama ile yakınsama, eksik kalmayana kadar tekrarlanmıştır.
- İlgili kontroller ve üretim derlemeleri geçmiştir.
- Gerçek kullanıcı yolu doğrulanmıştır.
- Güvenlik, geri alma, hata izleme ve destek yolu kaydedilmiştir.
- Bağımsız inceleme ve PR sonucu hazırdır.
