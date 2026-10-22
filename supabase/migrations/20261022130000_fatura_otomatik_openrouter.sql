begin;

create schema if not exists extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

-- Yalnız taşıma: araştırma ve ürün kararları OpenRouter preset'inde kalır.
-- HTTP yanıtı esnafa ham olarak açılmaz; bekleyen iş mağazaya bağlıdır.
create table if not exists public.invoice_provider_runs (
  job_id uuid primary key references public.invoice_jobs(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  request_id bigint unique,
  state text not null check (state in ('queued','received','processed','failed')),
  http_status integer,
  content_type text,
  response_body text,
  error_code text,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);
alter table public.invoice_provider_runs enable row level security;
revoke all on table public.invoice_provider_runs from public,anon,authenticated;
grant select,insert,update,delete on table public.invoice_provider_runs to service_role;
create index if not exists invoice_provider_runs_pending_idx
  on public.invoice_provider_runs(created_at) where state='queued';

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
    or coalesce(p_body->>'model','') not in ('@preset/vixrex-qwen-fatura-okuma-suzme','@preset/vixrex-fatura-otomatik-kart')
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
    -- Aynı fotoğrafa otomatik ikinci model isteği veya gizli tekrar yapılmaz.
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
  insert into public.invoice_provider_runs(job_id,store_id,request_id,state)
    values(v_job.id,p_store_id,v_request_id,'queued');
  return jsonb_build_object('success',true,'id',v_job.id,'state','queued');
end;
$$;
alter function public.enqueue_invoice_provider_job(uuid,text,jsonb,text) owner to postgres;
revoke execute on function public.enqueue_invoice_provider_job(uuid,text,jsonb,text) from public,anon,authenticated;
grant execute on function public.enqueue_invoice_provider_job(uuid,text,jsonb,text) to service_role;

create or replace function public.sync_invoice_provider_responses()
returns void language plpgsql security definer set search_path=pg_catalog,public
as $$
begin
  -- pg_net yanıtı geçici olsa da bu tablo normal WAL kayıtlıdır.
  update public.invoice_provider_runs r
    set http_status=h.status_code,content_type=h.content_type,response_body=h.content,
      state=case when coalesce(h.timed_out,false) or h.error_msg is not null then 'failed' else 'received' end,
      error_code=case when coalesce(h.timed_out,false) then 'OKUYUCU_ZAMAN_ASIMI'
                      when h.error_msg is not null then 'OKUYUCU_CEVAP_VERMEDI' else null end,
      finished_at=now()
    from net._http_response h
    where r.state='queued' and r.request_id=h.id;
  -- Çökme/kayıp kuyruk durumunda masraf doğuran otomatik tekrar yapılmaz.
  update public.invoice_provider_runs
    set state='failed',error_code='OKUYUCU_ZAMAN_ASIMI',finished_at=now()
    where state='queued' and created_at<now()-interval '33 minutes';
end;
$$;
alter function public.sync_invoice_provider_responses() owner to postgres;
revoke execute on function public.sync_invoice_provider_responses() from public,anon,authenticated;
grant execute on function public.sync_invoice_provider_responses() to service_role;

do $$
begin
  if not exists(select 1 from cron.job where jobname='vixrex-invoice-http-receipts') then
    perform cron.schedule('vixrex-invoice-http-receipts','* * * * *',
      'select public.sync_invoice_provider_responses();');
  end if;
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
    'state',r.state,'httpStatus',r.http_status,'contentType',r.content_type,
    'body',r.response_body,'error',r.error_code,'fingerprint',j.document_fingerprint
  ) into v_result from public.invoice_provider_runs r
    join public.invoice_jobs j on j.id=r.job_id and j.store_id=r.store_id
    where r.job_id=p_job_id and r.store_id=p_store_id;
  return v_result;
