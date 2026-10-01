\set ON_ERROR_STOP on
begin;
insert into public.stores(id,slug,name,edit_token) values('20000000-0000-4000-8000-000000000001','fatura-varyant-test','Fatura varyant test','fatura-varyant-local-token');
do $$
declare
  v_store uuid:='20000000-0000-4000-8000-000000000001';
  v_job uuid;
  v_other uuid;
  v_l uuid;
  v_xl uuid;
  v_product uuid;
  v_result jsonb;
  v_base jsonb:='{"model":"MODEL-GRUP","product_name":"Ürün","outcome":"kanitli","unit_price":40,"variant_name":"Siyah","catalog_snapshot":{"dayanak":"kod","resmiAd":"Ürün","kaynakFirma":"Üretici","marka":"Üretici","kaynak":"https://uretici.example/grup","gorselAdaylari":["https://uretici.example/l.jpg","https://uretici.example/xl.jpg"]}}';
  v_input jsonb:='{"name":"Ürün","priceText":"100 TL","priceAmount":100,"stockQuantity":2,"stockStatus":"available","imageUrls":["https://depo.example/l.webp"],"metadata":{},"variants":[]}';
  v_l_proof jsonb:='{"esnafOnayladi":true,"stokOnaylandi":true,"gorselKaynaklari":[{"depoUrl":"https://depo.example/l.webp","kaynakGorsel":"https://uretici.example/l.jpg","kaynakSayfa":"https://uretici.example/grup"}]}';
  v_xl_proof jsonb:='{"esnafOnayladi":true,"stokOnaylandi":true,"gorselKaynaklari":[{"depoUrl":"https://depo.example/xl.webp","kaynakGorsel":"https://uretici.example/xl.jpg","kaynakSayfa":"https://uretici.example/grup"}]}';
  v_failed boolean:=false;
