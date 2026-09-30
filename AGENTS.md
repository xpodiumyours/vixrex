# AGENTS.md ÔÇö VixRex ajan ├ğal─▒┼şma kurallar─▒

Bu dosya, bu depoda ├ğal─▒┼şan **her** ajan i├ğindir (Claude, ChatGPT/Codex, Kilo,
Freebuff, Cursor). Depo bilgisi de─şil, **kural** dosyas─▒d─▒r.

**Tek adres buras─▒d─▒r.** ├çal─▒┼şma tarz─▒ kurallar─▒ ba┼şka bir dosyada tutulmaz.
Ba┼şka bir dosya bu kurallar─▒ tekrarl─▒yorsa iki kopya zamanla ayr─▒┼ş─▒r ve
├ğeli┼şki do─şar (2026-09-29: `CONTRIBUTING.md` "tek kaynak" olarak art─▒k depoda
bulunmayan `CLAUDE.md`'yi g├Âsteriyordu ÔÇö yani ├ğal─▒┼şma kurallar─▒n─▒n hi├ğbir
adresi kalmam─▒┼şt─▒).

Depo haritas─▒, mimari, komut listesi ve ortam de─şi┼şkenleri bu dosyan─▒n i┼şi
de─şildir; onlar `README.md` ve kodun kendisinde ya┼şar. **Haritalar buraya
ta┼ş─▒nmaz.**

Kural: a┼şa─ş─▒daki her sat─▒r ge├ğmi┼şte ya┼şanm─▒┼ş somut bir aksili─şe dayan─▒r.
Daya─ş─▒ olmayan sat─▒r eklenmez. Yeni bir aksilik ya┼şand─▒─ş─▒nda buraya bir sat─▒r
eklenir ve m├╝mk├╝nse bir kanca ile ├Âl├ğ├╝l├╝r.

> **├ûl├ğ├╝m kancalar─▒ hakk─▒nda not:** Bu dosyada ad─▒ ge├ğen kanca betikleri
> (`.claude/hooks/`) 2026-09-26'da depodan kald─▒r─▒ld─▒. Kural metinleri kald─▒;
> kancalar─▒ geri getirmek Casper'─▒n karar─▒d─▒r. Kancas─▒ olmayan bir kural,
> ├Âl├ğ├╝lmeyen bir kurald─▒r ÔÇö buna g├╝venip "├Âl├ğ├╝ld├╝" demeyin.

---

## A. Durmadan ├Ânce

### 1. Sormadan uygulama (2026-09-03)
Hi├ğbir ad─▒m─▒, hi├ğbir de─şi┼şikli─şi Casper'a sormadan yapma ÔÇö k├╝├ğ├╝k g├Âr├╝nse bile.
"┼Şunu d├╝zelteyim mi", "bu iki se├ğenekten hangisi" diye sor, cevab─▒ bekle, sonra
uygula. Bir d├╝zeltmenin "do─şru" g├Âr├╝nd├╝─ş├╝ sana de─şil ona ait bir karar.

Neden: 2026-09-03'te "├çal─▒┼şma masas─▒" ekran─▒ bitmeden, onaylanmam─▒┼ş bir
d├╝zeltmeyle ak─▒ll─▒ motorun (serbest c├╝mleden alan ├ğ─▒karan motor) bir par├ğas─▒
sessizce devre d─▒┼ş─▒ b─▒rak─▒ld─▒ ve do─şrudan ana dala al─▒nd─▒. Casper canl─▒da fark
etti, saatlerce token yak─▒ld─▒, sonu├ğ g├╝vensizlik oldu.

### 2. Varsay─▒m, tahmin ve ├Âl├ğ├╝s├╝z de─şi┼şiklik yasak (2026-09-09, 2026-09-12)
- **Varsay─▒m yasak.** Emin olmad─▒─ş─▒n ┼şeyi do─şru gibi yazma. Bilmiyorsan
  "bilmiyorum" de, sor, bekle.
- **Tahminle i┼ş yapma.** Koda bakmadan "┼ş├Âyle olmal─▒" diye d├╝zeltme, dosya
  ekleme, silme.
