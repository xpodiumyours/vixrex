-- Luna is the sole manufacturer/product/catalog decision-maker.
-- Production changes require separate approval; this migration is staged in GitHub only.
-- Preserve owner authorization, atomic invoice linkage, and the publish approval gate.
DO $luna$
DECLARE
  v_imza regprocedure := 'public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric)'::regprocedure;
  v_fonksiyon text;
  v_once text;
  v_sonra text;
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

  EXECUTE v_fonksiyon;
  IF has_function_privilege('anon',v_imza,'EXECUTE')
    OR has_function_privilege('authenticated',v_imza,'EXECUTE')
    OR NOT has_function_privilege('service_role',v_imza,'EXECUTE')
  THEN RAISE EXCEPTION 'LUNA_FATURA_RPC_YETKILERI_DEGISTI'; END IF;
END;
$luna$;
