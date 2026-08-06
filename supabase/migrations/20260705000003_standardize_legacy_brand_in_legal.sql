-- ============================================
-- Legacy marka metinlerini Vixrex olarak standartlaştırma
-- Bu script'i Supabase SQL Editor'a yapıştır
-- ============================================

-- 1. Mevcut durumu kontrol et
SELECT id, document_type, version, title, is_active
FROM legal_documents
ORDER BY document_type;

-- 2. Tüm belgelerdeki eski marka yazımını güncelle
BEGIN;

UPDATE legal_documents
SET
  title = REPLACE(REPLACE(title, concat('Vitrin', 'X'), 'Vixrex'), concat('vitrin', 'x'), 'vixrex'),
  subtitle = REPLACE(REPLACE(subtitle, concat('Vitrin', 'X'), 'Vixrex'), concat('vitrin', 'x'), 'vixrex'),
  sections = REPLACE(REPLACE(sections::text, concat('Vitrin', 'X'), 'Vixrex'), concat('vitrin', 'x'), 'vixrex')::jsonb,
  content_hash = ''  -- trigger otomatik güncelleyecek
WHERE title LIKE '%' || concat('Vitrin', 'X') || '%' OR title LIKE '%' || concat('vitrin', 'x') || '%'
   OR subtitle LIKE '%' || concat('Vitrin', 'X') || '%' OR subtitle LIKE '%' || concat('vitrin', 'x') || '%'
   OR sections::text LIKE '%' || concat('Vitrin', 'X') || '%' OR sections::text LIKE '%' || concat('vitrin', 'x') || '%';

-- 3. E-posta adresi güncelleme
UPDATE legal_documents
SET
  sections = REPLACE(REPLACE(sections::text, concat('privacy@vitrin', 'x.app'), 'privacy@vixrex.app'), concat('vitrin', 'x.app'), 'vixrex.app')::jsonb,
  content_hash = ''
WHERE sections::text LIKE '%' || concat('vitrin', 'x') || '%';

-- 4. Tüm belgeleri aktif yap (eğer hala draft ise)
UPDATE legal_documents
SET is_active = true, effective_at = now()
WHERE is_active = false
  AND document_type IN ('privacy', 'terms', 'consent', 'dataDeletion');

COMMIT;

-- 5. Sonucu doğrula
SELECT
  document_type,
  version,
  title,
  is_active,
  effective_at,
  LEFT(sections::text, 200) as sections_preview
FROM legal_documents
WHERE is_active = true
ORDER BY document_type;

-- 6. Eski referans kaldı mı kontrol et
SELECT document_type, title
FROM legal_documents
WHERE title LIKE '%' || concat('Vitrin', 'X') || '%' OR title LIKE '%' || concat('vitrin', 'x') || '%'
   OR sections::text LIKE '%' || concat('Vitrin', 'X') || '%'
   OR sections::text LIKE '%' || concat('vitrin', 'x') || '%';
-- Bu sorgu boş sonuç dönmeli (0 satır)
