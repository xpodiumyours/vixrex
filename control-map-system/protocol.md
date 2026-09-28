# Vixrex Control Map Protocol v1

## Kapsam
Bu branch Vixrex'in bağımsız kontrol haritası omurgasıdır. Base44 yalnızca kalıcı görüntü/komuta yüzeyi olabilir; sistem gerçeği Base44'a bağlı değildir.

## Kanonik dosyalar
- `control-map-system/map.json`: insan kontrollü yapı; node ve ilişkiler.
- `control-map-system/state.json`: ölçülmüş canlı durum.
- `control-map-system/tasks.json`: ajan görev kuyruğu ve kilitler.
- `control-map-system/protocol.md`: bu kurallar.

## Gerçek kaynakları
- GitHub = kod ve CI gerçeği.
- Vercel = deploy gerçeği.
- Supabase = production veri gerçeği.
- `/api/health` = runtime gerçeği.
- Playwright/E2E = kullanıcı akışı kanıtı.

## Durum kuralları
- healthy: yalnız kanıt varsa.
- broken: ölçülmüş başarısızlık.
- partial: kısmi/eksik çalışma.
- unknown: ölçülmemiş veya kanıtsız.
- disabled: bilinçli kapalı.
- Unknown hiçbir zaman tahminle green yapılmaz.
- Kod, Preview, Live, Data ve E2E ayrı gerçekliklerdir.

## Çok ajanlı yönetim
1. ChatGPT, Base44 ajanı ve diğer ajanlar aynı `map/state/tasks` dosyalarını kullanır.
2. Bir ajan görevi almadan önce `tasks.json` içindeki kilidi kontrol eder.
3. Görev kapsamı seçilen node + doğrudan bağımlılıklarla sınırlıdır.
4. Yeni bağımlılık bulunursa `map.json` için öneri üretilebilir; görev kapsamı otomatik genişlemez.
5. Aynı göreve iki ajan aynı anda yazmaz.
6. Ajan kendi işini tek başına green/proven ilan etmez; ayrı kanıt gerekir.

## Değişiklik izni
Aşağıdakiler kullanıcı onayı olmadan YASAK:
- main merge
- production deploy/publish
- Supabase schema/RLS değişikliği
- geri döndürülemez veri işlemi
- ödeme/auth/güvenlik ayarı değişikliği

Read-only ölçüm, kanıt toplama ve control-map branch güncellemesi serbesttir.

## Branch ve deploy izolasyonu
Kanonik kontrol omurgası `control-map-system` branch'indedir.
Vixrex Vercel yapılandırması `* = false` olduğu için bu branch production/preview deploy tetiklemez.
GitHub CI mevcut yapılandırmada yalnız PR ve main push'ta çalışır.
Bu branch main'e otomatik birleştirilmez.

## Base44
Base44'ın görevi:
- bu dosyaları okumak,
- haritayı çizmek,
- kullanıcı komutlarını görev olarak yazmak/göstermek,
- Base44 ajanı uygun olduğunda aynı protokolü kullanmak.

Base44 build/AI limiti kontrol omurgasının varlığını veya diğer ajanların yönetimini durdurmaz.
