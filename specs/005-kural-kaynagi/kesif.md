# Keşif

İSTEK: "Bana özel kurulumun birinci maddesinden başla: Claude da diğer ajanlarla aynı ortak kuralı okusun."

## Bugün ne var

ÖLÇÜLDÜ: AGENTS.md — 58 satırlık ortak kural dosyası, "bütün insanlar ve yapay zekâ araçları için geçerlidir" diyor.
ÖLÇÜLDÜ: CLAUDE.md — 174 satır; resmî dokümana göre Claude yalnız bu dosyayı okuyor, AGENTS.md'yi okumuyor. İçinde AGENTS.md yalnız bir kez, "kaldırıldı" diyen eski bir notta geçiyor.
ÖLÇÜLDÜ: .specify/memory/constitution.md — yedinci ilke, onay verildikten sonra teknik ayrıntının tekrar sorulmayacağını söylüyor; CLAUDE.md'nin ilk maddesi ise her adımı sormayı istiyordu.

## Gelişim nereden başlar

BAŞLANGIÇ: CLAUDE.md'nin ilk satırından. Ortak kural oraya bağlanmadan Claude oturumları ortak sistemi hiç görmüyor.

## Nerede biter

BİTİŞ: Claude oturumu açıldığında AGENTS.md'nin yüklendiği ve onay kuralının Anayasa ile aynı şeyi söylediği görüldüğünde biter.

## Ne gözükecek

GÖRÜNEN: Oturum başında yüklenen kural dosyaları arasında AGENTS.md; CLAUDE.md'de tek ve Anayasa ile uyumlu bir onay maddesi.

GÖRÜNÜM: Metin değişikliği; ekranda karşılığı yok.

## Kim ne kazanır

ESNAF: Doğrudan kazanç yok; dolaylı kazanç, ajanların çelişen kural yüzünden yanlış iş yapmaması.
VIXREX: Dört ajan aynı kuralı okur; çelişen iki kural arasında rastgele seçim yapılması biter.
TÜKETİCİ: Doğrudan kazanç yok.

## Ne korunacak

KORUNACAK: 3 Eylül olayının koruması gevşemeyecek — onaysız uygulama yine yasak; onay noktası tek yere, Keşif kaydına taşınıyor. Varsayım, tahmin, kod içi yorum yasağı ve görsel doğrulama maddeleri aynen kalıyor.

## Etkilenen yüzeyler

YÜZEYLER: Yalnız CLAUDE.md. Ürün kodu, veritabanı, yayın ayarları ve kancalar değişmiyor.

## Dokunulmayacak

KAPSAM DIŞI: AGENTS.md içeriği, kancalar, kural klasörü, alt ajanlar, beceri ve CI incelemesi — bunlar kurulumun sonraki maddeleri.

## Karar

KARAR SORUSU: yok
ONAY: alındı
