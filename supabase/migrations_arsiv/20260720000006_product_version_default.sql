-- Aşama 5: Yeni mağazalarda product_storage_version varsayılanı 2
ALTER TABLE public.stores
ALTER COLUMN product_storage_version SET DEFAULT 2;
