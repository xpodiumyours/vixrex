-- ============================================
-- VixRex → VixRex Legal Document Güncelleme
-- Bu script'i Supabase SQL Editor'a yapıştır
-- ============================================

-- 1. Mevcut durumu kontrol et
SELECT id, document_type, version, title, is_active
FROM legal_documents
ORDER BY document_type;

-- 2. Tüm belgelerdeki VixRex → VixRex değişikliği
UPDATE legal_documents
SET
  title = REPLACE(title, 'VixRex', 'VixRex'),
  subtitle = REPLACE(subtitle, 'VixRex', 'VixRex'),
  sections = REPLACE(sections::text, 'VixRex', 'VixRex')::jsonb,
  content_hash = ''  -- trigger otomatik güncelleyecek
WHERE title LIKE '%VixRex%'
   OR subtitle LIKE '%VixRex%'
   OR sections::text LIKE '%VixRex%';

-- 3. E-posta adresi güncelleme
UPDATE legal_documents
SET
  sections = REPLACE(sections::text, 'privacy@VixRex.app', 'privacy@vixrex.app')::jsonb,
  sections = REPLACE(sections::text, 'VixRex.app', 'vixrex.app')::jsonb,
  content_hash = ''
WHERE sections::text LIKE '%VixRex%';

-- 4. Tüm belgeleri aktif yap (eğer hala draft ise)
UPDATE legal_documents
SET is_active = true, effective_at = now()
WHERE is_active = false
  AND document_type IN ('privacy', 'terms', 'consent', 'dataDeletion');

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
WHERE title LIKE '%VixRex%'
   OR sections::text LIKE '%VixRex%'
   OR sections::text LIKE '%VixRex%';
-- Bu sorgu boş sonuç dönmeli (0 satır)
