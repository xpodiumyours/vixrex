-- Commit 6: yayınlanmış vitrin çalışma taslağı (implementation_plan.md §5.3).
--
-- Canlı kayıt (stores.is_published = true) ile sahibin üzerinde çalıştığı
-- taslak ayrıştırılır. Taslağa yalnız get_or_create_working_draft RPC'si
-- üzerinden, edit_token (veya auth.uid()) yetkisiyle erişilir. Müşteri
-- sorguları (public select, get_store_preview) taslağa asla erişemez.
--
-- Güvenlik: owner_sessions deseniyle aynı. Tabloda RLS açık ve politika yok;
-- doğrudan SELECT anon/authenticated'e kapalı, tüm erişim SECURITY DEFINER
-- fonksiyonundan geçer.

-- 1) Canlı kayıt sürümü: stores satırı her güncellendiğinde artar.
--    Yayın sırasında canlı veri değiştiyse taslak sürüm çakışması algılanır.
alter table public.stores add column if not exists version bigint not null default 1;

comment on column public.stores.version is
  'Canlı kayıt sürümü. Her güncellemede artar; çalışma taslağının hangi canlı sürümden üretildiğini izler.';

create or replace function public.bump_store_version()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.version := coalesce(old.version, 0) + 1;
  return new;
end;
$$;

drop trigger if exists trg_stores_bump_version on public.stores;
create trigger trg_stores_bump_version
  before update on public.stores
  for each row execute function public.bump_store_version();

-- 2) Çalışma taslağı: canlı kayıttan ayrı, sahibin yayınlanmamış değişiklikleri.
create table public.store_working_drafts (
  store_id uuid primary key references public.stores(id) on delete cascade,
  draft_data jsonb not null,
  draft_version bigint not null default 1,
  base_live_version bigint not null,
  updated_at timestamptz not null default now()
);

alter table public.store_working_drafts enable row level security;

comment on table public.store_working_drafts is
  'Yayınlanmış vitrinin sahip çalışma taslağı. Yalnız get_or_create_working_draft RPC''si üzerinden erişilir.';

-- 3) Taslak oluştur/oku. İlk açılışta canlı veriden üretir; sonraki açılışlarda
--    mevcut taslağı korur. Canlı kayıt taslaktan ileri güncellendiyse
--    version_conflict = true döner (sessiz ezme yok).
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
    select id, to_jsonb(s), 1, version
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
    'draft_data', coalesce(v_draft_data, '{}'::jsonb),
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

notify pgrst, 'reload schema';
