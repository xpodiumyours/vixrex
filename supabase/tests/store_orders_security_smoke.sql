do $$
declare
  v_rls_enabled boolean;
begin
  select c.relrowsecurity
  into v_rls_enabled
  from pg_class c
  where c.oid = 'public.store_orders'::regclass;

  if not coalesce(v_rls_enabled, false) then
    raise exception 'store_orders RLS kapali';
  end if;

  if has_table_privilege('anon', 'public.store_orders', 'SELECT')
     or has_table_privilege('anon', 'public.store_orders', 'INSERT')
     or has_table_privilege('anon', 'public.store_orders', 'UPDATE')
     or has_table_privilege('anon', 'public.store_orders', 'DELETE') then
    raise exception 'anon store_orders tablo yetkisi acik';
  end if;

  if has_table_privilege('authenticated', 'public.store_orders', 'SELECT')
     or has_table_privilege('authenticated', 'public.store_orders', 'INSERT')
     or has_table_privilege('authenticated', 'public.store_orders', 'UPDATE')
     or has_table_privilege('authenticated', 'public.store_orders', 'DELETE') then
    raise exception 'authenticated store_orders tablo yetkisi acik';
  end if;

  if has_table_privilege('anon', 'public.store_order_items', 'SELECT')
     or has_table_privilege('anon', 'public.store_order_items', 'INSERT') then
    raise exception 'anon store_order_items tablo yetkisi acik';
  end if;

  if has_table_privilege('authenticated', 'public.store_order_items', 'SELECT')
     or has_table_privilege('authenticated', 'public.store_order_items', 'INSERT') then
    raise exception 'authenticated store_order_items tablo yetkisi acik';
  end if;

  if has_function_privilege('anon', 'public.create_store_order(text,text,text,text,text,text,text,jsonb)', 'EXECUTE') then
    raise exception 'anon create_store_order execute acik';
  end if;

  if has_function_privilege('authenticated', 'public.create_store_order(text,text,text,text,text,text,text,jsonb)', 'EXECUTE') then
    raise exception 'authenticated create_store_order execute acik';
  end if;

  if has_function_privilege('anon', 'public.record_store_order_payment(text,text,integer,text)', 'EXECUTE') then
    raise exception 'anon record_store_order_payment execute acik';
  end if;

  if has_function_privilege('authenticated', 'public.record_store_order_payment(text,text,integer,text)', 'EXECUTE') then
    raise exception 'authenticated record_store_order_payment execute acik';
  end if;

  if not has_function_privilege('service_role', 'public.create_store_order(text,text,text,text,text,text,text,jsonb)', 'EXECUTE') then
    raise exception 'service_role create_store_order execute kayboldu';
  end if;

  if not has_function_privilege('service_role', 'public.record_store_order_payment(text,text,integer,text)', 'EXECUTE') then
    raise exception 'service_role record_store_order_payment execute kayboldu';
  end if;
end;
$$;
