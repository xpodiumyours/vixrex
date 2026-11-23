-- #814: Canlı sitemap'te görünen beş deneme vitrini ile aynı işletmenin çift
-- kaydından fazlalık olanı geri dönüşlü biçimde yayından indirir. Kayıtlar,
-- içerikleri ve sahiplik bağlantıları silinmez; yalnız is_published değişir.

do $$
declare
  v_test_slugs text[] := array[
    'aasd-mwj3ln80',
    'sssss-mwpepeiq',
    'dename-mwjm5i7b',
    'drbrme-mwjho6k1',
    'deneri-m-mvlf57cg'
  ];
  v_meram_keep text := 'meram-kebap-mvmugivx';
  v_meram_drop text := 'meram-kebap-mvmuiox1';
  v_test_found bigint;
  v_test_published bigint;
  v_keep_published bigint;
  v_drop_published bigint;
  v_drop_newer boolean;
  v_updated bigint;
begin
  lock table public.stores in share row exclusive mode;

  select pg_catalog.count(*)
  into v_test_found
  from public.stores
  where slug = any (v_test_slugs);

  -- Test vitrinleri yerel kurulumun parçası değildir; hiçbiri yoksa no-op.
  -- Bir kısmı varsa kısmi durum kabul edilmez.
  if v_test_found not in (0, pg_catalog.array_length(v_test_slugs, 1)) then
    raise exception
      'DENEME_VITRIN_PREFLIGHT_FAILED: expected either 0 or % rows, found %',
      pg_catalog.array_length(v_test_slugs, 1),
      v_test_found;
  end if;

  select pg_catalog.count(*)
  into v_test_published
  from public.stores
  where slug = any (v_test_slugs)
    and is_published = true
    and is_demo = false;

  if v_test_published <> v_test_found then
    raise exception
      'DENEME_VITRIN_PREFLIGHT_FAILED: % of % target rows are not published non-demo stores',
      v_test_found - v_test_published,
      v_test_found;
  end if;

  select pg_catalog.count(*)
  into v_keep_published
  from public.stores
  where slug = v_meram_keep
    and is_published = true
    and is_demo = false;

  select pg_catalog.count(*)
  into v_drop_published
  from public.stores
  where slug = v_meram_drop
    and is_published = true
    and is_demo = false;

  -- Fazlalık kayıt, korunacak kayıttan sonra oluşmuş olmalı. Aksi hâlde
  -- yanlış kayıt yayından indirilir; işlem durur.
  if v_drop_published = 1 then
    select d.created_at > k.created_at
    into v_drop_newer
    from public.stores d
    cross join public.stores k
    where d.slug = v_meram_drop
      and k.slug = v_meram_keep;

    if v_keep_published <> 1 or v_drop_newer is not true then
      raise exception
        'MERAM_KEBAP_PREFLIGHT_FAILED: keep row must be the older published record';
    end if;
  end if;

  update public.stores
  set is_published = false
  where (slug = any (v_test_slugs) or slug = v_meram_drop)
    and is_published = true
    and is_demo = false;

  get diagnostics v_updated = row_count;

  if v_updated <> v_test_published + v_drop_published then
    raise exception
      'UNPUBLISH_UPDATE_FAILED: expected % rows, updated %',
      v_test_published + v_drop_published,
      v_updated;
  end if;

  select pg_catalog.count(*)
  into v_test_published
  from public.stores
  where slug = any (v_test_slugs)
    and is_published = true;

  select pg_catalog.count(*)
  into v_drop_published
  from public.stores
  where slug = v_meram_drop
    and is_published = true;

  if v_test_published <> 0 or v_drop_published <> 0 then
    raise exception
      'UNPUBLISH_POSTCHECK_FAILED: % target rows are still published',
      v_test_published + v_drop_published;
  end if;
end;
$$;

-- GERİ DÖNÜŞ (yeni bir migration olarak uygulanır):
-- update public.stores
-- set is_published = true
-- where slug in (
--   'aasd-mwj3ln80', 'sssss-mwpepeiq', 'dename-mwjm5i7b',
--   'drbrme-mwjho6k1', 'deneri-m-mvlf57cg', 'meram-kebap-mvmuiox1'
-- ) and is_published = false and is_demo = false;
