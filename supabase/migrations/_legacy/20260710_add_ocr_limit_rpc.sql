-- Faz 1.4: OCR limit kontrolünü sunucu tarafına taşı
-- Atomik RPC: limit kontrolü + sayacı artırma tek transaction'da

CREATE OR REPLACE FUNCTION public.check_and_increment_ocr_usage(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_current_count INT;
  v_daily_limit INT := 3;
  v_is_premium BOOLEAN := FALSE;
  v_result JSONB;
BEGIN
  -- Premium kontrolü
  SELECT COALESCE(is_premium, FALSE) INTO v_is_premium
  FROM public.stores
  WHERE user_id = p_user_id
  LIMIT 1;

  -- Premium ise limitsiz
  IF v_is_premium THEN
    -- Sayacı yine de artır (analytics için)
    INSERT INTO public.ocr_usage (user_id, usage_date, usage_count)
    VALUES (p_user_id, v_today, 1)
    ON CONFLICT (user_id, usage_date)
    DO UPDATE SET usage_count = public.ocr_usage.usage_count + 1;

    RETURN jsonb_build_object(
      'allowed', true,
      'remaining', -1,
      'is_premium', true
    );
  END IF;

  -- Mevcut kullanımı bul
  SELECT usage_count INTO v_current_count
  FROM public.ocr_usage
  WHERE user_id = p_user_id AND usage_date = v_today;

  -- İlk kullanım ise sıfırdan başla
  IF v_current_count IS NULL THEN
    v_current_count := 0;
  END IF;

  -- Limit kontrolü
  IF v_current_count >= v_daily_limit THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'remaining', 0,
      'is_premium', false,
      'message', 'Günlük OCR limitiniz doldu. Premium ile sınırsız kullanın.'
    );
  END IF;

  -- Atomik olarak sayacı artır (UPSERT)
  INSERT INTO public.ocr_usage (user_id, usage_date, usage_count)
  VALUES (p_user_id, v_today, 1)
  ON CONFLICT (user_id, usage_date)
  DO UPDATE SET usage_count = public.ocr_usage.usage_count + 1;

  RETURN jsonb_build_object(
    'allowed', true,
    'remaining', v_daily_limit - v_current_count - 1,
    'is_premium', false
  );
END;
$$;

-- Yetkilendirme
REVOKE EXECUTE ON FUNCTION public.check_and_increment_ocr_usage(UUID) FROM public;
REVOKE EXECUTE ON FUNCTION public.check_and_increment_ocr_usage(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.check_and_increment_ocr_usage(UUID) TO authenticated;

-- ocr_usage tablosuna unique constraint ekle (eğer yoksa)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ocr_usage_user_date_unique'
  ) THEN
    ALTER TABLE public.ocr_usage
    ADD CONSTRAINT ocr_usage_user_date_unique UNIQUE (user_id, usage_date);
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
