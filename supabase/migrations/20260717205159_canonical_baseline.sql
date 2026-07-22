-- ============================================================================
-- VixRex Canonical Baseline (M2B)
-- 17 tablo, SIFIRDAN yazıldı. supabase_schema.sql kopyalanmadı.
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 2. CANONICAL TABLOLAR (17)
-- ============================================================================

-- 2.1 stores
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (length(btrim(slug)) > 0),
  name TEXT NOT NULL CHECK (length(btrim(name)) > 0),
  business_type TEXT,
  description TEXT,
  corporate_bio TEXT,
  whatsapp TEXT,
  instagram TEXT,
  website TEXT,
  address TEXT,
  theme TEXT,
  status TEXT DEFAULT 'draft',
  marketplace_links JSONB DEFAULT '{}'::jsonb,
  gallery_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  products JSONB NOT NULL DEFAULT '[]'::jsonb,
  product_categories JSONB NOT NULL DEFAULT '[]'::jsonb,
  offerings JSONB DEFAULT '[]'::jsonb,
  catalog_link TEXT,
  references_link TEXT,
  vcard_link TEXT,
  shelf_image_url TEXT,
  logo_url TEXT,
  working_hours TEXT,
  is_published BOOLEAN DEFAULT false,
  is_store BOOLEAN DEFAULT false,
  kategori TEXT,
  latitude FLOAT8,
  longitude FLOAT8,
  location_accuracy_meters FLOAT8,
  location_consented_at TIMESTAMPTZ,
  location_source TEXT,
  province_code TEXT,
  province_name TEXT,
  district_code TEXT,
  district_name TEXT,
  google_business_link TEXT,
  is_blog_trusted BOOLEAN DEFAULT false,
  privacy_notice_acknowledged BOOLEAN NOT NULL DEFAULT false,
  privacy_notice_acknowledged_at TIMESTAMPTZ,
  privacy_notice_version TEXT,
  privacy_notice_hash TEXT,
  terms_accepted BOOLEAN NOT NULL DEFAULT false,
  terms_accepted_at TIMESTAMPTZ,
  terms_version TEXT,
  terms_hash TEXT,
  publication_consent_accepted BOOLEAN NOT NULL DEFAULT false,
  publication_consent_accepted_at TIMESTAMPTZ,
  publication_consent_withdrawn_at TIMESTAMPTZ,
  publication_consent_version TEXT,
  publication_consent_hash TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  edit_token TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  published_at TIMESTAMPTZ,
  CONSTRAINT unique_user_store UNIQUE (user_id),
  CONSTRAINT check_offerings_limit CHECK (
    offerings IS NULL OR (
      jsonb_typeof(offerings) = 'array' AND jsonb_array_length(offerings) <= 6
    )
  ),
  CONSTRAINT check_google_link CHECK (
    google_business_link IS NULL OR
    google_business_link = '' OR
    google_business_link ~* '^https:\/\/(www\.)?(search\.google\.com|g\.page|maps\.google\.com|maps\.app\.goo\.gl)\/.*$'
  )
);

COMMENT ON COLUMN public.stores.gallery_items IS 'VixRex gallery items. Each item keeps imageUrl, title and description.';
COMMENT ON COLUMN public.stores.products IS 'Product catalog list for stores.';
COMMENT ON COLUMN public.stores.product_categories IS 'Ordered custom product categories for the store catalog.';
COMMENT ON COLUMN public.stores.working_hours IS 'Working hours text for stores.';
COMMENT ON COLUMN public.stores.latitude IS 'Store location latitude coordinate.';
COMMENT ON COLUMN public.stores.longitude IS 'Store location longitude coordinate.';
COMMENT ON COLUMN public.stores.location_accuracy_meters IS 'Accuracy radius of the retrieved location in meters.';
COMMENT ON COLUMN public.stores.location_consented_at IS 'Timestamp when the user provided KVKK consent to share their location.';
COMMENT ON COLUMN public.stores.location_source IS 'Source platform/device from which location was retrieved.';

-- 2.2 vitrin_views
CREATE TABLE IF NOT EXISTS public.vitrin_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  session_key TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'direct',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.3 booking_settings
CREATE TABLE IF NOT EXISTS public.booking_settings (
  store_slug TEXT PRIMARY KEY REFERENCES public.stores(slug) ON DELETE CASCADE,
  is_enabled BOOLEAN DEFAULT false,
  capacity INT DEFAULT 1 CONSTRAINT check_capacity CHECK (capacity >= 1 AND capacity <= 5),
  working_hours JSONB DEFAULT '{
    "1": {"start": "09:00", "end": "19:00", "active": true},
    "2": {"start": "09:00", "end": "19:00", "active": true},
    "3": {"start": "09:00", "end": "19:00", "active": true},
    "4": {"start": "09:00", "end": "19:00", "active": true},
    "5": {"start": "09:00", "end": "19:00", "active": true},
    "6": {"start": "10:00", "end": "17:00", "active": true},
    "7": {"start": "00:00", "end": "00:00", "active": false}
  }'::jsonb,
  lunch_break JSONB DEFAULT '{"start": "12:00", "end": "13:00", "active": true}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2.4 store_articles
CREATE TABLE IF NOT EXISTS public.store_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
  summary TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL CHECK (length(btrim(content)) > 0),
  cover_image_url TEXT,
  article_type TEXT NOT NULL DEFAULT 'standard' CHECK (article_type IN ('standard', 'news', 'promotion')),
  target_topic TEXT,
  target_city TEXT,
  seo_score INT NOT NULL DEFAULT 0 CHECK (seo_score >= 0 AND seo_score <= 100),
  seo_errors JSONB NOT NULL DEFAULT '[]'::jsonb,
  slug TEXT NOT NULL CHECK (length(btrim(slug)) > 0),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at TIMESTAMPTZ,
  CONSTRAINT unique_store_article_slug UNIQUE (store_slug, slug)
);

-- 2.5 appointments
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_notes TEXT,
  service_title TEXT NOT NULL,
  service_price TEXT,
  service_duration INT NOT NULL CONSTRAINT check_duration CHECK (service_duration >= 15 AND service_duration <= 240),
  appointment_time TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending' CONSTRAINT check_status CHECK (status IN ('pending', 'confirmed', 'rejected', 'cancelled_by_customer', 'cancelled_by_store', 'expired')),
  token_hash TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL
);

-- 2.6 store_instagram_connections
CREATE TABLE IF NOT EXISTS public.store_instagram_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  instagram_user_id TEXT,
  username TEXT,
  account_type TEXT,
  scopes TEXT[] NOT NULL DEFAULT '{}'::text[],
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'connected', 'disconnected', 'failed')),
  state_nonce TEXT,
  edit_token_hash TEXT,
  connected_at TIMESTAMPTZ,
  last_sync_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT unique_store_instagram_connection UNIQUE (store_slug)
);

-- 2.7 store_instagram_tokens
CREATE TABLE IF NOT EXISTS public.store_instagram_tokens (
  connection_id UUID PRIMARY KEY REFERENCES public.store_instagram_connections(id) ON DELETE CASCADE,
  access_token_ciphertext TEXT NOT NULL,
  token_type TEXT NOT NULL DEFAULT 'bearer',
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.8 store_instagram_imports
CREATE TABLE IF NOT EXISTS public.store_instagram_imports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  connection_id UUID REFERENCES public.store_instagram_connections(id) ON DELETE SET NULL,
  source_media_id TEXT NOT NULL,
  source_permalink TEXT,
  product_slug TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'imported' CHECK (status IN ('imported', 'updated', 'failed', 'retained')),
  error_message TEXT,
  imported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT unique_store_instagram_import UNIQUE (store_slug, source_media_id)
);

-- 2.9 legal_documents
CREATE TABLE IF NOT EXISTS public.legal_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_type TEXT NOT NULL CHECK (document_type IN ('privacy', 'terms', 'consent', 'dataDeletion')),
  version TEXT NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL DEFAULT '',
  sections JSONB NOT NULL CHECK (jsonb_typeof(sections) = 'array'),
  content_hash TEXT NOT NULL DEFAULT '',
  is_active BOOLEAN NOT NULL DEFAULT false,
  effective_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (document_type, version)
);

