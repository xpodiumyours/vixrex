alter table public.invoice_jobs add column if not exists discovery_state jsonb not null default '{}'::jsonb;

create or replace function public.save_invoice_product(
  p_store_id uuid, p_edit_token text, p_line_id uuid,
  p_product jsonb, p_evidence jsonb, p_purchase_price numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_line public.invoice_job_lines%rowtype;
  v_current public.products%rowtype;
  v_result jsonb;
  v_id uuid;
  v_created boolean := false;
  v_mode text;
  v_source text;
  v_identity text;
  v_code text;
  v_state jsonb;
  v_price numeric;
  v_stock integer;
  v_ids jsonb;
  v_total integer;
  v_group_price numeric;
  v_prices integer;
  v_variants jsonb;
  v_images jsonb;
  v_proofs jsonb;
  v_authoritative_job uuid;
begin
  if not public._check_store_authorization(p_store_id, p_edit_token) then raise exception 'UNAUTHORIZED'; end if;
  select l.* into v_line from public.invoice_job_lines l
    join public.invoice_jobs j on j.id=l.job_id
    where l.id=p_line_id and j.store_id=p_store_id;
  if not found then raise exception 'FATURA_SATIRI_BULUNAMADI'; end if;
  if v_line.outcome='kanitli' and (v_line.catalog_snapshot is null or nullif(v_line.catalog_snapshot->>'kaynak','') is null) then
    raise exception 'FATURA_KAYNAK_KANITI_EKSIK';
  end if;
  v_source := v_line.catalog_snapshot->>'kaynak';
  v_code := case when v_line.catalog_snapshot->>'dayanak'='barkod' then nullif(v_line.barcode,'') else nullif(v_line.model,'') end;
  v_identity := case when v_line.outcome='kanitli' and v_source is not null and v_code is not null
    then md5(jsonb_build_array(coalesce(v_line.catalog_snapshot->>'kaynakFirma',v_line.catalog_snapshot->>'marka'),v_source,v_code)::text)
    else v_line.id::text end;
  perform pg_advisory_xact_lock(hashtextextended(p_store_id::text||':'||v_identity,0));
  select * into v_line from public.invoice_job_lines where id=p_line_id for update;
  v_state := v_line.owner_state;
  v_price := nullif(case when strpos(v_state->>'satisFiyati',',')>0
    then replace(replace(v_state->>'satisFiyati','.',''),',','.') else v_state->>'satisFiyati' end,'')::numeric;
  v_stock := nullif(v_state->>'stok','')::integer;
  if v_state is null or v_price is distinct from (p_product->>'priceAmount')::numeric
    or v_stock is distinct from (p_product->>'stockQuantity')::integer
    or coalesce(v_state->>'onayli','false') is distinct from coalesce(p_evidence->>'esnafOnayladi','false')
    or coalesce(v_state->>'stokOnaylandi','false') is distinct from coalesce(p_evidence->>'stokOnaylandi','false')
  then raise exception 'FATURA_ONAY_DURUMU_DEGISTI'; end if;
  if exists(select 1 from jsonb_array_elements_text(coalesce(p_product->'imageUrls','[]'::jsonb)) image(url)
    where not exists(select 1 from jsonb_array_elements(coalesce(p_evidence->'gorselKaynaklari','[]'::jsonb)) g
      join public.invoice_image_rights r on r.line_id=v_line.id and r.image_url=g->>'kaynakGorsel'
      where g->>'depoUrl'=image.url and g->>'kaynakSayfa'=v_source and coalesce(r.usage_status,'unknown')<>'denied')
    and not (coalesce(v_state->'esnafGorselleri','[]'::jsonb) ? image.url
      and exists(select 1 from public.stores s where s.id=p_store_id
        and starts_with(substring(image.url from '^https://[^/]+(/.*)$'),
          '/storage/v1/object/public/shelf-images/'||s.slug||'/products/'))))
  then raise exception 'FATURA_GORSEL_KAYNAK_EKSIK'; end if;
  if v_line.product_id is not null then
    select * into v_current from public.products where id=v_line.product_id and store_id=p_store_id for update;
    if not found then raise exception 'FATURA_BAGLI_URUN_BULUNAMADI'; end if;
    v_id:=v_current.id;
    v_created:=false;
  else
    v_result:=public.create_store_product_v3(
      p_store_id=>p_store_id,p_edit_token=>p_edit_token,
      p_name=>coalesce(v_line.catalog_snapshot->>'resmiAd',p_product->>'name'),
      p_description=>coalesce(v_line.catalog_snapshot->>'aciklama',p_product->>'description',''),
      p_price_text=>p_product->>'priceText',p_price_amount=>(p_product->>'priceAmount')::numeric,
      p_image_urls=>p_product->'imageUrls',p_category_id=>nullif(p_product->>'categoryId','')::uuid,
      p_source_type=>'invoice',p_external_product_id=>'invoice:'||v_identity,
      p_is_visible=>false,p_sort_order=>coalesce((p_product->>'sortOrder')::integer,0),
      p_brand=>coalesce(v_line.catalog_snapshot->>'marka',v_line.brand),p_barcode=>nullif(v_line.barcode,''),
      p_stock_quantity=>(p_product->>'stockQuantity')::integer,p_stock_status=>p_product->>'stockStatus',
      p_metadata=>p_product->'metadata',p_variants=>'[]'::jsonb
    );
    if v_result->>'success' is distinct from 'true' then raise exception 'FATURA_URUN_YAZILAMADI'; end if;
    v_id:=(v_result->>'id')::uuid;
    v_created:=coalesce((v_result->>'created')::boolean,true);
    select * into v_current from public.products where id=v_id and store_id=p_store_id for update;
    if not found then raise exception 'FATURA_BAGLI_URUN_BULUNAMADI'; end if;
  end if;
  select job_id into v_authoritative_job from public.invoice_job_lines
    where id=nullif(v_current.fatura_kanit->>'satirId','')::uuid;
  update public.invoice_job_lines set product_id=v_id,product_linked_at=now() where id=p_line_id;
  if v_authoritative_job is not null and v_authoritative_job<>v_line.job_id then
    return jsonb_build_object('success',true,'id',v_id,'slug',v_current.slug,'created',false,'kayit','mevcut');
  end if;
  perform 1 from public.invoice_job_lines where job_id=v_line.job_id and product_id=v_id order by id for update;
  select jsonb_agg(id::text order by line_index),sum(nullif(owner_state->>'stok','')::integer),
    min(nullif(case when strpos(owner_state->>'satisFiyati',',')>0 then
      replace(replace(owner_state->>'satisFiyati','.',''),',','.') else owner_state->>'satisFiyati' end,'')::numeric),
    count(distinct nullif(case when strpos(owner_state->>'satisFiyati',',')>0 then
      replace(replace(owner_state->>'satisFiyati','.',''),',','.') else owner_state->>'satisFiyati' end,'')::numeric)
    into v_ids,v_total,v_group_price,v_prices from public.invoice_job_lines where job_id=v_line.job_id and product_id=v_id;
  if v_prices<>1 or v_group_price is null then raise exception 'FATURA_MODEL_FIYATLARI_FARKLI'; end if;
  if exists(select 1 from public.invoice_job_lines where job_id=v_line.job_id and product_id=v_id
    and (owner_state is null or nullif(owner_state->>'stok','') is null or (owner_state->>'stok')::integer<0
      or catalog_snapshot->>'kaynak' is distinct from v_source
      or (case when catalog_snapshot->>'dayanak'='barkod' then nullif(barcode,'') else nullif(model,'') end) is distinct from v_code)) then raise exception 'FATURA_MODEL_GRUBU_GECERSIZ'; end if;
  select coalesce(jsonb_agg(v),'[]'::jsonb) into v_variants from jsonb_array_elements(coalesce(v_current.variants,'[]'::jsonb)) v
    where coalesce(v->>'id','') not like 'iv-%';
  with lines as (
    select l.*,array(select distinct btrim(x) from regexp_split_to_table(coalesce(variant_name,''),'[/|,;]+') x where btrim(x)<>'') colors,
      array(select distinct btrim(x) from regexp_split_to_table(coalesce(size_text,''),'[/|,;]+') x where btrim(x)<>'') sizes
      from public.invoice_job_lines l where job_id=v_line.job_id and product_id=v_id
  ), options as (
    select l.id,l.owner_state,l.colors,l.sizes,o.color,o.size from lines l cross join lateral (
      select c.color,z.size from jsonb_array_elements(case when jsonb_typeof(l.catalog_snapshot->'varyantlar')='array'
        then l.catalog_snapshot->'varyantlar' else '[]'::jsonb end) official
      cross join lateral (select (select x from unnest(l.colors) x where exists(select 1 from
        regexp_split_to_table(coalesce(official->>'ad',''),'[/|,;]+') t where lower(btrim(t))=lower(x)) limit 1) color) c
      cross join lateral (select (select x from unnest(l.sizes) x where exists(select 1 from
        regexp_split_to_table(coalesce(official->>'ad',''),'[/|,;]+') t where lower(btrim(t))=lower(x)) limit 1) size) z
      where (cardinality(l.colors)=0 or c.color is not null) and (cardinality(l.sizes)=0 or z.size is not null)
      union
      select nullif(c,''),nullif(z,'') from unnest(case when cardinality(l.colors)=0 then array[''] else l.colors end) c
        cross join unnest(case when cardinality(l.sizes)=0 then array[''] else l.sizes end) z
      where (l.catalog_snapshot->'varyantlar' is null or l.catalog_snapshot->'varyantlar'='[]'::jsonb)
        and (cardinality(l.colors)<=1 or cardinality(l.sizes)<=1)
    ) o where o.color is not null or o.size is not null
  ), quantities as (
    select *,cardinality(colors)<=1 and cardinality(sizes)<=1 and count(*) over(partition by id)=1 exact_qty from options
  ), grouped as (
    select min(color) color,min(size) size,bool_and(exact_qty) exact_qty,sum((owner_state->>'stok')::integer) qty
      from quantities group by lower(color),lower(size)
  ) select v_variants||coalesce(jsonb_agg(jsonb_build_object('id','iv-'||md5(jsonb_build_array(lower(color),lower(size))::text),
      'options',jsonb_strip_nulls(jsonb_build_object('color',color,'size',size)))||
      case when exact_qty then jsonb_build_object('stockQuantity',qty) else '{}'::jsonb end),'[]'::jsonb) into v_variants from grouped;
  select coalesce(jsonb_agg(distinct u),'[]'::jsonb) into v_images from jsonb_array_elements(
    coalesce(v_current.image_urls,'[]'::jsonb)||coalesce(p_product->'imageUrls','[]'::jsonb)) u;
  select coalesce(jsonb_agg(distinct g),'[]'::jsonb) into v_proofs from jsonb_array_elements(
    coalesce(v_current.fatura_kanit->'gorselKaynaklari','[]'::jsonb)||coalesce(p_evidence->'gorselKaynaklari','[]'::jsonb)) g;
  v_mode:=case when v_created then 'yeni' else 'guncellendi' end;
  v_result:=public.update_store_product_v2(p_product_id=>v_id,p_edit_token=>p_edit_token,
    p_name=>coalesce(v_line.catalog_snapshot->>'resmiAd',p_product->>'name'),
    p_description=>coalesce(v_line.catalog_snapshot->>'aciklama',p_product->>'description',''),
    p_price_text=>p_product->>'priceText',p_price_amount=>v_group_price,p_image_urls=>v_images,
    p_category_id=>nullif(p_product->>'categoryId','')::uuid,p_stock_quantity=>v_total,
    p_stock_status=>p_product->>'stockStatus',p_brand=>coalesce(v_line.catalog_snapshot->>'marka',v_line.brand),
    p_barcode=>nullif(v_line.barcode,''),p_metadata=>coalesce(v_current.metadata,p_product->'metadata'),
    p_variants=>v_variants,p_clear_category=>nullif(p_product->>'categoryId','') is null,
    p_clear_price_amount=>false);
  if v_result->>'success' is distinct from 'true' or v_id is null then raise exception 'FATURA_URUN_YAZILAMADI'; end if;
  if v_mode<>'mevcut' then
    update public.products set fatura_kanit=p_evidence||jsonb_build_object('kartDurumu',v_line.outcome,'satirId',v_line.id,'kaynak',v_source,
      'satirIdler',v_ids,'gorselKaynaklari',v_proofs,
      'esnafOnayladi',coalesce(v_state->>'onayli','false')='true',
      'stokOnaylandi',coalesce(v_state->>'stokOnaylandi','false')='true') where id=v_id and store_id=p_store_id;
    if v_line.unit_price is not null and v_line.unit_price>0 then
      insert into public.product_purchase_prices(product_id,store_id,amount,updated_at)
        values(v_id,p_store_id,v_line.unit_price,now())
        on conflict(product_id) do update set amount=excluded.amount,updated_at=excluded.updated_at;
    end if;
  end if;
  update public.invoice_job_lines set product_id=v_id,product_linked_at=now() where id=p_line_id;
  return jsonb_build_object('success',true,'id',v_id,'slug',coalesce(v_result->>'slug',v_current.slug),'created',v_created,'kayit',v_mode);
end;
$$;
alter function public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric) owner to postgres;
revoke execute on function public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric) from public,anon,authenticated;
grant execute on function public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric) to service_role;
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
  if not found or v_line.outcome is distinct from 'kanitli' then
    return jsonb_build_object('success',false,'hata','Güncel fatura satırı kanıtlı değil.');
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
    if v_member.outcome is distinct from 'kanitli' or v_member.catalog_snapshot->>'kaynak' is distinct from v_source
      or v_member.owner_state->>'onayli' is distinct from 'true'
      or v_member.owner_state->>'stokOnaylandi' is distinct from 'true'
      or nullif(v_member.owner_state->>'stok','') is null then
      return jsonb_build_object('success',false,'hata','Fatura grubundaki kartlar yeniden onaylanmalı.');
    end if;
    begin
      v_stock:=(v_member.owner_state->>'stok')::integer;
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
  if v_member_count<>jsonb_array_length(v_ids) or v_total is distinct from v_product.stock_quantity then
    return jsonb_build_object('success',false,'hata','Fatura grubu stok toplamı değişti.'); end if;
  v_state:=v_line.owner_state;
  begin
    v_price:=nullif(case when strpos(v_state->>'satisFiyati',',')>0
      then replace(replace(v_state->>'satisFiyati','.',''),',','.') else v_state->>'satisFiyati' end,'')::numeric;
    v_stock:=nullif(v_state->>'stok','')::integer;
  exception when invalid_text_representation or numeric_value_out_of_range then
    return jsonb_build_object('success',false,'hata','Satış fiyatı veya stok geçersiz.');
  end;
  if v_state is null or v_state->>'onayli' is distinct from 'true'
    or v_state->>'stokOnaylandi' is distinct from 'true'
    or v_product.fatura_kanit->>'esnafOnayladi' is distinct from 'true'
    or v_product.fatura_kanit->>'stokOnaylandi' is distinct from 'true'
    or v_price is null or v_price<=0 or v_stock is null or v_stock<0
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

