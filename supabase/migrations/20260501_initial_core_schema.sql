-- ============================================================
-- Migration: Initial core schema (stores + vitrin_views)
-- Tarih: 2026-07-01
-- Amaç: stores ve vitrin_views tablolarının ilk oluşturma SQL'ini
--       sağlamak. Bu migration, sonraki tüm ALTER TABLE migration
--       dosyalarının çalışması için zorunlu ön koşuldur.
-- ============================================================

-- ============================================================
-- 1. public.stores (Ana vitrin / işletme tablosu)
-- ============================================================

create table if not exists public.stores (
  slug text primary key,
  edit_token text not null,
  name text not null default '',
  business_type text not null default 'Butik',
  description text not null default '',
  corporate_bio text not null default '',
  whatsapp text not null default '',
  instagram text not null default '',
  website text not null default '',
  address text not null default '',
  theme text not null default 'Premium',
  status text not null default 'Açık',
  marketplace_links jsonb not null default '[]'::jsonb,
  gallery_items jsonb not null default '[]'::jsonb,
  catalog_link text not null default '',
  references_link text not null default '',
  vcard_link text not null default '',
  shelf_image_url text not null default '',
  is_published boolean not null default false,
  is_store boolean not null default false,
  kategori text not null default '',
  working_hours text not null default '',
  province_code text,
  province_name text,
  district_code text,
  district_name text,
  google_business_link text,
  logo_url text,
  latitude float8,
  longitude float8,
  location_accuracy_meters float8,
  location_consent_at timestamptz,
  location_source text,
  products jsonb not null default '[]'::jsonb,
  product_categories jsonb not null default '[]'::jsonb,
  offerings jsonb default '[]'::jsonb,
  privacy_notice_acknowledged boolean not null default false,
  privacy_notice_version text not null default '',
  privacy_notice_hash text not null default '',
  terms_accepted boolean not null default false,
  terms_version text not null default '',
  terms_hash text not null default '',
  publication_consent_accepted boolean not null default false,
  publication_consent_version text not null default '',
  publication_consent_hash text not null default '',
  user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  is_blog_trusted boolean default false
);

create index if not exists idx_stores_slug on public.stores (slug);
create index if not exists idx_stores_user_id on public.stores (user_id);
create index if not exists idx_stores_is_published on public.stores (is_published) where is_published = true;
create index if not exists idx_stores_kategori on public.stores (kategori) where is_published = true;

alter table public.stores enable row level security;

drop policy if exists "Allow public read published stores" on public.stores;
create policy "Allow public read published stores"
  on public.stores
  for select
  to anon, authenticated
  using (is_published = true);

drop policy if exists "Users can read their own stores" on public.stores;
create policy "Users can read their own stores"
  on public.stores
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can update their own stores" on public.stores;
create policy "Users can update their own stores"
  on public.stores
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
-- 2. public.vitrin_views
-- ============================================================

create table if not exists public.vitrin_views (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null references public.stores(slug) on delete cascade,
  session_key text not null default '',
  source text not null default 'unknown',
  ip_address text,
  viewed_at timestamptz not null default now()
);

create index if not exists idx_vitrin_views_store_slug on public.vitrin_views (store_slug);
create index if not exists idx_vitrin_views_viewed_at on public.vitrin_views (viewed_at);
create index if not exists idx_vitrin_views_session_key on public.vitrin_views (store_slug, session_key, viewed_at);

alter table public.vitrin_views enable row level security;

drop policy if exists "Deny direct access to public.vitrin_views" on public.vitrin_views;
create policy "Deny direct access to public.vitrin_views"
  on public.vitrin_views
  for all
  to public
  using (false)
  with check (false);

-- ============================================================
-- 3. RPC: record_vitrin_view
-- ============================================================

create or replace function public.record_vitrin_view(
  p_store_slug text,
  p_session_key text,
  p_source text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if not exists (
    select 1 from public.stores
    where slug = p_store_slug and is_published = true
  ) then
    return;
  end if;

  if exists (
    select 1 from public.vitrin_views
    where store_slug = p_store_slug
      and session_key = p_session_key
      and viewed_at > now() - interval '24 hours'
  ) then
    return;
  end if;

  insert into public.vitrin_views (store_slug, session_key, source, viewed_at)
  values (p_store_slug, p_session_key, p_source, now());
end;
$$;

revoke execute on function public.record_vitrin_view(text, text, text) from public;
grant execute on function public.record_vitrin_view(text, text, text) to anon, authenticated;

-- ============================================================
-- 4. RPC: get_today_vitrin_view_count
-- ============================================================

create or replace function public.get_today_vitrin_view_count(
  p_slug text,
  p_edit_token text
)
returns int
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_count int;
  v_valid boolean;
begin
  select exists (
    select 1 from public.stores
    where slug = p_slug and edit_token = p_edit_token
  ) into v_valid;

  if not v_valid then
    return 0;
  end if;

  select count(*) into v_count
  from public.vitrin_views
  where store_slug = p_slug
    and viewed_at >= date_trunc('day', now());

  return v_count;
end;
$$;

revoke execute on function public.get_today_vitrin_view_count(text, text) from public;
grant execute on function public.get_today_vitrin_view_count(text, text) to anon, authenticated;

-- ============================================================
-- 5. updated_at trigger for stores
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_stores_updated_at on public.stores;
create trigger trg_stores_updated_at
  before update on public.stores
  for each row execute function public.set_updated_at();

notify pgrst, 'reload schema';
