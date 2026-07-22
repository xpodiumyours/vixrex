-- Replace one mismatched food image and two unavailable auto images.
-- No rows are deleted; each update targets its original URL precisely.

UPDATE public.category_image_templates
SET
  image_url = 'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=1200&q=80',
  title = 'Gıda Reyonu'
WHERE category_key = 'gida'
  AND image_type = 'cover'
  AND display_order = 4
  AND image_url = 'https://images.unsplash.com/photo-1517433456452-f9633a875f6f?w=1200&q=80';

UPDATE public.category_image_templates
SET
  image_url = 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1200&q=80',
  title = 'Araç Servis Vitrini'
WHERE category_key = 'oto_arac'
  AND image_type = 'cover'
  AND display_order = 4
  AND image_url = 'https://images.unsplash.com/photo-1617886322168-72b886573c3c?w=1200&q=80';

UPDATE public.category_image_templates
SET
  image_url = 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&q=80',
  title = 'Araç Bakım Ürünü'
WHERE category_key = 'oto_arac'
  AND image_type = 'product'
  AND display_order = 5
  AND image_url = 'https://images.unsplash.com/photo-1562620658-c30089e02315?w=600&q=80';
