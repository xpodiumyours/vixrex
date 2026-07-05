-- ============================================
-- VixRex → VixRex Legal Document Güncelleme
-- Bu script'i Supabase SQL Editor'a yapıştır
-- ============================================

-- 1. Mevcut durumu kontrol et
SELECT id, document_type, version, title, is_active
FROM legal_documents
ORDER BY document_type;

-- 2. Tüm belgelerdeki VitrinX → VixRex değişikliği
UPDATE legal_documents
SET
  title = REPLACE(REPLACE(title, 'VitrinX', 'VixRex'), 'vitrinx', 'vixrex'),
  subtitle = REPLACE(REPLACE(subtitle, 'VitrinX', 'VixRex'), 'vitrinx', 'vixrex'),
  sections = REPLACE(REPLACE(sections::text, 'VitrinX', 'VixRex'), 'vitrinx', 'vixrex')::jsonb,
  content_hash = ''  -- trigger otomatik güncelleyecek
WHERE title LIKE '%VitrinX%' OR title LIKE '%vitrinx%'
   OR subtitle LIKE '%VitrinX%' OR subtitle LIKE '%vitrinx%'
   OR sections::text LIKE '%VitrinX%' OR sections::text LIKE '%vitrinx%';

-- 3. E-posta adresi güncelleme
UPDATE legal_documents
SET
  sections = REPLACE(REPLACE(sections::text, 'privacy@vitrinx.app', 'privacy@vixrex.app'), 'vitrinx.app', 'vixrex.app')::jsonb,
  content_hash = ''
WHERE sections::text LIKE '%vitrinx%';

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
WHERE title LIKE '%VitrinX%' OR title LIKE '%vitrinx%'
   OR sections::text LIKE '%VitrinX%'
   OR sections::text LIKE '%vitrinx%';
-- Bu sorgu boş sonuç dönmeli (0 satır)
