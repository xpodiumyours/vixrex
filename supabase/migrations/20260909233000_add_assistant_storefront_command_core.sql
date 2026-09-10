-- Vixrex Assistant: storefront için tek command/action güvenlik çekirdeği.
--
-- Hedef: bir kullanıcı mesajı = bir command_id. Aynı command yeniden gelirse
-- aynı sonuç replay edilir; aynı command_id farklı içerikle kullanılırsa işlem
-- reddedilir. Yazma + önceki değer + undo kaydı + audit receipt TEK transaction.
--
-- Yetki sarmalayıcıları:
--   apply_working_draft_command       -> Next.js custom owner session token
--   apply_owned_working_draft_command -> Flutter kalıcı auth.uid()
-- İkisi de istemciye kapalı iç `vixrex_apply_storefront_command_core` fonksiyonunu
-- çağırır; veri/yazma kuralı iki kez kopyalanmaz.

alter table public.owner_draft_undo_operations
  add column if not exists command_id uuid null;

create unique index if not exists owner_draft_undo_operations_command_unique
  on public.owner_draft_undo_operations (store_id, command_id)
  where command_id is not null;

create unique index if not exists audit_logs_vixrex_assistant_storefront_command_unique
  on public.audit_logs (target_id, ((metadata ->> 'command_id')))
  where action = 'vixrex_assistant_storefront_command'
    and metadata ? 'command_id';

create unique index if not exists audit_logs_vixrex_assistant_storefront_undo_unique
  on public.audit_logs (target_id, ((metadata ->> 'command_id')))
  where action = 'vixrex_assistant_storefront_command_undo'
    and metadata ? 'command_id';

