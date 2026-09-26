BEGIN;

ALTER TABLE public.stores DISABLE TRIGGER protect_landing_demo_stores;

WITH g(eski, yeni) AS (
  VALUES
    ('demo-aymira-giyim',  'kiralik-aymira-giyim'),
    ('demo-lezzet-duragi', 'kiralik-lezzet-duragi'),
    ('demo-nova-kuafor',   'kiralik-nova-kuafor'),
    ('demo-teknofix',      'kiralik-teknofix')
),
vitrin AS (
  UPDATE public.stores s
  SET slug = g.yeni
  FROM g
  WHERE s.slug = g.eski
    AND s.is_demo = true
    AND s.user_id IS NULL
  RETURNING s.slug
),
makale AS (
  UPDATE public.store_articles a
  SET store_slug = g.yeni
  FROM g
  WHERE a.store_slug = g.eski
  RETURNING a.store_slug
),
randevu AS (
  UPDATE public.appointments a
  SET store_slug = g.yeni
  FROM g
  WHERE a.store_slug = g.eski
  RETURNING a.store_slug
),
randevu_bloku AS (
  UPDATE public.booking_blocks b
  SET store_slug = g.yeni
  FROM g
  WHERE b.store_slug = g.eski
  RETURNING b.store_slug
),
randevu_ayari AS (
  UPDATE public.booking_settings c
  SET store_slug = g.yeni
  FROM g
  WHERE c.store_slug = g.eski
  RETURNING c.store_slug
),
instagram_baglantisi AS (
  UPDATE public.store_instagram_connections d
  SET store_slug = g.yeni
  FROM g
  WHERE d.store_slug = g.eski
  RETURNING d.store_slug
),
instagram_aktarimi AS (
  UPDATE public.store_instagram_imports e
  SET store_slug = g.yeni
  FROM g
  WHERE e.store_slug = g.eski
  RETURNING e.store_slug
)
SELECT
  (SELECT count(*) FROM vitrin) AS tasinan_vitrin,
  (SELECT count(*) FROM makale) AS tasinan_makale;

ALTER TABLE public.stores ENABLE TRIGGER protect_landing_demo_stores;

DO $$
DECLARE
  eski_kalan int;
  yeni_vitrin int;
  bagli_kalan int;
BEGIN
  SELECT count(*) INTO eski_kalan
  FROM public.stores
  WHERE slug = ANY(ARRAY[
    'demo-aymira-giyim', 'demo-lezzet-duragi', 'demo-nova-kuafor', 'demo-teknofix'
  ]::text[]);

  SELECT count(*) INTO yeni_vitrin
  FROM public.stores
  WHERE slug = ANY(ARRAY[
    'kiralik-aymira-giyim', 'kiralik-lezzet-duragi', 'kiralik-nova-kuafor', 'kiralik-teknofix'
  ]::text[])
    AND is_demo = true
    AND user_id IS NULL;

  SELECT count(*) INTO bagli_kalan
  FROM (
    SELECT store_slug FROM public.store_articles
    UNION ALL SELECT store_slug FROM public.appointments
    UNION ALL SELECT store_slug FROM public.booking_blocks
    UNION ALL SELECT store_slug FROM public.booking_settings
    UNION ALL SELECT store_slug FROM public.store_instagram_connections
    UNION ALL SELECT store_slug FROM public.store_instagram_imports
  ) bagli
  WHERE store_slug = ANY(ARRAY[
    'demo-aymira-giyim', 'demo-lezzet-duragi', 'demo-nova-kuafor', 'demo-teknofix'
  ]::text[]);

  IF eski_kalan > 0 THEN
    RAISE EXCEPTION 'SLUG_DEGISIMI_DUSTU: eski slug ile % vitrin kaldi', eski_kalan;
  END IF;

  IF yeni_vitrin <> 4 THEN
    RAISE EXCEPTION 'SLUG_DEGISIMI_DUSTU: yeni slug ile % vitrin bulundu', yeni_vitrin;
  END IF;

  IF bagli_kalan > 0 THEN
    RAISE EXCEPTION 'SLUG_DEGISIMI_DUSTU: % bagli kayit hala eski slug tasiyor', bagli_kalan;
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';

COMMIT;
