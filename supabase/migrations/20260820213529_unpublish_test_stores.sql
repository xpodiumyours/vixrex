-- #276: Keşfet'te gerçek şablonlarla karışan dokuz test/artık vitrini
-- geri dönüşlü biçimde yayından indirir. Kayıtlar, içerikler ve sahiplik
-- bağlantıları korunur; yalnız yayın görünürlüğü değişir.
--
-- Güvenlik: isim/desen araması yapılmaz. Canlı durum issue'daki kesin
-- listeyle birebir uyuşmuyorsa migration hata verir ve işlem geri alınır.

do $$
declare
  v_target_slugs text[] := array[
    'aymira-giyim',
    'casper-test-vitrini',
    'cccc',
    'debugtest-1786543537-2',
    'demo-teknofix-8a4e0020',
    'demo-teknofix-ba834c19',
    'deneme',
    'dogrulama-3c7176',
    'xxxxx'
  ];
  v_protected_demo_slugs text[] := array[
    'demo-aymira-giyim',
    'demo-lezzet-duragi',
    'demo-nova-kuafor',
    'demo-teknofix',
    'kiralik-butik',
    'kiralik-gida',
    'kiralik-kafe',
    'kiralik-kuafor',
    'kiralik-teknik'
  ];
  v_existing_target_count bigint;
  v_target_count bigint;
  v_target_demo_count bigint;
  v_protected_demo_count bigint;
  v_all_published_demo_count bigint;
  v_cleanup_clone_count bigint;
  v_cleanup_candidate_count bigint;
  v_updated_count bigint;
begin
  -- Ön kontroller ile güncelleme arasına eşzamanlı yazma giremez.
  lock table public.stores in share row exclusive mode;

  select pg_catalog.count(*)
  into v_existing_target_count
  from public.stores
  where slug = any (v_target_slugs);

  -- Test/artık kayıtları temiz bir yerel kurulumun parçası değildir. Bu
  -- yüzden hiçbir hedef yoksa migration güvenli bir no-op olur. Bir tanesi
  -- bile varsa kısmi durum kabul edilmez; canlıdaki dokuzlu birebir aranır.
  if v_existing_target_count = 0 then
    null;
  elsif v_existing_target_count <> pg_catalog.array_length(v_target_slugs, 1) then
    raise exception
      'TEST_STORE_PREFLIGHT_FAILED: expected either 0 or % target rows, found %',
      pg_catalog.array_length(v_target_slugs, 1),
      v_existing_target_count;
  else
  select pg_catalog.count(*)
  into v_protected_demo_count
  from public.stores
  where slug = any (v_protected_demo_slugs)
    and is_demo = true
    and is_published = true;

  if v_protected_demo_count <> pg_catalog.array_length(v_protected_demo_slugs, 1) then
    raise exception
      'DEMO_STORE_PREFLIGHT_FAILED: expected % published protected demos, found %',
      pg_catalog.array_length(v_protected_demo_slugs, 1),
      v_protected_demo_count;
  end if;

  select pg_catalog.count(*)
  into v_all_published_demo_count
  from public.stores
  where is_demo = true
    and is_published = true;

  if v_all_published_demo_count <> pg_catalog.array_length(v_protected_demo_slugs, 1) then
    raise exception
      'DEMO_STORE_PREFLIGHT_FAILED: unexpected published demo count %',
      v_all_published_demo_count;
  end if;

    select pg_catalog.count(*)
    into v_target_count
    from public.stores
    where slug = any (v_target_slugs)
      and is_published = true;

    if v_target_count <> pg_catalog.array_length(v_target_slugs, 1) then
      raise exception
        'TEST_STORE_PREFLIGHT_FAILED: expected % published targets, found %',
        pg_catalog.array_length(v_target_slugs, 1),
        v_target_count;
    end if;

    select pg_catalog.count(*)
    into v_target_demo_count
    from public.stores
    where slug = any (v_target_slugs)
      and is_demo = true;

    if v_target_demo_count <> 0 then
      raise exception
        'TEST_STORE_PREFLIGHT_FAILED: % target rows are protected demos',
        v_target_demo_count;
    end if;

    -- Yalnız bu eski kiralama klonu cloned_from_slug taşıyor. Yayından
    -- indikten sonra 14 günlük cleanup cron'u tarafından kalıcı silinmemesi
    -- için işaretini temizliyoruz; geri dönüş SQL'i değeri geri yükler.
    select pg_catalog.count(*)
    into v_cleanup_clone_count
    from public.stores
    where slug = any (v_target_slugs)
      and cloned_from_slug is not null;

    if v_cleanup_clone_count <> 1 or not exists (
      select 1
      from public.stores
      where slug = 'demo-teknofix-8a4e0020'
        and cloned_from_slug = 'demo-teknofix'
    ) then
      raise exception
        'CLEANUP_PREFLIGHT_FAILED: expected only demo-teknofix-8a4e0020 clone marker';
    end if;

    update public.stores
    set is_published = false,
        cloned_from_slug = case
          when slug = 'demo-teknofix-8a4e0020' then null
          else cloned_from_slug
        end
    where slug = any (v_target_slugs)
      and is_published = true
      and is_demo = false;

    get diagnostics v_updated_count = row_count;

    if v_updated_count <> pg_catalog.array_length(v_target_slugs, 1) then
      raise exception
        'TEST_STORE_UPDATE_FAILED: expected % rows, updated %',
        pg_catalog.array_length(v_target_slugs, 1),
        v_updated_count;
    end if;

    select pg_catalog.count(*)
    into v_cleanup_candidate_count
    from public.stores
    where slug = any (v_target_slugs)
      and cloned_from_slug is not null
      and is_published = false
      and premium_expires_at is null;

    if v_cleanup_candidate_count <> 0 then
      raise exception
        'CLEANUP_POSTCHECK_FAILED: % unpublished targets remain cleanup candidates',
        v_cleanup_candidate_count;
    end if;
  end if;
end;
$$;

-- ROLLBACK (yalnız acil geri dönüş için)
-- Aşağıdaki sorgu yeni bir geri dönüş migration'ında kullanılmalıdır;
-- uygulanmış migration dosyası sonradan değiştirilmez.
--
-- update public.stores
-- set is_published = true,
--     cloned_from_slug = case
--       when slug = 'demo-teknofix-8a4e0020' then 'demo-teknofix'
--       else cloned_from_slug
--     end
-- where slug in (
--   'aymira-giyim', 'casper-test-vitrini', 'cccc',
--   'debugtest-1786543537-2', 'demo-teknofix-8a4e0020',
--   'demo-teknofix-ba834c19', 'deneme', 'dogrulama-3c7176', 'xxxxx'
-- ) and is_published = false and is_demo = false;
