-- Kiralik vitrin puanlarini cesitlendirir ve puan bandini acar (2026-09-25)
-- GOREV Adim 3 / KIRALIK-VITRIN-KALITE-PLANI Adim 5: 20260728 seed'inden
-- beri bazi vitrinlerde ayni puan/yorum tekrari vardi ve
-- show_storefront_rating varsayilan kapali oldugu icin puan hic
-- gorunmuyordu.
--
-- Kapsam: YALNIZ kiralik vitrinler (teknik isaret `stores.is_demo = true`) ve
-- sahibi olmayan (user_id IS NULL) 30 vitrin. Gercek musteri vitrinlerine HIC dokunulmaz.
--
-- Davranis:
--   - Zaten birbirinden farkli puana sahip 5 vitrin (kiralik-butik,
--     kiralik-kafe, kiralik-kuafor, kiralik-teknik, kiralik-gida)
--     KORUNUR; yalniz puan bandi acilir.
--   - Kalan 25 vitrine deterministik, birbirinden farkli ve gercekci
--     (puan 4.5-4.9, yorum 39-203) degerler yazilir. Rastgele yok;
--     taze ortamda ayni sonuc uretilir.
--   - show_storefront_rating 30 vitrinde acilir.
--
-- Guard: ayni (puan, yorum) ikilisini tasiyan iki kiralik vitrin kalirsa
-- veya 30 vitrinin biri eksikse migration duser.
--
-- TETIKLEYICI (2026-09-25): public.stores uzerinde BEFORE UPDATE calisan
-- protect_landing_demo_stores -> public.prevent_demo_store_mutation()
-- is_demo=true satirlarda her guncellemeyi DEMO_STORE_IMMUTABLE ile durdurur.
-- Depodaki yerlesik desen ayni: islem boyunca tetikleyici kapatilir
-- (bkz. supabase/migrations/20260922010000_kiralik_vitrinleri_30a_tamamla.sql:106).
-- Tek transaction: guard dusse bile tetikleyici acik kalir.

BEGIN;

ALTER TABLE public.stores DISABLE TRIGGER protect_landing_demo_stores;

UPDATE public.stores s SET
  rating_score = v.puan,
  review_count = v.yorum,
  show_storefront_rating = true
FROM (VALUES
  ('demo-aymira-giyim',      4.6::numeric,  74),
  ('demo-lezzet-duragi',     4.7::numeric,  52),
  ('demo-nova-kuafor',       4.8::numeric,  95),
  ('demo-teknofix',          4.5::numeric,  61),
  ('kiralik-giyim-erkek',    4.6::numeric,  89),
  ('kiralik-giyim-cocuk',    4.7::numeric, 143),
  ('kiralik-giyim-tesettur', 4.8::numeric, 110),
  ('kiralik-giyim-spor',     4.5::numeric,  67),
  ('kiralik-butik-gunluk',   4.6::numeric, 178),
  ('kiralik-butik-abiye',    4.9::numeric,  76),
  ('kiralik-butik-aksesuar', 4.7::numeric, 121),
  ('kiralik-butik-genc',     4.5::numeric,  44),
  ('kiralik-gida-sarkuteri', 4.6::numeric, 132),
  ('kiralik-gida-manav',     4.7::numeric,  58),
  ('kiralik-gida-kuruyemis', 4.8::numeric, 165),
  ('kiralik-gida-market',    4.5::numeric,  99),
  ('kiralik-kafe-pastane',   4.9::numeric, 203),
  ('kiralik-kafe-kahvalti',  4.6::numeric,  87),
  ('kiralik-kafe-hizli',     4.5::numeric,  39),
  ('kiralik-kuafor-berber',  4.8::numeric, 112),
  ('kiralik-kuafor-guzellik',4.7::numeric, 146),
  ('kiralik-kuafor-nail',    4.6::numeric,  71),
  ('kiralik-teknik-bilgisayar', 4.9::numeric, 158),
  ('kiralik-teknik-beyaz-esya', 4.6::numeric,  84),
  ('kiralik-teknik-tv',      4.7::numeric, 103)
) AS v(slug, puan, yorum)
WHERE s.slug = v.slug
  AND s.is_demo = true
  AND s.user_id IS NULL;

-- Puan bandi: 30 vitrinin tamaminda acilir (puani korunan 5 dahil).
UPDATE public.stores s
SET show_storefront_rating = true
WHERE s.slug = ANY(ARRAY[
  'kiralik-butik', 'kiralik-kafe', 'kiralik-kuafor', 'kiralik-teknik', 'kiralik-gida'
]::text[])
  AND s.is_demo = true
  AND s.user_id IS NULL;

ALTER TABLE public.stores ENABLE TRIGGER protect_landing_demo_stores;

DO $$
DECLARE
  toplam int;
  tekrar int;
  bant_kapali int;
BEGIN
  SELECT count(*) INTO toplam
  FROM public.stores
  WHERE is_demo = true AND user_id IS NULL
    AND slug = ANY(ARRAY[
      'demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix',
      'kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor',
      'kiralik-butik','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc',
      'kiralik-gida','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market',
      'kiralik-kafe','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli',
      'kiralik-kuafor','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail',
      'kiralik-teknik','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv'
    ]::text[]);

  IF toplam <> 30 THEN
    RAISE EXCEPTION 'Kiralik vitrin sayisi 30 degil: % — seed hatti duzeltilmeli', toplam;
  END IF;

  SELECT count(*) INTO tekrar
  FROM (
    SELECT rating_score, review_count
    FROM public.stores
    WHERE is_demo = true AND user_id IS NULL
      AND slug = ANY(ARRAY[
      'demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix',
      'kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor',
      'kiralik-butik','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc',
      'kiralik-gida','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market',
      'kiralik-kafe','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli',
      'kiralik-kuafor','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail',
      'kiralik-teknik','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv'
    ]::text[])
    GROUP BY rating_score, review_count
    HAVING count(*) > 1
  ) tekrarlar;

  IF tekrar > 0 THEN
    RAISE EXCEPTION 'Ayni puan/yorum ikilisini tasiyan % kiralik vitrin cifti var — cesitlendirme eksik', tekrar;
  END IF;

  SELECT count(*) INTO bant_kapali
  FROM public.stores
  WHERE is_demo = true AND user_id IS NULL
    AND slug = ANY(ARRAY[
      'demo-aymira-giyim','demo-lezzet-duragi','demo-nova-kuafor','demo-teknofix',
      'kiralik-giyim-erkek','kiralik-giyim-cocuk','kiralik-giyim-tesettur','kiralik-giyim-spor',
      'kiralik-butik','kiralik-butik-gunluk','kiralik-butik-abiye','kiralik-butik-aksesuar','kiralik-butik-genc',
      'kiralik-gida','kiralik-gida-sarkuteri','kiralik-gida-manav','kiralik-gida-kuruyemis','kiralik-gida-market',
      'kiralik-kafe','kiralik-kafe-pastane','kiralik-kafe-kahvalti','kiralik-kafe-hizli',
      'kiralik-kuafor','kiralik-kuafor-berber','kiralik-kuafor-guzellik','kiralik-kuafor-nail',
      'kiralik-teknik','kiralik-teknik-bilgisayar','kiralik-teknik-beyaz-esya','kiralik-teknik-tv'
    ]::text[])
    AND show_storefront_rating <> true;

  IF bant_kapali > 0 THEN
    RAISE EXCEPTION '% kiralik vitrinde puan bandi hala kapali — seed hatti duzeltilmeli', bant_kapali;
  END IF;
END $$;

COMMIT;
