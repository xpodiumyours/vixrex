-- Katman 3 — merkezi Vixrex blog yazısını vitrin bloguna güvenli taslak olarak çekme.
--
-- Güvenlik sınırları:
-- - yalnız published merkezi yazı kaynak olabilir
-- - hedef store DB içinde yeniden yetkilendirilir
-- - yeni store_articles satırı daima draft olur
-- - aynı kaynak aynı vitrine idempotenttir
-- - merkezi kaynak silinirse vitrin kopyası silinmez; slug provenance snapshot'ı kalır

alter table public.store_articles
  add column if not exists source_vixrex_blog_article_id uuid,
  add column if not exists source_vixrex_blog_article_slug text,
  add column if not exists source_vixrex_blog_import_mode text,
  add column if not exists source_vixrex_blog_imported_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'store_articles_source_vixrex_blog_article_fkey'
      and conrelid = 'public.store_articles'::regclass
  ) then
    alter table public.store_articles
      add constraint store_articles_source_vixrex_blog_article_fkey
      foreign key (source_vixrex_blog_article_id)
      references public.vixrex_blog_articles(id)
      on delete set null;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'store_articles_source_vixrex_blog_import_mode_check'
      and conrelid = 'public.store_articles'::regclass
  ) then
    alter table public.store_articles
      add constraint store_articles_source_vixrex_blog_import_mode_check
      check (
        source_vixrex_blog_import_mode is null
        or source_vixrex_blog_import_mode in ('linked_excerpt', 'adaptable_draft')
      );
  end if;
end
$$;

create unique index if not exists uq_store_articles_vixrex_source_slug
  on public.store_articles (store_slug, source_vixrex_blog_article_slug)
  where source_vixrex_blog_article_slug is not null;

comment on column public.store_articles.source_vixrex_blog_article_id is
  'Merkezi Vixrex blog kaynağının canlı FK kimliği. Kaynak silinirse null olabilir; provenance slug snapshot ile korunur.';
comment on column public.store_articles.source_vixrex_blog_article_slug is
  'İçe aktarılan merkezi Vixrex yazısının kalıcı slug snapshotı; duplicate/idempotency anahtarıdır.';
comment on column public.store_articles.source_vixrex_blog_import_mode is
  'Katman 3 import modu: linked_excerpt veya adaptable_draft.';
comment on column public.store_articles.source_vixrex_blog_imported_at is
  'Merkezi Vixrex yazısının bu vitrine ilk kez taslak olarak çekildiği an.';

