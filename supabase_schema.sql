-- ============================================================================
-- Supabase Unified Database Schema (VixRex Platform)
-- Bootstraps all tables, indexes, triggers, storage configs, policies, & RPCs.
-- ============================================================================

-- 1. EXTENSIONS & CONFIG
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. CORE TABLES
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
  location_consent_at TIMESTAMPTZ,
  location_source TEXT,
  province_code TEXT,
  province_name TEXT,
  district_code TEXT,
  district_name TEXT,
  google_business_link TEXT,
  is_blog_trusted BOOLEAN DEFAULT false,
  
  -- Legal Acceptances fields
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
COMMENT ON COLUMN public.stores.location_consent_at IS 'Timestamp when the user provided KVKK consent to share their location.';
COMMENT ON COLUMN public.stores.location_source IS 'Source platform/device from which location was retrieved (e.g., ''geolocator'').';

CREATE TABLE IF NOT EXISTS public.vitrin_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  viewer_ip TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.legal_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_type TEXT NOT NULL CHECK (
    document_type IN ('privacy', 'terms', 'consent', 'dataDeletion')
  ),
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
ON public.legal_documents (document_type)
WHERE is_active;

CREATE TABLE IF NOT EXISTS public.admins (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 3. DEPENDENT TABLES
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
    "6": {"start": "09:00", "end": "16:00", "active": true},
    "7": {"start": "00:00", "end": "00:00", "active": false}
  }'::jsonb,
  lunch_break JSONB DEFAULT '{"start": "12:00", "end": "13:00", "active": true}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.booking_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  block_date DATE NOT NULL,
  start_time TIME WITHOUT TIME ZONE,
  end_time TIME WITHOUT TIME ZONE,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS public.appointment_reschedule_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  requested_time TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending' CONSTRAINT check_reschedule_status CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS public.article_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.store_articles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (length(btrim(reason)) > 0),
  reporter_ip TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS public.store_instagram_tokens (
  connection_id UUID PRIMARY KEY REFERENCES public.store_instagram_connections(id) ON DELETE CASCADE,
  access_token_ciphertext TEXT NOT NULL,
  token_type TEXT NOT NULL DEFAULT 'bearer',
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS public.category_image_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_key TEXT NOT NULL,
  category_label TEXT NOT NULL,
  image_type TEXT NOT NULL CHECK (image_type IN ('cover','logo_placeholder','gallery','product')),
  image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  title TEXT,
  description TEXT,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.store_category_image_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  category_key TEXT NOT NULL,
  images_used JSONB NOT NULL DEFAULT '[]',
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Core Indexes
CREATE INDEX IF NOT EXISTS idx_appointments_store_time ON public.appointments(store_slug, appointment_time);
CREATE INDEX IF NOT EXISTS idx_appointments_token_hash ON public.appointments(token_hash);
CREATE INDEX IF NOT EXISTS idx_booking_blocks_store_date ON public.booking_blocks(store_slug, block_date);
CREATE INDEX IF NOT EXISTS idx_store_instagram_connections_store ON public.store_instagram_connections (store_slug);
CREATE INDEX IF NOT EXISTS idx_store_instagram_connections_user ON public.store_instagram_connections (user_id);
CREATE INDEX IF NOT EXISTS idx_store_instagram_imports_store ON public.store_instagram_imports (store_slug, imported_at DESC);
CREATE INDEX IF NOT EXISTS idx_store_articles_published ON public.store_articles (store_slug, status, published_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_cat_templates_key ON public.category_image_templates(category_key);
CREATE INDEX IF NOT EXISTS idx_cat_templates_type ON public.category_image_templates(image_type);
CREATE INDEX IF NOT EXISTS idx_cat_templates_active ON public.category_image_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_store_cat_usage_store ON public.store_category_image_usage(store_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_store_cat_usage_store_unique ON public.store_category_image_usage(store_id);
CREATE INDEX IF NOT EXISTS legal_acceptance_events_store_slug_idx ON public.legal_acceptance_events (store_slug, occurred_at DESC);

-- 4. STORAGE BUCKETS
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'shelf-images') THEN
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('shelf-images', 'shelf-images', true, 15728640, ARRAY['image/jpeg', 'image/png', 'image/webp']);
  ELSE
    UPDATE storage.buckets
    SET public = true, file_size_limit = 15728640, allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
    WHERE id = 'shelf-images';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'category-templates') THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('category-templates', 'category-templates', true);
  END IF;
END $$;

-- 5. FUNCTIONS & TRIGGERS
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.mask_appointment_name(p_name text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
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

CREATE OR REPLACE FUNCTION public.set_published_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'published' AND (OLD.status IS DISTINCT FROM 'published') THEN
    NEW.published_at = COALESCE(NEW.published_at, now());
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_published_at_on_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'published' AND NEW.published_at IS NULL THEN
    NEW.published_at = now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.set_legal_document_hash()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
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
    new.document_type || '|' ||
    new.version || '|' ||
    new.title || '|' ||
    new.subtitle || '|' ||
    new.sections::text
  );
  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION private.validate_store_legal_acceptance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_now timestamptz := pg_catalog.now();
BEGIN
  if tg_op = 'UPDATE'
    and old.publication_consent_accepted
    and new.publication_consent_accepted is not true
    and new.publication_consent_withdrawn_at is null then
    new.publication_consent_withdrawn_at := v_now;
  end if;

  if new.is_published is not true then
    return new;
  end if;

  if new.privacy_notice_acknowledged is not true then
    raise exception 'PRIVACY_NOTICE_REQUIRED';
  end if;
  if new.terms_accepted is not true then
    raise exception 'TERMS_ACCEPTANCE_REQUIRED';
  end if;
  if new.publication_consent_accepted is not true then
    raise exception 'PUBLICATION_CONSENT_REQUIRED';
  end if;

  if not exists (
    select 1 from public.legal_documents d
    where d.document_type = 'privacy'
      and d.is_active
      and d.version = new.privacy_notice_version
      and d.content_hash = new.privacy_notice_hash
  ) then
    raise exception 'PRIVACY_NOTICE_VERSION_INVALID';
  end if;

  if not exists (
    select 1 from public.legal_documents d
    where d.document_type = 'terms'
      and d.is_active
      and d.version = new.terms_version
      and d.content_hash = new.terms_hash
  ) then
    raise exception 'TERMS_VERSION_INVALID';
  end if;

  if not exists (
    select 1 from public.legal_documents d
    where d.document_type = 'consent'
      and d.is_active
      and d.version = new.publication_consent_version
      and d.content_hash = new.publication_consent_hash
  ) then
    raise exception 'PUBLICATION_CONSENT_VERSION_INVALID';
  end if;

  if tg_op = 'INSERT'
    or old.privacy_notice_acknowledged is not true
    or old.privacy_notice_version is distinct from new.privacy_notice_version
    or old.privacy_notice_hash is distinct from new.privacy_notice_hash then
    new.privacy_notice_acknowledged_at := v_now;
  end if;

  if tg_op = 'INSERT'
    or old.terms_accepted is not true
    or old.terms_version is distinct from new.terms_version
    or old.terms_hash is distinct from new.terms_hash then
    new.terms_accepted_at := v_now;
  end if;

  if tg_op = 'INSERT'
    or old.publication_consent_accepted is not true
    or old.publication_consent_version is distinct from new.publication_consent_version
    or old.publication_consent_hash is distinct from new.publication_consent_hash then
    new.publication_consent_accepted_at := v_now;
    new.publication_consent_withdrawn_at := null;
  end if;

  return new;
END;
$$;

CREATE OR REPLACE FUNCTION private.record_store_legal_events()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  if new.privacy_notice_acknowledged and (
    tg_op = 'INSERT'
    or old.privacy_notice_acknowledged is not true
    or old.privacy_notice_version is distinct from new.privacy_notice_version
    or old.privacy_notice_hash is distinct from new.privacy_notice_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'privacy_notice_acknowledged', 'privacy',
      new.privacy_notice_version, new.privacy_notice_hash,
      new.privacy_notice_acknowledged_at
    );
  end if;

  if new.terms_accepted and (
    tg_op = 'INSERT'
    or old.terms_accepted is not true
    or old.terms_version is distinct from new.terms_version
    or old.terms_hash is distinct from new.terms_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'terms_accepted', 'terms',
      new.terms_version, new.terms_hash, new.terms_accepted_at
    );
  end if;

  if new.publication_consent_accepted and (
    tg_op = 'INSERT'
    or old.publication_consent_accepted is not true
    or old.publication_consent_version is distinct from new.publication_consent_version
    or old.publication_consent_hash is distinct from new.publication_consent_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'publication_consent_granted', 'consent',
      new.publication_consent_version, new.publication_consent_hash,
      new.publication_consent_accepted_at
    );
  end if;

  if tg_op = 'UPDATE'
    and old.publication_consent_accepted
    and new.publication_consent_accepted is not true then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'publication_consent_withdrawn', 'consent',
      old.publication_consent_version, old.publication_consent_hash,
      new.publication_consent_withdrawn_at
    );
  end if;

  return new;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_store_instagram_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  new.updated_at = pg_catalog.now();
  return new;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_article_before_save()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_is_trusted boolean;
  v_owner_id uuid;
