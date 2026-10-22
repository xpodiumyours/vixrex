begin;

alter table public.invoice_provider_runs
  add column stage text not null default 'legacy' check (stage in ('legacy','reading','cards')),
  add column read_result jsonb,
  add column read_receipt jsonb,
  add column stage_started_at timestamptz not null default now();

update public.invoice_provider_runs set stage_started_at=created_at;

create or replace function public.enqueue_invoice_preset_chain(
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
    or coalesce(p_body->>'model','') <> '@preset/vixrex-qwen-fatura-okuma-suzme'
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
  if found then
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
  insert into public.invoice_provider_runs(job_id,store_id,request_id,state,stage)
    values(v_job.id,p_store_id,v_request_id,'queued','reading');
  return jsonb_build_object('success',true,'id',v_job.id,'state','queued');
end;
$$;

create or replace function public.advance_invoice_provider_job(
  p_store_id uuid,p_job_id uuid,p_expected_request_id bigint,p_read_result jsonb,p_body jsonb,p_api_key text
) returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_job public.invoice_jobs%rowtype;
  v_run public.invoice_provider_runs%rowtype;
  v_request_id bigint;
begin
  if jsonb_typeof(p_read_result->'satirlar') is distinct from 'array'
    or jsonb_array_length(p_read_result->'satirlar')=0
    or jsonb_typeof(p_body) is distinct from 'object'
    or coalesce(p_body->>'model','') <> '@preset/urun-kart-olusturucu'
    or (p_body->>'stream') is distinct from 'true'
    or octet_length(p_body::text)>8388608
    or octet_length(p_read_result::text)>8388608
    or p_api_key is null or length(p_api_key)<8 or length(p_api_key)>4096
    or p_api_key ~ E'[\r\n]'
  then raise exception 'FATURA_ISLEYICI_GIRDISI_GECERSIZ'; end if;
  select * into v_job from public.invoice_jobs where id=p_job_id and store_id=p_store_id;
  if not found then raise exception 'FATURA_ISLEM_ESLESMEDI'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_store_id::text||':'||v_job.document_fingerprint,0));
  select * into v_job from public.invoice_jobs where id=p_job_id and store_id=p_store_id for update;
  select * into v_run from public.invoice_provider_runs where job_id=p_job_id and store_id=p_store_id for update;
  if not found then raise exception 'FATURA_ISLEM_ESLESMEDI'; end if;
  if v_run.stage='cards' then
    return jsonb_build_object('success',true,'id',p_job_id,'state',v_run.state);
  end if;
  if v_run.stage<>'reading' or v_run.state<>'received' or v_run.request_id is distinct from p_expected_request_id
    then raise exception 'FATURA_GERCEK_YANITI_HAZIR_DEGIL'; end if;
  v_request_id:=net.http_post(
    url:='https://openrouter.ai/api/v1/chat/completions',body:=p_body,
    headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||p_api_key,
      'HTTP-Referer','https://vixrex.com','X-Title','Vixrex Invoice Cards'),
    timeout_milliseconds:=1800000
  );
  update public.invoice_provider_runs set
    read_result=p_read_result,
    read_receipt=jsonb_build_object('requestId',request_id,'httpStatus',http_status,'contentType',content_type,'body',response_body),
    stage='cards',state='queued',request_id=v_request_id,stage_started_at=now(),
    http_status=null,content_type=null,response_body=null,error_code=null,finished_at=null
    where job_id=p_job_id and store_id=p_store_id;
  return jsonb_build_object('success',true,'id',p_job_id,'state','queued');
end;
$$;

create or replace function public.sync_invoice_provider_responses()
returns void language plpgsql security definer set search_path=pg_catalog,public
as $$
begin
  update public.invoice_provider_runs r
    set http_status=h.status_code,content_type=h.content_type,response_body=h.content,
      state=case when coalesce(h.timed_out,false) or h.error_msg is not null then 'failed' else 'received' end,
      error_code=case when coalesce(h.timed_out,false) then 'OKUYUCU_ZAMAN_ASIMI'
                      when h.error_msg is not null then 'OKUYUCU_CEVAP_VERMEDI' else null end,
      finished_at=now()
    from net._http_response h
    where r.state='queued' and r.request_id=h.id;
  update public.invoice_provider_runs
    set state='failed',error_code='OKUYUCU_ZAMAN_ASIMI',finished_at=now()
    where state='queued' and stage_started_at<now()-interval '33 minutes';
end;
$$;

