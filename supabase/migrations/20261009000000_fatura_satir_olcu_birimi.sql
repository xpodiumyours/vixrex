alter table public.invoice_job_lines
  add column if not exists qty_unit text not null default '';

comment on column public.invoice_job_lines.qty_unit is
  'Faturada adetin yaninda yazan olcu birimi. Yazmiyorsa bos; tahmin edilmez.';

create or replace function public.save_invoice_job(p_store_id uuid,p_job jsonb,p_lines jsonb)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_job_id uuid;
  v_complete boolean;
  v_item jsonb;
  v_line public.invoice_job_lines%rowtype;
  v_source text;
  v_image text;
  v_strength text;
  v_expected integer;
begin
  if not exists(select 1 from public.stores where id=p_store_id) then raise exception 'FATURA_VITRINI_BULUNAMADI'; end if;
  if nullif(p_job->>'document_fingerprint','') is null or jsonb_typeof(p_lines) is distinct from 'array'
    or jsonb_array_length(p_lines)<1 then raise exception 'FATURA_ISLEM_GIRDISI_GECERSIZ'; end if;
  v_expected:=jsonb_array_length(p_lines);
  if (select count(distinct (u->>'line_index')::integer) from jsonb_array_elements(p_lines) u)<>v_expected then
    raise exception 'FATURA_SATIRLARI_TEKRARLI';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_store_id::text||':'||(p_job->>'document_fingerprint'),0));
  insert into public.invoice_jobs(store_id,document_fingerprint,status,supplier_name,supplier_tax_id,supplier_address,supplier_site,
    supplier_trace,document_adet,document_total,document_warning,document_type,document_no,document_date,
    goods_total,vat_total,discount_total,payable_total,discovery_state)
    values(p_store_id,p_job->>'document_fingerprint',p_job->>'status',coalesce(p_job->>'supplier_name',''),
      coalesce(p_job->>'supplier_tax_id',''),coalesce(p_job->>'supplier_address',''),coalesce(p_job->>'supplier_site',''),
      p_job->'supplier_trace',(p_job->>'document_adet')::numeric,(p_job->>'document_total')::numeric,
      coalesce(p_job->>'document_warning',''),coalesce(p_job->>'document_type',''),coalesce(p_job->>'document_no',''),
      (p_job->>'document_date')::date,(p_job->>'goods_total')::numeric,(p_job->>'vat_total')::numeric,
      (p_job->>'discount_total')::numeric,(p_job->>'payable_total')::numeric,coalesce(p_job->'discovery_state','{}'::jsonb))
    on conflict(store_id,document_fingerprint) do nothing;
  select id,ingest_complete into v_job_id,v_complete from public.invoice_jobs
    where store_id=p_store_id and document_fingerprint=p_job->>'document_fingerprint' for update;
  if v_complete then return jsonb_build_object('success',true,'id',v_job_id,'mevcut',true); end if;
  for v_item in select u from jsonb_array_elements(p_lines) u order by (u->>'line_index')::integer loop
    insert into public.invoice_job_lines(job_id,line_index,raw_line,model,product_name,barcode,variant_name,size_text,qty,
      qty_unit,unit_price,line_total,confidence,outcome,brand,warning,catalog_snapshot,conflict_snapshot)
    values(v_job_id,(v_item->>'line_index')::integer,coalesce(v_item->>'raw_line',''),coalesce(v_item->>'model',''),
      coalesce(v_item->>'product_name',''),coalesce(v_item->>'barcode',''),coalesce(v_item->>'variant_name',''),
      coalesce(v_item->>'size_text',''),(v_item->>'qty')::numeric,coalesce(v_item->>'qty_unit',''),
      (v_item->>'unit_price')::numeric,
      (v_item->>'line_total')::numeric,coalesce((v_item->>'confidence')::numeric,0),v_item->>'outcome',
      coalesce(v_item->>'brand',''),coalesce(v_item->>'warning',''),nullif(v_item->'catalog_snapshot','null'::jsonb),
      nullif(v_item->'conflict_snapshot','null'::jsonb)) on conflict(job_id,line_index) do nothing;
  end loop;
  if (select count(*) from public.invoice_job_lines where job_id=v_job_id)<v_expected then raise exception 'FATURA_SATIR_KAYDI_EKSIK'; end if;
  for v_line in select * from public.invoice_job_lines where job_id=v_job_id order by line_index for update loop
    v_source:=coalesce(nullif(v_line.catalog_snapshot->>'kaynak',''),'fatura');
    v_strength:=case when v_line.catalog_snapshot is not null then 'strong' when v_line.confidence>=0.6 then 'partial' else 'weak' end;
    insert into public.invoice_line_evidence(line_id,field_name,value_text,source,strength)
    values(v_line.id,'urun_adi',coalesce(nullif(v_line.catalog_snapshot->>'resmiAd',''),v_line.product_name),v_source,v_strength),
      (v_line.id,'kod',coalesce(nullif(v_line.model,''),v_line.barcode),v_source,case when v_line.catalog_snapshot is not null then 'strong' else 'weak' end)
    on conflict(line_id,field_name,source) do update set value_text=excluded.value_text,strength=excluded.strength,checked_at=now();
    if v_line.catalog_snapshot is not null then
      insert into public.invoice_line_candidates(line_id,url,platform)
        values(v_line.id,v_source,coalesce(p_job->'supplier_trace'->>'platform',''))
        on conflict(line_id,url) do nothing;
      for v_image in select jsonb_array_elements_text(coalesce(v_line.catalog_snapshot->'gorselAdaylari','[]'::jsonb)) loop
        insert into public.invoice_image_rights(line_id,image_url,usage_status,source)
        values(v_line.id,v_image,case when v_line.catalog_snapshot->>'izinDurumu'='var' then 'verified_supplier_permission' else 'unknown' end,v_source)
        on conflict(line_id,image_url) do update set source=excluded.source,checked_at=now(),
          usage_status=case when invoice_image_rights.usage_status='denied' then 'denied' else excluded.usage_status end;
      end loop;
    end if;
  end loop;
  update public.invoice_jobs set ingest_complete=true,updated_at=now() where id=v_job_id;
  return jsonb_build_object('success',true,'id',v_job_id,'mevcut',false);
end;
$$;
alter function public.save_invoice_job(uuid,jsonb,jsonb) owner to postgres;
revoke execute on function public.save_invoice_job(uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.save_invoice_job(uuid,jsonb,jsonb) to service_role;

notify pgrst, 'reload schema';
