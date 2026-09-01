-- Vixrex Asistan tek konuşma seam'i.
-- Hem Flutter hem Next.js aynı kullanıcıya ait tek aktif konuşmayı açar.
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

  insert into public.assistant_conversations (user_id, store_id)
  values (v_user_id, v_store_id)
  returning * into v_conversation;

  return to_jsonb(v_conversation);
end;
$$;

revoke all on function public.ensure_assistant_conversation() from public;
grant execute on function public.ensure_assistant_conversation() to authenticated;

comment on function public.ensure_assistant_conversation() is
  'Flutter ve Next.js için kullanıcı başına tek Vixrex Asistan konuşmasını idempotent olarak döndürür/oluşturur.';

create or replace function public.get_assistant_conversation()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
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
    'messages', coalesce((
      select jsonb_agg(to_jsonb(recent_message) order by recent_message.seq asc)
      from (
        select
          m.id,
          m.seq,
          m.role,
          m.message_key,
          m.message_text,
          m.catalog_snapshot,
          m.client_message_id,
          m.created_at
        from public.assistant_messages m
        where m.conversation_id = c.id
        order by m.seq desc
        limit 500
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
  'Flutter ve Next.js tarafında kullanılan tek Vixrex konuşmasını ve son 500 mesajını sıra korunarak döndürür.';