CREATE UNIQUE INDEX IF NOT EXISTS legal_documents_one_active_per_type
  ON public.legal_documents (document_type) WHERE is_active;

-- 2.10 assistant_rate_limits
CREATE TABLE IF NOT EXISTS public.assistant_rate_limits (
  client_key TEXT PRIMARY KEY,
  window_started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  request_count INTEGER NOT NULL DEFAULT 0 CHECK (request_count >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.11 booking_blocks
CREATE TABLE IF NOT EXISTS public.booking_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  block_date DATE NOT NULL,
  start_time TIME WITHOUT TIME ZONE,
  end_time TIME WITHOUT TIME ZONE,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2.12 appointment_reschedule_requests
CREATE TABLE IF NOT EXISTS public.appointment_reschedule_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  requested_time TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending' CONSTRAINT check_reschedule_status CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2.13 article_reports
CREATE TABLE IF NOT EXISTS public.article_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.store_articles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (length(btrim(reason)) > 0),
  reporter_ip TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.14 meta_data_deletion_requests
CREATE TABLE IF NOT EXISTS public.meta_data_deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL DEFAULT 'instagram',
  provider_user_id TEXT,
  store_slug TEXT,
  status TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'processing', 'completed', 'failed')),
  confirmation_code TEXT NOT NULL UNIQUE,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  error_message TEXT
);

-- 2.15 legal_acceptance_events
CREATE TABLE IF NOT EXISTS public.legal_acceptance_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL,
  user_id UUID,
  event_type TEXT NOT NULL CHECK (
    event_type IN (
      'privacy_notice_acknowledged',
      'terms_accepted',
      'publication_consent_granted',
      'publication_consent_withdrawn'
    )
  ),
  document_type TEXT NOT NULL,
  document_version TEXT NOT NULL,
  document_hash TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.16 category_image_templates
CREATE TABLE IF NOT EXISTS public.category_image_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_key TEXT NOT NULL,
  category_label TEXT NOT NULL,
  image_type TEXT NOT NULL CHECK (image_type IN ('cover', 'logo_placeholder', 'gallery', 'product')),
  image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  title TEXT,
  description TEXT,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.17 store_category_image_usage
CREATE TABLE IF NOT EXISTS public.store_category_image_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  category_key TEXT NOT NULL,
  images_used JSONB NOT NULL DEFAULT '[]',
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 3. İNDEKSLER
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_stores_user_id ON public.stores USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_stores_slug ON public.stores USING btree (slug);
CREATE INDEX IF NOT EXISTS idx_vitrin_views_store_slug ON public.vitrin_views USING btree (store_slug);
CREATE INDEX IF NOT EXISTS idx_vitrin_views_created ON public.vitrin_views USING btree (created_at);
CREATE INDEX IF NOT EXISTS idx_appointments_store_time ON public.appointments(store_slug, appointment_time);
CREATE INDEX IF NOT EXISTS idx_appointments_token_hash ON public.appointments(token_hash);
CREATE INDEX IF NOT EXISTS idx_booking_blocks_store_date ON public.booking_blocks(store_slug, block_date);
CREATE INDEX IF NOT EXISTS idx_store_instagram_connections_store ON public.store_instagram_connections(store_slug);
CREATE INDEX IF NOT EXISTS idx_store_instagram_connections_user ON public.store_instagram_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_store_instagram_imports_store ON public.store_instagram_imports(store_slug, imported_at DESC);
CREATE INDEX IF NOT EXISTS idx_store_articles_published ON public.store_articles(store_slug, status, published_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_cat_templates_key ON public.category_image_templates(category_key);
CREATE INDEX IF NOT EXISTS idx_cat_templates_type ON public.category_image_templates(image_type);
CREATE INDEX IF NOT EXISTS idx_cat_templates_active ON public.category_image_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_store_cat_usage_store ON public.store_category_image_usage(store_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_store_cat_usage_store_unique ON public.store_category_image_usage(store_id);
CREATE INDEX IF NOT EXISTS legal_acceptance_events_store_slug_idx ON public.legal_acceptance_events(store_slug, occurred_at DESC);

-- ============================================================================
-- 4. STORAGE BUCKETS (5 MB, P1 güvenli)
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'shelf-images') THEN
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('shelf-images', 'shelf-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']);
  ELSE
    UPDATE storage.buckets
    SET public = true, file_size_limit = 5242880, allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
    WHERE id = 'shelf-images';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'category-templates') THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('category-templates', 'category-templates', true);
  END IF;
END $$;

-- ============================================================================
-- 4b. PRIVATE SCHEMA (idempotent)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO service_role;

-- ============================================================================
-- 5. TRIGGER FONKSİYONLARI
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY INVOKER SET search_path = pg_catalog, public AS $$
BEGIN
  NEW.updated_at = pg_catalog.now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_published_at()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY INVOKER SET search_path = pg_catalog, public AS $$
BEGIN
  IF NEW.status = 'published' AND (OLD.status IS DISTINCT FROM 'published') THEN
    NEW.published_at = COALESCE(NEW.published_at, pg_catalog.now());
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_published_at_on_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY INVOKER SET search_path = pg_catalog, public AS $$
BEGIN
  IF NEW.status = 'published' AND NEW.published_at IS NULL THEN
    NEW.published_at = pg_catalog.now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.mask_appointment_name(p_name text)
RETURNS text LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  v_parts text[];
  v_result text[] := '{}';
  v_part text;
BEGIN
  v_parts := regexp_split_to_array(trim(p_name), '\s+');
  FOREACH v_part IN ARRAY v_parts LOOP
    IF length(v_part) > 0 THEN
      v_result := array_append(v_result, left(v_part, 1) || '***');
    END IF;
  END LOOP;
  RETURN array_to_string(v_result, ' ');
END;
$$;

CREATE OR REPLACE FUNCTION public.set_store_instagram_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
BEGIN
  new.updated_at = pg_catalog.now();
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_article_before_save()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_is_trusted boolean;
  v_owner_id uuid;
BEGIN
  SELECT is_blog_trusted, user_id INTO v_is_trusted, v_owner_id
  FROM public.stores WHERE slug = new.store_slug;
  IF new.status = 'published' AND (v_is_trusted IS NULL OR NOT v_is_trusted) THEN
    IF auth.uid() = v_owner_id THEN
      new.status := 'review';
    END IF;
  END IF;
  new.updated_at := pg_catalog.now();
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_article_approved()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_count int;
BEGIN
  IF new.status = 'published' AND (old.status IS NULL OR old.status <> 'published') THEN
    SELECT count(*) INTO v_count FROM public.store_articles
    WHERE store_slug = new.store_slug AND status = 'published';
    IF v_count >= 3 THEN
      UPDATE public.stores SET is_blog_trusted = true WHERE slug = new.store_slug;
    END IF;
  END IF;
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_article_spam_check()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE
  v_count int;
  v_banned text := '(bahis|casino|slot|escort|porn|porno|uyusturucu|silah|kumar)';
