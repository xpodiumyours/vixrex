-- Kiralık vitrin platformunun güvenli veri temeli.
-- Bu migration canlı akışı değiştirmez: tüm yeni özellik bayrakları kapalıdır.

-- ---------------------------------------------------------------------------
-- 1. Sunucuda da denetlenecek kapalı özellik bayrakları
-- ---------------------------------------------------------------------------
INSERT INTO public.feature_flags
  (flag_key, is_enabled, target_users, description)
VALUES
  ('rental_marketplace', false, 'all', 'Keşfet kiralık vitrin kataloğu'),
  ('rental_trial', false, 'all', '14 günlük kiralık vitrin denemesi'),
  ('product_origin', false, 'all', 'Ürün teslim ve hizmet noktaları'),
  ('assistant_rental_flow', false, 'all', 'Asistan ile kiralık vitrin kişiselleştirme'),
  ('paytr_checkout', false, 'all', 'PayTR kiralık vitrin ödeme akışı')
ON CONFLICT (flag_key) DO UPDATE
SET
  target_users = EXCLUDED.target_users,
  description = EXCLUDED.description;

-- ---------------------------------------------------------------------------
-- 2. Vitrin türü ve herkese açık erişim süresi
-- ---------------------------------------------------------------------------
ALTER TABLE public.stores
  ADD COLUMN IF NOT EXISTS storefront_kind TEXT NOT NULL DEFAULT 'standard',
  ADD COLUMN IF NOT EXISTS source_template_store_id UUID
    REFERENCES public.stores(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS template_version INTEGER,
  ADD COLUMN IF NOT EXISTS rental_access_status TEXT,
  ADD COLUMN IF NOT EXISTS rental_access_until TIMESTAMPTZ;

ALTER TABLE public.stores
  DROP CONSTRAINT IF EXISTS stores_storefront_kind_check;
ALTER TABLE public.stores
  ADD CONSTRAINT stores_storefront_kind_check CHECK (
    storefront_kind IN (
      'standard',
      'rental_template',
      'rental_tenant',
      'sale_template',
      'sale_tenant'
    )
  );

ALTER TABLE public.stores
  DROP CONSTRAINT IF EXISTS stores_rental_access_status_check;
ALTER TABLE public.stores
  ADD CONSTRAINT stores_rental_access_status_check CHECK (
    rental_access_status IS NULL
    OR rental_access_status IN (
      'trialing',
      'active',
      'past_due',
      'suspended',
      'cancelled'
    )
  );

CREATE INDEX IF NOT EXISTS idx_stores_storefront_kind
  ON public.stores(storefront_kind);
CREATE INDEX IF NOT EXISTS idx_stores_rental_access
  ON public.stores(rental_access_status, rental_access_until)
  WHERE storefront_kind = 'rental_tenant';

COMMENT ON COLUMN public.stores.source_template_store_id IS
  'Kullanıcı vitrininin kopyalandığı değiştirilemez ana şablon mağaza.';
COMMENT ON COLUMN public.stores.rental_access_until IS
  'Kiralık vitrinin herkese açık kalabileceği son an.';

-- Önceki sütun bazlı SELECT güvenlik modeli yeni güvenli sütunları da kapsasın.
GRANT SELECT (
  storefront_kind,
  source_template_store_id,
  template_version,
  rental_access_status,
  rental_access_until
) ON public.stores TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Kiralık şablon kataloğu
-- ---------------------------------------------------------------------------
CREATE TABLE public.rental_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL UNIQUE
    REFERENCES public.stores(id) ON DELETE RESTRICT,
  category_key TEXT NOT NULL,
  category_family TEXT NOT NULL CHECK (
    category_family IN (
      'fashion_retail',
      'technical_retail',
      'food_menu',
      'appointment_portfolio',
      'regional_service'
    )
  ),
  display_name TEXT NOT NULL CHECK (length(btrim(display_name)) > 0),
  version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
  monthly_price_kurus INTEGER NOT NULL DEFAULT 49900
    CHECK (monthly_price_kurus >= 0),
  vat_included BOOLEAN NOT NULL DEFAULT false,
  trial_days INTEGER NOT NULL DEFAULT 14 CHECK (trial_days BETWEEN 1 AND 30),
  is_active BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.rental_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read active rental templates"
ON public.rental_templates
FOR SELECT
TO anon, authenticated
USING (is_active = true);

GRANT SELECT ON public.rental_templates TO anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.rental_templates
  FROM anon, authenticated;

CREATE INDEX idx_rental_templates_category
  ON public.rental_templates(category_key, is_active);

DROP TRIGGER IF EXISTS trg_rental_templates_updated_at
  ON public.rental_templates;
CREATE TRIGGER trg_rental_templates_updated_at
  BEFORE UPDATE ON public.rental_templates
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 4. Kullanıcı kiralama ve deneme hakkı
-- ---------------------------------------------------------------------------
CREATE TABLE public.rental_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  store_id UUID NOT NULL UNIQUE
    REFERENCES public.stores(id) ON DELETE CASCADE,
  template_id UUID NOT NULL
    REFERENCES public.rental_templates(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'trialing' CHECK (
    status IN ('trialing', 'active', 'past_due', 'suspended', 'cancelled')
  ),
  trial_started_at TIMESTAMPTZ NOT NULL,
  trial_ends_at TIMESTAMPTZ NOT NULL,
  current_period_started_at TIMESTAMPTZ,
  current_period_ends_at TIMESTAMPTZ,
  grace_ends_at TIMESTAMPTZ,
  payment_provider TEXT,
  provider_customer_ref TEXT,
  provider_subscription_ref TEXT,
  last_verified_notification_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id),
  CHECK (trial_ends_at > trial_started_at),
  CHECK (
    payment_provider IS NULL
    OR payment_provider IN ('paytr')
  )
);

