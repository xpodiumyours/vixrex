-- PR1-C4: owner workspace bootstrap — tek çağrıda sahiplik + taslak + akış + konuşma özeti
-- Eski istemcileri etkilemez: yalnızca okur, yazma/oluşturma yapmaz.
-- Yetki: yalnız auth.uid() üzerinden; search_path sabit, revoke/grant açık.

create or replace function public.get_owner_workspace_bootstrap()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_store jsonb;
  v_draft jsonb;
  v_flow jsonb;
  v_conversation jsonb;
  v_store_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object(
      'user_id', null,
      'store', null,
      'working_draft', null,
      'flow_state', null,
      'conversation', null
    );
  end if;

  -- Mağaza (hesap başına tek)
  select to_jsonb(s) into v_store
  from public.stores s
  where s.user_id = v_user_id
  limit 1;

  if v_store is not null then
    v_store_id := (v_store->>'id')::uuid;

    -- Çalışma taslağı (varsa)
    select jsonb_build_object(
      'store_id', d.store_id,
      'draft_data', public.strip_draft_secrets(d.draft_data),
      'draft_version', d.draft_version,
      'base_live_version', d.base_live_version,
      'updated_at', d.updated_at
    ) into v_draft
    from public.store_working_drafts d
    where d.store_id = v_store_id;

    -- Akış durumu (varsa)
    select to_jsonb(f) into v_flow
    from public.owner_flow_states f
    where f.user_id = v_user_id
    order by f.updated_at desc
    limit 1;

    -- Aktif konuşma ve son 20 mesaj özeti (varsa)
    select jsonb_build_object(
      'id', c.id,
      'store_id', c.store_id,
      'created_at', c.created_at,
      'updated_at', c.updated_at,
      'messages', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', m.id,
            'seq', m.seq,
            'role', m.role,
            'message_key', m.message_key,
            'message_text', m.message_text,
            'catalog_snapshot', m.catalog_snapshot,
            'client_message_id', m.client_message_id,
            'created_at', m.created_at
          ) order by m.seq asc
        )
        from public.assistant_messages m
        where m.conversation_id = c.id
        order by m.seq desc
        limit 20
      ), '[]'::jsonb)
    ) into v_conversation
    from public.assistant_conversations c
    where c.user_id = v_user_id
    order by c.updated_at desc
    limit 1;
  else
    -- Mağazası olmayan kullanıcı için akış/konuşma yine dönebilir
    select to_jsonb(f) into v_flow
    from public.owner_flow_states f
    where f.user_id = v_user_id
    order by f.updated_at desc
    limit 1;

    select jsonb_build_object(
      'id', c.id,
      'store_id', c.store_id,
      'created_at', c.created_at,
      'updated_at', c.updated_at,
      'messages', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', m.id,
            'seq', m.seq,
            'role', m.role,
            'message_key', m.message_key,
            'message_text', m.message_text,
            'catalog_snapshot', m.catalog_snapshot,
            'client_message_id', m.client_message_id,
            'created_at', m.created_at
          ) order by m.seq asc
        )
        from public.assistant_messages m
        where m.conversation_id = c.id
        order by m.seq desc
        limit 20
      ), '[]'::jsonb)
    ) into v_conversation
    from public.assistant_conversations c
    where c.user_id = v_user_id
    order by c.updated_at desc
    limit 1;
  end if;

  return jsonb_build_object(
    'user_id', v_user_id,
    'store', coalesce(v_store, 'null'::jsonb),
    'working_draft', v_draft,
    'flow_state', v_flow,
    'conversation', v_conversation
  );
end;
$$;

revoke execute on function public.get_owner_workspace_bootstrap() from public;
grant execute on function public.get_owner_workspace_bootstrap() to authenticated;

comment on function public.get_owner_workspace_bootstrap() is
  'Owner Workspace Bootstrap: auth.uid() için mağaza + working_draft + flow_state + conversation özetini tek çağrıda döner. Yalnız okur, oluşturmaz.';
