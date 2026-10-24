# Vixrex fatura → ürün kartı AI akışı

Bu klasör, OpenRouter preset’leri ile Vixrex kodu arasındaki **tek sürüm kaynağıdır**. Canlı ayar değişikliği yapılmadan önce bu dosyalar aynı kod commit’inde bulunmalı ve testleri geçmelidir.

## İki iş, iki preset

1. `invoice-read.system.md`: yalnız belge/fatura okur. Ürün araması yapmaz. Çıktısı `vixrex.invoice-read/1.0`.
2. `product-research.system.md`: her fatura satırının `row_id`’siyle üreticinin resmî ürün sayfasını araştırır. Çıktısı `vixrex.product-research/1.0`.

OpenRouter’da mevcut iki slug korunur. Yeni test preset’i açılmaz. `archive/` altında üretimde gözlenen önceki promptlar, sürüm numaraları ve hash’leri geri dönüş için saklanır. Canlı sürümlerin ve hedef ayarların kaydı `release-manifest.json` dosyasındadır. Üretimdeki sürüm numarası ve araçlar API’den yeniden okunup manifestle karşılaştırılmadan “yayında” denmez.

OpenRouter’da `@preset/slug` isteği her zaman en son preset sürümünü kullanır; belirli eski sürüm yalnızca görüntülenebilir, istek için sabitlenemez ([OpenRouter preset belgeleri](https://openrouter.ai/docs/guides/features/presets)). Bu yüzden Vixrex dalı geçişte yeni ve eski istek biçimlerini birlikte gönderir; eski ve yeni yanıtları da okuyabilir. Canlıya geçiş sırası şöyledir: önce bu uyumlu Vixrex kodunu dağıt; sonra **ürün araştırma preset’ini** güncelle ve tek test faturasıyla doğrula; ancak o geçince **fatura okuma preset’ini** güncelle. Bir adım geçmezse kaydedilmiş önceki ayarı geri yükle. Böylece üretimdeki esnaf akışı ile presetler sırayla uyumlu kalır.

## Değişiklik kapıları

- **Kod kapısı:** şema/adaptör testleri, tüm fatura testleri, tip denetimi ve lint geçer.
- **Preset kapısı:** doğru model modalitesi ve araçları doğrulanır; tam prompt, model, araç listesi ve şema sürümü manifestte kayıtlı olur.
- **Canlı kapı:** yalnız mevcut slug’da yeni sürüm; ardından sürüm ayarını OpenRouter API’den tekrar oku. Başarısızsa kayıtlı önceki ayarı aynı slug’a geri bas; yeni slug silmeye veya kör tekrar denemeye çalışma.
- **İş kabul kapısı:** gerçek fatura Vixrex arayüzünden yüklenir. Satır sayısı, kimlikler, kaynak sayfalar ve görseller; satış fiyatının boş olduğu gizli taslaklar; esnaf fiyatı ve onayı olmadan yayının kapalı olduğu doğrulanır.

**Yayın kabul kuralı:** ham fatura fotoğrafı veya tam fatura metni loglara yazılmaz. İzleme kaydı preset slug/sürümü, model, iş/istek kimliği, süre, kullanım/maliyet, satır/kart sayıları ve hata kodunu tutar. Şüpheli veya bulunamayan ürün silinmez ve “doğrulandı” gösterilmez; faturadaki gerçek bilgilerle taslak kalır.

## Bu dalın durumu

Bu feature branch sözleşme v1 ve yerel adaptör/test değişikliklerini içerir. Manifestteki yeni preset ayarları henüz canlıya uygulanmadı. Bu nedenle kod, preset ve gerçek fatura Vixrex uçtan uca sonucu birlikte doğrulanmadan production’a alınmamalıdır.
