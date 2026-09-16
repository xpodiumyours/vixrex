alter table public.vitrin_engagement_events
  add column if not exists surface text not null default 'unknown';

alter table public.vitrin_engagement_events
  drop constraint if exists vitrin_engagement_events_surface_check;

alter table public.vitrin_engagement_events
  add constraint vitrin_engagement_events_surface_check
  check (
    surface in (
      'unknown',
      'storefront_hero',
      'storefront_contact',
      'product_card',
      'product_quick_view',
      'product_detail',
      'storefront_floating'
    )
  );

create index if not exists idx_vitrin_engagement_events_product_id
  on public.vitrin_engagement_events (product_id);

alter table public.vitrin_engagement_events enable row level security;

revoke all on table public.vitrin_engagement_events from anon, authenticated;

alter table public.vitrin_views
  drop constraint if exists vitrin_views_source_check;

alter table public.vitrin_views
  add constraint vitrin_views_source_check
  check (
    source in (
      'direct',
      'qr',
      'share',
      'unknown',
      'google',
      'instagram',
      'facebook',
      'whatsapp',
      'twitter',
      'tiktok',
      'diger_site',
      'kesfet'
    )
  );

create or replace function public.record_vitrin_view(
  p_store_slug text,
  p_session_key text,
  p_source text default 'unknown'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store_id uuid;
  v_store_slug text;
  v_session_key text;
  v_source text;
  v_viewed_date date;
begin
  v_session_key := pg_catalog.btrim(coalesce(p_session_key, ''));

  if pg_catalog.length(v_session_key) < 16 then
    return;
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

  v_source := pg_catalog.lower(pg_catalog.btrim(coalesce(p_source, 'unknown')));

  if v_source not in (
    'direct', 'qr', 'share', 'unknown',
    'google', 'instagram', 'facebook', 'whatsapp', 'twitter', 'tiktok',
    'diger_site', 'kesfet'
  ) then
    v_source := 'unknown';
  end if;

  v_viewed_date := (now() at time zone 'Europe/Istanbul')::date;

  insert into public.vitrin_views (
    store_id,
    store_slug,
    session_key,
    source,
    viewed_date
  ) values (
    v_store_id,
    v_store_slug,
    v_session_key,
    v_source,
    v_viewed_date
  )
  on conflict (store_id, session_key, viewed_date) do nothing;
end;
$$;

create or replace function public.record_vitrin_engagement_v2(
  p_store_slug text,
  p_event_type text,
  p_session_key text,
  p_product_slug text default null,
  p_surface text default 'unknown'
)
returns void
language plpgsql
security definer
set search_path = 'pg_catalog', 'public'
as $$
declare
  v_store_id uuid;
  v_session_key text := pg_catalog.btrim(coalesce(p_session_key, ''));
  v_event_type text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_event_type, '')));
  v_surface text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_surface, 'unknown')));
  v_product_id uuid;
begin
  if pg_catalog.length(v_session_key) < 16 then
    return;
  end if;

  if v_event_type not in ('whatsapp_click', 'phone_click', 'directions_click', 'product_view') then
    return;
  end if;

  if v_surface not in (
    'unknown',
    'storefront_hero',
    'storefront_contact',
    'product_card',
    'product_quick_view',
    'product_detail',
    'storefront_floating'
  ) then
    v_surface := 'unknown';
  end if;

  select id into v_store_id
  from public.stores
  where slug = pg_catalog.btrim(coalesce(p_store_slug, ''))
    and is_published = true
  limit 1;

  if v_store_id is null then
    return;
  end if;

  if p_product_slug is not null then
    select id into v_product_id
    from public.products
    where store_id = v_store_id
      and slug = pg_catalog.btrim(p_product_slug)
    limit 1;
  end if;

  insert into public.vitrin_engagement_events (
    store_id,
    event_type,
    product_id,
    session_key,
    surface
  ) values (
    v_store_id,
    v_event_type,
    v_product_id,
    v_session_key,
    v_surface
  );
end;
$$;

revoke all on function public.record_vitrin_engagement_v2(text, text, text, text, text) from public;
grant execute on function public.record_vitrin_engagement_v2(text, text, text, text, text) to anon, authenticated;
