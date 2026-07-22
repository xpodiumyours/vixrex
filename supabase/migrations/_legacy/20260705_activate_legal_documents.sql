-- Yerel yasal belgeleri aktif yap
-- Bu migration onceki seed'deki draft belgeleri aktif hale getirir
-- Gercek sirket kimligi ve hukuki inceleme sonrasi yapilmaliydi

UPDATE legal_documents
SET
  is_active = true,
  effective_at = now()
WHERE is_active = false
  AND document_type IN ('privacy', 'terms', 'consent', 'dataDeletion')
  AND version LIKE '%-draft';

-- Aktif belgeleri dogrula
SELECT document_type, version, is_active, effective_at
FROM legal_documents
WHERE is_active = true
ORDER BY document_type;
