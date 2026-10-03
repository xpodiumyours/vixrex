# Güvenlik Politikası

VixRex'in kaynak kodu herkese açıktır (public depo); lisans özel
mülkiyet şartlarındadır (bkz. `LICENSE`).

## Güvenlik açığı bildirimi

Bu depoda genel kullanıma açık bir güvenlik e-posta adresi
bulunmamaktadır. Bir güvenlik açığı (ör. veri sızıntısı, yetkisiz erişim,
kimlik doğrulama açığı) tespit ettiyseniz lütfen bunu **herkese açık bir
issue olarak paylaşmayın**; GitHub'ın özel güvenlik açığı bildirimi
(Private Vulnerability Reporting) özelliğini kullanın veya repo sahibi
(`@xpodiumyours`) ile özel kanaldan iletişime geçin.

## Kapsam

- `lib/` — Flutter panel
- `public_web/` — Next.js herkese açık site
- `supabase/` — veritabanı şeması, RLS politikaları, Edge Function'lar

## Desteklenen sürümler

Bu proje sürekli dağıtım (continuous deployment) ile çalışır; yalnızca
`main` dalındaki güncel canlı sürüm desteklenir. Eski sürümler için ayrı
bir güvenlik desteği yoktur.
