-- PR1-C2: owner_flow_states — kalıcı kurulum/kiralama akış durumu
-- Problem: oluşturma/kiralama niyeti ve seçilen şablon yalnızca
-- tarayıcı belleğinde veya URL parametresinde tutuluyor; hesap
-- bağlanınca güvenle aktarılmıyor.
-- Çözüm: kullanıcıya bağlı, sürümlü, tek kaynak akış kaydı.
-- Erişim deseni: doğrudan tablo erişimi YOK (RLS açık, politika yok),
-- tüm yazma/okuma SECURITY DEFINER fonksiyonlardan (PR1-C4/C5).

create table public.owner_flow_states (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade,
  flow_type text not null check (flow_type in ('create', 'rental')),
  selected_template text,
  current_step text,
  completed_steps text[] not null default '{}',
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Hesap başına tek aktif vitrin kuralı korunuyor; tek akış kaydı.
create unique index if not exists idx_owner_flow_states_user_unique
  on public.owner_flow_states (user_id);

create index if not exists idx_owner_flow_states_store_id
  on public.owner_flow_states (store_id);

create index if not exists idx_owner_flow_states_flow_type
  on public.owner_flow_states (flow_type);

-- updated_at otomatik
create or replace function public.set_owner_flow_states_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at := now();
  new.version := coalesce(old.version, 0) + 1;
  return new;
end;
$$;

drop trigger if exists trg_owner_flow_states_updated_at on public.owner_flow_states;
create trigger trg_owner_flow_states_updated_at
  before update on public.owner_flow_states
  for each row execute function public.set_owner_flow_states_updated_at();

alter table public.owner_flow_states enable row level security;

comment on table public.owner_flow_states is
  'Tek-kaynak kurulum/kiralama akış durumu: seçilen şablon, mevcut adım ve sürüm. Doğrudan erişim kapalı; yalnız definer fonksiyonlar üzerinden.';

-- Doğrudan anon/authenticated erişimi kapat — RLS açık, politika yok
-- Eski istemciler etkilenmez; yeni fonksiyonlar eklenene kadar tablo sessiz durur.

-- Gerekirse gelecekte definer fonksiyonlara grant verilecek;
-- tabloya doğrudan grant yok.
