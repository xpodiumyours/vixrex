begin;

alter table public.invoice_provider_runs
  add column if not exists stage text not null default 'reading',
  add column if not exists read_result jsonb;

alter table public.invoice_provider_runs
  drop constraint if exists invoice_provider_runs_stage_check;
alter table public.invoice_provider_runs
  add constraint invoice_provider_runs_stage_check check (stage in ('reading','cards'));

create or replace function public.advance_invoice_provider_job(
  p_store_id uuid,
  p_job_id uuid,
  p_read_result jsonb,
  p_body jsonb,
  p_api_key text
) returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_run public.invoice_provider_runs%rowtype;
  v_request_id bigint;
begin
  if p_read_result is null
    or jsonb_typeof(p_read_result) is distinct from 'object'
    or p_body is null
    or jsonb_typeof(p_body) is distinct from 'object'
    or coalesce(p_body->>'model','') <> '@preset/vixrex-fatura-otomatik-kart'
    or (p_body->>'stream') is distinct from 'true'
    or octet_length(p_body::text) > 8388608
    or p_api_key is null or length(p_api_key) < 8 or length(p_api_key) > 4096
    or p_api_key ~ E'[\\r\\n]'
  then raise exception 'FATURA_KART_GIRDISI_GECERSIZ'; end if;

  select * into v_run
    from public.invoice_provider_runs
    where job_id=p_job_id and store_id=p_store_id
    for update;
  if not found then raise exception 'FATURA_ISLEMI_BULUNAMADI'; end if;

  -- Aynı GET iki kez gelirse ikinci ücretli çağrı yapılmaz.
  if v_run.stage <> 'reading' or v_run.state <> 'received' then
    return jsonb_build_object('success',true,'id',p_job_id,'stage',v_run.stage,'state',v_run.state);
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
    set stage='cards', state='queued', request_id=v_request_id,
        read_result=p_read_result, response_body=null, http_status=null,
        content_type=null, error_code=null, finished_at=null
    where job_id=p_job_id and store_id=p_store_id;

  return jsonb_build_object('success',true,'id',p_job_id,'stage','cards','state','queued');
end;
$$;
alter function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) owner to postgres;
revoke execute on function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) from public,anon,authenticated;
grant execute on function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) to service_role;

create or replace function public.get_invoice_provider_response(p_store_id uuid,p_job_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_result jsonb;
begin
  if not exists(select 1 from public.invoice_jobs where id=p_job_id and store_id=p_store_id) then return null; end if;
  perform public.sync_invoice_provider_responses();
  select jsonb_build_object(
    'state',r.state,'stage',r.stage,'httpStatus',r.http_status,'contentType',r.content_type,
    'body',r.response_body,'readResult',r.read_result,'error',r.error_code,'fingerprint',j.document_fingerprint
  ) into v_result from public.invoice_provider_runs r
    join public.invoice_jobs j on j.id=r.job_id and j.store_id=r.store_id
    where r.job_id=p_job_id and r.store_id=p_store_id;
  return v_result;
end;
$$;
alter function public.get_invoice_provider_response(uuid,uuid) owner to postgres;
revoke execute on function public.get_invoice_provider_response(uuid,uuid) from public,anon,authenticated;
grant execute on function public.get_invoice_provider_response(uuid,uuid) to service_role;

notify pgrst, 'reload schema';
commit;
