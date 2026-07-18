-- P1 canlı güvenlik artıkları: listing, makale RLS, storage delete hatası,
-- duplicate stores SELECT, inert grants, mutable search_path.

-- 1) Public bucket listing kapat (nesne URL'leri public bucket ile çalışmaya devam eder)
DROP POLICY IF EXISTS "Allow public shelf image reads" ON storage.objects;
DROP POLICY IF EXISTS "Public can read shelf images" ON storage.objects;
DROP POLICY IF EXISTS "category_templates_storage_public" ON storage.objects;

-- 2) DELETE policy: objects.name (storage path) kullanılmalı; stores.name yanlıştı
DROP POLICY IF EXISTS "Users can delete their own shelf images" ON storage.objects;
CREATE POLICY "Users can delete their own shelf images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'shelf-images'
  AND EXISTS (
    SELECT 1 FROM public.stores
    WHERE stores.slug = split_part(objects.name, '/', 1)
      AND stores.user_id = (select auth.uid())
  )
);

-- Authenticated INSERT path da objects.name ile netleştirilir
DROP POLICY IF EXISTS "Authenticated users can upload shelf images" ON storage.objects;
CREATE POLICY "Authenticated users can upload shelf images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'shelf-images'
  AND objects.name ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
  AND (
    EXISTS (
      SELECT 1 FROM public.stores
      WHERE stores.slug = split_part(objects.name, '/', 1)
        AND stores.user_id = (select auth.uid())
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.stores
      WHERE stores.slug = split_part(objects.name, '/', 1)
    )
  )
);

-- 3) store_articles: always-true yazma politikalarını kaldır, sahipliğe bağla
DROP POLICY IF EXISTS "Anyone can insert articles" ON public.store_articles;
DROP POLICY IF EXISTS "Store owner can update own articles" ON public.store_articles;
DROP POLICY IF EXISTS "Public can read published articles" ON public.store_articles;
DROP POLICY IF EXISTS "Anyone can read published articles" ON public.store_articles;
DROP POLICY IF EXISTS "Owners can read all their own articles" ON public.store_articles;
DROP POLICY IF EXISTS "Owners can insert their own articles" ON public.store_articles;
DROP POLICY IF EXISTS "Owners can update their own articles" ON public.store_articles;
DROP POLICY IF EXISTS "Owners can delete their own articles" ON public.store_articles;

CREATE POLICY "Anyone can read published articles"
ON public.store_articles
FOR SELECT
TO anon, authenticated
USING (status = 'published');

CREATE POLICY "Owners can read all their own articles"
ON public.store_articles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = store_articles.store_slug
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can insert their own articles"
ON public.store_articles
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = store_articles.store_slug
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can update their own articles"
ON public.store_articles
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = store_articles.store_slug
      AND s.user_id = (select auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = store_articles.store_slug
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can delete their own articles"
ON public.store_articles
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = store_articles.store_slug
      AND s.user_id = (select auth.uid())
  )
);

-- 4) Duplicate stores SELECT (aynı işlev)
DROP POLICY IF EXISTS "Published stores are publicly readable" ON public.stores;

-- Owner UPDATE/DELETE: (select auth.uid()) sarmalaması
DROP POLICY IF EXISTS "Users can update their own stores" ON public.stores;
DROP POLICY IF EXISTS "Owners can update their stores" ON public.stores;
CREATE POLICY "Owners can update their stores"
ON public.stores
FOR UPDATE
TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own stores" ON public.stores;
CREATE POLICY "Owners can delete their stores"
ON public.stores
FOR DELETE
TO authenticated
USING ((select auth.uid()) = user_id);

-- 5) İnert anon grants (RLS zaten engelliyor; least-privilege)
REVOKE SELECT ON TABLE public.appointments FROM anon;
REVOKE ALL ON TABLE public.assistant_rate_limits FROM anon, authenticated;

-- 6) Mutable search_path kapat
ALTER FUNCTION public.link_store_to_user(text) SET search_path = '';
ALTER FUNCTION public.set_updated_at() SET search_path = '';
ALTER FUNCTION public.set_published_at() SET search_path = '';
ALTER FUNCTION public.set_published_at_on_insert() SET search_path = '';

NOTIFY pgrst, 'reload schema';