ALTER TABLE public.rental_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their rental subscription"
ON public.rental_subscriptions
FOR SELECT
TO authenticated
USING ((select auth.uid()) = user_id);

GRANT SELECT ON public.rental_subscriptions TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.rental_subscriptions
  FROM anon, authenticated;

CREATE INDEX idx_rental_subscriptions_status
  ON public.rental_subscriptions(status, trial_ends_at);

DROP TRIGGER IF EXISTS trg_rental_subscriptions_updated_at
  ON public.rental_subscriptions;
CREATE TRIGGER trg_rental_subscriptions_updated_at
  BEFORE UPDATE ON public.rental_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 5. Web sitesi seviyesindeki düzenlenebilir sayfalar
-- ---------------------------------------------------------------------------
CREATE TABLE public.store_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  page_key TEXT NOT NULL CHECK (
    page_key IN ('home', 'about', 'gallery', 'faq', 'contact')
  ),
  title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
  content JSONB NOT NULL DEFAULT '{}'::jsonb
    CHECK (jsonb_typeof(content) = 'object'),
  is_visible BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (store_id, page_key)
);

ALTER TABLE public.store_pages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read visible store pages"
ON public.store_pages
FOR SELECT
TO anon, authenticated
USING (
  is_visible = true
  AND EXISTS (
    SELECT 1
    FROM public.stores s
    WHERE s.id = store_pages.store_id
      AND s.is_published = true
      AND (
        s.storefront_kind <> 'rental_tenant'
        OR (
          s.rental_access_status IN ('trialing', 'active', 'past_due')
          AND s.rental_access_until IS NOT NULL
          AND s.rental_access_until > now()
        )
      )
  )
);

CREATE POLICY "Owners can read their store pages"
ON public.store_pages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = store_pages.store_id
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can insert their store pages"
ON public.store_pages
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = store_pages.store_id
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can update their store pages"
ON public.store_pages
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = store_pages.store_id
      AND s.user_id = (select auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = store_pages.store_id
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can delete their store pages"
ON public.store_pages
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = store_pages.store_id
      AND s.user_id = (select auth.uid())
  )
);

GRANT SELECT ON public.store_pages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.store_pages TO authenticated;

