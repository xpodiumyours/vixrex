# AGENTS.md — VixRex ajan çalışma kuralları

Bu dosya, bu depoda çalışan **her** ajan içindir (Claude, ChatGPT/Codex, Kilo,
Freebuff, Cursor). Depo bilgisi değil, **kural** dosyasıdır.

**Tek adres burasıdır.** Çalışma tarzı kuralları başka bir dosyada tutulmaz.
Başka bir dosya bu kuralları tekrarlıyorsa iki kopya zamanla ayrışır ve
çelişki doğar (2026-09-29: `CONTRIBUTING.md` "tek kaynak" olarak artık depoda
bulunmayan `CLAUDE.md`'yi gösteriyordu — yani çalışma kurallarının hiçbir
adresi kalmamıştı).

Depo haritası, mimari, komut listesi ve ortam değişkenleri bu dosyanın işi
değildir; onlar `README.md` ve kodun kendisinde yaşar. **Haritalar buraya
taşınmaz.**

Kural: aşağıdaki her satır geçmişte yaşanmış somut bir aksiliğe dayanır.
Dayağı olmayan satır eklenmez. Yeni bir aksilik yaşandığında buraya bir satır
eklenir ve mümkünse bir kanca ile ölçülür.

> **Ölçüm kancaları hakkında not:** Bu dosyada adı geçen kanca betikleri
> (`.claude/hooks/`) 2026-09-26'da depodan kaldırıldı. Kural metinleri kaldı;
> kancaları geri getirmek Casper'ın kararıdır. Kancası olmayan bir kural,
> ölçülmeyen bir kuraldır — buna güvenip "ölçüldü" demeyin.

---

## A. Durmadan önce

### 1. Sormadan uygulama (2026-09-03)
Hiçbir adımı, hiçbir değişikliği Casper'a sormadan yapma — küçük görünse bile.
"Şunu düzelteyim mi", "bu iki seçenekten hangisi" diye sor, cevabı bekle, sonra
uygula. Bir düzeltmenin "doğru" göründüğü sana değil ona ait bir karar.

Neden: 2026-09-03'te "Çalışma masası" ekranı bitmeden, onaylanmamış bir
düzeltmeyle akıllı motorun (serbest cümleden alan çıkaran motor) bir parçası
sessizce devre dışı bırakıldı ve doğrudan ana dala alındı. Casper canlıda fark
etti, saatlerce token yakıldı, sonuç güvensizlik oldu.

### 2. Varsayım, tahmin ve ölçüsüz değişiklik yasak (2026-09-09, 2026-09-12)
- **Varsayım yasak.** Emin olmadığın şeyi doğru gibi yazma. Bilmiyorsan
  "bilmiyorum" de, sor, bekle.
- **Tahminle iş yapma.** Koda bakmadan "şöyle olmalı" diye düzeltme, dosya
  ekleme, silme.
- **Ölçmeden değiştirme.** Bir eşik/ayar değiştirmeden önce gerçekte ne
  ürettiğini ölç.
- **Kanıt ver.** Hangi dosyaya baktıysan tam yol ve satır yaz; bakmadıysan
  "bakmadım" de.

Neden: 2026-09-12 ölçümünde tek dosya lint'i bile 50 saniye sürdü; ölçmeden
"yeşil" demek bu depoda pahalıya mal oldu.

### 3. Kendi araçlarınla bulabileceğini Casper'a sorma (2026-09-10)
Arama, tarama, envanter, ölçüm ve "şu paket kurulu mu / şu API nasıl çalışır"
gibi soruların cevabı sende. Önce kendin araştır, sonra SONUCU anlat.
Casper'a sorulacak tek şey gerçekten onun kararı olan şeydir: büyük mimari,
ürün kuralı, onay gerektiren canlı işlem.

### 4. CERRAHİ İŞLEM DÜZENİ — her değişiklikte, istisnasız (2026-09-24)
Casper: "her işlem için böyle çalışacağız." Aşağıdaki 6 adım bir öneri değil,
bu depodaki her kod değişikliğinin zorunlu sırası. Adım atlanamaz.

