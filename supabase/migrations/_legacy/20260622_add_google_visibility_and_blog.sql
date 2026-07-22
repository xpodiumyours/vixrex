-- 1. Add Local SEO columns and Google review links to stores table
alter table public.stores
add column if not exists province_code text,
add column if not exists province_name text,
add column if not exists district_code text,
add column if not exists district_name text,
add column if not exists google_business_link text,
add column if not exists is_blog_trusted boolean default false;

-- Add check constraint for google_business_link to enforce HTTPS and only secure Google/g.page/goo.gl domains
alter table public.stores drop constraint if exists check_google_link;
alter table public.stores add constraint check_google_link check (
  google_business_link is null or 
  google_business_link = '' or 
  google_business_link ~* '^https:\/\/(www\.)?(search\.google\.com|g\.page|maps\.google\.com|maps\.app\.goo\.gl)\/.*$'
);

-- 2. Create store_articles table for the blog functionality
create table if not exists public.store_articles (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null references public.stores(slug) on delete cascade,
  title text not null check (length(btrim(title)) > 0),
  summary text not null default '',
  content text not null check (length(btrim(content)) > 0),
  cover_image_url text,
  article_type text not null default 'standard' check (article_type in ('standard', 'news', 'promotion')),
  target_topic text,
  target_city text,
  seo_score int not null default 0 check (seo_score >= 0 and seo_score <= 100),
  seo_errors jsonb not null default '[]'::jsonb,
  slug text not null check (length(btrim(slug)) > 0),
  status text not null default 'draft' check (status in ('draft', 'review', 'published', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  constraint unique_store_article_slug unique (store_slug, slug)
);

-- Enable RLS on store_articles
alter table public.store_articles enable row level security;

-- Establish RLS policies for store_articles
drop policy if exists "Anyone can read published articles" on public.store_articles;
create policy "Anyone can read published articles"
on public.store_articles
for select
using (status = 'published');

drop policy if exists "Owners can read all their own articles" on public.store_articles;
create policy "Owners can read all their own articles"
on public.store_articles
for select
using (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);

drop policy if exists "Owners can insert their own articles" on public.store_articles;
create policy "Owners can insert their own articles"
on public.store_articles
for insert
with check (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);

drop policy if exists "Owners can update their own articles" on public.store_articles;
create policy "Owners can update their own articles"
on public.store_articles
for update
using (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);

drop policy if exists "Owners can delete their own articles" on public.store_articles;
create policy "Owners can delete their own articles"
on public.store_articles
for delete
using (
  exists (
    select 1 from public.stores
    where stores.slug = store_articles.store_slug
      and stores.user_id = auth.uid()
  )
);

-- 3. Moderation and Trust Automation triggers

-- Before Save: Force status to 'review' if the store is not trusted and the owner tries to publish
create or replace function public.on_article_before_save()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_is_trusted boolean;
  v_owner_id uuid;
begin
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
end;
$$;

drop trigger if exists trg_article_before_save on public.store_articles;
create trigger trg_article_before_save
before insert or update on public.store_articles
for each row
execute function public.on_article_before_save();

-- After Approved: Count published articles, if >= 3 then mark the store as trusted
create or replace function public.on_article_approved()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count int;
begin
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
end;
$$;

drop trigger if exists trg_article_approved on public.store_articles;
create trigger trg_article_approved
after insert or update on public.store_articles
for each row
execute function public.on_article_approved();

-- 4. Update the update_store_with_token function to support new fields
create or replace function public.update_store_with_token(p_slug text, p_edit_token text, p_store jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_slug is null or pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;

  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  update public.stores
  set
    name = pg_catalog.coalesce(p_store->>'name', name),
    business_type = pg_catalog.coalesce(p_store->>'business_type', business_type),
    description = pg_catalog.coalesce(p_store->>'description', description),
    corporate_bio = pg_catalog.coalesce(p_store->>'corporate_bio', corporate_bio),
    whatsapp = pg_catalog.coalesce(p_store->>'whatsapp', whatsapp),
    instagram = pg_catalog.coalesce(p_store->>'instagram', instagram),
    website = pg_catalog.coalesce(p_store->>'website', website),
    address = pg_catalog.coalesce(p_store->>'address', address),
    theme = pg_catalog.coalesce(p_store->>'theme', theme),
    status = pg_catalog.coalesce(p_store->>'status', status),
    marketplace_links = pg_catalog.coalesce(p_store->'marketplace_links', marketplace_links),
    gallery_items = pg_catalog.coalesce(p_store->'gallery_items', gallery_items),
    products = pg_catalog.coalesce(p_store->'products', products),
    offerings = pg_catalog.coalesce(p_store->'offerings', offerings),
    catalog_link = pg_catalog.coalesce(p_store->>'catalog_link', catalog_link),
    references_link = pg_catalog.coalesce(p_store->>'references_link', references_link),
    vcard_link = pg_catalog.coalesce(p_store->>'vcard_link', vcard_link),
    shelf_image_url = pg_catalog.coalesce(pg_catalog.nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
    logo_url = pg_catalog.coalesce(pg_catalog.nullif(p_store->>'logo_url', ''), logo_url),
    working_hours = pg_catalog.coalesce(p_store->>'working_hours', working_hours),
    is_published = true,
    is_store = pg_catalog.coalesce((p_store->>'is_store')::boolean, is_store),
    kategori = pg_catalog.coalesce(p_store->>'kategori', kategori),
    latitude = case when p_store ? 'latitude' then (p_store->>'latitude')::float8 else latitude end,
    longitude = case when p_store ? 'longitude' then (p_store->>'longitude')::float8 else longitude end,
    location_accuracy_meters = case when p_store ? 'location_accuracy_meters' then (p_store->>'location_accuracy_meters')::float8 else location_accuracy_meters end,
    location_consent_at = case when p_store ? 'location_consent_at' then (p_store->>'location_consent_at')::timestamptz else location_consent_at end,
    location_source = case when p_store ? 'location_source' then p_store->>'location_source' else location_source end,
    province_code = pg_catalog.coalesce(p_store->>'province_code', province_code),
    province_name = pg_catalog.coalesce(p_store->>'province_name', province_name),
    district_code = pg_catalog.coalesce(p_store->>'district_code', district_code),
    district_name = pg_catalog.coalesce(p_store->>'district_name', district_name),
    google_business_link = pg_catalog.coalesce(p_store->>'google_business_link', google_business_link),
    updated_at = pg_catalog.now()
  where slug = p_slug
    and edit_token = p_edit_token
    and edit_token <> '';

  if not pg_catalog.found then
    raise exception 'EDIT_TOKEN_MISMATCH' using errcode = 'P0001';
  end if;
end;
$$;

-- 5. Create public.admins table
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- Enable RLS on admins
alter table public.admins enable row level security;

-- Only admins can see who else is admin
create policy "Admins can view admins" on public.admins
  for select to authenticated using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- 6. Store Trust Protection Trigger
create or replace function public.on_store_trust_protection()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_is_admin boolean;
begin
  if new.is_blog_trusted <> old.is_blog_trusted then
    select exists (
      select 1 from public.admins where user_id = auth.uid()
    ) into v_is_admin;
    
    if not v_is_admin then
      new.is_blog_trusted := old.is_blog_trusted;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_store_trust_protection on public.stores;
create trigger trg_store_trust_protection
before update on public.stores
for each row
execute function public.on_store_trust_protection();

-- 7. Admin RPC functions
create or replace function public.approve_store_article(p_article_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_is_admin boolean;
begin
  select exists (
    select 1 from public.admins where user_id = auth.uid()
  ) into v_is_admin;
  
  if not v_is_admin then
    raise exception 'UNAUTHORIZED';
  end if;

  update public.store_articles
  set status = 'published', published_at = now()
  where id = p_article_id;
end;
$$;

create or replace function public.reject_store_article(p_article_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_is_admin boolean;
begin
  select exists (
    select 1 from public.admins where user_id = auth.uid()
  ) into v_is_admin;
  
  if not v_is_admin then
    raise exception 'UNAUTHORIZED';
  end if;

  update public.store_articles
  set status = 'rejected'
  where id = p_article_id;
end;
$$;

grant execute on function public.approve_store_article(uuid) to authenticated;
grant execute on function public.reject_store_article(uuid, text) to authenticated;

-- 8. Create article_reports table for spam and abuse reporting
create table if not exists public.article_reports (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.store_articles(id) on delete cascade,
  reason text not null check (length(btrim(reason)) > 0),
  reporter_ip text,
  created_at timestamptz not null default now()
);

-- Enable RLS on article_reports
alter table public.article_reports enable row level security;

-- Establish RLS policies for article_reports
drop policy if exists "Anyone can report articles" on public.article_reports;
create policy "Anyone can report articles"
on public.article_reports
for insert
to anon, authenticated
with check (true);

drop policy if exists "Admins can view reports" on public.article_reports;
create policy "Admins can view reports"
on public.article_reports
for select
to authenticated
using (
  exists (
    select 1 from public.admins
    where admins.user_id = auth.uid()
  )
);