BEGIN
  select is_blog_trusted, user_id into v_is_trusted, v_owner_id
  from public.stores
  where slug = new.store_slug;

  if new.status = 'published' and (v_is_trusted is null or not v_is_trusted) then
    if auth.uid() = v_owner_id then
      new.status := 'review';
    end if;
  end if;

  new.updated_at := pg_catalog.now();
  return new;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_article_approved()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_count int;
BEGIN
  if new.status = 'published' and (old.status is null or old.status <> 'published') then
    select count(*) into v_count
    from public.store_articles
    where store_slug = new.store_slug
      and status = 'published';

    if v_count >= 3 then
      update public.stores
      set is_blog_trusted = true
      where slug = new.store_slug;
    end if;
  end if;
  return new;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_article_spam_check()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_count int;
  v_banned_pattern text := '(bahis|casino|slot|escort|porn|porno|uyusturucu|silah|kumar)';
BEGIN
  -- Check Rate Limit: Maximum 5 articles in 24 hours per store (Only on INSERT)
  if tg_op = 'INSERT' then
    select count(*) into v_count
    from public.store_articles
    where store_slug = new.store_slug
      and created_at > now() - interval '24 hours';
      
    if v_count >= 5 then
      raise exception 'STORE_ARTICLE_RATE_LIMIT_EXCEEDED: 24 saat içinde en fazla 5 yazı yayınlayabilirsiniz.' using errcode = 'P0001';
    end if;
  end if;

  -- Check Banned Keywords: Case-insensitive check on title, summary, content, topic, and city
  if (new.title ~* v_banned_pattern) or 
     (new.summary ~* v_banned_pattern) or 
     (new.content ~* v_banned_pattern) or
     (new.target_topic ~* v_banned_pattern) or
     (new.target_city ~* v_banned_pattern) then
    raise exception 'CONTENT_CONTAINS_BANNED_WORDS: İçeriğiniz yasaklı veya uygunsuz kelimeler barındırmaktadır.' using errcode = 'P0001';
  end if;

  return new;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_store_trust_protection()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  if new.is_blog_trusted <> old.is_blog_trusted then
    select exists (
      select 1 from public.admins where user_id = auth.uid()
    ) into v_is_admin;
    
    if not v_is_admin then
      new.is_blog_trusted := old.is_blog_trusted;
    end if;
  end if;
  return new;
