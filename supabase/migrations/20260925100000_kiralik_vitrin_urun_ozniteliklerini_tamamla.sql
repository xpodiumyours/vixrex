-- Kiralik vitrin urunlerinin kategoriye ozel oznitelik/hizmet alanlarini tamamlar (2026-09-25)
-- GOREV Adim 3 / KIRALIK-VITRIN-KALITE-PLANI Adim 2: 30 kiralik vitrindeki
-- urunlerde metadata.attributes ve metadata.service bos; bu yuzden kartta
-- ozellik satiri hic gorunmuyor. Kaynak yalniz tek dosya:
--   shared/product_attribute_schema.json (v4, kategori sablonlari)
-- Ikinci bir alan listesi YAZILMADI; asagidaki degerler sablon tanimlarinin
-- (key, valueType, requirement, optionLabels) gerceklesmis halidir.
--
-- Kapsam: YALNIZ kiralik vitrinlerin urunleri. Teknik isaret `stores.is_demo = true`;
-- kullaniciya gorunen ad "kiralik vitrin (kiralanabilir)". Gercek musteri urunlerine
-- (is_demo = false) HIC dokunulmaz (foto migration'iyla ayni kapsam deseni).
--
-- Idempotent: yalniz bos alanlari doldurur; dolu bir alani asla ezmez.
-- Tekrar kosum guvenli; guard blogu kalan eksik urun 0 olmadan gecmez.
--
-- Kart okuma zinciri (public_web/src/lib):
--   buildProductCardFacts -> metadataAttributeFacts
--   -> definition.optionLabels[key] ile etiketler; yani deger olarak
--   OPTION ANAHTARI yazilir ("dar", "kadin"), etiketi kod uretir ("Dar kesim").
--
-- 2026-09-25 canli olcumu (Kesfet'te kiralik duran 30 vitrin): 182 aktif demo
-- urunun 164'unde ozellik dolu; kalan 18 urun uc vitrinde (demo-aymira-giyim,
-- demo-lezzet-duragi, demo-nova-kuafor) ve o vitrinlerin urun kategorileri
-- product_template_key='generic' oldugu icin asagidaki UPDATE'lerin hicbiri
-- o 18 urunu tutmuyordu. Bu yuzden once kategori sablonu duzeltilir.
-- Esleme ikinci bir liste degil: shared/business_categories.json icindeki
-- productTemplateKey alaninin SQL karsiligidir; sozlesme testi
-- (public_web/tests/kiralik-vitrin-icerik-sozlesmesi.test.ts) ayrismayi reddeder.

BEGIN;

-- ============================================================
-- Bolum 0: kategori sablonu (tek kaynak: shared/business_categories.json)
-- ============================================================
-- Kiralik vitrinlerin kendi actigi kategoriler ("Ust Giyim", "Ana Yemekler" gibi)
-- generic sablonla kalmis. Sablon yazilmadan ne kartta ozellik satiri cikar
-- (public_web/src/lib/productCardPresentation.ts:102) ne de vitrin
-- kiralandiginda esnafin urun formu kategori alanlarini getirir
-- (public_web/src/app/api/products/route.ts:176).
-- Yalniz bos/generic kategoriler doldurulur; dolu sablon ezilmez.

UPDATE public.product_categories pc
SET product_template_key = e.sablon
FROM public.stores s
JOIN (VALUES
  ('Giyim', 'fashion'),
  ('Butik', 'fashion'),
  ('Gıda', 'food'),
  ('Kafe / Lokanta', 'cafe_restaurant'),
  ('Kuaför', 'service'),
  ('Teknik Servis', 'technical_service')
) AS e(kategori, sablon) ON e.kategori = btrim(s.kategori)
WHERE pc.store_id = s.id
  AND s.is_demo = true
  AND (
    pc.product_template_key IS NULL
    OR btrim(pc.product_template_key) = ''
    OR pc.product_template_key = 'generic'
  );

-- ============================================================
-- Bolum 1: templateKey ve itemKind temeli
-- ============================================================

-- templateKey bos olan kiralik vitrin urunlerine kategorisinin sablonunu yaz.
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{templateKey}',
  to_jsonb(pc.product_template_key),
  true
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT (p.metadata ? 'templateKey'))
  AND coalesce(pc.product_template_key, 'generic') <> 'generic';

-- itemKind'i yaz (hizmet sablonlari icin 'service').
-- Kafes: (a) itemKind bos -> yaz; (b) itemKind fiziksel ama sablon hizmet ->
-- duzelt (yiyecek-icecek urunleri 'physical' kaldi; sablonuna gore hizmet).
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{itemKind}',
  '"service"'::jsonb,
  true
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') IN ('service', 'technical_service')
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT (p.metadata ? 'itemKind'));

-- ============================================================
-- Bolum 2: marka (core.brand) + metadata.identifiers.sku
-- ============================================================
-- Sablonda marka kartta gorunuyor ve autoFill=storeName (schema v4);
-- bos marka urunlerde magaza adiyla dolar.

