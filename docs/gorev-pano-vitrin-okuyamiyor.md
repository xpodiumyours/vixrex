# Görev — /app panosu kullanıcının vitrinini okuyamıyor

**Yazan:** Claude (27 Ağustos 2026, 19:15) · **Yürüten:** Freebuff · **Doğrulayan:** Claude

**Canlıda gerçek bir hesapla ölçüldü.** Bu, blog/randevu işinden ayrı ama
onu görünmez kılan bir kırık — aynı PR'a girsin.

## Belirti

Gerçek bir hesapla `https://vixrex-public.vercel.app/giris` üzerinden girip
`/app` panosuna geçtim. Hesabın **vitrini var** (veritabanında doğruladım:
`deneme-kuafor-salonu-mtbp9tip`, `user_id` dolu). Pano yine de:

- "Vitrin bilgileri yüklenemedi. Lütfen sayfayı yenileyip tekrar dene."
- Altında "İLK ADIM — Vitrinini oluştur" formu (sanki hiç vitrini yokmuş gibi)
- Ürün yönetimi, blog ve randevu bağlantıları **hiç çıkmıyor**

Yani bugün eklenen blog/randevu bağlantıları kullanıcının önüne asla gelmez.

## Sebep (ölçüldü, tahmin değil)

`public_web/src/app/app/page.tsx` içindeki `magazalariGetir`:

```ts
.from("stores").select(...).eq("user_id", userId)
```

Canlıda `authenticated` rolünün `stores` tablosunda SELECT izni olan
sütunları şunlar:

```
id, is_published, kategori, name, slug, updated_at
```

**`user_id` bu listede yok** (V-09 sertleştirmesinde bilinçli olarak
kaldırıldı). Okunamayan bir sütuna göre filtrelemek 42501 ile düşüyor.

Aynı hata 26 Ağustos'ta Flutter tarafında da çıkmıştı ve orada
`bootstrap_owner_state` RPC'siyle çözülmüştü. Web tarafı o düzeltmeyi
almamış.

## Yapılacak

`magazalariGetir` artık `user_id` ile filtrelemesin. Sıra şu olsun:

1. `supabase.rpc("bootstrap_owner_state")` çağır — parametresiz, `auth.uid()`
   üzerinden çalışıyor, `authenticated` rolü çağırabiliyor. Dönen alanlar:
   `has_store`, `slug`, `edit_token`, `reason`.
2. `has_store !== true` ise: **hata gösterme.** Bu hesabın henüz vitrini
   yok demektir; kurulum formunu göster. Bugünkü kod burada da yanlış —
   vitrini olmayan yeni hesaba kırmızı hata yazıyor.
3. `has_store === true` ise vitrini `.eq("slug", sonuc.slug)` ile oku.
   `slug` okunabilir sütunlar arasında.
4. Ürünler/kategoriler bugünkü gibi aynı sorguda gömülü kalabilir —
   onların izniyle ilgili bir sorun ölçülmedi.

`edit_token`'ı arayüzde **gösterme ve saklama**; yalnız çerez kurulumu
kullanıyor, o da `/api/owner-session/self` içinde sunucu tarafında.

Aynı deseni kullanan başka yer var mı diye tara: `.eq("user_id"` geçen her
istemci sorgusu aynı hatayı taşır.

## Doğrulama

```
cd public_web && npm run lint && npm test && npm run build
```

Ayrıca **sözleşme testi ekle**: istemci tarafı kodda `stores` sorgusunda
`.eq("user_id"` geçerse test kırılsın. Bu hata üçüncü kez çıkmasın.

Gerçek hesapla doğrulamayı ben yapacağım — sende çalışan hesap yok.

## Not: bu iş sırasında canlıya iki düzeltme uygulandı

İkisi de veritabanı tarafında, kod tarafını ilgilendirmiyor ama bilmen için:

1. `20260827155458` — `create_owner_session` search_path'ine `extensions`
   geri kondu.
2. `20260827155815` — aynı fonksiyonun 24 Ağustos'ta ezilen doğru gövdesi
   (`_create_owner_session_core` delegasyonu) geri getirildi.

Bu ikisi düzelmeden sahip çerezi hiç üretilemiyordu; blog/randevu/ürün
yönetiminin hiçbiri çalışamazdı.

## Çalışma kuralları

1. Klasörde tek ajan.
2. Dal: `feat/web-yazi-randevu-api` (üstünde çalışıyorsun, değiştirme).
3. Geçici betikleri commit etme.
4. PR'ı main'e indirme işi Claude'da.
