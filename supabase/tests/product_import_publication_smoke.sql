begin;
do $$
declare
  v_store uuid := '00000000-0000-0000-0000-000000000001';
  v_token text := 'test-token-long-enough-123456';
  v_result jsonb;
  v_id uuid;
  v_rejected boolean := false;
begin
  update public.products set name = 'Legacy updated' where slug = 'legacy' and store_id = v_store;
  if not exists (select 1 from public.products where store_id = v_store and slug = 'legacy' and is_visible and image_publish_minimum = 0) then
    raise exception 'Legacy product was hidden';
  end if;
  v_result := public.batch_create_products(v_store, v_token, '[{"name":"Imported","brand":"Brand","barcode":"00123","sku":"S1","stock_quantity":10,"price_text":"1.299 TL","image_urls":[]},null,{"name":"Ready","image_urls":["https://cdn.example/1.jpg","https://cdn.example/2.jpg","https://cdn.example/3.jpg"]}]');
  if (v_result->>'inserted')::integer <> 2 or (v_result->>'errors')::integer <> 1 or (v_result #>> '{error_details,0,index}')::integer <> 2 then
    raise exception 'Batch result mismatch: %', v_result;
  end if;
  if not exists (select 1 from public.products where store_id = v_store and name = 'Imported' and not is_visible and image_publish_minimum = 3 and brand = 'Brand' and barcode = '00123' and stock_quantity = 10 and price_amount = 1299 and metadata #>> '{identifiers,sku}' = 'S1') then
    raise exception 'Draft or rich fields lost';
  end if;
  select id into v_id from public.products where store_id = v_store and name = 'Imported';
  update public.products set is_visible = true, image_publish_minimum = 0 where id = v_id;
  if exists (select 1 from public.products where id = v_id and (is_visible or image_publish_minimum <> 3)) then
    raise exception 'Image rule bypassed';
  end if;
  update public.products set image_urls = '["https://cdn.example/1.jpg","https://cdn.example/2.jpg","https://cdn.example/3.jpg"]', is_visible = true where id = v_id;
  if not exists (select 1 from public.products where id = v_id and is_visible) then raise exception 'Completed draft stayed hidden'; end if;
  update public.products set image_urls = '["https://cdn.example/1.jpg","https://cdn.example/1.jpg","https://cdn.example/1.jpg"]' where id = v_id;
  if exists (select 1 from public.products where id = v_id and is_visible) then raise exception 'Duplicate images bypassed count'; end if;
  begin
    perform public.batch_create_products(v_store, 'incorrect-token-long-enough-123', '[{"name":"Unauthorized"}]');
  exception when others then
    if sqlerrm = 'UNAUTHORIZED' then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'Unauthorized batch accepted'; end if;
end;
$$;
set local role anon;
do $$
begin
  if exists (select 1 from public.products where store_id = '00000000-0000-0000-0000-000000000001' and name = 'Imported') then
    raise exception 'Anonymous reader can see draft';
  end if;
  if (select count(*) from public.products where store_id = '00000000-0000-0000-0000-000000000001' and name in ('Ready', 'Legacy updated')) <> 2 then
    raise exception 'Anonymous reader lost visible products';
  end if;
end;
$$;
rollback;
