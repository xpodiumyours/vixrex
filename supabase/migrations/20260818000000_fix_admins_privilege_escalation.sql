-- V-01 (attack-vectors.md, 2026-08-18): "admins" tablosunda kritik
-- ayrıcalık yükseltme açığı.
--
-- BULGU: "Allow insert admins" politikası `WITH CHECK (true)` idi ve rol
-- kısıtı da yoktu (yani PUBLIC — anon dahil tüm roller). Ayrıca tabloya
-- `GRANT ALL` hem `anon` hem `authenticated`'e verilmişti. Sonuç: herhangi
-- bir ziyaretçi (giriş bile yapmadan, herkese açık anon anahtarıyla)
-- `admins` tablosuna kendi user_id'sini — hatta başka birinin user_id'sini
-- — ekleyip platform admini olabiliyordu. "Admins can ..." adlı tüm
-- politikalar (appointments, audit_logs, platform_settings, stores,
-- profiles, store_articles, category_image_templates) bu tek satırın
-- varlığına güveniyor.
--
-- Not: `20260804120000_fix_admins_rls_recursion.sql` yalnız SELECT
-- özyinelemesini (infinite recursion) düzeltmişti; bu INSERT politikasına
-- hiç dokunmamıştı.
--
-- ÇÖZÜM: Admin atama istemciden HİÇBİR yoldan yapılamaz hale getirilir.
-- Yeni admin eklemek yalnız `service_role` ile (RLS'i tamamen bypass eden
-- tek rol, Supabase dashboard/SQL editor üzerinden Casper tarafından)
-- yapılabilir. Ayrıca "Admins can read" (USING true, PUBLIC dahil) tüm
-- admin user_id'lerini herkese açık okumaya bırakıyordu — hedefli hesap
-- ele geçirme için keşif bilgisi. Uygulama kodunda tabloyu çok satırlı
-- okuyan hiçbir yer yok (her yerde `EXISTS (... WHERE user_id = auth.uid())`
-- deseni kullanılıyor); kalan "Admins can view own admin row" politikası
-- (yalnız kendi satırını görme) bu ihtiyacı zaten karşılıyor.

DROP POLICY IF EXISTS "Allow insert admins" ON "public"."admins";
DROP POLICY IF EXISTS "Admins can read" ON "public"."admins";

-- RLS "son çare" değil "tek çare" olmasın diye GRANT seviyesinde de kapat:
-- anon'un admins üzerinde hiçbir yetkisi olmamalı; authenticated yalnız
-- kendi satırını okuyabilsin (kalan "Admins can view own admin row" bunu
-- zaten TO authenticated + user_id = auth.uid() ile sınırlıyor).
REVOKE ALL ON TABLE "public"."admins" FROM "anon";
REVOKE ALL ON TABLE "public"."admins" FROM "authenticated";
GRANT SELECT ON TABLE "public"."admins" TO "authenticated";
