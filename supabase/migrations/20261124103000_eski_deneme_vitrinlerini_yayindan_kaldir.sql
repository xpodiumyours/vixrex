do $$
declare
  v_korunan_demo bigint;
  v_hedefler text[];
  v_guncellenen bigint;
  v_kalan bigint;
  v_korunan_demo_sonra bigint;
begin
  lock table public.stores in share row exclusive mode;

  select pg_catalog.count(*)
  into v_korunan_demo
  from public.stores
  where is_demo = true
    and is_published = true;

  select coalesce(
    pg_catalog.array_agg(hedef.slug order by hedef.slug),
    array[]::text[]
  )
  into v_hedefler
  from (
    select s.slug
    from public.stores s
    where s.is_published = true
      and s.is_demo = false
      and pg_catalog.btrim(coalesce(s.slug, '')) <> ''
      and (
        lower(s.slug) = any (
          array[
            'aasd-mwj3ln80',
            'sssss-mwpepeiq',
            'dename-mwjm5i7b',
            'drbrme-mwjho6k1',
            'deneri-m-mvlf57cg'
          ]
        )
        or exists (
          select 1
          from pg_catalog.unnest(
            array[
              lower(s.slug),
              lower(regexp_replace(s.slug, '-(mw[a-z0-9]+|[a-z0-9]{6,10})$', '')),
              lower(pg_catalog.btrim(coalesce(s.name, '')))
            ]
          ) as aday(deger)
          where aday.deger like any (
            array['%test%', '%deneme%', '%debug%', '%demo%', '%dename%']
          )
        )
        or exists (
          select 1
          from pg_catalog.unnest(
            array[
              lower(s.slug),
              lower(regexp_replace(s.slug, '-(mw[a-z0-9]+|[a-z0-9]{6,10})$', '')),
              lower(pg_catalog.btrim(coalesce(s.name, '')))
            ]
          ) as aday(deger)
          where aday.deger ~ '^(.)\1{2,}$'
             or aday.deger ~ '^(asdf|asdfg|qwerty|qwert|zxcv|1234|12345|aasd|sssss)(-|$)'
        )
      )
  ) as hedef;

  update public.stores s
  set is_published = false
  where s.slug = any (v_hedefler)
    and s.is_published = true
    and s.is_demo = false;

  get diagnostics v_guncellenen = row_count;

  if v_guncellenen <> coalesce(pg_catalog.array_length(v_hedefler, 1), 0) then
    raise exception
      'ESKI_DENEME_UNPUBLISH_FAILED: expected % rows, updated %',
      coalesce(pg_catalog.array_length(v_hedefler, 1), 0),
      v_guncellenen;
  end if;

  select pg_catalog.count(*)
  into v_kalan
  from public.stores
  where slug = any (v_hedefler)
    and is_published = true;

  select pg_catalog.count(*)
  into v_korunan_demo_sonra
  from public.stores
  where is_demo = true
    and is_published = true;

  if v_kalan <> 0 then
    raise exception
      'ESKI_DENEME_UNPUBLISH_POSTCHECK_FAILED: % target rows are still published',
      v_kalan;
  end if;

  if v_korunan_demo_sonra <> v_korunan_demo then
    raise exception
      'ESKI_DENEME_UNPUBLISH_POSTCHECK_FAILED: demo rental storefronts changed (% -> %)',
      v_korunan_demo,
      v_korunan_demo_sonra;
  end if;
end;
$$;