1. **Önce tespit — dokunmadan önce.** Nereye, neden, ne kadar dokunacağını
   yaz: dosya, satır, ne değişecek. Yanına "dokunmayacağım" listesini de yaz.
   Onay al, sonra başla. Kapsam onaydan sonra büyütülemez.
2. **Sadece onaylanan satırlar.** Yol üstünde başka bir hata görsen bile
   dokunma; ayrıca söyle. Hiçbir şey "geri getirilmez", hiçbir bölüm
   eklenmez/kaldırılmaz.
3. **Yayılma alanını ölç.** Dokunduğun dosya/bileşen başka nerelerde
   kullanılıyor — hepsini bul ve yaz. "Başka yeri kırmadım" cümlesi ancak bu
   ölçümle kurulabilir.
4. **Kapıları koş.** Testler, tip kontrolü, lint, üretim derlemesi. Gerçek
   çıktıyı yaz (kaç test geçti), "yeşil" deyip geçme.
5. **GÖRSEL KANIT — jargonsuz.** Görünen her değişiklikte öncesi/sonrası
   resmini Casper'a gönder. Kod okuyarak "böyle görünecek" demek yasak.
   Gerçek panele girilemiyorsa (giriş gerekiyorsa) bunu açıkça söyle ve
   sitenin kendi derlenmiş stil dosyasıyla izole kopyasını çizip göster —
   ama "gerçek ekran değil" diye belirt.
6. **Dal / ana dal / canlı ayrımı + geri alma.** Değişikliğin şu an nerede
   olduğunu üç kelimeyle söyle, test adresini yaz, geri alma komutunu ver.

**Anlatım kuralı:** teknik terim kullanma. Kullanmak zorundaysan yanına tek
cümlelik Türkçe karşılığını yaz. Yarım anlatma — Casper'ın projeye hâkimiyeti
senin anlatımına bağlı.

Neden: 2026-09-24'te panelin Hakkımızda/SSS/Kampanya/Pazaryeri/Galeri kutuları
"beyaz zemin üstünde beyaz yazı" olduğu için görünmez hale gelmişti; sebebi,
1 Eylül'de bu kutular açılır pencereden panele gömülürken zemin renginin beyaz
bırakılmasıydı. Casper'ın sorusu şuydu: "başka bir yeri kırmadığına nasıl emin
olacaksın?" Cevabı üreten şey bu 6 adım oldu.

---

## B. Yazarken

### 5. Yorum satırı kuralı (2026-09-09)
Kod içine **yeni** yorum satırı ekleme (`//`, `/* */`, `#`, `<!-- -->`, `--`).
Açıklama gerekiyorsa mesaja yaz.

Var olan bir yorumu **kendi kararınla** değiştirme veya silme. Ama bir yorum
fiilen yanlış hâle gelmişse (ör. kaldırılmış bir dosyayı, geçmiş bir sayıyı
gösteriyorsa) bunu Casper'a söyle — onay verirse **yalnız o yorum** düzeltilir.
Yanlış bilgi taşıyan bir yorumu "dokunma" diye korumak, yanlışın kalıcı
olmasına izin vermektir.

### 6. Anahtarı/jetonu dosyaya gömme (2026-08-19 sızıntısı)
Ortam değişkeni kullan. Alanın ADINA güvenme, değerin şekline bak.

### 7. Başka ajanın işine girme (2026-09-10)
Bir düzeltme teklif etmeden önce `git log --oneline -5 -- <dosya>` ile yakın
zamanlı bir commit var mı bak. Kendi yazdığını sonra "hata buldum" diye
raporlama.

### 8. Aynı klasörde iki ajan çalıştırma (2026-08-26)
İş sessizce silinir.

### 9. Dal açarken tabanı uzaktan al
Yerel ana daldan alma; yerel kirli olabilir.

---

## C. Bitirdim demeden önce

