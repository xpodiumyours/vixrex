-- PR3-C11: landing yerel başlangıç -> owner_flow_states + konuşma import (idempotent)
-- Hesap bağlandıktan sonra tek seferde aktarır; tekrar çağrı aynı sonucu üretir.

create or replace function public.import_landing_flow_state(
  p_flow_type text,
  p_selected_template text default null,
  p_current_step text default null,
  p_client_message_id text default null,
  p_message_text text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_flow public.owner_flow_states%rowtype;
  v_conversation_id uuid;
  v_msg jsonb;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_flow_type not in ('create', 'rental') then
    raise exception 'INVALID_FLOW_TYPE' using errcode = 'P0001';
  end if;

  -- Flow state: varsa döndür (idempotent), yoksa oluştur
  select * into v_flow from public.owner_flow_states where user_id = v_user_id;
  if not found then
    insert into public.owner_flow_states (user_id, flow_type, selected_template, current_step, completed_steps)
    values (v_user_id, p_flow_type, p_selected_template, coalesce(p_current_step, 'name'), '{}')
    returning * into v_flow;
  else
    -- Mevcut akış farklı tipte ise güncelleme yapma, mevcutu döndür (tek akış kuralı)
    -- Seçilen şablon boşsa mevcut korunur
    if p_selected_template is not null and v_flow.selected_template is null then
      update public.owner_flow_states
      set selected_template = p_selected_template
      where id = v_flow.id
      returning * into v_flow;
    end if;
  end if;

  -- Konuşma: varsa al, yoksa oluştur
  select id into v_conversation_id from public.assistant_conversations where user_id = v_user_id limit 1;
  if v_conversation_id is null then
    insert into public.assistant_conversations (user_id) values (v_user_id) returning id into v_conversation_id;
  end if;

  -- İstemci mesajı varsa idempotent ekle (ayrı landing conversation oluşturmaz)
  if p_client_message_id is not null and p_message_text is not null then
    -- Aynı client_message_id tekrar gelirse append fonksiyonu mevcutu döner
    select public.append_assistant_message(
      v_conversation_id,
      p_client_message_id,
      'user',
      null,
      p_message_text,
      null
    ) into v_msg;
  end if;

  return jsonb_build_object(
    'flow_state', to_jsonb(v_flow),
    'conversation_id', v_conversation_id,
    'message', v_msg
  );
end;
$$;

revoke execute on function public.import_landing_flow_state(text, text, text, text, text) from public;
grant execute on function public.import_landing_flow_state(text, text, text, text, text) to authenticated;

comment on function public.import_landing_flow_state(text, text, text, text, text) is
  'Landing yerel başlangıcı owner_flow_states + tek active conversation''a idempotent aktarır. Tekrar çağrı aynı sonucu üretir.';
