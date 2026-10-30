select store_id, barcode, count(*) as adet,
       count(distinct external_product_id) as kimlik_adedi,
       array_agg(id order by id) as urun_idleri,
       array_agg(name order by id) as adlar
  from public.products
 where barcode is not null and btrim(barcode) <> ''
 group by store_id, barcode
 having count(*) > 1
 order by count(*) desc, store_id, barcode;

select count(*) as cakisan_barkod_grubu,
       coalesce(sum(adet - 1), 0) as fazla_urun_adedi
  from (
    select store_id, barcode, count(*) as adet
      from public.products
     where barcode is not null and btrim(barcode) <> ''
     group by store_id, barcode
     having count(*) > 1
  ) t;
