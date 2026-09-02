-- Faz 0 (Tek Asistan planı): "hesabına bağla" CTA'sının hangi vitrinde
-- gösterileceğini belirlemek için gereken bilgi.
--
-- SORUN (canlı veriyle doğrulandı, 2026-09-02):
--   OwnerWorkspaceShell.tsx'teki "Google ile bağla" bandı `isDemo` (yani
--   stores.is_demo) koşuluna bakıyor. Ama:
--     1) is_demo=true olan satırlar yalnız 9 kanonik ŞABLONUN kendisi
--        (kiralik-kafe vb.) — hiçbir müşteri kendi vitrinini bu bayrakla
--        görmez; clone_demo_store_as_draft klonu is_demo=false doğurur
--        (kolonun default'u false, INSERT listesinde hiç geçmiyor).
--     2) get_working_draft_for_session zaten is_demo=true olan satırlar
--        için DEMO_STORE_IMMUTABLE fırlatıyor — yani isOwnerMode hiçbir
--        zaman is_demo=true iken true olamaz. Bant koşulu ULAŞILAMAZ kod.
--   Ölçüm: demo olmayan 29 gerçek mağazadan yalnız 2'sinin user_id'si dolu;
--   kalan 27'si edit_token ile yönetiliyor ve bu CTA'yı hiç göremiyordu.
--
-- ÇÖZÜM: get_working_draft_for_session zaten stores satırını okuyor —
-- user_id'yi SEÇMEDEN (V-09 dersi: authenticated'e SELECT açık değil,
-- PostgREST kolon bazlı grant arar) yalnız TÜRETİLMİŞ bir boolean döner.
-- Bu fonksiyon SECURITY DEFINER olduğu için iç sorgusu grant'e tabi değil.

create or replace function public.get_working_draft_for_session(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token text := pg_catalog.btrim(coalesce(p_session_token, ''));
  v_token_hash text;
  v_store_id uuid;
  v_slug text;
  v_is_demo boolean;
  v_live_version bigint;
  v_assistant_handoff jsonb;
  v_has_account boolean;
  v_draft_draft_version bigint;
  v_draft_base_live_version bigint;
  v_draft_data jsonb;
  v_atlanan_alanlar text[];
  v_created boolean;
  v_conflict boolean;
begin
  if v_token = '' then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if pg_catalog.length(v_token) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(v_token::bytea), 'hex');

  select
    s.store_id,
    st.slug,
    st.is_demo,
    st.version,
    s.assistant_handoff,
    st.user_id is not null
  into
    v_store_id,
    v_slug,
    v_is_demo,
    v_live_version,
    v_assistant_handoff,
    v_has_account
  from public.owner_sessions s
  join public.stores st on st.id = s.store_id
  where s.session_token_hash = v_token_hash
    and s.consumed_at is not null
    and s.expires_at > now();

  if not found then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  select draft_version, base_live_version, draft_data, atlanan_alanlar
  into v_draft_draft_version, v_draft_base_live_version, v_draft_data, v_atlanan_alanlar
  from public.store_working_drafts
  where store_id = v_store_id;

  v_created := false;
  v_conflict := false;

  if v_draft_draft_version is null then
    insert into public.store_working_drafts (
      store_id, draft_data, draft_version, base_live_version
    )
    select id, public.strip_draft_secrets(to_jsonb(s)), 1, version
    from public.stores s
    where id = v_store_id;

    v_draft_draft_version := 1;
    v_draft_base_live_version := v_live_version;
    v_atlanan_alanlar := '{}';

    select draft_data into v_draft_data
    from public.store_working_drafts
    where store_id = v_store_id;

    v_created := true;
  else
    v_conflict := (v_draft_base_live_version <> v_live_version);
  end if;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'draft_data', public.strip_draft_secrets(v_draft_data),
    'draft_version', v_draft_draft_version,
    'base_live_version', v_draft_base_live_version,
    'live_version', coalesce(v_live_version, 1),
    'version_conflict', v_conflict,
    'created', v_created,
    'assistant_handoff', v_assistant_handoff,
    'atlanan_alanlar', to_jsonb(coalesce(v_atlanan_alanlar, '{}')),
    'has_account', coalesce(v_has_account, false)
  );
end;
$$;

revoke execute on function public.get_working_draft_for_session(text) from public;
grant execute on function public.get_working_draft_for_session(text)
  to anon, authenticated;

comment on function public.get_working_draft_for_session(text) is
  'Sahip oturum token''ıyla çalışma taslağını döner. Faz 0 (2026-09-02):
   ayrıca has_account (stores.user_id dolu mu) döner — ham user_id hiç
   seçilmez, yalnız türetilmiş boolean. "Hesabına bağla" CTA''sı bunu
   kullanır; artık ulaşılamaz olan is_demo koşulunun yerini alır.';

notify pgrst, 'reload schema';