BEGIN
  IF tg_op = 'INSERT' THEN
    SELECT count(*) INTO v_count FROM public.store_articles
    WHERE store_slug = new.store_slug AND created_at > now() - interval '24 hours';
    IF v_count >= 5 THEN
      RAISE EXCEPTION 'STORE_ARTICLE_RATE_LIMIT_EXCEEDED' USING errcode = 'P0001';
    END IF;
  END IF;
  IF (new.title ~* v_banned) OR (new.summary ~* v_banned) OR (new.content ~* v_banned)
     OR (new.target_topic ~* v_banned) OR (new.target_city ~* v_banned) THEN
    RAISE EXCEPTION 'CONTENT_CONTAINS_BANNED_WORDS' USING errcode = 'P0001';
  END IF;
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION private.set_legal_document_hash()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF tg_op = 'UPDATE' AND old.is_active AND (
    new.document_type IS DISTINCT FROM old.document_type
    OR new.version IS DISTINCT FROM old.version
    OR new.title IS DISTINCT FROM old.title
    OR new.subtitle IS DISTINCT FROM old.subtitle
    OR new.sections IS DISTINCT FROM old.sections
  ) THEN
    RAISE EXCEPTION 'ACTIVE_LEGAL_DOCUMENT_IS_IMMUTABLE';
  END IF;
  new.content_hash := pg_catalog.md5(
    new.document_type || '|' || new.version || '|' || new.title || '|' || new.subtitle || '|' || new.sections::text
  );
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION private.validate_store_legal_acceptance()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_now timestamptz := pg_catalog.now();
BEGIN
  IF tg_op = 'UPDATE' AND old.publication_consent_accepted
    AND new.publication_consent_accepted IS NOT true
    AND new.publication_consent_withdrawn_at IS NULL THEN
    new.publication_consent_withdrawn_at := v_now;
  END IF;
  IF new.is_published IS NOT true THEN RETURN new; END IF;
  IF new.privacy_notice_acknowledged IS NOT true THEN RAISE EXCEPTION 'PRIVACY_NOTICE_REQUIRED'; END IF;
  IF new.terms_accepted IS NOT true THEN RAISE EXCEPTION 'TERMS_ACCEPTANCE_REQUIRED'; END IF;
  IF new.publication_consent_accepted IS NOT true THEN RAISE EXCEPTION 'PUBLICATION_CONSENT_REQUIRED'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.legal_documents WHERE document_type='privacy' AND is_active AND version=new.privacy_notice_version AND content_hash=new.privacy_notice_hash) THEN
    RAISE EXCEPTION 'PRIVACY_NOTICE_VERSION_INVALID';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.legal_documents WHERE document_type='terms' AND is_active AND version=new.terms_version AND content_hash=new.terms_hash) THEN
    RAISE EXCEPTION 'TERMS_VERSION_INVALID';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.legal_documents WHERE document_type='consent' AND is_active AND version=new.publication_consent_version AND content_hash=new.publication_consent_hash) THEN
    RAISE EXCEPTION 'PUBLICATION_CONSENT_VERSION_INVALID';
  END IF;
  IF tg_op = 'INSERT' OR old.privacy_notice_acknowledged IS NOT true THEN new.privacy_notice_acknowledged_at := v_now; END IF;
  IF tg_op = 'INSERT' OR old.terms_accepted IS NOT true THEN new.terms_accepted_at := v_now; END IF;
  IF tg_op = 'INSERT' OR old.publication_consent_accepted IS NOT true THEN
    new.publication_consent_accepted_at := v_now;
    new.publication_consent_withdrawn_at := null;
  END IF;
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION private.record_store_legal_events()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF new.privacy_notice_acknowledged AND (tg_op = 'INSERT' OR old.privacy_notice_acknowledged IS NOT true) THEN
    INSERT INTO public.legal_acceptance_events (store_slug, user_id, event_type, document_type, document_version, document_hash, occurred_at)
    VALUES (new.slug, new.user_id, 'privacy_notice_acknowledged', 'privacy', new.privacy_notice_version, new.privacy_notice_hash, new.privacy_notice_acknowledged_at);
  END IF;
  IF new.terms_accepted AND (tg_op = 'INSERT' OR old.terms_accepted IS NOT true) THEN
    INSERT INTO public.legal_acceptance_events (store_slug, user_id, event_type, document_type, document_version, document_hash, occurred_at)
    VALUES (new.slug, new.user_id, 'terms_accepted', 'terms', new.terms_version, new.terms_hash, new.terms_accepted_at);
  END IF;
  IF new.publication_consent_accepted AND (tg_op = 'INSERT' OR old.publication_consent_accepted IS NOT true) THEN
    INSERT INTO public.legal_acceptance_events (store_slug, user_id, event_type, document_type, document_version, document_hash, occurred_at)
    VALUES (new.slug, new.user_id, 'publication_consent_granted', 'consent', new.publication_consent_version, new.publication_consent_hash, new.publication_consent_accepted_at);
  END IF;
  IF tg_op = 'UPDATE' AND old.publication_consent_accepted AND new.publication_consent_accepted IS NOT true THEN
    INSERT INTO public.legal_acceptance_events (store_slug, user_id, event_type, document_type, document_version, document_hash, occurred_at)
    VALUES (new.slug, new.user_id, 'publication_consent_withdrawn', 'consent', old.publication_consent_version, old.publication_consent_hash, new.publication_consent_withdrawn_at);
  END IF;
  RETURN new;
END;
$$;

-- ============================================================================
-- 6. TRIGGER KAYITLARI
-- ============================================================================

DROP TRIGGER IF EXISTS trg_stores_updated_at ON public.stores;
CREATE TRIGGER trg_stores_updated_at BEFORE UPDATE ON public.stores FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_store_articles_updated_at ON public.store_articles;
CREATE TRIGGER trg_store_articles_updated_at BEFORE UPDATE ON public.store_articles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_store_articles_published_at ON public.store_articles;
CREATE TRIGGER trg_store_articles_published_at BEFORE UPDATE ON public.store_articles FOR EACH ROW EXECUTE FUNCTION public.set_published_at();

DROP TRIGGER IF EXISTS trg_store_articles_published_at_insert ON public.store_articles;
CREATE TRIGGER trg_store_articles_published_at_insert BEFORE INSERT ON public.store_articles FOR EACH ROW EXECUTE FUNCTION public.set_published_at_on_insert();

DROP TRIGGER IF EXISTS trg_set_legal_document_hash ON public.legal_documents;
CREATE TRIGGER trg_set_legal_document_hash BEFORE INSERT OR UPDATE ON public.legal_documents FOR EACH ROW EXECUTE FUNCTION private.set_legal_document_hash();

DROP TRIGGER IF EXISTS trg_validate_store_legal_acceptance ON public.stores;
CREATE TRIGGER trg_validate_store_legal_acceptance BEFORE INSERT OR UPDATE ON public.stores FOR EACH ROW EXECUTE FUNCTION private.validate_store_legal_acceptance();

DROP TRIGGER IF EXISTS trg_record_store_legal_events ON public.stores;
CREATE TRIGGER trg_record_store_legal_events AFTER INSERT OR UPDATE ON public.stores FOR EACH ROW EXECUTE FUNCTION private.record_store_legal_events();

DROP TRIGGER IF EXISTS trg_store_instagram_connections_updated_at ON public.store_instagram_connections;
CREATE TRIGGER trg_store_instagram_connections_updated_at BEFORE UPDATE ON public.store_instagram_connections FOR EACH ROW EXECUTE FUNCTION public.set_store_instagram_updated_at();

DROP TRIGGER IF EXISTS trg_store_instagram_tokens_updated_at ON public.store_instagram_tokens;
CREATE TRIGGER trg_store_instagram_tokens_updated_at BEFORE UPDATE ON public.store_instagram_tokens FOR EACH ROW EXECUTE FUNCTION public.set_store_instagram_updated_at();

DROP TRIGGER IF EXISTS trg_store_instagram_imports_updated_at ON public.store_instagram_imports;
CREATE TRIGGER trg_store_instagram_imports_updated_at BEFORE UPDATE ON public.store_instagram_imports FOR EACH ROW EXECUTE FUNCTION public.set_store_instagram_updated_at();

DROP TRIGGER IF EXISTS trg_article_before_save ON public.store_articles;
CREATE TRIGGER trg_article_before_save BEFORE INSERT OR UPDATE ON public.store_articles FOR EACH ROW EXECUTE FUNCTION public.on_article_before_save();

DROP TRIGGER IF EXISTS trg_article_approved ON public.store_articles;
CREATE TRIGGER trg_article_approved AFTER INSERT OR UPDATE ON public.store_articles FOR EACH ROW EXECUTE FUNCTION public.on_article_approved();

