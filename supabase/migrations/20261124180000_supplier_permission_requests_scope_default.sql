do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'supplier_permission_requests'
      and column_name = 'scope'
  ) then
    execute 'alter table public.supplier_permission_requests alter column scope set default ''data_and_images''';
  end if;
end $$;

notify pgrst, 'reload schema';
