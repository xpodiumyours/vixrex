-- Vixrex Assistant undo sınırı.
--
-- 20260909223500 migration'ı tek-alan ve batch yazımına undo kaydı ekledi.
-- Doğrulama sırasında şu yarış bulundu:
--   Assistant X alanını yazar → kart açık kalır → kullanıcı X'i manuel değiştirir
--   → eski kart yalnız anahtar listesiyle en yeni X undo kaydını seçebilirdi.
--
-- Güvenli kural: gerçek Assistant "Geri al" yalnız Assistant'ın
-- `/owner-draft-batch` yolunun oluşturduğu undo işlemini geri alır.
-- Manuel tek-alan `update_working_draft_field` mevcut davranışına döner ve
-- undo kaydı oluşturmaz. Assistant serbest mesajı tek alan olsa bile batch
-- endpoint'i kullanır (istemci kontratıyla kilitlidir).

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

  -- Aynı alanın eşzamanlı yazımları draft_version hesabını kaybetmesin.
  select draft_version
  into v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

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

  return pg_catalog.jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'key', v_key,
    'draft_version', v_draft_version
  );
end;
$$;

comment on function public.update_working_draft_field(text, text, jsonb) is
  'Manuel/tek-alan çalışma taslağı yazımı. Assistant undo kaydı oluşturmaz; Assistant serbest-metin işlemleri batch RPC kullanır.';

revoke all on function public.update_working_draft_field(text, text, jsonb) from public;
grant execute on function public.update_working_draft_field(text, text, jsonb) to anon, authenticated;

notify pgrst, 'reload schema';