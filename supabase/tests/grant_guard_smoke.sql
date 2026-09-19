do $$
declare
  v_count integer;
  v_detay text;
begin
  select count(*), string_agg(
    format('%s: %s -> %s', grantee.rolname, c.relname, a.privilege_type),
    ', '
  )
  into v_count, v_detay
  from pg_class c
  cross join lateral aclexplode(c.relacl) a
  join pg_roles grantee on grantee.oid = a.grantee
  where c.relnamespace = 'public'::regnamespace
    and c.relkind in ('r', 'p')
    and grantee.rolname in ('anon', 'authenticated')
    and a.privilege_type in ('TRUNCATE', 'MAINTAIN', 'REFERENCES', 'TRIGGER');

  if v_count > 0 then
    raise exception
      'GRANT güvenlik bekçisi: % kayıt bulundu. Detay: %',
      v_count,
      v_detay;
  end if;
end
$$;
