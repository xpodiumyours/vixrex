-- Vitrin Ölçer cihazı kaldırıldı: sayaçlar silindi, WhatsApp siparişi kendi
-- tablosuna alındı.
--
-- ÖLÇÜM (2026-11-22): ürün sayfası görüntülemesi GA4'te zaten sayılıyor —
--   doğrudan açılış:  g/collect ... dl=/v/<slug>/urun/<urun> & en=page_view → 204
--   menüden geçiş:    g/collect ... dl=/v/<slug>/urun/<urun> & en=page_view → 204
-- Aynı açılışta /api/vitrin-engagement de yazıyordu: aynı olay iki yere
-- gidiyordu. Sayaçlar bu yüzden kaldırılıyor; trafik rakamı Google'ın.
--
-- Sipariş ölçüm değil ticari kayıttır: eskiden yalnız
-- vitrin_engagement_events(cart_whatsapp_order) satırıydı ve başka hiçbir
-- tabloya yazılmıyordu. O satırlar aşağıda yeni tabloya taşınıyor.
--
-- Sayaç tabloları DÜŞÜRÜLMEZ, arşive alınır (rename): geri dönüşü tek
-- cümlelik olsun diye. Gerekirse:
--   alter table public.vitrin_engagement_events_arsiv_20261122
--     rename to vitrin_engagement_events;

create table if not exists public.vitrin_whatsapp_orders (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  order_key text not null check (
    pg_catalog.length(pg_catalog.btrim(order_key)) between 8 and 64
  ),
  session_key text not null check (pg_catalog.length(pg_catalog.btrim(session_key)) >= 16),
  item_count integer not null check (item_count between 1 and 200),
  total_quantity integer not null check (total_quantity between 1 and 99999),
  total_amount numeric(12, 2),
  items jsonb not null check (jsonb_typeof(items) = 'array'),
  created_at timestamptz not null default now(),
  unique (store_id, order_key)
);

create index if not exists idx_vitrin_whatsapp_orders_store_created
  on public.vitrin_whatsapp_orders (store_id, created_at desc);

alter table public.vitrin_whatsapp_orders enable row level security;
revoke all on table public.vitrin_whatsapp_orders from public, anon, authenticated;

