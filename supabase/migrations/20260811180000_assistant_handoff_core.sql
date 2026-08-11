-- Vixrex Asistan güvenli handoff CORE.
--
-- Tek omurga ilkesi: handoff için ikinci tablo/veri yolu açılmaz. Sürüm 1
-- özeti, zaten mağazaya bağlı, 15 dakika yaşayan ve yalnız hash'lenmiş
-- yetki verisi tutan owner_sessions satırına atomik olarak eklenir.
--
-- Güvenlik sınırı:
--   * Doğrudan tablo erişimi kapalı (RLS açık, politika yok).
--   * İstemci yalnız izin listeli ve boyutu sınırlı bir JSON özeti yazabilir.
--   * edit_token/session_token/ocode hiçbir biçimde handoff'a alınmaz.
--   * Handoff yalnız tüketilmiş ve süresi dolmamış session_token ile okunur.
--   * Eski create_owner_session RPC'si aynı çekirdeğe bağlı kalır.

alter table public.owner_sessions
  add column if not exists assistant_handoff jsonb;

alter table public.owner_sessions enable row level security;
revoke all on table public.owner_sessions from anon, authenticated;

comment on column public.owner_sessions.assistant_handoff is
  'Vixrex Asistan geçiş özeti. Sürüm 1, izin listeli, en fazla 16 KiB; yalnız geçerli owner session üzerinden okunur.';

alter table public.owner_sessions
  drop constraint if exists owner_sessions_assistant_handoff_v1_check;

alter table public.owner_sessions
  add constraint owner_sessions_assistant_handoff_v1_check
  check (
    assistant_handoff is null
    or (
      jsonb_typeof(assistant_handoff) = 'object'
      and assistant_handoff ->> 'version' = '1'
      and pg_catalog.octet_length(assistant_handoff::text) <= 16384
    )
  );

create or replace function public.sanitize_assistant_handoff(p_data jsonb)
returns jsonb
language plpgsql
immutable
set search_path = pg_catalog
as $$
declare
  v_version integer;
  v_completed_input jsonb;
  v_completed jsonb := '[]'::jsonb;
  v_messages_input jsonb;
  v_messages jsonb := '[]'::jsonb;
  v_item jsonb;
  v_step text;
  v_next text;
  v_role text;
  v_text text;
