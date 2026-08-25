# Şube / Çoklu Konum Desteği

VixRex bilinçli olarak **tek hesap = tek vitrin** modeliyle çalışır. Bir işletme
hesabı aynı anda yalnızca bir mağaza satırına sahip olabilir
(`stores` tablosundaki `unique_user_store UNIQUE (user_id)` kısıtı). Şube,
çoklu konum veya zincir işletme yönetimi desteklenmez.

## Neden kapsam dışı

Bu kısıt tesadüf değil, ürünün hedef kitlesiyle uyumlu bir tasarım kararıdır:

- VixRex'in ilk hedefi bireysel esnaf ve tek mekânlı küçük işletmelerdir;
  "tek sahip, tek vitrin" basitliği hem kayıt akışını hem sahiplik/yetki
  modelini sade tutar.
- Şube desteği tek başına bir kısıt kaldırma işi değildir: mağazalar arası
  ilişki şeması, şube bazlı yetkilendirme (RLS), şube seçimi UI'ı ve iki
  istemcideki (Flutter panel + Next.js Asistan) akışların tümü yeniden
  tasarlanmasını gerektirir.
- Bu büyüklükte bir değişiklik, gerçek bir talep kanıtı olmadan yapılmaz.

## Yeniden değerlendirme koşulu

Zincir işletme / çok şubeli esnaf talebi somutlaştığında (ör. birden fazla
ödeme yapan müşteri adayı bu özelliği istediğinde) karar yeniden ele alınır.
İlgili issue yeniden açılabilir; bu dosya silinip normal triage akışına
dönülür.

## Prior requests

- #256 — "Şube/çoklu konum desteklenmiyor — 'unique_user_store' kısıtı bir kullanıcıya tek mağaza sınırlıyor"