DROP TRIGGER IF EXISTS trg_store_pages_updated_at ON public.store_pages;
CREATE TRIGGER trg_store_pages_updated_at
  BEFORE UPDATE ON public.store_pages
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 6. Ürün ve hizmet teslim noktaları
-- ---------------------------------------------------------------------------
CREATE TABLE public.fulfillment_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  label TEXT NOT NULL CHECK (length(btrim(label)) > 0),
  district_name TEXT,
  province_name TEXT,
  country_code TEXT NOT NULL DEFAULT 'TR',
  public_address_text TEXT,
  is_exact_address_public BOOLEAN NOT NULL DEFAULT false,
  delivery_note TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.fulfillment_location_private (
  location_id UUID PRIMARY KEY
    REFERENCES public.fulfillment_locations(id) ON DELETE CASCADE,
  address_line TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_fulfillment_locations_one_default
  ON public.fulfillment_locations(store_id)
  WHERE is_default = true AND is_active = true;
CREATE INDEX idx_fulfillment_locations_store
  ON public.fulfillment_locations(store_id, is_active);

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS fulfillment_location_id UUID
    REFERENCES public.fulfillment_locations(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS delivery_mode TEXT,
  ADD COLUMN IF NOT EXISTS origin_display_override TEXT;

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_delivery_mode_check;
ALTER TABLE public.products
  ADD CONSTRAINT products_delivery_mode_check CHECK (
    delivery_mode IS NULL
    OR delivery_mode IN (
      'ship',
      'pickup',
      'local_delivery',
      'service_at_business',
      'service_at_customer',
      'digital'
    )
  );

CREATE INDEX idx_products_fulfillment_location
  ON public.products(fulfillment_location_id);

CREATE OR REPLACE FUNCTION public.validate_product_fulfillment_location()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  IF NEW.fulfillment_location_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM public.fulfillment_locations fl
      WHERE fl.id = NEW.fulfillment_location_id
        AND fl.store_id = NEW.store_id
        AND fl.is_active = true
    )
  THEN
    RAISE EXCEPTION 'FULFILLMENT_LOCATION_NOT_IN_SAME_STORE';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_product_fulfillment_location
  ON public.products;
CREATE TRIGGER trg_validate_product_fulfillment_location
  BEFORE INSERT OR UPDATE OF store_id, fulfillment_location_id
  ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.validate_product_fulfillment_location();

ALTER TABLE public.fulfillment_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fulfillment_location_private ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read safe fulfillment locations"
ON public.fulfillment_locations
FOR SELECT
TO anon, authenticated
USING (
  is_active = true
  AND EXISTS (
    SELECT 1
    FROM public.stores s
    WHERE s.id = fulfillment_locations.store_id
      AND s.is_published = true
      AND (
        s.storefront_kind <> 'rental_tenant'
        OR (
          s.rental_access_status IN ('trialing', 'active', 'past_due')
          AND s.rental_access_until IS NOT NULL
          AND s.rental_access_until > now()
        )
      )
  )
);

CREATE POLICY "Owners can manage fulfillment locations"
ON public.fulfillment_locations
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = fulfillment_locations.store_id
      AND s.user_id = (select auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = fulfillment_locations.store_id
      AND s.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can manage private fulfillment addresses"
ON public.fulfillment_location_private
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.fulfillment_locations fl
    JOIN public.stores s ON s.id = fl.store_id
    WHERE fl.id = fulfillment_location_private.location_id
      AND s.user_id = (select auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.fulfillment_locations fl
    JOIN public.stores s ON s.id = fl.store_id
    WHERE fl.id = fulfillment_location_private.location_id
      AND s.user_id = (select auth.uid())
  )
);

REVOKE SELECT ON TABLE public.fulfillment_locations
  FROM anon, authenticated;
GRANT SELECT (
  id,
  store_id,
  label,
  district_name,
  province_name,
  country_code,
  public_address_text,
  is_exact_address_public,
  delivery_note,
  is_default,
  is_active,
  created_at,
  updated_at
) ON public.fulfillment_locations TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.fulfillment_locations
  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.fulfillment_location_private TO authenticated;

DROP TRIGGER IF EXISTS trg_fulfillment_locations_updated_at
  ON public.fulfillment_locations;
CREATE TRIGGER trg_fulfillment_locations_updated_at
  BEFORE UPDATE ON public.fulfillment_locations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_fulfillment_location_private_updated_at
  ON public.fulfillment_location_private;
CREATE TRIGGER trg_fulfillment_location_private_updated_at
  BEFORE UPDATE ON public.fulfillment_location_private
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 7. Kiralık vitrinlerin süresi dolunca public erişimi anında kes
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow public read stores" ON public.stores;
DROP POLICY IF EXISTS "Published stores are publicly readable" ON public.stores;
DROP POLICY IF EXISTS "Public stores are viewable by everyone" ON public.stores;

CREATE POLICY "Allow public read stores"
ON public.stores
FOR SELECT
TO anon, authenticated
USING (
  is_published = true
  AND (
    storefront_kind <> 'rental_tenant'
    OR (
      rental_access_status IN ('trialing', 'active', 'past_due')
      AND rental_access_until IS NOT NULL
      AND rental_access_until > now()
    )
  )
);

DROP POLICY IF EXISTS "anon_read_products" ON public.products;
CREATE POLICY "anon_read_products"
ON public.products
FOR SELECT
TO anon
USING (
  is_active = true
  AND is_visible = true
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = products.store_id
      AND s.is_published = true
      AND (
        s.storefront_kind <> 'rental_tenant'
        OR (
          s.rental_access_status IN ('trialing', 'active', 'past_due')
          AND s.rental_access_until IS NOT NULL
          AND s.rental_access_until > now()
        )
      )
  )
);