DROP TRIGGER IF EXISTS trg_article_spam_check ON public.store_articles;
CREATE TRIGGER trg_article_spam_check BEFORE INSERT OR UPDATE ON public.store_articles FOR EACH ROW EXECUTE FUNCTION public.on_article_spam_check();

-- ============================================================================
-- 7. RPC FONKSİYONLARI (PUBLIC REVOKE, kesin grant)
-- ============================================================================

-- 7.1 record_vitrin_view — C0 canlı güncel imza (p_store_slug, p_session_key, p_source)
CREATE OR REPLACE FUNCTION public.record_vitrin_view(
  p_store_slug text,
  p_session_key text,
  p_source text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, auth AS $$
BEGIN
  INSERT INTO public.vitrin_views(store_slug, session_key, source)
  VALUES (p_store_slug, p_session_key, p_source);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.record_vitrin_view(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_vitrin_view(text, text, text) TO anon, authenticated;

-- 7.2 get_today_vitrin_view_count — C0 canlı güncel imza (p_slug, p_edit_token)
CREATE OR REPLACE FUNCTION public.get_today_vitrin_view_count(
  p_slug text,
  p_edit_token text
) RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, auth AS $$
DECLARE v_count bigint;
BEGIN
  SELECT count(*) INTO v_count FROM public.vitrin_views v
  JOIN public.stores s ON s.slug = v.store_slug
  WHERE v.store_slug = p_slug
    AND v.created_at > now() - interval '24 hours'
    AND s.edit_token = p_edit_token;
  RETURN v_count;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_today_vitrin_view_count(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_today_vitrin_view_count(text, text) TO anon, authenticated;

-- 7.3 link_store_to_user
CREATE OR REPLACE FUNCTION public.link_store_to_user(p_edit_token text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, auth AS $$
DECLARE v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'UNAUTHORIZED'; END IF;
  UPDATE public.stores SET user_id = v_user_id WHERE edit_token = p_edit_token AND user_id IS NULL;
  RETURN found;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.link_store_to_user(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.link_store_to_user(text) TO authenticated;

-- 7.4 create_store_with_token
CREATE OR REPLACE FUNCTION public.create_store_with_token(
  p_slug text, p_edit_token text, p_store jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_user_id uuid := auth.uid();
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN RAISE EXCEPTION 'INVALID_SLUG'; END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN RAISE EXCEPTION 'INVALID_EDIT_TOKEN'; END IF;
  INSERT INTO public.stores (slug, edit_token, user_id, name, business_type, description, corporate_bio, whatsapp, instagram, website, address, theme, status, marketplace_links, gallery_items, products, product_categories, offerings, catalog_link, references_link, vcard_link, shelf_image_url, logo_url, working_hours, is_published, is_store, kategori, latitude, longitude, location_accuracy_meters, location_consented_at, location_source, province_code, province_name, district_code, district_name, google_business_link, privacy_notice_acknowledged, privacy_notice_version, privacy_notice_hash, terms_accepted, terms_version, terms_hash, publication_consent_accepted, publication_consent_version, publication_consent_hash, updated_at)
  VALUES (pg_catalog.btrim(p_slug), pg_catalog.btrim(p_edit_token), v_user_id,
    coalesce(p_store->>'name',''), coalesce(p_store->>'business_type',''), coalesce(p_store->>'description',''),
    coalesce(p_store->>'corporate_bio',''), coalesce(p_store->>'whatsapp',''), coalesce(p_store->>'instagram',''),
    coalesce(p_store->>'website',''), coalesce(p_store->>'address',''), coalesce(p_store->>'theme',''),
    coalesce(p_store->>'status',''), coalesce(p_store->'marketplace_links','[]'::jsonb),
    coalesce(p_store->'gallery_items','[]'::jsonb), coalesce(p_store->'products','[]'::jsonb),
    coalesce(p_store->'product_categories','[]'::jsonb), coalesce(p_store->'offerings','[]'::jsonb),
    coalesce(p_store->>'catalog_link',''), coalesce(p_store->>'references_link',''),
    coalesce(p_store->>'vcard_link',''), coalesce(p_store->>'shelf_image_url',''),
    coalesce(p_store->>'logo_url',''), coalesce(p_store->>'working_hours',''),
    true, coalesce((p_store->>'is_store')::boolean,false), coalesce(p_store->>'kategori',''),
    case when p_store ? 'latitude' AND nullif(p_store->>'latitude','') IS NOT NULL then (p_store->>'latitude')::float8 else null end,
    case when p_store ? 'longitude' AND nullif(p_store->>'longitude','') IS NOT NULL then (p_store->>'longitude')::float8 else null end,
    case when p_store ? 'location_accuracy_meters' AND nullif(p_store->>'location_accuracy_meters','') IS NOT NULL then (p_store->>'location_accuracy_meters')::float8 else null end,
    case when p_store ? 'location_consented_at' AND nullif(p_store->>'location_consented_at','') IS NOT NULL then (p_store->>'location_consented_at')::timestamptz else null end,
    p_store->>'location_source', coalesce(p_store->>'province_code',''), coalesce(p_store->>'province_name',''),
    coalesce(p_store->>'district_code',''), coalesce(p_store->>'district_name',''),
    coalesce(p_store->>'google_business_link',''),
    coalesce((p_store->>'privacy_notice_acknowledged')::boolean,false), coalesce(p_store->>'privacy_notice_version',''),
    coalesce(p_store->>'privacy_notice_hash',''), coalesce((p_store->>'terms_accepted')::boolean,false),
    coalesce(p_store->>'terms_version',''), coalesce(p_store->>'terms_hash',''),
    coalesce((p_store->>'publication_consent_accepted')::boolean,false),
    coalesce(p_store->>'publication_consent_version',''), coalesce(p_store->>'publication_consent_hash',''),
    pg_catalog.now());
END;
$$;
REVOKE EXECUTE ON FUNCTION public.create_store_with_token(text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_store_with_token(text, text, jsonb) TO anon, authenticated;

-- 7.5 update_store_with_token (güncel imza)
CREATE OR REPLACE FUNCTION public.update_store_with_token(
  p_slug text, p_edit_token text, p_store jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, auth AS $$
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN RAISE EXCEPTION 'INVALID_SLUG'; END IF;
  IF (select auth.uid()) IS NULL THEN
    -- Misafir/anon: token zorunlu ve ≥24 karakter olmalı
    IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN RAISE EXCEPTION 'INVALID_EDIT_TOKEN'; END IF;
  END IF;
  UPDATE public.stores SET
    name = coalesce(p_store->>'name', name), business_type = coalesce(p_store->>'business_type', business_type),
    description = coalesce(p_store->>'description', description), corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
    whatsapp = coalesce(p_store->>'whatsapp', whatsapp), instagram = coalesce(p_store->>'instagram', instagram),
    website = coalesce(p_store->>'website', website), address = coalesce(p_store->>'address', address),
    theme = coalesce(p_store->>'theme', theme), status = coalesce(p_store->>'status', status),
    marketplace_links = coalesce(p_store->'marketplace_links', marketplace_links),
    gallery_items = coalesce(p_store->'gallery_items', gallery_items),
    products = coalesce(p_store->'products', products),
    product_categories = coalesce(p_store->'product_categories', product_categories),
    offerings = coalesce(p_store->'offerings', offerings),
    catalog_link = coalesce(p_store->>'catalog_link', catalog_link),
    references_link = coalesce(p_store->>'references_link', references_link),
    vcard_link = coalesce(p_store->>'vcard_link', vcard_link),
    shelf_image_url = coalesce(nullif(p_store->>'shelf_image_url',''), shelf_image_url),
    logo_url = coalesce(nullif(p_store->>'logo_url',''), logo_url),
    working_hours = coalesce(p_store->>'working_hours', working_hours),
    is_published = true,
    is_store = coalesce((p_store->>'is_store')::boolean, is_store),
    kategori = coalesce(p_store->>'kategori', kategori),
    latitude = CASE WHEN p_store ? 'latitude' THEN (p_store->>'latitude')::float8 ELSE latitude END,
    longitude = CASE WHEN p_store ? 'longitude' THEN (p_store->>'longitude')::float8 ELSE longitude END,
    location_accuracy_meters = CASE WHEN p_store ? 'location_accuracy_meters' THEN (p_store->>'location_accuracy_meters')::float8 ELSE location_accuracy_meters END,
    location_consented_at = CASE WHEN p_store ? 'location_consented_at' THEN (p_store->>'location_consented_at')::timestamptz ELSE location_consented_at END,
    location_source = CASE WHEN p_store ? 'location_source' THEN p_store->>'location_source' ELSE location_source END,
    province_code = coalesce(p_store->>'province_code', province_code), province_name = coalesce(p_store->>'province_name', province_name),
    district_code = coalesce(p_store->>'district_code', district_code), district_name = coalesce(p_store->>'district_name', district_name),
    google_business_link = coalesce(p_store->>'google_business_link', google_business_link),
    privacy_notice_acknowledged = coalesce((p_store->>'privacy_notice_acknowledged')::boolean, privacy_notice_acknowledged),
    privacy_notice_version = coalesce(p_store->>'privacy_notice_version', privacy_notice_version),
    privacy_notice_hash = coalesce(p_store->>'privacy_notice_hash', privacy_notice_hash),
    terms_accepted = coalesce((p_store->>'terms_accepted')::boolean, terms_accepted),
    terms_version = coalesce(p_store->>'terms_version', terms_version),
    terms_hash = coalesce(p_store->>'terms_hash', terms_hash),
    publication_consent_accepted = coalesce((p_store->>'publication_consent_accepted')::boolean, publication_consent_accepted),
    publication_consent_version = coalesce(p_store->>'publication_consent_version', publication_consent_version),
    publication_consent_hash = coalesce(p_store->>'publication_consent_hash', publication_consent_hash),
    updated_at = pg_catalog.now()
  WHERE (slug = p_slug AND edit_token = p_edit_token AND edit_token <> '')
     OR (slug = p_slug AND (select auth.uid()) IS NOT NULL AND user_id = (select auth.uid()));
  IF NOT FOUND THEN RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH' USING errcode = 'P0001'; END IF;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) TO anon, authenticated;

-- 7.6 delete_store_with_token
CREATE OR REPLACE FUNCTION public.delete_store_with_token(
  p_slug text, p_edit_token text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_slug text := pg_catalog.btrim(p_slug); v_store_id uuid;
BEGIN
  SELECT id INTO v_store_id FROM public.stores WHERE slug = v_slug
    AND (edit_token = pg_catalog.btrim(p_edit_token)
         OR ((select auth.uid()) IS NOT NULL AND user_id = (select auth.uid())));
  IF v_store_id IS NULL THEN RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH'; END IF;
  DELETE FROM public.store_instagram_imports WHERE store_slug = v_slug OR connection_id IN (SELECT id FROM public.store_instagram_connections WHERE store_slug = v_slug);
  DELETE FROM public.store_instagram_tokens WHERE connection_id IN (SELECT id FROM public.store_instagram_connections WHERE store_slug = v_slug);
  DELETE FROM public.store_instagram_connections WHERE store_slug = v_slug;
  DELETE FROM public.vitrin_views WHERE store_slug = v_slug;
  DELETE FROM public.store_category_image_usage WHERE store_id = v_store_id;
  DELETE FROM public.booking_settings WHERE store_slug = v_slug;
  DELETE FROM public.store_articles WHERE store_slug = v_slug;
  DELETE FROM public.appointments WHERE store_slug = v_slug;
  DELETE FROM public.stores WHERE id = v_store_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.delete_store_with_token(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_store_with_token(text, text) TO anon, authenticated;

-- 7.7 withdraw_store_publication_consent
CREATE OR REPLACE FUNCTION public.withdraw_store_publication_consent(
  p_slug text, p_edit_token text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF p_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 THEN RAISE EXCEPTION 'INVALID_SLUG'; END IF;
  IF (select auth.uid()) IS NULL THEN
    -- Misafir/anon: token zorunlu ve ≥24 karakter olmalı
    IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN RAISE EXCEPTION 'INVALID_EDIT_TOKEN'; END IF;
  END IF;
  UPDATE public.stores SET is_published = false, publication_consent_accepted = false,
    publication_consent_withdrawn_at = pg_catalog.now(), updated_at = pg_catalog.now()
  WHERE slug = p_slug
    AND (edit_token = p_edit_token AND edit_token <> ''
         OR ((select auth.uid()) IS NOT NULL AND user_id = (select auth.uid())));
  IF NOT FOUND THEN RAISE EXCEPTION 'EDIT_TOKEN_MISMATCH' USING errcode = 'P0001'; END IF;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text) TO anon, authenticated;

-- 7.8 consume_assistant_request — service_role ONLY
CREATE OR REPLACE FUNCTION public.consume_assistant_request(
  p_client_key text, p_max_requests integer DEFAULT 6
) RETURNS TABLE(allowed boolean, retry_after_seconds integer) LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_window timestamptz; v_count integer;
BEGIN
  INSERT INTO public.assistant_rate_limits AS limits (client_key, window_started_at, request_count, updated_at)
  VALUES (p_client_key, now(), 1, now())
  ON CONFLICT (client_key) DO UPDATE SET
    window_started_at = CASE WHEN limits.window_started_at <= now() - interval '1 minute' THEN now() ELSE limits.window_started_at END,
    request_count = CASE WHEN limits.window_started_at <= now() - interval '1 minute' THEN 1 ELSE limits.request_count + 1 END,
    updated_at = now()
  RETURNING window_started_at, request_count INTO v_window, v_count;
  RETURN QUERY SELECT v_count <= p_max_requests, greatest(0, ceil(extract(epoch from (v_window + interval '1 minute' - now())))::integer);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.consume_assistant_request(text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.consume_assistant_request(text, integer) TO service_role;

-- 7.9 get_public_booking_slots
CREATE OR REPLACE FUNCTION public.get_public_booking_slots(p_store_slug text, p_date date)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_settings public.booking_settings%rowtype; v_dow text; v_hours jsonb; v_start_str text; v_end_str text; v_lunch_active boolean; v_lunch_start time; v_lunch_end time; v_slot timestamptz; v_end_limit timestamptz; v_capacity int; v_slot_time time; v_blocked boolean; v_active_count int; v_confirmed_names text[]; v_has_pending boolean; v_slots_result jsonb := '[]'::jsonb; v_appt record;
BEGIN
  SELECT * INTO v_settings FROM public.booking_settings WHERE store_slug = p_store_slug;
  IF NOT found OR NOT v_settings.is_enabled THEN RETURN '[]'::jsonb; END IF;
  v_capacity := v_settings.capacity;
  v_dow := extract(isodow from p_date)::text;
  v_hours := v_settings.working_hours->v_dow;
  IF v_hours IS NULL OR NOT (v_hours->>'active')::boolean THEN RETURN '[]'::jsonb; END IF;
  v_start_str := v_hours->>'start'; v_end_str := v_hours->>'end';
  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  IF v_lunch_active THEN v_lunch_start := (v_settings.lunch_break->>'start')::time; v_lunch_end := (v_settings.lunch_break->>'end')::time; END IF;
  v_slot := (p_date::text || ' ' || v_start_str)::timestamptz;
  v_end_limit := (p_date::text || ' ' || v_end_str)::timestamptz;
  WHILE v_slot < v_end_limit LOOP
    v_slot_time := v_slot::time;
    IF v_lunch_active AND v_slot_time >= v_lunch_start AND v_slot_time < v_lunch_end THEN v_blocked := true;
    ELSE SELECT EXISTS (SELECT 1 FROM public.booking_blocks WHERE store_slug = p_store_slug AND block_date = p_date AND ((start_time IS NULL AND end_time IS NULL) OR (v_slot_time >= start_time AND v_slot_time < end_time))) INTO v_blocked; END IF;
    IF NOT v_blocked THEN
      v_active_count := 0; v_confirmed_names := '{}'::text[]; v_has_pending := false;
      FOR v_appt IN (SELECT customer_name, status, service_duration, appointment_time FROM public.appointments WHERE store_slug = p_store_slug AND status IN ('pending','confirmed') AND (status='confirmed' OR expires_at > now()) AND appointment_time <= v_slot AND v_slot < appointment_time + (service_duration || ' minutes')::interval) LOOP
        v_active_count := v_active_count + 1;
        IF v_appt.status = 'confirmed' THEN v_confirmed_names := array_append(v_confirmed_names, public.mask_appointment_name(v_appt.customer_name)); ELSE v_has_pending := true; END IF;
      END LOOP;
      v_slots_result := v_slots_result || jsonb_build_array(jsonb_build_object('time', to_char(v_slot_time,'HH24:MI'), 'capacity_total', v_capacity, 'capacity_used', v_active_count, 'slots_left', greatest(0, v_capacity - v_active_count), 'confirmed_names', to_jsonb(v_confirmed_names), 'has_pending', v_has_pending));
    END IF;
    v_slot := v_slot + interval '15 minutes';
  END LOOP;
  RETURN v_slots_result;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_public_booking_slots(text, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_booking_slots(text, date) TO anon, authenticated;

-- 7.10 create_appointment_request
CREATE OR REPLACE FUNCTION public.create_appointment_request(
  p_store_slug text, p_customer_name text, p_customer_phone text, p_customer_notes text,
  p_service_title text, p_service_price text, p_service_duration int, p_appointment_time timestamptz
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_settings public.booking_settings%rowtype; v_lock_ok boolean; v_daily_count int; v_plaintext_token text; v_token_hash text; v_appt_id uuid; v_appt_end timestamptz; v_slot timestamptz; v_active_count int; v_dow text; v_hours jsonb; v_start_time time; v_end_time time; v_lunch_active boolean; v_lunch_start time; v_lunch_end time; v_slot_time time; v_blocked boolean;
BEGIN
  SELECT count(*) INTO v_daily_count FROM public.appointments WHERE customer_phone = p_customer_phone AND created_at > now() - interval '24 hours';
  IF v_daily_count >= 5 THEN RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED'; END IF;
  SELECT pg_try_advisory_xact_lock(hashtext(p_store_slug)) INTO v_lock_ok;
  IF NOT v_lock_ok THEN RAISE EXCEPTION 'STORE_BUSY_TRY_AGAIN'; END IF;
  SELECT * INTO v_settings FROM public.booking_settings WHERE store_slug = p_store_slug;
  IF NOT found OR NOT v_settings.is_enabled THEN RAISE EXCEPTION 'BOOKING_DISABLED'; END IF;
  v_dow := extract(isodow from p_appointment_time)::text;
  v_hours := v_settings.working_hours->v_dow;
  IF v_hours IS NULL OR NOT (v_hours->>'active')::boolean THEN RAISE EXCEPTION 'STORE_CLOSED_ON_THIS_DAY'; END IF;
  v_start_time := (v_hours->>'start')::time; v_end_time := (v_hours->>'end')::time; v_slot_time := p_appointment_time::time;
  IF v_slot_time < v_start_time OR v_slot_time >= v_end_time THEN RAISE EXCEPTION 'OUTSIDE_WORKING_HOURS'; END IF;
  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  IF v_lunch_active THEN v_lunch_start := (v_settings.lunch_break->>'start')::time; v_lunch_end := (v_settings.lunch_break->>'end')::time;
    IF v_slot_time >= v_lunch_start AND v_slot_time < v_lunch_end THEN RAISE EXCEPTION 'LUNCH_BREAK_BLOCK'; END IF;
  END IF;
  SELECT EXISTS (SELECT 1 FROM public.booking_blocks WHERE store_slug = p_store_slug AND block_date = p_appointment_time::date AND ((start_time IS NULL AND end_time IS NULL) OR (v_slot_time >= start_time AND v_slot_time < end_time))) INTO v_blocked;
  IF v_blocked THEN RAISE EXCEPTION 'DATE_TIME_BLOCKED'; END IF;
  v_appt_end := p_appointment_time + (p_service_duration || ' minutes')::interval; v_slot := p_appointment_time;
  WHILE v_slot < v_appt_end LOOP
    SELECT count(*) INTO v_active_count FROM public.appointments WHERE store_slug = p_store_slug AND status IN ('pending','confirmed') AND (status='confirmed' OR expires_at > now()) AND appointment_time <= v_slot AND v_slot < appointment_time + (service_duration || ' minutes')::interval;
    IF v_active_count >= v_settings.capacity THEN RAISE EXCEPTION 'CAPACITY_FULL'; END IF;
    v_slot := v_slot + interval '15 minutes';
  END LOOP;
  v_plaintext_token := encode(gen_random_bytes(16), 'hex');
  v_token_hash := encode(sha256(v_plaintext_token::bytea), 'hex');
  v_appt_id := gen_random_uuid();
  INSERT INTO public.appointments (id, store_slug, customer_name, customer_phone, customer_notes, service_title, service_price, service_duration, appointment_time, status, token_hash, expires_at)
  VALUES (v_appt_id, p_store_slug, trim(p_customer_name), trim(p_customer_phone), trim(p_customer_notes), trim(p_service_title), trim(p_service_price), p_service_duration, p_appointment_time, 'pending', v_token_hash, now() + interval '2 hours');
  RETURN jsonb_build_object('appointment_id', v_appt_id, 'token', v_plaintext_token);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.create_appointment_request(text,text,text,text,text,text,int,timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_appointment_request(text,text,text,text,text,text,int,timestamptz) TO anon, authenticated;

-- 7.11 get_appointment_by_token
CREATE OR REPLACE FUNCTION public.get_appointment_by_token(p_token text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_token_hash text; v_appt record; v_resched record;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');
  SELECT a.*, s.name AS store_name INTO v_appt FROM public.appointments a JOIN public.stores s ON s.slug = a.store_slug WHERE a.token_hash = v_token_hash;
  IF NOT found THEN RETURN null; END IF;
  SELECT * INTO v_resched FROM public.appointment_reschedule_requests WHERE appointment_id = v_appt.id AND status = 'pending' ORDER BY created_at DESC LIMIT 1;
  RETURN jsonb_build_object('id',v_appt.id,'store_slug',v_appt.store_slug,'store_name',v_appt.store_name,'customer_name',v_appt.customer_name,'customer_phone',v_appt.customer_phone,'customer_notes',v_appt.customer_notes,'service_title',v_appt.service_title,'service_price',v_appt.service_price,'service_duration',v_appt.service_duration,'appointment_time',v_appt.appointment_time,'status',v_appt.status,'created_at',v_appt.created_at,'expires_at',v_appt.expires_at,
    'reschedule_request', CASE WHEN v_resched.id IS NOT NULL THEN jsonb_build_object('id',v_resched.id,'requested_time',v_resched.requested_time,'status',v_resched.status) ELSE null END);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_appointment_by_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_appointment_by_token(text) TO anon, authenticated;

-- 7.12 cancel_appointment_by_token
CREATE OR REPLACE FUNCTION public.cancel_appointment_by_token(p_token text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_token_hash text;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');
  UPDATE public.appointments SET status = 'cancelled_by_customer' WHERE token_hash = v_token_hash AND status IN ('pending','confirmed');
  RETURN found;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.cancel_appointment_by_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_appointment_by_token(text) TO anon, authenticated;

-- 7.13 request_appointment_reschedule
CREATE OR REPLACE FUNCTION public.request_appointment_reschedule(p_token text, p_new_time timestamptz)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_token_hash text; v_appt public.appointments%rowtype; v_settings public.booking_settings%rowtype; v_appt_end timestamptz; v_slot timestamptz; v_active_count int; v_lock_ok boolean;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');
  SELECT * INTO v_appt FROM public.appointments WHERE token_hash = v_token_hash;
  IF NOT found OR v_appt.status NOT IN ('pending','confirmed') THEN RAISE EXCEPTION 'APPOINTMENT_NOT_ACTIVE'; END IF;
  SELECT pg_try_advisory_xact_lock(hashtext(v_appt.store_slug)) INTO v_lock_ok;
  IF NOT v_lock_ok THEN RAISE EXCEPTION 'STORE_BUSY_TRY_AGAIN'; END IF;
  SELECT * INTO v_settings FROM public.booking_settings WHERE store_slug = v_appt.store_slug;
  IF NOT found OR NOT v_settings.is_enabled THEN RAISE EXCEPTION 'BOOKING_DISABLED'; END IF;
  v_appt_end := p_new_time + (v_appt.service_duration || ' minutes')::interval; v_slot := p_new_time;
  WHILE v_slot < v_appt_end LOOP
    SELECT count(*) INTO v_active_count FROM public.appointments WHERE store_slug = v_appt.store_slug AND id <> v_appt.id AND status IN ('pending','confirmed') AND (status='confirmed' OR expires_at > now()) AND appointment_time <= v_slot AND v_slot < appointment_time + (service_duration || ' minutes')::interval;
    IF v_active_count >= v_settings.capacity THEN RAISE EXCEPTION 'CAPACITY_FULL'; END IF;
    v_slot := v_slot + interval '15 minutes';
  END LOOP;
  UPDATE public.appointment_reschedule_requests SET status = 'rejected' WHERE appointment_id = v_appt.id AND status = 'pending';
  INSERT INTO public.appointment_reschedule_requests (appointment_id, requested_time, status) VALUES (v_appt.id, p_new_time, 'pending');
  RETURN true;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.request_appointment_reschedule(text, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_appointment_reschedule(text, timestamptz) TO anon, authenticated;

-- 7.14 respond_to_appointment
CREATE OR REPLACE FUNCTION public.respond_to_appointment(p_appointment_id uuid, p_action text, p_reschedule_action text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_appt public.appointments%rowtype; v_resched public.appointment_reschedule_requests%rowtype; v_is_owner boolean;
BEGIN
  SELECT * INTO v_appt FROM public.appointments WHERE id = p_appointment_id;
  IF NOT found THEN RAISE EXCEPTION 'APPOINTMENT_NOT_FOUND'; END IF;
  SELECT EXISTS (SELECT 1 FROM public.stores WHERE slug = v_appt.store_slug AND user_id = auth.uid()) INTO v_is_owner;
  IF NOT v_is_owner THEN RAISE EXCEPTION 'UNAUTHORIZED'; END IF;
  IF p_action IS NOT NULL THEN
    IF p_action = 'confirm' THEN UPDATE public.appointments SET status = 'confirmed', expires_at = '9999-12-31 23:59:59+00'::timestamptz WHERE id = p_appointment_id;
    ELSIF p_action = 'reject' THEN UPDATE public.appointments SET status = 'rejected' WHERE id = p_appointment_id;
    ELSE RAISE EXCEPTION 'INVALID_ACTION'; END IF;
    RETURN true;
  END IF;
  IF p_reschedule_action IS NOT NULL THEN
    SELECT * INTO v_resched FROM public.appointment_reschedule_requests WHERE appointment_id = p_appointment_id AND status = 'pending' ORDER BY created_at DESC LIMIT 1;
    IF NOT found THEN RAISE EXCEPTION 'NO_PENDING_RESCHEDULE'; END IF;
    IF p_reschedule_action = 'approve' THEN
      UPDATE public.appointment_reschedule_requests SET status = 'approved' WHERE id = v_resched.id;
      UPDATE public.appointments SET appointment_time = v_resched.requested_time, status = 'confirmed', expires_at = '9999-12-31 23:59:59+00'::timestamptz WHERE id = p_appointment_id;
    ELSIF p_reschedule_action = 'reject' THEN UPDATE public.appointment_reschedule_requests SET status = 'rejected' WHERE id = v_resched.id;
    ELSE RAISE EXCEPTION 'INVALID_ACTION'; END IF;
    RETURN true;
  END IF;
  RETURN false;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.respond_to_appointment(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.respond_to_appointment(uuid, text, text) TO authenticated;

-- 7.15 apply_category_template (7-param, auth.uid() + edit_token ownership gate)
CREATE OR REPLACE FUNCTION public.apply_category_template(
  p_store_id uuid,
  p_category_key text,
  p_fill_cover boolean DEFAULT true,
  p_fill_logo boolean DEFAULT true,
  p_fill_gallery boolean DEFAULT true,
  p_fill_products boolean DEFAULT true,
  p_edit_token text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb := '{}'::jsonb;
  v_image_row record;
  v_current_cover text;
  v_current_logo text;
  v_current_gallery jsonb;
  v_current_products jsonb;
  v_gallery_items jsonb := '[]'::jsonb;
  v_template_products jsonb := '[]'::jsonb;
  v_applied_count int := 0;
  v_authorized boolean := false;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.stores s
    WHERE s.id = p_store_id
      AND (
        (auth.uid() IS NOT NULL AND s.user_id = auth.uid())
        OR (
          pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
          AND s.edit_token = pg_catalog.btrim(p_edit_token)
        )
      )
  ) INTO v_authorized;

  IF NOT v_authorized THEN
    RAISE EXCEPTION 'STORE_UPDATE_NOT_ALLOWED' USING errcode = 'P0001';
  END IF;

  SELECT shelf_image_url, logo_url, gallery_items, products
  INTO v_current_cover, v_current_logo, v_current_gallery, v_current_products
  FROM public.stores
  WHERE id = p_store_id;

  IF p_fill_cover THEN
    SELECT image_url INTO v_image_row
    FROM public.category_image_templates
    WHERE category_key = p_category_key AND image_type = 'cover' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_cover IS NULL OR v_current_cover = '') THEN
      UPDATE public.stores SET shelf_image_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"cover": true}'::jsonb;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_logo THEN
    SELECT image_url INTO v_image_row
    FROM public.category_image_templates
    WHERE category_key = p_category_key AND image_type = 'logo_placeholder' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_logo IS NULL OR v_current_logo = '') THEN
      UPDATE public.stores SET logo_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"logo": true}'::jsonb;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_gallery THEN
    IF v_current_gallery IS NULL OR jsonb_array_length(v_current_gallery) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'imageUrl', image_url,
          'title', coalesce(title, 'Gorsel')
        ) ORDER BY display_order
      )
      INTO v_gallery_items
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND image_type = 'gallery' AND is_active = true;

      IF v_gallery_items IS NOT NULL AND jsonb_array_length(v_gallery_items) > 0 THEN
        UPDATE public.stores SET gallery_items = v_gallery_items WHERE id = p_store_id;
        v_result := v_result || '{"gallery": true}'::jsonb;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  IF p_fill_products THEN
    IF v_current_products IS NULL OR jsonb_array_length(v_current_products) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', gen_random_uuid(),
          'name', coalesce(title, 'Urun'),
          'description', '',
          'price', '',
          'imageUrls', jsonb_build_array(image_url),
          'isVisible', true,
          'source', 'category_template'
        ) ORDER BY display_order
      )
      INTO v_template_products
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND image_type = 'product' AND is_active = true;

      IF v_template_products IS NOT NULL AND jsonb_array_length(v_template_products) > 0 THEN
        UPDATE public.stores SET products = v_template_products WHERE id = p_store_id;
        v_result := v_result || '{"products": true}'::jsonb;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  IF v_applied_count > 0 THEN
    INSERT INTO public.store_category_image_usage (store_id, category_key, images_used)
    VALUES (
      p_store_id,
      p_category_key,
      coalesce(
        (
          SELECT jsonb_agg(image_url)
          FROM public.category_image_templates
          WHERE category_key = p_category_key AND is_active = true
        ),
        '[]'::jsonb
      )
    )
    ON CONFLICT (store_id) DO UPDATE SET
      category_key = EXCLUDED.category_key,
      images_used = EXCLUDED.images_used,
      applied_at = pg_catalog.now();
  END IF;

  RETURN v_result || jsonb_build_object(
    'success', v_applied_count > 0,
    'image_count', (
      SELECT count(*)::int
      FROM public.category_image_templates
      WHERE category_key = p_category_key AND is_active = true
    )
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.apply_category_template(uuid, text, boolean, boolean, boolean, boolean, text)
FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_category_template(uuid, text, boolean, boolean, boolean, boolean, text)
TO anon, authenticated;

-- Eski 6-arg imza varsa gerçekten kaldır
DROP FUNCTION IF EXISTS public.apply_category_template(uuid, text, boolean, boolean, boolean, boolean);

-- 7.16 check_and_increment_ocr_usage KALDIRILDI — OCR tabloları post-baseline'da.

-- ============================================================================
-- 8. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vitrin_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_reschedule_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meta_data_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_instagram_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_instagram_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_instagram_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_acceptance_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assistant_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.category_image_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_category_image_usage ENABLE ROW LEVEL SECURITY;

-- vitrin_views: deny direct
CREATE POLICY "Deny direct access to public.vitrin_views" ON public.vitrin_views FOR ALL TO public USING (false) WITH CHECK (false);

-- stores
CREATE POLICY "Allow public read stores" ON public.stores FOR SELECT TO anon, authenticated USING (is_published = true);
CREATE POLICY "Authenticated users can create stores" ON public.stores FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update their own stores" ON public.stores FOR UPDATE TO authenticated USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Owners can delete their stores" ON public.stores FOR DELETE TO authenticated USING ((select auth.uid()) = user_id);
CREATE POLICY "Store owners can read their stores" ON public.stores FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);

-- legal_documents
CREATE POLICY "Active legal documents are publicly readable" ON public.legal_documents FOR SELECT TO anon, authenticated USING (is_active = true);

-- booking_settings
CREATE POLICY "Allow public read booking settings" ON public.booking_settings FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow owners to insert booking settings" ON public.booking_settings FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));
CREATE POLICY "Allow owners to update booking settings" ON public.booking_settings FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid()))) WITH CHECK (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));

-- booking_blocks (public read kaldırıldı — slot RPC üzerinden okunuyor)
CREATE POLICY "Allow owners to manage booking blocks" ON public.booking_blocks FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = booking_blocks.store_slug AND s.user_id = (select auth.uid()))) WITH CHECK (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = booking_blocks.store_slug AND s.user_id = (select auth.uid())));

-- appointments
CREATE POLICY "Owners can view their store appointments" ON public.appointments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));
CREATE POLICY "Owners can update their store appointments" ON public.appointments FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid()))) WITH CHECK (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));