END;
$$;

-- 6. TRIGGERS REGISTRATION
DROP TRIGGER IF EXISTS trg_stores_updated_at ON public.stores;
CREATE TRIGGER trg_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_store_articles_updated_at ON public.store_articles;
CREATE TRIGGER trg_store_articles_updated_at
  BEFORE UPDATE ON public.store_articles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_store_articles_published_at ON public.store_articles;
CREATE TRIGGER trg_store_articles_published_at
  BEFORE UPDATE ON public.store_articles
  FOR EACH ROW EXECUTE FUNCTION public.set_published_at();

DROP TRIGGER IF EXISTS trg_store_articles_published_at_insert ON public.store_articles;
CREATE TRIGGER trg_store_articles_published_at_insert
  BEFORE INSERT ON public.store_articles
  FOR EACH ROW EXECUTE FUNCTION public.set_published_at_on_insert();

DROP TRIGGER IF EXISTS trg_set_legal_document_hash ON public.legal_documents;
CREATE TRIGGER trg_set_legal_document_hash
  BEFORE INSERT OR UPDATE ON public.legal_documents
  FOR EACH ROW EXECUTE FUNCTION private.set_legal_document_hash();

DROP TRIGGER IF EXISTS trg_validate_store_legal_acceptance ON public.stores;
CREATE TRIGGER trg_validate_store_legal_acceptance
  BEFORE INSERT OR UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION private.validate_store_legal_acceptance();

DROP TRIGGER IF EXISTS trg_record_store_legal_events ON public.stores;
CREATE TRIGGER trg_record_store_legal_events
  AFTER INSERT OR UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION private.record_store_legal_events();

DROP TRIGGER IF EXISTS trg_store_instagram_connections_updated_at ON public.store_instagram_connections;
CREATE TRIGGER trg_store_instagram_connections_updated_at
  BEFORE UPDATE ON public.store_instagram_connections
  FOR EACH ROW EXECUTE FUNCTION public.set_store_instagram_updated_at();

DROP TRIGGER IF EXISTS trg_store_instagram_tokens_updated_at ON public.store_instagram_tokens;
CREATE TRIGGER trg_store_instagram_tokens_updated_at
  BEFORE UPDATE ON public.store_instagram_tokens
  FOR EACH ROW EXECUTE FUNCTION public.set_store_instagram_updated_at();

DROP TRIGGER IF EXISTS trg_store_instagram_imports_updated_at ON public.store_instagram_imports;
CREATE TRIGGER trg_store_instagram_imports_updated_at
  BEFORE UPDATE ON public.store_instagram_imports
  FOR EACH ROW EXECUTE FUNCTION public.set_store_instagram_updated_at();

DROP TRIGGER IF EXISTS trg_article_before_save ON public.store_articles;
CREATE TRIGGER trg_article_before_save
  BEFORE INSERT OR UPDATE ON public.store_articles
  FOR EACH ROW EXECUTE FUNCTION public.on_article_before_save();

DROP TRIGGER IF EXISTS trg_article_approved ON public.store_articles;
CREATE TRIGGER trg_article_approved
  AFTER INSERT OR UPDATE ON public.store_articles
  FOR EACH ROW EXECUTE FUNCTION public.on_article_approved();

DROP TRIGGER IF EXISTS trg_article_spam_check ON public.store_articles;
CREATE TRIGGER trg_article_spam_check
  BEFORE INSERT OR UPDATE ON public.store_articles
  FOR EACH ROW EXECUTE FUNCTION public.on_article_spam_check();

DROP TRIGGER IF EXISTS trg_store_trust_protection ON public.stores;
CREATE TRIGGER trg_store_trust_protection
  BEFORE UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.on_store_trust_protection();

