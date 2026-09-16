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
3b. **Zinciri tersten kurma.** Bir ozellik girdiden ciktiya dogru kurulur:
   kategori/kural -> esnaf formu -> dogrulama -> Supabase kayit -> sahip
   duzenleme -> yayin kapisi -> public detay -> urun karti. Bir halka
   yoksa altindaki halka "tamamlandi" sayilmaz. Kaynagi olmayan veri
   ekranda tasarlanmaz; kaydetme yolu olmayan alan public'e cikarilmaz.
   Ayrinti: `CLAUDE.md` > "Gelistirme zinciri". (2026-09-16)

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
   (2026-08-26)
8. **Dal acarken tabani uzaktan al**, yerel ana daldan alma; yerel kirli
   olabilir.

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
