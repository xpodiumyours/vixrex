-- code-review 2026-08-10 — taslak sır sızıntısını kapatan paylaşılan fonksiyon.
--
-- SORUN: get_or_create_working_draft (Flutter'ın hâlâ çağırdığı, eski RPC)
-- taslağı ilk oluştururken to_jsonb(s) ile stores satırının TAMAMINI
-- (edit_token, user_id, yasal onay hash'leri dahil) hiç ayıklamadan
-- store_working_drafts.draft_data'ya yazıyordu.
-- get_working_draft_for_session (Next.js'in kullandığı güncel RPC) bu 5
-- alanı ayıklıyordu — ama kendi başına, tekrar tekrar yazılmış bir
-- '{edit_token,user_id,privacy_notice_hash,terms_hash,publication_consent_hash}'
-- listesiyle. İki RPC aynı mantığı KOPYALAMIŞTI; biri güncellendi, biri
-- unutuldu — açık tam da bu yüzden oluştu.
--
-- ÇÖZÜM: temizleme mantığı tek bir paylaşılan fonksiyona çıkarılıyor.
-- İkisi de artık bu tek kaynağı çağırıyor; bir daha kopyalanamaz.

create or replace function public.strip_draft_secrets(p_data jsonb)
returns jsonb
language sql
immutable
set search_path = pg_catalog
as $$
  select coalesce(p_data, '{}'::jsonb)
    - '{edit_token,user_id,privacy_notice_hash,terms_hash,publication_consent_hash}'::text[];
$$;

comment on function public.strip_draft_secrets(jsonb) is
  'Taslak jsonb''sinden kalıcı yetki/gizlilik alanlarını ayıklar. get_or_create_working_draft ve get_working_draft_for_session için tek kaynak — VIXREX_RULES.md §9, koruma sınırı 7.';

revoke execute on function public.strip_draft_secrets(jsonb) from public;
grant execute on function public.strip_draft_secrets(jsonb) to anon, authenticated;

-- 1) get_or_create_working_draft — oluşturma VE dönüş dalı artık paylaşılan
--    fonksiyonu çağırıyor. Dönüşteki çağrı "ikinci kalkan": bu düzeltmeden
--    önce oluşmuş kirli satırlar da artık temiz döner (aşağıdaki tek
--    seferlik UPDATE bu kalkanı gereksiz kılana kadar).
create or replace function public.get_or_create_working_draft(
  p_slug text,
  p_edit_token text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_store_id uuid;
  v_is_demo boolean;
  v_live_version bigint;
  v_draft_draft_version bigint;
  v_draft_base_live_version bigint;
  v_draft_data jsonb;
  v_created boolean;
  v_conflict boolean;
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;

  select id, is_demo, version
  into v_store_id, v_is_demo, v_live_version
  from public.stores
  where slug = v_slug;

  if v_store_id is null then
    raise exception 'STORE_NOT_FOUND';
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  if not (
    (
      v_user_id is not null
      and exists (
        select 1 from public.stores
        where id = v_store_id and user_id = v_user_id
      )
    )
    or (
      v_token <> ''
      and exists (
        select 1 from public.stores
        where id = v_store_id and edit_token = v_token
      )
    )
  ) then
    raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode = 'P0001';
  end if;

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
    select id, public.strip_draft_secrets(to_jsonb(s)), 1, version
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
    'draft_data', public.strip_draft_secrets(v_draft_data),
    'draft_version', v_draft_draft_version,
    'base_live_version', v_draft_base_live_version,
    'live_version', coalesce(v_live_version, 1),
    'version_conflict', v_conflict,
    'created', v_created
  );
end;
$$;

revoke execute on function public.get_or_create_working_draft(text, text) from public;
grant execute on function public.get_or_create_working_draft(text, text) to anon, authenticated;

-- 2) get_working_draft_for_session — kendi kopyasını tutmuyor artık, aynı
--    paylaşılan fonksiyonu çağırıyor. Davranış değişmiyor, kaynak tekleşiyor.
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

  if pg_catalog.length(v_token) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(v_token::bytea), 'hex');

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
    select id, public.strip_draft_secrets(to_jsonb(s)), 1, version
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
    'draft_data', public.strip_draft_secrets(v_draft_data),
    'draft_version', v_draft_draft_version,
    'base_live_version', v_draft_base_live_version,
    'live_version', coalesce(v_live_version, 1),
    'version_conflict', v_conflict,
    'created', v_created
  );
end;
$$;

revoke execute on function public.get_working_draft_for_session(text) from public;
grant execute on function public.get_working_draft_for_session(text) to anon, authenticated;

-- 3) Tek seferlik, geri dönüşlü temizleme: bu düzeltmeden ÖNCE
--    get_or_create_working_draft'ın oluşturduğu ve hâlâ 5 sırdan birini
--    taşıyan satırlar varsa temizlenir. Yıkıcı değil — yalnız bilinen
--    sırlar kaldırılır (liste strip_draft_secrets'tan gelir, burada
--    tekrar yazılmaz — code-review 2026-08-10), kullanıcının taslak
--    içeriği dokunulmaz kalır.
--    Geri dönüş: aşağıdaki yedek tablo, bu migration'dan önceki hâli
--    saklar; sorun çıkarsa
--      update public.store_working_drafts d
--      set draft_data = b.draft_data
--      from public._backup_store_working_drafts_pre_strip b
--      where b.store_id = d.store_id;
--    ile geri alınabilir.
--
-- GÜVENLİK (code-review 2026-08-10): yedek tablo TAM OLARAK kaldırmaya
-- çalıştığımız sırları taşıyor. Bu şemadaki varsayılan yetkiler yeni her
-- tabloya ALL/anon+authenticated verir (bkz. temel_sema_bulut migration'ı);
-- RLS açılmazsa yedek tablo PostgREST üzerinden herkese açılırdı — tam da
-- kapatmaya çalıştığımız sızıntıyı yeniden açmış olurduk. store_working_drafts
-- ile aynı desen: RLS açık, politika YOK, erişim yalnız SECURITY DEFINER'la.
create table if not exists public._backup_store_working_drafts_pre_strip as
select store_id, draft_data, draft_version, base_live_version, updated_at
from public.store_working_drafts
where draft_data <> public.strip_draft_secrets(draft_data);

alter table public._backup_store_working_drafts_pre_strip enable row level security;

comment on table public._backup_store_working_drafts_pre_strip is
  'strip_draft_secrets migration''ından önceki taslak yedeği — yalnız geri dönüş amaçlı. RLS açık, politika yok; anon/authenticated''e kapalı.';

update public.store_working_drafts
set draft_data = public.strip_draft_secrets(draft_data)
where draft_data <> public.strip_draft_secrets(draft_data);

notify pgrst, 'reload schema';
