begin;
-- Dakikalık Supabase görevinin güvenli Vixrex callback izni.
alter table public.invoice_provider_runs add column if not exists callback_token uuid not null default gen_random_uuid(), add column if not exists callback_sent_at timestamptz;
create index if not exists invoice_provider_runs_callback_idx on public.invoice_provider_runs(callback_sent_at) where state='received';
-- İki var olan preset aynı kalır. İlk JSON fatura gerçeği, ikinci JSON kart kararıdır.
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
    or coalesce(p_body->>'model','') <> '@preset/urun-kart-olusturucu'
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
        content_type=null, error_code=null, finished_at=null, callback_sent_at=null
    where job_id=p_job_id and store_id=p_store_id;

  return jsonb_build_object('success',true,'id',p_job_id,'stage','cards','state','queued');
end;
$$;
alter function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) owner to postgres;
revoke execute on function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) from public,anon,authenticated;
grant execute on function public.advance_invoice_provider_job(uuid,uuid,jsonb,jsonb,text) to service_role;

-- Yalnız kullanıcı aynı faturayı açıkça yeniden yüklediğinde başarısız işi tekrarla.
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
  if v_run.job_id is not null and v_run.state <> 'failed' then
    -- Yeni ücretli çağrı yalnız kullanıcının yeni bir fotoğraf yüklemesiyle yapılır.
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

-- Ürün yayını için satış fiyatı + açık onay: kaynaksız/görselsiz ürün sahte kanıt sayılmaz.
-- Var olan kaynak/görsel verisi mevcutsa, yanlış kaynağı ve reddedilen görselleri engellemeye devam et.
do $publish$
declare
 v_signature regprocedure := 'public.publish_invoice_product(uuid,text)'::regprocedure;
 v_definition text := pg_get_functiondef(v_signature);
 v_old_source text := $frag$  if nullif(v_source,'') is null or v_source is distinct from v_product.fatura_kanit->>'kaynak'
    or nullif(v_line.catalog_snapshot->>'resmiAd','') is null then
    return jsonb_build_object('success',false,'hata','Resmî ürün kaynağı doğrulanamadı.');
  end if;$frag$;
 v_new_source text := $frag$  if nullif(v_source,'') is not null and v_source is distinct from v_product.fatura_kanit->>'kaynak' then
    return jsonb_build_object('success',false,'hata','Ürün kaynağı kayıtlı kaynakla uyuşmuyor.');
  end if;$frag$;
 v_old_image text := $frag$  if v_product.image_urls is null or jsonb_typeof(v_product.image_urls)<>'array' or jsonb_array_length(v_product.image_urls)<1 then
    return jsonb_build_object('success',false,'hata','En az bir doğru ürün görseli gerekiyor.');
  end if;$frag$;
 v_new_image text := $frag$  if v_product.image_urls is not null and jsonb_typeof(v_product.image_urls)<>'array' then
    return jsonb_build_object('success',false,'hata','Ürün görsel listesi geçersiz.');
  end if;$frag$;
begin
 if position(v_old_source in v_definition)=0 or position(v_old_image in v_definition)=0 then
   raise exception 'FATURA_YAYIN_FONKSIYONU_BEKLENEN_SURUM_DEGIL';
 end if;
 v_definition:=replace(replace(v_definition,v_old_source,v_new_source),v_old_image,v_new_image);
 execute v_definition;
 if not has_function_privilege('service_role',v_signature,'EXECUTE') then
   raise exception 'FATURA_YAYIN_YETKISI_DEGISTI';
 end if;
end;
$publish$;

-- Var olan pg_cron her dakika çağırır. Sadece hazır cevaplara bildirim gider.
create or replace function public.sync_invoice_provider_responses()
returns void language plpgsql security definer set search_path=pg_catalog,public
as $worker$
declare v_row record;
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
    where state='queued' and created_at<now()-interval '33 minutes';
  for v_row in
    select r.job_id,r.callback_token from public.invoice_provider_runs r
    where r.state='received' and (r.callback_sent_at is null or r.callback_sent_at<now()-interval '2 minutes')
    order by r.created_at limit 8 for update skip locked
  loop
    perform net.http_post(
      url := 'https://vixrex.com/api/cron/fatura-provider',
      body := jsonb_build_object('jobId',v_row.job_id::text),
      headers := jsonb_build_object('Content-Type','application/json','X-Vixrex-Callback',v_row.callback_token::text),
      timeout_milliseconds := 60000
    );
    update public.invoice_provider_runs set callback_sent_at=now()
      where job_id=v_row.job_id and state='received';
  end loop;
end;
$worker$;
alter function public.sync_invoice_provider_responses() owner to postgres;
revoke execute on function public.sync_invoice_provider_responses() from public,anon,authenticated;
grant execute on function public.sync_invoice_provider_responses() to service_role;

notify pgrst, 'reload schema';
commit;
