-- ============================================================================
-- Premium yayın kapısı (PR #3) — "Kiralık Vitrin = Premium"
-- ============================================================================
-- NEDEN VAR
-- İş modeli (2026-08-17, Casper): sıfırdan kendi vitrinini kuran esnaf
-- ÜCRETSİZ yayınlar; şablon kiralayan (cloned_from_slug dolu) esnaf ise
-- yalnız AKTİF PREMIUM ile yayınlar. Bu kapı VERİTABANINDA olmalı:
-- UI atlansa bile istemci premium'suz kiralık vitrin yayınlayamaz.
--
-- ORGANİK VİTRİNLER ETKİLENMEZ: kontrol yalnız cloned_from_slug dolu
-- satırlara uygulanır. Sıfırdan kurulan vitrinlerde cloned_from_slug
-- her zaman null'dur → premium şartı hiç devreye girmez.
--
-- ACTIVE PREMIUM TANIMI: premium_expires_at dolu VE gelecekte.
--   null                       → hiç premium almamış → YAYINLANAMAZ
--   geçmişte                   → süre bitmiş → YAYINLANAMAZ
--   gelecekte                  → aktif → YAYINLANABİLİR
-- (PR #2'deki demote_expired_premium_stores süresi dolalı 3 GÜN olmuş
--  vitrinleri zaten taslağa döndürür; bu kapı o 3 günlük pencerede de
--  çalışır — süre bitmiş bir kiralık vitrin 3 gün içinde bile YENİDEN
--  yayınlanamaz.)
--
-- NOT: Uygulanmış migration değiştirilmez (VIXREX_RULES §9) —
-- publish_working_draft create or replace ile GÜNCELLENİR; oturum,
-- taslak, çakışma ve yasal kontrol mantığı BİREBİR korunur, yalnız
-- premium kontrolü eklenir.
-- ============================================================================

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
  -- 1) Oturum doğrulaması — update_working_draft_field ile birebir aynı.
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

  -- 1.5) PREMIUM KAPISI — kiralık vitrin yalnız aktif premium ile yayınlanır.
  -- Organik vitrinlerde cloned_from_slug null'dur → bu kontrol atlanır.
  if v_cloned_from_slug is not null
     and (v_premium_expires_at is null or v_premium_expires_at <= now()) then
    raise exception 'PREMIUM_REQUIRED';
  end if;

  -- 2) Taslağı al.
  select draft_data, base_live_version
  into v_draft_data, v_base_live_version
  from public.store_working_drafts
  where store_id = v_store_id;

  if v_draft_data is null then
    raise exception 'WORKING_DRAFT_NOT_FOUND';
  end if;

  -- 3) Çakışma kontrolü.
  if v_live_version is distinct from v_base_live_version then
    raise exception 'DRAFT_STALE';
  end if;

  -- 4) Yalnız yazılabilir sütunları süz.
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

  -- 5) Canlı satıra uygula.
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

  -- 6) Yayına al. Yasal tetikleyici burada devreye girer.
  update public.stores
  set is_published = true
  where id = v_store_id;

  -- 7) Taslağı kaldır.
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

comment on function public.publish_working_draft is
  'Sahip çalışma taslağını canlı vitrine yayınlar. Kiralık vitrinler
   (cloned_from_slug dolu) yalnız AKTİF premium ile yayınlanabilir
   (PREMIUM_REQUIRED); organik vitrinler etkilenmez. Yasal onay kontrolü
   stores tetikleyicisindedir; başarısızlıkta işlem geri sarar ve taslak
   korunur.';

-- Disiplin: grant satırı yok ≠ kapalı değildir. create or replace yetkileri
-- korur, ama bu fonksiyon anon/authenticated'e AÇIK olmalı (sahip paneli
-- /api/owner-publish üzerinden anon rolüyle çağırır) — mevcut grant'ı
-- doğrulayıcı olarak yine de açıkça koyarız; istemci RPC'yi doğrudan
-- çağırsa bile PREMIUM_REQUIRED kapısı içeridedir.
grant execute on function public.publish_working_draft(text) to anon, authenticated;
