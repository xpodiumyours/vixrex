-- Alter status check constraint to include 'retained' status
ALTER TABLE public.store_instagram_imports
  DROP CONSTRAINT IF EXISTS store_instagram_imports_status_check;

ALTER TABLE public.store_instagram_imports
  ADD CONSTRAINT store_instagram_imports_status_check
  CHECK (status IN ('imported', 'updated', 'failed', 'retained'));
