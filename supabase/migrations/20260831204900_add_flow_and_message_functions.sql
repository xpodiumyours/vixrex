-- PR1-C5: dar akış ve konuşma fonksiyonları — sürüm çakışması ve idempotency
-- Yetki yalnız auth.uid(), search_path sabit, revoke/grant açık, hata sözleşmesi testli.

-- 1) Akış durumunu beklenen sürümle güncelle
create or replace function public.update_owner_flow_state(
  p_flow_id uuid,
  p_expected_version bigint,
  p_current_step text default null,
  p_completed_steps text[] default null,
  p_selected_template text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.owner_flow_states%rowtype;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_flow_id is null or p_expected_version is null then
    raise exception 'INVALID_PARAMS' using errcode = 'P0001';
  end if;

  -- Sürüm kontrollü güncelleme: sessiz ezme yok, çakışma hatası döner
  update public.owner_flow_states
  set
    current_step = coalesce(p_current_step, current_step),
    completed_steps = coalesce(p_completed_steps, completed_steps),
    selected_template = coalesce(p_selected_template, selected_template)
  where id = p_flow_id
    and user_id = v_user_id
    and version = p_expected_version
  returning * into v_row;

  if not found then
    -- Yetki veya sürüm çakışmasını ayırt et
    if exists (select 1 from public.owner_flow_states where id = p_flow_id and user_id = v_user_id) then
      raise exception 'VERSION_CONFLICT' using errcode = 'P0001';
    else
      raise exception 'FLOW_NOT_FOUND_OR_UNAUTHORIZED' using errcode = 'P0001';
    end if;
  end if;

  return to_jsonb(v_row);
end;
$$;

revoke execute on function public.update_owner_flow_state(uuid, bigint, text, text[], text) from public;
grant execute on function public.update_owner_flow_state(uuid, bigint, text, text[], text) to authenticated;

-- 2) Konuşmaya mesaj ekle (idempotent)
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

  select * into v_conversation
  from public.assistant_conversations
  where id = p_conversation_id and user_id = v_user_id;

  if not found then
    raise exception 'CONVERSATION_NOT_FOUND_OR_UNAUTHORIZED' using errcode = 'P0001';
  end if;

  -- Idempotent: aynı client_message_id tekrar gelirse mevcut satırı döndür
  select * into v_msg
  from public.assistant_messages
  where conversation_id = p_conversation_id and client_message_id = p_client_message_id;

  if found then
    return to_jsonb(v_msg);
  end if;

  -- Sıra: max(seq)+1
  select coalesce(max(seq), 0) + 1 into v_next_seq
  from public.assistant_messages
  where conversation_id = p_conversation_id;

  insert into public.assistant_messages (
    conversation_id, seq, role, message_key, message_text, catalog_snapshot, client_message_id
  ) values (
    p_conversation_id, v_next_seq, p_role, p_message_key, coalesce(p_message_text, ''), p_catalog_snapshot, p_client_message_id
  ) returning * into v_msg;

  -- Konuşma updated_at tetiklenir
  update public.assistant_conversations set updated_at = now() where id = p_conversation_id;

  return to_jsonb(v_msg);
end;
$$;

revoke execute on function public.append_assistant_message(uuid, text, text, text, text, text) from public;
grant execute on function public.append_assistant_message(uuid, text, text, text, text, text) to authenticated;

comment on function public.update_owner_flow_state(uuid, bigint, text, text[], text) is
  'Sürüm kontrollü akış güncellemesi: expected_version eşleşmezse VERSION_CONFLICT. Yetki yalnız auth.uid().';
comment on function public.append_assistant_message(uuid, text, text, text, text, text) is
  'Idempotent mesaj ekleme: aynı client_message_id tekrarı mevcut satırı döner, seq otomatik artar.';