### 10. Yeşil test, "çalışıyor" demek değil (2026-09-03)
Gerçek çıktıyı çalıştır, ekranı aç. Görsel/UI hatasında canlı doğrula;
göremiyorsan "göremedim" de, tahminle "düzelttim" deme.

### 11. Görsel/UI hatasında önce canlı doğrula (2026-09-03)
Bir UI/görsel hatayı (ekran görüntüsüyle bildirilen, "kutu kaymış", "boşluk
yanlış" tarzı) koda bakıp tahminle düzeltip commit etme. Önce canlı aç, sorunu
kendi gözünle gör, düzeltmeyi uyguladıktan sonra AYNI şekilde tekrar bak ve
doğrula — ancak öyle "düzelttim" de. Canlı doğrulama gerçekten mümkün değilse
(ör. sandbox'tan Supabase'e ağ erişimi yok) bunu açıkça söyle ve Casper'dan
ekran görüntüsü/canlı bakış iste — kör tahminle commit atma.

Neden: aynı gün iki uzun oturum (807 ve 461 mesaj) büyük ölçüde verimsiz
soru-cevap döngüsüne girdi.

### 12. Ajan kendi işini denetlemez
Üreten ayrı, doğrulayan ayrı.

### 13. Ağır kapılar elde (2026-09-12 ölçümü)
Testler, tip kontrolü, lint, üretim derlemesi. Bunlar kancaya konmadı çünkü tek
dosya lint'i bile 50 saniye sürüyor. Merge öncesi `bash tool/merge-hazir.sh`
koşulur; güncel kapı listesi `.github/workflows/ci.yml` içindedir.

(2026-09-29'a kadar burada `kapilar` adlı bir kısayoldan söz ediliyordu; öyle
bir komut depoda hiç yoktu. Doğru adres `tool/merge-hazir.sh`.)

---

## D. Bitmemiş iş ve saha düzeni

### 14. Bitmemiş iş burada beklemez (2026-09-29)
El emeği, üretildiği gün kendi hattına alınır. Bir iş bittiğinde hattı ve
geçici çalışma alanı silinir. Bu klasör bir geçici çalışma masası değildir.

Neden: 2026-09-29'da sipariş/tahsilat işi günlerce kaydedilmeden bu klasörde
durdu; bu klasör ana dalın 32 adım gerisinde kaldı ve aynı dönemde yazılan
belgeler "çelişkili" hâle geldi. Belgeler yanlış değildi, **eskiydi**: çelişki
diye görünen şeyin kökü, geride kalmış bir kopyaydı.

**Eki (2026-10-03) — dal taşıma düzeni ve ölçüm kanca:**
Bir işin **tek** taşıyıcı dalı olur; aynı iş için ikinci dal açılmaz. Taşıyıcı
dal üç gün içinde push edilmezse veya işi main'e/önizlemeye alınmazsa dal
kapatılır — sessizce bekleyen dal, unutulmuş iştir. Haftada bir
`bash tool/dal-durumu.sh` koşulur; çıktısındaki SESSİZ (3+ gün), ESKI (15+
gün), GERIDE (100+ commit) etiketleri bir sonraki oturumda kapatılır.
"SILINEBILIR" etiketi `git cherry` novel=0 demektir: iş zaten main'dedir, dalın
görevi bitmiştir; silme onayı yine Casper'ındır. Merge kapısı ayrıdır:
`bash tool/merge-hazir.sh` (kural 13).

Neden (2026-10-03 ölçümü): ölçüm yokken depoda 71 yerel dal ve 46 worktree
birikti; 35 dal tamamen boş, 31 worktree mezarlıktı ve kimse fark etmiyordu.
Aynı ölçümde 61 dal üç gündür, 31 dal on beş gündür dokunulmamış; 34 dal
main'den yüzün üzerinde commit gerideydi. Sayılmayan dal çoğalır.

---

## E. Rapor verirken

### 15. Dal, ana dal ve canlı ayrı şeyler
"Gönderdim" demek canlıda düzeldi demek değil. Hangisinden bahsettiğini açıkça
yaz.

### 16. Taslak/WIP/deneme commit ana dala inmez (2026-09-10)
Onaydan önce farkı oku.

### 17. Test adresini hep yaz
Hangi adrese bakılacağı yazılmazsa yanlış sürüm test edilir.

### 18. Cevap kısa olsun (2026-09-10)
Kanıt istenmeden dökülmez. Migration sürüm numarası, commit hash'i, satır
numarası gibi detaylar sonuç değildir: önce 2-3 cümlelik sade sonuç, detay
yalnız sorulursa. Cevabın sonuna soru/şüphe/uyarı iliştirme; bir hatayı kabul
ediyorsan sadece kabul et, arkasına savunma ekleme. Kapanışta soru gerekiyorsa
tek soru olsun ve gerçekten Casper'ın kararı olsun.

Neden: 2026-09-10 oturumunda aynı gün ana dala alınmış bir düzeltme sıfırdan
keşfedilip "canlıya uygulayayım mı" diye soruldu; cevaplar tablo/hash/satır
numarasıyla şişirildi ve hatayı kabul eden mesajın sonuna yine soru eklendi.
Casper: "artık seninle çalışmaktan bıkmaya başladım."

---

## F. Canlıya almadan önce

### 19. Önizleme adresi yalnız canlıyı yayınlayan projeden verilir (2026-10-08)
Canlı (vixrex.com) tek bir Vercel projesinden yayınlanır: `vixrex-public`.
`vixrex-app` projesinin önizlemesi farklı bir kabuk açar ve hiç canlıya
çıkmaz; adresi Casper'a test adresi diye verilmez, kanıt sayılmaz.

Casper'a önizleme adresi vermeden önce iki şey ölçülür ve mesaja yazılır:
1. Canlı hangi commit'te: `gh api repos/xpodiumyours/vixrex/deployments`
   çıktısında `Production – vixrex-public` satırının commit'i.
2. Dalın tabanı o commit mi: `git merge-base <dal> origin/main`.
İkisi aynı değilse dal `origin/main` üstüne yeniden alınır, sonra adres
verilir. Verilen adres `vixrex-public-git-...` ile başlamalı ve Casper'ın
canlıda kullandığı sayfa yolu (ör. `/app/urunler`) eklenmelidir.

Durum ölçümü, tablo ve "kodda ne var" tespiti de yalnız `origin/main`
üzerinden yapılır; yerel `main` kanıt değildir.

Neden: 2026-10-08'de yerel `main` uzaktakinin 16 commit gerisindeydi; dokuz
adımlık durum tablosu eski kopyadan ölçüldü ve "şemasız istem, JSON kesme,
elle site tarayıcı" gibi gerçek `main`'de çoktan kapanmış eksikler açıkmış gibi
yazıldı. Aynı gün ajan test adresi olarak `vixrex-app` önizlemesini verdi;
Casper `/home` sayfasında bambaşka bir ürün paneli gördü ve o gün düzeltilen
ürün ekleme sayfasının yeniden bozulacağını sandı. Kod aynıydı; adres yanlıştı.

### Token ekonomisi (2026-09-16)
Token en kıt kaynak. Bitince koordinasyon, doğrulama ve merge sorumluluğu
duruyor — yani proje duruyor. Yavaş ajan, duran projeden iyidir.

- Arama, tarama, envanter, ölçüm, raporlama ve kodun kendisi ajana verilir.
- Koordinatörde kalan: hedefi yazmak, ajanın raporunu doğrulamak, riskli tek
  noktayı **tek komutla** ölçmek, commit/merge/sıra takibi.
- Görev yazmadan önce dosya adı doğrulamak için komut çalıştırma; ajan bulur.
- Ölçüm yalnız bir **karar** ona bağlıysa yapılır.
- Her yeni faz → yeni oturum; şişmiş bağlam her cevabı pahalılaştırır.
- Uzun rapor yazma; sonuç tek satır, detay istenirse gelir.
