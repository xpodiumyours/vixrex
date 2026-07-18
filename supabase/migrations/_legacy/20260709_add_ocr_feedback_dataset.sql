-- Sıfır Maliyetli Eğitim Veri Seti (Feedback Loop)
-- Tarih: 2026-07-09

CREATE TABLE IF NOT EXISTS ocr_feedback_dataset (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  raw_ocr_text TEXT NOT NULL,
  corrected_products JSONB NOT NULL, -- Kullanıcının düzelttiği nihai [ad, fiyat] listesi
  scan_mode VARCHAR(20) DEFAULT 'receipt', -- 'receipt' veya 'shelf_label'
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);

-- RLS politikaları
ALTER TABLE ocr_feedback_dataset ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi verilerini okuyabilir
CREATE POLICY "Users can read own OCR feedback"
  ON ocr_feedback_dataset FOR SELECT
  USING (auth.uid() = user_id);

-- Kullanıcılar kendi verilerini ekleyebilir (Anonim veya üye kullanıcılar)
CREATE POLICY "Users can insert own OCR feedback"
  ON ocr_feedback_dataset FOR INSERT
  WITH CHECK (auth.uid() = user_id OR auth.uid() IS NULL);
