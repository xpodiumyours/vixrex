-- #237: Flutter ve Next.js için tek yayın hazırlığı omurgası.

create or replace function public.assert_store_publish_ready(p_store jsonb)
returns void
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
declare
  v_category text := pg_catalog.btrim(coalesce(p_store ->> 'kategori', ''));
  v_phone_raw text := pg_catalog.btrim(coalesce(p_store ->> 'whatsapp', ''));
  v_phone_digits text;
  v_phone_canonical text;
begin
  if pg_catalog.btrim(coalesce(p_store ->> 'name', '')) = '' then
    raise exception 'STORE_NAME_REQUIRED';
  end if;

  if v_category = '' or pg_catalog.lower(v_category) in ('diğer', 'diger') then
    raise exception 'STORE_CATEGORY_REQUIRED';
  end if;

  if v_phone_raw = '' then
    raise exception 'STORE_WHATSAPP_REQUIRED';
  end if;
  if v_phone_raw ~ '[[:alpha:]]' then
    raise exception 'STORE_WHATSAPP_INVALID';
  end if;

  v_phone_digits := pg_catalog.regexp_replace(v_phone_raw, '[^0-9]', '', 'g');
  v_phone_canonical := case
    when v_phone_digits ~ '^05[0-9]{9}$' then '90' || pg_catalog.substr(v_phone_digits, 2)
    when v_phone_digits ~ '^5[0-9]{9}$' then '90' || v_phone_digits
    when v_phone_digits ~ '^905[0-9]{9}$' then v_phone_digits
    else null
  end;
  if v_phone_canonical is null then
    raise exception 'STORE_WHATSAPP_INVALID';
  end if;

  if pg_catalog.btrim(coalesce(p_store ->> 'address', '')) = '' then
    raise exception 'STORE_ADDRESS_REQUIRED';
  end if;
  if pg_catalog.btrim(coalesce(p_store ->> 'province_name', '')) = '' then
    raise exception 'STORE_PROVINCE_REQUIRED';
  end if;
  if pg_catalog.btrim(coalesce(p_store ->> 'district_name', '')) = '' then
    raise exception 'STORE_DISTRICT_REQUIRED';
  end if;
end;
$$;

comment on function public.assert_store_publish_ready(jsonb) is
  'İstemciye kapalı ortak yayın hazırlığı kontrolü. İl/ilçe kodlarını şart koşmaz.';

revoke execute on function public.assert_store_publish_ready(jsonb) from public;
revoke execute on function public.assert_store_publish_ready(jsonb) from anon, authenticated;

create or replace function public.enforce_store_publish_readiness()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.is_published is not true then
    return new;
  end if;

  -- Migration mevcut yayınlı satırları taramaz; yayınlı→yayınlı güncellemeler
  -- yeniden yayın RPC'sindeki açık çağrı tarafından denetlenir.
  if tg_op = 'UPDATE' and old.is_published is true then
    return new;
  end if;

  perform public.assert_store_publish_ready(pg_catalog.to_jsonb(new));
  return new;
end;
$$;

revoke execute on function public.enforce_store_publish_readiness() from public;
revoke execute on function public.enforce_store_publish_readiness() from anon, authenticated;

drop trigger if exists stores_publish_readiness_guard on public.stores;
create trigger stores_publish_readiness_guard
before insert or update of is_published on public.stores
for each row execute function public.enforce_store_publish_readiness();

create or replace function public.publish_working_draft(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token_hash text;
  v_store_id uuid;
  v_slug text;
  v_is_demo boolean;
  v_cloned_from_slug text;
  v_premium_expires_at timestamptz;
  v_live_version bigint;
  v_base_live_version bigint;
  v_draft_data jsonb;
  v_guvenli jsonb := '{}'::jsonb;
  v_anahtar text;
  v_kolonlar text;
  v_mevcut jsonb;
begin
  if p_session_token is null or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo, st.cloned_from_slug,
         st.premium_expires_at, st.version
  into v_store_id, v_slug, v_is_demo, v_cloned_from_slug,
       v_premium_expires_at, v_live_version
  from public.owner_sessions s
  join public.stores st on st.id = s.store_id
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  if v_cloned_from_slug is not null
     and (v_premium_expires_at is null or v_premium_expires_at <= now()) then
    raise exception 'PREMIUM_REQUIRED';
  end if;

  select draft_data, base_live_version
  into v_draft_data, v_base_live_version
  from public.store_working_drafts
  where store_id = v_store_id;

  if v_draft_data is null then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;
  if v_live_version is distinct from v_base_live_version then
    raise exception 'DRAFT_STALE';
  end if;

  for v_anahtar in select jsonb_object_keys(v_draft_data)
  loop
    if v_anahtar = any (public.owner_forbidden_draft_keys()) then
      continue;
    end if;
    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'stores'
        and column_name = v_anahtar
        and is_generated = 'NEVER'
        and is_updatable = 'YES'
    ) then
      continue;
    end if;
    v_guvenli := v_guvenli || jsonb_build_object(v_anahtar, v_draft_data -> v_anahtar);
  end loop;

  if v_guvenli <> '{}'::jsonb then
    select string_agg(format('%I', anahtar), ', ' order by anahtar)
    into v_kolonlar
    from jsonb_object_keys(v_guvenli) as t(anahtar);

    select to_jsonb(st) into v_mevcut from public.stores st where st.id = v_store_id;
    execute format(
      'update public.stores set (%s) = (select %s from jsonb_populate_record(null::public.stores, $1)) where id = $2',
      v_kolonlar, v_kolonlar
    ) using (v_mevcut || v_guvenli), v_store_id;
  end if;

  -- Yeniden yayında is_published zaten true olabilir; bu yüzden tetikleyiciye
  -- güvenmeden ortak core açıkça çağrılır. Hata tüm transactionı geri sarar.
  select pg_catalog.to_jsonb(st) into v_mevcut
  from public.stores st where st.id = v_store_id;
  perform public.assert_store_publish_ready(v_mevcut);

  -- Mevcut yasal tetikleyici bu UPDATE sırasında çalışır.
  update public.stores
  set is_published = true
  where id = v_store_id;

  delete from public.store_working_drafts where store_id = v_store_id;

  select version into v_live_version from public.stores where id = v_store_id;
  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'published', true,
    'live_version', v_live_version
  );
end;
$$;

comment on function public.publish_working_draft(text) is
  'Sahip taslağını ortak hazırlık, premium ve yasal kapılardan geçirerek yayınlar. Hata transactionı geri sarar.';

grant execute on function public.publish_working_draft(text) to anon, authenticated;