DROP POLICY IF EXISTS "auth_read_products" ON public.products;
CREATE POLICY "auth_read_products"
ON public.products
FOR SELECT
TO authenticated
USING (
  is_active = true
  AND is_visible = true
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = products.store_id
      AND s.is_published = true
      AND (
        s.storefront_kind <> 'rental_tenant'
        OR (
          s.rental_access_status IN ('trialing', 'active', 'past_due')
          AND s.rental_access_until IS NOT NULL
          AND s.rental_access_until > now()
        )
      )
  )
);

DROP POLICY IF EXISTS "anon_read_categories" ON public.product_categories;
CREATE POLICY "anon_read_categories"
ON public.product_categories
FOR SELECT
TO anon
USING (
  is_active = true
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = product_categories.store_id
      AND s.is_published = true
      AND (
        s.storefront_kind <> 'rental_tenant'
        OR (
          s.rental_access_status IN ('trialing', 'active', 'past_due')
          AND s.rental_access_until IS NOT NULL
          AND s.rental_access_until > now()
        )
      )
  )
);

DROP POLICY IF EXISTS "auth_read_categories" ON public.product_categories;
CREATE POLICY "auth_read_categories"
ON public.product_categories
FOR SELECT
TO authenticated
USING (
  is_active = true
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = product_categories.store_id
      AND s.is_published = true
      AND (
        s.storefront_kind <> 'rental_tenant'
        OR (
          s.rental_access_status IN ('trialing', 'active', 'past_due')
          AND s.rental_access_until IS NOT NULL
          AND s.rental_access_until > now()
        )
      )
  )
);

DROP POLICY IF EXISTS "Anyone can read published articles"
  ON public.store_articles;
CREATE POLICY "Anyone can read published articles"
ON public.store_articles
FOR SELECT
TO anon, authenticated
USING (
  status = 'published'
  AND EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.slug = store_articles.store_slug
      AND s.is_published = true
      AND (
        s.storefront_kind <> 'rental_tenant'
        OR (
          s.rental_access_status IN ('trialing', 'active', 'past_due')
          AND s.rental_access_until IS NOT NULL
          AND s.rental_access_until > now()
        )
      )
  )
);

-- ---------------------------------------------------------------------------
-- 8. Hazır şablonları gerçek kiralık katalog kaydına dönüştür
-- ---------------------------------------------------------------------------
UPDATE public.stores
SET storefront_kind = 'rental_template'
WHERE is_demo = true
  AND slug IN (
    'kiralik-butik',
    'kiralik-kafe',
    'kiralik-kuafor',
    'kiralik-teknik',
    'kiralik-gida'
  );

