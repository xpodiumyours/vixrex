-- Cerrahi 2026-09-11 (Risk 5): ayni anda yazismada kayip olmasin.
-- 1) append_assistant_message: parent satiri FOR UPDATE ile kilitle (seq uretimi serilesir),
--    client_message_id icin ON CONFLICT ile idempotent don, seq yarismasinda 3 kez dene.
-- 2) ensure_assistant_conversation: cift ensure ON CONFLICT ile tek satira duser.
-- Davranis korunur: hata kodlari ayni, grant/revoke ayni, gorsel degisiklik yok.

create or replace function public.append_assistant_message(
  p_conversation_id uuid,
  p_client_message_id text,
  p_role text,
  p_message_key text default null,
  p_message_text text default null,
  p_catalog_snapshot text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation public.assistant_conversations%rowtype;
  v_next_seq bigint;
  v_msg public.assistant_messages%rowtype;
  v_attempt int := 0;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_conversation_id is null or p_client_message_id is null or p_role is null then
    raise exception 'INVALID_PARAMS' using errcode = 'P0001';
  end if;

  if p_role not in ('assistant', 'user') then
    raise exception 'INVALID_ROLE' using errcode = 'P0001';
  end if;

  if p_message_text is not null and (char_length(p_message_text) = 0 or char_length(p_message_text) > 4000) then
    raise exception 'INVALID_MESSAGE_TEXT' using errcode = 'P0001';
  end if;

  -- Parent kilit: ayni konusmaya eszamanli yazimlar siralanir.
  select * into v_conversation
  from public.assistant_conversations
  where id = p_conversation_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'CONVERSATION_NOT_FOUND_OR_UNAUTHORIZED' using errcode = 'P0001';
  end if;

  -- Idempotent: ayni client_message_id tekrar gelirse mevcut satiri dondur.
  select * into v_msg
  from public.assistant_messages
  where conversation_id = p_conversation_id and client_message_id = p_client_message_id;

  if found then
    return to_jsonb(v_msg);
  end if;

  -- Seq yarismasi: kilit sonrasi bile farkli node'dan ayni seq gelebilir,
  -- unique_violation'da en fazla 3 dene; client_message_id catismasinda varolani don.
  loop
    v_attempt := v_attempt + 1;
    begin
      select coalesce(max(seq), 0) + 1 into v_next_seq
      from public.assistant_messages
      where conversation_id = p_conversation_id;

      insert into public.assistant_messages (
        conversation_id, seq, role, message_key, message_text, catalog_snapshot, client_message_id
      ) values (
        p_conversation_id, v_next_seq, p_role, p_message_key, coalesce(p_message_text, ''), p_catalog_snapshot, p_client_message_id
      )
      on conflict (conversation_id, client_message_id) where client_message_id is not null do nothing
      returning * into v_msg;

      if found then
        update public.assistant_conversations set updated_at = now() where id = p_conversation_id;
        return to_jsonb(v_msg);
      end if;

      -- ON CONFLICT DO NOTHING calistiysa baskasi ayni client_message_id'yi yazmis.
      select * into v_msg
      from public.assistant_messages
      where conversation_id = p_conversation_id and client_message_id = p_client_message_id;

      if found then
        return to_jsonb(v_msg);
      end if;

      -- Buraya dustuyse seq catismasi degil, beklenmedik durum: tekrar dene.
      if v_attempt >= 3 then
        raise exception 'MESSAGE_WRITE_CONFLICT' using errcode = 'P0001';
      end if;
    exception when unique_violation then
      -- Seq cakismasi: ayni client_message_id mi diye bak, yoksa seq'yi tazeleyip tekrar dene.
      select * into v_msg
      from public.assistant_messages
      where conversation_id = p_conversation_id and client_message_id = p_client_message_id;

      if found then
        return to_jsonb(v_msg);
      end if;

      if v_attempt >= 3 then
        raise;
      end if;
      -- Dongu basi max(seq)'yi yeniden okur.
    end;
  end loop;
end;
$$;

revoke execute on function public.append_assistant_message(uuid, text, text, text, text, text) from public;
grant execute on function public.append_assistant_message(uuid, text, text, text, text, text) to authenticated;

create or replace function public.ensure_assistant_conversation()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation public.assistant_conversations%rowtype;
  v_store_id uuid;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_conversation
  from public.assistant_conversations
  where user_id = v_user_id
  limit 1;

  if found then
    return to_jsonb(v_conversation);
  end if;

  select id into v_store_id
  from public.stores
  where user_id = v_user_id
  limit 1;

  -- Cift ensure yarismasi: ikinci yazim sessizce mevcut satira duser.
  insert into public.assistant_conversations (user_id, store_id)
  values (v_user_id, v_store_id)
  on conflict (user_id) do nothing
  returning * into v_conversation;

  if found then
    return to_jsonb(v_conversation);
  end if;

  select * into v_conversation
  from public.assistant_conversations
  where user_id = v_user_id
  limit 1;

  return to_jsonb(v_conversation);
end;
$$;

revoke all on function public.ensure_assistant_conversation() from public;
grant execute on function public.ensure_assistant_conversation() to authenticated;
