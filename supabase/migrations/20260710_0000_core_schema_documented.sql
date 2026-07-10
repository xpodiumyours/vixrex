-- ============================================================================
-- VixRex Core Schema (0000)
-- Bu migration: stores ve vitrin_views tablolarının ilk oluşturmasını sağlar.
-- Mevcut supabase_schema.sql dosyasındaki çekirdek tabloları kapsar.
-- Yeni Supabase projelerinde bu dosya önce çalıştırılmalıdır.
-- ============================================================================

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Core Tables
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
  )
);

CREATE TABLE IF NOT EXISTS public.vitrin_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_slug TEXT NOT NULL REFERENCES public.stores(slug) ON DELETE CASCADE,
  viewer_ip TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_stores_user_id ON public.stores USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_stores_slug ON public.stores USING btree (slug);
CREATE INDEX IF NOT EXISTS idx_vitrin_views_store_slug ON public.vitrin_views USING btree (store_slug);
CREATE INDEX IF NOT EXISTS idx_vitrin_views_created ON public.vitrin_views USING btree (created_at);

-- 4. RLS
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vitrin_views ENABLE ROW LEVEL SECURITY;

-- Public read for published stores
CREATE POLICY "Published stores are publicly readable"
ON public.stores FOR SELECT TO anon, authenticated
USING (is_published = true);

-- Owners can manage their stores
CREATE POLICY "Authenticated users can create stores"
ON public.stores FOR INSERT TO authenticated
WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Owners can update their stores"
ON public.stores FOR UPDATE TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

-- vitrin_views: direct access denied (only via RPC)
CREATE POLICY "Deny direct access to vitrin_views"
ON public.vitrin_views FOR ALL TO public
USING (false) WITH CHECK (false);

-- 5. Updated_at trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

NOTIFY pgrst, 'reload schema';
