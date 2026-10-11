-- Luna is the sole manufacturer/product/catalog decision-maker.
-- Production changes require separate approval; this migration is staged in GitHub only.
-- Preserve owner authorization, atomic invoice linkage, and the publish approval gate.
DO $luna$
DECLARE
  v_imza regprocedure := 'public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric)'::regprocedure;
  v_fonksiyon text;
  v_once text;
  v_sonra text;
  v_baslangic integer;
  v_bitis integer;
BEGIN
  v_fonksiyon := pg_get_functiondef(v_imza);
  IF v_fonksiyon NOT ILIKE '%SECURITY DEFINER%' THEN RAISE EXCEPTION 'LUNA_FATURA_RPC_KORUMA_YOK'; END IF;

  -- The fresh, trusted Luna catalog snapshot must replace stale product metadata.
  v_once := 'p_metadata=>coalesce(v_current.metadata,p_product->''metadata'')';
  v_sonra := 'p_metadata=>coalesce(p_product->''metadata'',v_current.metadata)';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_METADATA_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);

  -- Never invent code/size variants in SQL; save precisely Luna's variant payload.
  v_once := 'p_variants=>v_variants';
  v_sonra := 'p_variants=>coalesce(p_product->''variants'',''[]''::jsonb)';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_VARYANT_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);

  -- Do not reintroduce previously linked photos after Luna replaces a product card.
  v_once := 'p_image_urls=>v_images';
  v_sonra := 'p_image_urls=>coalesce(p_product->''imageUrls'',''[]''::jsonb)';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_GORSEL_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);


  v_once := 'v_identity := case when v_line.outcome=''kanitli'' and v_source is not null and v_code is not null
    then md5(jsonb_build_array(coalesce(v_line.catalog_snapshot->>''kaynakFirma'',v_line.catalog_snapshot->>''marka''),v_source,v_code)::text)
    else v_line.id::text end;';
  v_sonra := 'v_identity := v_line.id::text;';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_SATIR_KIMLIGI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);

  v_once := 'v_stock := nullif(v_state->>''stok'','''')::integer;';
  v_sonra := 'v_quantity := nullif(replace(v_state->>''stok'','','',''.''),'''')::numeric;
  v_stock := case when v_quantity=trunc(v_quantity) and v_quantity between 0 and 2147483647
    then v_quantity::integer else null end;';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_MIKTAR_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);
  v_once := 'v_stock integer;';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_MIKTAR_TANIMI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,'v_stock integer;
  v_quantity numeric;');
  v_once := 'or v_stock is distinct from (p_product->>''stockQuantity'')::integer';
  v_sonra := 'or v_quantity<0 or v_stock::numeric is distinct from nullif(p_product->>''stockQuantity'','''')::numeric';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_MIKTAR_ONAYI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);

  v_once := 'v_id:=v_current.id;
    v_created:=false;
  else';
  v_sonra := 'if v_current.fatura_kanit->>''satirId''=v_line.id::text then
      v_id:=v_current.id;
      v_created:=false;
      update public.products set external_product_id=''invoice:''||v_identity where id=v_id and store_id=p_store_id;
    end if;
  end if;
  if v_id is null then';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_ESKI_BAGLANTI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);

  v_baslangic := strpos(v_fonksiyon,'  select job_id into v_authoritative_job from public.invoice_job_lines');
  v_bitis := strpos(v_fonksiyon,'  v_mode:=case when v_created then ''yeni'' else ''guncellendi'' end;');
  IF v_baslangic=0 OR v_bitis<=v_baslangic
    OR v_fonksiyon NOT LIKE '%FATURA_MODEL_FIYATLARI_FARKLI%'
    OR v_fonksiyon NOT LIKE '%FATURA_MODEL_GRUBU_GECERSIZ%'
    OR v_fonksiyon NOT LIKE '%into v_variants from grouped;%'
  THEN RAISE EXCEPTION 'LUNA_GRUP_BLOGU_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := substring(v_fonksiyon from 1 for v_baslangic-1)
    ||'  v_ids:=jsonb_build_array(v_line.id::text);
  v_proofs:=coalesce(p_evidence->''gorselKaynaklari'',''[]''::jsonb);
'
    ||substring(v_fonksiyon from v_bitis);

  v_once := 'p_price_amount=>v_group_price';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_SATIR_FIYATI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,'p_price_amount=>v_price');
  v_once := 'p_stock_quantity=>v_total';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_SATIR_STOKU_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,'p_stock_quantity=>v_stock,p_clear_stock_quantity=>v_stock is null');
  v_once := 'p_clear_price_amount=>false';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_BOS_FIYAT_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,'p_clear_price_amount=>v_price is null');

  EXECUTE v_fonksiyon;
  IF has_function_privilege('anon',v_imza,'EXECUTE')
    OR has_function_privilege('authenticated',v_imza,'EXECUTE')
    OR NOT has_function_privilege('service_role',v_imza,'EXECUTE')
  THEN RAISE EXCEPTION 'LUNA_FATURA_RPC_YETKILERI_DEGISTI'; END IF;

  v_imza := 'public.publish_invoice_product(uuid,text)'::regprocedure;
  v_fonksiyon := pg_get_functiondef(v_imza);
  IF v_fonksiyon NOT ILIKE '%SECURITY DEFINER%' THEN RAISE EXCEPTION 'LUNA_YAYIN_RPC_KORUMA_YOK'; END IF;
  v_once := 'coalesce(round(nullif(replace(coalesce(v_member.owner_state->>''stok'',''''),'','',''.''),'''')::numeric),0)::integer';
  v_sonra := 'case when nullif(replace(v_member.owner_state->>''stok'','','',''.''),'''')::numeric=trunc(nullif(replace(v_member.owner_state->>''stok'','','',''.''),'''')::numeric)
    and nullif(replace(v_member.owner_state->>''stok'','','',''.''),'''')::numeric between 0 and 2147483647
    then nullif(replace(v_member.owner_state->>''stok'','','',''.''),'''')::numeric::integer else null end';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_YAYIN_GRUP_MIKTARI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);
  v_once := 'coalesce(round(nullif(replace(coalesce(v_state->>''stok'',''''),'','',''.''),'''')::numeric),0)::integer';
  v_sonra := replace(v_sonra,'v_member.owner_state','v_state');
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_YAYIN_SATIR_MIKTARI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,v_sonra);
  v_once := 'v_total:=v_total+v_stock;';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_YAYIN_STOK_TOPLAMI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,'v_total:=v_total+coalesce(v_stock,0);');
  v_once := 'if v_stock<0 or v_price is null';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_YAYIN_NEGATIF_GRUP_MIKTARI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,'if nullif(replace(v_member.owner_state->>''stok'','','',''.''),'''')::numeric<0 or v_stock<0 or v_price is null');
  v_once := 'or v_price is null or v_price<=0 or v_stock<0';
  IF (length(v_fonksiyon)-length(replace(v_fonksiyon,v_once,'')))<>length(v_once)
    THEN RAISE EXCEPTION 'LUNA_YAYIN_NEGATIF_SATIR_MIKTARI_HEDEFI_BULUNAMADI'; END IF;
  v_fonksiyon := replace(v_fonksiyon,v_once,'or v_price is null or v_price<=0 or v_stock<0 or nullif(replace(v_state->>''stok'','','',''.''),'''')::numeric<0');
  EXECUTE v_fonksiyon;
  IF has_function_privilege('anon',v_imza,'EXECUTE')
    OR has_function_privilege('authenticated',v_imza,'EXECUTE')
    OR NOT has_function_privilege('service_role',v_imza,'EXECUTE')
  THEN RAISE EXCEPTION 'LUNA_YAYIN_RPC_YETKILERI_DEGISTI'; END IF;
END;
$luna$;
