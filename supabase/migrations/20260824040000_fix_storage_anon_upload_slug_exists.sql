-- ============================================================================
-- V-10 Fix: Storage anon upload — verify slug exists in stores table
-- ============================================================================
-- SORUN: "Anon can upload scoped shelf images" politikası sadece regex
-- pattern kontrol ediyor. Kayıtlı olmayan/olmayan bir slug için de upload
-- yapılabilir (ör. `kayitsiz-store/gallery/1234567890.jpg`).
--
-- ÇÖZÜM: Anon INSERT policy'sine `EXISTS (SELECT 1 FROM stores WHERE slug = ...)`
-- kontrolü ekle. Sadece stores tablosunda VAR OLAN slug'lar için anon upload
-- izni verilir.
--
-- Not: Authenticated policy zaten ownership kontrolü yapıyor.
-- Bu fix yalnız anon policy'sini sıkılaştırır.
-- ============================================================================

BEGIN;

DROP POLICY IF EXISTS "Anon can upload scoped shelf images" ON "storage"."objects";

CREATE POLICY "Anon can upload scoped shelf images"
ON "storage"."objects"
FOR INSERT
TO "anon"
WITH CHECK (
  "bucket_id" = 'shelf-images'
  AND "name" ~ '^[a-z0-9]+(-[a-z0-9]+)*((/gallery)|(/products/[a-z0-9_-]+))?/[0-9]{10,}\.(jpg|png|webp)$'
  AND EXISTS (
    SELECT 1 FROM "public"."stores"
    WHERE "stores"."slug" = split_part("objects"."name", '/', 1)
  )
);

COMMIT;