- **├ûl├ğmeden de─şi┼ştirme.** Bir e┼şik/ayar de─şi┼ştirmeden ├Ânce ger├ğekte ne
  ├╝retti─şini ├Âl├ğ.
- **Kan─▒t ver.** Hangi dosyaya bakt─▒ysan tam yol ve sat─▒r yaz; bakmad─▒ysan
  "bakmad─▒m" de.

Neden: 2026-09-12 ├Âl├ğ├╝m├╝nde tek dosya lint'i bile 50 saniye s├╝rd├╝; ├Âl├ğmeden
"ye┼şil" demek bu depoda pahal─▒ya mal oldu.

### 3. Kendi ara├ğlar─▒nla bulabilece─şini Casper'a sorma (2026-09-10)
Arama, tarama, envanter, ├Âl├ğ├╝m ve "┼şu paket kurulu mu / ┼şu API nas─▒l ├ğal─▒┼ş─▒r"
gibi sorular─▒n cevab─▒ sende. ├ûnce kendin ara┼şt─▒r, sonra SONUCU anlat.
Casper'a sorulacak tek ┼şey ger├ğekten onun karar─▒ olan ┼şeydir: b├╝y├╝k mimari,
├╝r├╝n kural─▒, onay gerektiren canl─▒ i┼şlem.

### 4. CERRAH─░ ─░┼ŞLEM D├£ZEN─░ ÔÇö her de─şi┼şiklikte, istisnas─▒z (2026-09-24)
Casper: "her i┼şlem i├ğin b├Âyle ├ğal─▒┼şaca─ş─▒z." A┼şa─ş─▒daki 6 ad─▒m bir ├Âneri de─şil,
bu depodaki her kod de─şi┼şikli─şinin zorunlu s─▒ras─▒. Ad─▒m atlanamaz.

1. **├ûnce tespit ÔÇö dokunmadan ├Ânce.** Nereye, neden, ne kadar dokunaca─ş─▒n─▒
   yaz: dosya, sat─▒r, ne de─şi┼şecek. Yan─▒na "dokunmayaca─ş─▒m" listesini de yaz.
   Onay al, sonra ba┼şla. Kapsam onaydan sonra b├╝y├╝t├╝lemez.
2. **Sadece onaylanan sat─▒rlar.** Yol ├╝st├╝nde ba┼şka bir hata g├Ârsen bile
   dokunma; ayr─▒ca s├Âyle. Hi├ğbir ┼şey "geri getirilmez", hi├ğbir b├Âl├╝m
   eklenmez/kald─▒r─▒lmaz.
3. **Yay─▒lma alan─▒n─▒ ├Âl├ğ.** Dokundu─şun dosya/bile┼şen ba┼şka nerelerde
   kullan─▒l─▒yor ÔÇö hepsini bul ve yaz. "Ba┼şka yeri k─▒rmad─▒m" c├╝mlesi ancak bu
   ├Âl├ğ├╝mle kurulabilir.
4. **Kap─▒lar─▒ ko┼ş.** Testler, tip kontrol├╝, lint, ├╝retim derlemesi. Ger├ğek
   ├ğ─▒kt─▒y─▒ yaz (ka├ğ test ge├ğti), "ye┼şil" deyip ge├ğme.
5. **G├ûRSEL KANIT ÔÇö jargonsuz.** G├Âr├╝nen her de─şi┼şiklikte ├Âncesi/sonras─▒
   resmini Casper'a g├Ânder. Kod okuyarak "b├Âyle g├Âr├╝necek" demek yasak.
   Ger├ğek panele girilemiyorsa (giri┼ş gerekiyorsa) bunu a├ğ─▒k├ğa s├Âyle ve
   sitenin kendi derlenmi┼ş stil dosyas─▒yla izole kopyas─▒n─▒ ├ğizip g├Âster ÔÇö
   ama "ger├ğek ekran de─şil" diye belirt.
6. **Dal / ana dal / canl─▒ ayr─▒m─▒ + geri alma.** De─şi┼şikli─şin ┼şu an nerede
   oldu─şunu ├╝├ğ kelimeyle s├Âyle, test adresini yaz, geri alma komutunu ver.

