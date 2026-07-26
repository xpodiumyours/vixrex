CREATE TABLE public.feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_key TEXT UNIQUE NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  target_users TEXT NOT NULL DEFAULT 'all'
    CHECK (target_users IN ('all', 'premium', 'free')),
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read feature flags"
  ON public.feature_flags
  FOR SELECT
  TO anon, authenticated
  USING (true);

GRANT SELECT ON TABLE public.feature_flags TO anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.feature_flags
  FROM anon, authenticated;

INSERT INTO public.feature_flags
  (flag_key, is_enabled, target_users, description)
VALUES
  ('ocr_enabled', true, 'all', 'OCR scan feature'),
  ('bulk_upload_enabled', false, 'premium', 'Bulk product upload'),
  ('advanced_analytics', false, 'premium', 'Advanced analytics dashboard'),
  ('instagram_sync', true, 'all', 'Instagram product sync'),
  ('blog_enabled', true, 'all', 'Blog/magazine section'),
  ('booking_enabled', true, 'all', 'Appointment booking'),
  ('xml_upload', true, 'all', 'XML product upload');

CREATE OR REPLACE FUNCTION public.get_feature_flags()
RETURNS TABLE(flag_key TEXT, is_enabled BOOLEAN, target_users TEXT)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT ff.flag_key, ff.is_enabled, ff.target_users
  FROM public.feature_flags AS ff;
$$;

REVOKE ALL ON FUNCTION public.get_feature_flags() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_feature_flags()
  TO anon, authenticated;