INSERT INTO public.rental_templates (
  store_id,
  category_key,
  category_family,
  display_name,
  version,
  monthly_price_kurus,
  vat_included,
  trial_days,
  is_active
)
SELECT
  s.id,
  CASE s.slug
    WHEN 'kiralik-butik' THEN 'butik'
    WHEN 'kiralik-kafe' THEN 'kafe-lokanta'
    WHEN 'kiralik-kuafor' THEN 'kuafor'
    WHEN 'kiralik-teknik' THEN 'teknik-servis'
    WHEN 'kiralik-gida' THEN 'gida'
  END,
  CASE s.slug
    WHEN 'kiralik-butik' THEN 'fashion_retail'
    WHEN 'kiralik-kafe' THEN 'food_menu'
    WHEN 'kiralik-kuafor' THEN 'appointment_portfolio'
    WHEN 'kiralik-teknik' THEN 'regional_service'
    WHEN 'kiralik-gida' THEN 'food_menu'
  END,
  s.name,
  1,
  49900,
  false,
  14,
  true
FROM public.stores s
WHERE s.slug IN (
  'kiralik-butik',
  'kiralik-kafe',
  'kiralik-kuafor',
  'kiralik-teknik',
  'kiralik-gida'
)
ON CONFLICT (store_id) DO NOTHING;

INSERT INTO public.store_pages (
  store_id,
  page_key,
  title,
  content,
  is_visible,
  sort_order
)
SELECT
  s.id,
  'about',
  'Hakkımızda',
  jsonb_build_object(
    'body',
    coalesce(nullif(btrim(s.corporate_bio), ''), s.description, '')
  ),
  true,
  30
FROM public.stores s
WHERE s.storefront_kind = 'rental_template'
ON CONFLICT (store_id, page_key) DO NOTHING;

INSERT INTO public.store_pages (
  store_id,
  page_key,
  title,
  content,
  is_visible,
  sort_order
)
SELECT
  s.id,
  'faq',
  'Sıkça Sorulan Sorular',
  jsonb_build_object(
    'items',
    jsonb_build_array(
      jsonb_build_object(
        'question', 'Nasıl iletişim kurabilirim?',
        'answer', 'Vitrindeki iletişim seçeneklerinden bize ulaşabilirsiniz.'
      ),
      jsonb_build_object(
        'question', 'Çalışma saatleri nedir?',
        'answer', 'Güncel çalışma saatleri iletişim bölümünde yer alır.'
      )
    )
  ),
  true,
  50
