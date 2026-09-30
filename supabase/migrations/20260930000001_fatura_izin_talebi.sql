-- Fatura firma izin talebi: hazır kart üzerinden esnafın seçimi ve firma cevabı.
-- "Ben isteyeceğim" esnafın sorumluluğudur; "VixRex istesin" takip edilebilir görevdir.
-- Esnafın talebi firma onayı yerine geçmez.
create table if not exists public.invoice_permission_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  job_id uuid references public.invoice_jobs(id) on delete set null,
  firma text not null default '',
  kapsam text not null default '',
  ornek_urun_id uuid references public.products(id) on delete set null,
  sorumlu text not null check (sorumlu in ('esnaf', 'vixrex')),
  durum text not null default 'hazir'
    check (durum in ('hazir', 'gonderildi', 'cevap_bekliyor', 'izin_var', 'reddedildi')),
  gonderildi_at timestamptz,
  cevap_at timestamptz,
  cevap_notu text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists invoice_permission_requests_store_idx
  on public.invoice_permission_requests (store_id);
create index if not exists invoice_permission_requests_job_idx
  on public.invoice_permission_requests (job_id);

comment on table public.invoice_permission_requests is
  'Hazir kart uzerinden firma veri/gorsel izin talebi. Talep ile firma onayi ayridir.';

alter table public.invoice_permission_requests enable row level security;
revoke all on public.invoice_permission_requests from anon;
revoke all on public.invoice_permission_requests from authenticated;
revoke all on public.invoice_permission_requests from public;