**Anlat─▒m kural─▒:** teknik terim kullanma. Kullanmak zorundaysan yan─▒na tek
c├╝mlelik T├╝rk├ğe kar┼ş─▒l─▒─ş─▒n─▒ yaz. Yar─▒m anlatma ÔÇö Casper'─▒n projeye h├ókimiyeti
senin anlat─▒m─▒na ba─şl─▒.

Neden: 2026-09-24'te panelin Hakk─▒m─▒zda/SSS/Kampanya/Pazaryeri/Galeri kutular─▒
"beyaz zemin ├╝st├╝nde beyaz yaz─▒" oldu─şu i├ğin g├Âr├╝nmez hale gelmi┼şti; sebebi,
1 Eyl├╝l'de bu kutular a├ğ─▒l─▒r pencereden panele g├Âm├╝l├╝rken zemin renginin beyaz
b─▒rak─▒lmas─▒yd─▒. Casper'─▒n sorusu ┼şuydu: "ba┼şka bir yeri k─▒rmad─▒─ş─▒na nas─▒l emin
olacaks─▒n?" Cevab─▒ ├╝reten ┼şey bu 6 ad─▒m oldu.

---

## B. Yazarken

### 5. Yorum sat─▒r─▒ kural─▒ (2026-09-09)
Kod i├ğine **yeni** yorum sat─▒r─▒ ekleme (`//`, `/* */`, `#`, `<!-- -->`, `--`).
A├ğ─▒klama gerekiyorsa mesaja yaz.

Var olan bir yorumu **kendi karar─▒nla** de─şi┼ştirme veya silme. Ama bir yorum
fiilen yanl─▒┼ş h├óle gelmi┼şse (├Âr. kald─▒r─▒lm─▒┼ş bir dosyay─▒, ge├ğmi┼ş bir say─▒y─▒
g├Âsteriyorsa) bunu Casper'a s├Âyle ÔÇö onay verirse **yaln─▒z o yorum** d├╝zeltilir.
Yanl─▒┼ş bilgi ta┼ş─▒yan bir yorumu "dokunma" diye korumak, yanl─▒┼ş─▒n kal─▒c─▒
olmas─▒na izin vermektir.

### 6. Anahtar─▒/jetonu dosyaya g├Âmme (2026-08-19 s─▒z─▒nt─▒s─▒)
Ortam de─şi┼şkeni kullan. Alan─▒n ADINA g├╝venme, de─şerin ┼şekline bak.

### 7. Ba┼şka ajan─▒n i┼şine girme (2026-09-10)
Bir d├╝zeltme teklif etmeden ├Ânce `git log --oneline -5 -- <dosya>` ile yak─▒n
zamanl─▒ bir commit var m─▒ bak. Kendi yazd─▒─ş─▒n─▒ sonra "hata buldum" diye
raporlama.

### 8. Ayn─▒ klas├Ârde iki ajan ├ğal─▒┼şt─▒rma (2026-08-26)
─░┼ş sessizce silinir.

### 9. Dal a├ğarken taban─▒ uzaktan al
Yerel ana daldan alma; yerel kirli olabilir.

---

## C. Bitirdim demeden ├Ânce

### 10. Ye┼şil test, "├ğal─▒┼ş─▒yor" demek de─şil (2026-09-03)
Ger├ğek ├ğ─▒kt─▒y─▒ ├ğal─▒┼şt─▒r, ekran─▒ a├ğ. G├Ârsel/UI hatas─▒nda canl─▒ do─şrula;
g├Âremiyorsan "g├Âremedim" de, tahminle "d├╝zelttim" deme.

