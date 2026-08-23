-- 20260822162256 ile eklenen iki OCR tablosu, 20260821200730'daki taramadan
-- SONRA oluştuğu için aynı açıkla doğdu: anon ve authenticated rollerine
-- tablo seviyesinde TRUNCATE/MAINTAIN/REFERENCES/TRIGGER + gereksiz
-- UPDATE/DELETE verilmişti. TRUNCATE RLS'ten muaftır — bu hâliyle herkese
-- açık anon anahtarla product_database boşaltılabilirdi.
--
-- 20260821200730'un sonundaki uyarının uygulanması: yeni tabloda yetkiler
-- açıkça daraltılır.

-- Önce her iki tabloda da her şeyi geri al, sonra yalnız gerekeni ver.
REVOKE ALL ON TABLE public.product_database FROM anon, authenticated;
REVOKE ALL ON TABLE public.ocr_feedback_dataset FROM anon, authenticated;

-- product_database: herkese açık sözlük. Yazma yalnız admin'e ait ve
-- RLS ile sınırlanır; RLS'in devreye girebilmesi için authenticated'ın
-- yazma yetkisi tablo seviyesinde açık olmalı.
GRANT SELECT ON TABLE public.product_database TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.product_database TO authenticated;

-- ocr_feedback_dataset: append-only. Esnağın auth hesabı olmadığı için
-- anon INSERT şart, ama anon hiçbir şey okuyamaz (SELECT verilmedi) ve
-- kimse satır güncelleyip silemez.
GRANT INSERT ON TABLE public.ocr_feedback_dataset TO anon;
GRANT SELECT, INSERT ON TABLE public.ocr_feedback_dataset TO authenticated;

NOTIFY pgrst, 'reload schema';
