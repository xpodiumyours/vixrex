-- Katman 2 — Merkezi Blog Kütüphanesi
-- Katman 1'deki vixrex_blog_articles korunur; yalnız makine-okur metadata eklenir.
-- Sektör sözlüğü DB'de kopyalanmaz: tek kaynak shared/business_categories.json.

alter table public.vixrex_blog_articles
  add column if not exists primary_topic text,
  add column if not exists purpose text,
  add column if not exists sector_ids text[] not null default '{}'::text[],
  add column if not exists location_scope text not null default 'national',
  add column if not exists province_codes text[] not null default '{}'::text[],
  add column if not exists district_targets jsonb not null default '[]'::jsonb,
  add column if not exists tags text[] not null default '{}'::text[],
  add column if not exists provenance text not null default 'vixrex-editorial',
  add column if not exists source_urls text[] not null default '{}'::text[];

alter table public.vixrex_blog_articles
  drop constraint if exists vixrex_blog_articles_location_scope_check,
  add constraint vixrex_blog_articles_location_scope_check
    check (location_scope in ('national', 'province', 'district')),
  drop constraint if exists vixrex_blog_articles_district_targets_array_check,
  add constraint vixrex_blog_articles_district_targets_array_check
    check (jsonb_typeof(district_targets) = 'array'),
  drop constraint if exists vixrex_blog_articles_sector_limit_check,
  add constraint vixrex_blog_articles_sector_limit_check
    check (cardinality(sector_ids) <= 19),
  drop constraint if exists vixrex_blog_articles_province_limit_check,
  add constraint vixrex_blog_articles_province_limit_check
    check (cardinality(province_codes) <= 81),
  drop constraint if exists vixrex_blog_articles_tag_limit_check,
  add constraint vixrex_blog_articles_tag_limit_check
    check (cardinality(tags) <= 8),
  drop constraint if exists vixrex_blog_articles_location_target_check,
  add constraint vixrex_blog_articles_location_target_check
    check (
      location_scope = 'national'
      or (location_scope = 'province' and cardinality(province_codes) > 0)
      or (location_scope = 'district' and jsonb_array_length(district_targets) > 0)
    ),
  drop constraint if exists vixrex_blog_articles_published_library_metadata_check,
  add constraint vixrex_blog_articles_published_library_metadata_check
    check (
      status <> 'published'
      or (
        primary_topic is not null
        and length(btrim(primary_topic)) > 0
        and purpose is not null
        and length(btrim(purpose)) > 0
      )
    );

create index if not exists idx_vixrex_blog_articles_topic_published
  on public.vixrex_blog_articles (primary_topic, published_at desc nulls last)
  where status = 'published';

create index if not exists idx_vixrex_blog_articles_sector_ids
  on public.vixrex_blog_articles using gin (sector_ids);

create index if not exists idx_vixrex_blog_articles_province_codes
  on public.vixrex_blog_articles using gin (province_codes);

create index if not exists idx_vixrex_blog_articles_tags
  on public.vixrex_blog_articles using gin (tags);

-- İlgili yazılar gevşek slug dizisi değildir; FK ile gerçek makaleye bağlanır.
create table if not exists public.vixrex_blog_article_relations (
  article_id uuid not null references public.vixrex_blog_articles(id) on delete cascade,
  related_article_id uuid not null references public.vixrex_blog_articles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (article_id, related_article_id),
  constraint vixrex_blog_article_relations_not_self_check
    check (article_id <> related_article_id)
);

create index if not exists idx_vixrex_blog_article_relations_related
  on public.vixrex_blog_article_relations (related_article_id);

alter table public.vixrex_blog_article_relations enable row level security;

revoke all on table public.vixrex_blog_article_relations from public;
grant select on table public.vixrex_blog_article_relations to anon;
grant select, insert, update, delete on table public.vixrex_blog_article_relations to authenticated;
grant all on table public.vixrex_blog_article_relations to service_role;

-- Public yalnız iki ucu da yayında olan ilişkileri görebilir.
drop policy if exists "Public can read published Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Public can read published Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.vixrex_blog_articles a
      where a.id = article_id and a.status = 'published'
    )
    and exists (
      select 1 from public.vixrex_blog_articles b
      where b.id = related_article_id and b.status = 'published'
    )
  );

-- Admin taslak ilişkileri de yönetebilir.
drop policy if exists "Admins can read all Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can read all Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for select
  to authenticated
  using (
    exists (select 1 from public.admins where admins.user_id = auth.uid())
  );

drop policy if exists "Admins can insert Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can insert Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for insert
  to authenticated
  with check (
    exists (select 1 from public.admins where admins.user_id = auth.uid())
  );

drop policy if exists "Admins can update Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can update Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for update
  to authenticated
  using (
    exists (select 1 from public.admins where admins.user_id = auth.uid())
  )
  with check (
    exists (select 1 from public.admins where admins.user_id = auth.uid())
  );

drop policy if exists "Admins can delete Vixrex blog relations"
  on public.vixrex_blog_article_relations;
create policy "Admins can delete Vixrex blog relations"
  on public.vixrex_blog_article_relations
  for delete
  to authenticated
  using (
    exists (select 1 from public.admins where admins.user_id = auth.uid())
  );

-- Mevcut iki taslak için yalnız doğrulanmış metadata atanır; yayın durumları değişmez.
update public.vixrex_blog_articles
set
  primary_topic = 'dijital-vitrin-web',
  purpose = 'musteri-kazanma',
  sector_ids = array['kuafor']::text[],
  location_scope = 'national',
  tags = array['kuafor', 'internet-sitesi', 'dijital-vitrin']::text[],
  provenance = 'vixrex-editorial'
where slug = 'kuafor-icin-internet-sitesi'
  and status = 'draft';

update public.vixrex_blog_articles
set
  primary_topic = 'google-yerel-gorunurluk',
  purpose = 'gorunurluk-artirma',
  sector_ids = '{}'::text[],
  location_scope = 'national',
  tags = array['google', 'yerel-seo', 'isletme-profili']::text[],
  provenance = 'vixrex-editorial'
where slug = 'isletmemi-googleda-nasil-gosteririm'
  and status = 'draft';