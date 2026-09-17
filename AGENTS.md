# AGENTS.md — VixRex ajan kontrol listesi

Bu dosya bu depoda calisan **her** ajan icindir (Claude, ChatGPT/Codex,
Kilo, Freebuff, Cursor). Depo bilgisi degil, **kural** dosyasidir.
Mimari, komutlar ve ortam degiskenleri icin: `CLAUDE.md`.

Kural: buradaki her satir gecmiste yasanmis somut bir aksiliga dayanir.
Dayanagi olmayan satir eklenmez. Yeni bir aksilik yasandiginda buraya bir
satir eklenir ve mumkunse `.claude/hooks/` altinda bir kanca ile olculur.

## Durmadan once

1. **Sormadan uygulama.** Kucuk gorunse bile. (2026-09-03: onaylanmamis
   bir duzeltme akilli motoru sessizce bozdu, canliya indi.)
2. **Tahminle is yapma.** Koda bakmadan duzeltme yazma. Baktigin dosyanin
   tam yolunu ve satirini yaz; bakmadiysan "bakmadim" de. (2026-09-09)
3. **Kendi araclarinla bulabilecegini Casper'a sorma.** Once arastir,
   sonra sonucu anlat. (2026-09-10)
3b. **Zinciri tersten kurma.** Bir is girdiden ciktiya dogru kurulur ve
   halka atlanmaz. Zincirin tanimi, "bitti" tanimi ve tasarim ilkeleri
   tek yerdedir: `.specify/memory/constitution.md`. Burada tekrarlanmaz.
   Celisme olursa sira: anayasa -> bu dosya -> `CLAUDE.md`. (2026-09-16)

3c. **Ise baslamadan once baglami oku.** Aktif is nedir, son commitler ne
   yapti, acik PR var mi. Bunlari okumadan oneri yapma; Casper'a durumu
   tekrar anlattirma. (2026-09-17)
3d. **Ayni seyi iki kez tarama.** Bu oturumda veya kayitta zaten olculmus
   bir seyi yeniden arama. Olcum yalniz bir karar ona bagliysa yapilir;
   gorev yazmadan once dosya adi dogrulamak icin komut kosturma.
   (2026-09-17)

## Yazarken

4. **Kod icine yorum satiri ekleme.** Aciklama mesaja yazilir.
   Olculur: `.claude/hooks/yorum-satiri.sh` (2026-09-09)
5. **Anahtari/jetonu dosyaya gomme.** Ortam degiskeni kullan. Alanin
   ADINA guvenme, degerin sekline bak.
   Olculur: `.claude/hooks/anahtar-sizintisi.sh` (2026-08-19 sizintisi)
6. **Baska ajanin isine girme.** Bir duzeltme teklif etmeden once
   `git log --oneline -5 -- <dosya>` ile yakin commit var mi bak.
   Kendi yazdigini sonra "hata buldum" diye raporlama. (2026-09-10)
7. **Ayni klasorde iki ajan calistirma.** Is sessizce silinir.
   (2026-08-26) Her isin tek sahibi vardir; ikinci ajan ayri dal ve ayri
   calisma klasoru (worktree) kullanir.
8. **Dal acarken tabani uzaktan al**, yerel ana daldan alma; yerel kirli
   olabilir.
8b. **Flutter paneline (`lib/`) izinsiz dokunma.** Casper icin en kilitli,
   en iyi calisan yer orasi. Hedef tek yuz Next.js olmasi bu izni
   vermez; "nasilsa kalkacak" diyip orayi kirmak yasak. Gorunum farki
   varsa duzeltme `public_web/` tarafinda yapilir. (2026-09-07 karari)
8c. **Yarim is birakip yenisine gecme.** Acik is ikiden fazlaysa yeni is
   acilmaz. Kapatmak tamamlamak degildir; bir is bitmeden digerine
   gecilmez. (2026-09-16)

## Bitirdim demeden once

0. **"Bitti" = gercek kullanicinin gercek yolundan bir kez bastan sona
   calistirildi ve ekran goruldu.** Yesil test yetmez. (2026-09-16)

9. **Yesil test calisiyor demek degil.** Gercek ciktiyi calistir, ekrani
   ac. Gorsel/UI hatasinda canli dogrula; goremiyorsan "goremedim" de,
   tahminle "duzelttim" deme. (2026-09-03)
10. **Olcmeden degistirme.** Esik/ayar degistirmeden once gercekte ne
    urettigini olc.
11. **Ajan kendi isini denetlemez.** Ureten ayri, dogrulayan ayri.
12. **Agir kapilar elde:** testler, tip kontrolu, lint, uretim derlemesi.
    Bunlar kancaya konmadi cunku tek dosya lint'i bile 50 saniye suruyor
    (2026-09-12 olcumu). Merge oncesi `kapilar` ile kosulur.

## Rapor verirken

13. **Dal, ana dal ve canli ayri seylerdir.** "Gonderdim" demek canlida
    duzeldi demek degil. Hangisinden bahsettigini acikca yaz.
    Olculur: `.claude/hooks/dal-durumu.sh`
14. **Taslak/WIP/deneme commit ana dala inmez.** Onaydan once farki oku.
    (2026-09-10)
15. **Test adresini hep yaz.** Hangi adrese bakilacagi yazilmazsa yanlis
    surum test ediliyor.
16. **Cevap kisa olacak.** Kanit istenmeden dokulmez.
17. **Duz Turkce yaz.** Casper yazilimci degil, teknik terim ve Ingilizce
    bilmiyor. Bir terim kullanmak zorundaysan yanina tek cumlelik Turkce
    karsiligini yaz. Dosya adi, bilesen adi, kod numarasi verme; ne ise
    yaradigini anlat. "Ozet su" diye basla, madde madde devam et.
18. **Bilmiyorsan bilmiyorum de.** "Kontrol edeyim" demek serbest.
    Oldugundan iyi gostermek guven kaybettirir; gecmiste boyle yaralar
    var.
