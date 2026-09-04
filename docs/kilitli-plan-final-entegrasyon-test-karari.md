# KİLİTLİ PLAN EK KARARI — Final Entegrasyon Testi

Bu karar, ana planın **ekran/entegrasyon testinin zamanlamasını** netleştirir. Ana katman sırası değişmez.

## Kullanıcı kararı
Katman 1–5 tamamlanmadan her katmanda ayrı ayrı kullanıcı ekranı test döngüsüne girilmeyecek.

Her katmanda yine zorunlu olarak:
- RESEARCH
- UX-FIT
- SECURITY/RISK
- LOOK
- LOCK
- BUILD
- teknik VERIFY (tip/test/build/migration/RLS/kontrat/regresyon)

yapılır.

Ancak kapsamlar arası gerçek kullanıcı senaryosu ve somut ekran kabul testi **final entegrasyon kapısında** yapılır.

## Final entegrasyon kapısı
Katman 1–5 teknik olarak tamamlandıktan sonra tek uçtan uca senaryo çalıştırılır:

1. Vixrex merkezi blogunda gerçek bir yazı hazır olur.
2. Merkezi Blog Kütüphanesi yazıyı konu/sektör/amaç bilgileriyle bulabilir.
3. Kontrollü bir deneme/kiralık vitrin kiralanır.
4. Sahiplik ekranı açılır.
5. Vixrex Asistan'a blog yazısı ekleme komutu verilir.
6. Asistan merkezi kütüphaneden uygun yazıyı seçer.
7. Yazı kiralık vitrinin `store_articles` alanına **taslak** olarak çekilir.
8. Sahip ekranında yazının geldiği somut olarak görülür; kaynak/provenance ilişkisi doğrulanır.
9. Esnafın mevcut düzenle/yayınla akışıyla yazı yayınlanır.
10. Public vitrin blogunda yazı doğru görünür.
11. Dijital Çarşı bağlantı katmanı uygulanmışsa merkezi yazı ↔ vitrin ↔ ilgili vitrin ilişkisi ekrandan doğrulanır.
12. Mobil ve masaüstü ekran kanıtları alınır.

## Güvenlik kuralı
- Katman bazında teknik VERIFY atlanmaz.
- Final ekran testini ertelemek, güvenlik/RLS/test/build kontrollerini ertelemek anlamına gelmez.
- Main'e kullanıcı açık onayı olmadan merge yapılmaz.
- Final uçtan uca senaryo geçmeden plan bütünü tamamlandı sayılmaz.

## Durum
- Katman 1 teknik VERIFY: tamamlandı.
- Final uçtan uca ekran kabulü: Katman 1–5 tamamlandıktan sonra yapılacak.
- Sıradaki çalışma: Katman 2 — Merkezi Blog Kütüphanesi RESEARCH.