-- store_articles
CREATE POLICY "Anyone can read published articles" ON public.store_articles FOR SELECT TO anon, authenticated USING (status = 'published');
CREATE POLICY "Owners can read all their own articles" ON public.store_articles FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));
CREATE POLICY "Owners can insert their own articles" ON public.store_articles FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));
CREATE POLICY "Owners can update their own articles" ON public.store_articles FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid()))) WITH CHECK (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));
CREATE POLICY "Owners can delete their own articles" ON public.store_articles FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.slug = store_slug AND s.user_id = (select auth.uid())));

-- category_image_templates
CREATE POLICY "category_templates_select_public" ON public.category_image_templates FOR SELECT TO anon, authenticated USING (true);

-- store_category_image_usage
CREATE POLICY "store_cat_usage_owner_select" ON public.store_category_image_usage FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.user_id = (select auth.uid())));
CREATE POLICY "store_cat_usage_owner_insert" ON public.store_category_image_usage FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.stores s WHERE s.id = store_id AND s.user_id = (select auth.uid())));

-- ============================================================================
-- 9. GRANT (table-level)
-- ============================================================================

-- stores (column-level — edit_token excluded)
GRANT SELECT (
  id, slug, name, business_type, description, corporate_bio, whatsapp, instagram, website, address,
  theme, status, marketplace_links, gallery_items, products, product_categories, offerings,
  catalog_link, references_link, vcard_link, shelf_image_url, logo_url, working_hours,
  is_published, is_store, kategori, latitude, longitude, location_accuracy_meters,
  location_consented_at, location_source, province_code, province_name, district_code,
  district_name, google_business_link, is_blog_trusted, user_id, created_at, updated_at, published_at
) ON public.stores TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.stores TO authenticated;

