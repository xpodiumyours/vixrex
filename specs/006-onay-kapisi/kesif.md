# Keşif

İSTEK: "Sıradaki madde 5: ürün koduna yazmadan önce onayı makine seviyesinde arayan kanca. Evet başla."

## Bugün ne var

ÖLÇÜLDÜ: .claude/hooks — beş kanca var: tehlikeli git komutu, hassas dosya, anahtar sızıntısı, yorum satırı, dal durumu. Onay arayan bir kanca yok.
ÖLÇÜLDÜ: CLAUDE.md — onay kuralı metin olarak yazılı; resmî dokümana göre bu dosya bağlamdır, zorlayıcı ayar değildir.
ÖLÇÜLDÜ: .github/scripts/gelisim_zinciri_guard.py — onay yalnız teslimatta, yani iş bittikten sonra ölçülüyor; yazma anında hiçbir engel yok.

## Gelişim nereden başlar

BAŞLANGIÇ: Yazma anından. Onay bugün ancak PR'da fark ediliyor; oysa zararın oluştuğu an dosyanın değiştiği andır.

## Nerede biter

BİTİŞ: Onaysız bir işte ürün kodu dosyasına yazma denemesi durdurulduğunda, onaylı işte ve hata düzeltmesinde ise hiçbir sürtünme yaratmadığında biter.

## Ne gözükecek

GÖRÜNEN: Onay yokken ürün dosyasına yazma denemesinde, hangi işin açık olduğunu ve neyin eksik olduğunu söyleyen bir durdurma mesajı.

GÖRÜNÜM: Yalnız ajan oturumunda görünür; esnafın veya ziyaretçinin gördüğü hiçbir şey değişmez.

## Kim ne kazanır

ESNAF: Onaysız değişiklik canlıya ulaşamadığı için vitrini habersiz bozulmaz.
VIXREX: 3 Eylül'de yaşanan sessiz değişiklik makine seviyesinde engellenir; kural metin olmaktan çıkar.
TÜKETİCİ: Doğrudan kazanç yok.

## Ne korunacak

KORUNACAK: Hata düzeltmesi hızlı kalacak — sebep kaydı olan işte kanca durdurmaz. İş kayıtları, belgeler ve ayar dosyaları her zaman yazılabilir kalacak; aksi hâlde keşif yazılamaz ve sistem kilitlenir. Mevcut beş kanca aynen çalışmaya devam edecek.

## Etkilenen yüzeyler

YÜZEYLER: Yalnız Claude oturumunun kancaları ve ayar dosyası. Ürün kodu, veritabanı ve yayın ayarları değişmiyor.

## Dokunulmayacak

KAPSAM DIŞI: Diğer araçlar (kanca yalnız Claude'u bağlar), CI kapısı, kural klasörü, alt ajanlar ve beceri.

## Karar

KARAR SORUSU: yok
ONAY: alındı
