-- OCR ve Premium özellikleri için tablolar
-- Tarih: 2026-07-07

-- ============================================
-- 1. Premium Özellikleri
-- ============================================

-- Profil tablosuna premium alanları ekle (eğer yoksa)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_premium') THEN
    ALTER TABLE profiles ADD COLUMN is_premium BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'premium_expires_at') THEN
    ALTER TABLE profiles ADD COLUMN premium_expires_at TIMESTAMP;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'premium_plan') THEN
    ALTER TABLE profiles ADD COLUMN premium_plan VARCHAR(20);
  END IF;
END $$;

-- ============================================
-- 2. OCR Kullanım Takibi
-- ============================================

CREATE TABLE IF NOT EXISTS ocr_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  usage_date DATE DEFAULT CURRENT_DATE,
  usage_count INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(user_id, usage_date)
);

-- RLS politikaları
ALTER TABLE ocr_usage ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi verilerini okuyabilir
CREATE POLICY "Users can read own OCR usage"
  ON ocr_usage FOR SELECT
  USING (auth.uid() = user_id);

-- Kullanıcılar kendi verilerini ekleyebilir/güncelleyebilir
CREATE POLICY "Users can insert own OCR usage"
  ON ocr_usage FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own OCR usage"
  ON ocr_usage FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================
-- 3. OCR Geçmişi
-- ============================================

CREATE TABLE IF NOT EXISTS ocr_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  image_url TEXT,
  products JSONB DEFAULT '[]'::jsonb,
  confidence DECIMAL(3,2),
  product_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now()
);

-- RLS politikaları
ALTER TABLE ocr_history ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi verilerini okuyabilir
CREATE POLICY "Users can read own OCR history"
  ON ocr_history FOR SELECT
  USING (auth.uid() = user_id);

-- Kullanıcılar kendi verilerini ekleyebilir
CREATE POLICY "Users can insert own OCR history"
  ON ocr_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 4. Ürün Veritabanı (OCR Doğrulama İçin)
-- ============================================

CREATE TABLE IF NOT EXISTS product_database (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  urun_adi TEXT NOT NULL,
  normalize_urun_adi TEXT,
  marka TEXT,
  marka_alias TEXT,
  kategori TEXT,
  alt_kategori TEXT,
  aciklama TEXT,
  anahtar_kelimeler TEXT,
  ocr_eslesme_kelimeleri TEXT,
  ambalaj_tipi TEXT,
  hacim_miktar TEXT,
  birim TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_product_database_kategori ON product_database(kategori);
CREATE INDEX IF NOT EXISTS idx_product_database_marka ON product_database(marka);
CREATE INDEX IF NOT EXISTS idx_product_database_normalize ON product_database(normalize_urun_adi);

-- Full-text search indeksi
CREATE INDEX IF NOT EXISTS idx_product_database_ocr_search ON product_database USING gin(to_tsvector('turkish', ocr_eslesme_kelimeleri));

-- RLS politikaları (herkese açık okuma)
ALTER TABLE product_database ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read product database"
  ON product_database FOR SELECT
  USING (true);

-- Sadece admin'ler ekleyebilir/güncelleyebilir
CREATE POLICY "Admins can manage product database"
  ON product_database FOR ALL
  USING (auth.uid() IN (SELECT user_id FROM admins));