### 11. G├Ârsel/UI hatas─▒nda ├Ânce canl─▒ do─şrula (2026-09-03)
Bir UI/g├Ârsel hatay─▒ (ekran g├Âr├╝nt├╝s├╝yle bildirilen, "kutu kaym─▒┼ş", "bo┼şluk
yanl─▒┼ş" tarz─▒) koda bak─▒p tahminle d├╝zeltip commit etme. ├ûnce canl─▒ a├ğ, sorunu
kendi g├Âz├╝nle g├Âr, d├╝zeltmeyi uygulad─▒ktan sonra AYNI ┼şekilde tekrar bak ve
do─şrula ÔÇö ancak ├Âyle "d├╝zelttim" de. Canl─▒ do─şrulama ger├ğekten m├╝mk├╝n de─şilse
(├Âr. sandbox'tan Supabase'e a─ş eri┼şimi yok) bunu a├ğ─▒k├ğa s├Âyle ve Casper'dan
ekran g├Âr├╝nt├╝s├╝/canl─▒ bak─▒┼ş iste ÔÇö k├Âr tahminle commit atma.

Neden: ayn─▒ g├╝n iki uzun oturum (807 ve 461 mesaj) b├╝y├╝k ├Âl├ğ├╝de verimsiz
soru-cevap d├Âng├╝s├╝ne girdi.

### 12. Ajan kendi i┼şini denetlemez
├£reten ayr─▒, do─şrulayan ayr─▒.

### 13. A─ş─▒r kap─▒lar elde (2026-09-12 ├Âl├ğ├╝m├╝)
Testler, tip kontrol├╝, lint, ├╝retim derlemesi. Bunlar kancaya konmad─▒ ├ğ├╝nk├╝ tek
dosya lint'i bile 50 saniye s├╝r├╝yor. Merge ├Âncesi `bash tool/merge-hazir.sh`
ko┼şulur; g├╝ncel kap─▒ listesi `.github/workflows/ci.yml` i├ğindedir.

(2026-09-29'a kadar burada `kapilar` adl─▒ bir k─▒sayoldan s├Âz ediliyordu; ├Âyle
bir komut depoda hi├ğ yoktu. Do─şru adres `tool/merge-hazir.sh`.)

---

## D. Bitmemi┼ş i┼ş ve saha d├╝zeni

### 14. Bitmemi┼ş i┼ş burada beklemez (2026-09-29)
El eme─şi, ├╝retildi─şi g├╝n kendi hatt─▒na al─▒n─▒r. Bir i┼ş bitti─şinde hatt─▒ ve
ge├ğici ├ğal─▒┼şma alan─▒ silinir. Bu klas├Âr bir ge├ğici ├ğal─▒┼şma masas─▒ de─şildir.

Neden: 2026-09-29'da sipari┼ş/tahsilat i┼şi g├╝nlerce kaydedilmeden bu klas├Ârde
durdu; bu klas├Âr ana dal─▒n 32 ad─▒m gerisinde kald─▒ ve ayn─▒ d├Ânemde yaz─▒lan
belgeler "├ğeli┼şkili" h├óle geldi. Belgeler yanl─▒┼ş de─şildi, **eskiydi**: ├ğeli┼şki
diye g├Âr├╝nen ┼şeyin k├Âk├╝, geride kalm─▒┼ş bir kopyayd─▒.

---

## E. Rapor verirken

### 15. Dal, ana dal ve canl─▒ ayr─▒ ┼şeyler
"G├Ânderdim" demek canl─▒da d├╝zeldi demek de─şil. Hangisinden bahsetti─şini a├ğ─▒k├ğa
yaz.

### 16. Taslak/WIP/deneme commit ana dala inmez (2026-09-10)
Onaydan ├Ânce fark─▒ oku.

### 17. Test adresini hep yaz
Hangi adrese bak─▒laca─ş─▒ yaz─▒lmazsa yanl─▒┼ş s├╝r├╝m test edilir.

### 18. Cevap k─▒sa olsun (2026-09-10)
Kan─▒t istenmeden d├Âk├╝lmez. Migration s├╝r├╝m numaras─▒, commit hash'i, sat─▒r
numaras─▒ gibi detaylar sonu├ğ de─şildir: ├Ânce 2-3 c├╝mlelik sade sonu├ğ, detay
yaln─▒z sorulursa. Cevab─▒n sonuna soru/┼ş├╝phe/uyar─▒ ili┼ştirme; bir hatay─▒ kabul
ediyorsan sadece kabul et, arkas─▒na savunma ekleme. Kapan─▒┼şta soru gerekiyorsa
tek soru olsun ve ger├ğekten Casper'─▒n karar─▒ olsun.

Neden: 2026-09-10 oturumunda ayn─▒ g├╝n ana dala al─▒nm─▒┼ş bir d├╝zeltme s─▒f─▒rdan
ke┼şfedilip "canl─▒ya uygulayay─▒m m─▒" diye soruldu; cevaplar tablo/hash/sat─▒r
numaras─▒yla ┼şi┼şirildi ve hatay─▒ kabul eden mesaj─▒n sonuna yine soru eklendi.
Casper: "art─▒k seninle ├ğal─▒┼şmaktan b─▒kmaya ba┼şlad─▒m."

### Token ekonomisi (2026-09-16)
Token en k─▒t kaynak. Bitince koordinasyon, do─şrulama ve merge sorumlulu─şu
duruyor ÔÇö yani proje duruyor. Yava┼ş ajan, duran projeden iyidir.

- Arama, tarama, envanter, ├Âl├ğ├╝m, raporlama ve kodun kendisi ajana verilir.
- Koordinat├Ârde kalan: hedefi yazmak, ajan─▒n raporunu do─şrulamak, riskli tek
  noktay─▒ **tek komutla** ├Âl├ğmek, commit/merge/s─▒ra takibi.
- G├Ârev yazmadan ├Ânce dosya ad─▒ do─şrulamak i├ğin komut ├ğal─▒┼şt─▒rma; ajan bulur.
- ├ûl├ğ├╝m yaln─▒z bir **karar** ona ba─şl─▒ysa yap─▒l─▒r.
- Her yeni faz ÔåÆ yeni oturum; ┼şi┼şmi┼ş ba─şlam her cevab─▒ pahal─▒la┼şt─▒r─▒r.
- Uzun rapor yazma; sonu├ğ tek sat─▒r, detay istenirse gelir.


---

# Ürün hedefi: Faturadan dijital vitrine


# VixRex ÔÇö Ajanlar i├ğin proje talimatlar─▒

Fatura, firma ke┼şfi, ├╝r├╝n e┼şle┼ştirme, g├Ârsel, kart ve yay─▒nlama i┼şlerinde **[Faturadan Vitrine Master Plan](docs/FATURADAN-VITRINE-MASTER-PLAN.md)** esas al─▒n─▒r. Mevcut i┼şleri bu plandaki eksiklerle e┼şle┼ştir; ikinci bir plan veya paralel ├╝r├╝n ak─▒┼ş─▒ kurma. Fazlar─▒ yaln─▒z kod var diye tamamland─▒ sayma; ger├ğek kabul kan─▒t─▒n─▒ kaydet. Kullan─▒c─▒dan bu hedefi yeniden tarif etmesini isteme.

## Faturadan dijital vitrine: de─şi┼ştirilmeyecek ├╝r├╝n kapsam─▒

Bu b├Âl├╝m, proje sahibinin 30 Eyl├╝l 2026 tarihinde a├ğ─▒k├ğa belirtti─şi ├╝r├╝n hedefidir. Fatura, OCR, firma ke┼şfi, katalog e┼şle┼ştirme, ├╝r├╝n bilgisi, g├Ârsel ve ├╝r├╝n yay─▒nlama ├ğal─▒┼şmalar─▒nda bu hedefi esas al. Kullan─▒c─▒ya ayn─▒ kapsam─▒ yeniden anlatt─▒rma. Eski planlar, mevcut firma listeleri veya uygulamadaki eksikler bu hedefi daraltmaz. Kullan─▒c─▒n─▒n sonraki a├ğ─▒k talimat─▒ kapsam─▒ g├╝ncelleyebilir.

### Kime, hangi anda yard─▒mc─▒ oluyoruz?

K├╝├ğ├╝k esnaf, toptanc─▒dan veya ├╝reticiden ├╝r├╝n├╝n├╝ al─▒p ├╝r├╝n ve faturas─▒yla ba┼ş ba┼şa kald─▒─ş─▒nda VixRex devreye girer. Ama├ğ, esnaf─▒n raftaki ├╝r├╝nlerini tek tek foto─şraflay─▒p a├ğ─▒klama yazarak y├╝klemesini gerektirmeden dijital ├╝r├╝n kartlar─▒na ve t├╝keticinin g├Ârebilece─şi vitrine d├Ân├╝┼şt├╝rmektir. VixRex, ├╝retici ile k├╝├ğ├╝k esnaf aras─▒nda dijital k├Âpr├╝d├╝r.

### Ger├ğek kapsam ve e┼şle┼ştirme s─▒n─▒r─▒

- Hedef, ─░stanbul toptanc─▒lar─▒ ve T├╝rkiye ├╝reticileridir. Kapsam tek bir marka, sekt├Âr veya ├Ânceden haz─▒rlanm─▒┼ş firma listesi de─şildir.
- G─▒da, tekstil, temizlik, ev tekstili ve tuhafiye dahil farkl─▒ ├╝r├╝n gruplar─▒ kapsamdad─▒r. Tutku yaln─▒zca bir ├Ârnektir; bakkal─▒n faturas─▒ndaki Eti ve ├£lker ├╝r├╝nleri de ayn─▒ yakla┼ş─▒m─▒n i├ğindedir.
- **16 firma ve 54 firmal─▒k havuz, OpenRouter token maliyetini azaltmak i├ğin d├╝┼ş├╝n├╝lm├╝┼şt├╝r. Bunlar kapsam s─▒n─▒r─▒, izin verilen firmalar listesi veya yaln─▒z bu firmalarla ├ğal─▒┼şma karar─▒ de─şildir.** Havuz d─▒┼ş─▒nda olmak tek ba┼ş─▒na eleme gerek├ğesi olamaz.
- Belirleyici ko┼şul, faturadaki firma ve ├╝r├╝n bilgilerinin firman─▒n resm├« dijital kaynaklar─▒ndaki ├╝r├╝nlerle do─şrulanabilir bi├ğimde e┼şle┼şmesidir. Faturay─▒ kesen toptanc─▒ ile ├╝r├╝n├╝n ├╝reticisi ayn─▒ firma olmak zorunda de─şildir; do─şru ├╝r├╝n ve ├╝retici ili┼şkisi ├ğ├Âz├╝lmelidir.
- Bas─▒l─▒ veya el yaz─▒s─▒ fatura olmas─▒ tek ba┼ş─▒na kabul ya da ret nedeni de─şildir. Bilgiler okunabiliyor ve dijital kar┼ş─▒l─▒─ş─▒ bulunabiliyorsa ak─▒┼ş─▒n konusudur.
- Sadece benzerlik nedeniyle ba┼şka ├╝r├╝n├╝n g├Ârselini veya bilgisini kullanma. E┼şle┼şmeyen ya da belirsiz ├╝r├╝n├╝ e┼şle┼şmi┼ş gibi sunma. Tekil bir e┼şle┼şme sorunu ├╝zerinden b├╝t├╝n bir sekt├Âr├╝ veya firmalar─▒ kapsamdan ├ğ─▒karma.
- Sistem, her yeni firma veya faturada yorucu elle ara┼şt─▒rma gerektirmeden bu k├Âpr├╝y├╝ kurabilmelidir. Maliyet azaltma ├ğal─▒┼şmalar─▒ bu hedefi korumal─▒d─▒r.

### U├ğtan uca ba┼şar─▒ ├Âl├ğ├╝t├╝

1. Esnaf faturan─▒n foto─şraf─▒n─▒ verir.
2. Firma ve ├╝r├╝n bilgileri okunur; ilgili toptanc─▒, ├╝retici veya marka belirlenir.
3. Faturadaki ├╝r├╝nler, ilgili firman─▒n resm├« dijital ├╝r├╝nleriyle e┼şle┼ştirilir.
4. E┼şle┼şen ├╝r├╝nlerin do─şru bilgileri ve g├Ârselleri ├╝r├╝n kartlar─▒na yerle┼ştirilir.
5. Kartlar, t├╝keticinin g├Ârebilece─şi dijital vitrine kadar ula┼ş─▒r; yay─▒nlama ve g├Âr├╝nt├╝leme zinciri ger├ğek ak─▒┼şta do─şrulan─▒r.

Sadece OCR ├ğ─▒kt─▒s─▒, firma ba─şlant─▒s─▒, katalog arama sonucu veya g├Ârselsiz ara taslak bu hedefin tamamland─▒─ş─▒ anlam─▒na gelmez. Birka├ğ se├ğilmi┼ş marka ├╝zerinde ├ğal─▒┼şan ├Ârnek de genel kapsam─▒n tamamland─▒─ş─▒n─▒n kan─▒t─▒ de─şildir. Kullan─▒c─▒n─▒n ÔÇ£%100 ├ğal─▒┼şmal─▒ÔÇØ beklentisini kapsam─▒ k├╝├ğ├╝lterek kar┼ş─▒lama; zincirin tamam─▒n─▒ ├ğal─▒┼şt─▒r ve do─şrulanmam─▒┼ş noktalar─▒ a├ğ─▒k├ğa belirt.

### ├çal─▒┼şan sistem ve firma izin g├Âr├╝┼şmeleri

Kullan─▒c─▒n─▒n s─▒ralamas─▒: **├Ânce g├Ârseller ve t├╝keticiye g├Âsterilebilen ├╝r├╝n kartlar─▒ dahil ├ğal─▒┼şan sistemi somut olarak ispatlamak, ard─▒ndan bu ├ğal─▒┼şan sistemle firmalarla kullan─▒m izni g├Âr├╝┼şmesi yapmak.** ─░zin g├Âr├╝┼şmesini teknik geli┼ştirmeyi s├╝rekli durduran veya kapsam─▒ daraltan bir ├Ânko┼şula d├Ân├╝┼şt├╝rme. ─░zin s├╝reci hedefin bir par├ğas─▒d─▒r; yok say─▒lacak bir konu de─şildir.

Firmalara sunulacak de─şer: ÔÇ£├£r├╝nlerinizi satan k├╝├ğ├╝k esnafla dijital k├Âpr├╝n├╝z olal─▒m; esnaf─▒n raf─▒ndaki ├╝r├╝nlerinizi dijital vitrinde katalo─şa d├Ân├╝┼şt├╝relim.ÔÇØ Ama├ğ, hen├╝z ├ğal─▒┼şmayan bir fikre izin istemek de─şil, i┼şleyen ak─▒┼ş─▒ g├Âsterebilmektir.

Bu ├╝r├╝n hedefi, firmalardan izin al─▒nm─▒┼ş oldu─şu veya sistemin bug├╝n tamamland─▒─ş─▒ anlam─▒na gelmez. Teknik kabiliyet, do─şrulanm─▒┼ş u├ğtan uca sonu├ğ, canl─▒ yay─▒n ve al─▒nm─▒┼ş firma iznini raporlarken ayr─▒ ayr─▒ belirt. Bu belge tek ba┼ş─▒na firma ad─▒na ileti┼şim kurma, canl─▒ya da─ş─▒t─▒m veya d─▒┼ş ayar de─şi┼şikli─şi i├ğin i┼şlem yetkisi vermez; ilgili i┼şin kullan─▒c─▒ talimat─▒n─▒ esas al.

### Ajanlar─▒n ├ğal─▒┼şma bi├ğimi

- Bu hedefi yeniden tart─▒┼şmaya a├ğmak yerine mevcut eksikleri hedefe g├Âre belirle.
- Tutku'ya, sabit firma havuzlar─▒na veya izin konusuna tak─▒l─▒p b├╝y├╝k hedefi daraltma.
- Mevcut ├ğal─▒┼şan davran─▒┼ş─▒ ve kullan─▒c─▒ verilerini koru; yaln─▒z istenen i┼ş kapsam─▒nda de─şi┼şiklik yap.
- Hedefi, uygulanm─▒┼ş ├Âzelli─şi ve do─şrulanm─▒┼ş sonucu birbirine kar─▒┼şt─▒rma. ├çal─▒┼şt─▒rmad─▒─ş─▒n testi veya g├Ârmedi─şin canl─▒ sonucu tamamland─▒ diye raporlama.
