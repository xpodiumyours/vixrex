create or replace function public.publish_invoice_product(p_product_id uuid,p_edit_token text)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_store uuid;
  v_product public.products%rowtype;
  v_line public.invoice_job_lines%rowtype;
  v_source text;
  v_supplier text;
  v_state jsonb;
  v_price numeric;
  v_stock integer;
  v_ids jsonb;
  v_member public.invoice_job_lines%rowtype;
  v_total integer:=0;
  v_member_count integer:=0;
begin
  select id into v_store from public.stores where edit_token=p_edit_token limit 1;
  if v_store is null or not public._check_store_authorization(v_store,p_edit_token) then
    return jsonb_build_object('success',false,'hata','Vitrin yetkisi geçersiz veya süresi dolmuş.');
  end if;
  select * into v_product from public.products where id=p_product_id and store_id=v_store;
  if not found or v_product.source_type is distinct from 'invoice' then
    return jsonb_build_object('success',false,'hata','Fatura ürünü bulunamadı.');
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_store::text||':'||substring(v_product.external_product_id from '^invoice:(.*)$'),0));
  select l.* into v_line from public.invoice_job_lines l join public.invoice_jobs j on j.id=l.job_id
    where l.product_id=p_product_id and j.store_id=v_store
      and l.id::text=v_product.fatura_kanit->>'satirId' for update of l;
  if not found then
    return jsonb_build_object('success',false,'hata','Güncel fatura satırı bulunamadı.');
  end if;
  select * into v_product from public.products where id=p_product_id and store_id=v_store for update;
  if not found or v_line.id::text is distinct from v_product.fatura_kanit->>'satirId' then
    return jsonb_build_object('success',false,'hata','Fatura ürün bağlantısı değişti. Tekrar dene.');
  end if;
  v_source:=v_line.catalog_snapshot->>'kaynak';
  if nullif(v_source,'') is null or v_source is distinct from v_product.fatura_kanit->>'kaynak'
    or nullif(v_line.catalog_snapshot->>'resmiAd','') is null then
    return jsonb_build_object('success',false,'hata','Resmî ürün kaynağı doğrulanamadı.');
  end if;
  v_ids:=case when jsonb_typeof(v_product.fatura_kanit->'satirIdler')='array' then
    v_product.fatura_kanit->'satirIdler' else jsonb_build_array(v_line.id::text) end;
  if jsonb_array_length(v_ids)<1 then return jsonb_build_object('success',false,'hata','Fatura grubu boş.'); end if;
  for v_member in select * from public.invoice_job_lines where job_id=v_line.job_id
    and product_id=p_product_id and v_ids ? id::text order by id for update loop
    v_member_count:=v_member_count+1;
    if v_member.catalog_snapshot->>'kaynak' is distinct from v_source
      or v_member.owner_state->>'onayli' is distinct from 'true' then
      return jsonb_build_object('success',false,'hata','Fatura grubundaki kartlar yeniden onaylanmalı.');
    end if;
    begin
      v_stock:=coalesce(round(nullif(replace(coalesce(v_member.owner_state->>'stok',''),',','.'),'')::numeric),0)::integer;
      v_price:=nullif(case when strpos(v_member.owner_state->>'satisFiyati',',')>0 then
        replace(replace(v_member.owner_state->>'satisFiyati','.',''),',','.') else v_member.owner_state->>'satisFiyati' end,'')::numeric;
    exception when invalid_text_representation or numeric_value_out_of_range then
      return jsonb_build_object('success',false,'hata','Grup fiyatı veya stoku geçersiz.');
    end;
    if v_stock<0 or v_price is null or v_price<=0 or v_price is distinct from v_product.price_amount then
      return jsonb_build_object('success',false,'hata','Grup fiyatı veya stoku değişti.');
    end if;
    v_total:=v_total+v_stock;
  end loop;
  if v_member_count<>jsonb_array_length(v_ids) or v_total is distinct from coalesce(v_product.stock_quantity,0) then
    return jsonb_build_object('success',false,'hata','Fatura grubu stok toplamı değişti.'); end if;
  v_state:=v_line.owner_state;
  begin
    v_price:=nullif(case when strpos(v_state->>'satisFiyati',',')>0
      then replace(replace(v_state->>'satisFiyati','.',''),',','.') else v_state->>'satisFiyati' end,'')::numeric;
    v_stock:=coalesce(round(nullif(replace(coalesce(v_state->>'stok',''),',','.'),'')::numeric),0)::integer;
  exception when invalid_text_representation or numeric_value_out_of_range then
    return jsonb_build_object('success',false,'hata','Satış fiyatı veya stok geçersiz.');
  end;
  if v_state is null or v_state->>'onayli' is distinct from 'true'
    or v_product.fatura_kanit->>'esnafOnayladi' is distinct from 'true'
    or v_price is null or v_price<=0 or v_stock<0
    or v_price is distinct from v_product.price_amount
  then return jsonb_build_object('success',false,'hata','Fiyat, stok ve kart onayını yeniden kontrol et.'); end if;
  if v_product.image_urls is null or jsonb_typeof(v_product.image_urls)<>'array' or jsonb_array_length(v_product.image_urls)<1 then
    return jsonb_build_object('success',false,'hata','En az bir doğru ürün görseli gerekiyor.');
  end if;
  if exists(select 1 from jsonb_array_elements_text(v_product.image_urls) image(url)
    where not exists(select 1 from jsonb_array_elements(case when jsonb_typeof(v_product.fatura_kanit->'gorselKaynaklari')='array'
        then v_product.fatura_kanit->'gorselKaynaklari' else '[]'::jsonb end) g where g->>'depoUrl'=image.url)
      and not (exists(select 1 from public.invoice_job_lines l where l.job_id=v_line.job_id and l.product_id=p_product_id
          and v_ids ? l.id::text and coalesce(l.owner_state->'esnafGorselleri','[]'::jsonb) ? image.url)
        and exists(select 1 from public.stores s where s.id=v_store
          and starts_with(substring(image.url from '^https://[^/]+(/.*)$'),
            '/storage/v1/object/public/shelf-images/'||s.slug||'/products/'))))
  then return jsonb_build_object('success',false,'hata','Ürün görseli kayıtlı kaynak veya esnaf fotoğrafıyla bağlı değil.'); end if;
  if exists(select 1 from jsonb_array_elements(case when jsonb_typeof(v_product.fatura_kanit->'gorselKaynaklari')='array'
      then v_product.fatura_kanit->'gorselKaynaklari' else '[]'::jsonb end) g
    where g->>'kaynakSayfa' is distinct from v_source or not exists(
      select 1 from public.invoice_image_rights r where v_ids ? r.line_id::text
        and r.image_url=g->>'kaynakGorsel' and coalesce(r.usage_status,'unknown')<>'denied')
      or exists(select 1 from public.invoice_image_rights r where v_ids ? r.line_id::text
        and r.image_url=g->>'kaynakGorsel' and r.usage_status='denied')) then
    return jsonb_build_object('success',false,'hata','Ürün görselinin güncel kaynak veya izin kaydı uygun değil.');
  end if;
  v_supplier:=regexp_replace(lower(translate(coalesce(v_line.catalog_snapshot->>'kaynakFirma',v_line.catalog_snapshot->>'marka',''),'Iİ','ıi')),
    '[^a-z0-9çğıöşü]','','g')||':'||lower(substring(v_source from '^https://([^/:?#]+)'));
  if exists(select 1 from public.supplier_permissions p where p.supplier_key=v_supplier
    and p.scope in ('data','images','data_and_images') and p.status in ('reddedildi','geri_cekildi'))
    or exists(select 1 from public.supplier_permission_products b
      join public.supplier_permission_requests r on r.id=b.request_id
      join public.supplier_permissions p on p.supplier_key=r.supplier_key where b.product_id=p_product_id
      and p.scope in ('data','images','data_and_images') and p.status in ('reddedildi','geri_cekildi')) then
    return jsonb_build_object('success',false,'hata','Firma içerik kullanımını reddetti veya geri çekti.');
  end if;
  if v_product.is_visible then return jsonb_build_object('success',true,'id',p_product_id,'zaten_yayinda',true); end if;
  perform set_config('vixrex.fatura_yayin_serbest','acik',true);
  update public.products set is_visible=true,updated_at=now() where id=p_product_id and store_id=v_store;
  return jsonb_build_object('success',true,'id',p_product_id);
end;
$$;
alter function public.publish_invoice_product(uuid,text) owner to postgres;
revoke execute on function public.publish_invoice_product(uuid,text) from public,anon,authenticated;
grant execute on function public.publish_invoice_product(uuid,text) to service_role;

notify pgrst, 'reload schema';
