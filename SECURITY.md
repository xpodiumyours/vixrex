# Güvenlik Politikası

VixRex kapalı kaynaklı, özel mülkiyete tabi bir projedir (bkz. `LICENSE`).

## Güvenlik açığı bildirimi

Bu depoda genel kullanıma açık bir güvenlik e-posta adresi
bulunmamaktadır. Bir güvenlik açığı (ör. veri sızıntısı, yetkisiz erişim,
kimlik doğrulama açığı) tespit ettiyseniz lütfen bunu **herkese açık bir
issue olarak paylaşmayın**; yerine bu depoda özel/gizli bir
[GitHub issue](https://github.com/xpodiumyours/vixrex/issues/new) açıp
konuyu yalnızca başlıkta ("Güvenlik: ..." gibi) belirtin, ayrıntıyı issue
sahibiyle repo üzerinden özel olarak paylaşacağınızı yazın; repo sahibi
(`@xpodiumyours`) sizinle iletişime geçecektir.

## Kapsam

- `lib/` — Flutter panel
- `public_web/` — Next.js herkese açık site
- `supabase/` — veritabanı şeması, RLS politikaları, Edge Function'lar

## Desteklenen sürümler

Bu proje sürekli dağıtım (continuous deployment) ile çalışır; yalnızca
`main` dalındaki güncel canlı sürüm desteklenir. Eski sürümler için ayrı
bir güvenlik desteği yoktur.
