-- Vixrex asistanı için cihaz/IP anahtarına göre dakika başına istek sınırı.
-- Tabloya yalnız Edge Function service role ile erişir; istemci RLS ile kapalıdır.
create table if not exists public.assistant_rate_limits (
  client_key text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.assistant_rate_limits enable row level security;

create or replace function public.consume_assistant_request(
  p_client_key text,
  p_max_requests integer default 6
)
returns table(allowed boolean, retry_after_seconds integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_window_started_at timestamptz;
  v_request_count integer;
begin
  insert into public.assistant_rate_limits as limits (
    client_key,
    window_started_at,
    request_count,
    updated_at
  )
  values (p_client_key, now(), 1, now())
  on conflict (client_key) do update
  set
    window_started_at = case
      when limits.window_started_at <= now() - interval '1 minute' then now()
      else limits.window_started_at
    end,
    request_count = case
      when limits.window_started_at <= now() - interval '1 minute' then 1
      else limits.request_count + 1
    end,
    updated_at = now()
  returning window_started_at, request_count
  into v_window_started_at, v_request_count;

  return query select
    v_request_count <= p_max_requests,
    greatest(
      0,
      ceil(extract(epoch from (v_window_started_at + interval '1 minute' - now())))::integer
    );
end;
$$;

revoke all on function public.consume_assistant_request(text, integer) from public;
grant execute on function public.consume_assistant_request(text, integer) to service_role;
