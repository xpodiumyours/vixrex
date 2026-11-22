do $$
declare
  v_rls_enabled boolean;
begin
  select c.relrowsecurity
  into v_rls_enabled
  from pg_class c
  where c.oid = 'public.vitrin_whatsapp_orders'::regclass;

  if not coalesce(v_rls_enabled, false) then
    raise exception 'vitrin_whatsapp_orders RLS kapali';
  end if;

  if has_table_privilege('anon', 'public.vitrin_whatsapp_orders', 'SELECT')
     or has_table_privilege('anon', 'public.vitrin_whatsapp_orders', 'INSERT')
     or has_table_privilege('anon', 'public.vitrin_whatsapp_orders', 'UPDATE')
     or has_table_privilege('anon', 'public.vitrin_whatsapp_orders', 'DELETE') then
    raise exception 'anon siparis tablosu yetkisi acik';
  end if;

  if has_table_privilege('authenticated', 'public.vitrin_whatsapp_orders', 'SELECT')
     or has_table_privilege('authenticated', 'public.vitrin_whatsapp_orders', 'INSERT')
     or has_table_privilege('authenticated', 'public.vitrin_whatsapp_orders', 'UPDATE')
     or has_table_privilege('authenticated', 'public.vitrin_whatsapp_orders', 'DELETE') then
    raise exception 'authenticated siparis tablosu yetkisi acik';
  end if;

  if not has_function_privilege(
    'anon',
    'public.record_vitrin_whatsapp_order(text,text,text,jsonb,integer,numeric)',
    'EXECUTE'
  ) then
    raise exception 'anon siparis kaydedemiyor';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.record_vitrin_whatsapp_order(text,text,text,jsonb,integer,numeric)',
    'EXECUTE'
  ) then
    raise exception 'authenticated siparis kaydedemiyor';
  end if;

  if to_regclass('public.vitrin_engagement_events') is not null then
    raise exception 'vitrin_engagement_events hala duruyor';
  end if;

  if to_regclass('public.vitrin_views') is not null then
    raise exception 'vitrin_views hala duruyor';
  end if;

  if to_regclass('public.vitrin_engagement_events_arsiv_20261122') is null
     or to_regclass('public.vitrin_views_arsiv_20261122') is null then
    raise exception 'eski sayac tablolari arsive alinmadi';
  end if;

  if to_regprocedure('public.record_vitrin_engagement(text,text,text,text)') is not null
     or to_regprocedure('public.record_vitrin_engagement_v2(text,text,text,text,integer,jsonb)') is not null
     or to_regprocedure('public.record_vitrin_view(text,text,text)') is not null
     or to_regprocedure('public.record_vitrin_view_web(text,text,text,text,text)') is not null then
    raise exception 'ziyaret/tikla sayaci fonksiyonu hala duruyor';
  end if;

  if to_regprocedure('public.get_vitrin_olcer_summary(integer)') is not null
     or to_regprocedure('public.get_haftalik_performans(text)') is not null
     or to_regprocedure('public.get_today_vitrin_view_count(text,text)') is not null then
    raise exception 'sayac ozeti fonksiyonu hala duruyor';
  end if;

  if has_table_privilege('anon', 'public.vitrin_product_likes', 'SELECT')
     or has_table_privilege('authenticated', 'public.vitrin_product_likes', 'SELECT')
     or has_table_privilege('anon', 'public.vitrin_product_comments', 'SELECT')
     or has_table_privilege('authenticated', 'public.vitrin_product_comments', 'SELECT') then
    raise exception 'sosyal tablolar dogrudan okunabiliyor';
  end if;
  if has_function_privilege(
    'anon',
    'public.toggle_product_like(text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'anon urun begenebiliyor';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.toggle_product_like(text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'authenticated urun begenemiyor';
  end if;

  if has_function_privilege(
    'anon',
    'public.create_product_comment(text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'anon yorum yazabiliyor';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.create_product_comment(text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'authenticated yorum yazamiyor';
  end if;

  if has_function_privilege(
    'anon',
    'public.set_product_comment_status(uuid,text)',
    'EXECUTE'
  ) then
    raise exception 'anon yorum moderasyonu yapabiliyor';
  end if;
end;
$$;
