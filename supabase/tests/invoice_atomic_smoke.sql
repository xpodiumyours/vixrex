\set ON_ERROR_STOP on
begin;
insert into public.stores(id,slug,name,edit_token) values('10000000-0000-4000-8000-000000000001','fatura-atomik-test','Fatura atomik test','fatura-local-test-token');
create function public.fatura_test_purchase_failure() returns trigger language plpgsql as $$
begin raise exception 'FATURA_TEST_FAILURE'; end;
$$;
create trigger fatura_test_purchase_failure before insert on public.product_purchase_prices
for each row execute function public.fatura_test_purchase_failure();
do $$
declare
  v_store uuid:='10000000-0000-4000-8000-000000000001';
  v_job jsonb:='{"document_fingerprint":"atomic-test","status":"eslestirme","supplier_name":"Üretici","discovery_state":{}}';
  v_lines jsonb:='[{"line_index":0,"model":"MODEL1","product_name":"Ürün","outcome":"kanitli","unit_price":450,"catalog_snapshot":{"dayanak":"kod","resmiAd":"Ürün","kaynakFirma":"Üretici","marka":"Üretici","kaynak":"https://uretici.example/model1","izinDurumu":"yok","gorselAdaylari":["https://uretici.example/model1.jpg"]}}]';
  v_result jsonb;
  v_job_id uuid;
  v_line uuid;
  v_product uuid;
  v_input jsonb:='{"name":"Yanlış istemci adı","priceText":"1799,50 TL","priceAmount":1799.50,"stockQuantity":3,"stockStatus":"available","imageUrls":["https://depo.example/model1.webp"],"metadata":{},"variants":[]}';
  v_evidence jsonb:='{"esnafOnayladi":true,"stokOnaylandi":true,"ureticiGorsel":true,"gorselKaynaklari":[{"depoUrl":"https://depo.example/model1.webp","kaynakGorsel":"https://uretici.example/model1.jpg","kaynakSayfa":"https://uretici.example/model1"}]}';
  v_failed boolean:=false;
begin
  begin
    perform public.save_invoice_job(v_store,v_job||'{"document_fingerprint":"failed-test"}',
      '[{"line_index":0,"outcome":"invalid"}]');
  exception when check_violation then v_failed:=true;
  end;
  if not v_failed or exists(select 1 from public.invoice_jobs where document_fingerprint='failed-test') then
    raise exception 'partial job persisted';
  end if;
  v_result:=public.save_invoice_job(v_store,v_job,v_lines);
  v_job_id:=(v_result->>'id')::uuid;
  if v_result->>'success'<>'true' then raise exception 'job failed'; end if;
  if public.save_invoice_job(v_store,v_job,v_lines)->>'id'<>v_job_id::text then raise exception 'duplicate job'; end if;
  select id into v_line from public.invoice_job_lines where job_id=v_job_id;
  perform public.save_invoice_owner_state(v_store,v_job_id,jsonb_build_array(jsonb_build_object('satirSirasi',0,'sahipDurumu','{"satisFiyati":"1.799,50","stok":"3","stokOnaylandi":true,"onayli":true,"esnafGorselleri":[]}'::jsonb)));
  v_failed:=false;
  begin
    perform public.save_invoice_product(v_store,'fatura-local-test-token',v_line,v_input,v_evidence,450);
  exception when raise_exception then
    if sqlerrm<>'FATURA_TEST_FAILURE' then raise; end if;
    v_failed:=true;
  end;
  if not v_failed or exists(select 1 from public.products where store_id=v_store)
    or (select product_id from public.invoice_job_lines where id=v_line) is not null then
    raise exception 'partial product persisted';
  end if;
  drop trigger fatura_test_purchase_failure on public.product_purchase_prices;
  v_failed:=false;
  begin
    perform public.save_invoice_product(v_store,'fatura-local-test-token',v_line,
      v_input||'{"imageUrls":["https://depo.example/unrelated.webp"]}',v_evidence,450);
  exception when raise_exception then
    if sqlerrm<>'FATURA_GORSEL_KAYNAK_EKSIK' then raise; end if;
    v_failed:=true;
  end;
  if not v_failed or exists(select 1 from public.products where store_id=v_store) then
    raise exception 'unbound image accepted';
  end if;
  v_result:=public.save_invoice_product(v_store,'fatura-local-test-token',v_line,v_input,v_evidence,450);
  v_product:=(v_result->>'id')::uuid;
  if v_result->>'success'<>'true' then raise exception 'product failed'; end if;
  if (select name from public.products where id=v_product)<>'Ürün' then raise exception 'canonical name lost'; end if;
  if (select is_visible from public.products where id=v_product) then raise exception 'automatic publication'; end if;
  if public.save_invoice_product(v_store,'fatura-local-test-token',v_line,v_input,v_evidence,450)->>'id'<>v_product::text then raise exception 'duplicate product'; end if;
  v_result:=public.save_invoice_job(v_store,v_job||'{"document_fingerprint":"variant-test"}',
    jsonb_build_array((v_lines->0)||'{"size_text":"XL","variant_name":"Mavi"}'));
  v_job_id:=(v_result->>'id')::uuid;
  select id into v_line from public.invoice_job_lines where job_id=v_job_id;
  perform public.save_invoice_owner_state(v_store,v_job_id,jsonb_build_array(jsonb_build_object('satirSirasi',0,'sahipDurumu','{"satisFiyati":"1.799,50","stok":"3","stokOnaylandi":true,"onayli":true,"esnafGorselleri":[]}'::jsonb)));
  v_result:=public.save_invoice_product(v_store,'fatura-local-test-token',v_line,v_input,v_evidence,450);
  if v_result->>'id'<>v_product::text then raise exception 'same model split across invoices'; end if;
  if (select stock_quantity from public.products where id=v_product)<>3 then raise exception 'new invoice changed existing stock'; end if;
  select nullif(fatura_kanit->>'satirId','')::uuid into v_line from public.products where id=v_product;
  v_result:=public.publish_invoice_product(v_product,'fatura-local-test-token');
  if v_result->>'success'<>'true' then raise exception 'publish failed: %',v_result; end if;
  update public.invoice_image_rights set usage_status='denied' where line_id=v_line;
  if public.publish_invoice_product(v_product,'fatura-local-test-token')->>'success'<>'false' then raise exception 'visible product bypasses rejection'; end if;
  update public.stores set edit_token_expires_at=now()-interval '1 hour' where id=v_store;
  if public.publish_invoice_product(v_product,'fatura-local-test-token')->>'success'<>'false' then raise exception 'expired token accepted'; end if;
  raise notice 'PASS: job/product failure rollback, atomic job, retry identity, saved owner state, canonical card, draft gate, publish, denied recheck, expired token';
end;
$$;
rollback;
