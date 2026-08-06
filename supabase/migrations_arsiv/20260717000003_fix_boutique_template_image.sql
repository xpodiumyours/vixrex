-- Replace unavailable boutique cover image without deleting any records.
UPDATE public.category_image_templates
SET
  image_url = 'https://images.unsplash.com/photo-1506152983158-b4a74a01c721?w=1200&q=80',
  title = 'Butik Koleksiyon Vitrini'
WHERE category_key = 'butik'
  AND image_type = 'cover'
  AND display_order = 8
  AND image_url = 'https://images.unsplash.com/photo-1560243563-062bff001d68?w=1200&q=80';
