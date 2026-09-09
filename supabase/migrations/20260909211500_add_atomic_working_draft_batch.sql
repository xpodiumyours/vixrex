-- Vixrex Assistant: bir kullanıcı cümlesinden çıkan birden fazla taslak
-- değişikliğini tek transaction içinde uygular.
--
-- NEDEN AYRI RPC:
-- Mevcut update_working_draft_field tek alan için doğru ve manuel panelin
-- kanonik yoludur. Asistan ise tek cümleden birden çok alan çıkarabiliyor;
-- tek-alan RPC'yi döngüde çağırmak kısmi kayıt üretebilir. Bu fonksiyon
-- mevcut tek-alan sözleşmesini değiştirmeden yalnız batch ihtiyacını ekler.
--
-- GÜVENLİK:
-- - owner session token aynı owner_sessions sözleşmesiyle doğrulanır.
-- - demo vitrin değiştirilemez.
-- - owner_forbidden_draft_keys yeniden kullanılır.
-- - yalnız stores tablosunda gerçekten var olan kolonlar kabul edilir.
-- - en fazla 20 alan; uydurma/boş değişiklik reddedilir.
-- - taslak satırı FOR UPDATE ile kilitlenir.
-- - bütün değişiklikler tek UPDATE + tek draft_version artışıyla yazılır.
-- - JSON null mevcut tek-alan RPC gibi anahtarı taslaktan kaldırır.

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
begin
  if p_session_token is null
     or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if p_changes is null or pg_catalog.jsonb_typeof(p_changes) <> 'object' then
    raise exception 'INVALID_CHANGES';
  end if;

  select count(*) into v_change_count
  from pg_catalog.jsonb_object_keys(p_changes);

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

  -- Bütün anahtarları yazmadan önce doğrula. Bir tanesi bile geçersizse
  -- exception transactionı keser; taslağa hiçbir kısmi değişiklik gitmez.
  for v_key in select pg_catalog.jsonb_object_keys(p_changes)
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

  -- Aynı taslakta iki istemci aynı anda yazarsa son okuyan ilk yazanı
  -- sessizce ezmesin: satırı transaction sonuna kadar kilitle.
  select draft_data, draft_version
  into v_draft_data, v_draft_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  v_new_data := v_draft_data;
  for v_key in select pg_catalog.jsonb_object_keys(p_changes)
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

  return pg_catalog.jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'changed_count', v_change_count,
    'draft_version', v_draft_version
  );
end;
$$;

comment on function public.update_working_draft_fields(text, jsonb) is
  'Vixrex Assistant için doğrulanmış çoklu çalışma-taslağı değişikliklerini tek transaction ve tek sürüm artışıyla uygular.';

revoke all on function public.update_working_draft_fields(text, jsonb) from public;
grant execute on function public.update_working_draft_fields(text, jsonb) to anon, authenticated;

notify pgrst, 'reload schema';
