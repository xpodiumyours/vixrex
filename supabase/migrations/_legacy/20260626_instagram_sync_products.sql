-- Instagram + Google ürün SEO akışı için güvenli bağlantı tabloları.
-- Token tablosu public schema altında olsa da RLS açık ve client rolleri için kapalıdır.

create table if not exists public.store_instagram_connections (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null references public.stores(slug) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  instagram_user_id text,
  username text,
  account_type text,
  scopes text[] not null default '{}'::text[],
  status text not null default 'pending'
    check (status in ('pending', 'connected', 'disconnected', 'failed')),
  state_nonce text,
  edit_token_hash text,
  connected_at timestamptz,
  last_sync_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint unique_store_instagram_connection unique (store_slug)
);

create index if not exists idx_store_instagram_connections_store
  on public.store_instagram_connections (store_slug);

create index if not exists idx_store_instagram_connections_user
  on public.store_instagram_connections (user_id);

create index if not exists idx_store_instagram_connections_state_nonce
  on public.store_instagram_connections (state_nonce)
  where state_nonce is not null;

create table if not exists public.store_instagram_tokens (
  connection_id uuid primary key
    references public.store_instagram_connections(id) on delete cascade,
  access_token_ciphertext text not null,
  token_type text not null default 'bearer',
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_instagram_imports (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null references public.stores(slug) on delete cascade,
  connection_id uuid references public.store_instagram_connections(id) on delete set null,
  source_media_id text not null,
  source_permalink text,
  product_slug text not null,
  status text not null default 'imported'
    check (status in ('imported', 'updated', 'failed')),
  error_message text,
  imported_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint unique_store_instagram_import unique (store_slug, source_media_id)
);

create index if not exists idx_store_instagram_imports_store
  on public.store_instagram_imports (store_slug, imported_at desc);

alter table public.store_instagram_connections enable row level security;
alter table public.store_instagram_tokens enable row level security;
alter table public.store_instagram_imports enable row level security;

create or replace function public.set_store_instagram_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$$;

revoke all on function public.set_store_instagram_updated_at()
  from public, anon, authenticated;
grant execute on function public.set_store_instagram_updated_at()
  to service_role;

drop trigger if exists trg_store_instagram_connections_updated_at
  on public.store_instagram_connections;
create trigger trg_store_instagram_connections_updated_at
before update on public.store_instagram_connections
for each row execute function public.set_store_instagram_updated_at();

drop trigger if exists trg_store_instagram_tokens_updated_at
  on public.store_instagram_tokens;
create trigger trg_store_instagram_tokens_updated_at
before update on public.store_instagram_tokens
for each row execute function public.set_store_instagram_updated_at();

drop trigger if exists trg_store_instagram_imports_updated_at
  on public.store_instagram_imports;
create trigger trg_store_instagram_imports_updated_at
before update on public.store_instagram_imports
for each row execute function public.set_store_instagram_updated_at();

drop policy if exists "Owners can read own Instagram connection"
  on public.store_instagram_connections;
create policy "Owners can read own Instagram connection"
on public.store_instagram_connections
for select
to authenticated
using (
  exists (
    select 1
    from public.stores
    where stores.slug = store_instagram_connections.store_slug
      and stores.user_id = (select auth.uid())
  )
);

drop policy if exists "Owners can read own Instagram imports"
  on public.store_instagram_imports;
create policy "Owners can read own Instagram imports"
on public.store_instagram_imports
for select
to authenticated
using (
  exists (
    select 1
    from public.stores
    where stores.slug = store_instagram_imports.store_slug
      and stores.user_id = (select auth.uid())
  )
);

-- Token tablosu yalnızca service role tarafından kullanılacak.
revoke all on table public.store_instagram_tokens from anon, authenticated;

grant select, insert, update, delete
  on table public.store_instagram_connections
  to service_role;
grant select, insert, update, delete
  on table public.store_instagram_tokens
  to service_role;
grant select, insert, update, delete
  on table public.store_instagram_imports
  to service_role;

grant select on table public.store_instagram_connections to authenticated;
grant select on table public.store_instagram_imports to authenticated;