create or replace function public.save_invoice_owner_state(p_store_id uuid,p_job_id uuid,p_updates jsonb)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_item jsonb; v_count integer; v_expected integer;
begin
  perform 1 from public.invoice_jobs where id=p_job_id and store_id=p_store_id for update;
  if not found then raise exception 'FATURA_ISLEMI_BULUNAMADI'; end if;
  if jsonb_typeof(p_updates) is distinct from 'array' then raise exception 'FATURA_SATIRLARI_GECERSIZ'; end if;
  v_expected:=jsonb_array_length(p_updates);
  if v_expected<1 or v_expected>100 then raise exception 'FATURA_SATIR_SAYISI_GECERSIZ'; end if;
  select count(distinct (u->>'satirSirasi')::integer) into v_count from jsonb_array_elements(p_updates) u;
  if v_count<>v_expected then raise exception 'FATURA_SATIRLARI_TEKRARLI'; end if;
  for v_item in select u from jsonb_array_elements(p_updates) u order by (u->>'satirSirasi')::integer loop
    if jsonb_typeof(v_item->'sahipDurumu') is distinct from 'object' then raise exception 'FATURA_SAHIP_DURUMU_GECERSIZ'; end if;
    update public.invoice_job_lines set owner_state=v_item->'sahipDurumu',owner_state_updated_at=now()
      where job_id=p_job_id and line_index=(v_item->>'satirSirasi')::integer;
    get diagnostics v_count=row_count;
    if v_count<>1 then raise exception 'FATURA_SATIRI_BULUNAMADI'; end if;
  end loop;
  return jsonb_build_object('success',true,'kaydedilen',v_expected);
