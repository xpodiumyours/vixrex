-- Vixrex Akıllı Motor — authoritative storefront mutation + safe command Undo.
--
-- Bağımlılık: 20260905114039_vixrex_canonical_46_field_contract.sql
-- Production rollout kuralı: kill-switch migration'ındaki iki flag OFF başlar.

-- actionId global receipt anahtarıdır. Row-lock aynı store'da replay'i zaten
-- sıraya koyar; bu index store'lar arası deliberate/tesadüfi reuse'u da kapatır.
create unique index if not exists ux_audit_logs_smart_engine_action_id
on public.audit_logs ((metadata ->> 'action_id'))
where action = 'smart_engine_set_field' and metadata ? 'action_id';

-- Aynı store + command ikinci kez Undo edilirse tek command receipt vardır.
create unique index if not exists ux_audit_logs_smart_engine_undo_command
on public.audit_logs (target_id, ((metadata ->> 'command_id')))
where action = 'smart_engine_undo_command' and metadata ? 'command_id';

create or replace function public.vixrex_apply_storefront_action(
  p_session_token text,
  p_field_key text,
  p_value jsonb,
  p_expected_draft_version bigint,
  p_action_id uuid,
  p_command_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_store_user_id uuid;
  v_session_id uuid;
  v_is_demo boolean;
  v_contract jsonb;
  v_column text;
  v_draft_data jsonb;
  v_current_version bigint;
  v_old_value jsonb;
  v_new_version bigint;
  v_receipt public.audit_logs%rowtype;
  v_token_hash text;
  v_action_text text := p_action_id::text;
  v_command_text text := p_command_id::text;
begin
  if p_action_id is null or p_command_id is null or p_expected_draft_version is null then
    raise exception 'INVALID_ACTION_PRECONDITION' using errcode='P0001';
  end if;

  if not coalesce((select is_enabled from public.feature_flags where flag_key='vixrex_smart_engine_enabled'), false)
     or not coalesce((select is_enabled from public.feature_flags where flag_key='vixrex_smart_engine_storefront_enabled'), false) then
    raise exception 'SMART_ENGINE_DISABLED' using errcode='P0001';
  end if;

  -- Web owner path: HttpOnly cookie Next server'da doğrulanır, yalnız session
  -- token buraya gelir. Flutter permanent account path token göndermez.
  if nullif(pg_catalog.btrim(coalesce(p_session_token, '')), '') is not null then
    if length(pg_catalog.btrim(p_session_token)) <> 64 then
      raise exception 'INVALID_SESSION_TOKEN' using errcode='P0001';
    end if;

    v_token_hash := encode(
      extensions.digest(pg_catalog.btrim(p_session_token)::bytea, 'sha256'),
      'hex'
    );

    select os.store_id, os.id, s.user_id, s.is_demo
      into v_store_id, v_session_id, v_store_user_id, v_is_demo
    from public.owner_sessions os
    join public.stores s on s.id = os.store_id
    where os.session_token_hash = v_token_hash
      and os.consumed_at is not null
      and os.expires_at > now();

    if v_store_id is null then
      raise exception 'INVALID_SESSION_TOKEN' using errcode='P0001';
    end if;
  else
    if v_user_id is null or not public.is_permanent_user() then
      raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode='P0001';
    end if;

    select id, user_id, is_demo
      into v_store_id, v_store_user_id, v_is_demo
    from public.stores
    where user_id = v_user_id
    order by created_at asc
    limit 1;

    if v_store_id is null then
      raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode='P0001';
    end if;
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode='P0001';
  end if;

  v_contract := public.vixrex_storefront_field_contract(p_field_key);
  if v_contract is null then
    raise exception 'FIELD_NOT_EDITABLE' using errcode='P0001';
  end if;
  if not public.vixrex_validate_storefront_value(v_contract, p_value) then
    raise exception 'INVALID_FIELD_VALUE' using errcode='P0001';
  end if;
  v_column := v_contract ->> 'column';

  -- Tek authoritative serialize noktası: draft row.
  select draft_data, draft_version
    into v_draft_data, v_current_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND' using errcode='P0001';
  end if;

  -- Retry önce receipt'i görür. Aynı actionId farklı payload ise fail-closed.
  select * into v_receipt
  from public.audit_logs
  where action = 'smart_engine_set_field'
    and metadata ->> 'action_id' = v_action_text
  limit 1;

  if found then
    if v_receipt.target_id <> v_store_id::text
       or v_receipt.metadata ->> 'field_key' <> pg_catalog.btrim(p_field_key)
       or v_receipt.metadata ->> 'command_id' <> v_command_text
       or coalesce(v_receipt.new_value, 'null'::jsonb)
          is distinct from coalesce(p_value, 'null'::jsonb) then
      raise exception 'IDEMPOTENCY_KEY_REUSE' using errcode='P0001';
    end if;

    return jsonb_build_object(
      'ok', true,
      'replayed', true,
      'store_id', v_store_id,
      'field_key', p_field_key,
      'column', v_column,
      'draft_version', (v_receipt.metadata ->> 'result_draft_version')::bigint,
      'action_id', p_action_id,
      'command_id', p_command_id,
      'old_value', coalesce(v_receipt.old_value, 'null'::jsonb),
      'new_value', coalesce(v_receipt.new_value, 'null'::jsonb)
    );
  end if;

  if v_current_version <> p_expected_draft_version then
    raise exception 'DRAFT_VERSION_CONFLICT' using errcode='P0001';
  end if;

  v_old_value := v_draft_data -> v_column;

  update public.store_working_drafts
  set draft_data = case
        when p_value is null or jsonb_typeof(p_value) = 'null'
          then draft_data - v_column
        else draft_data || jsonb_build_object(v_column, p_value)
      end,
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = v_store_id
  returning draft_version into v_new_version;

  insert into public.audit_logs(
    user_id,
    session_id,
    action,
    target_type,
    target_id,
    old_value,
    new_value,
    metadata
  ) values (
    coalesce(v_user_id, v_store_user_id),
    v_session_id::text,
    'smart_engine_set_field',
    'store_working_draft',
    v_store_id::text,
    coalesce(v_old_value, 'null'::jsonb),
    coalesce(p_value, 'null'::jsonb),
    jsonb_build_object(
      'action_id', v_action_text,
      'command_id', v_command_text,
      'domain', 'storefront',
      'field_key', pg_catalog.btrim(p_field_key),
      'source', 'smart_engine',
      'result_draft_version', v_new_version
    )
  );

  return jsonb_build_object(
    'ok', true,
    'replayed', false,
    'store_id', v_store_id,
    'field_key', p_field_key,
    'column', v_column,
    'draft_version', v_new_version,
    'action_id', p_action_id,
    'command_id', p_command_id,
    'old_value', coalesce(v_old_value, 'null'::jsonb),
    'new_value', coalesce(p_value, 'null'::jsonb)
  );
end;
$$;

create or replace function public.vixrex_undo_storefront_command(
  p_session_token text,
  p_command_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_store_user_id uuid;
  v_session_id uuid;
  v_is_demo boolean;
  v_token_hash text;
  v_draft_data jsonb;
  v_simulated jsonb;
  v_current_version bigint;
  v_final_version bigint;
  v_receipt public.audit_logs%rowtype;
  v_undo_receipt public.audit_logs%rowtype;
  v_contract jsonb;
  v_column text;
  v_current_value jsonb;
  v_count int := 0;
  v_index int := 0;
  v_command_text text := p_command_id::text;
begin
  if p_command_id is null then
    raise exception 'INVALID_UNDO_PRECONDITION' using errcode='P0001';
  end if;

  if not coalesce((select is_enabled from public.feature_flags where flag_key='vixrex_smart_engine_enabled'), false)
     or not coalesce((select is_enabled from public.feature_flags where flag_key='vixrex_smart_engine_storefront_enabled'), false) then
    raise exception 'SMART_ENGINE_DISABLED' using errcode='P0001';
  end if;

  if nullif(pg_catalog.btrim(coalesce(p_session_token, '')), '') is not null then
    if length(pg_catalog.btrim(p_session_token)) <> 64 then
      raise exception 'INVALID_SESSION_TOKEN' using errcode='P0001';
    end if;

    v_token_hash := encode(
      extensions.digest(pg_catalog.btrim(p_session_token)::bytea, 'sha256'),
      'hex'
    );

    select os.store_id, os.id, s.user_id, s.is_demo
      into v_store_id, v_session_id, v_store_user_id, v_is_demo
    from public.owner_sessions os
    join public.stores s on s.id = os.store_id
    where os.session_token_hash = v_token_hash
      and os.consumed_at is not null
      and os.expires_at > now();

    if v_store_id is null then
      raise exception 'INVALID_SESSION_TOKEN' using errcode='P0001';
    end if;
  else
    if v_user_id is null or not public.is_permanent_user() then
      raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode='P0001';
    end if;

    select id, user_id, is_demo
      into v_store_id, v_store_user_id, v_is_demo
    from public.stores
    where user_id = v_user_id
    order by created_at asc
    limit 1;

    if v_store_id is null then
      raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode='P0001';
    end if;
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode='P0001';
  end if;

  select draft_data, draft_version
    into v_draft_data, v_current_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND' using errcode='P0001';
  end if;

  -- Command-level idempotency receipt.
  select * into v_undo_receipt
  from public.audit_logs
  where action = 'smart_engine_undo_command'
    and target_id = v_store_id::text
    and metadata ->> 'command_id' = v_command_text
  limit 1;

  if found then
    return jsonb_build_object(
      'ok', true,
      'replayed', true,
      'store_id', v_store_id,
      'command_id', p_command_id,
      'rolled_back_action_count', (v_undo_receipt.metadata ->> 'rolled_back_action_count')::int,
      'draft_version', (v_undo_receipt.metadata ->> 'result_draft_version')::bigint
    );
  end if;

  -- Önce RAM/jsonb üzerinde tam rollback simülasyonu: herhangi bir current !=
  -- receipt.new_value ise transaction hiç yazmadan UNDO_CONFLICT verir.
  v_simulated := v_draft_data;

  for v_receipt in
    select *
    from public.audit_logs
    where action = 'smart_engine_set_field'
      and target_id = v_store_id::text
      and metadata ->> 'command_id' = v_command_text
    order by (metadata ->> 'result_draft_version')::bigint desc, created_at desc
  loop
    v_contract := public.vixrex_storefront_field_contract(v_receipt.metadata ->> 'field_key');
    if v_contract is null then
      raise exception 'UNDO_CONFLICT' using errcode='P0001';
    end if;

    v_column := v_contract ->> 'column';
    v_current_value := v_simulated -> v_column;

    if coalesce(v_current_value, 'null'::jsonb)
       is distinct from coalesce(v_receipt.new_value, 'null'::jsonb) then
      raise exception 'UNDO_CONFLICT' using errcode='P0001';
    end if;

    v_simulated := case
      when v_receipt.old_value is null or jsonb_typeof(v_receipt.old_value) = 'null'
        then v_simulated - v_column
      else v_simulated || jsonb_build_object(v_column, v_receipt.old_value)
    end;

    v_count := v_count + 1;
  end loop;

  if v_count = 0 then
    raise exception 'UNDO_COMMAND_NOT_FOUND' using errcode='P0001';
  end if;

  v_final_version := v_current_version + v_count;

  update public.store_working_drafts
  set draft_data = v_simulated,
      draft_version = v_final_version,
      updated_at = now()
  where store_id = v_store_id;

  -- Receipt'ler ters action sırasıyla yazılır; final state yukarıdaki tek
  -- atomic update ile commit edilir.
  for v_receipt in
    select *
    from public.audit_logs
    where action = 'smart_engine_set_field'
      and target_id = v_store_id::text
      and metadata ->> 'command_id' = v_command_text
    order by (metadata ->> 'result_draft_version')::bigint desc, created_at desc
  loop
    v_index := v_index + 1;

    insert into public.audit_logs(
      user_id,
      session_id,
      action,
      target_type,
      target_id,
      old_value,
      new_value,
      metadata
    ) values (
      coalesce(v_user_id, v_store_user_id),
      v_session_id::text,
      'smart_engine_rollback_field',
      'store_working_draft',
      v_store_id::text,
      coalesce(v_receipt.new_value, 'null'::jsonb),
      coalesce(v_receipt.old_value, 'null'::jsonb),
      jsonb_build_object(
        'rollback_of_action_id', v_receipt.metadata ->> 'action_id',
        'command_id', v_command_text,
        'field_key', v_receipt.metadata ->> 'field_key',
        'source', 'smart_engine',
        'result_draft_version', v_current_version + v_index
      )
    );
  end loop;

  insert into public.audit_logs(
    user_id,
    session_id,
    action,
    target_type,
    target_id,
    metadata
  ) values (
    coalesce(v_user_id, v_store_user_id),
    v_session_id::text,
    'smart_engine_undo_command',
    'store_working_draft',
    v_store_id::text,
    jsonb_build_object(
      'command_id', v_command_text,
      'source', 'smart_engine',
      'rolled_back_action_count', v_count,
      'result_draft_version', v_final_version
    )
  );

  return jsonb_build_object(
    'ok', true,
    'replayed', false,
    'store_id', v_store_id,
    'command_id', p_command_id,
    'rolled_back_action_count', v_count,
    'draft_version', v_final_version
  );
end;
$$;

-- Helpers internal: metadata/validation client surface değildir.
revoke all on function public.vixrex_storefront_field_contract(text)
  from public, anon, authenticated, service_role;
revoke all on function public.vixrex_validate_storefront_value(jsonb, jsonb)
  from public, anon, authenticated, service_role;

-- Web server service_role, Flutter permanent account authenticated kullanır.
-- anon hiçbir authoritative mutation/Undo çağrısı yapamaz.
revoke all on function public.vixrex_apply_storefront_action(text, text, jsonb, bigint, uuid, uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.vixrex_apply_storefront_action(text, text, jsonb, bigint, uuid, uuid)
  to authenticated, service_role;

revoke all on function public.vixrex_undo_storefront_command(text, uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.vixrex_undo_storefront_command(text, uuid)
  to authenticated, service_role;
