create table if not exists public.meta_data_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  provider text not null default 'instagram',
  provider_user_id text,
  store_slug text,
  status text not null default 'received'
    check (status in ('received', 'processing', 'completed', 'failed')),
  confirmation_code text not null unique,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  error_message text
);

alter table public.meta_data_deletion_requests enable row level security;

grant all on table public.meta_data_deletion_requests to service_role;
