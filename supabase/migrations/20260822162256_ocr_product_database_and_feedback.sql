-- OCR ürün kataloğu altyapısı.
-- Arşivdeki 20260707 / 20260709 dosyalarından SADECE hâlâ geçerli olan iki
-- tablo alındı. ocr_usage / ocr_history / profiles premium sütunları
-- BİLEREK dışarıda bırakıldı: premium modeli artık vitrin bazlı
-- (stores.premium_expires_at + edit_token), esnafın auth hesabı yok —
-- o dosyalardaki auth.uid() = user_id politikaları hiçbir zaman eşleşmezdi.

-- ============================================
-- 1. Ürün veritabanı (OCR eşleştirme sözlüğü)
-- ============================================

CREATE TABLE IF NOT EXISTS public.product_database (
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
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.product_database IS
  'OCR''ın okuduğu ham metni gerçek ürün adına eşlemek için sözlük. Herkese açık okuma, yalnız admin yazar.';

CREATE INDEX IF NOT EXISTS idx_product_database_kategori
  ON public.product_database(kategori);
CREATE INDEX IF NOT EXISTS idx_product_database_marka
  ON public.product_database(marka);
CREATE INDEX IF NOT EXISTS idx_product_database_normalize
  ON public.product_database(normalize_urun_adi);
CREATE INDEX IF NOT EXISTS idx_product_database_ocr_search
  ON public.product_database
  USING gin(to_tsvector('turkish', coalesce(ocr_eslesme_kelimeleri, '')));

ALTER TABLE public.product_database ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read product database" ON public.product_database;
CREATE POLICY "Anyone can read product database"
  ON public.product_database FOR SELECT
  USING (true);

-- FOR ALL politikasında WITH CHECK açıkça yazıldı: eksik bırakılırsa
-- yazma tarafının hangi ifadeyle korunduğu okuyana belirsiz kalıyor.
DROP POLICY IF EXISTS "Admins can manage product database" ON public.product_database;
CREATE POLICY "Admins can manage product database"
  ON public.product_database FOR ALL
  USING (auth.uid() IN (SELECT user_id FROM public.admins))
  WITH CHECK (auth.uid() IN (SELECT user_id FROM public.admins));

-- ============================================
-- 2. OCR düzeltme veri seti (öğrenme kaydı)
-- ============================================
-- Sütunlar ocr_feedback_service.dart'ın gerçekte gönderdiği alanlara göre:
-- arşiv dosyasında parsed_products / image_hash / timestamp yoktu, tablo
-- kurulsa bile her insert hata verirdi.

CREATE TABLE IF NOT EXISTS public.ocr_feedback_dataset (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  raw_ocr_text TEXT NOT NULL,
  parsed_products JSONB NOT NULL DEFAULT '[]'::jsonb,
  corrected_products JSONB NOT NULL DEFAULT '[]'::jsonb,
  scan_mode VARCHAR(20) DEFAULT 'receipt',
  image_hash TEXT,
  "timestamp" TIMESTAMPTZ,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT ocr_feedback_raw_text_len CHECK (char_length(raw_ocr_text) <= 20000),
  CONSTRAINT ocr_feedback_image_hash_len CHECK (image_hash IS NULL OR char_length(image_hash) <= 200),
  CONSTRAINT ocr_feedback_scan_mode CHECK (scan_mode IN ('receipt', 'shelf_label', 'invoice'))
);

COMMENT ON TABLE public.ocr_feedback_dataset IS
  'Kullanıcının OCR çıktısında yaptığı düzeltmeler. Fatura içeriği hassas veri sayılır: okuma yalnız kendi satırına, anonim satırlara yalnız service_role erişir.';

CREATE INDEX IF NOT EXISTS idx_ocr_feedback_created_at
  ON public.ocr_feedback_dataset(created_at DESC);

ALTER TABLE public.ocr_feedback_dataset ENABLE ROW LEVEL SECURITY;

-- Okuma: yalnız kendi satırı. user_id NULL olan anonim satırlar hiçbir
-- istemciye görünmez (auth.uid() = NULL karşılaştırması NULL döner).
DROP POLICY IF EXISTS "Users can read own OCR feedback" ON public.ocr_feedback_dataset;
CREATE POLICY "Users can read own OCR feedback"
  ON public.ocr_feedback_dataset FOR SELECT
  USING (auth.uid() = user_id);

-- Yazma: esnağın auth hesabı olmadığı için anonim insert şart. Ancak
-- arşivdeki "auth.uid() IS NULL" koşulu, giriş yapmamış birinin
-- BAŞKASININ user_id'sini yazmasına izin veriyordu. Bu sürüm buna izin
-- vermez: ya satır anonim (user_id NULL) ya da kendi kimliğiyle.
DROP POLICY IF EXISTS "Users can insert own OCR feedback" ON public.ocr_feedback_dataset;
CREATE POLICY "Users can insert own OCR feedback"
  ON public.ocr_feedback_dataset FOR INSERT
  WITH CHECK (user_id IS NULL OR auth.uid() = user_id);

-- UPDATE / DELETE politikası bilerek yok: veri seti append-only,
-- düzeltme yalnız service_role ile yapılır.
