begin;

create table if not exists public.invoice_job_events (
  id bigint generated always as identity primary key,
  job_id uuid not null references public.invoice_jobs(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  stage text not null check (stage in ('reading','cards','save')),
  attempt smallint not null check (attempt between 1 and 10),
  from_state text,
  to_state text,
  reason_code text,
  error_class text not null check (error_class in ('none','transient','permanent')),
  http_status integer check (http_status is null or http_status between 100 and 599),
  retry_after_ms integer check (retry_after_ms is null or retry_after_ms between 0 and 3600000),
  duration_ms integer check (duration_ms is null or duration_ms >= 0),
  model text,
  response_bytes integer check (response_bytes is null or response_bytes >= 0),
  body_sha256 text check (body_sha256 is null or body_sha256 ~ '^[0-9a-f]{64}$'),
  actor text not null default 'worker' check (actor in ('worker','owner','cron','admin')),
  created_at timestamptz not null default now()
);

create index if not exists invoice_job_events_job_idx
  on public.invoice_job_events (job_id, created_at desc);

create index if not exists invoice_job_events_store_idx
  on public.invoice_job_events (store_id, created_at desc);

alter table public.invoice_job_events enable row level security;
revoke all on table public.invoice_job_events from public, anon, authenticated, service_role;
grant select, insert on table public.invoice_job_events to service_role;

alter table public.invoice_provider_runs
  add column if not exists attempt_count smallint not null default 0,
  add column if not exists next_attempt_at timestamptz,
  add column if not exists response_sha256 text;

alter table public.invoice_provider_runs drop constraint if exists invoice_provider_runs_attempt_count_check;
alter table public.invoice_provider_runs
  add constraint invoice_provider_runs_attempt_count_check check (attempt_count between 0 and 10);

alter table public.invoice_provider_runs drop constraint if exists invoice_provider_runs_response_sha256_check;
alter table public.invoice_provider_runs
  add constraint invoice_provider_runs_response_sha256_check
  check (response_sha256 is null or response_sha256 ~ '^[0-9a-f]{64}$');

create index if not exists invoice_provider_runs_retry_idx
  on public.invoice_provider_runs (next_attempt_at)
  where state = 'queued' and next_attempt_at is not null;

create or replace function public.invoice_error_class(p_http integer, p_code text)
returns text
language sql
immutable
set search_path = pg_catalog, public
as $$
  select case
    when p_code in (
      'KART_YANITI_COZULEMEDI',
      'KART_SATIRLARI_ESLESMEDI',
      'KART_KAPSAMI_EKSIK',
      'FOTOGRAFTA_YAZI_YOK',
      'PRESET_GECERSIZ'
    ) then 'permanent'
    when p_http is null then 'transient'
    when p_http in (408, 409, 425, 429) then 'transient'
    when p_http >= 500 then 'transient'
    else 'permanent'
  end
$$;

create or replace function public.invoice_backoff_ms(
  p_attempt integer,
  p_class text,
  p_retry_after_ms integer default null
)
returns integer
language sql
volatile
set search_path = pg_catalog, public
as $$
  select case
    when coalesce(p_class, 'permanent') <> 'transient' then 0
    else least(
      60000,
      greatest(
        floor(random() * least(20000, 2000 * power(2, greatest(p_attempt, 1) - 1)))::integer,
        coalesce(p_retry_after_ms, 0)
      )
    )
  end
$$;

create or replace function public.record_invoice_job_event(
  p_job_id uuid,
  p_store_id uuid,
  p_stage text,
  p_attempt smallint,
  p_from_state text default null,
  p_to_state text default null,
  p_reason_code text default null,
  p_error_class text default 'none',
  p_http_status integer default null,
  p_retry_after_ms integer default null,
  p_duration_ms integer default null,
  p_model text default null,
  p_response_bytes integer default null,
  p_body_sha256 text default null,
  p_actor text default 'worker'
)
returns bigint
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_id bigint;
begin
  if not exists (
    select 1 from public.invoice_jobs where id = p_job_id and store_id = p_store_id
  ) then
    raise exception 'fatura isi bulunamadi';
  end if;

  insert into public.invoice_job_events (
    job_id, store_id, stage, attempt, from_state, to_state, reason_code, error_class,
    http_status, retry_after_ms, duration_ms, model, response_bytes, body_sha256, actor
  ) values (
    p_job_id, p_store_id, p_stage, p_attempt, p_from_state, p_to_state, p_reason_code, p_error_class,
    p_http_status, p_retry_after_ms, p_duration_ms, p_model, p_response_bytes, p_body_sha256, p_actor
  ) returning id into v_id;

  return v_id;
end $$;

revoke all on function public.record_invoice_job_event(
  uuid, uuid, text, smallint, text, text, text, text,
  integer, integer, integer, text, integer, text, text
) from public, anon, authenticated;
grant execute on function public.record_invoice_job_event(
  uuid, uuid, text, smallint, text, text, text, text,
  integer, integer, integer, text, integer, text, text
) to service_role;

revoke all on function public.invoice_error_class(integer, text) from public, anon, authenticated;
grant execute on function public.invoice_error_class(integer, text) to service_role;

revoke all on function public.invoice_backoff_ms(integer, text, integer) from public, anon, authenticated;
grant execute on function public.invoice_backoff_ms(integer, text, integer) to service_role;

create or replace function public.get_invoice_provider_response(p_store_id uuid,p_job_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_result jsonb;
begin
  if not exists(select 1 from public.invoice_jobs where id=p_job_id and store_id=p_store_id) then return null; end if;
  perform public.sync_invoice_provider_responses();
  select jsonb_build_object(
    'state',r.state,'stage',r.stage,'httpStatus',r.http_status,'contentType',r.content_type,
    'body',r.response_body,'readResult',r.read_result,'error',r.error_code,'fingerprint',j.document_fingerprint,
    'attempts',r.attempt_count,'nextAttemptAt',r.next_attempt_at
  ) into v_result from public.invoice_provider_runs r
    join public.invoice_jobs j on j.id=r.job_id and j.store_id=r.store_id
    where r.job_id=p_job_id and r.store_id=p_store_id;
  return v_result;
end;
$$;
alter function public.get_invoice_provider_response(uuid,uuid) owner to postgres;
revoke all on function public.get_invoice_provider_response(uuid,uuid) from public,anon,authenticated;
grant execute on function public.get_invoice_provider_response(uuid,uuid) to service_role;

create or replace function public.retry_invoice_provider_job(
  p_store_id uuid,
  p_job_id uuid,
  p_body jsonb,
  p_api_key text
) returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_run public.invoice_provider_runs%rowtype;
  v_request_id bigint;
begin
  if p_body is null
    or jsonb_typeof(p_body) is distinct from 'object'
    or coalesce(p_api_key,'') = ''
  then
    return jsonb_build_object('success',false,'reason','invalid');
  end if;

  select * into v_run from public.invoice_provider_runs
    where job_id=p_job_id and store_id=p_store_id
    for update;

  if not found or v_run.state <> 'failed' or v_run.stage <> 'cards' then
    return jsonb_build_object('success',false,'reason','state');
  end if;

  if v_run.attempt_count >= 2 then
    return jsonb_build_object('success',false,'reason','limit');
  end if;

  if public.invoice_error_class(v_run.http_status, v_run.error_code) <> 'transient' then
    return jsonb_build_object('success',false,'reason','permanent');
  end if;

  v_request_id := net.http_post(
    url := 'https://openrouter.ai/api/v1/chat/completions',
    body := p_body,
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'Authorization','Bearer '||p_api_key,
      'HTTP-Referer','https://vixrex.com',
      'X-Title','Vixrex Invoice Product Cards'
    ),
    timeout_milliseconds := 1800000
  );

  update public.invoice_provider_runs
    set state='queued', request_id=v_request_id, attempt_count=v_run.attempt_count+1,
        error_code=null, http_status=null, content_type=null, response_body=null,
        finished_at=null, next_attempt_at=null
    where job_id=p_job_id and store_id=p_store_id;

  return jsonb_build_object('success',true,'id',p_job_id,'stage','cards','state','queued','attempt',v_run.attempt_count+1);
end;
$$;
alter function public.retry_invoice_provider_job(uuid,uuid,jsonb,text) owner to postgres;
revoke all on function public.retry_invoice_provider_job(uuid,uuid,jsonb,text) from public,anon,authenticated;
grant execute on function public.retry_invoice_provider_job(uuid,uuid,jsonb,text) to service_role;

notify pgrst, 'reload schema';

commit;
