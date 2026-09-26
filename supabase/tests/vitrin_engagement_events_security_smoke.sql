do $$
declare
  v_rls_enabled boolean;
begin
  select c.relrowsecurity
  into v_rls_enabled
  from pg_class c
  where c.oid = 'public.vitrin_engagement_events'::regclass;

  if not coalesce(v_rls_enabled, false) then
    raise exception 'vitrin_engagement_events RLS kapali';
  end if;

  if has_table_privilege('anon', 'public.vitrin_engagement_events', 'SELECT')
     or has_table_privilege('anon', 'public.vitrin_engagement_events', 'INSERT')
     or has_table_privilege('anon', 'public.vitrin_engagement_events', 'UPDATE')
     or has_table_privilege('anon', 'public.vitrin_engagement_events', 'DELETE') then
    raise exception 'anon tablo yetkisi acik';
  end if;

  if has_table_privilege('authenticated', 'public.vitrin_engagement_events', 'SELECT')
     or has_table_privilege('authenticated', 'public.vitrin_engagement_events', 'INSERT')
     or has_table_privilege('authenticated', 'public.vitrin_engagement_events', 'UPDATE')
     or has_table_privilege('authenticated', 'public.vitrin_engagement_events', 'DELETE') then
    raise exception 'authenticated tablo yetkisi acik';
  end if;

  if not has_function_privilege(
    'anon',
    'public.record_vitrin_engagement(text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'anon record_vitrin_engagement execute kayboldu';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.record_vitrin_engagement(text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'authenticated record_vitrin_engagement execute kayboldu';
  end if;

  if not has_function_privilege(
    'anon',
    'public.get_haftalik_performans(text)',
    'EXECUTE'
  ) then
    raise exception 'anon get_haftalik_performans execute kayboldu';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_haftalik_performans(text)',
    'EXECUTE'
  ) then
    raise exception 'authenticated get_haftalik_performans execute kayboldu';
  end if;
  if not has_function_privilege(
    'anon',
    'public.record_vitrin_engagement_v2(text,text,text,text,integer,jsonb)',
    'EXECUTE'
  ) then
    raise exception 'anon record_vitrin_engagement_v2 execute kayboldu';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_vitrin_olcer_summary(integer)',
    'EXECUTE'
  ) then
    raise exception 'authenticated get_vitrin_olcer_summary execute kayboldu';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_vitrin_olcer_summary(integer)',
    'EXECUTE'
  ) then
    raise exception 'anon vitrin olcer ozetini okuyabiliyor';
  end if;

  if has_table_privilege('anon', 'public.vitrin_product_likes', 'SELECT')
     or has_table_privilege('authenticated', 'public.vitrin_product_likes', 'SELECT')
     or has_table_privilege('anon', 'public.vitrin_product_comments', 'SELECT')
     or has_table_privilege('authenticated', 'public.vitrin_product_comments', 'SELECT') then
    raise exception 'sosyal tablolar dogrudan okunabiliyor';
  end if;
end;
$;
