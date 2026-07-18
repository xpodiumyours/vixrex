-- P0: shelf-images unrestricted upload kapatılır.
-- Ürün path'i ({slug}/products/{id}/{ts}.ext) scoped regex'e eklenir.
-- Geniş INSERT policy kaldırılmadan önce dar policy güncellenir.

DROP POLICY IF EXISTS "Anon can upload scoped shelf images" ON storage.objects;

CREATE POLICY "Anon can upload scoped shelf images"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'shelf-images'
  AND name ~ '^[a-z0-9]+(-[a-z0-9]+)*((/gallery)|(/products/[a-z0-9_-]+))?/[0-9]{10,}\.(jpg|png|webp)$'
);

DROP POLICY IF EXISTS "Allow public shelf image uploads" ON storage.objects;

DROP POLICY IF EXISTS "Authenticated users can upload shelf images" ON storage.objects;
CREATE POLICY "Authenticated users can upload shelf images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'shelf-images'
  AND name ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
  AND (
    EXISTS (
      SELECT 1 FROM public.stores
      WHERE stores.slug = split_part(name, '/', 1)
        AND stores.user_id = (select auth.uid())
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.stores
      WHERE stores.slug = split_part(name, '/', 1)
    )
  )
);

DROP POLICY IF EXISTS "Users can delete their own shelf images" ON storage.objects;
CREATE POLICY "Users can delete their own shelf images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'shelf-images'
  AND EXISTS (
    SELECT 1 FROM public.stores
    WHERE stores.slug = split_part(name, '/', 1)
      AND stores.user_id = (select auth.uid())
  )
);

UPDATE storage.buckets
SET file_size_limit = 5242880
WHERE id = 'shelf-images';
