begin;

do $beden$
declare
  v_signature regprocedure := 'public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric)'::regprocedure;
  v_definition text := pg_get_functiondef(v_signature);
  v_once text := $frag$v_identity := v_line.id::text;$frag$;
  v_once_eski text := $frag$v_identity := case when v_line.outcome='kanitli' and v_source is not null and v_code is not null
    then md5(jsonb_build_array(coalesce(v_line.catalog_snapshot->>'kaynakFirma',v_line.catalog_snapshot->>'marka'),v_source,coalesce(v_code,nullif(v_line.barcode,''),nullif(v_line.model,''),public.ek_urun_katla(coalesce(v_line.catalog_snapshot->>'resmiAd',v_line.product_name))),public.ek_urun_katla(coalesce(v_line.size_text,v_line.variant_name)))::text)
    else v_line.id::text end;$frag$;
  v_once_test text := $frag$v_identity := case when v_line.outcome='kanitli' and v_source is not null and v_code is not null
    then md5(jsonb_build_array(coalesce(v_line.catalog_snapshot->>'kaynakFirma',v_line.catalog_snapshot->>'marka'),v_source,v_code)::text)
    else v_line.id::text end;$frag$;
  v_anahtar text;
  v_sonra text := $frag$v_identity := case when v_line.outcome='kanitli' and v_source is not null and v_code is not null
    then md5(jsonb_build_array(coalesce(v_line.catalog_snapshot->>'kaynakFirma',v_line.catalog_snapshot->>'marka'),v_source,v_code,lower(btrim(coalesce(v_line.size_text,''))),lower(btrim(coalesce(v_line.variant_name,''))))::text)
    else v_line.id::text end;$frag$;
  v_kontrol text := $frag$lower(btrim(coalesce(v_line.size_text,''))),lower(btrim(coalesce(v_line.variant_name,'')))$frag$;
begin
  if position(v_kontrol in v_definition) > 0 then
    raise notice 'FATURA_KIMLIK_BEDEN_ZATEN_UYGULANMIS';
    return;
  end if;
  if position(v_once_eski in v_definition) > 0 then
    v_anahtar := v_once_eski;
  elsif position(v_once in v_definition) > 0 then
    v_anahtar := v_once;
  elsif position(v_once_test in v_definition) > 0 then
    v_anahtar := v_once_test;
  else
    raise exception 'FATURA_KIMLIK_SATIRI_BULUNAMADI';
  end if;
  if (length(v_definition)-length(replace(v_definition,v_anahtar,''))) <> length(v_anahtar) then
    raise exception 'FATURA_KIMLIK_SATIRI_BIRDEN_FAZLA';
  end if;
  if position('pg_advisory_xact_lock' in v_definition) = 0
    or position('||v_identity' in v_definition) = 0 then
    raise exception 'FATURA_KIMLIK_KORUMASI_DEGISTI';
  end if;
  v_definition := replace(v_definition,v_anahtar,v_sonra);
  execute v_definition;
  if position(v_kontrol in pg_get_functiondef(v_signature)) = 0 then
    raise exception 'FATURA_KIMLIK_UYGULANMADI';
  end if;
  if not has_function_privilege('service_role',v_signature,'EXECUTE') then
    raise exception 'FATURA_KAYIT_YETKISI_DEGISTI';
  end if;
end;
$beden$;

commit;
