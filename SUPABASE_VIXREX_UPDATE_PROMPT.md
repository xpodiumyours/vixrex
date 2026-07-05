# Supabase Legal Document Güncelleme Promptu

## Bu promptu Supabase SQL Editor'a yapıştırın:

```sql
-- VixRex → VixRex Legal Document Güncelleme
-- 1. Mevcut durumu kontrol
SELECT document_type, title, is_active FROM legal_documents ORDER BY document_type;

-- 2. Marka adını güncelle
UPDATE legal_documents
SET
  title = REPLACE(title, 'VitrinX', 'VixRex'),
  subtitle = REPLACE(subtitle, 'VitrinX', 'VixRex'),
  sections = REPLACE(sections::text, 'VitrinX', 'VixRex')::jsonb
WHERE title LIKE '%VitrinX%' OR subtitle LIKE '%VitrinX%' OR sections::text LIKE '%VitrinX%';

-- 3. E-posta ve URL güncelle
UPDATE legal_documents
SET
  sections = REPLACE(REPLACE(sections::text, 'privacy@vitrinx.app', 'privacy@vixrex.app'), 'vitrinx.app', 'vixrex.app')::jsonb
WHERE sections::text LIKE '%vitrinx%';

-- 4. Belgeleri aktif yap
UPDATE legal_documents
SET is_active = true, effective_at = now()
WHERE is_active = false
  AND document_type IN ('privacy', 'terms', 'consent', 'dataDeletion');

-- 5. Sonucu doğrula
SELECT document_type, title, is_active, LEFT(sections::text, 150) as preview
FROM legal_documents WHERE is_active = true ORDER BY document_type;

-- 6. Eski referans kontrolü (bu boş dönmeli)
SELECT document_type, title FROM legal_documents
WHERE title LIKE '%VitrinX%' OR sections::text LIKE '%vitrinx%';
```

## Beklenen Sonuç:
- 4 satır dönmeli (privacy, terms, consent, dataDeletion)
- Tüm başlıklarda "VixRex" yazmalı
- Hiçbir yerde "VixRex" veya "vixrex" kalmamalı
- Tüm belgeler `is_active = true` olmalı