-- 7. RPC FUNCTIONS
CREATE OR REPLACE FUNCTION public.record_vitrin_view(p_slug text, p_ip text, p_ua text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
BEGIN
  insert into public.vitrin_views(store_slug, viewer_ip, user_agent)
  values (p_slug, p_ip, p_ua);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_today_vitrin_view_count(p_slug text, p_ip text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_count bigint;
BEGIN
  select count(*) into v_count
  from public.vitrin_views
  where store_slug = p_slug
    and created_at > now() - interval '24 hours'
    and viewer_ip = p_ip;
  return v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.link_store_to_user(p_edit_token text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'UNAUTHORIZED';
  end if;

  update public.stores
  set user_id = v_user_id
  where edit_token = p_edit_token
    and user_id is null;

  return found;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
BEGIN
  delete from public.stores where user_id = auth.uid();
  delete from auth.users where id = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION public.get_public_booking_slots(p_store_slug text, p_date date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_settings public.booking_settings%rowtype;
  v_dow text;
  v_hours jsonb;
  v_start_str text;
  v_end_str text;
  v_lunch_start_str text;
  v_lunch_end_str text;
  v_lunch_active boolean;
  v_slot timestamptz;
  v_end_limit timestamptz;
  v_capacity int;
  v_slot_time_str text;
  v_lunch_start time;
  v_lunch_end time;
  v_slot_time time;
  v_blocked boolean;
  v_active_appts_count int;
  v_appt record;
  v_confirmed_names text[];
  v_has_pending boolean;
  v_slots_result jsonb := '[]'::jsonb;
  v_slot_obj jsonb;
BEGIN
  select * into v_settings from public.booking_settings where store_slug = p_store_slug;
  if not found or not v_settings.is_enabled then
    return '[]'::jsonb;
  end if;

  v_capacity := v_settings.capacity;
  v_dow := extract(isodow from p_date)::text;
  v_hours := v_settings.working_hours->v_dow;

  if v_hours is null or not (v_hours->>'active')::boolean then
    return '[]'::jsonb;
  end if;

  v_start_str := v_hours->>'start';
  v_end_str := v_hours->>'end';
  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  if v_lunch_active then
    v_lunch_start := (v_settings.lunch_break->>'start')::time;
    v_lunch_end := (v_settings.lunch_break->>'end')::time;
  end if;

  v_slot := (p_date::text || ' ' || v_start_str)::timestamp with time zone;
  v_end_limit := (p_date::text || ' ' || v_end_str)::timestamp with time zone;

  while v_slot < v_end_limit loop
    v_slot_time := v_slot::time;
    v_slot_time_str := to_char(v_slot_time, 'HH24:MI');

    if v_lunch_active and v_slot_time >= v_lunch_start and v_slot_time < v_lunch_end then
      v_blocked := true;
    else
      select exists (
        select 1 from public.booking_blocks
        where store_slug = p_store_slug
          and block_date = p_date
          and (
            (start_time is null and end_time is null) or
            (v_slot_time >= start_time and v_slot_time < end_time)
          )
      ) into v_blocked;
    end if;

    if not v_blocked then
      v_active_appts_count := 0;
      v_confirmed_names := '{}'::text[];
      v_has_pending := false;

      for v_appt in (
        select customer_name, status, service_duration, appointment_time
        from public.appointments
        where store_slug = p_store_slug
          and status in ('pending', 'confirmed')
          and (status = 'confirmed' or expires_at > now())
          and appointment_time <= v_slot
          and v_slot < appointment_time + (service_duration || ' minutes')::interval
      ) loop
        v_active_appts_count := v_active_appts_count + 1;
        if v_appt.status = 'confirmed' then
          v_confirmed_names := array_append(v_confirmed_names, public.mask_appointment_name(v_appt.customer_name));
        else
          v_has_pending := true;
        end if;
      end loop;

      v_slot_obj := jsonb_build_object(
        'time', v_slot_time_str,
        'capacity_total', v_capacity,
        'capacity_used', v_active_appts_count,
        'slots_left', greatest(0, v_capacity - v_active_appts_count),
        'confirmed_names', to_jsonb(v_confirmed_names),
        'has_pending', v_has_pending
      );

      v_slots_result := v_slots_result || jsonb_build_array(v_slot_obj);
    end if;

    v_slot := v_slot + interval '15 minutes';
  end loop;

  return v_slots_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_appointment_request(
  p_store_slug text,
  p_customer_name text,
  p_customer_phone text,
  p_customer_notes text,
  p_service_title text,
  p_service_price text,
  p_service_duration int,
  p_appointment_time timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_settings public.booking_settings%rowtype;
  v_lock_ok boolean;
  v_daily_count int;
  v_plaintext_token text;
  v_token_hash text;
  v_appt_id uuid;
  v_appt_end timestamptz;
  v_slot timestamptz;
  v_active_appts_count int;
  v_dow text;
  v_hours jsonb;
  v_start_time time;
  v_end_time time;
  v_lunch_active boolean;
  v_lunch_start time;
  v_lunch_end time;
  v_slot_time time;
  v_blocked boolean;
BEGIN
  select count(*) into v_daily_count
  from public.appointments
  where customer_phone = p_customer_phone
    and created_at > now() - interval '24 hours';
    
  if v_daily_count >= 5 then
    raise exception 'DAILY_LIMIT_EXCEEDED';
  end if;

  select pg_try_advisory_xact_lock(hashtext(p_store_slug)) into v_lock_ok;
  if not v_lock_ok then
    raise exception 'STORE_BUSY_TRY_AGAIN';
  end if;

  select * into v_settings from public.booking_settings where store_slug = p_store_slug;
  if not found or not v_settings.is_enabled then
    raise exception 'BOOKING_DISABLED';
  end if;

  v_dow := extract(isodow from p_appointment_time)::text;
  v_hours := v_settings.working_hours->v_dow;
  if v_hours is null or not (v_hours->>'active')::boolean then
    raise exception 'STORE_CLOSED_ON_THIS_DAY';
  end if;

  v_start_time := (v_hours->>'start')::time;
  v_end_time := (v_hours->>'end')::time;
  v_slot_time := p_appointment_time::time;

  if v_slot_time < v_start_time or v_slot_time >= v_end_time then
    raise exception 'OUTSIDE_WORKING_HOURS';
  end if;

  v_lunch_active := (v_settings.lunch_break->>'active')::boolean;
  if v_lunch_active then
    v_lunch_start := (v_settings.lunch_break->>'start')::time;
    v_lunch_end := (v_settings.lunch_break->>'end')::time;
    if v_slot_time >= v_lunch_start and v_slot_time < v_lunch_end then
      raise exception 'LUNCH_BREAK_BLOCK';
    end if;
  end if;

  select exists (
    select 1 from public.booking_blocks
    where store_slug = p_store_slug
      and block_date = p_appointment_time::date
      and (
        (start_time is null and end_time is null) or
        (v_slot_time >= start_time and v_slot_time < end_time)
      )
  ) into v_blocked;
  if v_blocked then
    raise exception 'DATE_TIME_BLOCKED';
  end if;

  v_appt_end := p_appointment_time + (p_service_duration || ' minutes')::interval;
  v_slot := p_appointment_time;

  while v_slot < v_appt_end loop
    select count(*) into v_active_appts_count
    from public.appointments
    where store_slug = p_store_slug
      and status in ('pending', 'confirmed')
      and (status = 'confirmed' or expires_at > now())
      and appointment_time <= v_slot
      and v_slot < appointment_time + (service_duration || ' minutes')::interval;

    if v_active_appts_count >= v_settings.capacity then
      raise exception 'CAPACITY_FULL';
    end if;

    v_slot := v_slot + interval '15 minutes';
  end loop;

  v_plaintext_token := encode(gen_random_bytes(16), 'hex');
  v_token_hash := encode(sha256(v_plaintext_token::bytea), 'hex');
  v_appt_id := gen_random_uuid();

  insert into public.appointments (
    id, store_slug, customer_name, customer_phone, customer_notes,
    service_title, service_price, service_duration, appointment_time,
    status, token_hash, expires_at
  ) values (
    v_appt_id, p_store_slug, trim(p_customer_name), trim(p_customer_phone), trim(p_customer_notes),
    trim(p_service_title), trim(p_service_price), p_service_duration, p_appointment_time,
    'pending', v_token_hash, now() + interval '2 hours'
  );

  return jsonb_build_object(
    'appointment_id', v_appt_id,
    'token', v_plaintext_token
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_appointment_by_token(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_token_hash text;
  v_appt record;
  v_reschedule record;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  select a.*, s.name as store_name
  into v_appt
  from public.appointments a
  join public.stores s on s.slug = a.store_slug
  where a.token_hash = v_token_hash;

  if not found then
    return null;
  end if;

  select * into v_reschedule
  from public.appointment_reschedule_requests
  where appointment_id = v_appt.id and status = 'pending'
  order by created_at desc
  limit 1;

  return jsonb_build_object(
    'id', v_appt.id,
    'store_slug', v_appt.store_slug,
    'store_name', v_appt.store_name,
    'customer_name', v_appt.customer_name,
    'customer_phone', v_appt.customer_phone,
    'customer_notes', v_appt.customer_notes,
    'service_title', v_appt.service_title,
    'service_price', v_appt.service_price,
    'service_duration', v_appt.service_duration,
    'appointment_time', v_appt.appointment_time,
    'status', v_appt.status,
    'created_at', v_appt.created_at,
    'expires_at', v_appt.expires_at,
    'reschedule_request', case
      when v_reschedule.id is not null then jsonb_build_object(
        'id', v_reschedule.id,
        'requested_time', v_reschedule.requested_time,
        'status', v_reschedule.status
      )
      else null
    end
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_appointment_by_token(p_token text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_token_hash text;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  update public.appointments
  set status = 'cancelled_by_customer'
  where token_hash = v_token_hash
    and status in ('pending', 'confirmed');

  return found;
END;
$$;

CREATE OR REPLACE FUNCTION public.request_appointment_reschedule(p_token text, p_new_time timestamptz)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_token_hash text;
  v_appt public.appointments%rowtype;
  v_settings public.booking_settings%rowtype;
  v_appt_end timestamptz;
  v_slot timestamptz;
  v_active_appts_count int;
  v_lock_ok boolean;
BEGIN
  v_token_hash := encode(sha256(p_token::bytea), 'hex');

  select * into v_appt from public.appointments where token_hash = v_token_hash;
  if not found or v_appt.status not in ('pending', 'confirmed') then
    raise exception 'APPOINTMENT_NOT_ACTIVE';
  end if;

  select pg_try_advisory_xact_lock(hashtext(v_appt.store_slug)) into v_lock_ok;
  if not v_lock_ok then
    raise exception 'STORE_BUSY_TRY_AGAIN';
  end if;

  select * into v_settings from public.booking_settings where store_slug = v_appt.store_slug;
  if not found or not v_settings.is_enabled then
    raise exception 'BOOKING_DISABLED';
  end if;

  v_appt_end := p_new_time + (v_appt.service_duration || ' minutes')::interval;
  v_slot := p_new_time;

  while v_slot < v_appt_end loop
    select count(*) into v_active_appts_count
    from public.appointments
    where store_slug = v_appt.store_slug
      and id <> v_appt.id
      and status in ('pending', 'confirmed')
      and (status = 'confirmed' or expires_at > now())
      and appointment_time <= v_slot
      and v_slot < appointment_time + (service_duration || ' minutes')::interval;

    if v_active_appts_count >= v_settings.capacity then
      raise exception 'CAPACITY_FULL';
    end if;

    v_slot := v_slot + interval '15 minutes';
  end loop;

  update public.appointment_reschedule_requests
  set status = 'rejected'
  where appointment_id = v_appt.id and status = 'pending';

  insert into public.appointment_reschedule_requests (
    appointment_id, requested_time, status
  ) values (
    v_appt.id, p_new_time, 'pending'
  );

  return true;
END;
$$;

CREATE OR REPLACE FUNCTION public.respond_to_appointment(
  p_appointment_id uuid,
  p_action text,
  p_reschedule_action text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_appt public.appointments%rowtype;
  v_resched public.appointment_reschedule_requests%rowtype;
  v_is_owner boolean;
BEGIN
  select * into v_appt from public.appointments where id = p_appointment_id;
  if not found then
    raise exception 'APPOINTMENT_NOT_FOUND';
  end if;

  select exists (
    select 1 from public.stores
    where slug = v_appt.store_slug
      and user_id = auth.uid()
  ) into v_is_owner;

  if not v_is_owner then
    raise exception 'UNAUTHORIZED';
  end if;

  if p_action is not null then
    if p_action = 'confirm' then
      update public.appointments
      set status = 'confirmed', expires_at = '9999-12-31 23:59:59+00'::timestamptz
      where id = p_appointment_id;
    elsif p_action = 'reject' then
      update public.appointments
      set status = 'rejected'
      where id = p_appointment_id;
    else
      raise exception 'INVALID_ACTION';
    end if;
    return true;
  end if;

  if p_reschedule_action is not null then
    select * into v_resched
    from public.appointment_reschedule_requests
    where appointment_id = p_appointment_id and status = 'pending'
    order by created_at desc
    limit 1;

    if not found then
      raise exception 'NO_PENDING_RESCHEDULE';
    end if;

    if p_reschedule_action = 'approve' then
      update public.appointment_reschedule_requests
      set status = 'approved'
      where id = v_resched.id;

      update public.appointments
      set appointment_time = v_resched.requested_time,
          status = 'confirmed',
          expires_at = '9999-12-31 23:59:59+00'::timestamptz
      where id = p_appointment_id;

    elsif p_reschedule_action = 'reject' then
      update public.appointment_reschedule_requests
      set status = 'rejected'
      where id = v_resched.id;
    else
      raise exception 'INVALID_ACTION';
    end if;
    return true;
  end if;

  return false;
END;
$$;

CREATE OR REPLACE FUNCTION public.approve_store_article(p_article_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  select exists (
    select 1 from public.admins where user_id = auth.uid()
  ) into v_is_admin;
  
  if not v_is_admin then
    raise exception 'UNAUTHORIZED';
  end if;

  update public.store_articles
  set status = 'published', published_at = now()
  where id = p_article_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_store_article(p_article_id uuid, p_reason text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_is_admin boolean;
BEGIN
  select exists (
    select 1 from public.admins where user_id = auth.uid()
  ) into v_is_admin;
  
  if not v_is_admin then
    raise exception 'UNAUTHORIZED';
  end if;

  update public.store_articles
  set status = 'rejected'
  where id = p_article_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.withdraw_store_publication_consent(
  p_slug text,
  p_edit_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  if p_slug is null or pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  update public.stores
  set
    is_published = false,
    publication_consent_accepted = false,
    publication_consent_withdrawn_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  where slug = p_slug
    and edit_token = p_edit_token
    and edit_token <> '';

  if not found then
    raise exception 'EDIT_TOKEN_MISMATCH' using errcode = 'P0001';
  end if;
END;
$$;

CREATE OR REPLACE FUNCTION apply_category_template(
  p_store_id UUID,
  p_category_key TEXT,
  p_fill_cover BOOLEAN DEFAULT true,
  p_fill_logo BOOLEAN DEFAULT true,
  p_fill_gallery BOOLEAN DEFAULT true,
  p_fill_products BOOLEAN DEFAULT true
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB := '{}';
  v_image_row RECORD;
  v_current_cover TEXT;
  v_current_logo TEXT;
  v_current_gallery JSONB;
  v_current_products JSONB;
  v_gallery_items JSONB := '[]'::JSONB;
  v_template_products JSONB := '[]'::JSONB;
  v_applied_count INT := 0;
BEGIN
  SELECT shelf_image_url, logo_url, gallery_items, products
  INTO v_current_cover, v_current_logo, v_current_gallery, v_current_products
  FROM stores WHERE id = p_store_id;

  IF p_fill_cover THEN
    SELECT image_url INTO v_image_row
    FROM category_image_templates
    WHERE category_key = p_category_key AND image_type = 'cover' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_cover IS NULL OR v_current_cover = '') THEN
      UPDATE stores SET shelf_image_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"cover": true}'::JSONB;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_logo THEN
    SELECT image_url INTO v_image_row
    FROM category_image_templates
    WHERE category_key = p_category_key AND image_type = 'logo_placeholder' AND is_active = true
    ORDER BY display_order LIMIT 1;

    IF FOUND AND (v_current_logo IS NULL OR v_current_logo = '') THEN
      UPDATE stores SET logo_url = v_image_row.image_url WHERE id = p_store_id;
      v_result := v_result || '{"logo": true}'::JSONB;
      v_applied_count := v_applied_count + 1;
    END IF;
  END IF;

  IF p_fill_gallery THEN
    IF v_current_gallery IS NULL OR jsonb_array_length(v_current_gallery) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'imageUrl', image_url,
          'title', COALESCE(title, 'Gorsel')
        ) ORDER BY display_order
      )
      INTO v_gallery_items
      FROM category_image_templates
      WHERE category_key = p_category_key AND image_type = 'gallery' AND is_active = true;

      IF v_gallery_items IS NOT NULL AND jsonb_array_length(v_gallery_items) > 0 THEN
        UPDATE stores SET gallery_items = v_gallery_items WHERE id = p_store_id;
        v_result := v_result || '{"gallery": true}'::JSONB;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  IF p_fill_products THEN
    IF v_current_products IS NULL OR jsonb_array_length(v_current_products) = 0 THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', gen_random_uuid(),
          'name', COALESCE(title, 'Urun'),
          'description', '',
          'price', '',
          'imageUrls', jsonb_build_array(image_url),
          'isVisible', true,
          'source', 'category_template'
        ) ORDER BY display_order
      )
      INTO v_template_products
      FROM category_image_templates
      WHERE category_key = p_category_key AND image_type = 'product' AND is_active = true;

      IF v_template_products IS NOT NULL AND jsonb_array_length(v_template_products) > 0 THEN
        UPDATE stores SET products = v_template_products WHERE id = p_store_id;
        v_result := v_result || '{"products": true}'::JSONB;
        v_applied_count := v_applied_count + 1;
      END IF;
    END IF;
  END IF;

  IF v_applied_count > 0 THEN
    INSERT INTO store_category_image_usage (store_id, category_key, images_used)
    VALUES (
      p_store_id,      p_category_key,
      COALESCE(
        (SELECT jsonb_agg(image_url)
         FROM category_image_templates
         WHERE category_key = p_category_key AND is_active = true),
        '[]'::JSONB
      )
    )
    ON CONFLICT (store_id) DO UPDATE SET
      category_key = EXCLUDED.category_key,
      images_used = EXCLUDED.images_used,
      applied_at = now();
  END IF;

  RETURN v_result || jsonb_build_object(
    'success', v_applied_count > 0,
    'image_count', (SELECT COUNT(*) FROM category_image_templates WHERE category_key = p_category_key AND is_active = true)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.update_store_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  if p_slug is null or pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  update public.stores
  set
    name = coalesce(p_store->>'name', name),
    business_type = coalesce(p_store->>'business_type', business_type),
    description = coalesce(p_store->>'description', description),
    corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
    whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
    instagram = coalesce(p_store->>'instagram', instagram),
    website = coalesce(p_store->>'website', website),
    address = coalesce(p_store->>'address', address),
    theme = coalesce(p_store->>'theme', theme),
    status = coalesce(p_store->>'status', status),
    marketplace_links = coalesce(p_store->'marketplace_links', marketplace_links),
    gallery_items = coalesce(p_store->'gallery_items', gallery_items),
    products = coalesce(p_store->'products', products),
    product_categories = coalesce(p_store->'product_categories', product_categories),
    offerings = coalesce(p_store->'offerings', offerings),
    catalog_link = coalesce(p_store->>'catalog_link', catalog_link),
    references_link = coalesce(p_store->>'references_link', references_link),
    vcard_link = coalesce(p_store->>'vcard_link', vcard_link),
    shelf_image_url = coalesce(nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
    logo_url = coalesce(nullif(p_store->>'logo_url', ''), logo_url),
    working_hours = coalesce(p_store->>'working_hours', working_hours),
    is_published = true,
    is_store = coalesce((p_store->>'is_store')::boolean, is_store),
    kategori = coalesce(p_store->>'kategori', kategori),
    latitude = case when p_store ? 'latitude' then (p_store->>'latitude')::float8 else latitude end,
    longitude = case when p_store ? 'longitude' then (p_store->>'longitude')::float8 else longitude end,
    location_accuracy_meters = case when p_store ? 'location_accuracy_meters' then (p_store->>'location_accuracy_meters')::float8 else location_accuracy_meters end,
    location_consent_at = case when p_store ? 'location_consent_at' then (p_store->>'location_consent_at')::timestamptz else location_consent_at end,
    location_source = case when p_store ? 'location_source' then p_store->>'location_source' else location_source end,
    province_code = coalesce(p_store->>'province_code', province_code),
    province_name = coalesce(p_store->>'province_name', province_name),
    district_code = coalesce(p_store->>'district_code', district_code),
    district_name = coalesce(p_store->>'district_name', district_name),
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
  where slug = p_slug
    and edit_token = p_edit_token
    and edit_token <> '';

  if not found then
    raise exception 'EDIT_TOKEN_MISMATCH' using errcode = 'P0001';
  end if;
END;
$$;

-- Secure search paths after compilation definitions
alter function public.update_store_with_token(text,text,jsonb) set search_path = pg_catalog, public, auth;
alter function public.link_store_to_user(text) set search_path = pg_catalog, public, auth;
alter function public.get_today_vitrin_view_count(text,text) set search_path = pg_catalog, public, auth;
alter function public.record_vitrin_view(text,text,text) set search_path = pg_catalog, public, auth;

-- Grant EXECUTE Permissions strategically
REVOKE EXECUTE ON FUNCTION public.link_store_to_user(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.link_store_to_user(text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_today_vitrin_view_count(text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.get_today_vitrin_view_count(text, text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.record_vitrin_view(text, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.record_vitrin_view(text, text, text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.update_store_with_token(text, text, jsonb) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_public_booking_slots(text, date) FROM public;
GRANT EXECUTE ON FUNCTION public.get_public_booking_slots(text, date) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.create_appointment_request(text, text, text, text, text, text, int, timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION public.create_appointment_request(text, text, text, text, text, text, int, timestamptz) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.get_appointment_by_token(text) FROM public;
GRANT EXECUTE ON FUNCTION public.get_appointment_by_token(text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.cancel_appointment_by_token(text) FROM public;
GRANT EXECUTE ON FUNCTION public.cancel_appointment_by_token(text) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.request_appointment_reschedule(text, timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION public.request_appointment_reschedule(text, timestamptz) TO anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.respond_to_appointment(uuid, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.respond_to_appointment(uuid, text, text) TO authenticated;

GRANT EXECUTE ON FUNCTION public.approve_store_article(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_store_article(uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.withdraw_store_publication_consent(text, text) TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_store_instagram_updated_at() FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_store_instagram_updated_at() TO service_role;

REVOKE EXECUTE ON FUNCTION private.set_legal_document_hash() FROM public;
REVOKE EXECUTE ON FUNCTION private.validate_store_legal_acceptance() FROM public;
REVOKE EXECUTE ON FUNCTION private.record_store_legal_events() FROM public;

-- 8. ROW LEVEL SECURITY POLICIES
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vitrin_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_reschedule_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meta_data_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_instagram_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_instagram_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_instagram_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_acceptance_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.category_image_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_category_image_usage ENABLE ROW LEVEL SECURITY;

-- Deny direct access to vitrin_views
CREATE POLICY "Deny direct access to public.vitrin_views" ON public.vitrin_views FOR ALL TO public USING (false) WITH CHECK (false);

-- Stores RLS
CREATE POLICY "Allow public read stores" ON public.stores FOR SELECT TO anon, authenticated USING (is_published = true);
CREATE POLICY "Allow owners to insert stores" ON public.stores FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own stores" ON public.stores FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Legal Acceptances
REVOKE ALL ON TABLE public.legal_documents FROM anon, authenticated;
GRANT SELECT ON TABLE public.legal_documents TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.legal_documents TO service_role;
CREATE POLICY "Active legal documents are publicly readable" ON public.legal_documents FOR SELECT TO anon, authenticated USING (is_active = true);

REVOKE ALL ON TABLE public.legal_acceptance_events FROM anon, authenticated;
GRANT SELECT ON TABLE public.legal_acceptance_events TO service_role;

-- Admins
CREATE POLICY "Admins can view admins" ON public.admins FOR SELECT TO authenticated USING (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- Booking settings
CREATE POLICY "Allow public read booking settings" ON public.booking_settings FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow owners to insert booking settings" ON public.booking_settings FOR INSERT TO authenticated WITH CHECK (
  exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
);
CREATE POLICY "Allow owners to update booking settings" ON public.booking_settings FOR UPDATE TO authenticated USING (
  exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
);

-- Booking blocks
CREATE POLICY "Allow public read booking blocks" ON public.booking_blocks FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow owners to manage booking blocks" ON public.booking_blocks FOR ALL TO authenticated USING (
  exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
);

-- Appointments RLS
CREATE POLICY "Allow owners select appointments" ON public.appointments FOR SELECT TO authenticated USING (
  exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
);
CREATE POLICY "Allow owners update appointments" ON public.appointments FOR UPDATE TO authenticated USING (
  exists (select 1 from public.stores s where s.slug = store_slug and s.user_id = auth.uid())
);

-- Reschedule Requests RLS
CREATE POLICY "Allow owners select reschedule requests" ON public.appointment_reschedule_requests FOR SELECT TO authenticated USING (
  exists (
    select 1 from public.appointments a
    join public.stores s on s.slug = a.store_slug
    where a.id = appointment_id and s.user_id = auth.uid()
  )
);
CREATE POLICY "Allow owners update reschedule requests" ON public.appointment_reschedule_requests FOR UPDATE TO authenticated USING (
  exists (
    select 1 from public.appointments a
    join public.stores s on s.slug = a.store_slug
    where a.id = appointment_id and s.user_id = auth.uid()
  )
);

-- Store Articles
CREATE POLICY "Anyone can read published articles" ON public.store_articles FOR SELECT USING (status = 'published');
CREATE POLICY "Owners can read all their own articles" ON public.store_articles FOR SELECT USING (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);
CREATE POLICY "Owners can insert their own articles" ON public.store_articles FOR INSERT WITH CHECK (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);
CREATE POLICY "Owners can update their own articles" ON public.store_articles FOR UPDATE USING (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
) WITH CHECK (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);
CREATE POLICY "Owners can delete their own articles" ON public.store_articles FOR DELETE USING (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);

-- Article reports
CREATE POLICY "Anyone can report articles" ON public.article_reports FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Admins can view reports" ON public.article_reports FOR SELECT TO authenticated USING (
  exists (select 1 from public.admins where admins.user_id = auth.uid())
);

-- Meta Data Deletion
GRANT ALL ON TABLE public.meta_data_deletion_requests TO service_role;

-- Instagram connections & tokens
REVOKE ALL ON TABLE public.store_instagram_tokens FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.store_instagram_connections TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.store_instagram_tokens TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.store_instagram_imports TO service_role;
GRANT SELECT ON TABLE public.store_instagram_connections TO authenticated;
GRANT SELECT ON TABLE public.store_instagram_imports TO authenticated;

CREATE POLICY "Owners can read own Instagram connection" ON public.store_instagram_connections FOR SELECT TO authenticated USING (
  exists (
    select 1 from public.stores
    where stores.slug = store_instagram_connections.store_slug
      and stores.user_id = (select auth.uid())
  )
);

CREATE POLICY "Owners can read own Instagram imports" ON public.store_instagram_imports FOR SELECT TO authenticated USING (
  exists (
    select 1 from public.stores
    where stores.slug = store_instagram_imports.store_slug
      and stores.user_id = (select auth.uid())
  )
);

-- Category image templates
CREATE POLICY "category_templates_select_public" ON public.category_image_templates FOR SELECT TO anon, authenticated USING (is_active = true);
CREATE POLICY "category_templates_admin_all" ON public.category_image_templates FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Store category usage
CREATE POLICY "store_cat_usage_owner_select" ON public.store_category_image_usage FOR SELECT TO authenticated USING (
  exists (select 1 from public.stores where public.stores.id = store_id and public.stores.user_id = auth.uid())
);
CREATE POLICY "store_cat_usage_owner_insert" ON public.store_category_image_usage FOR INSERT TO authenticated WITH CHECK (
  exists (select 1 from public.stores where public.stores.id = store_id and public.stores.user_id = auth.uid())
);

-- 9. STORAGE POLICIES
CREATE POLICY "Allow public shelf image uploads" ON storage.objects FOR INSERT TO anon, authenticated WITH CHECK (
  bucket_id = 'shelf-images' AND name ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
);

CREATE POLICY "category_templates_storage_public" ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = 'category-templates');
