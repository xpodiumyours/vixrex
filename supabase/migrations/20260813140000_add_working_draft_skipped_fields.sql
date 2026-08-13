-- Vixrex Asistan rehberli tamamlama (ADR 0002) — 3. alt-faz: "boş geç"
-- dediğin isteğe bağlı alanları KALICI hatırla. Önceki alt-fazda bu yalnız
-- oturum belleğindeydi (sayfa yenilenince unutuluyordu).
--
-- Ayrı bir kolon: `stores` tablosunun gerçek bir kolonu DEĞİL, akış
-- durumu — update_working_draft_field'ın "gerçek stores kolonu mu"
-- kontrolünden bilerek dışarıda tutuluyor, kendi dar RPC'siyle yazılıyor.

alter table public.store_working_drafts
  add column if not exists atlanan_alanlar text[] not null default '{}';

comment on column public.store_working_drafts.atlanan_alanlar is
  'Vixrex Asistan rehberli akışında "boş geç" denen isteğe bağlı alan anahtarları (vitrinFieldSchema.ts anahtar). Vitrin içeriği değil, yalnız akış durumu.';

-- Yalnız hâlâ geçerli bir oturumla, tek bir anahtarı işaretler. `v_key`
-- gerçek bir stores kolonuna karşılık gelmek ZORUNDA değil (bu liste
-- vitrin içeriği değil) — bilinmeyen bir anahtar yazılırsa zararsızca
-- hiçbir alanla eşleşmez, sessizce göz ardı edilir. İsteğe bağlı/temel
-- ayrımı da burada tekrar edilmez (TypeScript şeması tek kaynak, ADR
-- 0001) — istemci yalnız isteğe bağlı alanlarda bu düğmeyi gösterir;
-- burada zorlanması sunucu tarafında ikinci bir "isteğe bağlı" listesi
-- doğurur, aynı hatayı ikinci kez yapar.
create or replace function public.mark_working_draft_field_skipped(
  p_session_token text,
  p_key text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token_hash text;
  v_store_id uuid;
  v_is_demo boolean;
  v_key text := pg_catalog.btrim(coalesce(p_key, ''));
  v_atlanan text[];
begin
  if p_session_token is null or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.is_demo
  into v_store_id, v_is_demo
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

  update public.store_working_drafts
  set atlanan_alanlar = case
        when v_key = any(atlanan_alanlar) then atlanan_alanlar
        else atlanan_alanlar || v_key
      end,
      updated_at = now()
  where store_id = v_store_id
  returning atlanan_alanlar into v_atlanan;

  if v_atlanan is null then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  return jsonb_build_object('atlanan_alanlar', to_jsonb(v_atlanan));
end;
$$;

comment on function public.mark_working_draft_field_skipped is
  'Rehberli akışta "boş geç" denen isteğe bağlı alanı kalıcı işaretler. Oturum tokenıyla yetkilendirir.';

revoke all on function public.mark_working_draft_field_skipped(text, text) from public;
grant execute on function public.mark_working_draft_field_skipped(text, text) to anon, authenticated;

-- get_working_draft_for_session artık atlanan_alanlar'ı da döner — istemci
-- sayfa açılışında "boş geçilenleri" hatırlar, bir daha önermez.
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
    s.assistant_handoff
  into
    v_store_id,
    v_slug,
    v_is_demo,
    v_live_version,
    v_assistant_handoff
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
    'atlanan_alanlar', to_jsonb(coalesce(v_atlanan_alanlar, '{}'))
  );
end;
$$;

revoke execute on function public.get_working_draft_for_session(text) from public;
grant execute on function public.get_working_draft_for_session(text)
  to anon, authenticated;

notify pgrst, 'reload schema';
