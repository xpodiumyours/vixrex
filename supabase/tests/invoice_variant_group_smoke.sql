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
  v_second uuid;
  v_fractional uuid;
  v_result jsonb;
  v_base jsonb:='{"model":"MODEL-GRUP","product_name":"Ürün","outcome":"kanitli","unit_price":40,"variant_name":"Siyah","catalog_snapshot":{"dayanak":"kod","resmiAd":"Ürün L","kaynakFirma":"Üretici","marka":"Üretici","kaynak":"https://uretici.example/grup","gorselAdaylari":["https://uretici.example/l.jpg","https://uretici.example/xl.jpg"]}}';
  v_input jsonb:='{"name":"Ürün","priceText":"100 TL","priceAmount":100,"stockQuantity":2,"stockStatus":"available","imageUrls":["https://depo.example/l.webp"],"metadata":{"luna":"ilk"},"variants":[{"id":"luna-l","options":{"size":"L"}}]}';
  v_l_proof jsonb:='{"esnafOnayladi":true,"stokOnaylandi":true,"gorselKaynaklari":[{"depoUrl":"https://depo.example/l.webp","kaynakGorsel":"https://uretici.example/l.jpg","kaynakSayfa":"https://uretici.example/grup"}]}';
  v_xl_proof jsonb:='{"esnafOnayladi":true,"stokOnaylandi":true,"gorselKaynaklari":[{"depoUrl":"https://depo.example/xl.webp","kaynakGorsel":"https://uretici.example/xl.jpg","kaynakSayfa":"https://uretici.example/grup"}]}';
  v_failed boolean:=false;
