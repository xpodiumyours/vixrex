-- Sahip önizleme oturumları (implementation_plan.md §5.2, Commit 3).
--
-- Kalıcı düzenleme anahtarı URL sorgusuna yazılmaz. Flutter, kısa süreli tek
-- kullanımlık sahip kodu ister; bu kod Next.js sunucu rotasında doğrulanıp
-- güvenli HttpOnly çereze dönüştürülür (Commit 4).
--
-- Yalnızca hash'lenmiş kod saklanır. Açık kod yalnızca create_owner_session
-- çağırana döndürülür ve başka hiçbir yerde tutulmaz.

create table public.owner_sessions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  code_hash text not null,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_owner_sessions_store_id
  on public.owner_sessions (store_id);
create index if not exists idx_owner_sessions_code_hash
  on public.owner_sessions (code_hash);
create index if not exists idx_owner_sessions_expires_at
  on public.owner_sessions (expires_at);

-- Doğrudan erişim kapalıdır; tüm erişim SECURITY DEFINER RPC'leri üzerindendir.
-- Mevcut public RLS politikalarına dokunulmaz.
alter table public.owner_sessions enable row level security;

comment on table public.owner_sessions is
  'Kısa süreli tek kullanımlık sahip önizleme oturumları. Yalnızca hash''lenmiş kod saklanır.';

-- Oturum oluşturur. Yalnız doğrulanmış sahip (auth.uid() = stores.user_id) veya
-- geçerli edit yetkisi (edit_token eşleşmesi) oturum açabilir. Demo/kiralık
-- şablon (is_demo = true) hiçbir koşulda düzenlenemez.
create or replace function public.create_owner_session(
  p_slug text,
  p_edit_token text default null
)
returns jsonb
language plpgsql
security definer
-- extensions şeması dahil: gen_random_bytes/sha256, pgcrypto hangi şemada
-- kuruluysa (public veya extensions) oradan çözümlenir.
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_slug text := pg_catalog.btrim(coalesce(p_slug, ''));
  v_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_store_id uuid;
  v_is_demo boolean;
  v_code text;
  v_code_hash text;
  v_expires_at timestamptz;
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;

  select id, is_demo
  into v_store_id, v_is_demo
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

  v_code := encode(gen_random_bytes(16), 'hex');
  v_code_hash := encode(sha256(v_code::bytea), 'hex');
  v_expires_at := now() + interval '15 minutes';

  insert into public.owner_sessions (store_id, user_id, code_hash, expires_at)
  values (v_store_id, v_user_id, v_code_hash, v_expires_at);

  return jsonb_build_object(
    'code', v_code,
    'expires_at', v_expires_at
  );
end;
$$;

-- Tek kullanımlık kodu atomik olarak tüketir. Eşleşme tek satırı günceller ve
-- aynı anda consumed_at işaretlenir; ikinci kullanım eşleşmez, kod reddedilir.
-- Konsum yalnız ilgili vitrin slug'ı ile eşleşen oturumda geçerlidir.
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
begin
  if v_slug = '' then
    raise exception 'INVALID_SLUG';
  end if;
  if p_code is null or pg_catalog.length(pg_catalog.btrim(p_code)) = 0 then
    raise exception 'INVALID_OWNER_CODE';
  end if;

  v_code_hash := encode(sha256(p_code::bytea), 'hex');

  update public.owner_sessions s
  set consumed_at = now()
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

  return jsonb_build_object('store_id', v_store_id, 'slug', v_slug);
end;
$$;

revoke execute on function public.create_owner_session(text, text) from public;
grant execute on function public.create_owner_session(text, text) to anon, authenticated;
revoke execute on function public.consume_owner_session(text, text) from public;
grant execute on function public.consume_owner_session(text, text) to anon, authenticated;

notify pgrst, 'reload schema';
