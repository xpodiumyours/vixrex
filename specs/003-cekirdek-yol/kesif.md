# Keşif

İSTEK: "Çekirdek yola çevir. Gelişim zinciri gerekirse bataklığa sokar; ajanları hedefe değil bataklığa sokuyorsa temizlenmeli."

## Bugün ne var

ÖLÇÜLDÜ: .github/scripts/gelisim_zinciri_guard.py — özellik ve değişiklik için dokuz belge ve on bir aşama zorunluydu; bunların dördü yalnız sabit bir cümle taşıyordu.
ÖLÇÜLDÜ: specs/001-kesif-halkasi — tek bir sistem değişikliği için yazılan kayıtlar toplam 1410 kelime tuttu.
ÖLÇÜLDÜ: public_web/package.json — iki dosyalık bir bağımlılık güncellemesi kapıdan geçemiyordu; kapı "tam olarak bir specs/<iş> kaydıyla gelmeli" diyip duruyordu.
ÖLÇÜLDÜ: .specify/workflows/speckit/workflow.yml — akış her işte Clarify, Checklist ve Analyze adımlarını koşulsuz yürütüyordu.
ÖLÇÜLDÜ: DEVELOPMENT.md — zorunlu sıra on iki adımdı ve risk kadar kapı açma kavramı yoktu.

## Gelişim nereden başlar

BAŞLANGIÇ: Merkezi kontrolden. Zorunlu belge listesi ve aşama listesi orada tanımlı; belgeler ve akış dosyası onu takip ediyor.

## Nerede biter

BİTİŞ: Küçük bir bakım değişikliği kayıt yazmadan kapıdan geçtiğinde, yeni bir özellik beş kayıtla yürüdüğünde ve veritabanına dokunan bir iş kanıtını yazmadan geçemediğinde biter.

## Ne gözükecek

GÖRÜNEN: İş klasöründe dokuz yerine beş kayıt; zincir durumunda açılan kapılar ve kanıtları; bağımlılık güncellemelerinde kapının "iş kaydı gerekmez" demesi.

GÖRÜNÜM: Kapı hangi kapının neden açılması gerektiğini adıyla yazar. Açılmayan kapı hiç görünmez; riski olmayan işe kapı takılmaz.

## Kim ne kazanır

ESNAF: Küçük düzeltmeler ve güvenlik güncellemeleri belge beklemeden geldiği için vitrinindeki hatalar daha çabuk kapanır.
VIXREX: Ajanlar belge doldurmaya değil işe zaman ayırır; kapı yalnız gerçekten risk olan yerde durur.
TÜKETİCİ: Ekranı ve veriyi değiştiren işlerde kanıt zorunlu kaldığı için gördüğü vitrin bozulmadan gelişir.

## Ne korunacak

KORUNACAK: Kapının gerçek ölçümleri aynen kalacak — keşif satırlarının dolu olması, gösterilen yolların depoda bulunması, onayın alınmış olması, tamamlanmamış görev bırakılmaması ve değişen her dosyanın kayıtlarda geçmesi. Bunların hepsi bu işten sonra da kırmızı verebilmeli.

## Etkilenen yüzeyler

YÜZEYLER: Merkezi kontrol, Anayasa, DEVELOPMENT.md, AGENTS.md, Spec Kit akışı, PR şablonu ve şablon dosyaları. Ürün kodu, veritabanı ve yayın ayarları değişmez.

## Dokunulmayacak

KAPSAM DIŞI: Ürün kodu, veritabanı, canlı yayın ayarları, teslimat zincirinin zorunlu kapı listesi, CLAUDE.md ve araç kancaları.

## Karar

KARAR SORUSU: yok
ONAY: alındı