begin
  v_result:=public.save_invoice_job(v_store,'{"document_fingerprint":"variant-group","supplier_name":"Üretici","status":"eslestirme"}',
    jsonb_build_array(v_base||'{"line_index":0,"size_text":"L"}',v_base||'{"line_index":1,"size_text":"XL"}'||jsonb_build_object('catalog_snapshot',(v_base->'catalog_snapshot')||'{"resmiAd":"Ürün XL"}')));
  v_job:=(v_result->>'id')::uuid;
  select id into v_l from public.invoice_job_lines where job_id=v_job and line_index=0;
  select id into v_xl from public.invoice_job_lines where job_id=v_job and line_index=1;
  perform public.save_invoice_owner_state(v_store,v_job,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"100","stok":"2","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}},{"satirSirasi":1,"sahipDurumu":{"satisFiyati":"101","stok":"3","onayli":true,"stokOnaylandi":true,"esnafGorselleri":[]}}]');
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input,v_l_proof,40);
  v_product:=(v_result->>'id')::uuid;
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_xl,v_input||'{"priceAmount":101,"stockQuantity":3,"imageUrls":["https://depo.example/xl.webp"],"variants":[{"id":"luna-xl","options":{"size":"XL"}}]}',v_xl_proof,40);
  v_second:=(v_result->>'id')::uuid;
  if v_second=v_product or (select count(*) from public.products where store_id=v_store)<>2 then raise exception 'Luna cards merged'; end if;
  if (select name from public.products where id=v_product)<>'Ürün L' or (select name from public.products where id=v_second)<>'Ürün XL' then raise exception 'Luna names lost'; end if;
  if (select stock_quantity from public.products where id=v_product)<>2 or (select stock_quantity from public.products where id=v_second)<>3 then raise exception 'stock grouped'; end if;
  if (select variants from public.products where id=v_product) is distinct from v_input->'variants' then raise exception 'Luna variants changed'; end if;
  if (select jsonb_array_length(fatura_kanit->'satirIdler') from public.products where id=v_second)<>1 then raise exception 'proof grouped'; end if;
  if exists(select 1 from public.products where store_id=v_store and is_visible) then raise exception 'automatic publication'; end if;
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input||'{"metadata":{"luna":"guncel"},"variants":[{"id":"luna-new","options":{"size":"L"}}]}',v_l_proof,40);
  if v_result->>'id'<>v_product::text or (select metadata->>'luna' from public.products where id=v_product)<>'guncel' then raise exception 'retry identity or fresh metadata lost'; end if;
  if (select variants->0->>'id' from public.products where id=v_product)<>'luna-new' then raise exception 'fresh variant lost'; end if;
  if public.publish_invoice_product(v_product,'fatura-varyant-local-token')->>'success'<>'true' or public.publish_invoice_product(v_second,'fatura-varyant-local-token')->>'success'<>'true' then raise exception 'independent price approval publish failed'; end if;
  update public.invoice_image_rights set usage_status='denied' where line_id=v_xl and image_url='https://uretici.example/xl.jpg';
  if public.publish_invoice_product(v_second,'fatura-varyant-local-token')->>'success'<>'false' then raise exception 'denied image published'; end if;
  v_result:=public.save_invoice_job(v_store,'{"document_fingerprint":"variant-other","supplier_name":"Üretici","status":"eslestirme"}',jsonb_build_array(v_base||'{"line_index":0,"qty":2.5}'));
  v_other:=(v_result->>'id')::uuid;
  select id into v_fractional from public.invoice_job_lines where job_id=v_other;
  perform public.save_invoice_owner_state(v_store,v_other,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"200","stok":"2,5","onayli":true,"stokOnaylandi":false,"esnafGorselleri":[]}}]');
  update public.invoice_job_lines set product_id=v_product where id=v_fractional;
  v_result:=public.save_invoice_product(v_store,'fatura-varyant-local-token',v_fractional,v_input||'{"priceAmount":200,"stockQuantity":null,"metadata":{"luna":"ondalik"}}',v_l_proof||'{"stokOnaylandi":false}',40);
  v_fractional:=(v_result->>'id')::uuid;
  if v_fractional in(v_product,v_second) or (select count(*) from public.products where store_id=v_store)<>3 then raise exception 'legacy link card overwritten'; end if;
  if (select name from public.products where id=v_product)<>'Ürün L' or (select price_amount from public.products where id=v_product)<>100 then raise exception 'other invoice changed prior card'; end if;
  if (select stock_quantity from public.products where id=v_fractional) is not null then raise exception 'fractional quantity rounded'; end if;
  if (select qty from public.invoice_job_lines where job_id=v_other)<>2.5 or (select owner_state->>'stok' from public.invoice_job_lines where job_id=v_other)<>'2,5' then raise exception 'invoice quantity lost'; end if;
  if (select is_visible from public.products where id=v_fractional) then raise exception 'fractional automatic publish'; end if;
  if public.publish_invoice_product(v_fractional,'fatura-varyant-local-token')->>'success'<>'true' then raise exception 'fractional explicit approval publish failed'; end if;
  select id into v_l from public.invoice_job_lines where job_id=v_other;
  begin
    perform public.save_invoice_product(v_store,'fatura-varyant-local-token',v_l,v_input||'{"priceAmount":200,"stockQuantity":2}',v_l_proof||'{"stokOnaylandi":false}',40);
  exception when raise_exception then
    if sqlerrm<>'FATURA_ONAY_DURUMU_DEGISTI' then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'invented fractional inventory accepted'; end if;
  v_failed:=false;
  begin
    perform public.save_invoice_product(v_store,'wrong-token',v_l,v_input,v_l_proof,40);
  exception when raise_exception then
    if sqlerrm<>'UNAUTHORIZED' then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'authorization bypass'; end if;
  perform public.save_invoice_owner_state(v_store,v_other,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"200","stok":"-2,5","onayli":true,"stokOnaylandi":false,"esnafGorselleri":[]}}]');
  if public.publish_invoice_product(v_fractional,'fatura-varyant-local-token')->>'success'<>'false' then raise exception 'negative fractional amount accepted'; end if;
  perform public.save_invoice_owner_state(v_store,v_other,'[{"satirSirasi":0,"sahipDurumu":{"satisFiyati":"200","stok":"2,5","onayli":false,"stokOnaylandi":false,"esnafGorselleri":[]}}]');
  if public.publish_invoice_product(v_fractional,'fatura-varyant-local-token')->>'success'<>'false' then raise exception 'withdrawn owner approval ignored'; end if;
  if has_function_privilege('anon','public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric)','EXECUTE') or has_function_privilege('authenticated','public.publish_invoice_product(uuid,text)','EXECUTE') then raise exception 'RPC privilege widened'; end if;
  raise notice 'PASS: separate Luna cards, different prices, exact variants, fresh metadata, retry, legacy link split, fractional quantity, explicit publication, denied rights, authorization';
end;
$$;
rollback;