UPDATE public.products p
SET brand = s.name
FROM public.stores s
WHERE s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND (p.brand IS NULL OR btrim(p.brand) = '');

-- ============================================================
-- Bolum 3: fiziksel sablonlarin zorunlu ozellikleri
-- ============================================================
-- Kural: yalniz metadata.attributes BOŞ dizi/NULL iken doldur.
-- Deger olarak sablon OPTION anahtarlari yazilir; etiketi kod uretir.
-- attributes dizi ogeleri normalizeProductMetadata sozlesmesiyle {key,value}
-- seklindedir; label yazilmaz (kod definition.label'dan alir).

-- --- fashion: renk, beden, cinsiyet, kalip, materyal
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{attributes}',
  jsonb_build_array(
    jsonb_build_object('key', 'color', 'value', 'Siyah'),
    jsonb_build_object('key', 'size', 'value', 'M'),
    jsonb_build_object('key', 'gender', 'value', 'kadin'),
    jsonb_build_object('key', 'fit', 'value', 'normal'),
    jsonb_build_object('key', 'material', 'value', 'Pamuk karışımı')
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'fashion'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
    ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
  ));

-- --- electronics: model + garanti
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{attributes}',
  jsonb_build_array(
    jsonb_build_object('key', 'model', 'value', '2026 Serisi'),
    jsonb_build_object('key', 'warranty', 'value', '2 yıl distribütör garantisi')
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'electronics'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
    ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
  ));

-- --- food: net miktar, birim fiyat, alerjen, mensei, saklama
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{attributes}',
  jsonb_build_array(
    jsonb_build_object('key', 'netQuantity', 'value', '500 g'),
    jsonb_build_object('key', 'unitPrice', 'value', '100 g / 25 TL'),
    jsonb_build_object('key', 'allergens', 'value', jsonb_build_array('gluten', 'süt')),
    jsonb_build_object('key', 'origin', 'value', 'Türkiye'),
    jsonb_build_object('key', 'storageInstructions', 'value', 'Serin ve kuru yerde saklayın')
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'food'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
    ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
  ));

-- --- beauty: net miktar + kullanim alani
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{attributes}',
  jsonb_build_array(
    jsonb_build_object('key', 'netQuantity', 'value', '300 ml'),
    jsonb_build_object('key', 'usageType', 'value', 'Günlük bakım')
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'beauty'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
    ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
  ));

-- --- cafe_restaurant: porsiyon, alerjen, ana bilesen, alkol-domuz beyani,
--     hazirlama suresi (kart yuzeyinde gorunen dort alanin tamami)
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{attributes}',
  jsonb_build_array(
    jsonb_build_object('key', 'portion', 'value', '1 porsiyon'),
    jsonb_build_object('key', 'allergens', 'value', jsonb_build_array('gluten', 'süt ürünü')),
    jsonb_build_object('key', 'mainIngredients', 'value', jsonb_build_array('domates', 'zeytinyağı', 'baharat')),
    jsonb_build_object('key', 'containsAlcoholPork', 'value', 'yok'),
    jsonb_build_object('key', 'prepMinutes', 'value', 15)
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'cafe_restaurant'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
    ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
  ));

-- --- home: materyal + renk
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{attributes}',
  jsonb_build_array(
    jsonb_build_object('key', 'material', 'value', 'Masif ahşap'),
    jsonb_build_object('key', 'color', 'value', 'Ceviz')
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'home'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
    ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
  ));

