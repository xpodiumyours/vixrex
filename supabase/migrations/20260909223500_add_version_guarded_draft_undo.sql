-- Vixrex Assistant: gerçek son-işlem geri alma.
--
-- Eski `restore_working_draft_field` alanı CANLI stores değerine döndürür.
-- Bu, Assistant öncesinde taslakta bulunan değeri kaybedebilir. Bu migration
-- yazma anındaki taslak değerini sunucuda, aynı transaction içinde saklar.
-- Geri alma yalnız ilgili işlem hâlâ EN SON draft_version ise çalışır;
-- başka cihaz/sekme arada yazdıysa yeni veriyi ezmemek için reddedilir.

create table if not exists public.owner_draft_undo_operations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  previous_values jsonb not null,
  changed_keys text[] not null,
  expected_draft_version bigint not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  consumed_at timestamptz null
);

alter table public.owner_draft_undo_operations enable row level security;
revoke all on table public.owner_draft_undo_operations from public, anon, authenticated;

create index if not exists owner_draft_undo_operations_latest_idx
  on public.owner_draft_undo_operations (store_id, created_at desc)
  where consumed_at is null;

-- Tek alan yazma yolu: manuel panel davranışı değişmez; yalnız önceki değer
-- sunucuda sürüm-korumalı undo kaydı olarak tutulur. UI bu kaydı kullanmak
-- zorunda değildir. Assistant'ın tek-alan serbest mesajı aynı kanonik yolu
-- kullandığı için gerçek undo bundan da yararlanır.
create or replace function public.update_working_draft_field(
  p_session_token text,
  p_key text,
  p_value jsonb
)
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
  v_key text := pg_catalog.btrim(coalesce(p_key, ''));
  v_draft_version bigint;
  v_draft_data jsonb;
  v_previous_values jsonb;
  v_undo_id uuid;
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo
  into v_store_id, v_slug, v_is_demo
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

  if v_key = '' then
    raise exception 'INVALID_FIELD_KEY';
  end if;
  if v_key = any (public.owner_forbidden_draft_keys()) then
    raise exception 'FIELD_NOT_EDITABLE';
  end if;
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'stores'
      and column_name = v_key
      and is_generated = 'NEVER'
      and is_updatable = 'YES'
  ) then
    raise exception 'UNKNOWN_FIELD';
  end if;

  -- Önceki değer ile yazma aynı satır kilidi altında alınır: yarış penceresi yok.
  select draft_data, draft_version
  into v_draft_data, v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  v_previous_values := pg_catalog.jsonb_build_object(
    v_key,
    pg_catalog.jsonb_build_object(
      'present', v_draft_data ? v_key,
      'value', v_draft_data -> v_key
    )
  );

  update public.store_working_drafts
  set draft_data = case
        when p_value is null or pg_catalog.jsonb_typeof(p_value) = 'null'
          then draft_data - v_key
        else draft_data || pg_catalog.jsonb_build_object(v_key, p_value)
      end,
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = v_store_id
  returning draft_version into v_draft_version;

  insert into public.owner_draft_undo_operations (
    store_id,
    previous_values,
    changed_keys,
    expected_draft_version
  ) values (
    v_store_id,
    v_previous_values,
    array[v_key]::text[],
    v_draft_version
  )
  returning id into v_undo_id;

  return pg_catalog.jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'key', v_key,
    'draft_version', v_draft_version,
    'undo_id', v_undo_id
  );
end;
$$;

comment on function public.update_working_draft_field(text, text, jsonb) is
  'Sahip çalışma taslağında tek alan günceller; önceki değeri sürüm-korumalı undo kaydı olarak aynı transaction içinde saklar.';

revoke all on function public.update_working_draft_field(text, text, jsonb) from public;
grant execute on function public.update_working_draft_field(text, text, jsonb) to anon, authenticated;

-- Çok-alan Assistant yazma yolu: tüm doğrulamalar, önceki değer yakalama,
-- değişiklik ve undo kaydı tek transaction içindedir.
create or replace function public.update_working_draft_fields(
  p_session_token text,
  p_changes jsonb
)
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
  v_draft_version bigint;
  v_draft_data jsonb;
  v_new_data jsonb;
  v_key text;
  v_value jsonb;
  v_change_count integer;
  v_changed_keys text[];
  v_previous_values jsonb := '{}'::jsonb;
  v_undo_id uuid;
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if p_changes is null or pg_catalog.jsonb_typeof(p_changes) <> 'object' then
    raise exception 'INVALID_CHANGES';
  end if;

  select count(*), array_agg(k order by k)
  into v_change_count, v_changed_keys
  from pg_catalog.jsonb_object_keys(p_changes) as k;

  if v_change_count < 1 then
    raise exception 'INVALID_CHANGES';
  end if;
  if v_change_count > 20 then
    raise exception 'TOO_MANY_FIELDS';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo
  into v_store_id, v_slug, v_is_demo
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

  foreach v_key in array v_changed_keys
  loop
    v_key := pg_catalog.btrim(coalesce(v_key, ''));
    if v_key = '' then
      raise exception 'INVALID_FIELD_KEY';
    end if;
    if v_key = any (public.owner_forbidden_draft_keys()) then
      raise exception 'FIELD_NOT_EDITABLE';
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'stores'
        and column_name = v_key
        and is_generated = 'NEVER'
        and is_updatable = 'YES'
    ) then
      raise exception 'UNKNOWN_FIELD';
    end if;
  end loop;

  select draft_data, draft_version
  into v_draft_data, v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  foreach v_key in array v_changed_keys
  loop
    v_previous_values := v_previous_values || pg_catalog.jsonb_build_object(
      v_key,
      pg_catalog.jsonb_build_object(
        'present', v_draft_data ? v_key,
        'value', v_draft_data -> v_key
      )
    );
  end loop;

  v_new_data := v_draft_data;
  foreach v_key in array v_changed_keys
  loop
    v_value := p_changes -> v_key;
    if v_value is null or pg_catalog.jsonb_typeof(v_value) = 'null' then
      v_new_data := v_new_data - v_key;
    else
      v_new_data := v_new_data || pg_catalog.jsonb_build_object(v_key, v_value);
    end if;
  end loop;

  update public.store_working_drafts
  set draft_data = v_new_data,
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = v_store_id
  returning draft_version into v_draft_version;

  insert into public.owner_draft_undo_operations (
    store_id,
    previous_values,
    changed_keys,
    expected_draft_version
  ) values (
    v_store_id,
    v_previous_values,
    v_changed_keys,
    v_draft_version
  )
  returning id into v_undo_id;

  return pg_catalog.jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'changed_count', v_change_count,
    'draft_version', v_draft_version,
    'undo_id', v_undo_id
  );
