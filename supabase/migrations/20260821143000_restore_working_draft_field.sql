-- #261: çalışma taslağındaki tek alanı, diğer taslak değişikliklerine
-- dokunmadan canlı stores değerine döndürür.

create or replace function public.restore_working_draft_field(
  p_session_token text,
  p_key text
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
  v_live_value jsonb;
  v_draft_value jsonb;
  v_draft_version bigint;
  v_changed boolean;
begin
  if p_session_token is null or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo, to_jsonb(st) -> v_key
  into v_store_id, v_slug, v_is_demo, v_live_value
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
  ) then
    raise exception 'UNKNOWN_FIELD';
  end if;

  -- Satırı kilitle: aynı taslakta eşzamanlı alan yazımı sürüm hesabını veya
  -- başka bir alanı ezmesin. base_live_version ve atlanan_alanlar değişmez.
  select draft_data -> v_key, draft_version
  into v_draft_value, v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  v_changed := v_draft_value is distinct from v_live_value;

  if v_changed then
    update public.store_working_drafts
    set draft_data = jsonb_set(
          draft_data,
          array[v_key],
          coalesce(v_live_value, 'null'::jsonb),
          true
        ),
        draft_version = draft_version + 1,
        updated_at = now()
    where store_id = v_store_id
    returning draft_version into v_draft_version;
  end if;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'key', v_key,
    'value', coalesce(v_live_value, 'null'::jsonb),
    'changed', v_changed,
    'draft_version', v_draft_version
  );
end;
$$;

comment on function public.restore_working_draft_field is
  'Sahip çalışma taslağındaki tek alanı canlı stores değerine döndürür; diğer taslak alanlarını korur.';

revoke all on function public.restore_working_draft_field(text, text) from public;
grant execute on function public.restore_working_draft_field(text, text) to anon, authenticated;

notify pgrst, 'reload schema';
