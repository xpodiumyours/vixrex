# Keşif

İSTEK: "Ben doğal dil ile istediğimi söylicem, konuştuğum ajan Vixrex'e uygun gelişimin nereden başlayacağını, nerede biteceğini, ne gözükeceğini, nasıl gözükeceğini, esnafa, Vixrex'e ve tüketiciye ne katacağını söyleyecek bir zincir istiyorum."

## Bugün ne var

ÖLÇÜLDÜ: DEVELOPMENT.md — zincir Anayasa'dan sonra doğrudan Specify ile başlıyordu; doğal dildeki isteği ölçülmüş bir resme çeviren bir halka yoktu.
ÖLÇÜLDÜ: .github/scripts/gelisim_zinciri_guard.py — merkezi kontrol yalnız belgelerin var olup olmadığına ve içlerindeki kalıp cümlelere bakıyordu; hiçbir iddiayı gerçeğe bağlamıyordu.
ÖLÇÜLDÜ: AGENTS.md — ortak çalışma biçiminde "Furkan sonucu söyler" yazıyordu, ama sonucun nasıl yazılı hâle geleceği tarif edilmemişti.
ÖLÇÜLDÜ: specs/000-gelisim-sistemi/review.md — bağımsız inceleme kaydını işin üreticisi yazmıştı; inceleyenin kim olduğu kayıtta yoktu.
ÖLÇÜLDÜ: .specify/templates — hata yolu, zincir durumu, yakınsama ve inceleme için şablon yoktu; kapının aradığı tam yazımlar yalnız kontrol dosyasının içindeydi.

## Gelişim nereden başlar

BAŞLANGIÇ: Zincirin ilk kırık halkası Anayasa ile Specify arasıdır. Furkan'ın cümlesi ile ilk teknik belge arasında ölçüm, sınır ve kazanç yazan hiçbir adım yoktu; iş oradan başlar.

## Nerede biter

BİTİŞ: Furkan bir şey istediğinde, konuştuğu ajan tek belgede bugünkü hâli gerçek dosya yollarıyla, işin başlangıcını ve bitişini, ne ve nasıl gözükeceğini, esnaf, Vixrex ve tüketici kazancını yazdığında ve bu belge onaylanmadan sonraki adımların başlamadığı merkezi kontrolce doğrulandığında biter.

## Ne gözükecek

GÖRÜNEN: Her iş klasöründe kesif.md; PR sayfasında "Keşif özeti" bölümünde aynı cevapların kısa hâli; eksik veya uydurma yol varsa GitHub kontrolünde kırmızı satır.

## Nasıl gözükecek

GÖRÜNÜM: Teknik olmayan sade Türkçe, sabit başlıklar ve tek satırlık işaretler. Eksik hâl belirsiz kalmaz: kontrol hangi satırın boş olduğunu, hangi yolun depoda bulunmadığını ve hangi değişikliğin kayıtta geçmediğini adıyla yazar.

## Kim ne kazanır

ESNAF: Kendisine gösterilecek ekranın ne olduğu ve neyi değiştireceği iş başlamadan yazılı olduğu için yarım kalan, yanlış yere çizilmiş veya sahte veriyle doldurulmuş ekranlarla karşılaşmaz.
VIXREX: Doğal dildeki istek ile teslim edilen iş arasındaki mesafe ölçülebilir hâle gelir; kayıtta geçmeyen değişiklik teslim edilemediği için sessiz kapsam kayması durur.
TÜKETİCİ: Vitrinde gördüğü bilginin kaynağı ve nerede biteceği baştan tarif edildiği için kaynağı olmayan, boş veya yanlış görünen alanlarla karşılaşmaz.

## Etkilenen yüzeyler

YÜZEYLER: Gelişim sistemi belgeleri (Anayasa, DEVELOPMENT.md, AGENTS.md), Spec Kit akışı, GitHub merkezi kontrolü ve PR şablonu. Ürün kodu, veritabanı, Flutter paneli ve canlı yayın ayarları bu işte değişmez.

## Dokunulmayacak

KAPSAM DIŞI: Ürün kodu ve veritabanı; canlı yayın ayarları; CLAUDE.md ve .claude altındaki araç kancaları; teslimat işinin zorunlu kapı listesi; ana dal koruma ayarı.

## Karar

KARAR SORUSU: yok
ONAY: alındı
