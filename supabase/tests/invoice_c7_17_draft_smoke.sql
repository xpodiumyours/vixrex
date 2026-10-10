\set ON_ERROR_STOP on
-- C7: gerçek PostgreSQL RPC ve trigger zincirinde 17 fatura satırı.
-- Yalnız sentetik test girdisidir; Luna veya resmî üretici araştırma sonucu DEĞİLDİR.
-- Ürünlerin hiçbiri yayına çıkamaz. Her şeyi geri al.
BEGIN;
INSERT INTO public.stores(id,slug,name,edit_token)
VALUES ('33000000-0000-4000-8000-000000000001','cerrahi-17-smoke','C7 17-row isolated smoke','c7-token-local');
DO $c7$
DECLARE
 v_store uuid := '33000000-0000-4000-8000-000000000001';
 v_job uuid;
 v_result jsonb;
 v_line record;
 v_created integer := 0;
 v_line_count integer;
BEGIN
 v_result := public.save_invoice_job(v_store,
 jsonb_build_object('document_fingerprint','C7-17-LINE-ISOLATED-TEST','status','eslestirme','supplier_name','TEST TOPTANCI'),
 (SELECT jsonb_agg(jsonb_build_object('line_index',i,'model','LOCAL-MODEL-'||i,'product_name','Fatura TEST ürün '||(i+1),'outcome','eksik','unit_price',42.00,'catalog_snapshot',NULL) ORDER BY i) FROM generate_series(0,16) i));
 IF v_result->>'success' <> 'true' THEN RAISE EXCEPTION 'JOB_FAILED %',v_result; END IF;
 v_job := (v_result->>'id')::uuid;
 PERFORM public.save_invoice_owner_state(v_store,v_job,
 (SELECT jsonb_agg(jsonb_build_object('satirSirasi',i,'sahipDurumu',jsonb_build_object('satisFiyati','','stok','','stokOnaylandi',false,'onayli',false,'esnafGorselleri','[]'::jsonb)) ORDER BY i)
 FROM generate_series(0,16) i));
 FOR v_line IN SELECT id,line_index FROM public.invoice_job_lines WHERE job_id=v_job ORDER BY line_index LOOP
  v_result := public.save_invoice_product(v_store,'c7-token-local',v_line.id,
   jsonb_build_object('name','Fatura TEST ürün '||(v_line.line_index+1),'priceText','','priceAmount',NULL,'stockQuantity',NULL,'stockStatus','',
    'imageUrls','[]'::jsonb,'metadata','{}'::jsonb,'variants','[]'::jsonb),
   '{}'::jsonb,42.00);
  IF v_result->>'success' <> 'true' THEN RAISE EXCEPTION 'DRAFT_FAILED line % result %',v_line.line_index,v_result; END IF;
  v_created:=v_created+1;
 END LOOP;
 SELECT count(*) INTO v_line_count FROM public.invoice_job_lines WHERE job_id=v_job AND product_id IS NOT NULL;
 IF v_created<>17 OR v_line_count<>17 THEN RAISE EXCEPTION 'DRAFT_NOT_17 created %, linked %',v_created,v_line_count; END IF;
 IF EXISTS(SELECT 1 FROM public.products WHERE store_id=v_store AND is_visible=true) THEN
   RAISE EXCEPTION 'UNAPPROVED_PRODUCT_VISIBLE';
 END IF;
 RAISE NOTICE 'C7_PASS: 17 real DB product drafts, all unpublished; rollback next';
END $c7$;
ROLLBACK;
SELECT 'C7_ISOLATED_17_ROLLBACK' AS verdict,
(SELECT count(*) FROM public.products WHERE store_id='33000000-0000-4000-8000-000000000001') AS persisted_products;
