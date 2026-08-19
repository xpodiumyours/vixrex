-- V-06 (attack-vectors.md, 2026-08-18): "category_image_templates" tablosunda
-- herkese açık yazma.
--
-- BULGU: "category_templates_admin_all" politikasının adı "admin" ama
-- gerçek bir rol kontrolü yoktu — TO authenticated USING(true) WITH
-- CHECK(true). Sonuç: giriş yapmış HERHANGİ bir kullanıcı (esnaf hesabı
-- dahil, gerçek admin olması gerekmeden) platform genelindeki kategori
-- şablon görsellerini (kapak/logo/galeri/ürün) ekleyebilir, değiştirebilir,
-- silebilirdi — bu görseller `resolve_category_images` RPC'siyle TÜM
-- vitrinlere otomatik dolduruluyor (bkz. 00000000000000_..._bulut.sql:150-300).
--
-- ÇÖZÜM: Diğer "Admins can ..." politikalarıyla aynı desen — admins
-- tablosunda gerçek bir satırı olan kullanıcılarla sınırla (bkz. V-01,
-- 20260818000000_fix_admins_privilege_escalation.sql — o migration bu
-- deseni bozmayacak şekilde admins okuma/EXISTS kontrolünü sağlam bıraktı).
-- Herkese açık okuma (category_templates_select_public) DEĞİŞMEDİ — şablon
-- görselleri zaten yayın amaçlı, gizli değil.

DROP POLICY IF EXISTS "category_templates_admin_all" ON "public"."category_image_templates";

CREATE POLICY "category_templates_admin_all" ON "public"."category_image_templates"
  TO "authenticated"
  USING (EXISTS (SELECT 1 FROM "public"."admins" WHERE "admins"."user_id" = "auth"."uid"()))
  WITH CHECK (EXISTS (SELECT 1 FROM "public"."admins" WHERE "admins"."user_id" = "auth"."uid"()));

-- anon'un zaten yazma politikası yoktu ama GRANT ALL fazlaydı — daralt.
REVOKE ALL ON TABLE "public"."category_image_templates" FROM "anon";
GRANT SELECT ON TABLE "public"."category_image_templates" TO "anon";

REVOKE ALL ON TABLE "public"."category_image_templates" FROM "authenticated";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "public"."category_image_templates" TO "authenticated";
