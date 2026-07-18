-- Storage Bucket Güvenlik Düzeltmesi
-- Tarih: 2026-07-08
-- Sorun: Anonymous INSERT policy'si herkesin dosya yüklemesine izin veriyor

-- 1. Anonymous INSERT policy'sini kaldır
DROP POLICY IF EXISTS "Allow public shelf image uploads" ON storage.objects;

-- 2. Yalnızca authenticated kullanıcılar için INSERT policy ekle
-- Kullanıcı kendi mağazasına dosya yükleyebilir (slug ile eşleşme)
CREATE POLICY "Authenticated users can upload shelf images" 
ON storage.objects 
FOR INSERT 
TO authenticated 
WITH CHECK (
  bucket_id = 'shelf-images' 
  AND name ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
  AND (
    -- Kullanıcı kendi mağazasının klasörüne yükleyebilir
    -- Veya ilk kez yükleme yapıyorsa (klasör henüz yok)
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.slug = split_part(name, '/', 1)
      AND stores.user_id = auth.uid()
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.slug = split_part(name, '/', 1)
    )
  )
);

-- 3. SELECT policy'si ekle (herkes okuyabilir - public vitrin için)
CREATE POLICY "Public can read shelf images" 
ON storage.objects 
FOR SELECT 
TO anon, authenticated 
USING (bucket_id = 'shelf-images');

-- 4. DELETE policy'si ekle (kullanıcı kendi dosyalarını silebilir)
CREATE POLICY "Users can delete their own shelf images" 
ON storage.objects 
FOR DELETE 
TO authenticated 
USING (
  bucket_id = 'shelf-images' 
  AND EXISTS (
    SELECT 1 FROM public.stores 
    WHERE stores.slug = split_part(name, '/', 1)
    AND stores.user_id = auth.uid()
  )
);

-- 5. File size limitini 5MB'a düşür (image_picker zaten optimize ediyor)
UPDATE storage.buckets 
SET file_size_limit = 5242880 
WHERE id = 'shelf-images';
