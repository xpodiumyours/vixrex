begin;
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
    or coalesce(p_body->>'model','') not in ('@preset/urun-kart-olusturucu','@preset/vixrex-urun-karti-resmi-v1')
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
        content_type=null, error_code=null, created_at=now(), finished_at=null, callback_sent_at=null
    where job_id=p_job_id and store_id=p_store_id;

  return jsonb_build_object('success',true,'id',p_job_id,'stage','cards','state','queued');
end;
$$;
alter function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) owner to postgres;
revoke execute on function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) from public,anon,authenticated;
grant execute on function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) to service_role;

create or replace function public.enqueue_invoice_provider_job(
  p_store_id uuid,p_fingerprint text,p_body jsonb,p_api_key text
) returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_job public.invoice_jobs%rowtype;
  v_run public.invoice_provider_runs%rowtype;
  v_request_id bigint;
begin
  if not exists(select 1 from public.stores where id=p_store_id)
    or p_fingerprint is null or p_fingerprint !~ '^[0-9a-f]{64}$'
    or jsonb_typeof(p_body) is distinct from 'object'
    or coalesce(p_body->>'model','') not in ('@preset/vixrex-qwen-fatura-okuma-suzme','@preset/vixrex-fatura-otomatik-kart','@preset/vixrex-fatura-okuma-metin-v1')
    or (p_body->>'stream') is distinct from 'true'
    or octet_length(p_body::text)>8388608
    or p_api_key is null or length(p_api_key)<8 or length(p_api_key)>4096
    or p_api_key ~ E'[\r\n]'
  then raise exception 'FATURA_ISLEYICI_GIRDISI_GECERSIZ'; end if;

  perform pg_advisory_xact_lock(hashtextextended(p_store_id::text||':'||p_fingerprint,0));
  insert into public.invoice_jobs(store_id,document_fingerprint,status,ingest_complete)
    values(p_store_id,p_fingerprint,'eslestirme',false)
    on conflict(store_id,document_fingerprint) do nothing;
  select * into v_job from public.invoice_jobs
    where store_id=p_store_id and document_fingerprint=p_fingerprint for update;
  if v_job.ingest_complete then
    return jsonb_build_object('success',true,'id',v_job.id,'state','processed');
  end if;
  select * into v_run from public.invoice_provider_runs where job_id=v_job.id;
  if v_run.job_id is not null and v_run.state <> 'failed' then
    return jsonb_build_object('success',true,'id',v_job.id,'state',v_run.state);
  end if;

  v_request_id := net.http_post(
    url := 'https://openrouter.ai/api/v1/chat/completions',
    body := p_body,
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'Authorization','Bearer '||p_api_key,
      'HTTP-Referer','https://vixrex.com',
      'X-Title','Vixrex Invoice Worker'
    ),
    timeout_milliseconds := 1800000
  );
  if v_run.job_id is not null then
    update public.invoice_provider_runs set request_id=v_request_id, state='queued',
      stage='reading',read_result=null,response_body=null,http_status=null,
      content_type=null,error_code=null,created_at=now(),finished_at=null,callback_sent_at=null
      where job_id=v_job.id and store_id=p_store_id and state='failed';
  else
    insert into public.invoice_provider_runs(job_id,store_id,request_id,state)
      values(v_job.id,p_store_id,v_request_id,'queued');
  end if;
  return jsonb_build_object('success',true,'id',v_job.id,'state','queued');
end;
$$;
alter function public.enqueue_invoice_provider_job(uuid,text,jsonb,text) owner to postgres;
revoke execute on function public.enqueue_invoice_provider_job(uuid,text,jsonb,text) from public,anon,authenticated;
grant execute on function public.enqueue_invoice_provider_job(uuid,text,jsonb,text) to service_role;

notify pgrst, 'reload schema';
commit;
