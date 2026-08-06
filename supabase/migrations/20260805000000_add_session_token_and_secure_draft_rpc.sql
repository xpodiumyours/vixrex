-- Commit 7: owner_sessions güvenli zinciri — session_token_hash
--
-- 1) owner_sessions'a session_token_hash kolonu ekle (düz metin YOK)
alter table public.owner_sessions
add column if not exists session_token_hash text;

-- Üretilmiş her session_token_hash benzersiz olmalı.
--
-- NOT: koşula `expires_at > now()` KONULAMAZ. PostgreSQL indeks koşulunda
-- IMMUTABLE olmayan fonksiyona izin vermez; `now()` zamana bağlı olduğu için
-- indeks zamanla geçersizleşirdi. İlk yazımda bu hata vardı ve migration
-- "functions in index predicate must be marked IMMUTABLE" ile hiç uygulanamadı.
--
-- Süre kontrolü zaten sorgu tarafında yapılıyor (get_working_draft_for_session
-- içinde `expires_at > now()`), indeksin görevi yalnız benzersizlik.
create unique index if not exists uq_owner_sessions_session_token_hash
  on public.owner_sessions (session_token_hash)
  where session_token_hash is not null;

comment on column public.owner_sessions.session_token_hash is
  'SHA-256(session_token). Açık token veritabanında ASLA saklanmaz.';

-- 2) consume_owner_session: kod tüket, session_token üret, hashle, sakla, açık tokenı döndür
create or replace function public.consume_owner_session(
  p_slug text,
  p_code text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_code_hash text;
  v_store_id uuid;
  v_session_token text;
  v_session_token_hash text;
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;
  if p_code is null or pg_catalog.length(pg_catalog.btrim(p_code)) = 0 then
    raise exception 'INVALID_OWNER_CODE';
  end if;

  v_code_hash := encode(sha256(p_code::bytea), 'hex');

  -- 32 byte (256 bit) rastgele session_token üret
  v_session_token := encode(gen_random_bytes(32), 'hex');
  v_session_token_hash := encode(sha256(v_session_token::bytea), 'hex');

  update public.owner_sessions s
  set consumed_at = now(),
      session_token_hash = v_session_token_hash
  where s.code_hash = v_code_hash
    and s.consumed_at is null
    and s.expires_at > now()
    and exists (
      select 1 from public.stores st
      where st.id = s.store_id and st.slug = v_slug
    )
  returning s.store_id into v_store_id;

  if v_store_id is null then
    raise exception 'INVALID_OR_EXPIRED_OWNER_CODE' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'store_id', v_store_id,
    'slug', v_slug,
    'session_token', v_session_token
  );
end;
$$;

-- 3) get_working_draft_for_session: açık tokenı hashle, hash ile owner_sessions kaydı bul
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
  v_draft_draft_version bigint;
  v_draft_base_live_version bigint;
  v_draft_data jsonb;
  v_created boolean;
  v_conflict boolean;
begin
  if v_token = '' then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  -- token 64 hex char (32 byte) olmalı
  if pg_catalog.length(v_token) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(v_token::bytea), 'hex');

  -- hash ile owner_sessions kaydı bul
  select s.store_id, st.slug, st.is_demo, st.version
  into v_store_id, v_slug, v_is_demo, v_live_version
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

  -- Taslak getir veya oluştur
  select draft_version, base_live_version, draft_data
  into v_draft_draft_version, v_draft_base_live_version, v_draft_data
  from public.store_working_drafts
  where store_id = v_store_id;

  v_created := false;
  v_conflict := false;

  if v_draft_draft_version is null then
    insert into public.store_working_drafts (
      store_id, draft_data, draft_version, base_live_version
    )
    -- GİZLİ ALANLAR TASLAĞA GİRMEZ.
    -- to_jsonb(s) mağaza satırının TAMAMINI kopyalar; içinde edit_token de
    -- vardır. Taslak sahip paneline prop olarak gittiği için bu doğrudan
    -- tarayıcıya sızardı. edit_token kalıcı bir yetki anahtarıdır — onunla
    -- vitrin düzenlenebilir. Koruma sınırı 7 (implementation_plan.md §3).
    select id, to_jsonb(s) - '{edit_token,user_id,privacy_notice_hash,terms_hash,publication_consent_hash}'::text[], 1, version
    from public.stores s
    where id = v_store_id;

    v_draft_draft_version := 1;
    v_draft_base_live_version := v_live_version;

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
    -- İkinci kalkan: bu düzeltmeden ÖNCE oluşmuş taslaklarda edit_token
    -- kayıtlı olabilir. Dönerken de silinir; eski kayıtlar da güvenli olur.
    'draft_data', coalesce(v_draft_data, '{}'::jsonb)
                  - '{edit_token,user_id,privacy_notice_hash,terms_hash,publication_consent_hash}'::text[],
    'draft_version', v_draft_draft_version,
    'base_live_version', v_draft_base_live_version,
    'live_version', coalesce(v_live_version, 1),
    'version_conflict', v_conflict,
    'created', v_created
  );
end;
$$;

-- Eski güvensiz RPC'yi kaldır
drop function if exists public.get_working_draft_for_owner_session(uuid, text);

-- session_token düz metin kolonunu ve indeksini kaldır (varsa)
alter table public.owner_sessions drop column if exists session_token;
drop index if exists idx_owner_sessions_session_token;

-- RPC anon Next.js istemcisiyle çağrılacak — anon grant gerekli
revoke execute on function public.get_working_draft_for_session(text) from public;
grant execute on function public.get_working_draft_for_session(text) to anon, authenticated;

notify pgrst, 'reload schema';