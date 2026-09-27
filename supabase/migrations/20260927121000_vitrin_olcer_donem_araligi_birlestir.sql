-- get_vitrin_olcer_summary: ziyaret ve etkileşim zaman aralıkları birleştirildi.
--
-- SORUN (2026-09-27 Checkup turu, panoda "Vitrin Olcer donem hesabi" kusuru):
-- 7 gunluk ozet iki FARKLI pencere kullaniyordu:
--   ziyaret (vitrin_views):      viewed_date >= Istanbul gunu - (v_days - 1)
--   etkilesim (engagement):      created_at >= now() - make_interval(days)
-- Ilki N takvim gunu (Istanbul), ikincisi kayan 168 saat; ekran metni ise
-- "Son N gun ayni donem uzerinden hesaplanir" diyordu. Donusum orani
-- (conversion_percent) iki farkli pencerenin bolumu olarak yanilticiydi.
--
-- COZUM: tek ortak pencere. Ziyaret gun bazli tutuldugu icin (vitrin_views
-- dedup kunyesi gunluk) takvim gunu penceresi esas alindi; etkilesim
-- olaylari da ayni Istanbul gununun basindan itibaren sayiliyor. Artik
-- ziyaret, etkilesim, kaynak dagilimi ve ust urunler ayni [baslangic, now()]
-- araligini paylasiyor; period_start bu ortak baslangictir.
--
-- Sozlesme degismedi: giris/çikis anahtarlari ayni, yalniz degerlerin
-- donemi aynilasti. 20260927120000 ile uygulamasi beklemektedir.

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

  v_start_date := ((now() at time zone 'Europe/Istanbul')::date) - (v_days - 1);
  v_start := (v_start_date::timestamp) at time zone 'Europe/Istanbul';

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

-- Kayan zaman araligi kalintisi kalmis mi ve ortak pencere kurulmus mu —
-- CREATE etmek yetmez.
do $$
declare
  v_src text;
begin
  select p.prosrc into v_src
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'get_vitrin_olcer_summary';

  if position('make_interval' in v_src) > 0 then
    raise exception 'get_vitrin_olcer_summary hala kayan zaman araligi kullaniyor';
  end if;
  if position('v_start_date' in v_src) = 0 then
    raise exception 'get_vitrin_olcer_summary ortak gun penceresi kurmuyor';
  end if;
end;
$$;