end;
$$;

comment on function public.update_working_draft_fields(text, jsonb) is
  'Vixrex Assistant çoklu taslak değişikliklerini ve önceki değerlerin undo kaydını tek transaction içinde uygular.';

revoke all on function public.update_working_draft_fields(text, jsonb) from public;
grant execute on function public.update_working_draft_fields(text, jsonb) to anon, authenticated;

-- Son yazım hâlâ en güncel sürümse önceki TASLAK değerlerini geri koyar.
-- İstemci eski değer göndermez; yalnız zaten onay kartında bulunan alan
-- anahtarlarını yollar. Sunucu en son undo kaydındaki anahtarlarla birebir
-- karşılaştırır. Arada başka yazım varsa draft_version eşleşmez ve işlem durur.
create or replace function public.undo_latest_working_draft_change(
  p_session_token text,
  p_keys text[]
)
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
  v_requested_keys text[];
  v_undo_id uuid;
  v_previous_values jsonb;
  v_changed_keys text[];
  v_expected_draft_version bigint;
  v_draft_data jsonb;
  v_draft_version bigint;
  v_new_data jsonb;
  v_entry jsonb;
  v_key text;
  v_present boolean;
  v_restored_values jsonb := '{}'::jsonb;
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if p_keys is null or cardinality(p_keys) < 1 or cardinality(p_keys) > 20 then
    raise exception 'INVALID_UNDO_KEYS';
  end if;

  select array_agg(distinct pg_catalog.btrim(k) order by pg_catalog.btrim(k))
  into v_requested_keys
  from unnest(p_keys) as k
  where pg_catalog.btrim(coalesce(k, '')) <> '';

  if v_requested_keys is null
     or cardinality(v_requested_keys) <> cardinality(p_keys) then
    raise exception 'INVALID_UNDO_KEYS';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo
  into v_store_id, v_slug, v_is_demo
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

  select id, previous_values, changed_keys, expected_draft_version
  into v_undo_id, v_previous_values, v_changed_keys, v_expected_draft_version
  from public.owner_draft_undo_operations
  where store_id = v_store_id
    and consumed_at is null
    and expires_at > now()
  order by created_at desc, id desc
  limit 1
  for update;

  if not found then
    raise exception 'UNDO_NOT_AVAILABLE';
  end if;

  if v_changed_keys <> v_requested_keys then
    raise exception 'UNDO_NOT_LATEST';
  end if;

  select draft_data, draft_version
  into v_draft_data, v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  if v_draft_version <> v_expected_draft_version then
    raise exception 'UNDO_STALE';
  end if;

  v_new_data := v_draft_data;
  foreach v_key in array v_changed_keys
  loop
    if v_key = any (public.owner_forbidden_draft_keys()) then
      raise exception 'FIELD_NOT_EDITABLE';
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'stores'
        and column_name = v_key
        and is_generated = 'NEVER'
        and is_updatable = 'YES'
    ) then
      raise exception 'UNKNOWN_FIELD';
    end if;

    v_entry := v_previous_values -> v_key;
    if v_entry is null or pg_catalog.jsonb_typeof(v_entry) <> 'object' then
      raise exception 'INVALID_UNDO_RECORD';
    end if;

    v_present := coalesce((v_entry ->> 'present')::boolean, false);
    if v_present then
      v_new_data := v_new_data || pg_catalog.jsonb_build_object(v_key, v_entry -> 'value');
      v_restored_values := v_restored_values || pg_catalog.jsonb_build_object(v_key, v_entry -> 'value');
    else
      v_new_data := v_new_data - v_key;
      v_restored_values := v_restored_values || pg_catalog.jsonb_build_object(v_key, null);
    end if;
  end loop;

  update public.store_working_drafts
  set draft_data = v_new_data,
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = v_store_id
  returning draft_version into v_draft_version;

  update public.owner_draft_undo_operations
  set consumed_at = now()
  where id = v_undo_id;

  return pg_catalog.jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'changed_keys', v_changed_keys,
    'restored_values', v_restored_values,
    'draft_version', v_draft_version
  );
end;
$$;

comment on function public.undo_latest_working_draft_change(text, text[]) is
  'En son taslak yazımını yalnız draft_version değişmediyse Assistant öncesi taslak değerlerine atomik olarak döndürür.';

revoke all on function public.undo_latest_working_draft_change(text, text[]) from public;
grant execute on function public.undo_latest_working_draft_change(text, text[]) to anon, authenticated;

notify pgrst, 'reload schema';