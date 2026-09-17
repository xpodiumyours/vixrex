# Plan

## Ölçüm

Kapının hangi denetiminin hangi belgeyi okuduğu tek tek çıkarıldı: gerçek
ölçümler keşif, görevler ve zincir durumu dosyalarında; kontrol listesi,
çelişki taraması, yakınsama ve inceleme dosyaları yalnız birer sabit cümle
taşıyordu. Bir bağımlılık güncellemesi kapıya verildi ve reddedildi.

## Çözüm

1. `.github/scripts/gelisim_zinciri_guard.py` — zorunlu kayıt listesi beşe
   (hata yolunda üçe) indirildi; bakım muafiyeti eklendi; yakınsama ve inceleme
   satırları zincir durumundan okunur oldu; açılan kapı ve kanıt denetimi ile
   veritabanı değişikliğinde veri kapısının kendiliğinden zorunlu olması
   eklendi; keşifte korunacak davranış satırı zorunlu yapıldı.
2. `DEVELOPMENT.md` — çekirdek yol, iş türleri, kapı listesi ve "bir özellik
   istediğinde ne oluyor" anlatımı yeniden yazıldı.
3. `.specify/memory/constitution.md` — dokuzuncu ilke çekirdek yol ve isteğe
   bağlı kapı diliyle güncellendi, sürüm 2.3.0 olarak gerekçesiyle kaydedildi.
4. `AGENTS.md` — ortak kural dosyasındaki kayıt listesi ve sıra güncellendi.
5. `.specify/workflows/speckit/workflow.yml` — Clarify, Checklist ve Analyze
   adımları çekirdek akıştan çıkarıldı.
6. `.github/pull_request_template.md` — aşama listesi kısaltıldı, açılan kapılar
   bölümü eklendi.
7. `.specify/templates/zincir-template.md` — yeni aşama ve kapanış satırları.
8. `.specify/templates/kesif-template.md` — korunacak davranış bölümü eklendi.
9. `.specify/templates/convergence-template.md` ve
   `.specify/templates/review-template.md` — karşılığı tek satıra indiği için
   kaldırıldı.

## Geri alma

Tek commit; geri alınması tek commit'in geri alınmasıdır, ürün davranışını
etkilemez.