-- --- automotive: parca kodu, uyumlu marka/model (detail yuzeyi)
UPDATE public.products p
SET metadata = jsonb_set(
  coalesce(p.metadata, '{}'::jsonb),
  '{attributes}',
  jsonb_build_array(
    jsonb_build_object('key', 'partNumber', 'value', 'STD-2026'),
    jsonb_build_object('key', 'compatibleMake', 'value', jsonb_build_array('Standart')),
    jsonb_build_object('key', 'compatibleModel', 'value', jsonb_build_array('Evrensel'))
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'automotive'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_array_elements(
      CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
    ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
  ));

-- ============================================================
-- Bolum 4: hizmet sablonlarinin zorunlu alanlari (metadata.service)
-- ============================================================
-- Hizmet urunlerinde attributes degil service nesnesi doldurulur.
-- serviceTemplateKey yanlislikla 'physical' yazilan itemKind'i da duzeltir.

-- Yardimci mantik (her hizmet UPDATE icin ayni):
--   itemKind duzeltme: itemKind='physical' VE sablon hizmet ise 'service' yap.
--   service nesnesi: yalniz metadata->'service' bos/NULL iken yaz.

-- --- service sablonu (kuafor/guzellik): serviceType, priceMode,
--     serviceLocation, durationMinutes
UPDATE public.products p
SET metadata = jsonb_set(
  jsonb_set(
    coalesce(p.metadata, '{}'::jsonb),
    '{itemKind}',
    '"service"'::jsonb,
    true
  ),
  '{service}',
  jsonb_build_object(
    'serviceType', 'Diğer',
    'priceMode', 'fixed',
    'serviceLocation', 'business',
    'durationMinutes', 60
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'service'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_object_keys(
      CASE WHEN jsonb_typeof(p.metadata->'service') = 'object' THEN p.metadata->'service' ELSE '{}'::jsonb END
    ) k WHERE coalesce(p.metadata->'service'->>k, '') <> ''
  ));

-- --- technical_service: serviceType, deviceBrandModel, warrantyMonths,
--     partsIncluded + priceMode/serviceLocation
UPDATE public.products p
SET metadata = jsonb_set(
  jsonb_set(
    coalesce(p.metadata, '{}'::jsonb),
    '{itemKind}',
    '"service"'::jsonb,
    true
  ),
  '{service}',
  jsonb_build_object(
    'serviceType', 'Diğer',
    'priceMode', 'fixed',
    'serviceLocation', 'business'
  )
)
FROM public.product_categories pc, public.stores s
WHERE pc.id = p.category_id
  AND s.id = p.store_id
  AND s.is_demo = true
  AND p.is_active = true
  AND coalesce(pc.product_template_key, 'generic') = 'technical_service'
  AND (p.metadata IS NULL OR p.metadata = 'null'::jsonb OR NOT EXISTS (
    SELECT 1 FROM jsonb_object_keys(
      CASE WHEN jsonb_typeof(p.metadata->'service') = 'object' THEN p.metadata->'service' ELSE '{}'::jsonb END
    ) k WHERE coalesce(p.metadata->'service'->>k, '') <> ''
  ));

-- ============================================================
-- Bolum 5: guard — kalan bosluk migration'i dusurur
-- ============================================================
DO $$
DECLARE
  bos_attributes int;
  bos_service int;
  bos_template int;
  kalan_generic int;
BEGIN
  SELECT count(*) INTO bos_template
  FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  LEFT JOIN public.product_categories pc ON pc.id = p.category_id
  WHERE s.is_demo = true AND p.is_active = true
    AND coalesce(pc.product_template_key, 'generic') <> 'generic'
    AND (p.metadata IS NULL OR NOT (p.metadata ? 'templateKey'));

  IF bos_template > 0 THEN
    RAISE EXCEPTION 'Kiralik vitrin urunlerinde hala % urunde templateKey yok — seed hatti duzeltilmeli', bos_template;
  END IF;

  SELECT count(*) INTO bos_attributes
  FROM public.products p
  JOIN public.product_categories pc ON pc.id = p.category_id
  JOIN public.stores s ON s.id = p.store_id
  LEFT JOIN (VALUES
    ('fashion'), ('electronics'), ('food'), ('beauty'),
    ('cafe_restaurant'), ('home'), ('automotive')
  ) AS fiziksel(sablon) ON fiziksel.sablon = coalesce(pc.product_template_key, 'generic')
  WHERE s.is_demo = true AND p.is_active = true
    AND fiziksel.sablon IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(
        CASE WHEN jsonb_typeof(p.metadata->'attributes') = 'array' THEN p.metadata->'attributes' ELSE '[]'::jsonb END
      ) a WHERE coalesce(btrim(a->>'value'), '') <> ''
    );

  IF bos_attributes > 0 THEN
    RAISE EXCEPTION 'Kiralik vitrin urunlerinde hala % fiziksel urunde attributes bos — seed hatti duzeltilmeli', bos_attributes;
  END IF;

  SELECT count(*) INTO bos_service
  FROM public.products p
  JOIN public.product_categories pc ON pc.id = p.category_id
  JOIN public.stores s ON s.id = p.store_id
  LEFT JOIN (VALUES ('service'), ('technical_service')) AS hizmet(sablon) ON hizmet.sablon = coalesce(pc.product_template_key, 'generic')
  WHERE s.is_demo = true AND p.is_active = true
    AND hizmet.sablon IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_object_keys(
        CASE WHEN jsonb_typeof(p.metadata->'service') = 'object' THEN p.metadata->'service' ELSE '{}'::jsonb END
      ) k WHERE coalesce(p.metadata->'service'->>k, '') <> ''
    );

  IF bos_service > 0 THEN
    RAISE EXCEPTION 'Kiralik vitrin urunlerinde hala % hizmet urunde service nesnesi bos — seed hatti duzeltilmeli', bos_service;
  END IF;

  SELECT count(*) INTO kalan_generic
  FROM public.product_categories pc
  JOIN public.stores s ON s.id = pc.store_id
  WHERE s.is_demo = true
    AND (
      pc.product_template_key IS NULL
      OR btrim(pc.product_template_key) IN ('', 'generic')
    );

  IF kalan_generic > 0 THEN
    RAISE EXCEPTION 'Kiralik vitrinlerde % urun kategorisi hala generic — sablon eslemesi eksik', kalan_generic;
  END IF;
END $$;

COMMIT;
