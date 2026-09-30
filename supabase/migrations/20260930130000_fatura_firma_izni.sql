create table if not exists public.supplier_permissions (
  id uuid primary key default gen_random_uuid(),
  supplier_key text not null,
  supplier_name text not null default '',
  scope text not null default 'data_and_images'
    check (scope in ('data', 'images', 'data_and_images')),
  status text not null default 'izin_yok'
    check (status in ('izin_yok', 'izin_verildi', 'reddedildi', 'geri_cekildi')),
  valid_until date,
  responded_at timestamptz,
  response_note text not null default '',
  verified_by text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (supplier_key, scope)
);

create table if not exists public.supplier_permission_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  job_id uuid references public.invoice_jobs(id) on delete set null,
  supplier_key text not null,
  supplier_name text not null default '',
  supplier_site text not null default '',
  scope text not null default 'data_and_images'
    check (scope in ('data', 'images', 'data_and_images')),
  requested_by text not null check (requested_by in ('owner', 'vixrex')),
  status text not null default 'hazirlandi'
    check (status in ('hazirlandi', 'gonderim_bekliyor', 'gonderildi', 'cevaplandi', 'geri_cekildi')),
  message text not null default '',
  sample_url text not null default '',
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists supplier_permission_requests_aktif_uq
  on public.supplier_permission_requests (store_id, supplier_key, scope)
  where status in ('hazirlandi', 'gonderim_bekliyor', 'gonderildi');

create table if not exists public.supplier_permission_products (
  request_id uuid not null references public.supplier_permission_requests(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  action text not null default '' check (action in ('', 'gizlendi')),
  action_at timestamptz,
  primary key (request_id, product_id)
);

alter table public.supplier_permissions enable row level security;
alter table public.supplier_permission_requests enable row level security;
alter table public.supplier_permission_products enable row level security;

revoke all on public.supplier_permissions from anon, authenticated, public;
revoke all on public.supplier_permission_requests from anon, authenticated, public;
revoke all on public.supplier_permission_products from anon, authenticated, public;

comment on table public.supplier_permissions is
  'Firmanin DOGRULANMIS veri/gorsel kullanim izni. Esnafin talebi burayi degistirmez; yalniz yonetici cevabi kaydeder.';
comment on table public.supplier_permission_requests is
  'Esnafin firma izni talebi. requested_by=vixrex olan talep, gonderilene kadar gonderim_bekliyor durumundadir; arayuz gonderilmedi iken gonderildi demez.';
