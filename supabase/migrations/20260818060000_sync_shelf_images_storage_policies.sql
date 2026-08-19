-- V-10/V-28 (attack-vectors.md, 2026-08-18) — senkron düzeltmesi, GÜVENLİK
-- AÇIĞI DEĞİL.
--
-- BULGU: storage.buckets/storage.objects tanımları aktif
-- `supabase/migrations/` zincirinde hiç yoktu — yalnız arşivde
-- (20260604000003, 20260717000008 vb.) tanımlıydı.
--
-- CANLI DURUM DOĞRULANDI (2026-08-18, `supabase db dump --linked` ile
-- gerçek production'a salt-okunur bağlanıp kontrol edildi — tahmin değil):
--   - shelf-images bucket: public=true, file_size_limit=5242880,
--     allowed_mime_types={image/jpeg,image/png,image/webp}
--   - storage.objects politikaları ZATEN sıkılaştırılmış hâlde:
--     "Anon can upload scoped shelf images" (yalnız {slug}/gallery veya
--     {slug}/products/{id}/ altına, zaman damgalı dosya adı),
--     "Authenticated users can upload shelf images" (aynı desen + sahiplik
--     kontrolü), "Users can delete their own shelf images" (yalnız sahibi).
--   - Eski/geniş "Allow public shelf image uploads" politikası ZATEN YOK.
--
-- SONUÇ: V-10/V-28'in tarif ettiği açık production'da ZATEN KAPALI —
-- audit statik dosyaları okumuş, arşivlenmiş ESKİ migration'ı canlı sanmış.
-- Bu migration bir güvenlik düzeltmesi DEĞİL; yalnızca aktif migration
-- zincirini gerçek/doğrulanmış canlı durumla senkronlar (idempotent —
-- production'da zaten no-op, yalnız yerel/taze ortamlar için gerekli).

INSERT INTO "storage"."buckets" ("id", "name", "public", "file_size_limit", "allowed_mime_types")
VALUES ('shelf-images', 'shelf-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT ("id") DO UPDATE SET
  "public" = true,
  "file_size_limit" = 5242880,
  "allowed_mime_types" = ARRAY['image/jpeg', 'image/png', 'image/webp'];

DROP POLICY IF EXISTS "Allow public shelf image uploads" ON "storage"."objects";
DROP POLICY IF EXISTS "Allow public shelf image reads" ON "storage"."objects";

DROP POLICY IF EXISTS "Anon can upload scoped shelf images" ON "storage"."objects";
CREATE POLICY "Anon can upload scoped shelf images"
ON "storage"."objects"
FOR INSERT
TO "anon"
WITH CHECK (
  "bucket_id" = 'shelf-images'
  AND "name" ~ '^[a-z0-9]+(-[a-z0-9]+)*((/gallery)|(/products/[a-z0-9_-]+))?/[0-9]{10,}\.(jpg|png|webp)$'
);

DROP POLICY IF EXISTS "Authenticated users can upload shelf images" ON "storage"."objects";
CREATE POLICY "Authenticated users can upload shelf images"
ON "storage"."objects"
FOR INSERT
TO "authenticated"
WITH CHECK (
  "bucket_id" = 'shelf-images'
  AND "name" ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
  AND (
    EXISTS (
      SELECT 1 FROM "public"."stores"
      WHERE "stores"."slug" = "split_part"("objects"."name", '/', 1)
        AND "stores"."user_id" = (SELECT "auth"."uid"())
    )
    OR NOT EXISTS (
      SELECT 1 FROM "public"."stores"
      WHERE "stores"."slug" = "split_part"("objects"."name", '/', 1)
    )
  )
);

DROP POLICY IF EXISTS "Users can delete their own shelf images" ON "storage"."objects";
CREATE POLICY "Users can delete their own shelf images"
ON "storage"."objects"
FOR DELETE
TO "authenticated"
USING (
  "bucket_id" = 'shelf-images'
  AND EXISTS (
    SELECT 1 FROM "public"."stores"
    WHERE "stores"."slug" = "split_part"("objects"."name", '/', 1)
      AND "stores"."user_id" = (SELECT "auth"."uid"())
  )
);
