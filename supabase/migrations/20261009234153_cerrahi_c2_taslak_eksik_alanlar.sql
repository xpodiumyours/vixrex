-- VIXREX MP-CER-1.0 C2. 20261009234153 sürümü izole testte uygulanmıştır.
-- Production'a ayrıca açık onay olmadan uygulanmaz.
DO $cerrahi$
DECLARE
 v_imza regprocedure := 'public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric)'::regprocedure;
 v_fonksiyon text;
 v_once text;
 v_sonra text;
BEGIN
 v_fonksiyon := pg_get_functiondef(v_imza);
 IF v_fonksiyon NOT ILIKE '%SECURITY DEFINER%' THEN RAISE EXCEPTION 'C2_SECURITY_DEFINER_BEKLENEN_YOK'; END IF;
 v_once := 'if v_prices<>1 or v_group_price is null then raise exception ''FATURA_MODEL_FIYATLARI_FARKLI''; end if;';
 v_sonra := 'if v_prices>1 then raise exception ''FATURA_MODEL_FIYATLARI_FARKLI''; end if;';
 IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once) THEN RAISE EXCEPTION 'C2_FIYAT_KONTROLU_BEKLENENDEN_FARKLI'; END IF;
 v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);
 v_once := 'owner_state is null or nullif(owner_state->>''stok'','''') is null or (owner_state->>''stok'')::integer<0';
 v_sonra := 'owner_state is null or (nullif(owner_state->>''stok'','''') is not null and (owner_state->>''stok'')::integer<0)';
 IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once) THEN RAISE EXCEPTION 'C2_STOK_KONTROLU_BEKLENENDEN_FARKLI'; END IF;
 v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);
 v_once := 'case when exact_qty then jsonb_build_object(''stockQuantity'',qty) else ''{}''::jsonb end';
 v_sonra := 'case when exact_qty and qty is not null then jsonb_build_object(''stockQuantity'',qty) else ''{}''::jsonb end';
 IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once) THEN RAISE EXCEPTION 'C2_VARYANT_KONTROLU_BEKLENENDEN_FARKLI'; END IF;
 v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);
 EXECUTE v_fonksiyon;
 IF has_function_privilege('anon',v_imza,'EXECUTE')
 OR has_function_privilege('authenticated',v_imza,'EXECUTE')
 OR NOT has_function_privilege('service_role',v_imza,'EXECUTE') THEN RAISE EXCEPTION 'C2_RPC_YETKI_DEGISIKLIGI'; END IF;
END;
$cerrahi$;