begin
  if p_data is null then
    return null;
  end if;

  if jsonb_typeof(p_data) <> 'object' then
    raise exception 'INVALID_ASSISTANT_HANDOFF';
  end if;

  if pg_catalog.octet_length(p_data::text) > 16384 then
    raise exception 'ASSISTANT_HANDOFF_TOO_LARGE';
  end if;

  -- Yetki sırları üst seviyede veya mesaj nesnelerinde görünürse sessizce
  -- ayıklamak yerine tüm isteği reddet. Böylece yanlış istemci davranışı
  -- fark edilmeden kalıcılaşmaz.
  if p_data::text ~* '"(edit_token|session_token|ocode)"[[:space:]]*:' then
    raise exception 'ASSISTANT_HANDOFF_SECRET_FORBIDDEN';
  end if;

  if not (p_data ? 'version')
    or jsonb_typeof(p_data -> 'version') <> 'number' then
    raise exception 'INVALID_ASSISTANT_HANDOFF_VERSION';
  end if;

  begin
    v_version := (p_data ->> 'version')::integer;
  exception
    when invalid_text_representation then
      raise exception 'INVALID_ASSISTANT_HANDOFF_VERSION';
  end;

  if v_version <> 1 then
    raise exception 'UNSUPPORTED_ASSISTANT_HANDOFF_VERSION';
  end if;

  v_completed_input := coalesce(p_data -> 'completed_steps', '[]'::jsonb);
  if jsonb_typeof(v_completed_input) <> 'array'
    or jsonb_array_length(v_completed_input) > 6 then
    raise exception 'INVALID_ASSISTANT_HANDOFF_STEPS';
  end if;

  for v_item in
    select value from jsonb_array_elements(v_completed_input)
  loop
    if jsonb_typeof(v_item) <> 'string' then
      raise exception 'INVALID_ASSISTANT_HANDOFF_STEP';
    end if;

    v_step := v_item #>> '{}';
    if not (v_step = any (array[
      'name', 'category', 'whatsapp', 'location', 'legal', 'publishing'
    ])) then
      raise exception 'INVALID_ASSISTANT_HANDOFF_STEP';
    end if;

    if not (v_completed @> jsonb_build_array(v_step)) then
      v_completed := v_completed || jsonb_build_array(v_step);
    end if;
  end loop;

  if p_data ? 'next_step'
    and jsonb_typeof(p_data -> 'next_step') not in ('string', 'null') then
    raise exception 'INVALID_ASSISTANT_HANDOFF_NEXT_STEP';
  end if;

  v_next := nullif(pg_catalog.btrim(coalesce(p_data ->> 'next_step', '')), '');
  if v_next is not null
    and not (v_next = any (array[
      'name', 'category', 'whatsapp', 'location', 'legal', 'publishing', 'done'
    ])) then
    raise exception 'INVALID_ASSISTANT_HANDOFF_NEXT_STEP';
  end if;

  v_messages_input := coalesce(p_data -> 'messages', '[]'::jsonb);
  if jsonb_typeof(v_messages_input) <> 'array'
    or jsonb_array_length(v_messages_input) > 24 then
    raise exception 'INVALID_ASSISTANT_HANDOFF_MESSAGES';
  end if;

  for v_item in
    select value from jsonb_array_elements(v_messages_input)
  loop
    if jsonb_typeof(v_item) <> 'object'
      or jsonb_typeof(v_item -> 'role') <> 'string'
      or jsonb_typeof(v_item -> 'text') <> 'string' then
      raise exception 'INVALID_ASSISTANT_HANDOFF_MESSAGE';
    end if;

    v_role := v_item ->> 'role';
    v_text := pg_catalog.btrim(v_item ->> 'text');

    if not (v_role = any (array['assistant', 'user']))
      or v_text = ''
      or pg_catalog.char_length(v_text) > 500 then
      raise exception 'INVALID_ASSISTANT_HANDOFF_MESSAGE';
    end if;

    if v_text ~* '(edit_token|session_token|ocode)[[:space:]]*[:=]' then
      raise exception 'ASSISTANT_HANDOFF_SECRET_FORBIDDEN';
    end if;

    -- Yalnız rol ve görünür metin taşınır; istemciden gelen diğer alanlar
    -- (kimlik, araç çağrısı, model metadatası vb.) kalıcılaştırılmaz.
    v_messages := v_messages || jsonb_build_array(
      jsonb_build_object('role', v_role, 'text', v_text)
    );
  end loop;

  return jsonb_build_object(
    'version', 1,
    'completed_steps', v_completed,
    'next_step', to_jsonb(v_next),
    'messages', v_messages
  );
end;
$$;

comment on function public.sanitize_assistant_handoff(jsonb) is
  'assistant_handoff_v1 sözleşmesini doğrular ve yalnız izin listeli alanları döndürür. İstemciye doğrudan açık değildir.';

revoke execute on function public.sanitize_assistant_handoff(jsonb)
  from public, anon, authenticated;

