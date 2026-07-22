-- ============================================================
-- Migration: published_at + updated_at trigger
-- Tarih: 2026-06-22
-- ============================================================

-- 1. store_articles tablosuna published_at sütunu ekle
--    (eğer zaten varsa hata verme)
ALTER TABLE store_articles
  ADD COLUMN IF NOT EXISTS published_at timestamptz;

-- 2. Mevcut 'published' yazılar için published_at = created_at olarak dolduralım
UPDATE store_articles
SET published_at = created_at
WHERE status = 'published' AND published_at IS NULL;

-- 3. updated_at sütununu ekle (zaten yoksa)
ALTER TABLE store_articles
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- 4. updated_at otomatik güncelleme fonksiyonu
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 5. store_articles için updated_at trigger (zaten varsa yeniden yarat)
DROP TRIGGER IF EXISTS trg_store_articles_updated_at ON store_articles;
CREATE TRIGGER trg_store_articles_updated_at
  BEFORE UPDATE ON store_articles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 6. Moderatör 'published' statüsüne alırken published_at'i otomatik doldur
CREATE OR REPLACE FUNCTION set_published_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- draft veya review'dan published'a geçiliyorsa zaman damgasını yaz
  IF NEW.status = 'published' AND (OLD.status IS DISTINCT FROM 'published') THEN
    NEW.published_at = COALESCE(NEW.published_at, now());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_store_articles_published_at ON store_articles;
CREATE TRIGGER trg_store_articles_published_at
  BEFORE UPDATE ON store_articles
  FOR EACH ROW EXECUTE FUNCTION set_published_at();

-- 7. Yeni insert'lerde de published_at'i doldur (güvenilir yazar direkt yayınlıyorsa)
CREATE OR REPLACE FUNCTION set_published_at_on_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'published' AND NEW.published_at IS NULL THEN
    NEW.published_at = now();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_store_articles_published_at_insert ON store_articles;
CREATE TRIGGER trg_store_articles_published_at_insert
  BEFORE INSERT ON store_articles
  FOR EACH ROW EXECUTE FUNCTION set_published_at_on_insert();

-- 8. İndeks: sık kullanılan sıralama sorgusu için
CREATE INDEX IF NOT EXISTS idx_store_articles_published
  ON store_articles (store_slug, status, published_at DESC NULLS LAST);
