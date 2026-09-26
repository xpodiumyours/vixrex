-- ============================================================================
-- VITRIN OLCER — profesyonel etkileşim omurgası
-- 2026-09-26
--
-- AMAÇ
--   Ham ölçüm olaylarını, kalıcı beğeni/yorum durumunu ve sahip özetini
--   birbirinden ayırır. Doğrudan tablo erişimi açılmaz; public yüzey yalnız
--   dar SECURITY DEFINER RPC'lerle yazıp okur.
--
-- KORUMALAR
--   - Sahip/önizleme olayları istemci tarafında ayrıca kapatılır.
--   - session_key yeni kayıtlarda ham saklanmaz; SHA-256 aktör anahtarı tutulur.
--   - product_view aynı aktör/ürün için 30 dakika içinde tekilleştirilir.
--   - yorum kalıcı Google hesabı ister; e-posta public yanıta girmez.
--   - sahip raporu auth.uid() ile stores.user_id eşleşmeden veri döndürmez.
-- ============================================================================

begin;

alter table public.vitrin_engagement_events
  add column if not exists quantity integer,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

alter table public.vitrin_engagement_events
  drop constraint if exists vitrin_engagement_events_event_type_check;

alter table public.vitrin_engagement_events
  add constraint vitrin_engagement_events_event_type_check
  check (event_type in (
    'whatsapp_click',
    'phone_click',
    'directions_click',
    'product_view',
    'product_like',
    'product_unlike',
    'comment_create',
    'cart_add',
    'cart_remove',
    'cart_quantity_change',
    'cart_whatsapp_order'
  ));

alter table public.vitrin_engagement_events
  drop constraint if exists vitrin_engagement_events_quantity_check;

alter table public.vitrin_engagement_events
  add constraint vitrin_engagement_events_quantity_check
  check (quantity is null or (quantity >= 1 and quantity <= 999));

create index if not exists idx_vitrin_engagement_events_type_created
  on public.vitrin_engagement_events (store_id, event_type, created_at desc);

create index if not exists idx_vitrin_engagement_events_product_created
  on public.vitrin_engagement_events (product_id, created_at desc)
  where product_id is not null;

comment on column public.vitrin_engagement_events.session_key is
  'Eski satırlarda tarihsel session değeri bulunabilir. Vitrin Ölçer v2 RPC yeni kayıtlarda ham anahtar yerine SHA-256 aktör anahtarı yazar.';

create table if not exists public.vitrin_product_likes (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  actor_key text not null check (pg_catalog.length(actor_key) >= 32),
  user_id uuid,
  created_at timestamptz not null default now(),
  unique (product_id, actor_key)
);

alter table public.vitrin_product_likes enable row level security;
revoke all on table public.vitrin_product_likes from public, anon, authenticated;

create index if not exists idx_vitrin_product_likes_store_created
  on public.vitrin_product_likes (store_id, created_at desc);

