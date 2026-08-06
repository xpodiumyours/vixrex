-- Düzeltme: Keşfet ekranında mağazaların anonim kullanıcılar tarafından okunabilmesi için SELECT RLS politikası oluşturuluyor.
DROP POLICY IF EXISTS "Allow public read stores" ON public.stores;
DROP POLICY IF EXISTS "Public stores are viewable by everyone" ON public.stores;

CREATE POLICY "Allow public read stores" ON public.stores
FOR SELECT TO anon, authenticated
USING (is_published = true);
