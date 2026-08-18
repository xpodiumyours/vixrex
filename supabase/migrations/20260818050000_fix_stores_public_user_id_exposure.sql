-- V-09 (attack-vectors.md, 2026-08-18): Yayınlı store PII (email/phone/
-- user_id) anon okuma.
--
-- BULGU: "Allow public read stores" politikası (USING is_published = true)
-- satır bazlı — hangi kolonların okunabileceğini GRANT'lar belirliyor.
-- email/phone/user_id kolonlarının hepsi anon + authenticated'e açıktı.
-- `/rest/v1/stores?select=email,phone,user_id&is_published=eq.true`
-- anon anahtarla (her Next.js sayfasının JS paketinde public/gömülü)
-- doğrudan çağrılarak TÜM yayınlı mağazaların bilgisi tek seferde
-- çekilebiliyor.
--
-- AYRIM:
--   email, phone → vitrin sayfasının KENDİSİ bunları KASITLI gösteriyor
--     (VitrinProfileView.tsx: displayEmail/displayPhone, mailto:/tel:
--     linkleri, vCard). Müşterinin işletmeyle iletişime geçebilmesi ürünün
--     amacı — bunları kapatmak temel bir özelliği kırar. Buradaki asıl risk
--     "görünür olması" değil, "toplu kazınabilir olması" (spam listesi) —
--     bu commit'in kapsamı DIŞINDA (ayrı bir anti-scraping/rate-limit işi).
--   user_id → hiçbir yerde vitrin arayüzünde GÖSTERİLMİYOR (grep: 0
--     eşleşme, public_web/src/app/v/[slug]). Sahibin iç kullanıcı kimliğini
--     dışarı sızdırmanın hiçbir ürünsel gerekçesi yok — bu commit YALNIZ
--     bunu kapatıyor.

REVOKE SELECT ("user_id") ON TABLE "public"."stores" FROM "anon";
REVOKE SELECT ("user_id") ON TABLE "public"."stores" FROM "authenticated";