create or replace function public.record_vitrin_whatsapp_order(
  p_store_slug text,
  p_session_key text,
  p_order_key text,
  p_items jsonb,
  p_total_quantity integer,
  p_total_amount numeric default null
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_store_id uuid;
  v_session_key text := pg_catalog.btrim(coalesce(p_session_key, ''));
  v_order_key text := pg_catalog.btrim(coalesce(p_order_key, ''));
  v_items jsonb := coalesce(p_items, '[]'::jsonb);
begin
  if pg_catalog.length(v_session_key) < 16 then
    return;
  end if;

  if pg_catalog.length(v_order_key) < 8 or pg_catalog.length(v_order_key) > 64 then
    return;
  end if;

  if jsonb_typeof(v_items) <> 'array' then
    return;
  end if;

  if jsonb_array_length(v_items) = 0 or jsonb_array_length(v_items) > 200 then
    return;
  end if;

  if pg_column_size(v_items) > 16384 then
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

  insert into public.vitrin_whatsapp_orders (
    store_id,
    order_key,
    session_key,
    item_count,
    total_quantity,
    total_amount,
    items
  ) values (
    v_store_id,
    v_order_key,
    v_session_key,
    jsonb_array_length(v_items),
    greatest(1, least(99999, coalesce(p_total_quantity, 1))),
    p_total_amount,
    v_items
  )
  on conflict (store_id, order_key) do nothing;
end;
$$;

revoke all on function public.record_vitrin_whatsapp_order(text, text, text, jsonb, integer, numeric) from public;
grant execute on function public.record_vitrin_whatsapp_order(text, text, text, jsonb, integer, numeric) to anon, authenticated;

insert into public.vitrin_whatsapp_orders (
  store_id,
  order_key,
  session_key,
  item_count,
  total_quantity,
  total_amount,
  items,
  created_at
)
select
  e.store_id,
  k.order_key,
  min(e.session_key),
  least(200, count(*)::integer),
  least(99999, sum(greatest(1, coalesce(e.quantity, 1)))::integer),
  null,
  jsonb_agg(
    jsonb_build_object(
      'product_slug', p.slug,
      'name', p.name,
      'quantity', greatest(1, coalesce(e.quantity, 1)),
      'unit_price', null,
      'variant', null
    )
  ),
  min(e.created_at)
from public.vitrin_engagement_events e
left join public.products p on p.id = e.product_id
cross join lateral (
  select coalesce(nullif(e.metadata ->> 'order_key', ''), e.id::text) as order_key
) k
where e.event_type = 'cart_whatsapp_order'
group by e.store_id, k.order_key
on conflict (store_id, order_key) do nothing;

create or replace function public.delete_store_with_token(p_slug text, p_edit_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_slug text := pg_catalog.btrim(p_slug);
  v_store_id uuid;
begin
  if v_slug is null or v_slug = '' then
    raise exception 'STORE_DELETE_NOT_ALLOWED' using errcode = 'P0001';
  end if;

  select id
  into v_store_id
  from public.stores
  where slug = v_slug
    and (
      (
        pg_catalog.length(pg_catalog.btrim(coalesce(p_edit_token, ''))) >= 24
        and edit_token = pg_catalog.btrim(p_edit_token)
      )
      or (
        auth.uid() is not null
        and user_id = auth.uid()
      )
    );

  if v_store_id is null then
    raise exception 'STORE_DELETE_NOT_ALLOWED' using errcode = 'P0001';
  end if;

  delete from public.store_instagram_imports
  where store_slug = v_slug
     or connection_id in (
       select id from public.store_instagram_connections where store_slug = v_slug
     );
  delete from public.store_instagram_tokens
  where connection_id in (
    select id from public.store_instagram_connections where store_slug = v_slug
  );
  delete from public.store_instagram_connections where store_slug = v_slug;
  delete from public.store_category_image_usage where store_id = v_store_id;
  delete from public.booking_settings where store_slug = v_slug;
  delete from public.store_articles where store_slug = v_slug;
  delete from public.appointments where store_slug = v_slug;
  delete from public.stores where id = v_store_id;
end;
$$;

create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_slug text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = 'P0001';
  end if;

  select slug into v_store_slug from public.stores where user_id = v_user_id limit 1;

  if v_store_slug is not null then
    delete from public.appointment_reschedule_requests
    where appointment_id in (select id from public.appointments where store_slug = v_store_slug);
    delete from public.appointments where store_slug = v_store_slug;
    delete from public.booking_blocks where store_slug = v_store_slug;
    delete from public.booking_settings where store_slug = v_store_slug;
    delete from public.article_reports
    where article_id in (select id from public.store_articles where store_slug = v_store_slug);
    delete from public.store_articles where store_slug = v_store_slug;
    delete from public.store_instagram_tokens
    where connection_id in (select id from public.store_instagram_connections where store_slug = v_store_slug);
    delete from public.store_instagram_imports where store_slug = v_store_slug;
    delete from public.store_instagram_connections where store_slug = v_store_slug;
    delete from public.legal_acceptance_events where store_slug = v_store_slug;
    delete from public.store_category_image_usage
    where store_id in (select id from public.stores where user_id = v_user_id);
    delete from public.stores where user_id = v_user_id;
  end if;

  delete from public.vitrin_product_comments where user_id = v_user_id;
  delete from public.vitrin_product_likes
  where user_id = v_user_id
     or actor_key = 'u:' || encode(sha256(v_user_id::text::bytea), 'hex');

  delete from public.owner_sessions where user_id = v_user_id;
  delete from public.profiles where id = v_user_id;
  delete from auth.users where id = v_user_id;
end;
$$;

alter function public.delete_store_with_token(text, text) owner to postgres;
revoke execute on function public.delete_store_with_token(text, text) from public, anon;
grant execute on function public.delete_store_with_token(text, text) to anon, authenticated, service_role;

alter function public.delete_user_account() owner to postgres;
revoke execute on function public.delete_user_account() from public, anon;
grant execute on function public.delete_user_account() to authenticated, service_role;

do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as imza
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'get_vitrin_olcer_summary',
        'get_haftalik_performans',
        'get_today_vitrin_view_count',
        'record_vitrin_engagement',
        'record_vitrin_engagement_v2',
        'record_vitrin_view',
        'record_vitrin_view_web'
      )
  loop
    execute format('drop function if exists %s', r.imza);
  end loop;
end;
$$;

alter table if exists public.vitrin_engagement_events
  rename to vitrin_engagement_events_arsiv_20261122;
alter table if exists public.vitrin_views
  rename to vitrin_views_arsiv_20261122;

do $$
declare
  v_kalan integer;
begin
  select count(*) into v_kalan
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'get_vitrin_olcer_summary',
      'get_haftalik_performans',
      'get_today_vitrin_view_count',
      'record_vitrin_engagement',
      'record_vitrin_engagement_v2',
      'record_vitrin_view',
      'record_vitrin_view_web'
    );

  if v_kalan > 0 then
    raise exception 'ölçüm fonksiyonları hâlâ duruyor: %', v_kalan;
  end if;

  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'record_vitrin_whatsapp_order'
  ) then
    raise exception 'record_vitrin_whatsapp_order kurulmadı';
  end if;

  if to_regclass('public.vitrin_engagement_events_arsiv_20261122') is null
     or to_regclass('public.vitrin_views_arsiv_20261122') is null then
    raise exception 'eski sayac tablolari arsive alinmadi';
  end if;
end;
$$;
