-- PR7-C29: mevcut assistant_handoff bir kez kalici konusmaya aktar.
-- Tekrar ekleme yok — aktarim isareti konur.
create or replace function public.migrate_handoff_to_conversation_once(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_handoff jsonb;
  v_conv_id uuid;
  v_cnt int := 0;
begin
  if p_user_id is null or p_user_id <> auth.uid() then
    raise exception 'NOT_AUTHENTICATED';
  end if;
  for v_handoff, v_conv_id in
    select s.assistant_handoff, c.id
    from public.owner_sessions s
    join public.assistant_conversations c on c.user_id = p_user_id
    where s.store_id in (select id from public.stores where user_id = p_user_id)
      and s.assistant_handoff is not null
      and not coalesce((s.assistant_handoff->>'_migrated')::boolean, false)
    limit 5
  loop
    begin
      perform public.append_assistant_message(v_conv_id, 'handoff-' || v_conv_id::text, 'assistant', v_handoff->>'message_key', v_handoff->>'message_text', v_handoff::text);
      update public.owner_sessions set assistant_handoff = assistant_handoff || '{"_migrated": true}'::jsonb where store_id in (select id from public.stores where user_id = p_user_id);
      v_cnt := v_cnt + 1;
    exception when others then null;
    end;
  end loop;
  return jsonb_build_object('migrated', v_cnt);
end;
$$;
revoke all on function public.migrate_handoff_to_conversation_once(uuid) from public;
grant execute on function public.migrate_handoff_to_conversation_once(uuid) to authenticated;