begin
  v_result:=public.save_invoice_job(v_store,'{"document_fingerprint":"variant-group","supplier_name":"Üretici","status":"eslestirme"}',
    jsonb_build_array(v_base||'{"line_index":0,"size_text":"L"}',v_base||'{"line_index":1,"size_text":"XL"}'));
  v_job:=(v_result->>'id')::uuid;
  select id into v_l from public.invoice_job_lines where job_id=v_job and line_index=0;
  select id into v_xl from public.invoice_job_lines where job_id=v_job and line_index=1;
  perform public.save_invoice_owner_state(v_store,v_job,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"100","stok":"2","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}},{"satirSirasi":1,"sahipDurumu":{"satisFiyati":"100","stok":"3","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input,v_l_proof,40);
  v_product:=(v_result->>'id')::uuid;
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_xl,v_input||'{"stockQuantity":3,"imageUrls":["https://depo.example/xl.webp"]}',v_xl_proof,40);
  if v_result->>'id'<>v_product::text then raise exception 'model split'; end if;
  if (select count(*) from public.products where store_id=v_store)<>1 then raise exception 'extra card'; end if;
  if (select stock_quantity from public.products where id=v_product)<>5 then raise exception 'aggregate stock'; end if;
  if (select jsonb_array_length(variants) from public.products where id=v_product)<>2 then raise exception 'missing variants'; end if;
  perform public.save_invoice_product(v_store,'fatura-varyant-local-token',v_xl,v_input||'{"stockQuantity":3,"imageUrls":["https://depo.example/xl.webp"]}',v_xl_proof,40);
  if (select stock_quantity from public.products where id=v_product)<>5 then raise exception 'retry added stock'; end if;
  v_result:=public.publish_invoice_product(v_product,'fatura-varyant-local-token');
  if v_result->>'success'<>'true' then raise exception 'group publish %',v_result; end if;
  update public.invoice_image_rights set usage_status='denied' where line_id=v_xl and image_url='https://uretici.example/xl.jpg';
  if public.publish_invoice_product(v_product,'fatura-varyant-local-token')->>'success'<>'false' then raise exception 'denied group image published'; end if;
  update public.invoice_image_rights set usage_status='unknown' where image_url='https://uretici.example/xl.jpg' and line_id in(v_l,v_xl);
  perform public.save_invoice_owner_state(v_store,v_job,'[{"satirSirasi":1,"sahipDurumu":{"satisFiyati":"100","stok":"4","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  perform public.save_invoice_product(v_store,'fatura-varyant-local-token',v_xl,v_input||'{"stockQuantity":4,"imageUrls":["https://depo.example/xl.webp"]}',v_xl_proof,40);
  if (select stock_quantity from public.products where id=v_product)<>6 then raise exception 'correction added rather than replaced'; end if;
  if public.publish_invoice_product(v_product,'fatura-varyant-local-token')->>'success'<>'true' then raise exception 'corrected publish'; end if;
  perform public.save_invoice_owner_state(v_store,v_job,'[{"satirSirasi":1,"sahipDurumu":{"satisFiyati":"101","stok":"4","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  begin
    perform public.save_invoice_product(v_store,'fatura-varyant-local-token',v_xl,v_input||'{"priceAmount":101,"stockQuantity":4,"imageUrls":["https://depo.example/xl.webp"]}',v_xl_proof,40);
  exception when raise_exception then
    if sqlerrm<>'FATURA_MODEL_FIYATLARI_FARKLI' then raise; end if;
    v_failed:=true;
  end;
  if not v_failed or (select price_amount from public.products where id=v_product)<>100 then raise exception 'different price accepted'; end if;
  v_result:=public.save_invoice_job(v_store,'{"document_fingerprint":"variant-other","supplier_name":"Üretici","status":"eslestirme"}',jsonb_build_array(v_base||'{"line_index":0,"size_text":"XXL"}'));
  v_other:=(v_result->>'id')::uuid;
  select id into v_l from public.invoice_job_lines where job_id=v_other;
  perform public.save_invoice_owner_state(v_store,v_other,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"200","stok":"9","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input||'{"priceAmount":200,"stockQuantity":9}',v_l_proof,40);
  if v_result->>'id'<>v_product::text or (select stock_quantity from public.products where id=v_product)<>6
    or (select price_amount from public.products where id=v_product)<>100 then raise exception 'new invoice changed stock or price'; end if;
  v_result:=public.save_invoice_job(v_store,'{"document_fingerprint":"assorti-sizes","status":"eslestirme","supplier_name":"Üretici"}',
    jsonb_build_array(v_base||'{"line_index":0,"model":"ASSORTI-SIZE","size_text":"M/L/XL"}'));
  v_other:=(v_result->>'id')::uuid;
  select id into v_l from public.invoice_job_lines where job_id=v_other;
  perform public.save_invoice_owner_state(v_store,v_other,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"100","stok":"8","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input||'{"stockQuantity":8}',v_l_proof,40);
  v_product:=(v_result->>'id')::uuid;
  if (select jsonb_array_length(variants) from public.products where id=v_product)<>3
    or exists(select 1 from public.products p cross join jsonb_array_elements(p.variants) v
      where p.id=v_product and v ? 'stockQuantity') then raise exception 'assorti quantity invented'; end if;
  if public.publish_invoice_product(v_product,'fatura-varyant-local-token')->>'success'<>'true' then raise exception 'assorti publish'; end if;
  v_result:=public.save_invoice_job(v_store,'{"document_fingerprint":"assorti-unknown-pairs","status":"eslestirme","supplier_name":"Üretici"}',
    jsonb_build_array(v_base||'{"line_index":0,"model":"ASSORTI-UNKNOWN","variant_name":"Siyah/Mavi","size_text":"M/L"}'));
  v_other:=(v_result->>'id')::uuid;
  select id into v_l from public.invoice_job_lines where job_id=v_other;
  perform public.save_invoice_owner_state(v_store,v_other,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"100","stok":"8","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input||'{"stockQuantity":8}',v_l_proof,40);
  if (select jsonb_array_length(variants) from public.products where id=(v_result->>'id')::uuid)<>0 then raise exception 'unknown Cartesian pairs invented'; end if;
  v_result:=public.save_invoice_job(v_store,'{"document_fingerprint":"assorti-official-pairs","status":"eslestirme","supplier_name":"Üretici"}',
    jsonb_build_array(v_base||'{"line_index":0,"model":"ASSORTI-OFFICIAL","variant_name":"Siyah/Mavi","size_text":"M/L"}'||
      jsonb_build_object('catalog_snapshot',(v_base->'catalog_snapshot')||'{"varyantlar":[{"ad":"Siyah / M"},{"ad":"Mavi / L"}]}')));
  v_other:=(v_result->>'id')::uuid;
  select id into v_l from public.invoice_job_lines where job_id=v_other;
  perform public.save_invoice_owner_state(v_store,v_other,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"100","stok":"8","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input||'{"stockQuantity":8}',v_l_proof,40);
  v_product:=(v_result->>'id')::uuid;
  if (select jsonb_array_length(variants) from public.products where id=v_product)<>2
    or exists(select 1 from public.products p cross join jsonb_array_elements(p.variants) v
      where p.id=v_product and v ? 'stockQuantity') then raise exception 'official assorti pairs or quantities wrong'; end if;
  raise notice 'PASS: one model card, two variants, aggregate stock, retry, correction, denied image, different prices, new invoice preservation';
end;
$$;
rollback;
