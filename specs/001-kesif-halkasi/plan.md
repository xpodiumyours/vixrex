# Plan

## Ölçüm

Mevcut hâl `kesif.md` içinde beş ölçümle yazıldı: zincirin Anayasa'dan sonra
doğrudan Specify ile başlaması, merkezi kontrolün yalnız belge varlığı ve kalıp
cümle araması, ortak çalışma biçiminde isteğin nasıl yazıya geçeceğinin
tarifsiz olması, önceki işin inceleme kaydını üreticinin yazmış olması ve hata
yolu için şablon bulunmaması.

## Çözüm

1. `.specify/templates/kesif-template.md` — keşif belgesinin sabit şekli.
2. `.specify/templates/zincir-template.md` — üç iş türünün aşama satırlarının
   birebir yazımı; hata yolunun yazımı ilk kez belgede görünür.
3. `.specify/templates/root-cause-template.md` — hata yolunun sebep kaydı,
   ölçülmüş yol satırı zorunlu.
4. `.specify/templates/convergence-template.md` ve
   `.specify/templates/review-template.md` — kapanış kayıtlarının şekli;
   inceleme kaydında inceleyenin adı istenir.
5. `.github/scripts/gelisim_zinciri_guard.py` — kapıya üç yeni ölçüm eklendi:
   keşif satırlarının dolu olması, gösterilen yolların depoda gerçekten
   bulunması ve değişen her ürün dosyasının kayıtlarda geçmesi.
6. `DEVELOPMENT.md` — Keşif ikinci adım olarak eklendi, kapının aradığı bütün
   tam yazımlar belgeye yazıldı.
7. `.specify/memory/constitution.md` — birinci ve dokuzuncu ilkeye Keşif
   eklendi, sürüm 2.2.0 olarak tarih ve gerekçesiyle kaydedildi.
8. `AGENTS.md` — ortak kural dosyasında iş türü listesi ve kayıt bölümü
   Keşif'i içerecek biçimde güncellendi.
9. `.specify/workflows/speckit/workflow.yml` — Anayasa kapısından sonra Keşif
   kapısı eklendi; adım tipi mevcut şemadaki kapı biçimidir.
10. `.github/pull_request_template.md` — "Keşif özeti" bölümü ve Keşif satırı
    eklendi.

## Neden bu şekil

Kapı bir belgenin doğru olduğunu ölçemez. Ölçebileceği şey, belgenin gerçek
dosyalara dayanıp dayanmadığı ve teslim edilen değişikliğin kayıtla aynı şeyden
bahsedip bahsetmediğidir. Bu iki ölçüm, görmeden yazılmış keşfi ve kayıtta
geçmeyen sessiz değişikliği durdurur.

## Geri alma

Değişiklik tek commit'tir ve yalnız gelişim sistemi dosyalarına dokunur; geri
alınması tek commit'in geri alınmasıdır, ürün davranışını etkilemez.