end;
$$;
alter function public.save_invoice_owner_state(uuid,uuid,jsonb) owner to postgres;
revoke execute on function public.save_invoice_owner_state(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.save_invoice_owner_state(uuid,uuid,jsonb) to service_role;

create or replace function public.replace_invoice_line(p_store_id uuid,p_job_id uuid,p_line_id uuid,p_line jsonb,p_evidence jsonb,p_candidates jsonb,p_rights jsonb,p_discovery jsonb)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_old public.invoice_job_lines%rowtype; v_reset boolean;
begin
  perform 1 from public.invoice_jobs where id=p_job_id and store_id=p_store_id for update;
  if not found then raise exception 'FATURA_ISLEMI_BULUNAMADI'; end if;
  select * into v_old from public.invoice_job_lines where id=p_line_id and job_id=p_job_id for update;
  if not found then raise exception 'FATURA_SATIRI_BULUNAMADI'; end if;
  v_reset:=v_old.model is distinct from p_line->>'model' or v_old.barcode is distinct from p_line->>'barcode'
    or v_old.brand is distinct from p_line->>'brand' or v_old.outcome is distinct from p_line->>'outcome'
    or v_old.catalog_snapshot is distinct from p_line->'catalog_snapshot';
  update public.invoice_job_lines set model=p_line->>'model',product_name=p_line->>'product_name',barcode=p_line->>'barcode',
    brand=p_line->>'brand',outcome=p_line->>'outcome',warning=p_line->>'warning',catalog_snapshot=p_line->'catalog_snapshot',
    conflict_snapshot=p_line->'conflict_snapshot',
    owner_state=case when v_reset and v_old.owner_state is not null then v_old.owner_state||'{"onayli":false,"stokOnaylandi":false}'::jsonb else v_old.owner_state end,
    owner_state_updated_at=case when v_reset then now() else v_old.owner_state_updated_at end
    where id=p_line_id;
  delete from public.invoice_line_evidence where line_id=p_line_id;
  insert into public.invoice_line_evidence(line_id,field_name,value_text,source,strength)
    select p_line_id,u->>'field_name',u->>'value_text',u->>'source',u->>'strength' from jsonb_array_elements(p_evidence) u;
  delete from public.invoice_line_candidates where line_id=p_line_id;
  insert into public.invoice_line_candidates(line_id,url,platform)
    select p_line_id,u->>'url',coalesce(u->>'platform','') from jsonb_array_elements(p_candidates) u;
  delete from public.invoice_image_rights r where r.line_id=p_line_id and r.usage_status<>'denied'
    and not exists(select 1 from jsonb_array_elements(p_rights) u where u->>'image_url'=r.image_url);
  insert into public.invoice_image_rights(line_id,image_url,usage_status,source)
    select p_line_id,u->>'image_url',u->>'usage_status',coalesce(u->>'source','') from jsonb_array_elements(p_rights) u
    on conflict(line_id,image_url) do update set source=excluded.source,checked_at=now(),
      usage_status=case when invoice_image_rights.usage_status='denied' then 'denied' else excluded.usage_status end;
  update public.invoice_jobs set discovery_state=coalesce(p_discovery,'{}'::jsonb),updated_at=now() where id=p_job_id;
  return jsonb_build_object('success',true,'onaySifirlandi',v_reset,'sahipDurumu',
    case when v_reset and v_old.owner_state is not null then v_old.owner_state||'{"onayli":false,"stokOnaylandi":false}'::jsonb else v_old.owner_state end);
end;
$$;
alter function public.replace_invoice_line(uuid,uuid,uuid,jsonb,jsonb,jsonb,jsonb,jsonb) owner to postgres;
revoke execute on function public.replace_invoice_line(uuid,uuid,uuid,jsonb,jsonb,jsonb,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.replace_invoice_line(uuid,uuid,uuid,jsonb,jsonb,jsonb,jsonb,jsonb) to service_role;

alter table public.invoice_jobs add column if not exists ingest_complete boolean not null default false;

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
      unit_price,line_total,confidence,outcome,brand,warning,catalog_snapshot,conflict_snapshot)
    values(v_job_id,(v_item->>'line_index')::integer,coalesce(v_item->>'raw_line',''),coalesce(v_item->>'model',''),
      coalesce(v_item->>'product_name',''),coalesce(v_item->>'barcode',''),coalesce(v_item->>'variant_name',''),
      coalesce(v_item->>'size_text',''),(v_item->>'qty')::numeric,(v_item->>'unit_price')::numeric,
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