-- booking_settings
GRANT SELECT ON public.booking_settings TO anon, authenticated;
GRANT INSERT, UPDATE ON public.booking_settings TO authenticated;

-- booking_blocks (public SELECT kaldırıldı; authenticated ALL WITH CHECK ile)
GRANT ALL ON public.booking_blocks TO authenticated;

-- appointments (owner-only RLS ile anon SELECT engellenir; least-privilege)
GRANT SELECT ON public.appointments TO authenticated;
GRANT UPDATE ON public.appointments TO authenticated;

-- store_articles
GRANT SELECT ON public.store_articles TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.store_articles TO authenticated;

-- store_instagram_connections (policy yok → RLS deny; SELECT grant inert)
-- store_instagram_tokens — (no direct access)
-- store_instagram_imports — (policy yok → RLS deny; SELECT grant inert)

-- legal_documents
GRANT SELECT ON public.legal_documents TO anon, authenticated;

-- category_image_templates
GRANT SELECT ON public.category_image_templates TO anon, authenticated;

-- store_category_image_usage
GRANT SELECT ON public.store_category_image_usage TO authenticated;

-- assistant_rate_limits
-- (no direct access — service_role only via RPC)

-- article_reports
-- (no direct INSERT — doğrudan istemciden yazılmıyor)