FROM public.stores s
WHERE s.storefront_kind = 'rental_template'
ON CONFLICT (store_id, page_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 9. Doğrulanmış kullanıcı için atomik 14 günlük deneme ve tam şablon kopyası
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_rental_trial(
  p_template_id UUID
)
RETURNS TABLE (
  store_id UUID,
  store_slug TEXT,
  trial_ends_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_email_confirmed_at TIMESTAMPTZ;
  v_is_anonymous BOOLEAN;
  v_template public.rental_templates%ROWTYPE;
  v_source public.stores%ROWTYPE;
  v_store_id UUID;
  v_store_slug TEXT;
  v_trial_ends_at TIMESTAMPTZ;
  v_category RECORD;
  v_product RECORD;
  v_page RECORD;
  v_article RECORD;
  v_location RECORD;
  v_new_category_id UUID;
  v_new_location_id UUID;
  v_category_map JSONB := '{}'::jsonb;
  v_location_map JSONB := '{}'::jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.feature_flags
    WHERE flag_key = 'rental_marketplace'
      AND is_enabled = true
  ) OR NOT EXISTS (
    SELECT 1 FROM public.feature_flags
    WHERE flag_key = 'rental_trial'
      AND is_enabled = true
  ) THEN
    RAISE EXCEPTION 'RENTAL_TRIAL_DISABLED';
  END IF;

  SELECT u.email_confirmed_at, u.is_anonymous
  INTO v_email_confirmed_at, v_is_anonymous
  FROM auth.users u
  WHERE u.id = v_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_email_confirmed_at IS NULL
    OR coalesce(v_is_anonymous, false) = true
  THEN
    RAISE EXCEPTION 'VERIFIED_ACCOUNT_REQUIRED';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.rental_subscriptions rs
    WHERE rs.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'RENTAL_TRIAL_ALREADY_USED';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'USER_ALREADY_HAS_STORE';
  END IF;

  SELECT *
  INTO v_template
  FROM public.rental_templates rt
  WHERE rt.id = p_template_id
    AND rt.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'RENTAL_TEMPLATE_NOT_FOUND';
  END IF;

  SELECT *
  INTO v_source
  FROM public.stores s
  WHERE s.id = v_template.store_id
    AND s.storefront_kind = 'rental_template'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'RENTAL_TEMPLATE_STORE_NOT_FOUND';
  END IF;

  v_store_slug := 'v-' || replace(v_user_id::text, '-', '');
  v_trial_ends_at := now() + (v_template.trial_days * INTERVAL '1 day');

  INSERT INTO public.stores (
    slug,
    name,
    business_type,
    description,
    corporate_bio,
    whatsapp,
    instagram,
    website,
    address,
    theme,
    status,
    marketplace_links,
    gallery_items,
    products,
    product_categories,
    offerings,
    catalog_link,
    references_link,
    vcard_link,
    shelf_image_url,
    logo_url,
    working_hours,
    is_published,
    is_store,
    kategori,
    latitude,
    longitude,
    location_accuracy_meters,
    location_source,
    province_code,
    province_name,
    district_code,
    district_name,
    google_business_link,
    is_blog_trusted,
    privacy_notice_acknowledged,
    terms_accepted,
    publication_consent_accepted,
    user_id,
    edit_token,
    product_storage_version,
    theme_preset,
    email,
    rating_score,
    review_count,
    featured_banner_title,
    featured_banner_description,
    featured_banner_image_url,
    featured_banner_price_text,
    is_demo,
    storefront_kind,
    source_template_store_id,
    template_version,
    rental_access_status,
    rental_access_until
  )
  VALUES (
    v_store_slug,
    v_source.name,
    v_source.business_type,
    v_source.description,
    v_source.corporate_bio,
    NULL,
    NULL,
    NULL,
    NULL,
    v_source.theme,
    'draft',
    '{}'::jsonb,
    v_source.gallery_items,
    '[]'::jsonb,
    '[]'::jsonb,
    v_source.offerings,
    NULL,
    NULL,
    NULL,
    v_source.shelf_image_url,
    v_source.logo_url,
    v_source.working_hours,
    false,
    true,
    v_source.kategori,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    false,
    false,
    false,
    false,
    v_user_id,
    NULL,
    2,
    v_source.theme_preset,
    NULL,
    v_source.rating_score,
    v_source.review_count,
    v_source.featured_banner_title,
    v_source.featured_banner_description,
    v_source.featured_banner_image_url,
    v_source.featured_banner_price_text,
    false,
    'rental_tenant',
    v_source.id,
    v_template.version,
    'trialing',
    v_trial_ends_at
  )
  RETURNING id INTO v_store_id;

  FOR v_category IN
    SELECT * FROM public.product_categories
    WHERE store_id = v_source.id
    ORDER BY sort_order, created_at
  LOOP
    INSERT INTO public.product_categories (
      store_id,
      name,
      slug,
      sort_order,
      is_active
    )
    VALUES (
      v_store_id,
      v_category.name,
      v_category.slug,
      v_category.sort_order,
      v_category.is_active
    )
    RETURNING id INTO v_new_category_id;

    v_category_map := v_category_map
      || jsonb_build_object(
        v_category.id::text,
        v_new_category_id::text
      );
  END LOOP;

  FOR v_location IN
    SELECT * FROM public.fulfillment_locations
    WHERE store_id = v_source.id
    ORDER BY is_default DESC, created_at
  LOOP
    INSERT INTO public.fulfillment_locations (
      store_id,
      label,
      district_name,
      province_name,
      country_code,
      public_address_text,
      is_exact_address_public,
      delivery_note,
      is_default,
      is_active
    )
    VALUES (
      v_store_id,
      v_location.label,
      v_location.district_name,
      v_location.province_name,
      v_location.country_code,
      v_location.public_address_text,
      v_location.is_exact_address_public,
      v_location.delivery_note,
      v_location.is_default,
      v_location.is_active
    )
    RETURNING id INTO v_new_location_id;

    v_location_map := v_location_map
      || jsonb_build_object(
        v_location.id::text,
        v_new_location_id::text
      );
  END LOOP;

  FOR v_product IN
    SELECT * FROM public.products
    WHERE store_id = v_source.id
    ORDER BY sort_order, created_at
  LOOP
    INSERT INTO public.products (
      store_id,
      category_id,
      source_type,
      external_product_id,
      name,
      slug,
      description,
      price_amount,
      price_text,
      currency,
      stock_quantity,
      stock_status,
      image_urls,
      metadata,
      seo_title,
      seo_description,
      is_visible,
      is_active,
      sort_order,
      old_price_amount,
      badge_tag,
      fulfillment_location_id,
      delivery_mode,
      origin_display_override
    )
    VALUES (
      v_store_id,
      CASE
        WHEN v_product.category_id IS NULL THEN NULL
        ELSE (v_category_map ->> v_product.category_id::text)::uuid
      END,
      v_product.source_type,
      NULL,
      v_product.name,
      v_product.slug,
      v_product.description,
      v_product.price_amount,
      v_product.price_text,
      v_product.currency,
      v_product.stock_quantity,
      v_product.stock_status,
      v_product.image_urls,
      v_product.metadata,
      v_product.seo_title,
      v_product.seo_description,
      v_product.is_visible,
      v_product.is_active,
      v_product.sort_order,
      v_product.old_price_amount,
      v_product.badge_tag,
      CASE
        WHEN v_product.fulfillment_location_id IS NULL THEN NULL
        ELSE (
          v_location_map ->> v_product.fulfillment_location_id::text
        )::uuid
      END,
      v_product.delivery_mode,
      v_product.origin_display_override
    );
  END LOOP;

  FOR v_page IN
    SELECT * FROM public.store_pages
    WHERE store_id = v_source.id
    ORDER BY sort_order, created_at
  LOOP
    INSERT INTO public.store_pages (
      store_id,
      page_key,
      title,
      content,
      is_visible,
      sort_order
    )
    VALUES (
      v_store_id,
      v_page.page_key,
      v_page.title,
      v_page.content,
      v_page.is_visible,
      v_page.sort_order
    );
  END LOOP;

  FOR v_article IN
    SELECT * FROM public.store_articles
    WHERE store_slug = v_source.slug
    ORDER BY created_at
  LOOP
    INSERT INTO public.store_articles (
      store_slug,
      title,
      summary,
      content,
      cover_image_url,
      article_type,
      target_topic,
      target_city,
      seo_score,
      seo_errors,
      slug,
      status,
      published_at
    )
    VALUES (
      v_store_slug,
      v_article.title,
      v_article.summary,
      v_article.content,
      v_article.cover_image_url,
      v_article.article_type,
      v_article.target_topic,
      v_article.target_city,
      v_article.seo_score,
      v_article.seo_errors,
      v_article.slug,
      v_article.status,
      v_article.published_at
    );
  END LOOP;

  INSERT INTO public.rental_subscriptions (
    user_id,
    store_id,
    template_id,
    status,
    trial_started_at,
    trial_ends_at
  )
  VALUES (
    v_user_id,
    v_store_id,
    v_template.id,
    'trialing',
    now(),
    v_trial_ends_at
  );

  RETURN QUERY
  SELECT v_store_id, v_store_slug, v_trial_ends_at;
END;
$$;

REVOKE ALL ON FUNCTION public.start_rental_trial(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_rental_trial(UUID)
  TO authenticated;

NOTIFY pgrst, 'reload schema';
