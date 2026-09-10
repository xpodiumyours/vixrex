-- Vixrex yayın güvenliği: yasal onay DB kapısını geri getir.
--
-- 2026-09-10 production salt-okuma denetiminde:
--   - public.stores üzerinde stores_publish_readiness_guard VAR,
--   - fakat onun çağırdığı public.assert_store_publish_ready yalnız işletme
--     adı/kategori/WhatsApp/adres/il/ilçe kontrol ediyor,
--   - eski trg_validate_store_legal_acceptance ve bağlı private fonksiyon
--     production'da YOK.
--
-- Sonuç: UI yasal onayı kapatsa da geçerli owner session ile
-- publish_working_draft RPC doğrudan çağrıldığında DB'nin kendisi yasal onayı
-- yeniden doğrulamıyordu.
--
-- public.assert_store_publish_ready TEK migration'da tanımlı kalmalı (bkz.
-- store-publish-readiness-contract.test.ts) — 20260821164605 zaten
-- production'da, geri düzenlenemez. Bu yüzden yasal kontrol ayrı bir
-- fonksiyona (assert_store_legal_acceptance_ready) konur; mevcut iki yayın
-- çağrı noktası (publish_working_draft, enforce_store_publish_readiness) bu
-- yeni fonksiyonu da çağıracak şekilde burada yeniden tanımlanır.
--
-- Canlıya otomatik uygulanmaz. Draft PR doğrulama alanıdır.

create or replace function public.assert_store_legal_acceptance_ready(p_store jsonb)
returns void
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
begin
  if coalesce((p_store ->> 'privacy_notice_acknowledged')::boolean, false) is not true then
    raise exception 'PRIVACY_NOTICE_REQUIRED';
  end if;
  if coalesce((p_store ->> 'terms_accepted')::boolean, false) is not true then
    raise exception 'TERMS_ACCEPTANCE_REQUIRED';
  end if;
  if coalesce((p_store ->> 'publication_consent_accepted')::boolean, false) is not true then
    raise exception 'PUBLICATION_CONSENT_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'privacy'
      and d.is_active = true
      and d.version = p_store ->> 'privacy_notice_version'
      and d.content_hash = p_store ->> 'privacy_notice_hash'
  ) then
    raise exception 'PRIVACY_NOTICE_VERSION_INVALID';
  end if;

  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'terms'
      and d.is_active = true
      and d.version = p_store ->> 'terms_version'
      and d.content_hash = p_store ->> 'terms_hash'
  ) then
    raise exception 'TERMS_VERSION_INVALID';
  end if;

  if not exists (
    select 1
    from public.legal_documents d
    where d.document_type = 'consent'
      and d.is_active = true
      and d.version = p_store ->> 'publication_consent_version'
      and d.content_hash = p_store ->> 'publication_consent_hash'
  ) then
    raise exception 'PUBLICATION_CONSENT_VERSION_INVALID';
  end if;
end;
$$;

comment on function public.assert_store_legal_acceptance_ready(jsonb) is
  'İstemciye kapalı yasal onay kapısı: aktif belge sürüm/hash eşleşmesini doğrular. assert_store_publish_ready''ı değiştirmeden, onunla birlikte çağrılır.';

revoke execute on function public.assert_store_legal_acceptance_ready(jsonb) from public;
revoke execute on function public.assert_store_legal_acceptance_ready(jsonb) from anon, authenticated;

create or replace function public.enforce_store_publish_readiness()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.is_published is not true then
    return new;
  end if;

  -- Migration mevcut yayınlı satırları taramaz; yayınlı→yayınlı güncellemeler
  -- yeniden yayın RPC'sindeki açık çağrı tarafından denetlenir.
  if tg_op = 'UPDATE' and old.is_published is true then
    return new;
  end if;

  perform public.assert_store_publish_ready(pg_catalog.to_jsonb(new));
  perform public.assert_store_legal_acceptance_ready(pg_catalog.to_jsonb(new));
  return new;
end;
$$;

revoke execute on function public.enforce_store_publish_readiness() from public;
revoke execute on function public.enforce_store_publish_readiness() from anon, authenticated;

create or replace function public.publish_working_draft(p_session_token text)
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
  v_cloned_from_slug text;
  v_premium_expires_at timestamptz;
  v_live_version bigint;
  v_base_live_version bigint;
  v_draft_data jsonb;
  v_guvenli jsonb := '{}'::jsonb;
  v_anahtar text;
  v_kolonlar text;
  v_mevcut jsonb;
begin
  if p_session_token is null or pg_catalog.length(pg_catalog.btrim(p_session_token)) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(pg_catalog.btrim(p_session_token)::bytea), 'hex');

  select s.store_id, st.slug, st.is_demo, st.cloned_from_slug,
         st.premium_expires_at, st.version
  into v_store_id, v_slug, v_is_demo, v_cloned_from_slug,
       v_premium_expires_at, v_live_version
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

  if v_cloned_from_slug is not null
     and (v_premium_expires_at is null or v_premium_expires_at <= now()) then
    raise exception 'PREMIUM_REQUIRED';
  end if;

  select draft_data, base_live_version
  into v_draft_data, v_base_live_version
  from public.store_working_drafts
  where store_id = v_store_id;

  if v_draft_data is null then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;
  if v_live_version is distinct from v_base_live_version then
    raise exception 'DRAFT_STALE';
  end if;

  for v_anahtar in select jsonb_object_keys(v_draft_data)
  loop
    if v_anahtar = any (public.owner_forbidden_draft_keys()) then
      continue;
    end if;
    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'stores'
        and column_name = v_anahtar
        and is_generated = 'NEVER'
        and is_updatable = 'YES'
    ) then
      continue;
    end if;
    v_guvenli := v_guvenli || jsonb_build_object(v_anahtar, v_draft_data -> v_anahtar);
  end loop;

  if v_guvenli <> '{}'::jsonb then
    select string_agg(format('%I', anahtar), ', ' order by anahtar)
    into v_kolonlar
    from jsonb_object_keys(v_guvenli) as t(anahtar);

    select to_jsonb(st) into v_mevcut from public.stores st where st.id = v_store_id;
    execute format(
      'update public.stores set (%s) = (select %s from jsonb_populate_record(null::public.stores, $1)) where id = $2',
      v_kolonlar, v_kolonlar
    ) using (v_mevcut || v_guvenli), v_store_id;
  end if;

  -- Yeniden yayında is_published zaten true olabilir; bu yüzden tetikleyiciye
  -- güvenmeden ortak core açıkça çağrılır. Hata tüm transactionı geri sarar.
  select pg_catalog.to_jsonb(st) into v_mevcut
  from public.stores st where st.id = v_store_id;
  perform public.assert_store_publish_ready(v_mevcut);
  perform public.assert_store_legal_acceptance_ready(v_mevcut);

  -- Mevcut yasal tetikleyici bu UPDATE sırasında çalışır.
  update public.stores
  set is_published = true
  where id = v_store_id;

  delete from public.store_working_drafts where store_id = v_store_id;

  select version into v_live_version from public.stores where id = v_store_id;
  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'published', true,
    'live_version', v_live_version
  );
end;
$$;

comment on function public.publish_working_draft(text) is
  'Sahip taslağını ortak hazırlık, premium ve yasal kapılardan geçirerek yayınlar. Hata transactionı geri sarar.';

grant execute on function public.publish_working_draft(text) to anon, authenticated;

notify pgrst, 'reload schema';
