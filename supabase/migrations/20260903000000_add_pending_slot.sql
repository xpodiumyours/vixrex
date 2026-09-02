-- Faz 1: konuşma hafızası – bekleyen slot (netleştirme)
-- Kalıcı hafıza `assistant_conversations.pending_slot jsonb` – Supabase kanonik,
-- SharedPrefs yerel önbellek. Mevcut `assistant_conversations` tablosuna ek kolon,
-- RLS zaten tablo seviyesinde (doğrudan erişim kapalı, SECURITY DEFINER RPC’ler).

alter table public.assistant_conversations
  add column if not exists pending_slot jsonb;

comment on column public.assistant_conversations.pending_slot is
  'Vixrex NLU bekleyen slot: {anahtar, etiket, tip, sorulduAt, deneme} – netleştirme için. Flutter SharedPrefs ile senkron, tek kaynak Supabase.';

-- Doğrulama: pending_slot null veya obje, anahtar 46 alandan biri olmalı (gevşek, Dart tarafı doğrular).
alter table public.assistant_conversations
  drop constraint if exists assistant_conversations_pending_slot_check;

alter table public.assistant_conversations
  add constraint assistant_conversations_pending_slot_check
  check (
    pending_slot is null
    or (
      jsonb_typeof(pending_slot) = 'object'
      and pending_slot ? 'anahtar'
      and jsonb_typeof(pending_slot -> 'anahtar') = 'string'
      and char_length(pending_slot ->> 'anahtar') between 2 and 40
    )
  );

-- RPC: pending_slot yaz (upsert, auth.uid() ile)
create or replace function public.set_assistant_pending_slot(p_slot jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_conv public.assistant_conversations%rowtype;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_slot is not null and jsonb_typeof(p_slot) <> 'object' then
    raise exception 'INVALID_PENDING_SLOT' using errcode = 'P0001';
  end if;

  select * into v_conv from public.assistant_conversations where user_id = v_user_id limit 1;
  if not found then
    -- Konuşma yoksa oluştur (ensure)
    v_conv := (public.ensure_assistant_conversation())::public.assistant_conversations;
  end if;

  update public.assistant_conversations
     set pending_slot = p_slot, updated_at = now()
   where id = v_conv.id
  returning * into v_conv;

  return to_jsonb(v_conv);
end;
$$;

revoke execute on function public.set_assistant_pending_slot(jsonb) from public;
grant execute on function public.set_assistant_pending_slot(jsonb) to authenticated;

comment on function public.set_assistant_pending_slot(jsonb) is
  'Netleştirme bekleyen slot yaz – auth.uid() konuşmasına. null ile temizlenir.';

-- RPC: pending_slot oku (get_assistant_conversation zaten pending_slot döndürmüyor, ayrı RPC)
create or replace function public.get_assistant_pending_slot()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_slot jsonb;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;
  select pending_slot into v_slot from public.assistant_conversations where user_id = v_user_id limit 1;
  return coalesce(v_slot, 'null'::jsonb);
end;
$$;

revoke execute on function public.get_assistant_pending_slot() from public;
grant execute on function public.get_assistant_pending_slot() to authenticated;

-- get_assistant_conversation artık pending_slot’u da döndürsün (mevcut RPC’yi genişlet)
create or replace function public.get_assistant_conversation()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation_id uuid;
  v_conversation jsonb;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;
  v_conversation_id := (public.ensure_assistant_conversation()->>'id')::uuid;
  select jsonb_build_object(
    'id', c.id,
    'store_id', c.store_id,
    'created_at', c.created_at,
    'updated_at', c.updated_at,
    'pending_slot', c.pending_slot,
    'messages', coalesce((
      select jsonb_agg(to_jsonb(recent_message) order by recent_message.seq asc)
      from (
        select m.id, m.seq, m.role, m.message_key, m.message_text, m.catalog_snapshot, m.client_message_id, m.created_at
        from public.assistant_messages m
        where m.conversation_id = c.id
        order by m.seq desc limit 500
      ) recent_message
    ), '[]'::jsonb)
  ) into v_conversation
  from public.assistant_conversations c
  where c.id = v_conversation_id and c.user_id = v_user_id;
  return v_conversation;
end;
$$;

revoke all on function public.get_assistant_conversation() from public;
grant execute on function public.get_assistant_conversation() to authenticated;

comment on function public.get_assistant_conversation() is
  'Kalıcı konuşma + mesajlar + pending_slot – tek RPC.';

notify pgrst, 'reload schema';
