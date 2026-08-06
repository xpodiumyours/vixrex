-- Dilim B: ürün teslim bölgesi metni (Atmosfer şablon alanına karşılık).
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS fulfillment_region TEXT;

COMMENT ON COLUMN public.products.fulfillment_region IS
  'Ürünün teslim / hizmet bölgesi kısa metni (isteğe bağlı).';
