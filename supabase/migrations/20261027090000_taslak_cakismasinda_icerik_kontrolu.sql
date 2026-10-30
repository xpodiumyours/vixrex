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
  v_has_account boolean;
  v_draft_draft_version bigint;
  v_draft_base_live_version bigint;
  v_draft_data jsonb;
  v_atlanan_alanlar text[];
  v_created boolean;
  v_conflict boolean;
  v_taslak_veri jsonb;
  v_canli_veri jsonb;
  v_fark integer;
  v_anahtar text;
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
    s.assistant_handoff,
    st.user_id is not null
  into
    v_store_id,
    v_slug,
    v_is_demo,
    v_live_version,
    v_assistant_handoff,
    v_has_account
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

  select draft_version, base_live_version, draft_data, atlanan_alanlar
  into v_draft_draft_version, v_draft_base_live_version, v_draft_data, v_atlanan_alanlar
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
    v_atlanan_alanlar := '{}';

    select draft_data into v_draft_data
    from public.store_working_drafts
    where store_id = v_store_id;

    v_created := true;
  else
    v_conflict := (v_draft_base_live_version <> v_live_version);

    if v_conflict then
      v_taslak_veri := public.strip_draft_secrets(v_draft_data);

      select public.strip_draft_secrets(to_jsonb(st))
      into v_canli_veri
      from public.stores st
      where st.id = v_store_id;

      v_fark := 0;
      for v_anahtar in select pg_catalog.jsonb_object_keys(v_canli_veri)
      loop
        if v_taslak_veri -> v_anahtar is distinct from v_canli_veri -> v_anahtar then
          v_fark := v_fark + 1;
        end if;
      end loop;

      if v_fark = 0 then
        update public.store_working_drafts
        set base_live_version = v_live_version
        where store_id = v_store_id;

        v_draft_base_live_version := v_live_version;
        v_conflict := false;
      end if;
    end if;
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
    'assistant_handoff', v_assistant_handoff,
    'atlanan_alanlar', to_jsonb(coalesce(v_atlanan_alanlar, '{}')),
    'has_account', coalesce(v_has_account, false)
  );
end;
$$;

revoke execute on function public.get_working_draft_for_session(text) from public;
grant execute on function public.get_working_draft_for_session(text)
  to anon, authenticated;

notify pgrst, 'reload schema';
