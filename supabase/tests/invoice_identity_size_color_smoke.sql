\set ON_ERROR_STOP on
begin;
do $kimlik$
declare
  v_func text := pg_get_functiondef('public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric)'::regprocedure);
  v_imza regprocedure := 'public.save_invoice_product(uuid,text,uuid,jsonb,jsonb,numeric)'::regprocedure;
  v_l_siyah text;
  v_l_mavi text;
  v_xl_siyah text;
  v_bos_siyah text;
  v_bos_mavi text;
  v_tekrar text;
begin
  if position($frag$v_identity := case when v_line.outcome='kanitli'$frag$ in v_func) = 0
     or position($frag$lower(btrim(coalesce(v_line.size_text,''))),lower(btrim(coalesce(v_line.variant_name,'')))$frag$ in v_func) = 0
  then raise exception 'FATURA_KIMLIK_BEDEN_RENK_EKSIK'; end if;
  if position('pg_advisory_xact_lock' in v_func) = 0
     or position('||v_identity' in v_func) = 0
  then raise exception 'FATURA_KIMLIK_KILIDI_KAYIP'; end if;

  v_l_siyah := md5(jsonb_build_array('marka','resmi-sayfa','urun-kodu',lower(btrim('L')),lower(btrim('Siyah')))::text);
  v_l_mavi := md5(jsonb_build_array('marka','resmi-sayfa','urun-kodu',lower(btrim('L')),lower(btrim('Mavi')))::text);
  v_xl_siyah := md5(jsonb_build_array('marka','resmi-sayfa','urun-kodu',lower(btrim('XL')),lower(btrim('Siyah')))::text);
  v_bos_siyah := md5(jsonb_build_array('marka','resmi-sayfa','urun-kodu',lower(btrim('')),lower(btrim('Siyah')))::text);
  v_bos_mavi := md5(jsonb_build_array('marka','resmi-sayfa','urun-kodu',lower(btrim('')),lower(btrim('Mavi')))::text);
  v_tekrar := md5(jsonb_build_array('marka','resmi-sayfa','urun-kodu',lower(btrim(' l ')),lower(btrim(' SIYAH ')))::text);

  if v_l_siyah = v_l_mavi or v_l_siyah = v_xl_siyah
    or v_bos_siyah = v_bos_mavi or v_l_siyah = v_bos_siyah
  then raise exception 'FATURA_FARKLI_VARYANTLAR_BIRLESTI'; end if;
  if v_l_siyah <> v_tekrar then raise exception 'FATURA_AYNI_VARYANT_KIMLIK_DEGISTI'; end if;

  if has_function_privilege('anon',v_imza,'EXECUTE')
    or has_function_privilege('authenticated',v_imza,'EXECUTE')
    or not has_function_privilege('service_role',v_imza,'EXECUTE')
  then raise exception 'FATURA_RPC_YETKISI_DEGISTI'; end if;
  raise notice 'PASS: beden, renk, bos beden, ayni varyant, advisory lock, RPC yetkileri';
end;
$kimlik$;
rollback;