create or replace function public.import_vixrex_blog_article_to_store(
  p_store_slug text,
  p_source_article_id uuid,
  p_mode text,
  p_session_token text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_store_slug text := pg_catalog.btrim(coalesce(p_store_slug, ''));
  v_mode text := pg_catalog.btrim(coalesce(p_mode, ''));
  v_token text := pg_catalog.btrim(coalesce(p_session_token, ''));
  v_token_hash text;
  v_store_id uuid;
  v_store_is_demo boolean;
  v_authorized boolean := false;
  v_source record;
  v_article_id uuid;
  v_article_slug text;
  v_content text;
  v_created boolean := false;
begin
  if v_store_slug = '' then
    raise exception 'INVALID_STORE_SLUG' using errcode = 'P0001';
  end if;

  if p_source_article_id is null then
    raise exception 'INVALID_SOURCE_ARTICLE' using errcode = 'P0001';
  end if;

  if v_mode not in ('linked_excerpt', 'adaptable_draft') then
    raise exception 'INVALID_IMPORT_MODE' using errcode = 'P0001';
  end if;

  select s.id, coalesce(s.is_demo, false)
  into v_store_id, v_store_is_demo
  from public.stores s
  where s.slug = v_store_slug;

  if not found then
    raise exception 'STORE_NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_store_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  -- Next.js owner-session yolu: açık token DB'de hashlenir ve hedef store_id ile eşleşir.
  if v_token <> '' then
    if pg_catalog.length(v_token) = 64 and v_token ~ '^[0-9A-Fa-f]{64}$' then
      v_token_hash := encode(sha256(v_token::bytea), 'hex');
      select exists (
        select 1
        from public.owner_sessions os
        where os.store_id = v_store_id
          and os.session_token_hash = v_token_hash
          and os.consumed_at is not null
          and os.expires_at > now()
      ) into v_authorized;
    end if;
  end if;

  -- Flutter / hesap oturumu yolu: RLS ile aynı kullanıcı-sahipliği gerçeği DB içinde doğrulanır.
  if not v_authorized and auth.uid() is not null then
    select exists (
      select 1
      from public.stores s
      where s.id = v_store_id
        and s.user_id = auth.uid()
    ) into v_authorized;
  end if;

  if not v_authorized then
    raise exception 'STORE_NOT_AUTHORIZED' using errcode = 'P0001';
  end if;

  -- Taslak merkezi içerik hiçbir istemci yolundan import edilemez.
  select
    a.id,
    a.slug,
    a.title,
    a.summary,
    a.content,
    a.cover_image_url
  into v_source
  from public.vixrex_blog_articles a
  where a.id = p_source_article_id
    and a.status = 'published';

  if not found then
    raise exception 'SOURCE_NOT_PUBLISHED' using errcode = 'P0001';
  end if;

  -- Aynı kaynak aynı vitrinde zaten varsa ikinci satır üretme.
  select sa.id, sa.slug
  into v_article_id, v_article_slug
  from public.store_articles sa
  where sa.store_slug = v_store_slug
    and sa.source_vixrex_blog_article_slug = v_source.slug
  limit 1;

  if found then
    return jsonb_build_object(
      'created', false,
      'article_id', v_article_id,
      'article_slug', v_article_slug,
      'source_slug', v_source.slug,
      'mode', v_mode
    );
  end if;

  v_article_slug := pg_catalog.left(v_source.slug, 60);
  if exists (
    select 1 from public.store_articles sa
    where sa.store_slug = v_store_slug and sa.slug = v_article_slug
  ) then
    v_article_slug := pg_catalog.left(v_source.slug, 46)
      || '-vixrex-'
      || pg_catalog.substr(pg_catalog.replace(v_source.id::text, '-', ''), 1, 8);
  end if;

  if v_mode = 'linked_excerpt' then
    v_content := '<p>' || coalesce(v_source.summary, '') || '</p>'
      || '<p><a href="/blog/' || v_source.slug || '">Vixrex kaynak yazısını oku</a></p>';
  else
    v_content := coalesce(v_source.content, '');
  end if;

  insert into public.store_articles (
    store_slug,
    title,
    slug,
    summary,
    content,
    cover_image_url,
    article_type,
    seo_score,
    seo_errors,
    status,
    source_vixrex_blog_article_id,
    source_vixrex_blog_article_slug,
    source_vixrex_blog_import_mode,
    source_vixrex_blog_imported_at
  ) values (
    v_store_slug,
    v_source.title,
    v_article_slug,
    v_source.summary,
    v_content,
    v_source.cover_image_url,
    'standard',
    0,
    array[]::text[],
    'draft',
    v_source.id,
    v_source.slug,
    v_mode,
    now()
  )
  on conflict (store_slug, source_vixrex_blog_article_slug)
    where source_vixrex_blog_article_slug is not null
  do nothing
  returning id, slug into v_article_id, v_article_slug;

  if found then
    v_created := true;
  else
    select sa.id, sa.slug
    into v_article_id, v_article_slug
    from public.store_articles sa
    where sa.store_slug = v_store_slug
      and sa.source_vixrex_blog_article_slug = v_source.slug
    limit 1;
  end if;

  if v_article_id is null then
    raise exception 'IMPORT_FAILED' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'created', v_created,
    'article_id', v_article_id,
    'article_slug', v_article_slug,
    'source_slug', v_source.slug,
    'mode', v_mode
  );
end;
$$;

revoke execute on function public.import_vixrex_blog_article_to_store(text, uuid, text, text) from public;
grant execute on function public.import_vixrex_blog_article_to_store(text, uuid, text, text) to anon, authenticated;

notify pgrst, 'reload schema';