create or replace function public._create_owner_session_core(
  p_slug text,
  p_edit_token text,
  p_assistant_handoff jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_store_id uuid;
  v_is_demo boolean;
  v_code text;
  v_code_hash text;
  v_expires_at timestamptz;
  v_handoff jsonb;
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;

  select id, is_demo
  into v_store_id, v_is_demo
  from public.stores
  where slug = v_slug;

  if v_store_id is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  if not (
    (
      v_user_id is not null
      and exists (
        select 1 from public.stores
        where id = v_store_id and user_id = v_user_id
      )
    )
    or (
      v_token <> ''
      and exists (
        select 1 from public.stores
        where id = v_store_id and edit_token = v_token
      )
    )
  ) then
    raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode = 'P0001';
  end if;

  v_handoff := public.sanitize_assistant_handoff(p_assistant_handoff);
  v_code := encode(gen_random_bytes(16), 'hex');
  v_code_hash := encode(sha256(v_code::bytea), 'hex');
  v_expires_at := now() + interval '15 minutes';

  insert into public.owner_sessions (
    store_id,
    user_id,
    code_hash,
    expires_at,
    assistant_handoff
  )
  values (
    v_store_id,
    v_user_id,
    v_code_hash,
    v_expires_at,
    v_handoff
  );

  return jsonb_build_object(
    'code', v_code,
    'expires_at', v_expires_at
  );
end;
$$;

comment on function public._create_owner_session_core(text, text, jsonb) is
  'Eski ve handoff destekli owner-session RPC''lerinin tek iç çekirdeği. Doğrudan istemci çağrısına kapalıdır.';

revoke execute on function public._create_owner_session_core(text, text, jsonb)
  from public, anon, authenticated;

-- Geriye uyumluluk: mevcut Flutter sürümleri aynı iki parametreli RPC'yi
-- çağırmaya devam eder ve handoff olmadan aynı güvenli çekirdeği kullanır.
create or replace function public.create_owner_session(
  p_slug text,
  p_edit_token text default null
)
returns jsonb
language sql
security definer
set search_path = pg_catalog, public, extensions
as $$
  select public._create_owner_session_core(
    p_slug,
    p_edit_token,
    null::jsonb
  );
$$;

-- Yeni Flutter entegrasyonu bu RPC'yi çağıracak. Ayrı isim, PostgREST
-- fonksiyon overload belirsizliğini ve eski istemci kırılmasını önler.
create or replace function public.create_owner_session_with_handoff(
  p_slug text,
  p_edit_token text,
  p_assistant_handoff jsonb
)
returns jsonb
language sql
security definer
set search_path = pg_catalog, public, extensions
as $$
  select public._create_owner_session_core(
    p_slug,
    p_edit_token,
    p_assistant_handoff
  );
$$;

revoke execute on function public.create_owner_session(text, text) from public;
grant execute on function public.create_owner_session(text, text)
  to anon, authenticated;

revoke execute on function public.create_owner_session_with_handoff(text, text, jsonb)
  from public;
grant execute on function public.create_owner_session_with_handoff(text, text, jsonb)
  to anon, authenticated;

-- Next.js mevcut güvenli session_token okumasıyla aynı taslağı ve ona bağlı
-- handoff özetini birlikte alır. Handoff için ayrı okuma endpoint'i yoktur.
create or replace function public.get_working_draft_for_session(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token text := pg_catalog.btrim(coalesce(p_session_token, ''));
  v_token_hash text;
  v_store_id uuid;
  v_slug text;
  v_is_demo boolean;
  v_live_version bigint;
  v_assistant_handoff jsonb;
  v_draft_draft_version bigint;
  v_draft_base_live_version bigint;
  v_draft_data jsonb;
  v_created boolean;
  v_conflict boolean;
begin
  if v_token = '' then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if pg_catalog.length(v_token) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(v_token::bytea), 'hex');

  select
    s.store_id,
    st.slug,
    st.is_demo,
    st.version,
    s.assistant_handoff
  into
    v_store_id,
    v_slug,
    v_is_demo,
    v_live_version,
    v_assistant_handoff
  from public.owner_sessions s
  join public.stores st on st.id = s.store_id
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > now();

  if not found then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  select draft_version, base_live_version, draft_data
  into v_draft_draft_version, v_draft_base_live_version, v_draft_data
  from public.store_working_drafts
  where store_id = v_store_id;

  v_created := false;
  v_conflict := false;

  if v_draft_draft_version is null then
    insert into public.store_working_drafts (
      store_id, draft_data, draft_version, base_live_version
    )
    select id, public.strip_draft_secrets(to_jsonb(s)), 1, version
    from public.stores s
    where id = v_store_id;

    v_draft_draft_version := 1;
    v_draft_base_live_version := v_live_version;

    select draft_data into v_draft_data
    from public.store_working_drafts
    where store_id = v_store_id;

    v_created := true;
  else
    v_conflict := (v_draft_base_live_version <> v_live_version);
  end if;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'draft_data', public.strip_draft_secrets(v_draft_data),
    'draft_version', v_draft_draft_version,
    'base_live_version', v_draft_base_live_version,
    'live_version', coalesce(v_live_version, 1),
    'version_conflict', v_conflict,
    'created', v_created,
    'assistant_handoff', v_assistant_handoff
  );
end;
$$;

revoke execute on function public.get_working_draft_for_session(text) from public;
grant execute on function public.get_working_draft_for_session(text)
  to anon, authenticated;

notify pgrst, 'reload schema';