end;
$$;
alter function public.get_invoice_provider_response(uuid,uuid) owner to postgres;
revoke execute on function public.get_invoice_provider_response(uuid,uuid) from public,anon,authenticated;
grant execute on function public.get_invoice_provider_response(uuid,uuid) to service_role;

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
  -- Çekirdek kayıtla aynı kilit sırası: advisory → job → provider run.
  perform pg_advisory_xact_lock(hashtextextended(p_store_id::text||':'||(p_job->>'document_fingerprint'),0));
  select * into v_job from public.invoice_jobs where id=p_job_id and store_id=p_store_id for update;
  if not found or v_job.document_fingerprint is distinct from p_job->>'document_fingerprint'
    then raise exception 'FATURA_ISLEM_ESLESMEDI'; end if;
  if v_job.ingest_complete then
    return jsonb_build_object('success',true,'id',p_job_id,'mevcut',true);
  end if;
  select * into v_run from public.invoice_provider_runs where job_id=p_job_id and store_id=p_store_id for update;
  if not found or v_run.state<>'received' then raise exception 'FATURA_GERCEK_YANITI_HAZIR_DEGIL'; end if;

  -- Kuyruğa girerken boş olan başlık, yalnız gerçek OpenRouter sonucu ile dolar.
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
  -- Mevcut kanıt, stok, sahiplik ve onay kuralları aynen çekirdekte kalır.
  v_result:=public.save_invoice_job(p_store_id,p_job,p_lines);
  if v_result->>'success' is distinct from 'true' or v_result->>'id' is distinct from p_job_id::text
    then raise exception 'FATURA_KAYDI_EKSIK'; end if;
  update public.invoice_provider_runs set state='processed',response_body=null,finished_at=now()
    where job_id=p_job_id and store_id=p_store_id;
  return v_result;
end;
$$;
alter function public.complete_invoice_provider_job(uuid,uuid,jsonb,jsonb) owner to postgres;
revoke execute on function public.complete_invoice_provider_job(uuid,uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.complete_invoice_provider_job(uuid,uuid,jsonb,jsonb) to service_role;

create or replace function public.fail_invoice_provider_job(p_store_id uuid,p_job_id uuid,p_error text)
returns void language plpgsql security definer set search_path=pg_catalog,public
as $$
begin
  update public.invoice_provider_runs set state='failed',
    error_code=case when p_error ~ '^[A-Z_]{1,96}$' then p_error else 'OKUYUCU_CEVAP_VERMEDI' end,
    finished_at=now()
    where job_id=p_job_id and store_id=p_store_id and state in ('queued','received');
end;
$$;
alter function public.fail_invoice_provider_job(uuid,uuid,text) owner to postgres;
revoke execute on function public.fail_invoice_provider_job(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.fail_invoice_provider_job(uuid,uuid,text) to service_role;

create or replace function public.invoice_provider_ready()
returns boolean language sql security definer set search_path=pg_catalog,public
as $$
  select exists(select 1 from pg_extension where extname='pg_net')
    and exists(select 1 from pg_extension where extname='pg_cron')
    and exists(select 1 from cron.job where jobname='vixrex-invoice-http-receipts' and active)
    and exists(select 1 from pg_class where oid='public.invoice_provider_runs'::regclass and relrowsecurity);
$$;
alter function public.invoice_provider_ready() owner to postgres;
revoke execute on function public.invoice_provider_ready() from public,anon,authenticated;
grant execute on function public.invoice_provider_ready() to service_role;

-- Kurulum, istemciye fotoğraf/anahtar/ham yanıt erişimi açılmışsa tamamlanmaz.
do $$
begin
  if has_table_privilege('anon','public.invoice_provider_runs','SELECT')
    or has_table_privilege('authenticated','public.invoice_provider_runs','SELECT')
    or has_function_privilege('anon','public.get_invoice_provider_response(uuid,uuid)','EXECUTE')
    or has_function_privilege('authenticated','public.enqueue_invoice_provider_job(uuid,text,jsonb,text)','EXECUTE')
    or not public.invoice_provider_ready()
  then raise exception 'FATURA_ISLEYICI_KURULUM_KONTROLU_BASARISIZ'; end if;
end;
$$;

notify pgrst, 'reload schema';
commit;