create table if not exists public.vitrin_product_comments (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  user_id uuid not null,
  author_name text not null check (
    pg_catalog.length(pg_catalog.btrim(author_name)) between 1 and 80
  ),
  body text not null check (
    pg_catalog.length(pg_catalog.btrim(body)) between 3 and 500
  ),
  status text not null default 'published' check (
    status in ('published', 'hidden', 'deleted')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.vitrin_product_comments enable row level security;
revoke all on table public.vitrin_product_comments from public, anon, authenticated;

create index if not exists idx_vitrin_product_comments_product_created
  on public.vitrin_product_comments (product_id, created_at desc)
  where status = 'published';

create index if not exists idx_vitrin_product_comments_store_created
  on public.vitrin_product_comments (store_id, created_at desc);

create or replace function public.vitrin_actor_key(p_session_key text)
returns text
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  v_session text := pg_catalog.btrim(coalesce(p_session_key, ''));
  v_user_id uuid := auth.uid();
begin
  if v_user_id is not null and public.is_permanent_user() then
    return 'u:' || encode(sha256(v_user_id::text::bytea), 'hex');
  end if;

  if pg_catalog.length(v_session) < 16 then
    return null;
  end if;

  return 's:' || encode(sha256(v_session::bytea), 'hex');
end;
$$;

revoke all on function public.vitrin_actor_key(text) from public, anon, authenticated;

create or replace function public.record_vitrin_engagement_v2(
  p_store_slug text,
  p_event_type text,
  p_session_key text,
  p_product_slug text default null,
  p_quantity integer default null,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_store_id uuid;
  v_product_id uuid;
  v_event_type text := lower(pg_catalog.btrim(coalesce(p_event_type, '')));
  v_actor_key text := public.vitrin_actor_key(p_session_key);
  v_quantity integer;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  v_dedupe interval;
begin
  if v_actor_key is null then
    return;
  end if;

  if v_event_type not in (
    'whatsapp_click',
    'phone_click',
    'directions_click',
    'product_view',
    'product_like',
    'product_unlike',
    'comment_create',
    'cart_add',
    'cart_remove',
    'cart_quantity_change',
    'cart_whatsapp_order'
  ) then
    return;
  end if;

  select s.id into v_store_id
  from public.stores s
  where s.slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and s.is_published = true
  limit 1;

  if v_store_id is null then
    return;
  end if;

  if p_product_slug is not null and pg_catalog.btrim(p_product_slug) <> '' then
    select p.id into v_product_id
    from public.products p
    where p.store_id = v_store_id
      and p.slug = pg_catalog.btrim(p_product_slug)
      and p.is_active = true
      and p.is_visible = true
    limit 1;

    if v_product_id is null then
      return;
    end if;
  elsif v_event_type in (
    'product_view',
    'product_like',
    'product_unlike',
    'comment_create',
    'cart_add',
    'cart_remove',
    'cart_quantity_change'
  ) then
    return;
  end if;

  if p_quantity is not null then
    v_quantity := greatest(1, least(999, p_quantity));
  end if;

  if jsonb_typeof(v_metadata) <> 'object'
     or pg_column_size(v_metadata) > 4096 then
    v_metadata := '{}'::jsonb;
  end if;

  v_dedupe := case
    when v_event_type = 'product_view' then interval '30 minutes'
    when v_event_type in ('whatsapp_click', 'phone_click', 'directions_click', 'cart_whatsapp_order')
      then interval '5 seconds'
    else null
  end;

  if v_dedupe is not null and exists (
    select 1
    from public.vitrin_engagement_events e
    where e.store_id = v_store_id
      and e.event_type = v_event_type
      and e.session_key = v_actor_key
      and e.product_id is not distinct from v_product_id
      and e.created_at >= now() - v_dedupe
  ) then
    return;
  end if;

  if (
    select count(*)
    from public.vitrin_engagement_events e
    where e.store_id = v_store_id
      and e.session_key = v_actor_key
      and e.created_at >= now() - interval '1 minute'
  ) >= 120 then
    return;
  end if;

  insert into public.vitrin_engagement_events (
    store_id,
    event_type,
    product_id,
    session_key,
    quantity,
    metadata
  )
  values (
    v_store_id,
    v_event_type,
    v_product_id,
    v_actor_key,
    v_quantity,
    v_metadata
  );
end;
$$;

revoke all on function public.record_vitrin_engagement_v2(text,text,text,text,integer,jsonb)
  from public;
grant execute on function public.record_vitrin_engagement_v2(text,text,text,text,integer,jsonb)
  to anon, authenticated, service_role;

create or replace function public.record_vitrin_engagement(
  p_store_slug text,
  p_event_type text,
  p_session_key text,
  p_product_slug text default null
)
returns void
language sql
security invoker
set search_path = pg_catalog, public
as $$
  select public.record_vitrin_engagement_v2(
    p_store_slug,
    p_event_type,
    p_session_key,
    p_product_slug,
    null,
    '{}'::jsonb
  );
$$;

revoke all on function public.record_vitrin_engagement(text,text,text,text) from public;
grant execute on function public.record_vitrin_engagement(text,text,text,text)
  to anon, authenticated;

create or replace function public.toggle_product_like(
  p_store_slug text,
  p_product_slug text,
  p_session_key text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_store_id uuid;
  v_product_id uuid;
  v_actor_key text := public.vitrin_actor_key(p_session_key);
  v_user_id uuid := case when public.is_permanent_user() then auth.uid() else null end;
  v_session_actor_key text;
  v_liked boolean;
  v_count bigint;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if pg_catalog.length(pg_catalog.btrim(coalesce(p_session_key, ''))) >= 16 then
    v_session_actor_key := 's:' || encode(
      sha256(pg_catalog.btrim(p_session_key)::bytea),
      'hex'
    );
  end if;

  if v_actor_key is null then
    raise exception 'INVALID_VISITOR';
  end if;

  select s.id, p.id into v_store_id, v_product_id
  from public.stores s
  join public.products p on p.store_id = s.id
  where s.slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and s.is_published = true
    and p.slug = pg_catalog.btrim(coalesce(p_product_slug, ''))
    and p.is_active = true
    and p.is_visible = true
  limit 1;

  if v_product_id is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  if (
    select count(*)
    from public.vitrin_engagement_events e
    where e.store_id = v_store_id
      and e.session_key = v_actor_key
      and e.event_type in ('product_like', 'product_unlike')
      and e.created_at >= now() - interval '1 minute'
  ) >= 20 then
    raise exception 'RATE_LIMITED';
  end if;

  if exists (
    select 1 from public.vitrin_product_likes
    where product_id = v_product_id
      and actor_key in (
        v_actor_key,
        coalesce(v_session_actor_key, v_actor_key)
      )
  ) then
    delete from public.vitrin_product_likes
    where product_id = v_product_id
      and actor_key in (
        v_actor_key,
        coalesce(v_session_actor_key, v_actor_key)
      );
    v_liked := false;
    perform public.record_vitrin_engagement_v2(
      p_store_slug, 'product_unlike', p_session_key, p_product_slug, null, '{}'::jsonb
    );
  else
    insert into public.vitrin_product_likes (
      store_id, product_id, actor_key, user_id
    ) values (
      v_store_id, v_product_id, v_actor_key, v_user_id
    )
    on conflict (product_id, actor_key) do nothing;
    v_liked := true;
    perform public.record_vitrin_engagement_v2(
      p_store_slug, 'product_like', p_session_key, p_product_slug, null, '{}'::jsonb
    );
  end if;

  select count(*) into v_count
  from public.vitrin_product_likes
  where product_id = v_product_id;

  return jsonb_build_object('liked', v_liked, 'like_count', v_count);
end;
$$;

revoke all on function public.toggle_product_like(text,text,text)
  from public, anon;
grant execute on function public.toggle_product_like(text,text,text)
  to authenticated;

create or replace function public.get_product_social_state(
  p_store_slug text,
  p_product_slug text,
  p_session_key text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_product_id uuid;
  v_actor_key text := public.vitrin_actor_key(p_session_key);
  v_session_actor_key text;
  v_user_id uuid := auth.uid();
begin
  if pg_catalog.length(pg_catalog.btrim(coalesce(p_session_key, ''))) >= 16 then
    v_session_actor_key := 's:' || encode(
      sha256(pg_catalog.btrim(p_session_key)::bytea),
      'hex'
    );
  end if;
  select p.id into v_product_id
  from public.stores s
  join public.products p on p.store_id = s.id
  where s.slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and s.is_published = true
    and p.slug = pg_catalog.btrim(coalesce(p_product_slug, ''))
    and p.is_active = true
    and p.is_visible = true
  limit 1;

  if v_product_id is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  return jsonb_build_object(
    'like_count', (
      select count(*) from public.vitrin_product_likes l
      where l.product_id = v_product_id
    ),
    'liked', (
      v_actor_key is not null and exists (
        select 1 from public.vitrin_product_likes l
        where l.product_id = v_product_id
          and l.actor_key in (
            v_actor_key,
            coalesce(v_session_actor_key, v_actor_key)
          )
      )
    ),
    'comment_count', (
      select count(*) from public.vitrin_product_comments c
      where c.product_id = v_product_id and c.status = 'published'
    ),
    'comments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', q.id,
        'author_name', q.author_name,
        'body', q.body,
        'created_at', q.created_at,
        'can_delete', q.can_delete
      ) order by q.created_at desc)
      from (
        select
          c.id,
          c.author_name,
          c.body,
          c.created_at,
          (v_user_id is not null and c.user_id = v_user_id) as can_delete
        from public.vitrin_product_comments c
        where c.product_id = v_product_id
          and c.status = 'published'
        order by c.created_at desc
        limit 20
      ) q
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_product_social_state(text,text,text) from public;
grant execute on function public.get_product_social_state(text,text,text)
  to anon, authenticated;

create or replace function public.create_product_comment(
  p_store_slug text,
  p_product_slug text,
  p_session_key text,
  p_body text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_store_id uuid;
  v_product_id uuid;
  v_body text := pg_catalog.btrim(coalesce(p_body, ''));
  v_user_id uuid := auth.uid();
  v_author_name text;
  v_id uuid;
begin
  if v_user_id is null or not public.is_permanent_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  if pg_catalog.length(v_body) < 3 or pg_catalog.length(v_body) > 500 then
    raise exception 'INVALID_COMMENT';
  end if;

  select s.id, p.id into v_store_id, v_product_id
  from public.stores s
  join public.products p on p.store_id = s.id
  where s.slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and s.is_published = true
    and p.slug = pg_catalog.btrim(coalesce(p_product_slug, ''))
    and p.is_active = true
    and p.is_visible = true
  limit 1;

  if v_product_id is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  if (
    select count(*)
    from public.vitrin_product_comments c
    where c.user_id = v_user_id
      and c.created_at >= now() - interval '10 minutes'
      and c.status <> 'deleted'
  ) >= 5 then
    raise exception 'COMMENT_RATE_LIMIT';
  end if;

  if exists (
    select 1
    from public.vitrin_product_comments c
    where c.user_id = v_user_id
      and c.product_id = v_product_id
      and c.body = v_body
      and c.created_at >= now() - interval '10 minutes'
      and c.status <> 'deleted'
  ) then
    raise exception 'DUPLICATE_COMMENT';
  end if;

  v_author_name := pg_catalog.btrim(coalesce(
    auth.jwt() -> 'user_metadata' ->> 'full_name',
    auth.jwt() -> 'user_metadata' ->> 'name',
    'Vixrex kullanıcısı'
  ));
  v_author_name := pg_catalog.left(v_author_name, 80);
  if v_author_name = '' then
    v_author_name := 'Vixrex kullanıcısı';
  end if;

  insert into public.vitrin_product_comments (
    store_id, product_id, user_id, author_name, body
  ) values (
    v_store_id, v_product_id, v_user_id, v_author_name, v_body
  )
  returning id into v_id;

  perform public.record_vitrin_engagement_v2(
    p_store_slug,
    'comment_create',
    p_session_key,
    p_product_slug,
    null,
    '{}'::jsonb
  );

  return jsonb_build_object(
    'id', v_id,
    'author_name', v_author_name,
    'body', v_body,
    'created_at', now(),
    'can_delete', true
  );
end;
$$;

revoke all on function public.create_product_comment(text,text,text,text) from public;
grant execute on function public.create_product_comment(text,text,text,text)
  to authenticated;

create or replace function public.delete_my_product_comment(p_comment_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if auth.uid() is null or not public.is_permanent_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  update public.vitrin_product_comments
  set status = 'deleted', updated_at = now()
  where id = p_comment_id
    and user_id = auth.uid();
end;
$$;

revoke all on function public.delete_my_product_comment(uuid) from public;
grant execute on function public.delete_my_product_comment(uuid) to authenticated;

create or replace function public.set_product_comment_status(
  p_comment_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_status text := lower(pg_catalog.btrim(coalesce(p_status, '')));
begin
  if auth.uid() is null or not public.is_permanent_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  if v_status not in ('published', 'hidden', 'deleted') then
    raise exception 'INVALID_STATUS';
  end if;

  update public.vitrin_product_comments c
  set status = v_status, updated_at = now()
  where c.id = p_comment_id
    and exists (
      select 1
      from public.stores s
      where s.id = c.store_id
        and s.user_id = auth.uid()
    );

  if not found then
    raise exception 'NOT_FOUND_OR_FORBIDDEN';
  end if;
end;
$$;

revoke all on function public.set_product_comment_status(uuid,text) from public;
grant execute on function public.set_product_comment_status(uuid,text)
  to authenticated;

create or replace function public.get_vitrin_olcer_summary(p_days integer default 7)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_days integer := greatest(1, least(90, coalesce(p_days, 7)));
  v_start timestamptz;
  v_start_date date;
  v_visitors bigint;
  v_orders bigint;
begin
  if v_user_id is null or not public.is_permanent_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  select s.id into v_store_id
  from public.stores s
  where s.user_id = v_user_id
  order by s.created_at asc
  limit 1;

  if v_store_id is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  v_start := now() - make_interval(days => v_days);
  v_start_date := ((now() at time zone 'Europe/Istanbul')::date) - (v_days - 1);

  select count(distinct vv.session_key) into v_visitors
  from public.vitrin_views vv
  where vv.store_id = v_store_id
    and vv.viewed_date >= v_start_date;

  select count(distinct coalesce(
    nullif(e.metadata ->> 'order_key', ''),
    e.id::text
  )) into v_orders
  from public.vitrin_engagement_events e
  where e.store_id = v_store_id
    and e.event_type = 'cart_whatsapp_order'
    and e.created_at >= v_start;

  return jsonb_build_object(
    'days', v_days,
    'period_start', v_start,
    'period_end', now(),
    'unique_visitors', coalesce(v_visitors, 0),
    'store_views', (
      select count(*) from public.vitrin_views vv
      where vv.store_id = v_store_id and vv.viewed_date >= v_start_date
    ),
    'product_views', (
      select count(*) from public.vitrin_engagement_events e
      where e.store_id = v_store_id and e.event_type = 'product_view' and e.created_at >= v_start
    ),
    'likes', (
      select count(*) from public.vitrin_engagement_events e
      where e.store_id = v_store_id
        and e.event_type = 'product_like'
        and e.created_at >= v_start
    ),
    'comments', (
      select count(*) from public.vitrin_engagement_events e
      where e.store_id = v_store_id
        and e.event_type = 'comment_create'
        and e.created_at >= v_start
    ),
    'cart_adds', (
      select count(*) from public.vitrin_engagement_events e
      where e.store_id = v_store_id and e.event_type = 'cart_add' and e.created_at >= v_start
    ),
    'whatsapp_orders', coalesce(v_orders, 0),
    'whatsapp_clicks', (
      select count(*) from public.vitrin_engagement_events e
      where e.store_id = v_store_id and e.event_type = 'whatsapp_click' and e.created_at >= v_start
    ),
    'conversion_percent', case
      when coalesce(v_visitors, 0) = 0 then 0
      else round((v_orders::numeric * 100) / v_visitors::numeric, 1)
    end,
    'traffic_sources', coalesce((
      select jsonb_agg(jsonb_build_object('source', q.source, 'count', q.count) order by q.count desc)
      from (
        select vv.source, count(*) as count
        from public.vitrin_views vv
        where vv.store_id = v_store_id and vv.viewed_date >= v_start_date
        group by vv.source
        order by count(*) desc
      ) q
    ), '[]'::jsonb),
    'top_products', coalesce((
      select jsonb_agg(jsonb_build_object(
        'slug', q.slug,
        'name', q.name,
        'views', q.views,
        'likes', q.likes,
        'comments', q.comments,
        'cart_adds', q.cart_adds,
        'orders', q.orders
      ) order by q.cart_adds desc, q.views desc, q.likes desc)
      from (
        select
          p.slug,
          p.name,
          count(*) filter (
            where e.event_type = 'product_view' and e.created_at >= v_start
          ) as views,
          count(*) filter (
            where e.event_type = 'product_like' and e.created_at >= v_start
          ) as likes,
          count(*) filter (
            where e.event_type = 'comment_create' and e.created_at >= v_start
          ) as comments,
          count(*) filter (
            where e.event_type = 'cart_add' and e.created_at >= v_start
          ) as cart_adds,
          count(distinct coalesce(
            nullif(e.metadata ->> 'order_key', ''),
            e.id::text
          )) filter (
            where e.event_type = 'cart_whatsapp_order' and e.created_at >= v_start
          ) as orders
        from public.products p
        left join public.vitrin_engagement_events e on e.product_id = p.id
        where p.store_id = v_store_id
          and p.is_active = true
        group by p.id, p.slug, p.name
        order by cart_adds desc, views desc, likes desc
        limit 5
      ) q
    ), '[]'::jsonb),
    'recent_comments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', q.id,
        'product_slug', q.product_slug,
        'product_name', q.product_name,
        'author_name', q.author_name,
        'body', q.body,
        'status', q.status,
        'created_at', q.created_at
      ) order by q.created_at desc)
      from (
        select c.id, p.slug as product_slug, p.name as product_name,
               c.author_name, c.body, c.status, c.created_at
        from public.vitrin_product_comments c
        join public.products p on p.id = c.product_id
        where c.store_id = v_store_id
          and c.status <> 'deleted'
        order by c.created_at desc
        limit 20
      ) q
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_vitrin_olcer_summary(integer) from public;
grant execute on function public.get_vitrin_olcer_summary(integer) to authenticated;


create or replace function public.record_vitrin_view_web(
  p_store_slug text,
  p_session_key text,
  p_source text,
  p_request_fingerprint text,
  p_user_agent text default null
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $
declare
  v_store_id uuid;
  v_store_slug text;
  v_session_key text := pg_catalog.btrim(coalesce(p_session_key, ''));
  v_source text := lower(pg_catalog.btrim(coalesce(p_source, 'unknown')));
  v_fingerprint text := pg_catalog.btrim(coalesce(p_request_fingerprint, ''));
  v_user_agent text := pg_catalog.left(pg_catalog.btrim(coalesce(p_user_agent, '')), 300);
  v_viewed_date date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if pg_catalog.length(v_session_key) < 16
     or pg_catalog.length(v_fingerprint) < 32 then
    return;
  end if;

  if v_source not in (
    'direct', 'qr', 'share', 'unknown',
    'google', 'instagram', 'facebook', 'whatsapp', 'twitter', 'tiktok',
    'diger_site'
  ) then
    v_source := 'unknown';
  end if;

  select s.id, s.slug
    into v_store_id, v_store_slug
  from public.stores s
  where s.slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and s.is_published = true
  limit 1;

  if v_store_id is null then
    return;
  end if;

  -- Aynı teknik kaynaktan günde 50 farklı oturumdan fazlasını vitrin
  -- ziyaretine çevirmeyiz. Normal NAT/ofis trafiğini bozmayacak kadar geniş,
  -- session reset botlarını şişirmeyecek kadar sınırlı bir eşiktir.
  if (
    select count(*)
    from public.vitrin_views vv
    where vv.store_id = v_store_id
      and vv.viewer_ip = v_fingerprint
      and vv.viewed_date = v_viewed_date
  ) >= 50 then
    return;
  end if;

  insert into public.vitrin_views (
    store_id,
    store_slug,
    session_key,
    source,
    viewed_date,
    viewer_ip,
    user_agent
  ) values (
    v_store_id,
    v_store_slug,
    v_session_key,
    v_source,
    v_viewed_date,
    v_fingerprint,
    nullif(v_user_agent, '')
  )
  on conflict (store_id, session_key, viewed_date) do nothing;
end;
$;

revoke all on function public.record_vitrin_view_web(text,text,text,text,text)
  from public, anon, authenticated;
grant execute on function public.record_vitrin_view_web(text,text,text,text,text)
  to service_role;

comment on function public.record_vitrin_view_web(text,text,text,text,text) is
  'Web vitrin ziyaretini sunucu kapısından kaydeder. viewer_ip alanına ham IP değil SHA-256 teknik parmak izi yazılır.';

notify pgrst, 'reload schema';

commit;