create or replace function public.get_invoice_provider_response(p_store_id uuid,p_job_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_result jsonb;
begin
  if not exists(select 1 from public.invoice_jobs where id=p_job_id and store_id=p_store_id) then return null; end if;
  perform public.sync_invoice_provider_responses();
  select jsonb_build_object(
    'stage',r.stage,'requestId',r.request_id,'readResult',r.read_result,'state',r.state,'httpStatus',r.http_status,'contentType',r.content_type,
    'body',r.response_body,'error',r.error_code,'fingerprint',j.document_fingerprint
  ) into v_result from public.invoice_provider_runs r
    join public.invoice_jobs j on j.id=r.job_id and j.store_id=r.store_id
    where r.job_id=p_job_id and r.store_id=p_store_id;
  return v_result;
end;
$$;

create or replace function public.complete_invoice_provider_job(
  p_store_id uuid,p_job_id uuid,p_job jsonb,p_lines jsonb
) returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_job public.invoice_jobs%rowtype;
  v_run public.invoice_provider_runs%rowtype;
  v_result jsonb;
begin
  if nullif(p_job->>'document_fingerprint','') is null then raise exception 'FATURA_ISLEM_GIRDISI_GECERSIZ'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_store_id::text||':'||(p_job->>'document_fingerprint'),0));
  select * into v_job from public.invoice_jobs where id=p_job_id and store_id=p_store_id for update;
  if not found or v_job.document_fingerprint is distinct from p_job->>'document_fingerprint'
    then raise exception 'FATURA_ISLEM_ESLESMEDI'; end if;
  if v_job.ingest_complete then
    return jsonb_build_object('success',true,'id',p_job_id,'mevcut',true);
  end if;
  select * into v_run from public.invoice_provider_runs where job_id=p_job_id and store_id=p_store_id for update;
  if not found or (v_run.state<>'received' or v_run.stage='reading') then raise exception 'FATURA_GERCEK_YANITI_HAZIR_DEGIL'; end if;

  update public.invoice_jobs set
    status=p_job->>'status',
    supplier_name=coalesce(p_job->>'supplier_name',''),
    supplier_tax_id=coalesce(p_job->>'supplier_tax_id',''),
    supplier_address=coalesce(p_job->>'supplier_address',''),
    supplier_site=coalesce(p_job->>'supplier_site',''),
    supplier_trace=p_job->'supplier_trace',
    document_adet=(p_job->>'document_adet')::numeric,
    document_total=(p_job->>'document_total')::numeric,
    document_warning=coalesce(p_job->>'document_warning',''),
    document_type=coalesce(p_job->>'document_type',''),
    document_no=coalesce(p_job->>'document_no',''),
    document_date=nullif(p_job->>'document_date','')::date,
    goods_total=(p_job->>'goods_total')::numeric,
    vat_total=(p_job->>'vat_total')::numeric,
    discount_total=(p_job->>'discount_total')::numeric,
    payable_total=(p_job->>'payable_total')::numeric,
    discovery_state=coalesce(p_job->'discovery_state','{}'::jsonb),updated_at=now()
    where id=p_job_id and store_id=p_store_id and not ingest_complete;
  v_result:=public.save_invoice_job(p_store_id,p_job,p_lines);
  if v_result->>'success' is distinct from 'true' or v_result->>'id' is distinct from p_job_id::text
    then raise exception 'FATURA_KAYDI_EKSIK'; end if;
  update public.invoice_provider_runs set state='processed',response_body=null,read_receipt=null,read_result=null,finished_at=now()
    where job_id=p_job_id and store_id=p_store_id;
  return v_result;
end;
$$;

create or replace function public.fail_invoice_provider_job(p_store_id uuid,p_job_id uuid,p_error text)
returns void language plpgsql security definer set search_path=pg_catalog,public
as $$
begin
  update public.invoice_provider_runs set state='failed',
    error_code=case when p_error ~ '^[A-Z_]{1,96}$' then p_error else 'OKUYUCU_CEVAP_VERMEDI' end,
    finished_at=now()
    where job_id=p_job_id and store_id=p_store_id and stage='legacy' and state in ('queued','received');
end;
$$;

create or replace function public.fail_invoice_provider_stage(
  p_store_id uuid,p_job_id uuid,p_expected_request_id bigint,p_error text
) returns void language plpgsql security definer set search_path=pg_catalog,public
as $$
begin
  update public.invoice_provider_runs set state='failed',
    error_code=case when p_error ~ '^[A-Z_]{1,96}$' then p_error else 'OKUYUCU_CEVAP_VERMEDI' end,
    finished_at=now()
    where job_id=p_job_id and store_id=p_store_id and request_id=p_expected_request_id
      and state in ('queued','received');
end;
$$;

alter function public.enqueue_invoice_preset_chain(uuid,text,jsonb,text) owner to postgres;
revoke execute on function public.enqueue_invoice_preset_chain(uuid,text,jsonb,text) from public,anon,authenticated;
grant execute on function public.enqueue_invoice_preset_chain(uuid,text,jsonb,text) to service_role;

alter function public.advance_invoice_provider_job(uuid,uuid,bigint,jsonb,jsonb,text) owner to postgres;
revoke execute on function public.advance_invoice_provider_job(uuid,uuid,bigint,jsonb,jsonb,text) from public,anon,authenticated;
grant execute on function public.advance_invoice_provider_job(uuid,uuid,bigint,jsonb,jsonb,text) to service_role;

alter function public.sync_invoice_provider_responses() owner to postgres;
revoke execute on function public.sync_invoice_provider_responses() from public,anon,authenticated;
grant execute on function public.sync_invoice_provider_responses() to service_role;

alter function public.get_invoice_provider_response(uuid,uuid) owner to postgres;
revoke execute on function public.get_invoice_provider_response(uuid,uuid) from public,anon,authenticated;
grant execute on function public.get_invoice_provider_response(uuid,uuid) to service_role;

alter function public.complete_invoice_provider_job(uuid,uuid,jsonb,jsonb) owner to postgres;
revoke execute on function public.complete_invoice_provider_job(uuid,uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.complete_invoice_provider_job(uuid,uuid,jsonb,jsonb) to service_role;

alter function public.fail_invoice_provider_stage(uuid,uuid,bigint,text) owner to postgres;
revoke execute on function public.fail_invoice_provider_stage(uuid,uuid,bigint,text) from public,anon,authenticated;
grant execute on function public.fail_invoice_provider_stage(uuid,uuid,bigint,text) to service_role;

notify pgrst, 'reload schema';
commit;
