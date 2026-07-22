-- Mağaza arama ve public vitrin sorgularını hızlandırmak için bileşik indeks.
-- is_published = true filtresi en sık kullanılan koşul; partial index boyutu küçültür.
CREATE INDEX IF NOT EXISTS idx_stores_published_slug
ON public.stores (is_published, slug)
WHERE is_published = true;