-- vitrin_views
-- (no direct access — RPC only via deny-all policy)

-- meta_data_deletion_requests
-- (service_role only)

-- legal_acceptance_events
-- (service_role only)

-- appointment_reschedule_requests
-- (access via RPC only)

-- ============================================================================
-- 10. STORAGE POLICIES (P0 + P1 hardened)
-- ============================================================================

-- Public listing KAPALI — nesne URL'leri public bucket ile çalışmaya devam eder
DROP POLICY IF EXISTS "Allow public shelf image reads" ON storage.objects;
DROP POLICY IF EXISTS "Public can read shelf images" ON storage.objects;
DROP POLICY IF EXISTS "category_templates_storage_public" ON storage.objects;

-- Anon scoped upload: slug/gallery, slug/products/{id}, slug pattern
DROP POLICY IF EXISTS "Anon can upload scoped shelf images" ON storage.objects;
CREATE POLICY "Anon can upload scoped shelf images"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
  bucket_id = 'shelf-images'
  AND name ~ '^[a-z0-9]+(-[a-z0-9]+)*((/gallery)|(/products/[a-z0-9_-]+))?/[0-9]{10,}\.(jpg|png|webp)$'
);

-- Authenticated owner upload: objects.name ile path netleştirildi
DROP POLICY IF EXISTS "Authenticated users can upload shelf images" ON storage.objects;
CREATE POLICY "Authenticated users can upload shelf images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'shelf-images'
  AND objects.name ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
  AND (
    EXISTS (
      SELECT 1 FROM public.stores
      WHERE stores.slug = split_part(objects.name, '/', 1)
        AND stores.user_id = (select auth.uid())
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.stores
      WHERE stores.slug = split_part(objects.name, '/', 1)
    )
  )
);

-- Authenticated owner delete: objects.name (storage path) kullanılmalı
DROP POLICY IF EXISTS "Users can delete their own shelf images" ON storage.objects;
CREATE POLICY "Users can delete their own shelf images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'shelf-images'
  AND EXISTS (
    SELECT 1 FROM public.stores
    WHERE stores.slug = split_part(objects.name, '/', 1)
      AND stores.user_id = (select auth.uid())
  )
);
