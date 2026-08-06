-- Mevcut store'lardaki kisa edit_token'lari UUID ile degistir
-- Bu migration bir kez calistirilmalidir
-- Supabase UUID fonksiyonu gen_random_uuid() ile yeni token uretir

UPDATE stores
SET edit_token = gen_random_uuid()::text
WHERE length(btrim(edit_token)) < 24
  AND edit_token IS NOT NULL
  AND edit_token <> '';

-- Eger tabloda hala slug gibi kisa token varsa onlari da duzelt
UPDATE stores
SET edit_token = gen_random_uuid()::text
WHERE edit_token ~ '^[a-z0-9-]+$'  -- slug formatinda
  AND length(edit_token) < 24;