create or replace function public.vixrex_apply_storefront_command_core(
  p_store_id uuid,
  p_actor_user_id uuid,
  p_session_id text,
  p_command_id uuid,
  p_changes jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
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
  v_receipt public.audit_logs%rowtype;
begin
  if p_store_id is null or p_command_id is null then
    raise exception 'INVALID_COMMAND_PRECONDITION';
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

  select st.slug, st.is_demo
  into v_slug, v_is_demo
  from public.stores st
  where st.id = p_store_id;

  if v_slug is null then
    raise exception 'OWNED_STORE_NOT_FOUND';
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
    -- Assistant pozitif allowlisti: yeni bir stores kolonu eklenmesi Assistant'a
    -- otomatik yetki VERMEZ.
    if not (v_key = any (public.vixrex_assistant_editable_draft_columns())) then
      raise exception 'FIELD_NOT_EDITABLE';
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

  -- Bütün Assistant command'leri aynı draft satırında serialize olur. Receipt
  -- kontrolü kilitten SONRA yapılır; eşzamanlı aynı command iki kez uygulanmaz.
  select draft_data, draft_version
  into v_draft_data, v_draft_version
  from public.store_working_drafts
  where store_id = p_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  select * into v_receipt
  from public.audit_logs
  where action = 'vixrex_assistant_storefront_command'
    and target_id = p_store_id::text
    and metadata ->> 'command_id' = p_command_id::text
  limit 1;

  if found then
    if coalesce(v_receipt.new_value, '{}'::jsonb)
       is distinct from coalesce(p_changes, '{}'::jsonb) then
      raise exception 'IDEMPOTENCY_KEY_REUSE';
    end if;

    return pg_catalog.jsonb_build_object(
      'store_id', p_store_id,
      'slug', v_slug,
      'changed_count', coalesce((v_receipt.metadata ->> 'changed_count')::integer, v_change_count),
      'draft_version', (v_receipt.metadata ->> 'result_draft_version')::bigint,
      'undo_id', (v_receipt.metadata ->> 'undo_id')::uuid,
      'command_id', p_command_id,
      'replayed', true
    );
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
  where store_id = p_store_id
  returning draft_version into v_draft_version;

  insert into public.owner_draft_undo_operations (
    store_id,
    command_id,
    previous_values,
    changed_keys,
    expected_draft_version
  ) values (
    p_store_id,
    p_command_id,
    v_previous_values,
    v_changed_keys,
    v_draft_version
  )
  returning id into v_undo_id;

  insert into public.audit_logs (
    user_id,
    session_id,
    action,
    target_type,
    target_id,
    old_value,
    new_value,
    metadata
  ) values (
    p_actor_user_id,
    p_session_id,
    'vixrex_assistant_storefront_command',
    'store_working_draft',
    p_store_id::text,
    v_previous_values,
    p_changes,
    pg_catalog.jsonb_build_object(
      'command_id', p_command_id::text,
      'undo_id', v_undo_id::text,
      'domain', 'storefront',
      'source', 'vixrex_assistant',
      'changed_keys', to_jsonb(v_changed_keys),
      'changed_count', v_change_count,
      'result_draft_version', v_draft_version
    )
  );

  return pg_catalog.jsonb_build_object(
    'store_id', p_store_id,
    'slug', v_slug,
    'changed_count', v_change_count,
    'draft_version', v_draft_version,
    'undo_id', v_undo_id,
    'command_id', p_command_id,
    'replayed', false
  );
end;
$$;

revoke all on function public.vixrex_apply_storefront_command_core(
  uuid, uuid, text, uuid, jsonb
) from public, anon, authenticated, service_role;

create or replace function public.apply_working_draft_command(
  p_session_token text,
  p_command_id uuid,
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
  v_session_id uuid;
  v_store_user_id uuid;
  v_is_demo boolean;
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  if p_command_id is null then
    raise exception 'INVALID_COMMAND_PRECONDITION';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select os.store_id, os.id, st.user_id, st.is_demo
  into v_store_id, v_session_id, v_store_user_id, v_is_demo
  from public.owner_sessions os
  join public.stores st on st.id = os.store_id
  where os.session_token_hash = v_token_hash
    and os.consumed_at is not null
    and os.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  return public.vixrex_apply_storefront_command_core(
    v_store_id,
    v_store_user_id,
    v_session_id::text,
    p_command_id,
    p_changes
  );
end;
$$;

revoke all on function public.apply_working_draft_command(text, uuid, jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.apply_working_draft_command(text, uuid, jsonb)
  to anon, authenticated;

create or replace function public.apply_owned_working_draft_command(
  p_command_id uuid,
  p_changes jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_is_demo boolean;
begin
  if v_user_id is null or not public.is_permanent_user() then
    raise exception 'PERMANENT_ACCOUNT_REQUIRED';
  end if;
  if p_command_id is null then
    raise exception 'INVALID_COMMAND_PRECONDITION';
  end if;

  select st.id, st.is_demo
  into v_store_id, v_is_demo
  from public.stores st
  where st.user_id = v_user_id
  order by st.created_at asc
  limit 1;

  if v_store_id is null then
    raise exception 'OWNED_STORE_NOT_FOUND';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  -- Flutter'da ilk Assistant yazımı: mevcut owned batch ile aynı davranış,
  -- kanonik taslak yoksa canlı mağaza verisinden güvenli taslak oluştur.
  insert into public.store_working_drafts (
    store_id,
    draft_data,
    draft_version,
    base_live_version,
    updated_at
  )
  select
    st.id,
    public.strip_draft_secrets(to_jsonb(st)),
    1,
    st.version,
    now()
  from public.stores st
  where st.id = v_store_id
    and not exists (
      select 1 from public.store_working_drafts wd where wd.store_id = st.id
    )
  on conflict (store_id) do nothing;

  return public.vixrex_apply_storefront_command_core(
    v_store_id,
    v_user_id,
    null,
    p_command_id,
    p_changes
  );
end;
$$;

revoke all on function public.apply_owned_working_draft_command(uuid, jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.apply_owned_working_draft_command(uuid, jsonb)
  to authenticated;

create or replace function public.vixrex_undo_storefront_command_core(
  p_store_id uuid,
  p_actor_user_id uuid,
  p_session_id text,
  p_command_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_slug text;
  v_is_demo boolean;
  v_undo public.owner_draft_undo_operations%rowtype;
  v_receipt public.audit_logs%rowtype;
  v_draft_data jsonb;
  v_draft_version bigint;
  v_new_data jsonb;
  v_key text;
  v_entry jsonb;
  v_present boolean;
  v_restored_values jsonb := '{}'::jsonb;
begin
  if p_store_id is null or p_command_id is null then
    raise exception 'INVALID_UNDO_PRECONDITION';
  end if;

  select st.slug, st.is_demo
  into v_slug, v_is_demo
  from public.stores st
  where st.id = p_store_id;

  if v_slug is null then
    raise exception 'OWNED_STORE_NOT_FOUND';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  -- Tekrar tıklanan aynı undo ikinci kez veri değiştirmez; önceki receipt replay.
  select * into v_receipt
  from public.audit_logs
  where action = 'vixrex_assistant_storefront_command_undo'
    and target_id = p_store_id::text
    and metadata ->> 'command_id' = p_command_id::text
  limit 1;

  if found then
    return pg_catalog.jsonb_build_object(
      'store_id', p_store_id,
      'slug', v_slug,
      'command_id', p_command_id,
      'restored_values', coalesce(v_receipt.new_value, '{}'::jsonb),
      'draft_version', (v_receipt.metadata ->> 'result_draft_version')::bigint,
      'replayed', true
    );
  end if;

  select * into v_undo
  from public.owner_draft_undo_operations
  where store_id = p_store_id
    and command_id = p_command_id
  limit 1
  for update;

  if not found then
    raise exception 'UNDO_COMMAND_NOT_FOUND';
  end if;
  if v_undo.consumed_at is not null then
    raise exception 'UNDO_ALREADY_CONSUMED';
  end if;
  if v_undo.expires_at <= now() then
    raise exception 'UNDO_NOT_AVAILABLE';
  end if;

  select draft_data, draft_version
  into v_draft_data, v_draft_version
  from public.store_working_drafts
  where store_id = p_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  -- Komuttan sonra başka HERHANGİ bir draft yazımı olduysa eski komut yeni
  -- veriyi ezemez. Özellikle aynı alanı değiştiren iki Assistant kartı ayrılır.
  if v_draft_version <> v_undo.expected_draft_version then
    raise exception 'UNDO_STALE';
  end if;

  v_new_data := v_draft_data;
  foreach v_key in array v_undo.changed_keys
  loop
    if not (v_key = any (public.vixrex_assistant_editable_draft_columns())) then
      raise exception 'FIELD_NOT_EDITABLE';
    end if;
    v_entry := v_undo.previous_values -> v_key;
    if v_entry is null or pg_catalog.jsonb_typeof(v_entry) <> 'object' then
      raise exception 'INVALID_UNDO_RECORD';
    end if;

    v_present := coalesce((v_entry ->> 'present')::boolean, false);
    if v_present then
      v_new_data := v_new_data || pg_catalog.jsonb_build_object(
        v_key,
        v_entry -> 'value'
      );
      v_restored_values := v_restored_values || pg_catalog.jsonb_build_object(
        v_key,
        v_entry -> 'value'
      );
    else
      v_new_data := v_new_data - v_key;
      v_restored_values := v_restored_values || pg_catalog.jsonb_build_object(
        v_key,
        null
      );
    end if;
  end loop;

  update public.store_working_drafts
  set draft_data = v_new_data,
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = p_store_id
  returning draft_version into v_draft_version;

  update public.owner_draft_undo_operations
  set consumed_at = now()
  where id = v_undo.id;

  insert into public.audit_logs (
    user_id,
    session_id,
    action,
    target_type,
    target_id,
    old_value,
    new_value,
    metadata
  ) values (
    p_actor_user_id,
    p_session_id,
    'vixrex_assistant_storefront_command_undo',
    'store_working_draft',
    p_store_id::text,
    v_draft_data,
    v_restored_values,
    pg_catalog.jsonb_build_object(
      'command_id', p_command_id::text,
      'undo_id', v_undo.id::text,
      'domain', 'storefront',
      'source', 'vixrex_assistant',
      'result_draft_version', v_draft_version
    )
  );

  return pg_catalog.jsonb_build_object(
    'store_id', p_store_id,
    'slug', v_slug,
    'command_id', p_command_id,
    'changed_keys', v_undo.changed_keys,
    'restored_values', v_restored_values,
    'draft_version', v_draft_version,
    'replayed', false
  );
end;
$$;

revoke all on function public.vixrex_undo_storefront_command_core(
  uuid, uuid, text, uuid
) from public, anon, authenticated, service_role;

create or replace function public.undo_working_draft_command(
  p_session_token text,
  p_command_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token_hash text;
  v_store_id uuid;
  v_session_id uuid;
  v_store_user_id uuid;
  v_is_demo boolean;
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select os.store_id, os.id, st.user_id, st.is_demo
  into v_store_id, v_session_id, v_store_user_id, v_is_demo
  from public.owner_sessions os
  join public.stores st on st.id = os.store_id
  where os.session_token_hash = v_token_hash
    and os.consumed_at is not null
    and os.expires_at > now();

  if v_store_id is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  return public.vixrex_undo_storefront_command_core(
    v_store_id,
    v_store_user_id,
    v_session_id::text,
    p_command_id
  );
end;
$$;

revoke all on function public.undo_working_draft_command(text, uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.undo_working_draft_command(text, uuid)
  to anon, authenticated;

create or replace function public.undo_owned_working_draft_command(
  p_command_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_is_demo boolean;
begin
  if v_user_id is null or not public.is_permanent_user() then
    raise exception 'PERMANENT_ACCOUNT_REQUIRED';
  end if;

  select st.id, st.is_demo
  into v_store_id, v_is_demo
  from public.stores st
  where st.user_id = v_user_id
  order by st.created_at asc
  limit 1;

  if v_store_id is null then
    raise exception 'OWNED_STORE_NOT_FOUND';
  end if;
  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE';
  end if;

  return public.vixrex_undo_storefront_command_core(
    v_store_id,
    v_user_id,
    null,
    p_command_id
  );
end;
$$;

revoke all on function public.undo_owned_working_draft_command(uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.undo_owned_working_draft_command(uuid)
  to authenticated;

notify pgrst, 'reload schema';
